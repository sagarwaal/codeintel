#!/usr/bin/env bash
# Automated fixture-based refresh test suite for CodeIntel (10 scenarios).
set -euo pipefail

export GIT_CONFIG_GLOBAL=/dev/null

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REFRESH_SH="$ROOT_DIR/scripts/codeintel-refresh.sh"

pass_count=0
fail_count=0

pass() { echo "  [PASS] $1"; pass_count=$((pass_count + 1)); }
fail() { echo "  [FAIL] $1: $2" >&2; fail_count=$((fail_count + 1)); exit 1; }
assert_eq() {
  local actual="$1" expected="$2" msg="$3"
  [[ "$actual" == "$expected" ]] || fail "$msg" "expected '$expected', got '$actual'"
}

TMP_WORKSPACE="$(mktemp -d)"
trap 'rm -rf "$TMP_WORKSPACE"' EXIT

init_multi_component_fixture() {
  local dir="$1"
  mkdir -p "$dir/src/auth" "$dir/src/billing" "$dir/src/types" "$dir/tests"
  mkdir -p "$dir/.codeintel/manifests" "$dir/.codeintel/components" "$dir/.codeintel/workflows"

  git -C "$dir" init -b main -q
  git -C "$dir" config user.name "Test User"
  git -C "$dir" config user.email "test@example.com"
  echo "/.codeintel/" >> "$dir/.git/info/exclude"

  cat > "$dir/package.json" <<'EOF'
{
  "name": "fixture-app",
  "version": "1.0.0",
  "scripts": { "test": "echo ok" }
}
EOF

  cat > "$dir/src/app.ts" <<'EOF'
import { authenticate } from "./auth/service";
import { chargeCustomer } from "./billing/charge";
export function startApp() { return true; }
EOF

  cat > "$dir/src/types/contracts.ts" <<'EOF'
export interface AuthToken {
  userId: string;
  role: "admin" | "member";
}
EOF

  cat > "$dir/src/auth/service.ts" <<'EOF'
import { AuthToken } from "../types/contracts";
export function authenticate(token: string): AuthToken {
  return { userId: "u1", role: "member" };
}
EOF

  cat > "$dir/src/billing/charge.ts" <<'EOF'
export function chargeCustomer(amountCents: number): boolean {
  return amountCents > 0;
}
EOF

  cat > "$dir/src/billing/legacy-coupon.ts" <<'EOF'
export function applyLegacyCoupon(code: string): number {
  return code === "SAVE10" ? 10 : 0;
}
EOF

  cat > "$dir/tests/app.test.ts" <<'EOF'
// Behavioral tests for auth and billing
export function testAuthAndBilling() { return true; }
EOF

  git -C "$dir" add .
  git -C "$dir" commit -q -m "Initial commit"
  local sha
  sha="$(git -C "$dir" rev-parse HEAD)"

  # Populate initial .codeintel/ knowledge base
  cat > "$dir/.codeintel/INDEX.md" <<'EOF'
# Project Index
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Catalog: [COMPONENT_CATALOG.md](COMPONENT_CATALOG.md)
- Contracts: [API_AND_CONTRACTS.md](API_AND_CONTRACTS.md)
- Billing Legacy: `src/billing/legacy-coupon.ts`
EOF

  cat > "$dir/.codeintel/ARCHITECTURE.md" <<'EOF'
# Architecture
- Entry point: `src/app.ts` (`startApp`) — **VERIFIED**
- Auth service: `src/auth/service.ts` — **VERIFIED**
- Billing service: `src/billing/charge.ts` — **VERIFIED**
EOF

  cat > "$dir/.codeintel/COMPONENT_CATALOG.md" <<'EOF'
# Component Catalog
- `src/auth/service.ts`: Auth token verification.
- `src/billing/charge.ts`: Customer charging.
- `src/billing/legacy-coupon.ts`: Legacy coupon calculator.
EOF

  cat > "$dir/.codeintel/API_AND_CONTRACTS.md" <<'EOF'
# API and Contracts
- Shared contract `AuthToken` in `src/types/contracts.ts` consumed by `src/auth/service.ts`.
EOF

  cat > "$dir/.codeintel/TEST_STRATEGY.md" <<'EOF'
# Test Strategy
- Suite in `tests/app.test.ts` configured via `package.json`.
EOF

  cat > "$dir/.codeintel/KNOWN_ISSUES.md" <<'EOF'
# Known Issues
## ISS-001: Missing rate limit on authenticate
- **Status:** open
- **Severity:** medium
- **Confidence:** confirmed
- **Affected path:** `src/auth/service.ts`
- **Evidence:** `authenticate()` performs no throttling.
EOF

  cat > "$dir/.codeintel/components/billing.md" <<'EOF'
# Billing Component
- Implemented in `src/billing/charge.ts` (`chargeCustomer`).
- Invariant: `amountCents > 0` (**VERIFIED**).

## User Notes
Custom operator note: Billing settlement runs at 02:00 UTC on banking days.
EOF

  cat > "$dir/.codeintel/workflows/checkout.md" <<'EOF'
# Checkout Workflow
1. `src/auth/service.ts` validates `src/types/contracts.ts`.
2. `src/billing/charge.ts` executes `chargeCustomer`.
EOF

  cat > "$dir/.codeintel/manifests/analysis_state.json" <<EOF
{
  "schema_version": 2,
  "repository": {
    "root": ".",
    "branch": "main",
    "head_commit": "$sha",
    "analyzed_commit": "$sha",
    "working_tree_clean": true,
    "includes_uncommitted_changes": false
  },
  "analysis": {
    "status": "complete",
    "scope": "full",
    "last_successful_refresh": "2026-10-20T00:00:00Z",
    "unresolved_items": [],
    "excluded_paths": [],
    "commands_executed": ["npm test"],
    "verification_results": ["pass"],
    "limitations": []
  },
  "artifacts": {
    "INDEX.md": {
      "depends_on": ["src/app.ts", "src/billing/legacy-coupon.ts"],
      "status": "current"
    },
    "ARCHITECTURE.md": {
      "depends_on": ["src/app.ts", "src/auth/service.ts", "src/billing/charge.ts"],
      "status": "current"
    },
    "COMPONENT_CATALOG.md": {
      "depends_on": ["src/auth/service.ts", "src/billing/charge.ts", "src/billing/legacy-coupon.ts"],
      "status": "current"
    },
    "API_AND_CONTRACTS.md": {
      "depends_on": ["src/types/contracts.ts", "src/auth/service.ts"],
      "status": "current"
    },
    "TEST_STRATEGY.md": {
      "depends_on": ["package.json", "tests/"],
      "status": "current"
    },
    "KNOWN_ISSUES.md": {
      "depends_on": ["src/auth/service.ts"],
      "status": "current"
    },
    "components/billing.md": {
      "depends_on": ["src/billing/charge.ts"],
      "status": "current"
    },
    "workflows/checkout.md": {
      "depends_on": ["src/auth/service.ts", "src/billing/charge.ts", "src/types/contracts.ts"],
      "status": "current"
    }
  },
  "claims": [
    {
      "claim_id": "claim.billing.charge_min_amount",
      "statement": "chargeCustomer requires positive amountCents.",
      "status": "verified",
      "confidence": "high",
      "evidence": [
        { "path": "src/billing/charge.ts", "symbol": "chargeCustomer", "lines": "1-3" }
      ],
      "depends_on": ["src/billing/charge.ts"],
      "last_verified_commit": "$sha"
    },
    {
      "claim_id": "claim.auth.token_contract",
      "statement": "authenticate returns an AuthToken defined in contracts.ts.",
      "status": "verified",
      "confidence": "high",
      "evidence": [
        { "path": "src/auth/service.ts", "symbol": "authenticate", "lines": "1-5" },
        { "path": "src/types/contracts.ts", "symbol": "AuthToken", "lines": "1-4" }
      ],
      "depends_on": ["src/auth/service.ts", "src/types/contracts.ts"],
      "last_verified_commit": "$sha"
    }
  ]
}
EOF
}

