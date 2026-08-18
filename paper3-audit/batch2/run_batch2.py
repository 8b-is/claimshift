#!/usr/bin/env python3
import subprocess, os, json

BASELINE = open("baseline.lean").read()
LEAN_BIN = "/home/claude/lean410/lean-4.10.0-linux/bin/lean"
ENV = dict(os.environ)
ENV["LD_LIBRARY_PATH"] = "/home/claude/lean410/lean-4.10.0-linux/lib"

MUTANTS = [
    ("M02", "inductive Reach : X → X → Prop\n  | refl (x : X) : Reach x x\n  | tail {x y z : X} : Reach x y → Step y z → Reach x z",
     "inductive Reach : X → X → Prop\n  | refl (a : X) : Reach a a\n  | tail {a b c : X} : Reach a b → Step b c → Reach a c",
     "alpha-rename/variable substitution: Reach's implicit constructor binders x,y,z -> a,b,c"),

    ("M03", "theorem step_preserves_adm (x y : X) (h : Adm x) (hs : Step x y) :\n    Adm y := by",
     "theorem step_preserves_adm (x y : X) (hs : Step x y) (h : Adm x) :\n    Adm y := by",
     "commutative reordering: swap step_preserves_adm's own hypothesis argument order (tests whether positional callers break)"),

    ("M04", "def bindEffect (c1 c2 c1' c2' : Cell) : Prop :=\n  c1 = .held ∧ c2 = .held ∧ c1' = .bound ∧ c2' = .bound",
     "def bindEffect (c1 c2 c1' c2' : Cell) : Prop :=\n  c2 = .held ∧ c1 = .held ∧ c2' = .bound ∧ c1' = .bound",
     "commutative reordering: reorder bindEffect's conjuncts"),

    ("M05", "def bindEffect (c1 c2 c1' c2' : Cell) : Prop :=\n  c1 = .held ∧ c2 = .held ∧ c1' = .bound ∧ c2' = .bound",
     "def bindEffect (c1 c2 c1' c2' : Cell) : Prop :=\n  ((c1 = .held ∧ c2 = .held) ∧ c1' = .bound) ∧ c2' = .bound",
     "associative normalization: left-associate bindEffect's 4-way conjunction"),

    ("M06", "theorem local_step_preserves_other_fibers\n    (g : Loc) (p : Prim) (x y : X) (f : Loc) (hf : f ≠ g)\n    (h : LocalStep g p x y) : piProj f x = piProj f y := by",
     "theorem local_step_preserves_other_fibers\n    (g : Loc) (p : Prim) (x y : X) (f : Loc) (hf : ¬(f = g))\n    (h : LocalStep g p x y) : piProj f x = piProj f y := by",
     "syntactic desugaring: unfold Ne (f != g) to its definition not(f=g)"),

    ("M07", "theorem step_preserves_adm (x y : X) (h : Adm x) (hs : Step x y) :\n    Adm y := by",
     "theorem step_preserves_adm (x y : X) (h : boundCount x % 2 = 0) (hs : Step x y) :\n    Adm y := by",
     "syntactic desugaring: inline Adm's definition in step_preserves_adm's signature"),

    ("M08", "theorem fiber_invariant_under_avoidance\n    (f : Loc) (x y : X) (h : ReachAvoiding f x y) :\n    piProj f x = piProj f y := by\n  induction h with\n  | refl => rfl\n  | tail _hreach hstep hne ih =>\n      exact ih.trans (local_step_preserves_other_fibers _ _ _ _ _ hne.symm hstep)",
     "theorem fiber_invariant_under_avoidance\n    (loc : Loc) (x y : X) (h : ReachAvoiding loc x y) :\n    piProj loc x = piProj loc y := by\n  induction h with\n  | refl => rfl\n  | tail _hreach hstep hne ih =>\n      exact ih.trans (local_step_preserves_other_fibers _ _ _ _ _ hne.symm hstep)",
     "variable substitution: rename parameter f -> loc throughout fiber_invariant_under_avoidance"),

    ("M14", "theorem local_step_changes_own_fiber :\n    ∃ (g : Loc) (p : Prim) (x y : X),\n      LocalStep g p x y ∧ piProj g x ≠ piProj g y := by",
     "theorem local_step_changes_own_fiber :\n    ∀ (g : Loc) (p : Prim) (x y : X),\n      LocalStep g p x y ∧ piProj g x ≠ piProj g y := by",
     "quantifier mutation: turn the non-vacuity witness's exists into a forall (should be refuted)"),

    ("M19", "theorem fiber_invariant_under_avoidance\n    (f : Loc) (x y : X) (h : ReachAvoiding f x y) :\n    piProj f x = piProj f y := by",
     "theorem fiber_invariant_under_avoidance\n    (f : Loc) (x y : X) (h : ReachAvoiding f x y) :\n    piProj f x = piProj f y ∨ piProj f x = Cell.closed := by",
     "conclusion mutation: weaken T2's conclusion with an Or clause"),
]

def run_mutant(mid, old, new, note):
    n = BASELINE.count(old)
    assert n == 1, f"{mid}: old_str matched {n} times, need exactly 1"
    mutant_src = BASELINE.replace(old, new)
    fname = f"mutant_{mid}.lean"
    with open(fname, "w") as f:
        f.write(mutant_src)
    proc = subprocess.run([LEAN_BIN, fname], capture_output=True, text=True, env=ENV, timeout=120)
    ok = (proc.returncode == 0) and ("error" not in proc.stdout)
    return {
        "id": mid, "note": note,
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
    print(f"{mid}: O_m={r.get('O_m_compiles_with_original_proof', 'ERROR: ' + str(r.get('error')))} — {note}")

with open("harness_results_batch2.json", "w") as f:
    json.dump(results, f, indent=2)
