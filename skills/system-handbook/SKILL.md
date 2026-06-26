---
name: system-handbook
description: Generate or refresh a concise, accurate system/architecture handbook for a project — what it is, where everything lives, environments and URLs, runbooks, decisions, and gaps. Writes to ClickUp Docs (or repo markdown). Project-agnostic: reads the current repo and the live infra to get facts right. Use when asked to document a system, write architecture or ops docs, build a team handbook, or set up onboarding docs.
---

# System Handbook

Produce a handbook a real team will actually read: short, accurate, human. The guiding rule is **too much doc is the same as no doc, because nobody reads it.** Favor a tight map that points to the code over an exhaustive wiki.

This skill is **project-agnostic**. It reads the *current* repo and, where you have access, the live infrastructure, so the facts are right before a word is written.

## When to use

- "Document this system", "write our architecture / ops docs", "build a team handbook"
- "Set up onboarding docs", "a where-is-everything doc for the team"
- Refreshing an existing handbook after infra or architecture changed

## Principles

- **Concise beats complete.** Inverted pyramid: most important thing first. Tables over paragraphs. A page should read in under a minute.
- **Accurate or it's worse than nothing.** Verify every factual claim against the repo and the live infra. A confidently wrong handbook poisons trust in all of it.
- **Human voice, doc register.** No AI tells: grandiose openers, rule-of-three, em-dash tics. Run the `humanizer` skill over the prose.
- **No secrets, ever.** Document *where* credentials live (the host dashboard, repo secrets, the secret manager), never the values.
- **Two audiences.** Tag each page "Everyone" (plain language, for non-engineers) or "Devs". Most teams have both, and the leads who pay for the work are usually non-technical.
- **Owners and freshness.** Every page names an owner and a review date. A stale doc misleads more than a missing one.

## Steps

### 0. Gather the facts (read, don't guess)

Read what the repo already has, roughly in this order, and note the verified facts in a scratch file:

1. `CLAUDE.md` / `AGENTS.md` / `README.md` — the authoritative conventions and overview.
2. `docs/` — existing specs, blueprints, environment notes.
3. Deploy config: `render.yaml`, `vercel.json`, `Dockerfile`, `fly.toml`, `.github/workflows/`.
4. Manifests: `package.json`, `pyproject.toml`, `requirements.txt` — stack and pinned versions.
5. The live infra, if you can reach it: the hosting dashboard, the database project list, the real URLs. Confirm what's *running*, not just what's configured.

### 1. Decide where it lives

Default to a **space-level ClickUp Doc** in the project's space, not inside a task folder. Architecture docs are project-wide and durable, so they belong at the top, separate from tasks. If the team lives in the repo instead, a `docs/HANDBOOK.md` set works too. Confirm the target if it's unclear.

### 2. Draft the pages

Use the page set in `references/page-structure.md`. It pairs the C4 model (context, containers, components) for architecture with arc42-style operational sections (runbooks, decisions, glossary), kept light. Adapt to the project. Drop pages that don't apply, and never ship a page with nothing real in it.

### 3. Fact-check adversarially

Run `codex` against the repo to challenge the claims:

```bash
codex exec --sandbox read-only --skip-git-repo-check "Fact-check these handbook claims against THIS repo (read CLAUDE.md, deploy config, manifests). For each claim that is wrong, stale, or unsupported, give the correct value. End with ACCURATE / MINOR / MAJOR." < scratch-facts.md
```

**Mind the branch.** codex reads the current checkout. If the repo has `develop` / `main` divergence, verify against the right branch (or curl the live `/version` endpoint) before trusting a "wrong" verdict. Many false alarms come from a stale checkout. Fix every real error.

### 4. Humanize and trim

Run the `humanizer` skill over the prose. Then cut: remove AI tells, drop gratuitous em-dashes (commas, periods, or parentheses instead; keep directional arrows in flow diagrams), and delete any sentence that doesn't earn its place. Re-read each page asking "would a busy person actually read this?"

### 5. Write it to ClickUp

Create the Doc (space-level, PUBLIC), then add one page per section. Give each page a name, a subtitle, an owner line, and a review date. List the pages at the end to confirm they all landed and are in order.

## Writing rules (quick reference)

- Lead with the answer. Descriptive headings, so the page is scannable from the sidebar alone.
- Tables for anything with rows: environments, services, secrets, access.
- Direct sentences, plain words, varied rhythm.
- Mark every page's audience and owner.
- Link to the repo (`CLAUDE.md`, `docs/`) for depth instead of copying it in.

Full page template and a worked example: `references/page-structure.md`.