echo "Running CodeIntel Refresh & Evidence Test Suite (11 scenarios)..."

# ------------------------------------------------------------------------------
# Test 1: No changes -> detects no drift and avoids unnecessary document rewrites
# ------------------------------------------------------------------------------
REPO1="$TMP_WORKSPACE/repo1"
init_multi_component_fixture "$REPO1"
drift1="$(bash "$REFRESH_SH" check-drift "$REPO1")"
assert_eq "$(printf '%s\n' "$drift1" | jq -r '.has_drift')" "false" "Test 1: has_drift should be false"
assert_eq "$(printf '%s\n' "$drift1" | jq -r '.stale_artifacts | length')" "0" "Test 1: stale_artifacts should be empty"

before_hash="$(cksum "$REPO1/.codeintel/ARCHITECTURE.md" "$REPO1/.codeintel/manifests/analysis_state.json")"
bash "$REFRESH_SH" apply-refresh "$REPO1"
after_hash="$(cksum "$REPO1/.codeintel/ARCHITECTURE.md" "$REPO1/.codeintel/manifests/analysis_state.json")"
assert_eq "$after_hash" "$before_hash" "Test 1: no-op refresh must not rewrite documents or manifest"
pass "1/10 No changes: zero drift detected and no documents rewritten"

# ------------------------------------------------------------------------------
# Test 2, 8, 10: Implementation changes + User-authored knowledge + No false resolution
# ------------------------------------------------------------------------------
cat > "$REPO1/src/billing/charge.ts" <<'EOF'
export function chargeCustomer(amountCents: number, currency: string = "USD"): boolean {
  return amountCents >= 50 && currency.length === 3;
}
EOF
git -C "$REPO1" commit -am "feat(billing): require minimum 50 cents and currency code"
new_sha="$(git -C "$REPO1" rev-parse HEAD)"

