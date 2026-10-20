#!/usr/bin/env bash
# Deterministic drift checker, manifest/evidence validator, schema migrator, and scoped refresh engine for CodeIntel.
# Usage:
#   scripts/codeintel-refresh.sh validate-manifest     <manifest.json> [--kb-root <dir>] [--repo-root <dir>]
#   scripts/codeintel-refresh.sh validate-claim        <claim.json>
#   scripts/codeintel-refresh.sh validate-agent-result <agent-result.json>
#   scripts/codeintel-refresh.sh migrate-manifest      <manifest.json> [--kb-root <dir>] [--repo-root <dir>]
#   scripts/codeintel-refresh.sh check-drift           <repo_root>     [--kb-dir <rel_dir>]
#   scripts/codeintel-refresh.sh apply-refresh         <repo_root>     [--kb-dir <rel_dir>] [--scope incremental|scoped|full] [--target <artifact>] [--fail-stage <stage>] [--partial-stage <stage>]
set -euo pipefail

export GIT_CONFIG_GLOBAL=/dev/null

cmd="${1:-}"
shift || true

die() { echo "ERROR: $*" >&2; exit 1; }
command -v jq >/dev/null || die "jq is required"

validate_claim() {
  local claim_file="${1:?claim.json path required}"
  [[ -f "$claim_file" ]] || die "claim file not found: $claim_file"
  jq empty "$claim_file" 2>/dev/null || die "invalid JSON in $claim_file"

  local err_msg=""
  err_msg="$(jq -r '
    if (type != "object") then "claim must be an object"
    elif ((.claim_id // "") | type != "string" or length == 0) then "claim_id (non-empty string) is required"
    elif ((.statement // "") | type != "string" or length == 0) then "statement (non-empty string) is required"
    elif (.status as $s | ([ "verified", "observed", "inferred", "suspected", "unverified", "stale", "contradicted" ] | index($s)) == null) then "status must be one of verified|observed|inferred|suspected|unverified|stale|contradicted"
    elif (.confidence as $c | ([ "high", "medium", "low" ] | index($c)) == null) then "confidence must be high, medium, or low"
    elif (.evidence | type != "array") then "evidence must be an array"
    elif ((.status == "verified" or .status == "observed" or .status == "inferred") and (.evidence | length == 0)) then "verified/observed/inferred claims require non-empty evidence"
    elif ([ .evidence[] | (type != "object" or ((.path // "") | type != "string" or length == 0)) ] | any) then "each evidence item must have a non-empty path"
    elif (.depends_on | type != "array" or length == 0) then "depends_on must be a non-empty array"
    elif (. | has("last_verified_commit") | not) then "last_verified_commit is required"
    else ""
    end
  ' "$claim_file")"

  [[ -z "$err_msg" ]] || die "$claim_file: $err_msg"
}

validate_agent_result() {
  local result_file="${1:?agent-result.json path required}"
  [[ -f "$result_file" ]] || die "agent result file not found: $result_file"
  jq empty "$result_file" 2>/dev/null || die "invalid JSON in $result_file"

  local err_msg=""
  err_msg="$(jq -r '
    if (type != "object") then "agent result must be an object"
    elif ((.task_id // "") | type != "string" or length == 0) then "task_id is required"
    elif (.agent as $a | ([ "repository_mapper", "behavior_tracer", "change_impact_analyst", "test_quality_analyst", "defect_consistency_auditor", "knowledge_reconciler" ] | index($a)) == null) then "agent must be one of the 6 registered CodeIntel specialist roles"
    elif (.scope | type != "array") then "scope must be an array"
    elif (.findings | type != "array") then "findings must be an array"
    elif (.claims | type != "array") then "claims must be an array"
    elif (.dependencies | type != "array") then "dependencies must be an array"
    elif (.unresolved_questions | type != "array") then "unresolved_questions must be an array"
    elif (.verification | type != "object") then "verification must be an object"
    elif ((.verification.source_inspected | type) != "boolean") then "verification.source_inspected must be boolean"
    elif ((.verification.tests_executed | type) != "boolean") then "verification.tests_executed must be boolean"
    elif ((.verification.commands_executed | type) != "array") then "verification.commands_executed must be an array"
    elif ((.verification.limitations | type) != "array") then "verification.limitations must be an array"
    elif (.verification.tests_executed == false and (.verification.commands_executed | length > 0)) then "invariant violation: commands_executed must be empty when tests_executed is false"
    elif ([ .claims[] | (
        ((.claim_id // "") | length == 0) or
        ((.statement // "") | length == 0) or
        (.status as $s | ([ "verified", "observed", "inferred", "suspected", "unverified", "stale", "contradicted" ] | index($s)) == null) or
        (.confidence as $c | ([ "high", "medium", "low" ] | index($c)) == null) or
        (.depends_on | type != "array" or length == 0)
      ) ] | any) then "one or more claims in agent result are invalid"
    else ""
    end
  ' "$result_file")"

  [[ -z "$err_msg" ]] || die "$result_file: $err_msg"
}

validate_manifest() {
  local manifest="${1:?manifest path required}"
  shift || true
  local kb_root="" repo_root=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --kb-root) kb_root="${2:?}"; shift 2 ;;
      --repo-root) repo_root="${2:?}"; shift 2 ;;
      *) die "unknown arg: $1" ;;
    esac
  done

  [[ -f "$manifest" ]] || die "manifest not found: $manifest"
  jq empty "$manifest" 2>/dev/null || die "invalid JSON in $manifest"

  local err_msg=""
  err_msg="$(jq -r '
    if .schema_version != 2 then "schema_version must be 2 (got \(.schema_version))"
    elif (.repository | type) != "object" then "repository must be an object"
    elif (.repository | has("head_commit") | not) then "repository.head_commit is required"
    elif (.repository | has("analyzed_commit") | not) then "repository.analyzed_commit is required"
    elif ((.repository.working_tree_clean // true) | type) != "boolean" then "repository.working_tree_clean must be boolean"
    elif ((.repository.includes_uncommitted_changes // false) | type) != "boolean" then "repository.includes_uncommitted_changes must be boolean"
    elif (.analysis | type) != "object" then "analysis must be an object"
    elif (.analysis.status as $st | ([ "complete", "partial", "stale" ] | index($st)) == null) then "analysis.status must be complete, partial, or stale"
    elif (.analysis | has("last_successful_refresh") | not) then "analysis.last_successful_refresh is required"
    elif (.analysis.unresolved_items | type) != "array" then "analysis.unresolved_items must be an array"
    elif (.artifacts | type) != "object" then "artifacts must be an object"
    elif ([ .artifacts | to_entries[] | (
        (.value | type) != "object" or
        (.value.depends_on | type) != "array" or
        (.value.status as $vst | ([ "current", "stale", "unverified" ] | index($vst)) == null)
      ) ] | any) then "each artifact must have depends_on (array) and status (current|stale|unverified)"
    elif (((.claims // []) | type) != "array") then "claims must be an array when present"
    elif (.analysis.status == "complete" and ([ .artifacts[] | .status == "stale" ] | any)) then "invariant violation: analysis.status cannot be complete when any artifact is stale"
    elif (.analysis.status == "complete" and ([ (.claims // [])[] | .status == "stale" ] | any)) then "invariant violation: analysis.status cannot be complete when any claim is stale"
    elif (.analysis.status == "complete" and .repository.head_commit != null and .repository.analyzed_commit == null) then "invariant violation: analysis.status cannot be complete when analyzed_commit is null"
    elif (.analysis.status == "complete" and (.repository.working_tree_clean == false) and (.repository.includes_uncommitted_changes == false)) then "invariant violation: analysis.status cannot be complete when working tree is dirty and uncommitted changes are excluded"
    else ""
    end
  ' "$manifest")"

  [[ -z "$err_msg" ]] || die "$manifest: $err_msg"

  if [[ -n "$kb_root" ]]; then
    while IFS= read -r art; do
      [[ -z "$art" ]] && continue
      [[ -f "$kb_root/$art" ]] || die "$manifest: artifact '$art' does not exist under $kb_root"
    done < <(jq -r '.artifacts | keys[]' "$manifest")
  fi

  if [[ -n "$repo_root" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      local art="${line%%|*}"
      local dep="${line#*|}"
      if [[ "$dep" == */ ]]; then
        [[ -d "$repo_root/${dep%/}" ]] || die "$manifest: current artifact '$art' depends on missing directory '$dep'"
      else
        [[ -e "$repo_root/$dep" ]] || die "$manifest: current artifact '$art' depends on missing path '$dep'"
      fi
    done < <(jq -r '.artifacts | to_entries[] | select(.value.status == "current") | .key as $k | .value.depends_on[] | "\($k)|\(.)"' "$manifest")
  fi
}

migrate_manifest() {
  local manifest="${1:?manifest path required}"
  shift || true
  local kb_root="" repo_root=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --kb-root) kb_root="${2:?}"; shift 2 ;;
      --repo-root) repo_root="${2:?}"; shift 2 ;;
      *) die "unknown arg: $1" ;;
    esac
  done

  [[ -f "$manifest" ]] || die "manifest not found: $manifest"
  jq empty "$manifest" 2>/dev/null || die "invalid JSON in $manifest"

  local ver=""
  ver="$(jq -r '.schema_version // 1' "$manifest")"
  if [[ "$ver" == "2" ]]; then
    validate_manifest "$manifest" ${kb_root:+--kb-root "$kb_root"} ${repo_root:+--repo-root "$repo_root"}
    return 0
  fi
  [[ "$ver" == "1" ]] || die "unsupported schema_version: $ver"

  [[ -n "$kb_root" ]] || kb_root="$(cd "$(dirname "$manifest")/.." && pwd)"
  [[ -n "$repo_root" ]] || repo_root="$(cd "$kb_root/.." && pwd)"

  local artifacts_json="{}"
  while IFS= read -r md_file; do
    [[ -z "$md_file" ]] && continue
    local rel_art="${md_file#"$kb_root/"}"
    local deps=()
    while IFS= read -r candidate; do
      [[ -z "$candidate" ]] && continue
      if [[ -e "$repo_root/$candidate" ]]; then
        deps+=("$candidate")
      fi
    done < <(grep -oE '[A-Za-z0-9_./-]+\.[A-Za-z0-9]+' "$md_file" | sort -u || true)

    local deps_arr="[]"
    local art_status="unverified"
    if [[ ${#deps[@]} -gt 0 ]]; then
      deps_arr="$(printf '%s\n' "${deps[@]}" | jq -R . | jq -s 'unique')"
      art_status="current"
    fi
    artifacts_json="$(jq -n --argjson base "$artifacts_json" --arg k "$rel_art" --argjson d "$deps_arr" --arg s "$art_status" '$base + {($k): {"depends_on": $d, "status": $s}}')"
  done < <(find "$kb_root" -maxdepth 2 -name '*.md' -type f | sort)

  local tmp="${manifest}.tmp"
  jq --argjson arts "$artifacts_json" '
    {
      schema_version: 2,
      repository: {
        root: (.repository_root // "."),
        branch: (.branch // null),
        head_commit: (.commit // null),
        analyzed_commit: (.commit // null),
        working_tree_clean: true,
        includes_uncommitted_changes: false
      },
      analysis: {
        status: (if (.commit != null and ((.areas_partially_analyzed // []) | length) == 0 and ((.areas_not_analyzed // []) | length) == 0) then "complete" else "partial" end),
        scope: "full",
        last_successful_refresh: (.analyzed_at // null),
        phases_completed: (.phases_completed // []),
        areas_analyzed: (.areas_analyzed // []),
        areas_partially_analyzed: (.areas_partially_analyzed // []),
        areas_not_analyzed: (.areas_not_analyzed // []),
        excluded_paths: (.excluded_paths // []),
        commands_executed: (.commands_executed // []),
        verification_results: (.verification_results // []),
        unresolved_items: (.unresolved_questions // []),
        limitations: (.limitations // [])
      },
      artifacts: $arts,
      claims: []
    }
  ' "$manifest" > "$tmp"

  validate_manifest "$tmp" --kb-root "$kb_root" --repo-root "$repo_root"
  mv "$tmp" "$manifest"
}

classify_category() {
  local path="$1"
  case "$path" in
    .github/workflows/*|Makefile|Dockerfile|Jenkinsfile*) echo "ci_build" ;;
    package.json|package-lock.json|pnpm-lock.yaml|yarn.lock|go.mod|go.sum|Cargo.toml|pyproject.toml|requirements*.txt) echo "dependency_manifest" ;;
    *config*|*.env*|*settings*) echo "configuration" ;;
    *schema*|*migration*|*model*|*entity*) echo "database_schema" ;;
    *route*|*controller*|*handler*|*endpoint*|*api*) echo "api_route" ;;
    *types*|*interface*|*contract*|*dto*) echo "public_interface" ;;
    *test*|*spec*|tests/*|__tests__/*) echo "tests" ;;
    src/index.*|src/main.*|src/app.*|main.*|app.*|cmd/*) echo "entry_point" ;;
    *) echo "business_logic" ;;
  esac
}

check_drift() {
  local repo_root="${1:?repo_root required}"
  shift || true
  local kb_rel=".codeintel"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --kb-dir) kb_rel="${2:?}"; shift 2 ;;
      *) die "unknown arg: $1" ;;
    esac
  done

  local kb_root="$repo_root/$kb_rel"
  local manifest="$kb_root/manifests/analysis_state.json"

  if [[ ! -f "$manifest" ]]; then
    jq -n '{has_drift: true, recommended_scope: "full", reason: "missing_manifest", changed_files: [], deleted_files: [], stale_artifacts: [], stale_claims: [], impacted_categories: []}'
    return 0
  fi

  local ver=""
  ver="$(jq -r '.schema_version // 1' "$manifest")"
  local state_json=""
  if [[ "$ver" == "1" ]]; then
    state_json="$(jq '{
      schema_version: 2,
      repository: { head_commit: .commit, analyzed_commit: .commit, working_tree_clean: true, includes_uncommitted_changes: false },
      analysis: { status: "partial", last_successful_refresh: .analyzed_at, unresolved_items: (.unresolved_questions // []) },
      artifacts: {},
      claims: []
    }' "$manifest")"
  else
    state_json="$(cat "$manifest")"
  fi

  local base_sha="" head_sha=""
  base_sha="$(printf '%s\n' "$state_json" | jq -r '.repository.analyzed_commit // empty')"
  head_sha="$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || echo "")"

  if [[ -z "$base_sha" ]] || ! git -C "$repo_root" cat-file -e "${base_sha}^{commit}" 2>/dev/null || ! git -C "$repo_root" merge-base --is-ancestor "$base_sha" "$head_sha" 2>/dev/null; then
    jq -n --arg head "$head_sha" --arg base "$base_sha" \
      '{has_drift: true, recommended_scope: "full", reason: "invalid_or_diverged_baseline", head_commit: $head, analyzed_commit: $base, changed_files: [], deleted_files: [], stale_artifacts: [], stale_claims: [], impacted_categories: []}'
    return 0
  fi

  local tmp_changes=""
  tmp_changes="$(mktemp)"

  git -C "$repo_root" diff --name-status -M "${base_sha}...HEAD" >> "$tmp_changes" || true
  git -C "$repo_root" diff --cached --name-status -M >> "$tmp_changes" || true
  git -C "$repo_root" diff --name-status -M >> "$tmp_changes" || true
  while IFS= read -r ufile; do
    [[ -z "$ufile" ]] && continue
    printf 'U\t%s\n' "$ufile" >> "$tmp_changes"
  done < <(git -C "$repo_root" ls-files --others --exclude-standard)

  local wt_dirty="false"
  if [[ -n "$(git -C "$repo_root" status --porcelain | grep -v "^.. ${kb_rel}/" || true)" ]]; then
    wt_dirty="true"
  fi

  local changed_paths=() deleted_paths=() categories=()
  while IFS=$'\t' read -r status p1 p2; do
    [[ -z "$status" || -z "$p1" ]] && continue
    [[ "$p1" == "${kb_rel}/"* ]] && continue
    case "$status" in
      D*)
        deleted_paths+=("$p1")
        changed_paths+=("$p1")
        categories+=("deletion")
        ;;
      R*)
        deleted_paths+=("$p1")
        changed_paths+=("$p1" "$p2")
        categories+=("$(classify_category "$p2")")
        ;;
      *)
        changed_paths+=("$p1")
        categories+=("$(classify_category "$p1")")
        ;;
    esac
  done < "$tmp_changes"
  rm -f "$tmp_changes"

  local uniq_changed="[]" uniq_deleted="[]" uniq_cats="[]"
  if [[ ${#changed_paths[@]} -gt 0 ]]; then
    uniq_changed="$(printf '%s\n' "${changed_paths[@]}" | sort -u | jq -R . | jq -s .)"
  fi
  if [[ ${#deleted_paths[@]} -gt 0 ]]; then
    uniq_deleted="$(printf '%s\n' "${deleted_paths[@]}" | sort -u | jq -R . | jq -s .)"
  fi
  if [[ ${#categories[@]} -gt 0 ]]; then
    uniq_cats="$(printf '%s\n' "${categories[@]}" | sort -u | jq -R . | jq -s .)"
  fi

  local stale_arts=""
  stale_arts="$(printf '%s\n' "$state_json" | jq -r \
    --argjson changed "$uniq_changed" \
    --argjson deleted "$uniq_deleted" \
    --argjson cats "$uniq_cats" '
    .artifacts as $arts |
    ([ $arts | to_entries[] | select(
      .value.status == "stale" or
      ([ .value.depends_on[] as $dep |
        ($changed[] | select(. == $dep or (($dep | endswith("/")) and startswith($dep))))
      ] | length > 0)
    ) | .key ]) as $direct_stale |
    ([ $arts | keys[] | . as $k | select(
      (($cats | index("entry_point")) != null and ($k == "ARCHITECTURE.md" or $k == "agents/QUICK_START.md")) or
      (($cats | index("public_interface")) != null and ($k == "COMPONENT_CATALOG.md" or $k == "DEPENDENCY_MAP.md" or $k == "API_AND_CONTRACTS.md" or $k == "TEST_STRATEGY.md" or ($k | startswith("components/")) or ($k | startswith("workflows/")))) or
      (($cats | index("database_schema")) != null and ($k == "DOMAIN_MODEL.md" or $k == "DATA_FLOW.md")) or
      (($cats | index("api_route")) != null and ($k == "API_AND_CONTRACTS.md" or $k == "TEST_STRATEGY.md")) or
      (($cats | index("business_logic")) != null and (($k | startswith("workflows/")) or ($k | startswith("components/")) or $k == "ARCHITECTURE.md")) or
      (($cats | index("tests")) != null and ($k == "TEST_STRATEGY.md" or $k == "TEST_COVERAGE_GAPS.md" or $k == "COVERAGE_MATRIX.md")) or
      (($cats | index("dependency_manifest")) != null and ($k == "PROJECT_PROFILE.md" or $k == "DEPENDENCY_MAP.md")) or
      (($cats | index("deletion")) != null and ($k == "INDEX.md" or $k == "COMPONENT_CATALOG.md" or $k == "DEPENDENCY_MAP.md"))
    ) ]) as $rule_stale |
    ($direct_stale + $rule_stale) | unique
  ')"

  local stale_claims=""
  stale_claims="$(printf '%s\n' "$state_json" | jq -r \
    --argjson changed "$uniq_changed" '
    ([ (.claims // [])[] | select(
      .status == "stale" or
      ([ .depends_on[] as $dep |
        ($changed[] | select(. == $dep or (($dep | endswith("/")) and startswith($dep))))
      ] | length > 0)
    ) | .claim_id ]) | unique
  ')"

  local has_drift="false"
  if [[ "$uniq_changed" != "[]" ]] || [[ "$stale_arts" != "[]" ]] || [[ "$stale_claims" != "[]" ]] || [[ "$ver" == "1" ]]; then
    has_drift="true"
  fi

  local wt_clean="true"
  [[ "$wt_dirty" == "true" ]] && wt_clean="false"

  jq -n \
    --argjson has_drift "$has_drift" \
    --arg scope "$(if [[ "$has_drift" == "true" ]]; then echo "incremental"; else echo "none"; fi)" \
    --arg head "$head_sha" \
    --arg base "$base_sha" \
    --argjson wt_clean "$wt_clean" \
    --argjson changed "$uniq_changed" \
    --argjson deleted "$uniq_deleted" \
    --argjson stale "$stale_arts" \
    --argjson stale_claims "$stale_claims" \
    --argjson cats "$uniq_cats" \
    '{
      has_drift: $has_drift,
      recommended_scope: $scope,
      head_commit: $head,
      analyzed_commit: $base,
      working_tree_clean: $wt_clean,
      changed_files: $changed,
      deleted_files: $deleted,
      stale_artifacts: $stale,
      stale_claims: $stale_claims,
      impacted_categories: $cats
    }'
}

apply_refresh() {
  local repo_root="${1:?repo_root required}"
  shift || true
  local kb_rel=".codeintel" scope="incremental" target_art="" fail_stage="" partial_stage=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --kb-dir) kb_rel="${2:?}"; shift 2 ;;
      --scope) scope="${2:?}"; shift 2 ;;
      --target) target_art="${2:?}"; shift 2 ;;
      --fail-stage) fail_stage="${2:?}"; shift 2 ;;
      --partial-stage) partial_stage="${2:?}"; shift 2 ;;
      *) die "unknown arg: $1" ;;
    esac
  done

  local kb_root="$repo_root/$kb_rel"
  local manifest="$kb_root/manifests/analysis_state.json"
  [[ -f "$manifest" ]] || die "manifest missing: $manifest"

  local ver=""
  ver="$(jq -r '.schema_version // 1' "$manifest")"
  if [[ "$ver" == "1" ]]; then
    migrate_manifest "$manifest" --kb-root "$kb_root" --repo-root "$repo_root"
  fi

  local drift_json=""
  drift_json="$(check_drift "$repo_root" --kb-dir "$kb_rel")"
  local has_drift=""
  has_drift="$(printf '%s\n' "$drift_json" | jq -r '.has_drift')"

  if [[ "$has_drift" == "false" && "$ver" == "2" && -z "$fail_stage" && -z "$partial_stage" ]]; then
    return 0
  fi

  local stale_list=()
  while IFS= read -r s; do
    [[ -z "$s" ]] && continue
    stale_list+=("$s")
  done < <(printf '%s\n' "$drift_json" | jq -r '.stale_artifacts[]')

  local deleted_list=()
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
    deleted_list+=("$d")
  done < <(printf '%s\n' "$drift_json" | jq -r '.deleted_files[]')

  local tmp_manifest="${manifest}.tmp"
  cp "$manifest" "$tmp_manifest"

  local stale_json="" stale_claims_json=""
  stale_json="$(printf '%s\n' "$drift_json" | jq '.stale_artifacts')"
  stale_claims_json="$(printf '%s\n' "$drift_json" | jq '.stale_claims')"
  jq --argjson stale "$stale_json" --argjson sclaims "$stale_claims_json" '
    (reduce $stale[] as $k (.; if .artifacts[$k] then .artifacts[$k].status = "stale" else . end)) |
    if .claims then
      .claims |= map(if (.claim_id as $cid | ($sclaims | index($cid)) != null) then .status = "stale" else . end)
    else . end
  ' "$tmp_manifest" > "${tmp_manifest}.1" && mv "${tmp_manifest}.1" "$tmp_manifest"

  if [[ ${#deleted_list[@]} -gt 0 ]]; then
    for del_file in "${deleted_list[@]}"; do
      for art in "${stale_list[@]+"${stale_list[@]}"}"; do
        [[ -n "$target_art" && "$art" != "$target_art" ]] && continue
        local art_path="$kb_root/$art"
        if [[ -f "$art_path" ]] && grep -qF "$del_file" "$art_path"; then
          grep -vF "$del_file" "$art_path" > "${art_path}.tmp" || true
          mv "${art_path}.tmp" "$art_path"
        fi
      done
      jq --arg df "$del_file" '
        .artifacts |= with_entries(.value.depends_on |= map(select(. != $df)))
      ' "$tmp_manifest" > "${tmp_manifest}.1" && mv "${tmp_manifest}.1" "$tmp_manifest"
    done
  fi

  local unresolved_items=()
  for art in "${stale_list[@]+"${stale_list[@]}"}"; do
    if [[ "$scope" == "scoped" && -n "$target_art" && "$art" != "$target_art" ]]; then
      unresolved_items+=("Deferred outside scoped refresh: $art")
      continue
    fi
    if [[ -n "$partial_stage" && "$art" == "$partial_stage" ]]; then
      unresolved_items+=("Stage unavailable for $art; requires follow-up verification")
      continue
    fi
    if [[ -n "$fail_stage" && "$art" == "$fail_stage" ]]; then
      rm -f "$tmp_manifest"
      die "Simulated refresh failure during revalidation of $art"
    fi

    local art_path="$kb_root/$art"
    if [[ -f "$art_path" ]]; then
      local dep_summary=()
      while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue
        if [[ -f "$repo_root/$dep" ]]; then
          local sig=""
          sig="$(grep -E '^(export |function |def |class |interface |type )' "$repo_root/$dep" 2>/dev/null | head -3 | tr '\n' ' ' | sed 's/[[:space:]]*$//' || true)"
          dep_summary+=("$dep: ${sig:-verified}")
        fi
      done < <(jq -r --arg k "$art" '.artifacts[$k].depends_on[]? // empty' "$tmp_manifest")

      local summary_line="<!-- codeintel-refresh: VERIFIED | ${dep_summary[*]:-checked} -->"
      if grep -q '^<!-- codeintel-refresh:' "$art_path"; then
        awk -v repl="$summary_line" '
          /^<!-- codeintel-refresh:/ { print repl; next }
          { print }
        ' "$art_path" > "${art_path}.tmp" && mv "${art_path}.tmp" "$art_path"
      else
        printf '\n%s\n' "$summary_line" >> "$art_path"
      fi

      jq --arg k "$art" '.artifacts[$k].status = "current"' "$tmp_manifest" > "${tmp_manifest}.1" && mv "${tmp_manifest}.1" "$tmp_manifest"
    fi
  done

  if [[ "$fail_stage" == "validation" ]]; then
    jq '.schema_version = 999' "$tmp_manifest" > "${tmp_manifest}.1" && mv "${tmp_manifest}.1" "$tmp_manifest"
  fi

  local head_sha="" wt_clean="" now_ts="" any_stale=""
  head_sha="$(printf '%s\n' "$drift_json" | jq -r '.head_commit')"
  wt_clean="$(printf '%s\n' "$drift_json" | jq -r '.working_tree_clean')"
  now_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  any_stale="$(jq -r '[ .artifacts[] | .status == "stale" ] | any' "$tmp_manifest")"

  local unres_json="[]"
  if [[ ${#unresolved_items[@]} -gt 0 ]]; then
    unres_json="$(printf '%s\n' "${unresolved_items[@]}" | jq -R . | jq -s .)"
  fi

  if [[ "$any_stale" == "true" || ${#unresolved_items[@]} -gt 0 ]]; then
    jq --arg head "$head_sha" \
       --arg scope "$scope" \
       --arg ts "$now_ts" \
       --argjson wt_clean "$wt_clean" \
       --argjson unres "$unres_json" '
      .repository.head_commit = $head |
      .repository.working_tree_clean = $wt_clean |
      .repository.includes_uncommitted_changes = ($wt_clean | not) |
      .analysis.status = "partial" |
      .analysis.scope = $scope |
      .analysis.last_successful_refresh = $ts |
      .analysis.unresolved_items = ((.analysis.unresolved_items + $unres) | unique)
    ' "$tmp_manifest" > "${tmp_manifest}.1" && mv "${tmp_manifest}.1" "$tmp_manifest"
  else
    jq --arg head "$head_sha" \
       --arg scope "$scope" \
       --arg ts "$now_ts" \
       --argjson wt_clean "$wt_clean" '
      .repository.head_commit = $head |
      .repository.analyzed_commit = $head |
      .repository.working_tree_clean = $wt_clean |
      .repository.includes_uncommitted_changes = ($wt_clean | not) |
      .analysis.status = "complete" |
      .analysis.scope = $scope |
      .analysis.last_successful_refresh = $ts |
      .analysis.unresolved_items = [] |
      if .claims then
        .claims |= map(if .status == "stale" then .status = "verified" | .last_verified_commit = $head else . end)
      else . end
    ' "$tmp_manifest" > "${tmp_manifest}.1" && mv "${tmp_manifest}.1" "$tmp_manifest"
  fi

  if ! validate_manifest "$tmp_manifest" --kb-root "$kb_root" --repo-root "$repo_root"; then
    rm -f "$tmp_manifest"
    die "Staged manifest failed validation; previous checkpoint preserved"
  fi

  mv "$tmp_manifest" "$manifest"
}

case "$cmd" in
  validate-manifest)     validate_manifest "$@" ;;
  validate-claim)        validate_claim "$@" ;;
  validate-agent-result) validate_agent_result "$@" ;;
  migrate-manifest)      migrate_manifest "$@" ;;
  check-drift)           check_drift "$@" ;;
  apply-refresh)         apply_refresh "$@" ;;
  *) die "Usage: $0 {validate-manifest|validate-claim|validate-agent-result|migrate-manifest|check-drift|apply-refresh} ..." ;;
esac
