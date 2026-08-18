/-
  Dependency Audit Tool v3 — typed edges, sorryAx-safe
  =====================================================

  Fixes a real gap found while probing mutant M09: Lean's elaborator
  performs error recovery. A declaration whose tactic proof has
  unsolved goals still gets a `value?` in the environment — Lean
  silently inserts a `sorryAx` placeholder for the unproved part and
  continues. `ConstantInfo.value? = some _` is therefore NOT evidence
  that a declaration actually verified; it is only evidence that
  elaboration produced SOME term, possibly an unsound one.

  This matters specifically for mutation testing: a mutant file is
  expected to contain broken declarations. Any dependency-extraction
  tool run against such a file that does not check the axiom
  footprint will report real-looking dependency data for declarations
  that in fact failed to prove. DependencyAuditTyped.lean (v2) had
  this gap; this file (v3) is the fix, adding an explicit `verified`
  field per declaration and refusing to trust dependency data for any
  declaration whose axiom footprint contains `sorryAx`.
-/

import Lean
import Lean.Data.Json

open Lean Elab Meta Command

def usedIn (e : Expr) : Array Name := e.getUsedConstants

def isNamespaceTheorem (env : Environment) (ns : Name) (n : Name) : Bool :=
  ns.isPrefixOf n &&
  match env.find? n with
  | some (ConstantInfo.thmInfo _) => true
  | _ => false

structure TypedDeps where
  semantic   : List Name
  interface_ : List Name
  proofTerm  : List Name
deriving Inhabited

def sortedDedupStrs (ns : List Name) : List String :=
  let strs := (ns.map toString).eraseDups
  (strs.toArray.qsort (fun a b => a < b)).toList

def typedDirectDeps (env : Environment) (ns : Name) (n : Name) : TypedDeps :=
  match env.find? n with
  | some ci =>
      let typeConsts := (usedIn ci.type).toList
      let valueConsts := match ci.value? with
        | some v => (usedIn v).toList
        | none => []
      let sem := typeConsts.filter ns.isPrefixOf
      let (ifaceRaw, proofRaw) :=
        valueConsts.partition (fun m => isNamespaceTheorem env ns m)
      { semantic := sem, interface_ := ifaceRaw, proofTerm := proofRaw }
  | none => { semantic := [], interface_ := [], proofTerm := [] }

/-- Whether a declaration's axiom footprint contains `sorryAx`.
    Uses the same collection machinery `#print axioms` is built on. -/
def usesSorry (env : Environment) (n : Name) : Bool :=
  let (_, s) := (CollectAxioms.collect n).run env |>.run {}
  s.axioms.contains `sorryAx

def targets : List Name := [
  `AdmissibilityTransitionSystem.step_preserves_adm,
  `AdmissibilityTransitionSystem.reach_preserves_adm,
  `AdmissibilityTransitionSystem.global_admissibility,
  `AdmissibilityTransitionSystem.local_step_preserves_other_fibers,
  `AdmissibilityTransitionSystem.local_step_changes_own_fiber,
  `AdmissibilityTransitionSystem.fiber_invariant_under_avoidance
]

def theoremJson (env : Environment) (ns : Name) (t : Name) (verified : Bool) : Json :=
  if !verified then
    Json.mkObj [
      ("name", Json.str (toString t)),
      ("verified", Json.bool false),
      ("note", Json.str "axiom footprint contains sorryAx; dependency data below is UNTRUSTED and provided for inspection only"),
      ("semantic", Json.arr #[]),
      ("interface", Json.arr #[]),
      ("proof_term", Json.arr #[])
    ]
  else
    let td := typedDirectDeps env ns t
    Json.mkObj [
      ("name", Json.str (toString t)),
      ("verified", Json.bool true),
      ("semantic", Json.arr (sortedDedupStrs td.semantic |>.map Json.str).toArray),
      ("interface", Json.arr (sortedDedupStrs td.interface_ |>.map Json.str).toArray),
      ("proof_term", Json.arr (sortedDedupStrs td.proofTerm |>.map Json.str).toArray)
    ]

#eval show CommandElabM Unit from do
  let env ← getEnv
  let ns := `AdmissibilityTransitionSystem
  let mut docs : Array Json := #[]
  for t in targets do
    let verified := !(usesSorry env t)
    docs := docs.push (theoremJson env ns t verified)
  let doc := Json.mkObj [
    ("schema_version", Json.str "3.0-typed-edges-sorry-checked"),
    ("edge_roles", Json.arr #[Json.str "semantic", Json.str "interface", Json.str "proof_term"]),
    ("theorems", Json.arr docs)
  ]
  IO.println doc.pretty
