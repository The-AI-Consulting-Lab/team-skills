# <Product name>: Release Notes

<!--
  This is the TACL house format for a client release note, distilled from real notes the
  team has shipped. Write the markdown in exactly this shape, then render it with
  scripts/release/render.* using:
     --title    "<Product name>: Release Notes"
     --subtitle "RELEASED TO PRODUCTION · <MONTH DAY, YEAR>"
     --footer   "<CLIENT> · CONFIDENTIAL · PRODUCT UPDATE"
     --logo     <the client's letterhead logo>

  Rules that make it read like the samples:
   - Group by what the client can now DO, never by commit type.
   - Two bullet levels only: a bold capability, then plain-language detail underneath.
   - No table names, no file paths, no endpoints, no PR numbers, no internal jargon.
   - Cut every internal story: refactors, CI, evals, dependency bumps, test coverage.
   - The subtitle and footer are rendered from the flags above, not written in the body.
  Delete this comment before rendering.
-->

## Summary

One short paragraph in plain English: what this release is about, and the before/after so
the reader knows why it matters. State that the updates are live. Example shape: "This
release brings X, Y, and Z. Before it, <the gap this closes>."

## <Capability area>

- **<A capability, in the client's words>**
  - What it does, plainly
  - A second detail if it helps
  - A caveat or a "planned for later" note, if there is one
- **<Another capability in the same area>**
  - What it does

## <Another capability area>

- **<Capability>**
  - Detail

## Bug Fixes

- **<Short name for the fix>**
  - What was wrong, and what now happens instead
  - The cause in one plain line, only where it helps the reader trust the fix

## Worth Knowing

- **<A caveat, a heads-up, or context>**
  - Something the reader should know that is not a feature: a change noted for completeness,
    what needs live validation, or where feedback is most useful this week
- **Feedback**
  - Reports of any unexpected behaviour are welcome