test_strat_before="$(cksum "$REPO1/.codeintel/TEST_STRATEGY.md")"
drift2="$(bash "$REFRESH_SH" check-drift "$REPO1")"
assert_eq "$(printf '%s\n' "$drift2" | jq -r '.has_drift')" "true" "Test 2: drift detected on function change"
assert_eq "$(printf '%s\n' "$drift2" | jq -r '.stale_artifacts | index("components/billing.md") != null')" "true" "Test 2: components/billing.md marked stale"
assert_eq "$(printf '%s\n' "$drift2" | jq -r '.stale_artifacts | index("workflows/checkout.md") != null')" "true" "Test 2: dependent workflow marked stale"
assert_eq "$(printf '%s\n' "$drift2" | jq -r '.stale_artifacts | index("TEST_STRATEGY.md") == null')" "true" "Test 2: unrelated TEST_STRATEGY.md not marked stale"
assert_eq "$(printf '%s\n' "$drift2" | jq -r '.stale_claims | index("claim.billing.charge_min_amount") != null')" "true" "Test 2: billing claim marked stale"
assert_eq "$(printf '%s\n' "$drift2" | jq -r '.stale_claims | index("claim.auth.token_contract") == null')" "true" "Test 2: unrelated auth claim not marked stale"

bash "$REFRESH_SH" apply-refresh "$REPO1"
assert_eq "$(jq -r '.repository.analyzed_commit' "$REPO1/.codeintel/manifests/analysis_state.json")" "$new_sha" "Test 2: analyzed_commit advanced after success"
assert_eq "$(cksum "$REPO1/.codeintel/TEST_STRATEGY.md")" "$test_strat_before" "Test 2: unrelated TEST_STRATEGY.md untouched"
pass "2/10 Implementation changes: invalidated owning doc and dependent workflow, preserved unrelated docs"

# Test 8 check: user-authored notes in components/billing.md preserved
grep -q "Custom operator note: Billing settlement runs at 02:00 UTC on banking days." "$REPO1/.codeintel/components/billing.md" \
  || fail "Test 8: user-authored notes were lost" "missing note in components/billing.md"
pass "8/10 User-authored knowledge: custom operator notes in refreshed doc preserved verbatim"

# Test 10 check: open finding in KNOWN_ISSUES.md was not falsely marked resolved by billing change
grep -q "\*\*Status:\*\* open" "$REPO1/.codeintel/KNOWN_ISSUES.md" \
  || fail "Test 10: known defect status changed" "expected status open"
pass "10/10 No false resolution: unrelated change kept open defect ISS-001 unresolved"

# ------------------------------------------------------------------------------
# Test 3: Deleted component -> stale references removed and manifest validated
# ------------------------------------------------------------------------------
git -C "$REPO1" rm -q src/billing/legacy-coupon.ts
git -C "$REPO1" commit -q -m "chore: remove legacy coupon module"

drift3="$(bash "$REFRESH_SH" check-drift "$REPO1")"
assert_eq "$(printf '%s\n' "$drift3" | jq -r '.deleted_files[]')" "src/billing/legacy-coupon.ts" "Test 3: deleted file detected"
bash "$REFRESH_SH" apply-refresh "$REPO1"

if grep -q "legacy-coupon.ts" "$REPO1/.codeintel/COMPONENT_CATALOG.md" "$REPO1/.codeintel/INDEX.md"; then
  fail "Test 3: stale reference to deleted component remained in docs" "found legacy-coupon.ts"
fi
if jq -e '.artifacts[].depends_on[] | select(. == "src/billing/legacy-coupon.ts")' "$REPO1/.codeintel/manifests/analysis_state.json" >/dev/null; then
  fail "Test 3: deleted file remained in depends_on" "found legacy-coupon.ts"
