# TACL team-skills

Shared **Claude Code skills** and **engineering methods** for The AI Consulting Lab,
used across every client project (LCA, FEP, H2, Sashco, Thor, Daikin, …). One home,
so the team stays in sync instead of each repo carrying its own drifting copy.

## What's here

```
.claude-plugin/   Marketplace + plugin manifests (makes this repo installable)
methods/          Reference docs — the "how we work" (project-agnostic)
  estimation/     Sizing & delivery-forecasting method (story points + flow metrics)
skills/           Installable Claude Code skills
  card-estimate/  Break a request into sized, ClickUp-ready cards
  transcribe/     Turn a video URL (call recording, YouTube, …) into text
  release-notes/  Cut a release: changelog + client note (branded .docx) + tag
```

## Install via the Claude Code marketplace (recommended)

This repo is a Claude Code **plugin marketplace** (manifest at
`.claude-plugin/marketplace.json`). Add it once, then install the plugin — Claude Code
keeps it updated for you, on any machine.

In an interactive `claude` session:

```
/plugin marketplace add The-AI-Consulting-Lab/team-skills
/plugin install tacl-team-skills@team-skills
```

(Or use the **Settings → Plugins → Add marketplace** dialog and enter
`The-AI-Consulting-Lab/team-skills`.) The skills then work in every project — e.g.
`/tacl-team-skills:card-estimate`.

## Install a single skill manually (alternative)

Skills live in `~/.claude/skills/` (global — works in every project on your machine).
To install one without the marketplace:

```bash
# one-time: clone this repo somewhere
git clone https://github.com/The-AI-Consulting-Lab/team-skills.git ~/src/team-skills

# install (or re-install to update) a skill — symlink keeps it in sync with git pull
ln -sfn ~/src/team-skills/skills/card-estimate ~/.claude/skills/card-estimate
```

Then in any project: `/card-estimate`. To update later: `git pull` in the clone — the
symlink picks it up. (Prefer a copy over a symlink? `cp -r` instead, and re-copy to
update.)

## Methods vs. skills

- **Methods** are reference reading (humans + agents). They're project-agnostic.
- **Skills** are the executable tools that apply a method.
- **Per-project calibration stays in each project's own repo**, not here. For
  estimation, that's `docs/estimation/anchors.md` in the project (its reference
  stories + ClickUp IDs + security-sensitive areas). This repo holds only the shared
  method and the skill.

## The estimation method (start here)

`methods/estimation/README.md` — size effort in Fibonacci story points; forecast
delivery from flow metrics (cycle time + throughput) measured in ClickUp. The
`card-estimate` skill applies it: it reads the current repo to size cards, reads the
project's `anchors.md` for reference points, and publishes to ClickUp via the MCP.

## Adding a skill

1. New folder under `skills/<name>/` with a `SKILL.md` (frontmatter: `name`,
   `description`). The marketplace auto-discovers it — no manifest edit needed.
2. Keep it project-agnostic; put anything project-specific in the project repo.
3. Add it to the index above; bump `version` in `.claude-plugin/marketplace.json` and
   `.claude-plugin/plugin.json` so installs pick it up. Commit, push.

## Conventions

- Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).
- Skills must be self-contained (no dependency on a specific project's files); when a
  skill needs project context, it should look for it in the current repo at runtime.
