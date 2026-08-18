/-
  Dependency Audit Tool
  =====================

  Extracts, for a fixed list of target declarations, the direct and
  transitive constant-dependency graph (G_Lean) by walking each
  declaration's kernel-level proof/definition term via
  `ConstantInfo.value?` and `Expr.getUsedConstants`. This is below
  the tactic/elaboration layer: it audits what actually survived
  into the environment, not source text or tactic traces.

  This tool imports `AdmissibilityTransitionSystem` as a compiled
  module rather than duplicating its source, so the frozen specimen
  file itself is never touched by the audit apparatus.

  Usage protocol for Paper III (per the frozen mutation-testing
  design): run this tool once against the unmutated specimen and
  record its output as the baseline G_Lean. Every subsequent mutant
  is compared against that frozen baseline by diffing dependency
  edge sets, axiom sets, and kernel-check results — never by
  re-deriving "what changed" from a fresh extraction alone, since a
  fresh extraction cannot by itself distinguish "the original proof
  route still works" from "a different proof route was found."

  Axiom footprints are obtained separately via `#print axioms`
  (already validated manually against this specimen); this tool's
  contribution is the constant-level dependency graph, not the
  axiom set.
-/

import AdmissibilityTransitionSystem
import Lean

open Lean Elab Meta Command

/-- Direct constants referenced in a declaration's proof/definition
    term. Empty for axioms, opaques, and constructors/recursors that
    have no `value?`. -/
def directDeps (env : Environment) (n : Name) : Array Name :=
  match env.find? n with
  | some ci =>
      match ci.value? with
      | some e => e.getUsedConstants
      | none => #[]
  | none => #[]

/-- Transitive closure of constant dependencies, by breadth-first
    walk over `directDeps`. -/
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

/-- Restrict a dependency list to declarations inside a given
    namespace, filtering out core-library and instance-generated
    noise for the purposes of comparing against the declared graph
    (D1..T2) and the Paper II manifest's dependency edges. -/
def inNamespace (ns : Name) (ns' : List Name) : List Name :=
  ns'.filter (fun n => ns.isPrefixOf n)

/-- The six headline theorems whose dependency graph Paper III's
    audit tracks. Kept as an explicit, frozen list rather than
    discovered by scanning the environment, so the target set itself
    cannot silently drift between baseline and mutant runs. -/
def targets : List Name := [
  `AdmissibilityTransitionSystem.step_preserves_adm,
  `AdmissibilityTransitionSystem.reach_preserves_adm,
  `AdmissibilityTransitionSystem.global_admissibility,
  `AdmissibilityTransitionSystem.local_step_preserves_other_fibers,
  `AdmissibilityTransitionSystem.local_step_changes_own_fiber,
  `AdmissibilityTransitionSystem.fiber_invariant_under_avoidance
]

#eval show CommandElabM Unit from do
  let env ← getEnv
  let ns := `AdmissibilityTransitionSystem
  for t in targets do
    let dd_all := (directDeps env t).toList
    let dd_local := inNamespace ns dd_all
    let dd_external := dd_all.filter (fun n => !(ns.isPrefixOf n))
    let td_local := inNamespace ns (transitiveDeps env t)
    IO.println s!"=== {t} ==="
    IO.println s!"direct, in-namespace ({dd_local.length}): {dd_local}"
    IO.println s!"direct, external ({dd_external.length}): {dd_external}"
    IO.println s!"transitive, in-namespace ({td_local.length}): {td_local}"
    IO.println ""
