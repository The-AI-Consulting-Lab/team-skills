---
name: release-notes
description: Use when cutting a release — produces the technical changelog, the client-facing release note, the git tag and the GitHub Release. Project-agnostic; each repo opts in with convention, not config. Triggers - "cut a release", "release notes", "changelog", "what shipped", "prepare the release".
---

# Release Notes

Turn a release into three artefacts, for two audiences:

| Artefact | Audience | Where it lives |
|---|---|---|
| `CHANGELOG.md` | engineering, audit, rollback | the repo |
| Client release note | the client | a document you hand them |
| Tag + GitHub Release | the record | git / GitHub |

**A changelog and a release note are not the same document.** Collapsing them is the most
common way teams get this wrong. The changelog says what changed; the release note says what
the client can now do.

## The rule that matters

**A generator will produce a confident, wrong, client-facing document if nobody reads it.**

This is not hypothetical. When this skill was designed, three separate attempts to derive
"what shipped" — a commit range, a date filter, and git ancestry — each produced a plausible
number, and each was wrong. One would have announced features the client had been using for
two weeks; another included the repo's own README commit. All three survived until a review
caught them.

So: **stage 5 is a human, and it is not optional.** Everything before it is a draft.

## What ships with this skill vs. what a project supplies

**Logic is global, taste is local.** The derivation rules are identical everywhere, so they
live here and are fixed once. What differs per project is vocabulary and branding.

Shipped with the skill, in `scripts/` next to this file — use these, do not re-derive inline:

| Script | Purpose |
|---|---|
| `scripts/pr_set.sh` | Derives the PR set. Anchor rules, UTC normalisation, truncation guard, direct-to-prod detection. |
| `scripts/redact_check.sh` | Leak scan against the credential deny-list plus `curation.md`'s terms. |
| `scripts/test_anchor_choice.sh` | Regression test for the anchor decision. Runs offline. |

A repo may override with its own `scripts/release/pr_set.sh` if it genuinely needs different
logic — repo copy wins. Prefer fixing the global one.

Supplied by the project, all optional — a repo with none of them still gets a changelog.
**Starting points for all three ship in this skill's `templates/`** — copy, then adjust:

| File | Copy from | Purpose |
|---|---|---|
| `cliff.toml` | `templates/cliff.toml.example` | git-cliff's own config. Groups, commit parsers, format. |
| `scripts/release/render.*` | `templates/render.py.example` | Exactly one, executable, with a shebang. Produces the client document. Absent → markdown is the deliverable. |
| `docs/release/curation.md` | `templates/curation.md.example` | Product vocabulary, client-visible paths, never-leaves-the-building terms. Absent → **ask the operator; do not guess.** |

`render.py.example` is self-contained (only `python-docx`) and branded by editing two lines at
its top — so a new repo gets branded release docs with no app wiring. A project that already
has a markdown→docx renderer in its codebase should call that instead.

The renderer declares its own interpreter via its shebang. That is what keeps this skill
language-agnostic: it never maps an extension to a runtime, and never needs to know whether
the project is Python, Node or anything else. **More than one `render.*` → abort, don't guess.**

## Setting up a project that has never released this way

Four steps. Nothing here is generated blind — each asks the operator for what only they know.

1. **Detect the release line and confirm it.** Run the detection below and say the answer out
   loud before using it. One repo in this portfolio uses `staging` and has no `develop`.
2. **Add `cliff.toml`.** Start from `templates/cliff.toml.example` and adjust the commit parsers
   to that repo's actual convention. Check with
   `git log --oneline -100 | grep -cE '^[a-f0-9]+ (feat|fix|chore|docs)'` — a repo below about
   80% conventional commits will produce a changelog full of "Other", which is honest but
   noisy, and worth saying up front.
3. **Write `docs/release/curation.md` WITH the operator.** This is the one file you cannot
   infer. It carries how the client names things, which paths are client-visible, and the
   terms that must never leave the building. Without it, do not draft a client note — ask.
4. **Decide the client deliverable.** No `render.*` means markdown. A branded document means
   the project supplies the renderer.

Then cut the first release. It will have no tag to anchor on, so it anchors on the previous
promotion PR — which is exactly the path `test_anchor_choice.sh` covers.

## Three rules this pipeline learned the hard way

**Promote with a merge commit, never a squash.** Squashing a promotion leaves two lineages
with the same content, and no commit range can then reproduce what shipped. The first release
in this portfolio with a trustworthy range was the first one where both it and its predecessor
used merge commits.

**Run `pr_set.sh` at a moment it can reason about.** It decides the anchor from whether a
promotion PR is still open. That decision is printed as `describing:` — read that line. If it
names the wrong release, everything downstream is wrong and nothing else will say so.

**A CI step without `continue-on-error` is a hard gate, whether or not you meant it.** GitHub
halts on the first failing step, so one accidental gate silently skips every step after it. In
this portfolio that disabled seven eval suites — including a security check — for six days,
and the only visible signal was a job conclusion nobody read.

## Prerequisites

`git-cliff` (pin it), `gh`, `jq`. Check them first and say which is missing.

