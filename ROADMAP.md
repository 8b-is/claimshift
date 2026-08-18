# Claimshift Roadmap

**Research and development timeline for verification inheritance infrastructure**

## Current Phase: Paper III Experimental (August 2026)

### ✅ Completed

- [x] Frozen baseline artifact (`AdmissibilityTransitionSystem.lean`)
- [x] Kernel verification (exit 0, zero sorry)
- [x] Dependency audit infrastructure (`DependencyAuditTyped.lean`)
- [x] Baseline typed edge graph (JSON serialization)
- [x] **Preregistered mutation matrix** (20 mutants, ground truth predictions)
- [x] Flagship mutant identification (M09, M15, M20)
- [x] Paper I: Theory and undecidability results
- [x] Paper II: Manifest protocol specification

### 🚧 In Progress

- [ ] **Mutation harness implementation**
  - Automated mutant application from matrix specifications
  - Kernel-check runner with exit code capture
  - Failure set measurement (F_m)
  - Reprovability testing framework (R_m)
- [ ] **Mutant batch 1 execution** (M01-M10)
  - Certified rewrite fragment baseline (M01-M08)
  - Flagship D1-only mutation (M09)
  - Parity-flip reprovability case (M10)
- [ ] **Mutant batch 2 execution** (M11-M20)
  - Shared dependency mutations (M11, M13)
  - Self-refutation witness (M15)
  - Mid-branch propagation (M20)

### 📅 Next Steps (Q3 2026)

- [ ] Complete all 20 mutant measurements
- [ ] Validate ground truth predictions (G_m vs O_m analysis)
- [ ] Document prediction mismatches and their explanations
- [ ] Generate final results table for Paper III
- [ ] Write Paper III manuscript
- [ ] Submit Paper III for peer review

---

## Phase 2: Protocol Implementation (Q4 2026 - Q1 2027)

### Core Infrastructure

- [ ] **Manifest protocol reference implementation**
  - Claim record schema (JSON-LD or similar)
  - Verification record schema with role separation
  - Transformation attestation format
  - Append-only manifest storage
- [ ] **Robust locator system**
  - In-band commitment generation
  - Locator resolution and validation
  - Compatibility with existing watermarking (e.g., statistical, C2PA)
- [ ] **Policy layer**
  - Adjudicator registry
  - Claim-type-indexed authorization
  - Policy-qualified trust queries
- [ ] **Cryptographic substrate**
  - Signature verification (assert, verify, transform-attest roles)
  - Key management integration
  - Compatibility with Verifiable Credentials

### Integration Points

- [ ] **Lean 4 tooling integration**
  - Manifest generation from `#check` and `#print axioms`
  - Dependency graph extraction automation
  - Rewrite fragment certification hooks
- [ ] **Existing provenance systems**
  - PROV-O compatibility layer
  - Nanopublication mapping
  - W3C Verifiable Credentials support
- [ ] **Document formats**
  - PDF (via XMP metadata or annotations)
  - LaTeX (via custom packages)
  - Markdown (frontmatter extensions)
  - HTML (structured data annotations)

---

## Phase 3: Ecosystem & Tooling (Q2 2027 - Q4 2027)

### Developer Tools

- [ ] **CLI tool** for manifest operations
  - `claimshift init` — Initialize manifest for document
  - `claimshift verify` — Check verification inheritance
  - `claimshift attest` — Record transformation attestation
  - `claimshift query` — Policy-qualified trust queries
- [ ] **LSP integration** (Language Server Protocol)
  - Real-time verification status in editors
  - Dependency graph visualization
  - Transformation warnings for out-of-fragment edits
- [ ] **CI/CD plugins**
  - GitHub Actions for manifest validation
  - Pre-commit hooks for verification inheritance checks
  - Automated dependency audit on PR submissions

### User Interfaces

- [ ] **Web-based manifest explorer**
  - Interactive claim graph visualization
  - Verification trace inspection
  - Transformation history browsing
  - Policy rule debugging
- [ ] **Browser extension**
  - Display verification badges on scholarly PDFs
  - Quick manifest lookup for cited claims
  - Cross-document dependency tracking
- [ ] **Academic paper integration**
  - LaTeX package (`\usepackage{claimshift}`)
  - Pandoc filter for automatic manifest generation
  - Reference manager plugins (Zotero, Mendeley)

