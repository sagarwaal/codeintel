#!/usr/bin/env bash
# Validates skills, plugin manifests, and CodeIntel analysis-state schemas.
# Usage: scripts/validate.sh
# Optional: scripts/validate.sh --bump 1.2.0   (sets every manifest version)
set -euo pipefail
cd "$(dirname "$0")/.."

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

# path|jq-path-to-version
VERSION_FILES=(
  ".claude-plugin/plugin.json|.version"
  ".claude-plugin/marketplace.json|.plugins[0].version"
  ".codex-plugin/plugin.json|.version"
  ".cursor-plugin/plugin.json|.version"
  ".antigravity-plugin/plugin.json|.version"
  "gemini-extension.json|.version"
)

JSON_FILES=(
  ".claude-plugin/plugin.json"
  ".claude-plugin/marketplace.json"
  ".codex-plugin/plugin.json"
  ".agents/plugins/marketplace.json"
  ".cursor-plugin/plugin.json"
  ".antigravity-plugin/plugin.json"
  "gemini-extension.json"
  "skills/codeintel/templates/analysis-state-template.json"
  "skills/codeintel/templates/agent-result-template.json"
  "skills/codeintel/templates/claim-template.json"
)

if [[ "${1:-}" == "--bump" ]]; then
  new="${2:?usage: --bump X.Y.Z}"
  for entry in "${VERSION_FILES[@]}"; do
    f="${entry%%|*}"; p="${entry#*|}"
    tmp="$(mktemp)"; jq --indent 2 "$p = \"$new\"" "$f" >"$tmp" && mv "$tmp" "$f"
  done
  echo "Bumped all manifests to $new"
fi

fail=0
err() { echo "ERROR: $*" >&2; fail=1; }

# 1. Every JSON manifest parses.
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  jq empty "$f" 2>/dev/null || err "invalid JSON: $f"
done < <(
  {
    printf '%s\n' "${JSON_FILES[@]}"
    find . -name '*.json' -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null | sed 's|^\./||' || true
  } | sort -u
)

# 2. All manifest versions agree.
versions=()
for entry in "${VERSION_FILES[@]}"; do
  f="${entry%%|*}"; p="${entry#*|}"
  [[ -f "$f" ]] || { err "missing manifest: $f"; continue; }
  v="$(jq -r "$p" "$f")"
  versions+=("$v")
  echo "  $f -> $v"
done
uniq_count="$(printf '%s\n' "${versions[@]}" | sort -u | wc -l | tr -d ' ')"
[[ "$uniq_count" == "1" ]] || err "manifest versions differ"

# 3. Validate analysis_state.json Schema v2, claim, and agent-result templates and any active manifest.
if [[ -f "skills/codeintel/templates/analysis-state-template.json" ]]; then
  bash scripts/codeintel-refresh.sh validate-manifest "skills/codeintel/templates/analysis-state-template.json" \
    || err "analysis-state-template.json failed schema v2 validation"
else
  err "missing skills/codeintel/templates/analysis-state-template.json"
fi

if [[ -f "skills/codeintel/templates/claim-template.json" ]]; then
  bash scripts/codeintel-refresh.sh validate-claim "skills/codeintel/templates/claim-template.json" \
    || err "claim-template.json failed claim schema validation"
else
  err "missing skills/codeintel/templates/claim-template.json"
fi

if [[ -f "skills/codeintel/templates/agent-result-template.json" ]]; then
  bash scripts/codeintel-refresh.sh validate-agent-result "skills/codeintel/templates/agent-result-template.json" \
    || err "agent-result-template.json failed agent-result schema validation"
else
  err "missing skills/codeintel/templates/agent-result-template.json"
fi

if [[ -f ".codeintel/manifests/analysis_state.json" ]]; then
  bash scripts/codeintel-refresh.sh validate-manifest ".codeintel/manifests/analysis_state.json" \
    --kb-root ".codeintel" --repo-root "." \
    || err ".codeintel/manifests/analysis_state.json failed validation"
fi

# 3b. Verify required specialist agent role definitions exist.
REQUIRED_AGENTS=(
  "skills/codeintel/agents/repository-mapper.md"
  "skills/codeintel/agents/behavior-tracer.md"
  "skills/codeintel/agents/change-impact-analyst.md"
  "skills/codeintel/agents/test-quality-analyst.md"
  "skills/codeintel/agents/defect-consistency-auditor.md"
  "skills/codeintel/agents/knowledge-reconciler.md"
)
for agent_doc in "${REQUIRED_AGENTS[@]}"; do
  [[ -f "$agent_doc" ]] || err "missing agent role definition: $agent_doc"
done

# 4. Skill frontmatter: name matches folder, description present and <= 1024 chars.
SKILL_FILES=("skills/codeintel/SKILL.md")
while IFS= read -r discovered; do
  [[ -n "$discovered" ]] && SKILL_FILES+=("$discovered")
done < <(compgen -G "skills/*/SKILL.md" 2>/dev/null || true)

while IFS= read -r skill; do
  [[ -z "$skill" ]] && continue
  dir="$(basename "$(dirname "$skill")")"
  [[ "$(head -1 "$skill")" == "---" ]] || { err "$skill: missing frontmatter"; continue; }
  fm="$(awk 'NR==1{next} /^---$/{exit} {print}' "$skill")"
  name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p')"
  desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p')"
  [[ "$name" == "$dir" ]] || err "$skill: name '$name' != folder '$dir'"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "$skill: name must be kebab-case"
  [[ -n "$desc" ]] || err "$skill: empty description"
  (( ${#desc} <= 1024 )) || err "$skill: description is ${#desc} chars (max 1024)"
  lines="$(wc -l <"$skill" | tr -d ' ')"
  (( lines <= 500 )) || echo "WARN: $skill is $lines lines (guideline: <= 500)"

  # 5. Relative links inside the skill resolve.
  base="$(dirname "$skill")"
  while IFS= read -r link; do
    target="${link%%#*}"
    [[ -z "$target" || "$target" =~ ^(https?:|mailto:) ]] && continue
    [[ -e "$base/$target" ]] || err "$skill: broken link -> $link"
  done < <(grep -oE '\]\([^)]+\)' "$skill" | sed -E 's/^\]\((.*)\)$/\1/')
done < <(printf '%s\n' "${SKILL_FILES[@]}" | sort -u)

if (( fail )); then echo "Validation failed." >&2; exit 1; fi
echo "Validation passed."
