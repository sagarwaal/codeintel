# CodeIntel

**A reusable AI coding-agent skill for deeply understanding software repositories—and preserving that knowledge locally for future work.**

CodeIntel helps an AI agent move beyond a quick README summary. It builds an evidence-based knowledge base covering architecture, components, dependencies, workflows, design conventions, implementation risks, test gaps, and safe feature development.

The generated knowledge lives inside the target project in `.codeintel/` and is excluded from Git by default. Future sessions can use it to navigate the codebase, investigate defects, assess change impact, and implement features without repeatedly rediscovering the entire repository.

## Why

AI coding agents can lose useful context between sessions and may make incomplete changes when they do not understand the wider system. Codeintel gives them a structured, maintainable map of the codebase—with explicit evidence, uncertainty, and refresh guidance.

It is designed to answer questions such as:

- Where does this behavior belong?
- Which components, interfaces, and workflows will this change affect?
- Which implementation is the best existing reference pattern?
- What invariants and contracts must be preserved?
- Which behaviors lack meaningful tests?
- Is a suspected issue a confirmed defect or only a hypothesis?
- What should be rechecked after a change?

## What it creates

The skill adapts its output to the size and structure of the repository. A typical knowledge base may look like:

```text
your-project/
├── .codeintel/                   # Local, Git-ignored engineering knowledge
│   ├── INDEX.md
│   ├── PROJECT_PROFILE.md
│   ├── ARCHITECTURE.md
│   ├── DIRECTORY_MAP.md
│   ├── COMPONENT_CATALOG.md
│   ├── DEPENDENCY_MAP.md
│   ├── DATA_FLOW.md
│   ├── API_AND_CONTRACTS.md
│   ├── DESIGN_PRINCIPLES.md
│   ├── TEST_STRATEGY.md
│   ├── TEST_COVERAGE_GAPS.md
│   ├── KNOWN_ISSUES.md
│   ├── FEATURE_IMPLEMENTATION_GUIDE.md
│   ├── agents/
│   ├── components/
│   ├── workflows/
│   ├── findings/
│   └── manifests/
├── src/
├── tests/
└── ...
```

The exact files are chosen based on repository complexity; the skill should not create empty boilerplate just to match a template.

## Capabilities

- **Repository reconnaissance:** identify entry points, languages, frameworks, packages, tests, integrations, and project instructions.
- **Architecture reconstruction:** trace startup, critical workflows, data flows, interfaces, and architectural boundaries.
- **Component intelligence:** document responsibilities, contracts, dependencies, invariants, side effects, and testing approaches.
- **Change-impact analysis:** map important relationships and identify downstream consumers and likely blast radius.
- **Evidence-backed audits:** record correctness defects, cross-component inconsistencies, maintainability risks, and uncertainty.
- **Test intelligence:** map behavior to tests and identify meaningful behavioral coverage gaps—not just line coverage.
- **Project-specific design guidance:** derive conventions from real implementations and distinguish them from recommendations.
- **Security, performance, and reliability review:** identify relevant risks while separating confirmed findings from hypotheses.
- **Incremental refresh:** update affected knowledge as the repository changes rather than regenerating everything after every task.
- **Controlled specialist subagent layer:** delegate independent read-only investigations (`repository_mapper`, `behavior_tracer`, `change_impact_analyst`, `test_quality_analyst`, `defect_consistency_auditor`, `knowledge_reconciler`) using a shared evidence model (`agent-result.json` and `claim.json`), reconciled by a single controlled Knowledge Writer—or run the same roles sequentially when subagents are unavailable.
- **Agent-friendly navigation:** provide quick-start guidance and task routing so future sessions can find the right code and tests.

## Installation

The repository is a plugin for several coding agents. Every agent reads the same `skills/codeintel/` folder. If you use more than one agent, install it in each one.

### Claude Code

```text
/plugin marketplace add sagarwaal/codeintel
/plugin install codeintel@codeintel
```

### GitHub Copilot CLI

```bash
copilot plugin marketplace add sagarwaal/codeintel
copilot plugin install codeintel@codeintel
```

### OpenAI Codex (CLI / App)

```bash
codex plugin marketplace add sagarwaal/codeintel
```

Then open `/plugins`, search for **CodeIntel**, and install.

### Cursor

Install from the repository URL `https://github.com/sagarwaal/codeintel` through Cursor's plugin settings.

### Antigravity

```bash
agy plugin install https://github.com/sagarwaal/codeintel
```

Restart Antigravity after installing. Run the same command again to update.

### Gemini CLI

```bash
gemini extensions install https://github.com/sagarwaal/codeintel
gemini extensions update codeintel   # later
```

### Any agent that supports Agent Skills (skills.sh)

```bash
npx skills add sagarwaal/codeintel@codeintel
```

### Manual

Copy `skills/codeintel/` into your agent's skills directory (for example `~/.claude/skills/`, `~/.agents/skills/`, `.github/skills/`, or `~/.gemini/config/skills/`), then restart or refresh the agent.

