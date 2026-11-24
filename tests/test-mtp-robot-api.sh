#!/usr/bin/env bash
# Offline checks for MTP robot API setup scripts (no secrets, no OpenClaw required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

need() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    echo "FAIL missing $f"
    fail=1
  else
    echo "OK present $f"
  fi
}

need setup-mtp-robot-api.ps1
need verify-mtp-robot-api.ps1
need README.md

# Windows PowerShell 5.1 mis-parses UTF-8 dashes/quotes as broken strings.
for f in setup-mtp-robot-api.ps1 verify-mtp-robot-api.ps1; do
  if LC_ALL=C grep -n '[^[:print:][:space:]]' "$f" >/dev/null; then
    echo "FAIL non-ASCII bytes in $f (breaks Windows PowerShell)"
    LC_ALL=C grep -n '[^[:print:][:space:]]' "$f" || true
    fail=1
  else
    echo "OK ASCII-only $f"
  fi
done

# README must document the MTP Launch Guide path from the screenshot.
for phrase in "OPPO_MES" "appId" "appSecret" "Basic Data" "Basic Information" "setup-mtp-robot-api.ps1" "Service is busy"; do
  if grep -q "$phrase" README.md; then
    echo "OK README mentions $phrase"
  else
    echo "FAIL README missing: $phrase"
    fail=1
  fi
done

# Script must refuse placeholders and avoid echoing secrets.
if grep -q 'Test-LooksLikeAppId' setup-mtp-robot-api.ps1; then
  echo "OK setup validates AppId"
else
  echo "FAIL setup missing AppId validation"
  fail=1
fi
if grep -q 'value not printed' setup-mtp-robot-api.ps1; then
  echo "OK setup does not print credential values"
else
  echo "FAIL setup may print secrets"
  fail=1
fi
if grep -q 'Write-FeishuConfigDirect' setup-mtp-robot-api.ps1 && grep -q 'Find-BundledFeishu' setup-mtp-robot-api.ps1; then
  echo "OK setup patches config + loads bundled feishu for 2026.4.9"
else
  echo "FAIL setup missing 2026.4.9 bundled-feishu path"
  fail=1
fi
if grep -q 'plugins.load.paths' setup-mtp-robot-api.ps1; then
  echo "OK setup mentions plugins.load.paths"
else
  echo "FAIL setup missing plugins.load.paths"
  fail=1
fi

PWSH_BIN=""
if command -v pwsh >/dev/null 2>&1; then
  PWSH_BIN="$(command -v pwsh)"
elif [[ -x /tmp/pwsh/pwsh ]]; then
  PWSH_BIN="/tmp/pwsh/pwsh"
fi

if [[ -n "$PWSH_BIN" ]]; then
  echo "Running pwsh DryRun validation with $PWSH_BIN ..."
  if "$PWSH_BIN" -NoProfile -File ./setup-mtp-robot-api.ps1 -AppId "YOUR_APP_ID" -AppSecret "secret12345xx" -DryRun -SkipWorkspaceCopy; then
    echo "FAIL placeholder AppId should be rejected"
    fail=1
  else
    echo "OK placeholder AppId rejected"
  fi
  if "$PWSH_BIN" -NoProfile -File ./setup-mtp-robot-api.ps1 -AppId "cli_test_app_01" -AppSecret "secret_value_ok" -DryRun -SkipWorkspaceCopy; then
    echo "OK DryRun accepts Feishu-style credentials without OpenClaw"
  else
    echo "FAIL DryRun with Feishu-style credentials failed"
    fail=1
  fi
  # MTP OPPO_MES uses short numeric appId (real factory format).
  if "$PWSH_BIN" -NoProfile -File ./setup-mtp-robot-api.ps1 -AppId "22663" -AppSecret "MjI2NjNPUFBX01FUX1RFU1RfT05MWT09" -DryRun -SkipWorkspaceCopy; then
    echo "OK DryRun accepts short numeric MTP appId"
  else
    echo "FAIL short numeric MTP appId should be accepted"
    fail=1
  fi
  if "$PWSH_BIN" -NoProfile -File ./setup-mtp-robot-api.ps1 -AppId "cli_test_app_01" -AppSecret "secret_value_ok" -MesIssueChatId "oc_MES" -DryRun -SkipWorkspaceCopy; then
    echo "FAIL short placeholder chat id should be rejected"
    fail=1
  else
    echo "OK bad chat id rejected"
  fi
else
  echo "SKIP pwsh DryRun (pwsh not installed)"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: PASS"