fi
bash "$REFRESH_SH" validate-manifest "$REPO1/.codeintel/manifests/analysis_state.json" --kb-root "$REPO1/.codeintel" --repo-root "$REPO1"
pass "3/10 Deleted component: stale references purged from docs and depends_on"

# ------------------------------------------------------------------------------
# Test 4: Public contract changes -> dependent consumers and tests reconsidered
# ------------------------------------------------------------------------------
cat > "$REPO1/src/types/contracts.ts" <<'EOF'
export interface AuthToken {
  userId: string;
  role: "admin" | "member" | "auditor";
  expiresAt: number;
}
EOF
git -C "$REPO1" commit -am "feat(contracts): add auditor role and expiresAt to AuthToken"

drift4="$(bash "$REFRESH_SH" check-drift "$REPO1")"
assert_eq "$(printf '%s\n' "$drift4" | jq -r '.impacted_categories | index("public_interface") != null')" "true" "Test 4: public_interface category detected"
assert_eq "$(printf '%s\n' "$drift4" | jq -r '.stale_artifacts | index("API_AND_CONTRACTS.md") != null')" "true" "Test 4: API_AND_CONTRACTS.md invalidated"
assert_eq "$(printf '%s\n' "$drift4" | jq -r '.stale_artifacts | index("COMPONENT_CATALOG.md") != null')" "true" "Test 4: COMPONENT_CATALOG.md invalidated"
assert_eq "$(printf '%s\n' "$drift4" | jq -r '.stale_artifacts | index("TEST_STRATEGY.md") != null')" "true" "Test 4: TEST_STRATEGY.md invalidated for contract change"
bash "$REFRESH_SH" apply-refresh "$REPO1"
pass "4/10 Public contract changes: dependent consumers, contracts, and test strategy reconsidered"

# ------------------------------------------------------------------------------
# Test 5: Uncommitted changes -> detected without overwriting, dirty state recorded
# ------------------------------------------------------------------------------
echo "// uncommitted tweak" >> "$REPO1/src/auth/service.ts"
echo "export const helper = 1;" > "$REPO1/src/auth/untracked-helper.ts"

drift5="$(bash "$REFRESH_SH" check-drift "$REPO1")"
assert_eq "$(printf '%s\n' "$drift5" | jq -r '.has_drift')" "true" "Test 5: uncommitted drift detected"
assert_eq "$(printf '%s\n' "$drift5" | jq -r '.working_tree_clean')" "false" "Test 5: working_tree_clean is false"
assert_eq "$(printf '%s\n' "$drift5" | jq -r '.changed_files | index("src/auth/service.ts") != null')" "true" "Test 5: unstaged file detected"
assert_eq "$(printf '%s\n' "$drift5" | jq -r '.changed_files | index("src/auth/untracked-helper.ts") != null')" "true" "Test 5: untracked file detected"

bash "$REFRESH_SH" apply-refresh "$REPO1"
grep -q "// uncommitted tweak" "$REPO1/src/auth/service.ts" || fail "Test 5: uncommitted change was overwritten" "missing tweak"
assert_eq "$(jq -r '.repository.working_tree_clean' "$REPO1/.codeintel/manifests/analysis_state.json")" "false" "Test 5: manifest records working_tree_clean=false"
assert_eq "$(jq -r '.repository.includes_uncommitted_changes' "$REPO1/.codeintel/manifests/analysis_state.json")" "true" "Test 5: manifest records includes_uncommitted_changes=true"
git -C "$REPO1" checkout -- src/auth/service.ts
rm -f "$REPO1/src/auth/untracked-helper.ts"
pass "5/10 Uncommitted changes: detected unstaged + untracked changes without overwriting user work"

# ------------------------------------------------------------------------------
# Test 6: Refresh failure -> previous successful checkpoint preserved
# ------------------------------------------------------------------------------
prev_checkpoint="$(jq -r '.repository.analyzed_commit' "$REPO1/.codeintel/manifests/analysis_state.json")"
echo "// new committed change" >> "$REPO1/src/app.ts"
git -C "$REPO1" commit -am "feat: update app entry"

if bash "$REFRESH_SH" apply-refresh "$REPO1" --fail-stage "ARCHITECTURE.md" 2>/dev/null; then
  fail "Test 6: expected apply-refresh to fail when --fail-stage is set" "exited 0"