## Usage

The skill is named **`codeintel`**. Invoke it explicitly where your agent supports it (for example `/codeintel`), or just describe a task like one of these and the agent will pick it up from the skill description.

### 1. Deep initial analysis

> Use CodeIntel to analyze this repository deeply. Build the local `.codeintel/` knowledge base, reconstruct the actual architecture, map important component dependencies, identify evidence-backed defects and test gaps, document reference implementations, and create practical guidance for future feature development. Preserve existing work and do not modify application source code.

### 2. Investigate a bug

> Use CodeIntel to investigate this bug. Start from the existing knowledge base, verify relevant assumptions against current source, trace callers and cross-component behavior, identify the root cause, and recommend the smallest safe fix with regression tests. Do not implement the fix until asked.

### 3. Plan a feature

> Use CodeIntel to plan this feature. Identify the owning components, existing reference patterns, contracts, downstream consumers, invariants, test requirements, and operational risks. Propose a coherent implementation plan that fits the existing architecture.

### 4. Refresh knowledge after a change

> Refresh the CodeIntel knowledge affected by the current code changes. First run Phase A (read-only drift check) against `.codeintel/manifests/analysis_state.json` to list changed files, affected components, and stale claims; then run Phase B to revalidate affected claims against current code and tests, patch only impacted documents while preserving user notes, and advance the analysis checkpoint only after validation succeeds.

## Operating principles

1. **Source code is the source of truth.** Knowledge is derived and must be checked against current code.
2. **Evidence over confidence.** Important claims should point to real paths, symbols, tests, or command output.
3. **Uncertainty is explicit.** Distinguish verified facts, observations, inferences, suspicions, and unknowns.
4. **Preserve user work.** Do not reset, clean, overwrite, or discard unrelated changes.
5. **Analysis first.** Do not change application code during a knowledge-only audit unless authorized.
6. **No invented verification.** Never claim a test or scan passed unless it actually ran and passed.
7. **Incremental, not repetitive.** Refresh affected knowledge based on the change set and dependency relationships.
8. **Adapt to the repository.** Do not force a fixed architecture or create empty documents for small projects.

## Git exclusion and privacy

By default the skill adds this rule to the clone-local `.git/info/exclude`, so it creates no tracked change in your repository. It uses the shared `.gitignore` instead only if you ask, or if the project already ignores similar tooling directories there:

```gitignore
# Local AI-generated code intelligence and repository analysis
/.codeintel/
```

It verifies the ignore rule when Git is available. If files in the directory are already tracked, ignore rules alone will not untrack them; the skill must report that rather than silently changing tracking state.

**Important:** Git-ignored does not mean encrypted, private, or secure. The knowledge base may contain sensitive architectural information. Do not store credentials, tokens, private keys, sensitive production data, or secrets in it. Review the generated knowledge before sharing it or uploading it elsewhere.

Because the knowledge directory is ignored, it is not automatically shared with teammates or synchronized between machines through normal Git operations. Back it up or share it separately only when appropriate.

## Limitations

Codeintel is an analysis workflow, not a guarantee of exhaustive correctness. Results depend on repository access, available tools, execution time, static-analysis capabilities, test setup, and the parts of the code actually inspected.

Dynamic dispatch, reflection, generated code, runtime registration, external consumers, and undocumented production behavior may limit certainty. The skill is instructed to record these limitations rather than claim complete coverage.

## Repository layout

```text
.
├── .claude-plugin/          # Claude Code + Copilot CLI plugin and marketplace
├── .codex-plugin/           # OpenAI Codex plugin
├── .agents/plugins/         # Codex marketplace
├── .cursor-plugin/          # Cursor plugin
├── .antigravity-plugin/     # Antigravity plugin
├── gemini-extension.json    # Gemini CLI extension
├── scripts/
│   ├── validate.sh          # manifest, skill, and schema v2 validation
│   └── codeintel-refresh.sh # drift detection, schema migration, and refresh engine
├── tests/
│   └── test-refresh.sh      # 16-scenario automated fixture refresh, evidence & semantic regression test suite
├── skills/
│   └── codeintel/            # the skill (invoke as /codeintel)
│       ├── SKILL.md
│       ├── agents/          # 6 read-only specialist role protocols & reconciler
│       ├── references/      # architecture, change-protocol, evidence-model, impact-analysis, etc.
│       └── templates/       # analysis-state, agent-result, claim, and review templates
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
└── LICENSE
```

## Contributing

Contributions are welcome. Please see [CONTRIBUTING.md](CONTRIBUTING.md).

Useful contributions include:

- Improving analysis workflows and evidence quality.
- Adding language- or framework-specific guidance without making the core skill overly prescriptive.
- Improving incremental refresh and stale-knowledge detection.
- Adding realistic examples and validation tests.
- Reporting cases where the skill generates noisy, redundant, or misleading knowledge.

## License

[MIT](LICENSE)
