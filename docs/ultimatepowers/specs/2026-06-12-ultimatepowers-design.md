# Ultimatepowers — Design

**Date:** 2026-06-12
**Status:** Approved for planning (autonomous session; user supplied requirements directly)
**Upstreams:** `obra/superpowers` v5.1.0 (commit 6fd4507, MIT, Jesse Vincent) and `grosu/formal-verification-kit` (commit d0d07ba, MIT, Grigore Rosu) — both vendored as submodules under `reference/`.
**Research:** `docs/research/superpowers-analysis.md`, `docs/research/fvk-analysis.md`.

## Goal

Produce **ultimatepowers**: a standalone, installable plugin (Claude Code, Codex, Cursor, Gemini, OpenCode) that is superpowers with FVK-style formal analysis fused into its review pipeline. K-notation formal reasoning runs **automatically** during code review and produces higher-quality findings, which feed back into the implementation loop.

## Requirements (from user)

1. **UX-identical to superpowers.** Same skills, same workflow (brainstorm → spec → plan → execute → review), same artifact conventions. No new commands the user must learn.
2. **FVK fully automatic.** No opt-in flag. Whenever the superpowers flow reviews code, formal analysis happens.
3. **Formal artifacts organized like other superpowers artifacts** (siblings of `specs/` and `plans/`).
4. **One bundle** — not two cooperating plugins.
5. **FVK digested, not copied verbatim.** Rewrite its knowledge and workflow into superpowers-style skills.

## Approaches considered

- **A. Minimal graft** — one `formal-code-review` skill bolted onto `requesting-code-review`. Rejected: one skill cannot carry the K-notation depth (reachability claims, circularities, VC discharge, honesty rules); per-task SDD reviews would miss it; knowledge ends up shallow.
- **B. Full integration (chosen)** — copy superpowers verbatim, rebrand, add a small family of formal skills with digested FVK knowledge, and wire a formal reviewer into *both* review paths (standalone review and per-task SDD chain) using superpowers' own prompt-template precedent.
- **C. Companion plugin** — keep FVK separate, cross-reference. Rejected: violates req. 4; cross-plugin skill references are fragile; two installs.

## Architecture

### Base: superpowers, rebranded

The plugin root mirrors superpowers v5.1.0: 14 skills, SessionStart hook (injects `using-superpowers`), 6 platform manifests, test harness, scripts. Skill *names* stay identical (`brainstorming`, `writing-plans`, …) — only the namespace prefix changes (`superpowers:x` → `ultimatepowers:x`). Upstream's historical `docs/` and `RELEASE-NOTES.md` are not copied (they live in the submodule).

### New: four formal skills (digested from FVK)

