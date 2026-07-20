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
   not a terse one. If a field has nothing to say, write what makes it empty
   ("Depends on: nothing"); never drop the line.
   Type comes first and decides which fields are required:
     feature (default) → Type + all 8 fields below
     spike             → Type, Description, Acceptance criteria, Timebox — NO points
     bug (unplanned)   → Type, Description, Acceptance criteria — NO points
   ## <title — verb + object>
   - Type: feature
   - Story Points: <n>  Confidence: <H/M/L>
   - Sizing: U/C/V → n (nearest reference: "<anchor>")
   - Touches: <files/layers, or "not inspected">
   - Description: <2-4 plain sentences anyone can read>
   - Acceptance criteria: <checkboxes; each observable and testable — a reader can tell
     pass from fail without asking. "Works reliably" is not an acceptance criterion.>
   - Why this size might be wrong: <the one blind spot>
   - Assumptions / Risks / Depends on: <…>
   - Definition of Done: standard (build + checks + hand-test + review + bug-fix + AC)
   NO delivery time on any card — not a band, not an hour figure. A spike's Timebox
   (e.g. 4h) is the sole exception and appears only on a spike.
   If the repo could not be inspected, tag the card `desc-only` and cap Confidence at
   Medium.
   Before accepting a 5: if the card involves reliability/offline/cellular behavior, a
   security area, an unresolved design choice, or a broad verification surface, re-check
   it against the 8 and 13 anchors first. 5 is the most over-used number on this scale.
   Footer — Totals: <sum of pointed cards> pts, plus <n> unpointed (spikes/bugs, never
   folded into the total).
   Route to a developer before commit if ANY: points ≥ 8, Confidence Low, security area,
   3+ layers, a `desc-only` card that sized ≥ 5, or > 13 (must split). Unpointed cards
   can't trip a points threshold — route any spike or bug in a security area or whose
   outcome decides another card's size.

6. Ask whether the granularity and dependencies are right BEFORE anything is created.
```

---

## Publishing

With the skill + ClickUp MCP, cards are created automatically in the right List. By
hand: paste **the whole block** into the ClickUp task description — not a summary of it;
the fields people trim are the ones carrying the risk. Put the point value in the
**Story Points** custom field (or in the card body if the project hasn't created that
field yet), and **leave Story Points blank on spikes and unplanned bugs** — a blank
there is correct, an invented number is not. Tag spikes `spike` and unplanned bugs
`bug`. Find the target List in the project's `anchors.md` — do not hardcode an ID.

**Leave the native Time Estimate empty.** Time is forecast in aggregate from flow
(cycle time + throughput), never assigned per card. The cold-start bands in
`methods/estimation/README.md` are a private sanity-check only — writing one onto a
card recreates hour-estimating and poisons the flow data the forecast depends on.
