<div align="center">

# CodeIntel

**Persistent codebase memory for AI coding agents.**

Your agent analyzes a repository once, writes down what it learned, with evidence, in a local `.codeintel/` folder, and keeps those notes current as the code changes.<br>
Later sessions start from that map instead of re-reading the whole repo.

[![Validate](https://github.com/sagarwaal/codeintel/actions/workflows/validate.yml/badge.svg)](https://github.com/sagarwaal/codeintel/actions/workflows/validate.yml)
[![Release](https://img.shields.io/github/v/release/sagarwaal/codeintel?color=blue)](https://github.com/sagarwaal/codeintel/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Agent Skills](https://img.shields.io/badge/Agent%20Skills-compatible-8A2BE2)](https://skills.sh/sagarwaal/codeintel/codeintel)
[![GitHub stars](https://img.shields.io/github/stars/sagarwaal/codeintel?style=social)](https://github.com/sagarwaal/codeintel/stargazers)

Works with **Claude Code** · **OpenAI Codex** · **GitHub Copilot CLI** · **Cursor** · **Gemini CLI** · **Antigravity** · **Muse** · any agent that supports [Agent Skills](https://skills.sh)

[Quick start](#quick-start) · [See a real example](#see-it-on-a-real-repo) · [Why](#the-problem) · [Install](#installation) · [Usage](#usage) · [FAQ](#faq)

</div>

---

## Quick start

```text
# Claude Code (other agents: see Installation)
/plugin marketplace add sagarwaal/codeintel
/plugin install codeintel@codeintel
```

Then, inside any repository:

> Use CodeIntel to analyze this repository and build the `.codeintel/` knowledge base.

That's it. In later sessions the agent finds `.codeintel/` and uses it before planning, debugging, or editing code. After a change, it refreshes only the parts of the knowledge base that the change affected.

## The problem

Every new agent session starts from zero. The agent greps around, reads a dozen files, builds a partial picture of the system, and loses it all when the session ends. On a real codebase this leads to:

- **Wasted tokens and time** spent rediscovering the same architecture every session.
- **Changes that miss part of the system:** a fix in one place that breaks a caller the agent never saw.
- **Confident guesses:** "there are no tests for this" when the agent simply didn't look in the right directory.
- **Code that doesn't match the project's own conventions**, because the agent never found the right reference implementation.

`CLAUDE.md` / `AGENTS.md` files help, but they're short, written by hand, and go out of date quickly. CodeIntel adds a deeper layer that the agent maintains itself and that cites its sources.

## Before / after

<table>
<tr><th>Without CodeIntel</th><th>With CodeIntel</th></tr>
<tr valign="top"><td>

> *"Add retry support to the HTTP client."*

The agent searches for "retry", opens 9 files, patches the first plausible spot, and misses that a second code path builds its own connection pool and skips the change. It reports that tests pass after running the one test file it found.

</td><td>

> *"Add retry support to the HTTP client."*

The agent reads `.codeintel/agents/TASK_ROUTING.md`, which points it to the owning component, the [reference pattern](#what-it-creates) to copy, **both** code paths that build connection pools, the contract callers depend on, and the exact focused test command. It makes one coherent change and then refreshes the affected knowledge.

</td></tr>
</table>

## See it on a real repo

**[`examples/requests/`](examples/requests/)** holds a complete knowledge base that CodeIntel generated for [psf/requests](https://github.com/psf/requests) (v2.32.3). It is what your agent would write into `.codeintel/`, committed here so you can browse it without installing anything.

Good places to start:

- [`INDEX.md`](examples/requests/.codeintel/INDEX.md): the entry point and task router
- [`ARCHITECTURE.md`](examples/requests/.codeintel/ARCHITECTURE.md): the architecture as implemented, with a diagram
- [`workflows/`](examples/requests/.codeintel/workflows/get-request-trace.md): `requests.get()` traced end to end
- [`TEST_COVERAGE_GAPS.md`](examples/requests/.codeintel/TEST_COVERAGE_GAPS.md): behavioral gaps, not just line coverage
- [`KNOWN_ISSUES.md`](examples/requests/.codeintel/KNOWN_ISSUES.md): findings with evidence and confidence levels

## How it compares

| | `CLAUDE.md` / `AGENTS.md` | Editor code index / RAG | **CodeIntel** |
|---|---|---|---|
| What it holds | Short, hand-written instructions | Embeddings of code chunks | Architecture, components, dependencies, workflows, contracts, test gaps, findings |
| Who writes it | You | The tool | Your agent, following a strict evidence protocol |
| Answers "what breaks if I change X?" | Rarely | Partially (by text similarity) | Yes: dependency and impact maps |
| Distinguishes fact from guess | No | No | Yes: `VERIFIED` / `INFERRED` / `SUSPECTED` / `STALE` |
| Stays current | Manual | Re-indexes text | Incremental refresh: detects drift since the last analyzed commit and patches only affected docs |
| Readable by humans | Yes | No | Yes: plain Markdown + Mermaid |
| Lock-in | None | Tool-specific | None: one skill folder works across 6+ agents |

CodeIntel works alongside these. It can add a short discovery hook to your existing `AGENTS.md` / `CLAUDE.md` (only with your permission), so every future session knows to read `.codeintel/` first.

## What it creates

The skill scales its output to the repository. A typical knowledge base:

```text
your-project/
├── .codeintel/                   # Local, Git-ignored engineering knowledge
│   ├── INDEX.md                  # entry point + task routing
│   ├── PROJECT_PROFILE.md
│   ├── ARCHITECTURE.md           # as implemented, with Mermaid diagrams
│   ├── DIRECTORY_MAP.md
│   ├── COMPONENT_CATALOG.md
│   ├── DEPENDENCY_MAP.md         # blast radius for changes
│   ├── DATA_FLOW.md
│   ├── API_AND_CONTRACTS.md
│   ├── DESIGN_PRINCIPLES.md      # conventions + reference implementations
│   ├── TEST_STRATEGY.md          # real test commands
│   ├── TEST_COVERAGE_GAPS.md
│   ├── KNOWN_ISSUES.md           # evidence-backed findings
│   ├── FEATURE_IMPLEMENTATION_GUIDE.md
│   ├── agents/                   # QUICK_START, TASK_ROUTING, REVIEW_CHECKLIST
│   ├── components/
│   ├── workflows/
│   ├── findings/
│   └── manifests/                # analysis_state.json: commit checkpoint + claims
├── src/
└── ...
```

The skill picks which files to create based on how complex the repository is. It does not create empty boilerplate just to fill a template.

## Capabilities

- **Repository reconnaissance:** entry points, languages, frameworks, packages, tests, integrations, and existing project instructions.
- **Architecture reconstruction:** startup, critical workflows, data flows, interfaces, and boundaries, documented as they actually exist in the code.
- **Component intelligence:** responsibilities, contracts, dependencies, invariants, side effects, and how each component is tested.
- **Change-impact analysis:** downstream consumers and likely blast radius.
- **Evidence-backed audits:** correctness defects, cross-component inconsistencies, and maintainability risks, each with a confidence level.
- **Test intelligence:** maps behavior to tests and finds meaningful behavioral gaps, not just line coverage.
- **Project-specific design guidance:** conventions taken from real implementations and kept separate from recommendations.
- **Security, performance, and reliability review:** keeps confirmed findings separate from hypotheses.
- **Incremental refresh:** a two-phase drift check and patch, keyed to the last analyzed commit.
- **Optional specialist subagents:** six read-only roles (`repository_mapper`, `behavior_tracer`, `change_impact_analyst`, `test_quality_analyst`, `defect_consistency_auditor`, `knowledge_reconciler`) share an evidence model (`agent-result.json` and `claim.json`), and a single controlled Knowledge Writer reconciles their results. If the agent doesn't support subagents, the same roles run one after another.
- **Agent-friendly navigation:** quick-start and task-routing docs so future sessions land on the right code and tests.

## Installation

This repository is a plugin for several coding agents, and every agent reads the same `skills/codeintel/` folder. If you use more than one agent, install it in each.

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

### Muse

Muse reads skills from `~/workspace/custom-skills/<skill_name>/`, with the skill's metadata in a `skill.yaml` beside `SKILL.md` (not frontmatter). Copy the skill folder there, then remove the frontmatter block (the lines between the opening `---` and closing `---` at the top of the copied `SKILL.md`):

```bash
cp -r skills/codeintel/ ~/workspace/custom-skills/codeintel/
```

A ready-made `skill.yaml` ships in `skills/codeintel/` alongside `SKILL.md`, so a plain copy carries it; other agents ignore the extra file. Restart or refresh Muse after installing.

### Any agent that supports Agent Skills (skills.sh)

```bash
npx skills add sagarwaal/codeintel@codeintel
```

### Manual

Copy `skills/codeintel/` into your agent's skills directory (for example `~/.claude/skills/`, `~/.agents/skills/`, `.github/skills/`, or `~/.gemini/config/skills/`), then restart or refresh the agent.

## Usage

The skill is named **`codeintel`**. Invoke it explicitly where your agent supports it (for example `/codeintel`), or describe a task like one of these and the agent will pick it up from the skill description.

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

## FAQ

<details>
<summary><b>Does CodeIntel send my code anywhere?</b></summary>

No. CodeIntel is a set of instructions (a skill) plus small shell scripts. Your existing coding agent does the analysis with the access it already has, and the output is written only to `.codeintel/` inside your repository. Nothing is uploaded by CodeIntel.
</details>

<details>
<summary><b>How is this different from just writing a good <code>CLAUDE.md</code> / <code>AGENTS.md</code>?</b></summary>

Keep those files. They're the right place for short, hand-written rules. CodeIntel produces the deep, generated layer underneath them: component docs, dependency and impact maps, workflow traces, test gaps, and findings, each with evidence and a confidence label. It also detects when that knowledge has gone stale.
</details>

<details>
<summary><b>Will it modify my source code?</b></summary>

Not during analysis or refresh. The skill only writes inside `.codeintel/`, plus one local Git exclude rule (see below). It asks before adding a discovery hook to `AGENTS.md` / `CLAUDE.md`, and it changes application code only when you ask it to implement something.
</details>

<details>
<summary><b>How much does the first analysis cost?</b></summary>

It depends on the size of the repository and your agent. Deep Analysis is a one-time investment. After that, most work runs in the cheaper **Workflow Grounding** and **incremental refresh** modes, which read only the relevant knowledge files and the files that changed. For large repos and monorepos, the skill works in phases, starts with high-impact areas, and records partial coverage honestly.
</details>

<details>
<summary><b>Should I commit <code>.codeintel/</code>?</b></summary>

By default, no. It's excluded via `.git/info/exclude` so it creates no tracked change. Some teams choose to share it. If you do, review it first (see [Git exclusion and privacy](#git-exclusion-and-privacy)).
</details>

<details>
<summary><b>How does it stay up to date?</b></summary>

`.codeintel/manifests/analysis_state.json` records the last analyzed commit and which documents depend on which source files. A refresh first runs a read-only drift check (Phase A), then revalidates and patches only the affected claims (Phase B). The checkpoint moves forward only if validation passes. [`scripts/codeintel-refresh.sh`](scripts/codeintel-refresh.sh) handles the parts that can be done deterministically.
</details>

## Git exclusion and privacy

By default the skill adds this rule to the clone-local `.git/info/exclude`, so it creates no tracked change in your repository. It writes to the shared `.gitignore` instead only if you ask, or if the project already ignores similar tooling directories there:

```gitignore
# Local AI-generated code intelligence and repository analysis
/.codeintel/
```

It verifies the ignore rule when Git is available. If files in the directory are already tracked, ignore rules alone will not untrack them; in that case the skill reports the problem instead of silently changing what Git tracks.

**Important:** Git-ignored does not mean encrypted, private, or secure. The knowledge base may contain sensitive architectural information. Do not store credentials, tokens, private keys, sensitive production data, or secrets in it. Review the generated knowledge before sharing it or uploading it elsewhere.

Because the knowledge directory is ignored, normal Git operations won't share it with teammates or sync it between machines. Back it up or share it separately only when appropriate.

## Limitations

CodeIntel is an analysis workflow, not a guarantee of exhaustive correctness. Results depend on repository access, available tools, execution time, static-analysis capabilities, test setup, and which parts of the code were actually inspected.

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
├── examples/
│   └── requests/            # sample knowledge base generated for psf/requests
├── scripts/
│   ├── validate.sh          # manifest, skill, and schema v2 validation
│   └── codeintel-refresh.sh # drift detection, schema migration, and refresh engine
├── tests/
│   └── test-refresh.sh      # 16-scenario automated fixture refresh, evidence & semantic regression test suite
├── skills/
│   └── codeintel/           # the skill (invoke as /codeintel)
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
- Adding realistic examples and validation tests. **Ran CodeIntel on an interesting open-source repo? Open a PR adding it to `examples/`.**
- Reporting cases where the skill generates noisy, redundant, or misleading knowledge.

If CodeIntel saved you a session of rediscovering a codebase, **a ⭐ helps other developers find it.**

## License

[MIT](LICENSE)
