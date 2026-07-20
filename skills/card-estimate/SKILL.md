---
name: card-estimate
description: Break a feature request into sized, ClickUp-ready cards using the TACL house method — Fibonacci story points for sizing, flow metrics for forecasting. Project-agnostic: works in any repo. Use when asked to estimate work, size a feature, or break a request into cards/tickets.
---

# Card Estimate

Turn a feature request into well-formed, sized cards ready for ClickUp. Sizing is
in **Fibonacci story points**; *time* is forecast separately from flow metrics, not
derived per-card. Full method: the `methods/estimation/README.md` in the team-skills
repo (and embedded below so this skill is self-contained).

This skill is **project-agnostic**. It reads the *current* repo to size cards and
the project's own calibration file for reference stories and ClickUp IDs.

## When to use

- "Estimate this", "how big is this", "size this feature"
- "Break this into cards / tickets / tasks"

## Method essentials (embedded)

**Size effort, not time.** Fibonacci `1, 2, 3, 5, 8, 13` (+ `21` = "too big, split"
flag, never committed). Points = a *blend* of three axes (not a sum):

- **Uncertainty** (1–3) — judged from the request: 1 understood · 2 open questions · 3 spec unclear or depends on a missing answer/asset.
- **Complexity** (1–3) — judged from the **code**: 1 mechanical · 2 real logic / a design choice · 3 intricate, or a large surface to verify/trust.
- **Volume** (1–3) — judged from the **code**: 1 one spot · 2 a few files / one layer · 3 many files across layers.

Complexity and Volume can be scored two ways — see step 0. Quick mode reads them from
the description; code-inspected mode reads them from the repo.

Resolve by matching to the nearest **reference story**, rounding to nearest (not up).
If riskier than the nearest anchor, pick the higher candidate — don't add a step.

**The Definition of Done is in the number:** build + checks green + a developer reads
and hand-tests every line + code review + bug-fix + acceptance criteria. Don't pad.

**AI caveat:** generated code being fast to write does NOT make a card small — size
by the verify-and-integrate surface.

**Security-sensitive code is never small:** auth, authz/RLS, privileged keys,
storage/signed URLs, payments, migrations → Complexity ≥ 2, Confidence ≤ Medium.

## Process

### 0. Choose the estimation mode (ask up front, make it explicit)
There are two ways to score Complexity and Volume. **This is a real choice — surface
it; don't just default to digging through the code**, because not everyone wants to.

- **Quick (description-only)** — size from the request text alone. Fast, no code dive.
  For a non-technical requester, or a rough first pass. Complexity/Volume are read from
  the description; **Confidence is capped at Medium**, and the card is tagged
  `desc-only` so a developer can refine it later.
- **Code-inspected** — read the repo to derive Complexity/Volume from the real files.
  Slower, higher confidence. The default when a developer estimates or accuracy matters.

If the user hasn't said which, **ask** (one line: "quick estimate from the description,
or should I read the code?"). A non-technical user can always pick Quick and hand the
flagged cards to a dev.

### 1. Load this project's calibration
Look for `docs/estimation/anchors.md` (or `**/anchors.md`) in the repo: it holds the
project's **reference stories**, its **ClickUp Space/Folder/List IDs**, and its
**security-sensitive areas**. If absent, use the generic anchor shapes from the method
and tell the user this project has no calibration yet (offer to seed one).

