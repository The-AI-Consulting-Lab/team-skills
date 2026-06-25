# Estimation & Delivery Forecasting — house method

How we size work and how we forecast when it will be done. Project-agnostic:
the method is the same for every repo and every client tracked in ClickUp; only
the *reference stories* and the ClickUp IDs change per project (see
[Per-project calibration](#per-project-calibration)).

Two separate jobs, kept separate on purpose:

- **Sizing** — how big is a card? Story points, per card. Used to split work and
  spot the too-big ones.
- **Forecasting** — when will it be done? Flow metrics (cycle time + throughput),
  measured from ClickUp, in aggregate. *Not* derived per-card from points.

Mixing those two is the most common way estimation goes wrong, so this doc keeps
them in separate sections.

---

## TL;DR — the decisions

1. **Size effort, not time.** Each card gets a Fibonacci point value
   (1, 2, 3, 5, 8, 13). Points measure a *blend* of Complexity, Uncertainty and
   Volume — not hours.
2. **Forecast from flow, not from points×hours.** Predict delivery from measured
   **cycle time** and **throughput** (both fall out of ClickUp status history for
   free), expressed as a range. A fixed points→hours table is a cold-start crutch
   only, and a known anti-pattern if it becomes permanent.
3. **Score what you can actually know.** Uncertainty is answerable from the
   request itself. Complexity and Volume require the code — so they're derived by
   reading the repo, and marked low-confidence when the code can't be inspected.
4. **The Definition of Done is already inside the number.** Every estimate
   assumes the card is built, checked, hand-tested, reviewed, de-bugged, and
   verified against its acceptance criteria. That's where per-card slack lives.
5. **Never pad a card.** Slack lives in the DoD (per card) and in not
   over-committing the aggregate (flow). Inflating individual numbers corrupts the
   data you forecast from.
6. **AI shrinks typing, not verifying.** When code is cheap to generate, the cost
   moves to review, integration, and verification — sometimes it grows. Size a
   card by its verify-and-integrate surface, not by how fast the code appears.
7. **Recalibrate from real data.** Each cycle, compare estimates to measured cycle
   time and refresh the reference stories. That loop is what makes this real.

---

# Part 1 — Sizing (story points)

## Why points, not hours

The same card takes different wall-clock time depending on who picks it up, how
many interruptions hit, and whether it's blocked waiting on an answer. Estimating
hours directly means guessing all of that at once. Points isolate the part that's
*intrinsic to the work* — how hard, how unknown, how much of it — which is stable.
Time is then forecast separately, from measured flow (Part 2).

## The scale

A modified Fibonacci house scale: `1 · 2 · 3 · 5 · 8 · 13` — plus `21` used only
as a **flag, not an estimate**: "too big to size, split it." The gaps grow on
purpose. You can't pick "6"; you're forced to choose 5 or 8. That's honest —
bigger work is inherently less precise to size, so the scale stops pretending to
fine resolution.

- **13** is the largest a card should normally be. It's committable, but it always
  gets a second look from a developer first (see [Routing](#routing--guardrails)).
- **21** is never committed as-is — it's the signal to break the card down.

(So `21` is intentionally absent from the committable set `1/2/3/5/8/13`.)

## The three axes — and who scores each

Points reflect a **blend** of three axes, each scored 1–3. They are *not* added
up — the blend is resolved by matching to the nearest reference story (below).

| Axis | 1 | 2 | 3 | Scored from |
| --- | --- | --- | --- | --- |
| **Uncertainty** — how much is unknown? | Fully understood, done before | New tool / some open questions | Spec unclear, or depends on an answer/asset we don't have yet | **The request** — anyone can judge it |
| **Complexity** — how tricky is the thinking, and how much must be verified/trusted? | Mechanical, one obvious way | Some real logic / a design choice | Intricate logic, interacting parts, or a large surface to verify | **The code** |
| **Volume** — how much surface area? | One spot | A few files / one layer | Many files across layers (e.g. UI + service + DB + tests) | **The code** |

Uncertainty is the axis a non-technical requester genuinely knows ("is the spec
clear? do we have the asset?"). Complexity and Volume need the codebase — so the
estimating agent reads the repo (greps for the files/layers a card will touch) and
derives them from the real fan-out. **If the code can't be inspected, Volume and
Complexity are an estimate-from-description and the card is marked Confidence:
Low.**

The "how much must be verified/trusted" clause in Complexity is where the AI
caveat lives: a card where a lot of generated code lands in a sensitive area is
*not* small, even if it was fast to write.

## Resolving to a point value — reference stories

Don't compute points from a formula. **Match the card to the nearest reference
story** — a real, previously-shipped card whose size everyone agrees on — and use
its number. Each project keeps its own table (see
[Per-project calibration](#per-project-calibration)); the shape looks like this:

| Points | Reference story (example shape) |
| --- | --- |
| 1 | A one-spot, no-logic change (e.g. add a trivial endpoint) |
| 2 | Mechanical but multi-step, needs verification (e.g. a config rollout) |
| 3 | A real fix in one subsystem — logic + hands-on testing |
| 5 | A new capability across two or three layers (UI + service + config) |
| 8 | A feature whose *inputs* dominate (data model + assets + fallback), not just the code |
| 13 | A large multi-part effort — usually a sign it should be split |

Rules:

- **Round to the nearest** reference story. (Don't systematically round up —
  that's hidden padding, and it biases the data you calibrate from.)
- **Uncertainty is already reflected in the anchors.** If a card is genuinely
  riskier than its nearest anchor, pick the higher of the two candidate anchors —
  don't mechanically add a step on top.
- These are **reference stories, not measurements.** They're chosen
  retrospectively, so they look cleaner than a fresh estimate will. They get
  refreshed as real cards ship (see [Calibration](#calibration--the-loop)).

## The Definition of Done is in every number

A card isn't done when the code runs. Every estimate assumes all of:

1. Implemented.
2. Automated checks green (type-check / build / lint / tests where they exist).
3. A developer has read every line and hand-tested it — happy path + an edge case.
4. Code review (adversarial + human).
5. Known bugs fixed.
6. Acceptance criteria verified.

The DoD **activities** are constant across cards, which keeps points comparable.
Their **weight** varies — and that weight is part of what the points capture
(it's why a feature dominated by its inputs is sized by its verify surface, not
its typing).

## Security-sensitive work is never small

If a card lands generated code in a security-sensitive area — authentication,
authorization / row-level security, privileged service keys, file storage / signed
URLs, payments, or schema migrations — score **Complexity ≥ 2** and
**Confidence ≤ Medium** regardless of how little code it is. Under-verified code
in these areas isn't a slipped estimate, it's a vulnerability.

---

# Part 2 — Forecasting (flow metrics)

Points size cards. They do **not**, by themselves, tell you when work ships. For
that, measure flow — which ClickUp records for free in its status history.

## The two numbers

- **Cycle time** — how long a card takes from "in progress" to "done." Captured
  automatically from status timestamps; nobody logs hours.
- **Throughput** — how many cards (or points) finish per week.

From a few weeks of these you can forecast honestly and probabilistically:
"80% of cards finish within N days," or "this backlog of P points, at the current
throughput, lands in roughly X–Y weeks." That's a range leadership can trust,
and it needs no per-card time guess.

## Cold-start bands (provisional — delete once you have flow data)

Before there's any cycle-time history, you still sometimes need a rough time for a
card. Use these **provisional** bands — and retire them the moment real data
exists:

| Points | Rough focused effort | Rough calendar |
| --- | --- | --- |
| 1 | ≤ 1h | same day |
| 2 | 1–2h | same day |
| 3 | 2–4h | ~1 day |
| 5 | ½–1 day | 1–2 days |
| 8 | 1–2 days | 2–4 days |
| 13 | 3–5 days | split it |

> ⚠️ A *fixed* points→hours table is a known anti-pattern if it becomes
> permanent — it quietly turns relative sizing back into disguised hours and
> poisons the flow data. These bands exist only as a cold-start crutch. Once you
> have ~2–3 weeks of cycle time, forecast from measured **cycle-time-per-point**,
> not from this table.

## Optional: sprints and velocity

If a project wants fixed-length sprints, it can sum committed points per sprint
(velocity). This is **optional**, and weak when a project has only one developer:
"velocity" with one person is just one noisy number, easily wrecked by a single
sick day or a blocked card. Prefer flow metrics, which don't need a team to be
meaningful. If you do use velocity, plan the next sprint from the *last* sprint's
completed points — never from a guessed capacity number.

## For leadership — how to read these

- **Points** are *relative size*, for splitting and spotting big risks. They are
  not hours and not a productivity score.
- **The forecast** is a throughput-based *range*, not a promise of a single date.
- **Throughput / velocity is a planning input, never a performance target.** Do
  not compare it across periods to judge output, and never set it as a goal —
  especially on a small team, where it's mostly noise and where targeting it just
  guarantees inflated estimates and destroys the data the forecast depends on.

---

# Part 3 — Running the method

## Slack lives in exactly two places

1. **Per card** — the Definition of Done (review + manual test + bug-fix are
   already inside the points).
2. **In aggregate** — don't commit more than throughput says fits; leave headroom
   for bugs, reviews, and interruptions.

Never inflate an individual card. Padded numbers compound, hide real size, and
make the flow data uncalibratable.

## Routing & guardrails

The estimating agent will sometimes be confidently wrong, so don't rely on its
self-assessed confidence alone. **Route a card to a developer before it's
committed if *any* of these is true:**

- points ≥ 8
- Confidence: Low
- it touches a security-sensitive area (auth, RLS, privileged keys, storage,
  migrations)
- it spans 3+ layers
- the repo couldn't be inspected to score Volume / Complexity
- it sized to > 13 (this is auto-blocked — break it down first)

Every estimated card should also carry a one-line **"why this size might be
wrong"** — forcing the blind spot into the open is a cheap accuracy guardrail.

## Spikes — don't point research

If a card's job is to *remove uncertainty* rather than ship behavior (e.g.
"decide whether to integrate or replace system X," "figure out the data shape"),
it's a **spike**: timebox it (say 4h), don't assign points, and its output is a
decision or a follow-up card — not a feature.

## When an estimate is wrong mid-card

The most common real event: a 3 reveals itself as an 8 halfway through.

- **Don't change the original estimate.** Log the surprise as a comment and
  finish. Preserving the original is what keeps the calibration data honest.
- If the remaining work is now clearly a *different* card, split the remainder
  into a new card and estimate that.

## Bugs vs. features

- **Unplanned bugs** aren't pointed — they're interruptions, counted in throughput
  (and absorbed by the aggregate headroom). Pointing them pollutes feature data.
- **Planned fix / hardening cards** are pointed like any feature.

## Calibration — the loop

This is what turns the method from theater into something real. Each cycle (weekly
is fine):

- **Actual = ClickUp cycle time** (status `in progress` → `done`), captured
  automatically. Nobody logs hours.
- Compare each finished card's points against its cycle time. If a point value's
  median cycle time is drifting, adjust the bands or the reference stories.
- **Refresh one reference story per cycle:** replace the oldest anchor with a
  freshly-shipped card whose actual cycle time matched its points. Keep one anchor
  per point value. This keeps the table current instead of frozen.

Give the loop an owner and a fixed slot, or it won't happen — and if it doesn't
happen, every "we'll calibrate later" promise in this doc is empty.

---

## ClickUp setup (per project, one-time)

So estimates have somewhere to land:

1. **Story Points** — a *Number* custom field on the list (Fibonacci values only).
   Custom fields can't be created through the API/MCP, so add this once in the
   ClickUp UI. Until it exists, the estimate is written into the card body.
2. **Time Estimate** — ClickUp's native field (settable via the API), used only
   for the provisional cold-start band.
3. *(optional)* **Confidence** — a dropdown (High / Medium / Low).
4. Tag anything that sized **> 13** `needs-breakdown` and route it before
   committing.

Cycle time and throughput need **no setup** — ClickUp records status transitions
automatically; just read them.

---

## Per-project calibration

The method above is identical for every project. These two things are filled in
per repo / per client:

1. **Reference stories** — each project keeps its own anchor table (one real card
   per point value), refreshed by the calibration loop. New projects seed it by
   sizing 4–6 already-shipped cards relative to each other; thin projects can
   borrow another project's table until they have their own.
2. **ClickUp targets** — the Space / Folder / List IDs where this project's cards
   live, and the Story Points field ID once created.

Record both in the project's own repo (e.g. `docs/estimation/anchors.md`) or its
ClickUp space — not here. This file is the shared, project-agnostic method.

---

See [`card-breakdown-prompt.md`](./card-breakdown-prompt.md) and the
`card-estimate` skill for the tool that applies all of this.
