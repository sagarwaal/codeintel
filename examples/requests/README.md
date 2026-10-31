# Example: `psf/requests`

This directory demonstrates what **CodeIntel** creates inside an actual repository.

When an AI coding agent runs the `codeintel` skill on a target repo, it builds and maintains an evidence-backed knowledge base inside a local `.codeintel/` directory.

---

## 📂 Knowledge Base Location

The full generated knowledge base for **`psf/requests` (`v2.32.3`)** is located in:

👉 **[`examples/requests/.codeintel/`](.codeintel/)**

### Key Documents to Explore
- **[`.codeintel/INDEX.md`](.codeintel/INDEX.md)**: Entry point & task router.
- **[`.codeintel/ARCHITECTURE.md`](.codeintel/ARCHITECTURE.md)**: Actual implemented architecture with Mermaid component diagrams.
- **[`.codeintel/workflows/get-request-trace.md`](.codeintel/workflows/get-request-trace.md)**: End-to-end trace of `requests.get()` across socket boundaries.
- **[`.codeintel/TEST_COVERAGE_GAPS.md`](.codeintel/TEST_COVERAGE_GAPS.md)**: Behavioral test gaps identified by static inspection.
- **[`.codeintel/KNOWN_ISSUES.md`](.codeintel/KNOWN_ISSUES.md)**: Evidence-backed findings with explicit confidence levels.
- **[`.codeintel/agents/QUICK_START.md`](.codeintel/agents/QUICK_START.md)**: 60-second orientation for autonomous agents.
- **[`.codeintel/manifests/analysis_state.json`](.codeintel/manifests/analysis_state.json)**: Schema v2 manifest with checkpoint hash and claim verification statuses.