| Skill | Purpose |
|---|---|
| `formal-reasoning-foundations` | Reference skill: K-as-notation — configurations/cells, rewrites `x \|-> (OLD => NEW)`, `requires`/`ensures`, `?`-existentials, `[all-path]`, `...` framing; reachability claims as generalized Hoare triples; circularity rule + guardedness for loops/recursion; soundness side conditions; two-tier VC discharge; spec-only abstraction functions. Includes a claim-shape catalog (distilled from FVK's 13 worked examples) in `references/`. |
| `formalizing-code` | Workflow: read intent AND implementation (divergence is a finding) → build a mini semantics fragment for only the constructs used → per-function reachability claim → per-loop/recursion circularity claim with explicit soundness side conditions → findings. Supports **diff-scoped** operation (FVK upstream is whole-project only). |
| `verifying-specs` | Constructed-proof workflow: symbolic execution, guarded-coinduction circularity discharge, VC discharge (Z3-tier vs `[simplification]` lemmas), escalation boundaries, the honesty gate (constructed ≠ machine-checked; capability gaps ≠ code bugs; partial vs total correctness always stated). |
| `formal-code-review` | The integration skill: orchestrates formalizing + verifying over a diff in a review context; maps proof-derived findings into the code-reviewer severity schema (Critical/Important/Minor + merge verdict); persists artifacts; includes scoping rules (see Cost control). |

Key FVK principles carried over intact: **spec-difficulty is itself a bug signal**; findings cite concrete `input → observed vs expected` evidence; stuck semantics = runtime exception; positive findings and deliberate non-findings are reported; nothing constructed is ever labeled machine-checked.

### Wiring (the fully-automatic part)

Superpowers precedent: `requesting-code-review/code-reviewer.md` is the reviewer prompt template; SDD's `code-quality-reviewer-prompt.md` is a thin wrapper delegating to it. We extend the same pattern:

1. **`requesting-code-review/formal-reviewer.md`** (new template, sibling of `code-reviewer.md`): instructs a subagent to invoke `ultimatepowers:formal-code-review`, analyze the BASE_SHA..HEAD_SHA diff, persist artifacts, and return findings in the standard severity schema. Findings include the formal evidence line.
2. **`requesting-code-review/SKILL.md`** (edited): dispatches **two reviewers in parallel** — conventional + formal — then merges into one report (dedupe overlaps; formal findings keep their evidence). One merged "Ready to merge?" verdict; Critical from either blocks.
3. **`subagent-driven-development/SKILL.md`** (edited): after spec review passes for a task, the code-quality reviewer and a new **`formal-verification-reviewer-prompt.md`** wrapper dispatch in parallel; both must approve before the next task. The end-of-plan final review uses the full two-reviewer `requesting-code-review` flow (deeper, whole-change scope).
4. **`using-superpowers`** (hook-injected skill): rebranded text; one line noting review includes automatic formal analysis. No new user-facing gestures.

Intent sources for review-time formalization, in priority order: plan/spec docs under `docs/ultimatepowers/` → commit messages → code comments/docstrings. Missing or contradicted intent is reported as a finding (FVK's intent-spec mode), never silently assumed.

### Artifacts (req. 3)

```
docs/ultimatepowers/
  specs/   YYYY-MM-DD-<topic>-design.md      (existing convention, renamed namespace)
  plans/   YYYY-MM-DD-<feature>.md           (existing convention, renamed namespace)
  verification/ YYYY-MM-DD-<topic>/          (NEW, written by the formal reviewer)
    SPEC.md        — contracts in K notation + plain language
    FINDINGS.md    — evidence, classification, recommended change, status labels
    PROOF.md       — constructed-proof sketch (final/deep reviews)
    <mod>.k, <mod>-spec.k — runnable K artifacts (deep mode only; keep the machine-check escape hatch)
```

Per-task SDD reviews append to the feature's `verification/` dir rather than creating one per task. Unlike upstream superpowers (review output ephemeral), formal review output is durable — that is deliberate and satisfies req. 3.

### Cost control (inside `formal-code-review`, automatic — not a user knob)

- **Per-task mode:** claims only for functions/branches the diff touches; semantics fragment reused/extended across tasks of one feature.
- **Final-review mode:** adds cross-function composition (Transitivity) and deeper circularity discharge; may emit full `.k` artifacts.
- **Trivial-diff fast path:** doc-only/rename-only/config-only changes → record "no formal content changed" in FINDINGS.md and approve; no claims constructed.

## Rebrand policy

Rename: plugin name in all 6 manifests (+ dev marketplace `ultimatepowers-dev`); `superpowers:` cross-refs (7 skill files, ~30 occurrences, + test files); `docs/superpowers/` → `docs/ultimatepowers/` (5 skill files + test scripts); `~/.config/superpowers/` legacy paths → `~/.config/ultimatepowers/`; hook text ("You have superpowers" → "You have ultimatepowers"); OpenCode plugin filename/content; `superpowers-small.svg` → `ultimatepowers-small.svg` (+ codex manifest ref); README/CLAUDE.md/.github. Drop cursor manifest's stale `./agents/`, `./commands/` pointers.

Do **not** rename: LICENSE copyright lines (MIT requires retention); skill directory names (incl. `using-superpowers` — the hook, GEMINI.md, and OpenCode bootstrap reference it; renaming breaks all three); upstream credits (replace with proper attribution, don't string-substitute). `scripts/bump-version.sh --audit` (config-driven) serves as the post-rebrand drift checker.

## Licensing & attribution

MIT throughout. LICENSE retains "(c) 2025 Jesse Vincent" and adds "(c) 2026 Grigore Rosu (formal-verification skills, derived from formal-verification-kit)" plus a line for this derivative. README credits both upstreams with links and cites the matching-logic/K papers FVK cites (LMCS'17, FM'12, LICS'13/'19, OOPSLA'20).

## Out of scope

- Running the K toolchain (`kompile`/`kprove`) — we keep FVK's stance: constructed reasoning, with runnable `.k` artifacts emitted in deep mode so machine-checking stays possible later.
- Formal capture during brainstorming/planning (insertion point exists; deferred — YAGNI, keeps front-of-funnel UX identical).
- Auto-deleting tests on redundancy findings (FVK's honesty gate: that advice is machine-check-gated; we only ever recommend).
- New slash commands or agents (upstream removed theirs in v5.1.0; we follow).

## Risks

- **Token cost of always-on formal review** → mitigated by the three-mode scoping above.
- **Formal reviewer hallucinating "proofs"** → honesty machinery is mandatory skill content: status labels (`constructed` / `machine-checked` / `escalation-bounded`), `[ESCALATION BOUNDARY]` markers never faked, capability gaps reported as gaps.
- **Drift from upstream superpowers** → submodules pinned; README documents the delta surface (list of edited upstream files) to ease future rebases.
- **Co-installation with superpowers** → README warns: do not install both (duplicate SessionStart hooks).

## Verification of this build

Structural: every manifest path resolves; every `ultimatepowers:<skill>` reference resolves to an existing skill dir; zero dangling `superpowers:` refs outside LICENSE/credits/submodules/research docs; JSON manifests parse; frontmatter on all skills has exactly `name` + `description`; `bump-version.sh --audit` clean. Behavioral spot-check: headless harness's review test (plants SQL-injection bug; reviewer must flag Critical) adapted to confirm the formal reviewer also triggers — run if budget allows, otherwise documented as follow-up.
