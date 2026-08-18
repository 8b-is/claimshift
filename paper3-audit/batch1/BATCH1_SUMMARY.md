# Paper III — Harness Batch 1 Results

Real Lean 4.10.0 kernel runs against 11 of the 20 preregistered
mutants (M01, M09-M13, M15-M18, M20). M02-M08, M14, M19 not yet run —
deferred to a later batch, not silently skipped.

For each mutant, `run_batch1.py` applied the exact edit from
`mutation-matrix.md` to a fresh copy of the frozen baseline, leaving
every proof body textually unchanged, and kernel-checked the result.
A compile failure means the *original* proof/tactic script no longer
closes the goal against the mutated statement — this is `O_m = 0`.
It does NOT by itself mean the mutated statement is false; two of the
flagship "refuted" predictions (M15, M17) were separately proven false
outright, below, precisely to keep that distinction honest.

## O_m results (original proof against mutated statement)

| ID | Predicted G_m | O_m (compiles) | Matches prediction? | Note |
|----|---------------|-----------------|----------------------|------|
| M01 | equivalent | **1** | yes | alpha-rename invisible to Lean, as expected |
| M09 | refuted | 0 | yes | breaks at `applyLocal_ne_bound` (`⊢ False`) — **and also breaks the M15-unrelated `local_step_changes_own_fiber` witness**, see finding below |
| M10 | unrelated (F_m=1 predicted) | **1** | yes | confirms the even/odd-parity insensitivity predicted in the matrix |
| M11 | unrelated | 0 | yes | breaks both branches — confirms D2-shared propagation |
| M12 | equivalent | **1** | yes | confirms the "too coarse to detect" case |
| M13 | weaker (unprovable predicted) | 0 | yes | breaks both branches, exact predicted mechanism: `hframe` no longer directly applicable as a function |
| M15 | refuted | 0 | partial | compile failure here is from the proof body still referencing the deleted `hf`, a shallower failure than a genuine falsity check — see the separate refutation below |
| M16 | weaker (trivially provable predicted) | 0 | **no** | prediction was wrong: the added hypothesis is harmless to `step_preserves_adm` itself, but breaks its *caller* `reach_preserves_adm`, whose call site is missing the new argument — a ripple effect the matrix didn't anticipate |
| M17 | refuted | 0 | yes | `omega`'s own error message named the exact counterexample shape (`boundCount x = 1`) independently confirmed below |
| M18 | weaker | 0 | yes | needs `Or.inl` wrapping, exactly as predicted, not yet applied |
| M20 | unrelated | 0 | yes | breaks only `reach_preserves_adm`/`global_admissibility`; `step_preserves_adm` compiles untouched — confirms the predicted mid-branch propagation pattern |

## Genuine falsity proofs (not just O_m failures)

Two mutants' predicted `refuted` status was upgraded from "the old
proof fails" to "the statement is kernel-verified false":

- **M15**: `¬(∀ g p x y f, LocalStep g p x y → piProj f x = piProj f y)`
  proved directly from the specimen's own `local_step_changes_own_fiber`
  witness. Zero `sorry`, axiom footprint `[propext]` only.
- **M17**: `¬(∀ x y, boundCount x ≤ 3 → Step x y → Adm y)` proved by
  exhibiting the concrete counterexample state
  (`boundCount x = 1 →`(Bind on the other two locations)`→ boundCount y = 3`)
  that `omega`'s own error message had already pointed at during the
  O_m run. Zero `sorry`, axiom footprint `[propext]` only.

Both in `mutants/refutations.lean`.

## Real finding not anticipated by the preregistration

**M09's declared "D1-only, leaves L3/T2 untouched" claim is partly
wrong.** The core L3 theorem (`local_step_preserves_other_fibers`) and
T2 (`fiber_invariant_under_avoidance`) are indeed untouched, exactly as
predicted, since neither references `applyLocal`. But
`local_step_changes_own_fiber` — the non-vacuity *witness* theorem,
conceptually adjacent to the L3/T2 branch — breaks too, because its
concrete example happens to use Pop as the witnessing primitive. This
is exactly the kind of gap the `G_declared` vs `G_Lean` cross-check
was designed to catch: the *declared* graph treats the witness as
belonging to branch two and independent of D1, but the *actual* Lean
dependency graph (confirmed via `DependencyAuditJson.lean` in the
earlier session) shows `local_step_changes_own_fiber`'s direct
dependencies do include `AdmissibilityTransitionSystem.applyLocal`,
`Prim.pop`, `Cell.empty`, `Cell.held` — visible in the baseline JSON
all along, just not cross-referenced against the declared graph until
this mutation exposed why it mattered.

## Also revised: M16's prediction

The matrix predicted M16 (add unused hypothesis to `step_preserves_adm`)
would be trivially still provable. The harness shows this is false as
stated: fixing it requires also updating `reach_preserves_adm`'s call
site (supplying a proof of the new hypothesis at the point where
`step_preserves_adm` is invoked inside the induction), which is a
substantive, not cosmetic, second-order change. Worth reclassifying in
the matrix from "trivially weaker" to "weaker, but with a caller-side
propagation cost" — a distinct pattern from anything else in the batch.

## Not yet done

- M02-M08 (the remaining T_R-fragment mutants), M14, M19: not run.
- F_m (fresh proof attempts) only completed for M15 and M17. M16 and
  M18 have known, described fixes not yet implemented and kernel-checked.
- R_m (explicit D_R computation via the certified rewrite fragment)
  not computed for any mutant in this batch; for M01-M08 it is asserted
  by design (alpha/AC/desugar rules) rather than independently verified
  by a normalizer.
- No G_Lean / G_manifest cross-check has been run against any mutant
  yet (only against the baseline, in the prior session).