fi
after_fail_checkpoint="$(jq -r '.repository.analyzed_commit' "$REPO1/.codeintel/manifests/analysis_state.json")"
assert_eq "$after_fail_checkpoint" "$prev_checkpoint" "Test 6: analyzed_commit must not advance on refresh failure"
[[ ! -f "$REPO1/.codeintel/manifests/analysis_state.json.tmp" ]] || fail "Test 6: temporary manifest was not cleaned up" ".tmp exists"
pass "6/10 Refresh failure: previous successful analyzed_commit checkpoint preserved"

# ------------------------------------------------------------------------------
# Test 7: Partial analysis -> reported as partial rather than complete, checkpoint held
# ------------------------------------------------------------------------------
bash "$REFRESH_SH" apply-refresh "$REPO1" --partial-stage "ARCHITECTURE.md"
assert_eq "$(jq -r '.analysis.status' "$REPO1/.codeintel/manifests/analysis_state.json")" "partial" "Test 7: analysis.status must be partial"
assert_eq "$(jq -r '.repository.analyzed_commit' "$REPO1/.codeintel/manifests/analysis_state.json")" "$prev_checkpoint" "Test 7: analyzed_commit held during partial refresh"
assert_eq "$(jq -r '.analysis.unresolved_items | length > 0' "$REPO1/.codeintel/manifests/analysis_state.json")" "true" "Test 7: unresolved_items populated"

# Complete the remaining refresh and verify it advances now
bash "$REFRESH_SH" apply-refresh "$REPO1"
assert_eq "$(jq -r '.analysis.status' "$REPO1/.codeintel/manifests/analysis_state.json")" "complete" "Test 7b: status becomes complete after full revalidation"
assert_eq "$(jq -r '.repository.analyzed_commit' "$REPO1/.codeintel/manifests/analysis_state.json")" "$(git -C "$REPO1" rev-parse HEAD)" "Test 7b: analyzed_commit advances once complete"
pass "7/10 Partial analysis: recorded as partial with unresolved items and held checkpoint until completed"

# ------------------------------------------------------------------------------
# Test 9: Schema migration -> v1 manifest safely migrated to v2 without losing knowledge
# ------------------------------------------------------------------------------
REPO_SMALL="$TMP_WORKSPACE/repo_small"
mkdir -p "$REPO_SMALL/src" "$REPO_SMALL/.codeintel/manifests"
git -C "$REPO_SMALL" init -b main -q
git -C "$REPO_SMALL" config user.name "Test User"
git -C "$REPO_SMALL" config user.email "test@example.com"
echo "export const version = 1;" > "$REPO_SMALL/src/index.ts"
git -C "$REPO_SMALL" add .
git -C "$REPO_SMALL" commit -q -m "init small repo"
small_sha="$(git -C "$REPO_SMALL" rev-parse HEAD)"

cat > "$REPO_SMALL/.codeintel/ARCHITECTURE.md" <<'EOF'
# Small Repo Architecture
Single module in `src/index.ts`.
EOF

cat > "$REPO_SMALL/.codeintel/manifests/analysis_state.json" <<EOF
{
  "schema_version": 1,
  "repository_root": ".",
  "commit": "$small_sha",
  "branch": "main",
  "analyzed_at": "2026-10-19T12:00:00Z",
  "phases_completed": ["recon", "architecture"],
  "areas_analyzed": ["src/"],
  "areas_partially_analyzed": [],
  "areas_not_analyzed": [],
  "excluded_paths": ["node_modules/"],
  "commands_executed": ["npm test"],
  "verification_results": ["passed"],
  "unresolved_questions": ["Need load test numbers"],
  "limitations": ["Static analysis only"]
}
EOF

bash "$REFRESH_SH" migrate-manifest "$REPO_SMALL/.codeintel/manifests/analysis_state.json" \
  --kb-root "$REPO_SMALL/.codeintel" --repo-root "$REPO_SMALL"

assert_eq "$(jq -r '.schema_version' "$REPO_SMALL/.codeintel/manifests/analysis_state.json")" "2" "Test 9: migrated to schema_version 2"
assert_eq "$(jq -r '.repository.analyzed_commit' "$REPO_SMALL/.codeintel/manifests/analysis_state.json")" "$small_sha" "Test 9: preserved commit in repository.analyzed_commit"
assert_eq "$(jq -r '.analysis.unresolved_items[0]' "$REPO_SMALL/.codeintel/manifests/analysis_state.json")" "Need load test numbers" "Test 9: preserved unresolved_questions"
assert_eq "$(jq -r '.artifacts["ARCHITECTURE.md"].depends_on[0]' "$REPO_SMALL/.codeintel/manifests/analysis_state.json")" "src/index.ts" "Test 9: populated artifact depends_on from markdown"
[[ -f "$REPO_SMALL/.codeintel/ARCHITECTURE.md" ]] || fail "Test 9: existing markdown lost" "ARCHITECTURE.md missing"
pass "9/10 Schema migration: v1 manifest migrated in place to v2 with artifacts and metadata preserved"

