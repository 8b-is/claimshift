# R_m results across the 8 certified-fragment (T_R) mutants

No general-purpose symbolic normalizer (implementing Theorem 2's
alpha/AC/double-negation/desugaring rewrite rules abstractly, over
arbitrary claim syntax) was built. What exists instead is a complete,
per-mutant R_m certificate for all eight T_R mutants, obtained by two
different methods:

## Method 1 — definitional equality (strongest possible certificate)

For M01, M02, M04, M06, M07, M08: `O_m = 1`, meaning the *literal
original proof term* still typechecks against the mutated statement
without any change. In a dependently typed kernel this is only
possible if the original and mutated types are definitionally equal —
a strictly stronger fact than provable equivalence. These six mutants'
`R_m = PRESERVED` status is therefore witnessed by the kernel's own
defeq check during the batch 1/2 harness runs; no separate proof was
needed or would add anything beyond what `O_m = 1` already established.

## Method 2 — explicit proof of logical equivalence

For M03 and M05 (`O_m = 0`, but preregistered and confirmed
`equivalent`): `fresh_proofs.lean` contains direct, zero-`sorry`
proofs — `bindEffect_iff` (M05, propositional iff between the two
associativity groupings) and `step_preserves_adm_reordered` (M03, the
reordered theorem proved via the original with arguments un-swapped).
Both close with no axioms beyond the standard core set.

## What this does and doesn't establish

This gives real, certificate-backed `R_m = PRESERVED` for all eight
T_R mutants — stronger, in fact, than what a generic normalizer would
give for six of them (defeq beats provable-iff). It does NOT
constitute an implementation of Paper I's abstract Theorem 2 procedure
(compute normal forms via the rewrite system, compare) as a
general-purpose, claim-language-agnostic algorithm; that remains
unbuilt. The certificates here are specific to this specimen's eight
mutants, not a reusable decision procedure for arbitrary future
mutants in the same fragment.
