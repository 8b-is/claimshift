/-
  Dependency Audit Tool v2 — typed edges
  =======================================

  Amends DependencyAuditJson.lean (v1, flat edges) with a role-typed
  dependency relation, motivated directly by two findings from batch 1
  of the mutation experiment: a flat edge set cannot distinguish "the
  proposition asserted depends on this" from "the proof happens to
  invoke this" from "this caller needs that callee's signature to
  exist." M09 and M16 are each an instance of that conflation causing
  a wrong prediction under the v1 (flat) model.

  Role definitions:
    semantic   — n appears in the declaration's TYPE (what is
                 asserted). Changing n can change the proposition
                 itself.
    interface  — n appears in the declaration's VALUE (proof term),
                 and n is itself a theorem in our namespace. This
                 models "I invoke this proven fact as a black box";
                 the caller needs n's *signature* to line up, not its
                 internal proof content.
    proof_term — n appears in the declaration's VALUE, and n is NOT a
                 namespace theorem (a def, an auto-generated helper,
                 a core combinator, decidability/omega machinery,
                 etc.). This models genuine proof-construction
                 dependence rather than a named interface call.

  A single edge may carry more than one role (e.g. semantic AND
  interface, if n appears in both the type and as an invoked theorem
  in the value). Roles are therefore a SET per edge, not an enum.

  This is a mechanical heuristic, not a formal semantic analysis: it
  cannot distinguish, within "interface," whether a caller's
  correctness is fully opaque to the callee's proof strategy or
  merely happens to invoke it. It is deliberately scoped to what is
  cheaply and soundly extractable from ConstantInfo, and validated
  below against the two findings that motivated it, not assumed
  correct by construction.
-/

import AdmissibilityTransitionSystem
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

/-- Direct typed dependencies of a single declaration. -/
def typedDirectDeps (env : Environment) (ns : Name) (n : Name) : TypedDeps :=
  match env.find? n with
  | some ci =>
      let typeConsts := (usedIn ci.type).toList
      let valueConsts := match ci.value? with
        | some v => (usedIn v).toList
        | none => []
      let sem := ns |>.isPrefixOf |> (typeConsts.filter ·)
      let (ifaceRaw, proofRaw) :=
        valueConsts.partition (fun m => isNamespaceTheorem env ns m)
      { semantic := sem, interface_ := ifaceRaw, proofTerm := proofRaw }
  | none => { semantic := [], interface_ := [], proofTerm := [] }

def targets : List Name := [
  `AdmissibilityTransitionSystem.step_preserves_adm,
  `AdmissibilityTransitionSystem.reach_preserves_adm,
  `AdmissibilityTransitionSystem.global_admissibility,
  `AdmissibilityTransitionSystem.local_step_preserves_other_fibers,
  `AdmissibilityTransitionSystem.local_step_changes_own_fiber,
  `AdmissibilityTransitionSystem.fiber_invariant_under_avoidance
]

def theoremJson (env : Environment) (ns : Name) (t : Name) : Json :=
  let td := typedDirectDeps env ns t
  Json.mkObj [
    ("name", Json.str (toString t)),
    ("semantic", Json.arr (sortedDedupStrs td.semantic |>.map Json.str).toArray),
    ("interface", Json.arr (sortedDedupStrs td.interface_ |>.map Json.str).toArray),
    ("proof_term", Json.arr (sortedDedupStrs td.proofTerm |>.map Json.str).toArray)
  ]

#eval show CommandElabM Unit from do
  let env ← getEnv
  let ns := `AdmissibilityTransitionSystem
  let docs := targets.map (theoremJson env ns)
  let doc := Json.mkObj [
    ("schema_version", Json.str "2.0-typed-edges"),
    ("edge_roles", Json.arr #[Json.str "semantic", Json.str "interface", Json.str "proof_term"]),
    ("theorems", Json.arr docs.toArray)
  ]
  IO.println doc.pretty
