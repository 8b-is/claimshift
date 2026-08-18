# Paper III — Preregistered Mutation Matrix

Preregistered before any mutant `.lean` file is written or run, per the
frozen protocol: ground truth `G_m` is declared here first, then the
harness measures `O_m`, `F_m`, `R_m` against it — never the reverse.

Baseline artifact: `AdmissibilityTransitionSystem.lean` (kernel-verified,
frozen). `T_R` = the certified rewrite fragment from Paper I Example 1:
(i) alpha-renaming, (ii) AC-reordering of conjuncts/disjuncts,
(iii) double-negation elimination, (iv) syntactic-sugar unfolding.

## One addition to the ground-truth vocabulary before using it

The vocabulary fixed earlier — `{equivalent, stronger, weaker,
incompatible, unrelated}` — has no label for a mutant that is simply
**false**, as opposed to *incompatible* (which was specifically defined
as contradicting the *original* claim). Several mutants below are false
on their own terms, independent of the original theorem. Adding:

- **refuted**: `P_m` is false (has a countermodel / kernel-checkable
  counterexample), regardless of its logical relationship to `P`.

`refuted` and `incompatible` can co-occur (a mutant can be both false and
contradictory with the original) but are recorded as separate facts.

## Matrix

| ID | Operator class | Target | Edit | m ∈ T_R? | G_m | Rationale |
|----|----------------|--------|------|----------|-----|-----------|
| M01 | alpha-renaming | `LocalStep` | rename bound `j` → `k` throughout | yes | equivalent | pure bound-variable rename, rule (i) |
| M02 | alpha-renaming | `step_preserves_adm` | rename top-level parameter `x` → `s` | yes | equivalent | parameter rename, rule (i) extended to declaration binders |
| M03 | commutative reordering | `step_preserves_adm` | swap hypothesis argument order `(h : Adm x) (hs : Step x y)` → `(hs : Step x y) (h : Adm x)` | yes | equivalent | curried-argument reordering, rule (ii) |
| M04 | commutative reordering | `bindEffect` | reorder conjuncts `c1=held∧c2=held∧c1'=bound∧c2'=bound` → `c2=held∧c1=held∧c2'=bound∧c1'=bound` | yes | equivalent | AC-reordering, rule (ii) |
| M05 | associative normalization | `bindEffect` | re-parenthesize the 4-way conjunction | yes | equivalent | rule (iii)/(ii) combined, associativity |
| M06 | syntactic desugaring | `local_step_preserves_other_fibers` | unfold `Ne` in `(hf : f ≠ g)` to `¬(f = g)` | yes | equivalent | rule (iv), sugar unfolding |
| M07 | syntactic desugaring | `step_preserves_adm` | inline `Adm x` to `boundCount x % 2 = 0` | yes | equivalent | rule (iv) |
| M08 | variable substitution | `fiber_invariant_under_avoidance` | rename parameter `f` → `loc` throughout | yes | equivalent | same as M02, different declaration |
| **M09** | constant mutation | `applyLocal` | Pop's target `.held` → `.bound` (`.pop, .empty, .bound => True`) | no | **refuted** | breaks boundCount-parity invariant directly; **flagship D1-only mutant** — predicts L1/L2/T1 fail, L3/T2 completely untouched (D1 not in their dependency chain) |
| M10 | constant mutation | `Adm` | `% 2 = 0` → `% 2 = 1` | no | unrelated | subtle: both Adm-even and Adm-odd are preserved by the *same* steps (which only ever change boundCount by 0 or +2, preserving *either* parity) — predicts `F_m = 1` via a near-identical proof despite `G_m ≠ equivalent`; a clean instance of "reprovability is not verification inheritance" |
| M11 | relation-operator mutation | `LocalStep` | flip `y j = x j` → `y j ≠ x j` in the frame clause | no | unrelated | D2 mutation — predicted to affect **both** branches, since Step/LocalStep is the shared node |
| M12 | relation-operator mutation | `applyLocal` | Refuse's case → `.refuse, .empty, .held => True` (duplicates Pop's transition under Refuse's label) | no | equivalent *(for L1's provability only)* | semantically changes what Refuse means, but boundCount-parity argument is insensitive to *which* non-bound↔non-bound transition occurs — predicted L1/L2/T1 still provable unchanged; flagged as a case where the chosen invariant is too coarse to detect a real semantic change |
| M13 | quantifier mutation | `LocalStep` | frame clause `∀ j, j≠g → y j=x j` → `∃ j, j≠g → y j=x j` | no | weaker *(as a standalone proposition)* | D2 mutation; weakening a clause that appears as a *hypothesis* elsewhere makes downstream proofs *harder*, not easier — predicts L3 becomes unprovable (can't extract the needed instance for a specific given `f`) despite the clause itself being logically weaker |
| M14 | quantifier mutation | `local_step_changes_own_fiber` | outer `∃ (g p x y), ...` → `∀ (g p x y), ...` | no | **refuted** | turns a witness existential into a universal claim, false for any `g,p,x,y` with no `LocalStep` relation at all; second flagship "genuinely consequential" case, targeting the non-vacuity witness itself |
| **M15** | hypothesis deletion | `local_step_preserves_other_fibers` | delete `(hf : f ≠ g)` entirely | no | **refuted** | directly falsified by the already-proved `local_step_changes_own_fiber` witness — the specimen already carries its own kernel-checked kill for this mutant, per the design goal from a few sessions back |
| M16 | hypothesis strengthening | `step_preserves_adm` | add unused hypothesis `(hx : x ≠ y)` | no | weaker | adding a hypothesis weakens the implication (strictly implied by original) — predicts trivially still provable, `F_m = 1` |
| **M17** | hypothesis weakening | `step_preserves_adm` | replace `Adm x` with `boundCount x ≤ 3` (always true given 3 locations) | no | **refuted** | looks like a harmless generalization (every `x` satisfies the new hypothesis) but is false: an `x` with `boundCount x = 1` satisfies the new hypothesis, and a `BindStep` takes it to `boundCount y = 3`, which fails `Adm y`; illustrates that "weakening a hypothesis" is not automatically safe even when the weaker hypothesis looks obviously true |
| M18 | conclusion mutation | `global_admissibility` | conclusion `Adm y` → `Adm y ∨ True` | no *(borderline; not literally one of the four listed rules)* | weaker | tautological conclusion makes the theorem vacuously provable regardless of hypotheses; flags a real gap in the ground-truth vocabulary — "weaker" doesn't distinguish a meaningful weakening from a vacuous one |
| M19 | conclusion mutation | `fiber_invariant_under_avoidance` | conclusion `piProj f x = piProj f y` → `... ∨ piProj f x = Cell.closed` | no | weaker | strictly implied by original via `Or.inl`; predicts trivially still provable |
| **M20** | definition mutation | `Reach` | `tail` constructor: `Step y z` → `Step z y` | no | unrelated | defines a structurally different relation; predicted to hit **only** L2/T1 (Reach is used starting at L2, not by L1, which uses `Step` directly) and to leave T2 untouched (its own `ReachAvoiding` is a separate inductive type) — a third, distinct propagation pattern: mid-branch rather than branch-root |

## Coverage check against the preregistered operator list

alpha-renaming (M01,M02) · commutative reordering (M03,M04) ·
associative normalization (M05) · syntactic desugaring (M06,M07) ·
variable substitution (M08) · constant mutation (M09,M10) ·
relation-operator mutation (M11,M12) · quantifier mutation (M13,M14) ·
hypothesis deletion (M15) · hypothesis strengthening (M16) / weakening
(M17) · conclusion mutation (M18,M19) · definition mutation (M20).

All twelve classes represented; three flagship mutants (M09, M15, M20)
each isolate a different propagation pattern (branch-root, existing
witness, mid-branch); M10, M12, M13, M17 are the deliberately
counter-intuitive cases worth foregrounding in the paper's results
table.

## Explicitly NOT yet done

No mutant `.lean` file has been written. No `O_m`/`F_m`/`R_m` has been
measured. This document is the frozen preregistration only; the harness
that actually applies these edits, kernel-checks each result, and
records the four-tuple is the next, separate phase.
