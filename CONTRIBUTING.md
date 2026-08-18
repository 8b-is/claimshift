# Contributing to Claimshift

Thank you for your interest in contributing to Claimshift! This document provides guidelines for contributing to the research artifacts, mutation testing framework, and protocol implementation.

## 🎯 Project Scope

Claimshift is a research project focused on:

1. **Formal verification inheritance** theory and implementation
2. **Mutation testing** for verification systems
3. **Manifest protocol** for scholarly artifact provenance

Contributions should align with these research goals.

## 🚀 Getting Started

### Prerequisites

- **Lean 4.10.0** (or specified version in verification logs)
- **Git** for version control
- **LaTeX** (optional, for paper contributions)
- Familiarity with formal verification or mutation testing concepts

### Development Setup

```bash
# Clone the repository
git clone https://github.com/8b-is/claimshift.git
cd claimshift

# Verify baseline artifact
lean AdmissibilityTransitionSystem.lean

# Expected: exit code 0, zero errors, zero sorry
```

## 📋 Contribution Types

### 1. Mutation Testing Extensions

**New Mutants**

If proposing new mutants for the mutation matrix:

1. **Preregister** ground truth (`G_m`) BEFORE implementation
2. Justify the mutation class and predicted propagation pattern
3. Document expected failure sets
4. Add to `paper3-audit/mutation-matrix.md`

**Guidelines**:
- Never measure before preregistering
- Each mutant must isolate a specific phenomenon
- Provide rationale for flagship vs. non-flagship designation

### 2. Formal Verification Artifacts

**New Theorems or Lemmas**

When adding to the Lean artifact:

1. **Zero sorry** — All proofs must be complete
2. **Minimal axioms** — Use only Lean core (no Mathlib unless justified)
3. **Document dependencies** — Update dependency audit
4. **Kernel verification** — Must exit 0 with `lean <file>.lean`

**Proof Style**:
- Prefer `cases` over tactics requiring Mathlib
- Use explicit term-mode proofs for core lemmas
- Comment non-obvious proof strategies (sparingly)

### 3. Protocol Implementation

**Code Contributions**

For manifest protocol implementation:

1. **Role separation** — Respect assert/verify/transform-attest boundaries
2. **Three-valued logic** — Never conflate `OUTSIDE_FRAGMENT` with negative
3. **Test coverage** — Include tests for failure cases
4. **Documentation** — Docstrings for all public APIs

**Code Style**:
- Follow standard conventions for the language (Rust, Python, etc.)
- Include type annotations where applicable
- Write self-documenting code; comment "why", not "what"

### 4. Documentation

**Research Papers**

- LaTeX source must compile cleanly
- Use consistent notation across papers
- Cite related work appropriately

**Technical Docs**

- Markdown for READMEs, guides, and specifications
- Use clear headings and examples
- Keep language precise but accessible

### 5. Tooling and Infrastructure

**CLI Tools, Scripts, Automation**

- Make tools idempotent where possible
- Provide `--help` and usage examples
- Error messages should guide users to solutions

## 🔬 Research Discipline

### Frozen Artifacts

The baseline verification artifact (`AdmissibilityTransitionSystem.lean`) is **frozen** for Paper III. Modifications require:

1. New branch with clear naming (e.g., `extension-fiber-composition`)
2. Justification for unfreezing
3. Re-verification of entire dependency chain
4. Documentation of changes from baseline

### Preregistration Protocol

For mutation testing work:

1. **Ground truth first** — Declare `G_m` before measuring `O_m`, `F_m`, `R_m`
2. **No retroactive edits** — Ground truth predictions are immutable once committed
3. **Document surprises** — Mismatches between prediction and observation are scientifically valuable

### Verification Integrity

All verification claims must be:

- **Kernel-checkable** — No `sorry`, no untrusted axioms beyond core
- **Reproducible** — Include exact toolchain version in logs
- **Transparent** — `#print axioms` for all theorems

## 🛠️ Pull Request Process

### Before Submitting

1. **Run verification checks**:
   ```bash
   lean AdmissibilityTransitionSystem.lean  # Must exit 0
   ```

2. **Update documentation** if adding features or changing behavior

3. **Add tests** for new functionality

4. **Check for conflicts** with frozen artifacts

### PR Guidelines

**Title**: Concise description (e.g., "Add mutant M21: quantifier scope narrowing")

**Description**:
- What: Summary of changes
- Why: Motivation and context
- How: Implementation approach
- Testing: Verification steps taken

**Commits**:
- Atomic, logical commits
- Clear commit messages
- Sign commits if possible

### Review Process

1. **Automated checks**: Lean verification, linting
2. **Peer review**: At least one maintainer approval
3. **Research alignment**: Contribution fits project scope
4. **Documentation**: Changes are documented

## 🐛 Reporting Issues

### Bug Reports

Include:
- **Lean version** (`lean --version`)
- **Minimal reproduction** (smallest artifact exhibiting the issue)
- **Expected vs. actual behavior**
- **Verification logs** if applicable

### Feature Requests

Describe:
- **Use case**: What problem does this solve?
- **Proposed solution**: How should it work?
- **Alternatives considered**: Other approaches evaluated
- **Research alignment**: How does this advance the project goals?

## 💬 Communication

### Channels

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: Design questions, research ideas
- **Pull Requests**: Code and documentation contributions

### Response Times

This is a research project. Expect:
- **Issue acknowledgment**: Within 1 week
- **PR review**: Within 2 weeks
- **Research discussion**: Ongoing, as schedules permit

## 📜 Code of Conduct

### Scholarly Norms

- **Intellectual honesty**: Never fabricate data or results
- **Attribution**: Credit prior work and collaborators
- **Reproducibility**: Share artifacts needed to verify claims
- **Respectful discourse**: Critique ideas, not people

### Technical Norms

- **No breaking changes** without major version bump
- **Backward compatibility** for protocol specifications
- **Security**: Report vulnerabilities privately before disclosure

## 🏆 Recognition

Contributors will be:
- Listed in `CONTRIBUTORS.md`
- Acknowledged in research papers where appropriate
- Credited in release notes

Significant contributions may merit co-authorship on research papers (discussed case-by-case).

## 📚 Additional Resources

- [README.md](README.md) — Project overview
- [ROADMAP.md](ROADMAP.md) — Development timeline
- `paper3-audit/mutation-matrix.md` — Mutation testing protocol
- Research papers in repository root

## 🤝 Collaboration

Interested in deeper collaboration?

- **Research partnerships**: Open an issue tagged `collaboration`
- **Grant proposals**: Contact maintainers via GitHub
- **Academic credit**: Discuss co-authorship or acknowledgments early

## ❓ Questions?

If anything is unclear:

1. Check existing documentation
2. Search closed issues for similar questions
3. Open a new issue tagged `question`

We're here to help!

---

**Thank you for contributing to verification inheritance research!**

*Last updated: August 18, 2026*
