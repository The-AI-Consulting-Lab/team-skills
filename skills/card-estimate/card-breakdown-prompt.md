# Card Breakdown & Estimation Prompt (fallback)

The copy-paste fallback for anyone without the `card-estimate` skill. Same method,
manual. Project-agnostic — it reads the repo it's pasted into.

> Prefer the skill: `/card-estimate` does all of this as one invocation and can
> publish to ClickUp directly. Use this prompt only when the skill isn't installed.

## How to use

1. Open Claude Code in the project repo.
2. Paste the block below, replacing `<<<PASTE THE REQUEST HERE>>>`.
3. Review the output (especially the routing flags), then create the cards.

---

```text
You are sizing work using the TACL house method (methods/estimation/README.md if
available; otherwise the rules below). Sizing is in Fibonacci story points; time is
forecast from flow, NOT derived per card.

REQUEST:
<<<PASTE THE REQUEST HERE>>>

1. LOAD CALIBRATION. Look for docs/estimation/anchors.md in this repo for the
   project's reference stories, ClickUp IDs, and security-sensitive areas. If absent,
   use generic anchors and say so.

2. SPLIT into the smallest independently-shippable cards (vertical slices, each ≤ 8
   points). If a card's only job is to remove uncertainty, make it a timeboxed SPIKE
   (no points).

3. SCORE each card 1-3 on three axes:
   - Uncertainty (from the request): 1 understood / 2 open questions / 3 spec unclear
     or depends on a missing answer/asset.
   - Complexity and Volume (FROM THE CODE — grep/read the repo for the files and
     layers the card touches; derive from the real fan-out, not the wording). If you
     can't inspect the repo, set Confidence: Low.
   Security-sensitive code (auth, RLS/authz, privileged keys, storage, migrations) →
   Complexity ≥ 2, Confidence ≤ Medium.

4. RESOLVE to Fibonacci (1,2,3,5,8,13) by matching the nearest reference story; round
   to NEAREST (not up); if riskier than the nearest anchor, take the higher one.
   Remember the Definition of Done (build + checks + hand-test + review + bug-fix + AC)
   is already inside the number — do not pad. Size by verify-and-integrate surface,
   not typing speed.

5. OUTPUT one block per card. Emit EVERY field — a missing field is a failed card,
   not a terse one. Do NOT write any time value onto a card (see step 7).
   ## <title — verb + object>
   - Story Points: <n>  Confidence: <H/M/L>
   - Sizing: U/C/V → n (nearest reference: "<anchor>")
   - Touches: <files/layers, or "not inspected">
   - Description: <2-4 plain sentences anyone can read>
   - Acceptance criteria: <checkboxes; each observable and testable>
   - Why this size might be wrong: <the one blind spot>
   - Assumptions / Risks / Depends on: <…>
   - Definition of Done: standard (build + checks + hand-test + review + bug-fix + AC)
   If the repo could not be inspected, tag the card `desc-only` and cap Confidence at
   Medium.
   Footer — Route to a developer before commit if ANY: points ≥ 8, Confidence Low,
   security area, 3+ layers, repo not inspected, a `desc-only` card that sized ≥ 5,
   or > 13 (must split).

6. Ask whether the granularity and dependencies are right BEFORE anything is created.
```

---

## Publishing

With the skill + ClickUp MCP, cards are created automatically in the right List. By
hand: paste each block into a ClickUp task and put the point value in the **Story
Points** custom field (or in the card body if the project hasn't created that field
yet). Find the target List in the project's `anchors.md` — do not hardcode an ID.

**Leave the native Time Estimate empty.** Time is forecast in aggregate from flow
(cycle time + throughput), never assigned per card. The cold-start bands in
`methods/estimation/README.md` are a private sanity-check only — writing one onto a
card recreates hour-estimating and poisons the flow data the forecast depends on.
