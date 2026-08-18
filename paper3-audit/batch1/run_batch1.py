#!/usr/bin/env python3
"""
Paper III mutation harness — batch runner.

For each mutant: apply the exact edit to a fresh copy of the frozen
baseline, compile with the real Lean 4.10.0 kernel (proof bodies left
untouched, so a compile failure means the ORIGINAL proof term no longer
typechecks against the mutated statement/definition -- this measures
O_m), and record the result. This does not re-derive ground truth; it
only measures against what was preregistered in mutation-matrix.md.
"""
import subprocess, os, json, sys

BASELINE = open("baseline.lean").read()
LEAN_BIN = "/home/claude/lean410/lean-4.10.0-linux/bin/lean"
ENV = dict(os.environ)
ENV["LD_LIBRARY_PATH"] = "/home/claude/lean410/lean-4.10.0-linux/lib"

# Each mutant: (id, old_str, new_str, notes). old_str must be unique in baseline.lean.
MUTANTS = [
    ("M01", "def LocalStep (g : Loc) (p : Prim) (x y : X) : Prop :=\n  applyLocal p (x g) (y g) ∧ ∀ j, j ≠ g → y j = x j",
     "def LocalStep (g : Loc) (p : Prim) (x y : X) : Prop :=\n  applyLocal p (x g) (y g) ∧ ∀ k, k ≠ g → y k = x k",
     "alpha-rename bound var j -> k in LocalStep"),

    ("M09", ".pop,      .empty, .held   => True",
     ".pop,      .empty, .bound  => True",
     "constant mutation: Pop's target held -> bound (D1-only, should break L1/L2/T1, leave L3/T2 untouched)"),

    ("M10", "def Adm (x : X) : Prop := boundCount x % 2 = 0",
     "def Adm (x : X) : Prop := boundCount x % 2 = 1",
     "constant mutation: Adm even -> odd parity"),

    ("M11", "def LocalStep (g : Loc) (p : Prim) (x y : X) : Prop :=\n  applyLocal p (x g) (y g) ∧ ∀ j, j ≠ g → y j = x j",
     "def LocalStep (g : Loc) (p : Prim) (x y : X) : Prop :=\n  applyLocal p (x g) (y g) ∧ ∀ j, j ≠ g → y j ≠ x j",
     "relation-operator mutation: flip = to != in LocalStep frame clause (D2, should affect both branches)"),

    ("M12", ".refuse,   .held,  .empty  => True",
     ".refuse,   .empty, .held  => True",
     "relation-operator mutation: Refuse's case duplicates Pop's transition"),

    ("M13", "def LocalStep (g : Loc) (p : Prim) (x y : X) : Prop :=\n  applyLocal p (x g) (y g) ∧ ∀ j, j ≠ g → y j = x j",
     "def LocalStep (g : Loc) (p : Prim) (x y : X) : Prop :=\n  applyLocal p (x g) (y g) ∧ ∃ j, j ≠ g → y j = x j",
     "quantifier mutation: forall -> exists in LocalStep frame clause"),

    ("M15", "theorem local_step_preserves_other_fibers\n    (g : Loc) (p : Prim) (x y : X) (f : Loc) (hf : f ≠ g)\n    (h : LocalStep g p x y) : piProj f x = piProj f y := by",
     "theorem local_step_preserves_other_fibers\n    (g : Loc) (p : Prim) (x y : X) (f : Loc)\n    (h : LocalStep g p x y) : piProj f x = piProj f y := by",
     "hypothesis deletion: remove f != g from L3 (should be refuted by existing witness)"),

    ("M16", "theorem step_preserves_adm (x y : X) (h : Adm x) (hs : Step x y) :\n    Adm y := by",
     "theorem step_preserves_adm (x y : X) (h : Adm x) (hs : Step x y) (hx : x ≠ y) :\n    Adm y := by",
     "hypothesis strengthening: add unused x != y to step_preserves_adm"),

    ("M17", "theorem step_preserves_adm (x y : X) (h : Adm x) (hs : Step x y) :\n    Adm y := by",
     "theorem step_preserves_adm (x y : X) (h : boundCount x ≤ 3) (hs : Step x y) :\n    Adm y := by",
     "hypothesis weakening: Adm x -> boundCount x <= 3 (looks safe, should be refuted)"),

    ("M18", "theorem global_admissibility (x y : X) (h : Adm x) (hr : Reach x y) :\n    Adm y :=\n  reach_preserves_adm x y h hr",
     "theorem global_admissibility (x y : X) (h : Adm x) (hr : Reach x y) :\n    Adm y ∨ True :=\n  reach_preserves_adm x y h hr",
     "conclusion mutation: Adm y -> Adm y \\/ True (should still need adjustment, tests vacuity)"),

    ("M20", "inductive Reach : X → X → Prop\n  | refl (x : X) : Reach x x\n  | tail {x y z : X} : Reach x y → Step y z → Reach x z",
     "inductive Reach : X → X → Prop\n  | refl (x : X) : Reach x x\n  | tail {x y z : X} : Reach x y → Step z y → Reach x z",
     "definition mutation: flip Step y z -> Step z y in Reach.tail"),
]

def run_mutant(mid, old, new, note):
    assert BASELINE.count(old) == 1, f"{mid}: old_str not unique or not found ({BASELINE.count(old)} matches)"
    mutant_src = BASELINE.replace(old, new)
    fname = f"mutant_{mid}.lean"
    with open(fname, "w") as f:
        f.write(mutant_src)
    proc = subprocess.run([LEAN_BIN, fname], capture_output=True, text=True, env=ENV, timeout=120)
    ok = (proc.returncode == 0) and ("error" not in proc.stdout)
    return {
        "id": mid,
        "note": note,
        "O_m_compiles_with_original_proof": ok,
        "lean_exit_code": proc.returncode,
        "stdout_tail": proc.stdout[-1500:],
    }

results = []
for mid, old, new, note in MUTANTS:
    try:
        r = run_mutant(mid, old, new, note)
    except AssertionError as e:
        r = {"id": mid, "note": note, "error": str(e)}
    results.append(r)
    print(f"{mid}: O_m={r.get('O_m_compiles_with_original_proof')} — {note}")

with open("harness_results_batch1.json", "w") as f:
    json.dump(results, f, indent=2)
