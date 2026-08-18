/-
  Dependency Audit Tool — JSON output
  ====================================

  Same extraction as DependencyAudit.lean (direct and transitive
  in-namespace constant dependencies per target theorem, via
  ConstantInfo.value? / Expr.getUsedConstants), emitted as a single
  deterministic JSON document instead of pretty-printed Lean lists.

  This is the frozen output schema for Paper III's mutation
  experiment. Every mutant run produces one JSON document with this
  exact shape; comparison across baseline and mutants is a JSON diff
  on named fields, never a re-derivation from scratch and never an
  eyeballed text comparison.

  Schema (top level object):
    {
      "schema_version": "1.0",
      "lean_version": string,
      "specimen_module": string,
      "generated_from": "baseline" | "mutant:<id>",
      "theorems": [
        {
          "name": string,
          "direct_in_namespace": [string],     -- sorted, deduplicated
          "direct_external": [string],         -- sorted, deduplicated
          "transitive_in_namespace": [string], -- sorted, deduplicated
          "counts": {
            "direct_in_namespace": int,
            "direct_external": int,
            "transitive_in_namespace": int
          }
        },
        ...
      ]
    }

  Arrays are sorted lexicographically and deduplicated before
  serialization specifically so that two independent runs against
  the same environment produce byte-identical JSON, and so a diff
  between baseline and mutant reflects only genuine dependency
  changes, never nondeterministic traversal order.

  Axiom footprints are intentionally NOT included in this schema.
  They are obtained separately via `#print axioms` and recorded in a
  parallel document; conflating the two here would blur the
  distinction this project's theory paper insists on, between a
  declaration's constant-dependency graph and its trust base.
-/

import AdmissibilityTransitionSystem
import Lean
import Lean.Data.Json

open Lean Elab Meta Command

def directDeps (env : Environment) (n : Name) : Array Name :=
  match env.find? n with
  | some ci =>
      match ci.value? with
      | some e => e.getUsedConstants
      | none => #[]
  | none => #[]

partial def transitiveDeps (env : Environment) (n : Name) : List Name :=
  let rec go (frontier : List Name) (visited : List Name) : List Name :=
    match frontier with
    | [] => visited
    | m :: rest =>
      if visited.contains m then go rest visited
      else
        let visited' := m :: visited
        let deps := (directDeps env m).toList
        go (deps ++ rest) visited'
  go [n] []

def inNamespace (ns : Name) (ns' : List Name) : List Name :=
  ns'.filter (fun n => ns.isPrefixOf n)

/-- Sort and deduplicate a name list by its string form, so JSON
    output is deterministic across runs regardless of traversal
    order. -/
def sortedDedupStrs (ns : List Name) : List String :=
  let strs := (ns.map toString).eraseDups
  (strs.toArray.qsort (fun a b => a < b)).toList

def targets : List Name := [
  `AdmissibilityTransitionSystem.step_preserves_adm,
  `AdmissibilityTransitionSystem.reach_preserves_adm,
  `AdmissibilityTransitionSystem.global_admissibility,
  `AdmissibilityTransitionSystem.local_step_preserves_other_fibers,
  `AdmissibilityTransitionSystem.local_step_changes_own_fiber,
  `AdmissibilityTransitionSystem.fiber_invariant_under_avoidance
]

def theoremJson (env : Environment) (ns : Name) (t : Name) : Json :=
  let dd_all := (directDeps env t).toList
  let dd_local := sortedDedupStrs (inNamespace ns dd_all)
  let dd_external := sortedDedupStrs (dd_all.filter (fun n => !(ns.isPrefixOf n)))
  let td_local := sortedDedupStrs (inNamespace ns (transitiveDeps env t))
  Json.mkObj [
    ("name", Json.str (toString t)),
    ("direct_in_namespace", Json.arr (dd_local.map Json.str).toArray),
    ("direct_external", Json.arr (dd_external.map Json.str).toArray),
    ("transitive_in_namespace", Json.arr (td_local.map Json.str).toArray),
    ("counts", Json.mkObj [
      ("direct_in_namespace", Json.num dd_local.length),
      ("direct_external", Json.num dd_external.length),
      ("transitive_in_namespace", Json.num td_local.length)
    ])
  ]

#eval show CommandElabM Unit from do
  let env ← getEnv
  let ns := `AdmissibilityTransitionSystem
  let theoremDocs := targets.map (theoremJson env ns)
  let doc := Json.mkObj [
    ("schema_version", Json.str "1.0"),
    ("lean_version", Json.str (toString Lean.versionString)),
    ("specimen_module", Json.str "AdmissibilityTransitionSystem"),
    ("generated_from", Json.str "baseline"),
    ("theorems", Json.arr theoremDocs.toArray)
  ]
  IO.println doc.pretty