# ------------------------------------------------------------------------------
# Test 11: Subagent & Evidence Model schema validation (claim.json & agent-result.json)
# ------------------------------------------------------------------------------
bash "$REFRESH_SH" validate-claim "$ROOT_DIR/skills/codeintel/templates/claim-template.json"
bash "$REFRESH_SH" validate-agent-result "$ROOT_DIR/skills/codeintel/templates/agent-result-template.json"

BAD_CLAIM="$TMP_WORKSPACE/bad-claim.json"
cat > "$BAD_CLAIM" <<'EOF'
{
  "id": "claim.bad",
  "subject": "bad",
  "statement": "Missing evidence and invalid confidence",
  "confidence": "guessed",
  "evidence": [],
  "depends_on": ["src/index.ts"],
  "status": "current",
  "last_verified_commit": "abc1234"
}
EOF
if bash "$REFRESH_SH" validate-claim "$BAD_CLAIM" 2>/dev/null; then
  fail "Test 11: expected validate-claim to reject invalid confidence and empty evidence" "exited 0"
fi

BAD_AGENT_RESULT="$TMP_WORKSPACE/bad-agent-result.json"
cat > "$BAD_AGENT_RESULT" <<'EOF'
{
  "agent": "unknown_agent_role",
  "scope": "invalid_scope",
  "analyzed_commit": "abc1234",
  "working_tree_clean": true,
  "status": "complete",
  "inspected_files": [],
  "commands_executed": [],
  "claims": [],
  "candidate_findings": [],
  "impacted_artifacts": [],
  "unresolved_items": []
}
EOF
if bash "$REFRESH_SH" validate-agent-result "$BAD_AGENT_RESULT" 2>/dev/null; then
  fail "Test 11: expected validate-agent-result to reject unknown agent role and scope" "exited 0"
fi
pass "11/16 Shared evidence & subagent schema: validated claim/agent-result templates and rejected malformed payloads"

# ------------------------------------------------------------------------------
# Semantic Regression Suite (5 targeted correctness & staging boundaries)
# ------------------------------------------------------------------------------
REPO_SEM="$TMP_WORKSPACE/repo_sem"
mkdir -p "$REPO_SEM/src/payments" "$REPO_SEM/src/utils" "$REPO_SEM/.codeintel/manifests" "$REPO_SEM/.codeintel/components"
git -C "$REPO_SEM" init -b main -q
git -C "$REPO_SEM" config user.name "Test User"
git -C "$REPO_SEM" config user.email "test@example.com"

cat > "$REPO_SEM/src/payments/retry.py" <<'EOF'
def retry_count():
    return 3
EOF

cat > "$REPO_SEM/src/payments/legacy_gateway.py" <<'EOF'
def use_legacy_gateway():
    return True
EOF

cat > "$REPO_SEM/src/utils/format.py" <<'EOF'
def fmt_currency(val):
    return f"${val}"
EOF

git -C "$REPO_SEM" add .
git -C "$REPO_SEM" commit -q -m "init semantic fixture"
sem_sha="$(git -C "$REPO_SEM" rev-parse HEAD)"

cat > "$REPO_SEM/.codeintel/INDEX.md" <<'EOF'
# Index
- `src/payments/retry.py`: Retry policy
- `src/payments/legacy_gateway.py`: Legacy gateway
EOF

cat > "$REPO_SEM/.codeintel/COMPONENT_CATALOG.md" <<'EOF'
# Catalog
- `src/payments/retry.py`: Payment retry logic
- `src/payments/legacy_gateway.py`: Old gateway module
- `src/utils/format.py`: Formatting helper

## Historical Notes
In v0, `src/payments/legacy_gateway.py` handled synchronous XML calls before the REST migration.
EOF

cat > "$REPO_SEM/.codeintel/ARCHITECTURE.md" <<'EOF'
# Architecture
Core payment flow uses `src/payments/retry.py`.
EOF

cat > "$REPO_SEM/.codeintel/components/payment.md" <<'EOF'
# Payment Component
The retry policy in `retry_count` allows three attempts.
EOF

cat > "$REPO_SEM/.codeintel/components/utils.md" <<'EOF'
# Utils Component
Currency formatting in `src/utils/format.py`.
EOF

