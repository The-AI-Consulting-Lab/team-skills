# Page structure

The default handbook is ten short pages. Adapt to the project: merge thin ones, drop what doesn't apply, but keep the order (it reads top to bottom for a newcomer).

| # | Page | Audience | Holds |
|---|---|---|---|
| 1 | Start Here | Everyone | One-paragraph "what it is", a where-things-live table, the rules for the handbook |
| 2 | Architecture | Devs | C4: context (who and what it talks to), containers (the moving parts), the data flows that matter |
| 3 | Environments & URLs | Everyone | Local / staging / prod table: URLs, databases, deploy triggers. How a change reaches prod |
| 4 | Infrastructure & Deploy Flow | Devs | The concrete hosting, database, and repo IDs; what a push to each branch triggers |
| 5 | Data & Domain Glossary | Everyone | The vocabulary a newcomer needs; key tables and views |
| 6 | Conventions & Standards | Devs | Branching, commits, versioning, the non-obvious rules. Summarize; point to CLAUDE.md |
| 7 | Runbooks | Devs | Step-by-step for the ops you actually run: deploy, rollback, "X is broken", rotate a secret |
| 8 | Secrets, Access & Onboarding | Devs + Leads | Where each secret lives (never values), an access matrix, an onboarding checklist |
| 9 | Decision Log (ADRs) | Everyone | One short entry per big decision: what and why. So future members don't have to dig |
| 10 | Gaps & Recommendations | Leads | An honest list of what's missing and worth adding, by priority |

## What each page is for

- **Start Here** is the map. A reader should know in 30 seconds what the system is and where to click next. Include a where-things-live table (app URLs, repo, database, hosting, project management).
- **Architecture** uses [C4](https://c4model.com): a context view (users + external systems), a container view (a simple ASCII box diagram is fine), and the handful of data flows that surprise people.
- **Environments & URLs** is usually the most-read page. A three-column table (local, staging, prod) with URL, database, what it deploys from, and who uses it. Add the promote flow.
- **Infrastructure** has the concrete refs (project IDs, service names, regions). These appear in URLs, so they aren't secret, but say so explicitly.
- **Glossary** is for the non-engineers and new hires. Define the domain terms and the key tables.
- **Conventions** summarizes; the repo's CLAUDE.md is the living version. Don't duplicate it, point to it.
- **Runbooks** are tested procedures, numbered. Keep them honest; a wrong runbook is dangerous.
- **Secrets/Access** lists where secrets live and who has access. Never the values.
- **Decision Log** is short ADRs: "Decision. Why." Add one when a real call is made.
- **Gaps** is the value-add. What monitoring, backups, or automation is missing? Prioritize, and frame as proposals, not commitments.

## Page footer

End every page with an owner and review date:

```
_Owner: <name>. Reviewed <YYYY-MM-DD>._
```

## Worked example (abridged)

A "Start Here" page that gets it right: leads with the one-line what-it-is, then a where-things-live table, then the rules. No throat-clearing, no "this comprehensive guide will".

```markdown
# <Project>: System Handbook

How the system is built, where everything lives, and how to run it. For the whole
team, technical or not. Pages tagged _Everyone_ are written for non-engineers.

## What it is

<One paragraph: what it does, for whom, the stack in one sentence.>

## Where things live

| What | Where |
|---|---|
| Production app | <url> |
| Staging app | <url> |
| Code | <repo> |
| Database | <provider + project names> |
| Hosting | <provider + project> |
| Project management | <ClickUp space> |

## Rules for this handbook

- No secrets here. They live in <host> and <secret store>.
- It's a living doc. Fix what's wrong; review yearly.
- The repo has the depth (CLAUDE.md, docs/). This is the map.

_Owner: <name>. Reviewed <date>._
```

Note what's absent: no "single source of truth for everything", no em-dashes as decoration, no rule-of-three. Just the answer.
