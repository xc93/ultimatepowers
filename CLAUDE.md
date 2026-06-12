# Ultimatepowers — Contributor Guidelines

Ultimatepowers is a derived plugin: obra/superpowers (v5.1.0) fused with a
formal-verification review capability digested from grosu/formal-verification-kit.
Both upstreams are pinned read-only as git submodules under `reference/`.

## Rules

- Never modify anything under `reference/` — those are the upstreams of record.
- Never PR rebrand or fork-specific changes to either upstream (upstream policy
  explicitly rejects them). Ultimatepowers lives independently.
- Skill names and directory layouts mirror upstream superpowers exactly; only the
  namespace prefix (`ultimatepowers:`) and the four formal skills differ. The full
  delta surface is listed in README.md.
- Skills are behavior-shaping content. Modify them via ultimatepowers:writing-skills
  (baseline pressure-test first). Do not reword Red Flags tables, rationalization
  tables, or "your human partner" language without eval evidence.
- The four formal skills must never claim machine-checked status for constructed
  reasoning, never fake `[ESCALATION BOUNDARY]` obligations, and never auto-delete
  tests. These honesty rules are load-bearing; treat them as frozen.

## Checks before any commit

```bash
scripts/check-structure.sh      # structural invariants (namespace refs, manifests, frontmatter)
scripts/bump-version.sh --audit # version-string drift
```

## Artifact conventions

`docs/ultimatepowers/specs/` (designs), `docs/ultimatepowers/plans/` (plans),
`docs/ultimatepowers/verification/` (formal review artifacts, written by the
formal reviewer).
