# Changelog

All notable changes to this project are documented here. This project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-19

### Added
- `codeintel` skill with Deep Analysis, Task Investigation, Knowledge Refresh, and Audit modes.
- Mode-to-step routing and a "reuse existing knowledge" Step 0.
- Plugin manifests for Claude Code, GitHub Copilot CLI, OpenAI Codex, Cursor, Antigravity, and Gemini CLI.
- `scripts/validate.sh` and CI validation.

### Changed
- Git exclusion defaults to `.git/info/exclude`; `.gitignore` is used only on request or by existing convention.
