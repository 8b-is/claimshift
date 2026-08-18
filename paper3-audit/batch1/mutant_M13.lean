/-
  Admissibility Transition System
  ================================

  Frozen mathematical specimen for Paper III, the mutation-testing
  companion to "Verification Inheritance Under Transformation" (Paper I)
  and "A Manifest Protocol for Verification Inheritance" (Paper II).

  Design constraints, fixed before mutation testing begins:
    * No Mathlib dependency. Only Lean 4 core.
    * Grounded in the confirmed Spherepop four-primitive grammar
      (Pop = Selection, Refuse = Exclusion, Bind = Coupling,
      Collapse = Projection), simplified to the minimum structure
      needed for a genuine, non-vacuous mutation target. This is a
      caricature of Spherepop's operator vocabulary and effects, not
      a formalization of the Spherepop kernel itself.
    * Asymmetric dependency graph, two branches sharing D2:

        D1, D2 -> L1 -> L2 -> T1     (global admissibility)
        D2, D3 -> L3 -> T2           (fiber non-interference)

      D1 = applyLocal / bindEffect (per-primitive local compatibility)
      D2 = Step (the global transition relation; its frame/locality
           clauses are what both branches depend on)
      D3 = piProj (the fiber projection)

  Status of Bind: this is NOT a formalization of Spherepop's Bind
  (Coupling) semantics. It is a pair-producing abstraction of Bind,
  sufficient to exercise the boundCount-parity invariant this
  specimen is built around, and no more. The claim under test is
  whether this abstraction preserves the dependency structure needed
  for the Paper III mutation experiment, not whether it is faithful
  to the full Spherepop kernel's operational semantics.
-/

namespace AdmissibilityTransitionSystem

/-- Three named locations ("fibers"), as a bespoke 3-constructor
    type rather than `Fin 3`, so case analysis stays plain `cases`
    with no Mathlib tactics. -/
inductive Loc where
  | l0 | l1 | l2
deriving DecidableEq, Repr

/-- Local state a single location can hold. `bound` only ever
    arises in coupled pairs, produced by Bind; `closed` is a
    terminal state produced by Collapse. -/
inductive Cell where
  | empty  : Cell
  | held   : Cell
  | bound  : Cell
  | closed : Cell
deriving DecidableEq, Repr

/-- The single-location primitives among the four confirmed
    Spherepop primitives. Bind (Coupling) is two-location and is
    handled separately by `bindEffect`. -/
inductive Prim where
  | pop | refuse | collapse
deriving DecidableEq, Repr

/-- A state is a function from location to cell. -/
def X := Loc → Cell

/-- D1 (local compatibility): the effect of a single-location
    primitive on one cell. Pop = Selection (empty to held),
    Refuse = Exclusion (held to empty), Collapse = Projection
    (held to closed). -/
def applyLocal : Prim → Cell → Cell → Prop
  | .pop,      .empty, .held   => True
  | .refuse,   .held,  .empty  => True
  | .collapse, .held,  .closed => True
  | _,         _,      _       => False

/-- D1 (local compatibility, coupling case): Bind = Coupling
    requires both locations to be `held`, and moves both to
    `bound` together, never one without the other. -/
def bindEffect (c1 c2 c1' c2' : Cell) : Prop :=
  c1 = .held ∧ c2 = .held ∧ c1' = .bound ∧ c2' = .bound

/-- A single-location step: primitive `p` fires at location `g`;
    every other location is left untouched. The frame condition
    is what branch two (fiber non-interference) depends on. -/
def LocalStep (g : Loc) (p : Prim) (x y : X) : Prop :=
  applyLocal p (x g) (y g) ∧ ∃ j, j ≠ g → y j = x j

/-- A two-location coupling step: Bind fires across distinct
    locations `i` and `j`; every other location is untouched. -/
def BindStep (i j : Loc) (x y : X) : Prop :=
  i ≠ j ∧ bindEffect (x i) (x j) (y i) (y j) ∧
    ∀ k, k ≠ i → k ≠ j → y k = x k

/-- D2 (the global transition relation): a step is either a
    single-location primitive application or a two-location Bind.
    Shared by both branches of the dependency graph. -/
def Step (x y : X) : Prop :=
  (∃ g p, LocalStep g p x y) ∨ (∃ i j, BindStep i j x y)

/-- Number of `bound` locations in a state, computed directly over
    the three fixed locations. -/
def boundCount (x : X) : Nat :=
  (if x .l0 = Cell.bound then 1 else 0) +
  (if x .l1 = Cell.bound then 1 else 0) +
  (if x .l2 = Cell.bound then 1 else 0)

/-- The admissibility invariant: bound locations always come in
    pairs, since only Bind ever produces them and it always
    produces exactly two at once. -/
def Adm (x : X) : Prop := boundCount x % 2 = 0

/-- Helper: if a single-location primitive relates cell states `a`
    and `b`, neither `a` nor `b` is `bound`. Used to show local
    steps never change a cell's contribution to `boundCount`. -/
theorem applyLocal_ne_bound {p : Prim} {a b : Cell}
    (h : applyLocal p a b) : a ≠ Cell.bound ∧ b ≠ Cell.bound := by
  cases p <;> cases a <;> cases b <;> simp_all [applyLocal]