cat > "$REPO_SEM/.codeintel/manifests/analysis_state.json" <<EOF
{
  "schema_version": 2,
  "repository": {
    "root": ".",
    "branch": "main",
    "head_commit": "$sem_sha",
    "analyzed_commit": "$sem_sha",
    "working_tree_clean": true,
    "includes_uncommitted_changes": false
  },
  "analysis": {
    "status": "complete",
    "scope": "full",
    "last_successful_refresh": "2026-10-20T00:00:00Z",
    "unresolved_items": []
  },
  "artifacts": {
    "INDEX.md": {
      "depends_on": ["src/payments/retry.py", "src/payments/legacy_gateway.py"],
      "status": "current"
    },
    "COMPONENT_CATALOG.md": {
      "depends_on": ["src/payments/retry.py", "src/payments/legacy_gateway.py", "src/utils/format.py"],
      "status": "current"
    },
    "ARCHITECTURE.md": {
      "depends_on": ["src/payments/retry.py"],
      "status": "current"
    },
    "components/payment.md": {
      "depends_on": ["src/payments/retry.py"],
      "status": "current"
    },
    "components/utils.md": {
      "depends_on": ["src/utils/format.py"],
      "status": "current"
    }
  },
  "claims": [
    {
      "claim_id": "payment-retry-policy",
      "statement": "The retry policy allows three attempts.",
      "status": "verified",
      "confidence": "high",
      "evidence": [
        { "path": "src/payments/retry.py", "symbol": "retry_count", "lines": "1-2" }
      ],
      "depends_on": ["src/payments/retry.py"],
      "last_verified_commit": "$sem_sha"
    },
    {
      "claim_id": "legacy-gateway-active",
      "statement": "Legacy gateway module is active.",
      "status": "verified",
      "confidence": "high",
      "evidence": [
        { "path": "src/payments/legacy_gateway.py", "symbol": "use_legacy_gateway", "lines": "1-2" }
      ],
      "depends_on": ["src/payments/legacy_gateway.py"],
      "last_verified_commit": "$sem_sha"
    }
  ]
}
EOF

# Semantic Test 12: Source behavior changes (return 3 -> return 5 updates claim and doc)
cat > "$REPO_SEM/src/payments/retry.py" <<'EOF'
def retry_count():
    return 5
EOF
git -C "$REPO_SEM" commit -am "feat(payments): increase retry_count from 3 to 5" -q
drift_sem1="$(bash "$REFRESH_SH" check-drift "$REPO_SEM")"
assert_eq "$(printf '%s\n' "$drift_sem1" | jq -r '.stale_claims | index("payment-retry-policy") != null')" "true" "SemTest 1: payment-retry-policy marked stale"
bash "$REFRESH_SH" apply-refresh "$REPO_SEM"
assert_eq "$(jq -r '.claims[] | select(.claim_id == "payment-retry-policy") | .statement' "$REPO_SEM/.codeintel/manifests/analysis_state.json")" "The retry policy allows 5 attempts." "SemTest 1: claim statement updated to 5 attempts"
grep -q "allows 5 attempts" "$REPO_SEM/.codeintel/components/payment.md" || fail "SemTest 1: components/payment.md not updated to 5 attempts" "$(cat "$REPO_SEM/.codeintel/components/payment.md")"
pass "12/16 Semantic regression 1 (Behavior change): retry_count 3->5 invalidated old claim and updated knowledge to 5"

# Semantic Test 13: Unrelated source changes (modify utils/format.py -> payment claim & doc untouched)
payment_doc_before="$(cksum "$REPO_SEM/.codeintel/components/payment.md")"
cat > "$REPO_SEM/src/utils/format.py" <<'EOF'
def fmt_currency(val):
    return f"USD {val:.2f}"
EOF
git -C "$REPO_SEM" commit -am "chore(utils): format currency with USD prefix" -q
drift_sem2="$(bash "$REFRESH_SH" check-drift "$REPO_SEM")"
assert_eq "$(printf '%s\n' "$drift_sem2" | jq -r '.stale_claims | index("payment-retry-policy") == null')" "true" "SemTest 2: payment-retry-policy remains current on unrelated util change"
assert_eq "$(printf '%s\n' "$drift_sem2" | jq -r '.stale_artifacts | index("components/payment.md") == null')" "true" "SemTest 2: components/payment.md not marked stale on unrelated util change"
bash "$REFRESH_SH" apply-refresh "$REPO_SEM"
assert_eq "$(cksum "$REPO_SEM/.codeintel/components/payment.md")" "$payment_doc_before" "SemTest 2: components/payment.md was not rewritten"
assert_eq "$(jq -r '.analysis.last_refresh_metrics.reused_existing_knowledge' "$REPO_SEM/.codeintel/manifests/analysis_state.json")" "true" "SemTest 2: metrics confirm existing knowledge reuse"
pass "13/16 Semantic regression 2 (Unrelated change): payment claim and component doc remained current and untouched"

