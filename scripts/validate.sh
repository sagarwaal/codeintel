#!/usr/bin/env bash
# Validates skills and plugin manifests. Usage: scripts/validate.sh
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
  jq empty "$f" 2>/dev/null || err "invalid JSON: $f"
done < <(find . -name '*.json' -not -path './.git/*' -not -path './node_modules/*')

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

# 3. Skill frontmatter: name matches folder, description present and <= 1024 chars.
for skill in skills/*/SKILL.md; do
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

  # 4. Relative links inside the skill resolve.
  base="$(dirname "$skill")"
  while IFS= read -r link; do
    target="${link%%#*}"
    [[ -z "$target" || "$target" =~ ^(https?:|mailto:) ]] && continue
    [[ -e "$base/$target" ]] || err "$skill: broken link -> $link"
  done < <(grep -oE '\]\([^)]+\)' "$skill" | sed -E 's/^\]\((.*)\)$/\1/')
done

if (( fail )); then echo "Validation failed." >&2; exit 1; fi
echo "Validation passed."
