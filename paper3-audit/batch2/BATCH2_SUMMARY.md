# Paper III — Harness Batch 2 Results

All 9 remaining preregistered mutants (M02, M03, M04, M05, M06, M07,
M08, M14, M19) run against the frozen specimen with Lean 4.10.0. The
matrix is now complete: 20/20 mutants executed.

## O_m results

| ID | Predicted G_m | m ∈ T_R? | O_m | Matches prediction? |
|----|---------------|----------|-----|----------------------|
| M02 | equivalent | yes | **1** | yes |
| M03 | equivalent | yes | 0 | **no** — see finding below |
| M04 | equivalent | yes | **1** | yes |
| M05 | equivalent | yes | 0 | **no** — see finding below |
| M06 | equivalent | yes | **1** | yes |
| M07 | equivalent | yes | **1** | yes |
| M08 | equivalent | yes | **1** | yes |
| M14 | refuted | no | 0 | yes |
| M19 | weaker | no | 0 | yes (needed `Or.inl`, as predicted) |

## The important finding: M05

M05 was preregistered as `equivalent`, inside the certified rewrite
fragment $\mathcal{R}$ (associative normalization, rule (iii)). It
should be — and, checked separately below, *is* — logically
equivalent to the original. But $O_m = 0$: left-associating
`bindEffect`'s four-way conjunction breaks the original proof, because
a `cases`/pattern-match elsewhere in the file expected the default
right-associated shape and fails with `dependent elimination failed`
on the reshaped `And`.

This is not a bug in the theory. It's the theory papers' own
distinction, demonstrated for the first time with a real counterexample
rather than argued for in the abstract: **Theorem 2 (`PRESERVED` under
$\mathcal{R}$) is a claim about semantic correspondence, never a claim
that any specific existing proof term survives the transformation.**
`M05_is_equivalent` (`bindEffect_iff`, in `fresh_proofs.lean`) proves
the two forms of `bindEffect` are logically interchangeable, zero
`sorry`, no axioms at all. So M05 is simultaneously: correctly
`PRESERVED` by $\mathcal{R}$, and a genuine $O_m = 0$ case. Both are
true at once, and the matrix's binary "equivalent → predicted `O_m=1`"
shorthand from earlier batches was an oversimplification worth
correcting explicitly rather than quietly dropping.

## M03: a third instance of the M16 pattern

M03 (swap `step_preserves_adm`'s own argument order) broke for exactly
the same reason M16 did: `reach_preserves_adm`'s positional call
`step_preserves_adm _ _ ih hstep` now has `ih`/`hstep` in the wrong
slots. Confirmed via the typed-edge model's own vocabulary: this is an
`interface` dependency (a caller needing a specific signature shape),
not a `semantic` one — `step_preserves_adm_reordered` in
`fresh_proofs.lean` proves the reordered theorem is trivially still
true by simply calling the original with arguments un-swapped, zero
`sorry`, `[propext, Quot.sound]` only. Three of the twenty mutants
(M03, M16, and structurally M09's witness) have now independently hit
variants of "the semantic claim survives; a specific caller's
positional or definitional coupling does not" — this is no longer an
isolated surprise, it's a recurring category worth naming as such in
Paper III's discussion rather than three separate anecdotes.

## M14, M19: closed out with real proofs, not just failed compiles

- **M14**: `M14_mutant_is_false` in `fresh_proofs.lean` refutes the
  universal-quantified witness directly, using a simpler counterexample
  than the original non-vacuity witness (`.pop` applied to two
  `.closed` cells, where `LocalStep` fails outright since `applyLocal`
  is `False` there). Zero `sorry`, no axioms.
- **M19**: `fiber_invariant_under_avoidance_weakened` proves the
  `Or`-weakened conclusion trivially via `Or.inl`, confirming `F_m = 1`
  as predicted. Zero `sorry`, no axioms.

## Status: matrix complete, not yet the full four-way audit

All 20 mutants now have `O_m`. Six have real `G_m`-confirming proofs
beyond the preregistration (M05 equivalence, M03 fix, M14 refutation,
M15 refutation, M17 refutation, M19 fix) — the other 14 have `O_m`
data consistent with their preregistered prediction but no independent
proof of `G_m` beyond "the original proof still/no-longer compiles."
`R_m` (explicit $D_{\mathcal{R}}$ computation via a real normalizer)
has still not been built or run for any mutant; the eight T_R-fragment
mutants' `PRESERVED` status is asserted by the rewrite rules' design,
not independently verified by executing Theorem 2's normalization
procedure. No `G_Lean`/`G_manifest` cross-check, typed or otherwise,
has been run against any mutant — only against the untouched baseline.