# Semantic Test 14: Source deletion preserves Historical Notes while invalidating claim and removing active catalog entry
git -C "$REPO_SEM" rm -q src/payments/legacy_gateway.py
git -C "$REPO_SEM" commit -q -m "chore: delete legacy_gateway.py"
bash "$REFRESH_SH" apply-refresh "$REPO_SEM"
grep -q "In v0, \`src/payments/legacy_gateway.py\` handled synchronous XML calls" "$REPO_SEM/.codeintel/COMPONENT_CATALOG.md" \
  || fail "SemTest 3: Historical Notes section was destroyed on file deletion" "$(cat "$REPO_SEM/.codeintel/COMPONENT_CATALOG.md")"
if grep -q "^- \`src/payments/legacy_gateway.py\`" "$REPO_SEM/.codeintel/COMPONENT_CATALOG.md" "$REPO_SEM/.codeintel/INDEX.md"; then
  fail "SemTest 3: active catalog bullet for deleted file remained" "found active bullet"
fi
assert_eq "$(jq -r '.claims[] | select(.claim_id == "legacy-gateway-active") | .status' "$REPO_SEM/.codeintel/manifests/analysis_state.json")" "contradicted" "SemTest 3: claim for deleted module marked contradicted, not verified"
pass "14/16 Semantic regression 3 (Deletion safety): invalidated deleted module claim, purged active catalog bullet, preserved Historical Notes"

# Semantic Test 15: Interrupted refresh rolls back staged artifact changes atomically
cat > "$REPO_SEM/src/payments/retry.py" <<'EOF'
def retry_count():
    return 7
EOF
git -C "$REPO_SEM" commit -am "feat(payments): bump retry_count to 7" -q
arch_before="$(cksum "$REPO_SEM/.codeintel/ARCHITECTURE.md")"
payment_before="$(cksum "$REPO_SEM/.codeintel/components/payment.md")"
if bash "$REFRESH_SH" apply-refresh "$REPO_SEM" --fail-stage "components/payment.md" 2>/dev/null; then
  fail "SemTest 4: expected interrupted refresh to exit non-zero" "exited 0"
fi
assert_eq "$(cksum "$REPO_SEM/.codeintel/ARCHITECTURE.md")" "$arch_before" "SemTest 4: earlier staged artifact ARCHITECTURE.md was rolled back, not partially promoted"
assert_eq "$(cksum "$REPO_SEM/.codeintel/components/payment.md")" "$payment_before" "SemTest 4: components/payment.md untouched on failure"
[[ ! -d "$REPO_SEM/.codeintel/manifests/.staging" && ! -d "$REPO_SEM/.codeintel/manifests/.refresh.lock" ]] \
  || fail "SemTest 4: staging or lock directory leaked after failure" "staging/lock exists"
bash "$REFRESH_SH" apply-refresh "$REPO_SEM"
pass "15/16 Semantic regression 4 (Interrupted refresh): transactional staging prevented partial artifact mutation on disk"

# Semantic Test 16: Uncommitted working-tree change detected via diff & evidence_hash despite unchanged HEAD commit
head_before_dirty="$(git -C "$REPO_SEM" rev-parse HEAD)"
cat > "$REPO_SEM/src/payments/retry.py" <<'EOF'
def retry_count():
    return 9
EOF
drift_sem5="$(bash "$REFRESH_SH" check-drift "$REPO_SEM")"
assert_eq "$(printf '%s\n' "$drift_sem5" | jq -r '.head_commit')" "$head_before_dirty" "SemTest 5: HEAD commit hash is unchanged"
assert_eq "$(printf '%s\n' "$drift_sem5" | jq -r '.has_drift')" "true" "SemTest 5: drift detected despite unchanged commit hash"
assert_eq "$(printf '%s\n' "$drift_sem5" | jq -r '.working_tree_clean')" "false" "SemTest 5: working_tree_clean is false"
assert_eq "$(printf '%s\n' "$drift_sem5" | jq -r '.stale_claims | index("payment-retry-policy") != null')" "true" "SemTest 5: claim invalidated by uncommitted change and evidence_hash mismatch"
pass "16/16 Semantic regression 5 (Uncommitted change & evidence hash): detected dirty source change despite identical commit hash"

echo ""
echo "All $pass_count/16 refresh, evidence, and semantic regression test scenarios passed!"
