import AdmissibilityTransitionSystem
open AdmissibilityTransitionSystem

-- M05: confirm the left-associated bindEffect is still logically equivalent
-- to the original (Theorem 2's guarantee) by proving the mutated
-- step_preserves_adm fresh, with a proof adapted to the new grouping.
def bindEffect' (c1 c2 c1' c2' : Cell) : Prop :=
  ((c1 = .held ∧ c2 = .held) ∧ c1' = .bound) ∧ c2' = .bound

theorem bindEffect_iff (c1 c2 c1' c2' : Cell) :
    bindEffect' c1 c2 c1' c2' ↔ bindEffect c1 c2 c1' c2' := by
  unfold bindEffect' bindEffect
  constructor
  · rintro ⟨⟨⟨h1,h2⟩,h3⟩,h4⟩; exact ⟨h1,h2,h3,h4⟩
  · rintro ⟨h1,h2,h3,h4⟩; exact ⟨⟨⟨h1,h2⟩,h3⟩,h4⟩

-- M03: confirm swapping step_preserves_adm's own argument order is
-- still logically the same theorem, fixed at the call site.
theorem step_preserves_adm_reordered (x y : X) (hs : Step x y) (h : Adm x) :
    Adm y := step_preserves_adm x y h hs

-- M14: the non-vacuity witness turned into a universal claim is false --
-- refute it directly (not merely "old proof fails").
theorem M14_mutant_is_false :
    ¬ (∀ (g : Loc) (p : Prim) (x y : X),
        LocalStep g p x y ∧ piProj g x ≠ piProj g y) := by
  intro hbad
  -- instantiate at a case where NO LocalStep relation holds at all:
  -- g := l0, p := pop, x := fun _ => Cell.closed, y := fun _ => Cell.closed
  -- applyLocal .pop .closed .closed is False, so LocalStep fails outright.
  have h := hbad .l0 .pop (fun _ => Cell.closed) (fun _ => Cell.closed)
  obtain ⟨⟨happly, _⟩, _⟩ := h
  simp [applyLocal] at happly

-- M19: confirm T2's Or-weakened conclusion is trivially still provable.
theorem fiber_invariant_under_avoidance_weakened
    (f : Loc) (x y : X) (h : ReachAvoiding f x y) :
    piProj f x = piProj f y ∨ piProj f x = Cell.closed :=
  Or.inl (fiber_invariant_under_avoidance f x y h)

#print axioms bindEffect_iff
#print axioms step_preserves_adm_reordered
#print axioms M14_mutant_is_false
#print axioms fiber_invariant_under_avoidance_weakened
