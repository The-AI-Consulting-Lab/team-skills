#!/usr/bin/env bash
# Regression test for the anchor choice in pr_set.sh.
#
# The bug this pins (2026-07-22): the anchor was always the second-to-last merged
# promotion. That is only right when the release has ALREADY merged. Run while the
# promotion PR is still open — which is the natural time to draft a release note — it
# reaches one release too far back and silently re-admits work that already shipped.
# On this repo it produced 20 content PRs instead of 19, re-including a security fix
# the client had had for eight days.
#
# No network: the decision is pure, so it is tested against fixtures.
set -euo pipefail

PROMOTIONS='[
  {"number":53,"mergedAt":"2026-06-29T21:29:28Z"},
  {"number":81,"mergedAt":"2026-07-13T21:22:02Z"},
  {"number":95,"mergedAt":"2026-07-14T22:58:50Z"}
]'
PROMOTIONS_AFTER='[
  {"number":53,"mergedAt":"2026-06-29T21:29:28Z"},
  {"number":81,"mergedAt":"2026-07-13T21:22:02Z"},
  {"number":95,"mergedAt":"2026-07-14T22:58:50Z"},
  {"number":113,"mergedAt":"2026-07-22T22:52:53Z"}
]'

# Mirrors the branch in pr_set.sh: open promotion → -1, otherwise → -2.
choose() {
  local promos="$1" open="$2" idx
  if [[ -n "$open" ]]; then idx=-1; else idx=-2; fi
  jq -r --argjson i "$idx" '.[$i].number' <<<"$promos"
}

fail=0
check() {
  local name="$1" got="$2" want="$3"
  if [[ "$got" == "$want" ]]; then
    echo "  ok    $name (anchor #$got)"
  else
    echo "  FAIL  $name — expected #$want, got #$got"; fail=1
  fi
}

echo "anchor choice:"

# Drafting the note while PR #113 is still open. Prod is #95, so #95 is the boundary.
check "promotion still open  → anchors on the last merged promotion" \
      "$(choose "$PROMOTIONS" "113")" "95"

# Same moment, but taking the old unconditional -2: reaches back past a shipped release.
check "the old behaviour would have anchored on #81 (the bug)" \
      "$(jq -r '.[-2].number' <<<"$PROMOTIONS")" "81"

# After #113 merges, it is the release being described, so the boundary is again #95.
check "promotion merged      → anchors on the one before it" \
      "$(choose "$PROMOTIONS_AFTER" "")" "95"

# Both entry points must agree on the boundary, or the same release documents differently
# depending on when you happened to run the script.
a="$(choose "$PROMOTIONS" "113")"; b="$(choose "$PROMOTIONS_AFTER" "")"
check "before and after the merge agree" "$a" "$b"

exit "$fail"
