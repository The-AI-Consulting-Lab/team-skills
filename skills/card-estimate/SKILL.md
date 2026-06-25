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

Resolve by matching to the nearest **reference story**, rounding to nearest (not up).
If riskier than the nearest anchor, pick the higher candidate — don't add a step.

**The Definition of Done is in the number:** build + checks green + a developer reads
and hand-tests every line + code review + bug-fix + acceptance criteria. Don't pad.

**AI caveat:** generated code being fast to write does NOT make a card small — size
by the verify-and-integrate surface.

**Security-sensitive code is never small:** auth, authz/RLS, privileged keys,
storage/signed URLs, payments, migrations → Complexity ≥ 2, Confidence ≤ Medium.

## Process

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

### 4. Score each card — READ THE REPO
- **Uncertainty:** from the request.
- **Complexity & Volume:** grep/Read the repo to find the files and layers this card
  will actually touch; derive the scores from that real fan-out, not the wording of
  the request. **If you cannot inspect the repo, set Confidence: Low and say Volume/
  Complexity are estimated from the description.**
- Apply the security-area rule.

### 5. Resolve to a point value and a provisional band
Match to the nearest reference story → Fibonacci number. Time is a **provisional
cold-start band** only (`1→≤1h · 3→2-4h · 5→½-1d · 8→1-2d · 13→3-5d`); the real
forecast is flow (cycle time / throughput), so don't over-invest in the band.

### 6. Emit one block per card (exact shape)

```
## <Card title — verb + object>
- Story Points: <Fib>   Provisional band: <band>   Confidence: <High|Medium|Low>
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
- Totals: <sum points>
- Route to a developer before commit: <cards hitting any trigger below>
```

**Routing triggers** (don't rely on self-assessed confidence): route a card if ANY of
— points ≥ 8 · Confidence Low · touches a security-sensitive area · spans 3+ layers ·
repo couldn't be inspected · sized > 13 (auto-blocked, must split).

### 7. Confirm before publishing
Show the breakdown as a numbered list. Ask: granularity right (too coarse / too fine)?
dependencies correct? split or merge any? Iterate until approved. **Never publish
unapproved cards.**

### 8. Publish to ClickUp
For each approved card: `clickup_create_task` in the matching List, set the native
**Time Estimate** (provisional band), put Description + Acceptance criteria in the body
(with the Story Points line), and set the **Story Points** custom field if it exists.
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
