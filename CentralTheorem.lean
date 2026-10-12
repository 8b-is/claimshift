/-
  Central Theorem (Epistemic Overlap)
  ====================================

  Companion of the frozen mathematical specimen
  (AdmissibilityTransitionSystem.lean, the Paper III mutation audit —
  which this file does not touch). This is the generalization lane: the
  combinatorial core of the Central Theorem, the no-safe-action
  corollary, and the minimal-history premise, as the operational
  skeleton of the engine's zone-keeper admissibility kernel.

  Source: standardgalactic/alphabet, central-theorem/ (SPEC.md +
  theorem.tex, branch central-theorem, PR #13).

  MANIFEST: CT-000 (both directions, and the iff), CT-000+
            (No-Safe-Action), CT-015 (minimal-history premise)

  Design constraints:
    * No Mathlib. Lean 4.10.0 core only, no lakefile — the same
      discipline as the specimen. Admissibility is carried as a
      predicate (W -> A -> Prop), not a Set.
    * Grounded in the claim set: an action is admissible in a world iff
      it is a continuation of that world's attested history
      (CT-001), independent of any valuation of the outcome; the
      epistemic overlap relation is the kernel of the observation map.
    * Axiom policy: the backward direction, the No-Safe-Action
      corollary, and the projection lemma carry no axioms. The forward
      direction requires selecting one common admissible action per
      observation class — in the operational regime (finite worlds,
      finite action vocabulary) that selection is a decidable finite
      search, implemented constructively in the engine
      (crates/admissibility::guaranteeing_policy); the kernel proof
      uses Classical.choice here. Footprints are recorded per theorem
      in CentralTheorem_VERIFICATION.txt.
    * The entropic side (Pillar III, RSVP: the No-Go for Safe Virality
      and its renormalization form) is deliberately NOT formalized
      here: field analysis is out of Lean-core scope. It stays
      proven in the monograph.
-/

namespace CentralTheorem

/-- CT-000, forward direction: if every observation class carries a
    common admissible action, a policy that guarantees an admissible
    global action exists. The choice is per class; `Classical.choice`
    is the only principle used, and it is vacuous when observations
    and actions are finite. -/
theorem epistemic_overlap_forward
    {W O A : Type u} {obs : W → O} {adm : W → A → Prop}
    (h : ∀ o : O, ∃ a : A, ∀ w : W, obs w = o → adm w a) :
    ∃ π : O → A, ∀ w : W, adm w (π (obs w)) := by
  refine ⟨fun o => Classical.choose (h o), ?_⟩
  intro w
  exact Classical.choose_spec (h (obs w)) w rfl

/-- CT-000, backward direction: if a policy guarantees an admissible
    global action, then all epistemically indistinguishable worlds share
    a common admissible action — the policy's choice at the shared
    observation is that common element. No axioms. -/
theorem epistemic_overlap_backward
    {W O A : Type u} {obs : W → O} {adm : W → A → Prop}
    (π : O → A) (h : ∀ w : W, adm w (π (obs w))) (w w' : W)
    (ho : obs w = obs w') :
    ∃ a : A, adm w a ∧ adm w' a := by
  exact ⟨π (obs w), h w, by rw [ho]; exact h w'⟩

/-- CT-000 as a single iff: a guaranteeing policy exists if and only
    if every epistemic overlap class carries a common admissible
    action. The forward direction is where (finite) choice enters; the
    backward direction is witnessed, not chosen. -/
theorem epistemic_overlap_iff
    {W O A : Type u} {obs : W → O} {adm : W → A → Prop} :
    (∃ π : O → A, ∀ w : W, adm w (π (obs w))) ↔
    (∀ o : O, ∃ a : A, ∀ w : W, obs w = o → adm w a) := by
  constructor
  · intro hp o
    obtain ⟨π, hπ⟩ := hp
    exact ⟨π o, fun w hw => by rw [← hw]; exact hπ w⟩
  · exact epistemic_overlap_forward

/-- CT-000+ (No-Safe-Action corollary): if some observation class
    blurs an admissibility-relevant distinction — two epistemically
    indistinguishable worlds whose admissible sets are disjoint — then
    no policy can guarantee an admissible global action. No axioms. -/
theorem no_safe_action
    {W O A : Type u} {obs : W → O} {adm : W → A → Prop}
    (h : ∃ w w' : W, obs w = obs w' ∧ ¬ ∃ a : A, adm w a ∧ adm w' a) :
    ¬ ∃ π : O → A, ∀ w : W, adm w (π (obs w)) := by
  obtain ⟨w, w', ho, hdisjoint⟩ := h
  intro hp
  obtain ⟨π, hπ⟩ := hp
  exact hdisjoint ⟨π (obs w), hπ w, by rw [ho]; exact hπ w'⟩

/-- CT-015 (minimal-history premise): the guarantee property is read
    through any factorization of admissibility. If a world's
    admissible actions depend only on its minimal decision-relevant
    prefix `p w` — admissibility factors through `p` — then a policy
    guarantees under the full admissible map if and only if it
    guarantees under the projected one. No axioms. -/
theorem ct015_prefix_projection
    {W P O A : Type u} {obs : W → O}
    {adm : W → A → Prop} {adm' : P → A → Prop}
    (p : W → P) (hfac : ∀ (w : W) (a : A), adm w a ↔ adm' (p w) a) :
    (∃ π : O → A, ∀ w : W, adm w (π (obs w))) ↔
    (∃ π : O → A, ∀ w : W, adm' (p w) (π (obs w))) := by
  constructor
  · rintro ⟨π, hπ⟩
    exact ⟨π, fun w => (hfac w _).mp (hπ w)⟩
  · rintro ⟨π, hπ⟩
    exact ⟨π, fun w => (hfac w _).mpr (hπ w)⟩

/-- Non-vacuity witness, no-safe-action side: a blurred observation
    class exists in the most degenerate case — two worlds
    indistinguishable under the available observation, each with its
    own admissible action, none admissible in both. No policy. -/
theorem no_safe_action_witness_example :
    ∃ (obs : Bool → Bool) (adm : Bool → Bool → Prop),
      obs true = obs false ∧
      (∃ a : Bool, adm true a) ∧ (∃ a : Bool, adm false a) ∧
      ¬ ∃ π : Bool → Bool, ∀ w : Bool, adm w (π (obs w)) := by
  refine ⟨(fun _ => true), fun w a => if w then a = true else a = false, ?_⟩
  constructor
  · rfl
  · constructor
    · exact ⟨true, rfl⟩
    · constructor
      · exact ⟨false, rfl⟩
      · rintro ⟨π, hπ⟩
        -- both worlds observe `true`, so both clauses pin `π true`
        have h1 : π true = true := by simpa using hπ true
        have h2 : π true = false := by simpa using hπ false
        have hbad : true = false := h1.symm.trans h2
        cases hbad

/-- Non-vacuity witness, overlap side: when the observation separates
    the worlds and every class overlaps, the guaranteeing policy exists
    and is explicit. -/
theorem common_action_witness_example :
    ∃ (obs : Bool → Bool) (adm : Bool → Bool → Prop),
      (∀ o : Bool, ∃ a : Bool, ∀ w : Bool, obs w = o → adm w a) ∧
      ∃ π : Bool → Bool, ∀ w : Bool, adm w (π (obs w)) := by
  refine ⟨(fun w => w), fun _ a => a = true, ?_⟩
  constructor
  · intro o
    exact ⟨true, fun _ _ => rfl⟩
  · exact ⟨fun _ => true, fun _ => rfl⟩

end CentralTheorem
