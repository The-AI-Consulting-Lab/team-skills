#!/usr/bin/env bash
# REDACT gate — runs over release documents before anything leaves the building.
#
# THIS IS A TRIPWIRE, NOT THE CONTROL.
# A regex cannot catch an agent *paraphrasing* an internal fact (an unrotated credential,
# a data-exposure finding, a staging hostname). The control is the human who reads the
# draft. This gate exists to make the mechanical mistakes impossible, not the judgement
# ones.
#
# Aborts on a hit. It never masks and continues: a document that silently redacted itself
# is a document nobody audited.
#
# TWO LEVELS, because they are two different questions:
#
#   default   credentials only. Applied to every release document, including the internal
#             CHANGELOG. A real secret belongs in neither.
#   --client  credentials PLUS the project's "never leaves the building" terms. Only for
#             documents that go to the CLIENT.
#
# The distinction is load-bearing. The technical CHANGELOG *must* be able to say
# "fepbi_assistant_ro" and "security_invoker" — that is the whole point of its Operational
# notes section, and the next engineer on call needs it. The same words in a client
# document are a leak. Collapsing the two levels blocks your own changelog on its most
# useful line, and the operator learns to bypass the gate.
#
# Usage:  scripts/release/redact_check.sh [--client] FILE [FILE...]
#         RELEASE_REDACT_OVERRIDE="reason" scripts/release/redact_check.sh FILE
set -euo pipefail

CLIENT_FACING=0
if [[ "${1:-}" == "--client" ]]; then
  CLIENT_FACING=1
  shift
fi

[[ $# -gt 0 ]] || { echo "usage: $0 [--client] FILE [FILE...]" >&2; exit 2; }

# Deny-list. Extend per project via docs/release/curation.md ("Never leaves the building").
PATTERNS=(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'postgres(ql)?://[^[:space:]]*:[^[:space:]]*@'   # a URI carrying a password
  '\bsk-[A-Za-z0-9_-]{16,}'                        # Anthropic / OpenAI style
  '\bghp_[A-Za-z0-9]{20,}'                         # GitHub PAT
  '\bpat[A-Za-z0-9]{14,}\.[A-Za-z0-9]{40,}'        # Airtable PAT
  '\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'    # a JWT (service-role keys look like this)
  'SUPABASE_SERVICE_KEY[[:space:]]*[=:][[:space:]]*[^[:space:]]'
  'ANTHROPIC_API_KEY[[:space:]]*[=:][[:space:]]*[^[:space:]]'
)

# Per-project "never leaves the building" terms — CLIENT-FACING DOCUMENTS ONLY.
#
# Resolved from the REPO ROOT, not the caller's cwd. Resolving it relatively meant that
# running this from any other directory silently degraded --client to credentials-only and
# still printed "clean" — a gate that lies when you invoke it from the wrong place is worse
# than no gate. And in --client mode a missing curation file is now a HARD ERROR: fail
# closed, never fail quiet.
REPO_ROOT=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)
CURATION="${REPO_ROOT:-.}/docs/release/curation.md"

if [[ "$CLIENT_FACING" -eq 1 ]]; then
  if [[ ! -f "$CURATION" ]]; then
    echo "error: --client requires $CURATION (the project's 'never leaves the building' terms)." >&2
    echo "       Refusing to check a client document against the credential list alone." >&2
    exit 2
  fi
  TERMS=0
  while IFS= read -r term; do
    # Only bare, single-token terms are patterns (project refs, role names, hostnames).
    # The narrative bullets in that section are instructions to the human reviewer, not
    # regexes.
    if [[ -n "$term" && "$term" != *" "* && "$term" != -* ]]; then
      PATTERNS+=("$term")
      TERMS=$((TERMS + 1))
    fi
  done < <(awk '/^## *Never leaves the building/{f=1;next} /^## /{f=0} f && NF && !/^#/' "$CURATION")
  if [[ "$TERMS" -eq 0 ]]; then
    echo "error: no terms parsed from the 'Never leaves the building' section of $CURATION." >&2
    echo "       Either the section is empty or its heading changed. Failing closed." >&2
    exit 2
  fi
fi

HITS=0
for file in "$@"; do
  [[ -f "$file" ]] || { echo "error: no such file: $file" >&2; exit 2; }

  # Refuse binaries. A .docx is a ZIP: grep cannot see the text inside it, so scanning the
  # rendered deliverable would report a confident "clean" while a leaked term sits in
  # word/document.xml. Scan the SOURCE markdown — that is what the renderer consumes, so a
  # clean source is a clean document.
  if ! grep -Iq . "$file" 2>/dev/null; then
    echo "error: $file is binary (a .docx is a ZIP — grep cannot see inside it)." >&2
    echo "       Scan the source markdown instead; the rendered document derives from it." >&2
    exit 2
  fi

  for pat in "${PATTERNS[@]}"; do
    if grep -nEi -- "$pat" "$file" >/dev/null 2>&1; then
      echo "REDACT HIT  $file" >&2
      grep -nEi -- "$pat" "$file" | sed 's/^/    /' >&2
      HITS=$((HITS + 1))
    fi
  done
done

if [[ "$HITS" -gt 0 ]]; then
  if [[ -n "${RELEASE_REDACT_OVERRIDE:-}" ]]; then
    # An override is allowed — a PR legitimately titled "fix: strip postgres:// from logs"
    # must not be able to hard-block a release forever, or people just delete the gate.
    # But it is recorded, never silent.
    echo >&2
    echo "OVERRIDDEN: $RELEASE_REDACT_OVERRIDE" >&2
    echo "(recorded — put this reason in the release PR)" >&2
    exit 0
  fi
  echo >&2
  echo "ABORTED: $HITS pattern(s) matched. Nothing is written, nothing is sent." >&2
  echo "If this is a false positive, re-run with:" >&2
  echo "  RELEASE_REDACT_OVERRIDE=\"why this is safe\" $0 $*" >&2
  exit 1
fi

echo "redact: clean ($# file(s))"