### 2. Discover the ClickUp target
Use the project's anchors file IDs if present; otherwise use the ClickUp MCP
(`clickup_get_workspace_hierarchy`) to find the right Space → Folder → List. Read the
list's custom fields (`clickup_get_custom_fields`) to find the **Story Points** field
ID. If no Story Points field exists, note it — the point value goes in the card body
until someone adds the field in the ClickUp UI (the API can't create custom fields).

### 3. Split into vertical slices
Smallest set of independently shippable cards; each cuts end-to-end through the layers
it touches and is verifiable on its own. Every card ≤ 8 points; split anything bigger.
If a slice's only job is to *remove uncertainty* (research/decision), make it a
**spike**: timebox it, don't point it.

### 4. Score each card (per the mode from step 0)
- **Uncertainty:** always from the request.
- **Complexity & Volume:**
  - *Code-inspected mode* — grep/Read the repo for the files and layers this card will
    actually touch; derive the scores from that real fan-out, not the wording.
  - *Quick mode* — estimate them from the description; cap **Confidence at Medium** and
    tag the card `desc-only`. (Same if code-inspected mode was chosen but the repo
    can't be read.)
- Apply the security-area rule in **both** modes — a quick estimate doesn't get to skip
  the "security work is never small" rule.

### 5. Resolve to a point value (points only — no per-card time)
Match to the nearest reference story → Fibonacci number. **Do not assign a per-card time
estimate.** Time is forecast separately, in aggregate, from flow (cycle time /
throughput). A rough band (`1→≤1h … 13→3-5d`) is a mental sanity-check only — never
write it to the card.

### 6. Emit one block per card (exact shape)

**Every field, every card. A missing field is a failed card, not a terse one.** If a
field has nothing to say, write what makes it empty (`Depends on: nothing`) — never drop
the line. Omission is the measured failure mode of this skill: a real run emitted 1 of
the 8 fields as specified, and the four it dropped were the four that carry the risk.

`Type` selects *which* fields are required, so it comes first and is not one of the 8:

| `Type` | Required | Never |
| --- | --- | --- |
| `feature` (default) | `Type` + all 8 fields below | Story Points on a spike/bug; any delivery time |
| `spike` | `Type`, Description, Acceptance criteria, `Timebox` | Story Points |
| `bug` (unplanned) | `Type`, Description, Acceptance criteria | Story Points |

Spikes and unplanned bugs carry **no points** (`methods/estimation`: spikes are
timeboxed; unplanned bugs are interruptions counted in throughput). Don't invent a point
value to make a card look complete — a blank Story Points field on a spike is correct.

A spike's `Timebox` (e.g. `4h`) is **the one legitimate time value on any card.** It is a
budget for research, not an estimate of delivery, and it belongs only on a spike.

```
## <Card title — verb + object>
- Type: feature
- Story Points: <Fib>   Confidence: <High|Medium|Low>
- Sizing: U=<1-3> C=<1-3> V=<1-3> → <Fib>  (nearest reference: "<anchor>")
- Touches: <files/layers found in the repo, or "not inspected">
- Description: <2-4 plain sentences anyone can read>
- Acceptance criteria:
  - [ ] <observable, testable outcome>
- Why this size might be wrong: <the one blind spot>
- Assumptions / Risks / Depends on: <…>
- Definition of Done: standard (build + checks + hand-test + review + bug-fix + AC)
```

Footer:
```
- Totals: <sum of pointed cards> pts across <n> cards  ·  plus <n> unpointed (spikes/bugs)
- Route to a developer before commit: <cards hitting any trigger below>
```

Spikes and unplanned bugs are **excluded from the points total** and counted separately —
folding them in either inflates the total or tempts someone to point them.

**Routing triggers** (don't rely on self-assessed confidence): route a card if ANY of
— points ≥ 8 · Confidence Low · touches a security-sensitive area · spans 3+ layers ·
sized > 13 (auto-blocked, must split) · it's a `desc-only` card that sized ≥ 5 (a quick
estimate of something non-trivial should get a developer's eyes before it's committed).

Unpointed cards can't trip a points threshold, so they get their own rule: **route any
spike or bug that touches a security-sensitive area or whose outcome decides another
card's size.** A spike's whole job is to remove uncertainty someone else is blocked on.

### 7. Confirm before publishing
Show the breakdown as a numbered list. Ask: granularity right (too coarse / too fine)?
dependencies correct? split or merge any? Iterate until approved. **Never publish
unapproved cards.**

### 8. Self-check — before a single card is created

**Nothing enforces this but you.** There is no validator and no hook; the only gate is
this step actually being run. It is skipped exactly when it matters most — a long
thread, no repo, a hurry. Run it anyway.

Print this table, one row per card, filled in. Printing it is the check; a table you
did not write out is a table you did not run.

| Card | Type | Points | Sizing+ref | Touches | Desc | AC | Why-wrong | Assum/Depends | DoD |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

Then confirm, in writing:

- [ ] Every `feature` card has all 8 fields. Spikes/bugs have their required set and **no points**.
- [ ] Every `Sizing:` line ends with `(nearest reference: "<anchor>")`.
- [ ] Every `Touches:` says real files/layers, or literally `not inspected`.
- [ ] Every AC is **observable and testable** — a reader could tell pass from fail without asking. "Works reliably" is not an acceptance criterion.
- [ ] Every `Why this size might be wrong:` names a real blind spot, not a hedge.
- [ ] Repo not inspected → every card tagged `desc-only`, Confidence ≤ Medium.
- [ ] Routing triggers applied and listed in the footer — including `desc-only` **and** sized ≥ 5.
- [ ] No card carries a **delivery** time estimate — not in ClickUp's Time Estimate field, not in the body, not as a "provisional band." A spike's `Timebox` is the sole exception and appears only on a spike.
- [ ] Any card sized **5** that involves reliability/offline/cellular behavior, a security-sensitive area, an unresolved design choice, or a broad verification surface has been re-checked against the **8** and **13** anchors before the 5 was accepted. A 5 is the most over-used number on this scale.

If a row is incomplete, **fix the card — do not publish and fix later.** Cards are read
by whoever picks up the work; an incomplete card has already done its damage by then.

### 9. Publish to ClickUp
For each approved card, `clickup_create_task` in the matching List. **Publish the whole
block, not a summary of it** — every field from step 6 goes into `markdown_description`.
The fields that get dropped here are the ones that carry the risk, which is the same
failure as dropping them upstream.

Per type:

| | `feature` | `spike` | `bug` (unplanned) |
| --- | --- | --- | --- |
| Story Points custom field | set it (id from `anchors.md`) | **leave blank** | **leave blank** |
| `Timebox` | n/a | in the body | n/a |
| Tag | — | `spike` | `bug` |

`Type` is persisted as a **ClickUp tag** (`spike` / `bug`; `feature` is the default and
needs no tag) *and* stays as the `Type:` line in the body. Tags must already exist in the
Space — if the tag is missing, say so and leave it off rather than failing the create.

**Never set the native Time Estimate**, for any type. Time is forecast from flow (cycle
time / throughput), not assigned per card. A spike's timebox lives in the body, not in
that field.

Tag `needs-breakdown` and ask first before creating any card that sized > 13. Report
created task IDs and URLs.

## Mid-flight re-estimation
If a card turns out bigger than sized, **don't change the original number** — log the
surprise as a comment and finish (preserves honest calibration data). If the remainder
is now a different card, split it off and size that.

## Guardrails
- Never pad an individual estimate — slack is the DoD (per card) and aggregate headroom
  (flow), not an inflated number.
- Bugs: unplanned bugs aren't pointed (interruptions); planned fix cards are.
- Don't invent ClickUp structure — read it via the MCP or the anchors file.

## Where this lives
Canonical home: the **team-skills** repo on the org GitHub. Install by copying this
folder into `~/.claude/skills/` (then it works in every project) or symlinking it.
Each project supplies its own `docs/estimation/anchors.md`.