## The pipeline

```
1. EXTRACT  (deterministic)  git-cliff over <anchor>..<release-line>  → raw changelog
            (deterministic)  the PR set since the previous release    → prs.json
2. ROUTE    (deterministic)  commit parsers + path rules              → grouped, nothing dropped
3. DRAFT    (you)            PRs + curation.md                        → the two documents
4. REDACT   (mandatory)      deny-list scan; ABORT on a hit           → never masks silently
5. APPROVE  (human)          they read it. Nothing proceeds without this.
6. RENDER   (project)        scripts/release/render.*                  → the client document
7. PUBLISH  (human-triggered) CHANGELOG commit → tag → GitHub Release
```

### 1 — Extract

**Detect the release line. Do not assume it.** It is the branch most merged PRs target — not
"develop if it exists" (a repo in this very portfolio uses `staging` and has no `develop` at
all, which falsifies that rule):

```bash
gh pr list --state merged --limit 100 --json baseRefName \
  | jq -r 'group_by(.baseRefName) | max_by(length) | .[0].baseRefName'
```

**Anchor on the previous release, not on a date.** A release is a *promotion PR into the prod
branch*. If tags exist, the last tag is the anchor. If not, the previous promotion PR is —
identified by its **head branch** (the release line, or `release/*`), never by how someone
worded the title.

A hand-typed date is not a release boundary. In this project it wrongly included a PR whose
fix had been promoted to prod *five seconds* after it merged.

Run the script that ships with this skill: `"$CLAUDE_SKILL_DIR"/scripts/pr_set.sh`, or the
repo's own `scripts/release/pr_set.sh` if it has one (repo wins). Do not derive this inline —
the hardening is the point, and it is where every bug in this pipeline has been.

**Read the `describing:` line it prints.** It names the release the set claims to cover. The
anchor depends on whether the promotion PR has merged yet, and taking the wrong one re-admits
work that already shipped. Measured: run before the promotion merged, the earlier version
returned 20 content PRs instead of 19, re-including a security fix the client had had for
eight days.

Either way, **surface PRs merged straight to the prod branch** — they shipped on their own
deploy and are invisible to the release line.

### 2 — Route

`filter_commits = false`. **A silently dropped commit in a "what did we ship to prod" document
is a correctness bug, not a formatting one.** Anything unparsed lands visibly in "Other".

Watch for reverts. A `feat → revert → feat` sequence must not announce the feature twice.

### 3 — Draft

Two documents, written differently.

**`CHANGELOG.md`** — Keep a Changelog (`Added` / `Changed` / `Fixed` / `Security`), ISO dates,
newest first, plus:
- **Dependencies** — including any that reached prod on their own.
- **Operational notes** — migrations needing a manual apply, new env vars, deploy changes.
  This is the single most valuable section: it is what the next engineer on call reads. Never
  put it in the client note.

**The client release note** — product language. Group by *what they can now do*, not by commit
type. Use `curation.md`'s vocabulary. No table names, no file paths, no endpoints, no PR
numbers. Cut every internal story: refactors, CI, evals, dependency bumps, test coverage. If a
change's value is "the code is easier to work on", the client does not want to hear about it.

### 4 — Redact

Runs on both documents. **Aborts** — it never masks and continues.

Two levels, and the distinction matters: credentials are forbidden in *any* document;
project-internal terms are forbidden only in *client* documents. Blocking your own changelog
on the very line that makes it useful is how you teach an operator to bypass the gate.

**Be honest about what this is: a tripwire, not the control.** A regex cannot catch you
*paraphrasing* an internal fact — an unrotated credential, a security finding, another client.
The human is the control.

### 5 — Approve

Show them both documents. Say plainly what you might have got wrong. **Stop.**

### 6 — Render

If `scripts/release/render.*` exists, call it:

```
<the script> --in NOTES.md --out DOC.<ext> --title "..."
```

Exit 0 → the document is the deliverable. **Non-zero → warn, keep the markdown, do not abort.**
A broken renderer must never cost you the release note.

Only run `render.*` in a repo you own — an in-repo script executed by a global skill *is*
arbitrary code execution.

### 7 — Publish

**Confirm with the human before any push. Never tag, push or merge on your own.**

**Tag the release PR's merge commit on the prod branch.** It is by definition exactly what
shipped. Do *not* tag a commit on the release line: the host merges the release line's *tip at
merge time*, so anything landing after your tag ships untagged — and gets re-counted next
release.

Dated tag (`vYYYY.MM.DD`, annotated, a suffix on same-day collisions). Put the SHA and the
app's internal version in the tag body so the mapping is auditable. Then the GitHub Release,
with the changelog entry as the body.

## Then hand it over

The document is not the point; the client receiving it is. Name who delivers it and when. A
release note nobody sends is a release note nobody read.

## Keeping the next release clean

Promotions to the prod branch must use a **merge commit**, not a squash. Squash promotions
leave the release line and the prod branch as duplicate lineages, and then *no* commit range
is trustworthy — which is exactly how the three wrong numbers above happened. Say this out
loud to the team once; it is a one-line policy that saves the whole pipeline.
