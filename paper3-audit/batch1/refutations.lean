import AdmissibilityTransitionSystem
open AdmissibilityTransitionSystem

-- M15: is the hypothesis-deleted version of L3 actually FALSE (not merely
-- unprovable by the old proof)? Prove its negation directly, reusing the
-- specimen's own non-vacuity witness.
theorem M15_mutant_is_false :
    ¬ (∀ (g : Loc) (p : Prim) (x y : X) (f : Loc),
        LocalStep g p x y → piProj f x = piProj f y) := by
  intro hbad
  obtain ⟨g, p, x, y, hstep, hne⟩ := local_step_changes_own_fiber
  exact hne (hbad g p x y g hstep)

-- M17: is the hypothesis-weakened version of L1 actually FALSE?
-- Exhibit the concrete counterexample omega's error message pointed at:
-- a state with boundCount = 1 (satisfies the new weaker hypothesis,
-- boundCount x <= 3) that a BindStep carries to boundCount = 3, which
-- fails the *original* Adm predicate (odd, not even).
def M17_x : X := fun j => match j with
  | .l0 => Cell.bound
  | .l1 => Cell.held
  | .l2 => Cell.held

def M17_y : X := fun j => match j with
  | .l0 => Cell.bound
  | .l1 => Cell.bound
  | .l2 => Cell.bound

theorem M17_mutant_is_false :
    ¬ (∀ (x y : X), boundCount x ≤ 3 → Step x y → Adm y) := by
  intro hbad
  have hcount3 : boundCount M17_x ≤ 3 := by decide
  have hstep : Step M17_x M17_y := by
    right
    refine ⟨.l1, .l2, ?_, ?_, ?_⟩
    · decide
    · exact ⟨rfl, rfl, rfl, rfl⟩
    · intro k hk1 hk2; cases k <;> simp_all [M17_x, M17_y]
  have := hbad M17_x M17_y hcount3 hstep
  unfold Adm boundCount at this
  simp [M17_y] at this

#print axioms M15_mutant_is_false
#print axioms M17_mutant_is_false