/-- L1: a single step preserves admissibility.

    Dependencies: D1 (applyLocal / bindEffect) and D2 (Step, for the
    case split into LocalStep / BindStep). -/
theorem step_preserves_adm (x y : X) (h : Adm x) (hs : Step x y) :
    Adm y := by
  have hcount : boundCount x = boundCount y ∨ boundCount y = boundCount x + 2 := by
    rcases hs with ⟨g, p, hloc, hframe⟩ | ⟨i, j, hij, hbind, hframe⟩
    · left
      obtain ⟨hxg, hyg⟩ := applyLocal_ne_bound hloc
      cases g <;>
        simp_all [boundCount, ne_eq] <;>
        (first
          | (have h1 := hframe .l1 (by decide)
             have h2 := hframe .l2 (by decide)
             simp_all)
          | (have h0 := hframe .l0 (by decide)
             have h2 := hframe .l2 (by decide)
             simp_all)
          | (have h0 := hframe .l0 (by decide)
             have h1 := hframe .l1 (by decide)
             simp_all))
    · right
      obtain ⟨c1eq, c2eq, c1'eq, c2'eq⟩ := hbind
      cases i <;> cases j <;>
        simp_all [boundCount, ne_eq] <;>
        (first
          | (have hk := hframe .l2 (by decide) (by decide); simp_all; omega)
          | (have hk := hframe .l1 (by decide) (by decide); simp_all; omega)
          | (have hk := hframe .l0 (by decide) (by decide); simp_all; omega))
  unfold Adm at *
  rcases hcount with heq | heq
  · rw [← heq]; exact h
  · rw [heq]; omega

/-- Local reachability: the reflexive-transitive closure of `Step`,
    defined directly rather than imported from Mathlib. -/
inductive Reach : X → X → Prop
  | refl (x : X) : Reach x x
  | tail {x y z : X} : Reach x y → Step y z → Reach x z

/-- L2: admissibility is preserved along any finite sequence of
    steps. Mechanically downstream of L1 by induction on `Reach`. -/
theorem reach_preserves_adm (x y : X) (h : Adm x) (hr : Reach x y) :
    Adm y := by
  induction hr with
  | refl => exact h
  | tail _hreach hstep ih => exact step_preserves_adm _ _ ih hstep

/-- T1 (Global Admissibility Theorem): the headline result of
    branch one. Identical in content to `reach_preserves_adm`,
    named separately because it is the branch-one target Paper
    III's audit tracks. -/
theorem global_admissibility (x y : X) (h : Adm x) (hr : Reach x y) :
    Adm y :=
  reach_preserves_adm x y h hr

/-- D3: the fiber projection onto a named location. -/
def piProj (f : Loc) (x : X) : Cell := x f

/-- L3 (Non-interference lemma): a single-location step at `g`
    leaves every other fiber `f ≠ g` unchanged.

    Dependencies: D2 (Step / LocalStep's frame clause) and D3
    (piProj's definition). Deliberately independent of D1: the
    proof never inspects what `applyLocal` computes. -/
theorem local_step_preserves_other_fibers
    (g : Loc) (p : Prim) (x y : X) (f : Loc) (hf : f ≠ g)
    (h : LocalStep g p x y) : piProj f x = piProj f y := by
  obtain ⟨_, hframe⟩ := h
  exact (hframe f hf).symm

/-- Non-vacuity witness: the `f ≠ g` hypothesis above is load-
    bearing, because a concrete local step does change its own
    fiber. Without this theorem, `local_step_preserves_other_fibers`
    could hold only because no local step ever changes anything. -/
theorem local_step_changes_own_fiber :
    ∃ (g : Loc) (p : Prim) (x y : X),
      LocalStep g p x y ∧ piProj g x ≠ piProj g y := by
  refine ⟨.l0, .pop, fun _ => Cell.empty,
    fun j => if j = .l0 then Cell.held else Cell.empty, ?_, ?_⟩
  · constructor
    · simp [applyLocal]
    · intro j hj
      cases j <;> simp_all
  · simp [piProj]

/-- Reachability restricted to single-location steps that never
    touch a designated fiber `f`. -/
inductive ReachAvoiding (f : Loc) : X → X → Prop
  | refl (x : X) : ReachAvoiding f x x
  | tail {x y z : X} {g : Loc} {p : Prim} :
      ReachAvoiding f x y → LocalStep g p y z → g ≠ f →
      ReachAvoiding f x z

/-- T2 (Non-Interference / Conservation Theorem): fiber `f` is
    invariant along any finite sequence of local steps that never
    fire at `f`. Mechanically downstream of L3 by induction on
    `ReachAvoiding`, mirroring L2's structure on the other branch. -/
theorem fiber_invariant_under_avoidance
    (f : Loc) (x y : X) (h : ReachAvoiding f x y) :
    piProj f x = piProj f y := by
  induction h with
  | refl => rfl
  | tail _hreach hstep hne ih =>
      exact ih.trans (local_step_preserves_other_fibers _ _ _ _ _ hne.symm hstep)

end AdmissibilityTransitionSystem