---

## Phase 4: Research Extensions (2028+)

### Theoretical Work

- [ ] **Extended rewrite fragments**
  - Expand certified transformation classes beyond α-renaming, AC-reordering, etc.
  - Investigate domain-specific rewrite systems (e.g., category theory, linear algebra)
  - Formalize conditions for safe compositional transformations
- [ ] **Dependency calculus**
  - Abstract algebra of verification dependencies
  - Composition laws for verification inheritance
  - Minimal dependency set computation
- [ ] **Trust propagation models**
  - Formal semantics for transitive trust
  - Policy composition and conflict resolution
  - Time-decay models for verification confidence

### Applied Research

- [ ] **Large-scale case studies**
  - Mathlib dependency analysis
  - Archive of Formal Proofs (AFP) transformation history
  - Software verification benchmark suites (e.g., CompCert, seL4)
- [ ] **Machine learning integration**
  - Proof repair for broken verification inheritance
  - Automatic transformation attestation suggestion
  - Anomaly detection in verification chains
- [ ] **Cross-language verification**
  - Lean ↔ Coq translation with inheritance tracking
  - Isabelle/HOL ↔ Agda verification correspondence
  - Interoperability with SMT solvers and SAT checkers

---

## Phase 5: Community & Standardization (2028+)

### Standards Development

- [ ] **RFC or W3C Community Group**
  - Open standard for verification manifests
  - Interoperability testing framework
  - Reference implementation certification program
- [ ] **Academic partnerships**
  - Formal methods research groups
  - Digital humanities scholars
  - Scientific reproducibility initiatives
- [ ] **Publisher engagement**
  - ACM, IEEE, Springer integration pilots
  - arXiv manifest support
  - Journal submission workflow integration

### Community Building

- [ ] **Documentation and tutorials**
  - User guide for scholars
  - Developer documentation for tool builders
  - Best practices for verification inheritance
- [ ] **Workshops and conferences**
  - Annual Claimshift conference
  - Tutorial sessions at POPL, ITP, FM conferences
  - Webinar series for early adopters
- [ ] **Open-source governance**
  - Community contribution guidelines
  - Roadmap voting and prioritization
  - Security disclosure process

---

## Long-Term Vision (2030+)

### Societal Impact

- [ ] **Reproducibility infrastructure**
  - Standard part of scientific publishing workflow
  - Integrated with institutional repositories
  - Required by funding agencies (NSF, ERC, etc.)
- [ ] **Educational adoption**
  - Undergraduate formal methods courses
  - Graduate-level verification seminars
  - Online learning platforms (Coursera, edX)
- [ ] **Policy and regulation**
  - Standards for AI-assisted research artifacts
  - Verification requirements for safety-critical systems
  - Legal frameworks for computational evidence

### Technical Horizons

- [ ] **Quantum-resistant cryptography**
  - Post-quantum signature schemes for manifests
  - Long-term archival security (100+ year horizon)
- [ ] **Decentralized verification**
  - Blockchain or distributed ledger integration
  - Peer-to-peer manifest distribution
  - Byzantine-fault-tolerant consensus for adjudicators
- [ ] **AI verification assistants**
  - LLM-powered proof repair
  - Automated transformation attestation
  - Natural language verification queries

---

## Milestones Summary

| Phase | Timeline | Key Deliverable |
|-------|----------|-----------------|
| **Paper III Experimental** | Q3 2026 | 20-mutant measurement, Paper III submission |
| **Protocol Implementation** | Q4 2026 - Q1 2027 | Reference implementation, Lean integration |
| **Ecosystem & Tooling** | Q2-Q4 2027 | CLI tool, LSP plugin, web explorer |
| **Research Extensions** | 2028+ | Extended rewrite fragments, large case studies |
| **Community & Standardization** | 2028+ | Open standard, academic partnerships |
| **Long-Term Vision** | 2030+ | Widespread adoption, policy impact |

---

## Contributing to the Roadmap

This roadmap is a living document. Contributions, suggestions, and priority feedback are welcome:

1. **GitHub Issues**: Tag with `roadmap` label
2. **Discussions**: Use GitHub Discussions for feature proposals
3. **Pull Requests**: Submit updates to this document directly

**Contact**: See repository maintainers or open an issue for discussion.

---

*Last updated: August 18, 2026*
