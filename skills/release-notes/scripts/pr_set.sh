#!/usr/bin/env bash
# Derive the PR set for a release. Deterministic — stage 1 of the release pipeline.
#
# WHY THIS EXISTS
# A release is a *promotion PR into the prod branch*. Its content is the set of PRs merged
# since the PREVIOUS promotion. Getting this wrong is not theoretical: on 2026-07-13 a
# hand-typed date filter ("mergedAt > 2026-06-29") included PR #48, whose fix had been
# promoted to prod five seconds after it merged. Two other approaches also failed:
#   - commit ranges  → the repo's squash history duplicates lineages (see the design doc)
#   - git ancestry   → a PR's squash on the release line and the squash that carried it to
#                      prod are different objects with the same content
# Anchor on the previous promotion. From the first tagged release on, anchor on the tag.
#
# Nothing here writes, pushes, tags or merges. Read-only by construction.
#
# Usage:  scripts/release/pr_set.sh [--json]
set -euo pipefail

command -v gh >/dev/null || { echo "error: gh (GitHub CLI) is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }

PROD_BRANCH="${PROD_BRANCH:-main}"
PR_LIMIT=300

# gh pr list silently truncates at --limit. A truncated list can drop the previous promotion
# (wrong anchor) or drop PRs from the release set — both fail SILENTLY, which is the one
# failure mode this pipeline exists to prevent. Fail loudly instead.
assert_not_truncated() {
  local count="$1" what="$2"
  if [[ "$count" -ge "$PR_LIMIT" ]]; then
    echo "error: $what hit the $PR_LIMIT-PR fetch limit — the set would be silently truncated." >&2
    echo "       Raise PR_LIMIT in $0, or narrow the query. Refusing to guess." >&2
    exit 1
  fi
}

# --- Release line: DETECTED, not assumed. It's the branch most merged PRs target.
# FEP → develop. lca-platform → staging (it has no develop at all, which is why an
# "if develop exists" rule would be wrong).
BASES=$(gh pr list --state merged --limit "$PR_LIMIT" --json baseRefName)
assert_not_truncated "$(jq length <<<"$BASES")" "the base-branch sample"
RELEASE_LINE=$(jq -r --arg prod "$PROD_BRANCH" \
      '[.[] | select(.baseRefName != $prod)]
       | group_by(.baseRefName) | max_by(length) | .[0].baseRefName // empty' <<<"$BASES")
RELEASE_LINE="${RELEASE_LINE:-$PROD_BRANCH}"

# --- Promotions vs direct-to-prod.
# A promotion is identified by WHERE IT CAME FROM, not by how someone worded the title.
# A PR into prod is a promotion if its head is the release line or a release/deploy branch.
# Everything else that reached prod is a DIRECT-TO-PROD PR — real, shipped, and outside the
# release train. We surface those loudly instead of quietly re-anchoring on one. This is
# load-bearing: if a hotfix merged straight to main could qualify as a promotion, it would
# become the anchor and silently truncate the release set to everything after the hotfix.
#
# This runs on EVERY release, not only the untagged bootstrap. Direct-to-prod PRs stay
# possible after the first tag, and they still land in SET/DEPS/CONTENT — the operator
# needs the call-out either way.
ALL_TO_PROD=$(gh pr list --state merged --base "$PROD_BRANCH" --limit "$PR_LIMIT" \
  --json number,title,mergedAt,headRefName | jq 'sort_by(.mergedAt)')
assert_not_truncated "$(jq length <<<"$ALL_TO_PROD")" "the promotion-PR list"

IS_PROMO='(.headRefName == $line) or (.headRefName | test("^(release|deploy)/"))'
PROMOTIONS=$(jq --arg line "$RELEASE_LINE" "[.[] | select($IS_PROMO)]" <<<"$ALL_TO_PROD")
DIRECT=$(jq --arg line "$RELEASE_LINE" "[.[] | select(($IS_PROMO) | not)]" <<<"$ALL_TO_PROD")

# --- Anchor.
# Preferred: the most recent tag (once this pipeline has run once, this is the normal path).
# Bootstrap: the previous promotion PR into the prod branch.
#
# Both anchor sources MUST be UTC in the same textual shape as gh's `mergedAt`
# (`YYYY-MM-DDTHH:MM:SSZ`), because the release set is selected by a jq STRING comparison.
# `git log --format=%cI` keeps the committer's local offset, so a tag written at
# 2026-07-13T22:33:54-03:00 compares as if it were 22:33 UTC and wrongly admits every PR
# merged in the preceding ~3 hours — PRs that already shipped in the previous release.
# That is the same class of bug as the hand-typed date filter described at the top.
LAST_TAG=$(git tag --sort=-creatordate | head -1)

# WHICH release are we describing? This decides the anchor, and getting it wrong is silent.
#
# An OPEN promotion PR means the release is the one about to ship, so the anchor is the most
# recent MERGED promotion. With no open promotion, the release is the one that just merged,
# so the anchor is the promotion BEFORE it.
#
# Taking .[-2] unconditionally — which this script did until 2026-07-22 — is only correct in
# the second case. Run before the promotion merges, it reaches one release too far back and
# silently re-admits work that already shipped. Measured on this repo: it produced 20 content
# PRs instead of 19, re-including the security hotfix the client had had for eight days.
OPEN_PROMO=$(gh pr list --state open --base "$PROD_BRANCH" --limit "$PR_LIMIT" \
  --json number,headRefName \
  | jq -r --arg line "$RELEASE_LINE" "[.[] | select($IS_PROMO)] | .[0].number // empty")

if [[ -n "$OPEN_PROMO" ]]; then
  DESCRIBING="open promotion PR #$OPEN_PROMO (not yet merged)"
  PREV_IDX=-1
else
  DESCRIBING="merged promotion PR #$(jq -r '.[-1].number // "?"' <<<"$PROMOTIONS")"
  PREV_IDX=-2
fi

if [[ -n "$LAST_TAG" ]]; then
  ANCHOR=$(TZ=UTC0 git log -1 --format=%cd --date=format-local:%Y-%m-%dT%H:%M:%SZ "$LAST_TAG")
  ANCHOR_SRC="tag $LAST_TAG"
else
  ANCHOR=$(jq -r --argjson i "$PREV_IDX" '.[$i].mergedAt // empty' <<<"$PROMOTIONS")
  ANCHOR_SRC="previous promotion PR #$(jq -r --argjson i "$PREV_IDX" '.[$i].number // "?"' <<<"$PROMOTIONS")"
  [[ -n "$ANCHOR" ]] || { echo "error: no previous promotion found; cannot anchor" >&2; exit 1; }
fi

# Only warn about direct-to-prod PRs inside THIS release window. Listing every one ever
# merged would bury the signal from the release that is actually being cut.
DIRECT_IN_WINDOW=$(jq --arg A "$ANCHOR" '[.[] | select(.mergedAt > $A)]' <<<"$DIRECT")
if [[ "$(jq length <<<"$DIRECT_IN_WINDOW")" -gt 0 ]]; then
  echo "note: PR(s) merged straight into $PROD_BRANCH, outside the release train." >&2
  echo "      They shipped to prod on their own deploy. Dependency bumps are expected here;" >&2
  echo "      anything else belongs in the technical changelog." >&2
  jq -r '.[] | "        #\(.number)  \(.title)"' <<<"$DIRECT_IN_WINDOW" >&2
  echo >&2
fi

# --- The set: merged after the anchor, ONTO the release line or straight to prod.
# The base filter is not cosmetic: without it, a PR merged into any unrelated branch after
# the anchor lands in the client release note despite never having shipped.
# Dependency bumps are EXCLUDED from the client note but must still be visible somewhere —
# the technical changelog lists them (they have reached prod on their own before).
ALL_MERGED=$(gh pr list --state merged --limit "$PR_LIMIT" \
  --json number,title,body,mergedAt,baseRefName,author)
assert_not_truncated "$(jq length <<<"$ALL_MERGED")" "the merged-PR list"

SET=$(jq --arg A "$ANCHOR" --arg line "$RELEASE_LINE" --arg prod "$PROD_BRANCH" '
      [ .[]
        | select(.mergedAt > $A)
        | select(.baseRefName == $line or .baseRefName == $prod)
        | select(.title | test("(?i)(back-merge|promote staging queue|^release:|bump version to)") | not)
      ] | sort_by(.mergedAt)' <<<"$ALL_MERGED")

# These four patterns MUST mirror the Dependencies parsers in cliff.toml. They are the only
# thing keeping a dependency bump out of the client note (per the rule stated above), so a
# pattern present there but missing here means that PR is written up for the client as a
# feature. Dependabot emits "Bump ..." / "Update ... requirement"; Renovate and hand-typed
# bumps emit "chore(deps): ...". This is a TITLE filter on the release set only — it has no
# bearing on the anchor, which is chosen by head branch above.
DEP_PATTERN='^(Bump |Update .* requirement|chore\(deps\)|chore\(dependabot\))'
CONTENT=$(jq --arg p "$DEP_PATTERN" '[.[] | select(.title | test($p) | not)]' <<<"$SET")
DEPS=$(jq    --arg p "$DEP_PATTERN" '[.[] | select(.title | test($p))]'       <<<"$SET")

if [[ "${1:-}" == "--json" ]]; then
  jq -n --argjson content "$CONTENT" --argjson deps "$DEPS" \
        --arg line "$RELEASE_LINE" --arg anchor "$ANCHOR" --arg src "$ANCHOR_SRC" \
        '{release_line: $line, anchor: $anchor, anchor_source: $src,
          content_prs: $content, dependency_prs: $deps}'
  exit 0
fi

echo "release line : $RELEASE_LINE  (detected)"
# Printed because the anchor is chosen from this, and a wrong choice is otherwise invisible:
# the operator's only defence is seeing which release the set claims to describe.
echo "describing   : $DESCRIBING"
echo "anchor       : $ANCHOR  ($ANCHOR_SRC)"
echo
echo "content PRs  : $(jq length <<<"$CONTENT")"
jq -r '.[] | "  #\(.number)  \(.title)"' <<<"$CONTENT"
echo
echo "dependency PRs (technical changelog only, never the client note): $(jq length <<<"$DEPS")"
jq -r '.[] | "  #\(.number)  \(.title)"' <<<"$DEPS"
