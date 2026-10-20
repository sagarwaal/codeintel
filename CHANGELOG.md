# Changelog

All notable changes to this project are documented here. This project follows [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-10-20

### Added
- Two-phase Knowledge Refresh workflow (**Phase A — Check drift** [read-only] and **Phase B — Refresh knowledge** [scoped write]) with `incremental`, `scoped`, and `full` scopes and a 7-phase refresh pipeline (`Detect -> Plan -> Investigate -> Reconcile -> Update -> Validate -> Commit Checkpoint`).
- Schema v2 for `.codeintel/manifests/analysis_state.json` with artifact-level `depends_on` tracking, structured `claims[]`, staleness status (`current`, `stale`, `unverified`, `deprecated`), working-tree dirtiness flags, and in-place Schema v1 -> v2 migration.
- Optional, controlled specialist subagent layer (`skills/codeintel/agents/`): 6 read-only role definitions (`repository-mapper`, `behavior-tracer`, `change-impact-analyst`, `test-quality-analyst`, `defect-consistency-auditor`, and `knowledge-reconciler`) with a single controlled Knowledge Writer.
- **Workflow Grounding (Consumer)** mode and **Before -> During -> After** workflow lifecycle hook in `SKILL.md`, plus a **Workflow & Subagent Context Pack** handoff table in `quick-start-template.md` and `task-routing-template.md` so planning, implementation, TDD, debugging, and code-review workflows automatically discover and use `.codeintel/`.
- Shared evidence model (`skills/codeintel/references/evidence-model.md`) and two-tier impact propagation guide (`skills/codeintel/references/impact-analysis.md`).
- Schema templates in `skills/codeintel/templates/`: `analysis-state-template.json`, `agent-result-template.json`, and `claim-template.json`.
- `scripts/codeintel-refresh.sh` for manifest/claim/agent-result validation, v1 -> v2 migration, drift detection, invalidation mapping, and atomic checkpoint updates.
- `tests/test-refresh.sh` covering 11 fixture-based refresh and evidence validation scenarios in CI.

## [1.0.0] - 2026-10-19

### Added
- `codeintel` skill with Deep Analysis, Task Investigation, Knowledge Refresh, and Audit modes.
- Mode-to-step routing and a "reuse existing knowledge" Step 0.
- Plugin manifests for Claude Code, GitHub Copilot CLI, OpenAI Codex, Cursor, Antigravity, and Gemini CLI.
- `scripts/validate.sh` and CI validation.

### Changed
- Git exclusion defaults to `.git/info/exclude`; `.gitignore` is used only on request or by existing convention.
