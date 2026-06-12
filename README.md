# Ultimatepowers

Ultimatepowers is the complete software development methodology from superpowers, extended with K-notation formal verification fused into its review pipeline — composable skills plus the session-start instructions that make your coding agent actually use them. The formal method is digested from the formal-verification-kit (FVK): contracts and proof sketches written in K notation, never an executed toolchain. Formal analysis runs automatically during every code review; you don't ask for it. The UX is otherwise identical to superpowers — same skills, same workflow, no new commands.

> **⚠️ Do not install ultimatepowers alongside superpowers.** Ultimatepowers bundles every superpowers skill under its own namespace. Installing both gives you duplicate SessionStart hooks, two competing bootstraps, and identically-named skills. Uninstall superpowers first.

## How it works

It starts the moment you fire up your coding agent. As soon as it sees you're building something, it *doesn't* jump into writing code. It steps back and asks what you're really trying to do. Once it has teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest.

After you sign off on the design, your agent writes an implementation plan clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow — true red/green TDD, YAGNI, DRY. Then, once you say "go", it launches a subagent-driven development process: a fresh subagent per task, each one's work inspected and reviewed before moving forward.

Here is what ultimatepowers changes: every review dispatches two reviewers in parallel — a conventional code reviewer and a formal one. The formal reviewer derives contracts from your plan/spec intent, constructs proof sketches against the changed code, and files findings with concrete counterexample inputs (`input → observed vs expected`). The evidence persists under `docs/ultimatepowers/verification/` in your project, next to your specs and plans.

Because the skills trigger automatically, you don't need to do anything special. Your coding agent just has ultimatepowers.

## Installation

Installation differs by harness. If you use more than one, install ultimatepowers separately for each.

The canonical repository URL is `https://github.com/xc-math/ultimatepowers`. It appears in this README's install commands, the platform manifests, and `.opencode/INSTALL.md`; if hosting elsewhere, it is one search-and-replace away.

### Claude Code

- Register the marketplace and install:

  ```text
  /plugin marketplace add xc-math/ultimatepowers
  /plugin install ultimatepowers@ultimatepowers-dev
  ```

- Or from a local clone:

  ```text
  /plugin marketplace add /path/to/ultimatepowers
  /plugin install ultimatepowers@ultimatepowers-dev
  ```

- Or for testing without installing:

  ```bash
  claude --plugin-dir /path/to/ultimatepowers
  ```

### Codex CLI / Codex App

Install from a local clone via the plugins interface. The `skills` manifest is at `.codex-plugin/plugin.json`.

### Cursor

Point the plugin system at the repo: the manifest is `.cursor-plugin/plugin.json`, and hooks load via `hooks/hooks-cursor.json`.

### Gemini CLI

```bash
gemini extensions install https://github.com/xc-math/ultimatepowers
```

### OpenCode

Follow `.opencode/INSTALL.md`: add the plugin array entry `ultimatepowers@git+https://github.com/xc-math/ultimatepowers.git` to your `opencode.json`, then restart OpenCode.

## The formal-verification delta (what ultimatepowers adds to superpowers)

- **Four new skills:** `formal-reasoning-foundations` (+ `references/claim-shapes.md`), `formalizing-code`, `verifying-specs`, `formal-code-review` — FVK's method digested into superpowers-style skills. K is used as notation; no toolchain is ever executed. Reasoning is constructed, with a machine-check escape hatch via emitted runnable `.k` artifacts in deep mode.
- **Automatic wiring:** `requesting-code-review` dispatches conventional + formal reviewers in parallel with one merged verdict (Critical from either blocks). Subagent-driven development runs the formal reviewer in parallel with the code-quality reviewer after spec review passes on every task. The end-of-plan final review runs both over the whole branch in final-review mode.
- **Cost control:** trivial-diff fast path / per-task mode / final-review mode — selected automatically from the diff and the review context, not a knob.
- **Honesty guarantees:**
  - constructed is never called machine-checked
  - `[ESCALATION BOUNDARY]` obligations are never faked as `[trusted]`
  - capability gaps are reported as gaps, not code bugs
  - test removal is recommendation-only and machine-check-gated
- **Durable artifacts:** `docs/ultimatepowers/verification/YYYY-MM-DD-<topic>/` (SPEC.md, FINDINGS.md, PROOF.md, optional `.k`) — siblings of `specs/` and `plans/`.

## Delta surface (edited upstream files — for future rebases against superpowers)

These are the files that differ from upstream obra/superpowers — consult this list when rebasing onto a newer superpowers.

- **Modified:** `skills/requesting-code-review/SKILL.md`, `skills/subagent-driven-development/SKILL.md`, `skills/using-superpowers/SKILL.md`, `skills/using-superpowers/references/gemini-tools.md`, `hooks/session-start` (rebrand only), all 6 manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `gemini-extension.json`, `package.json`), `.version-bump.json`, `CLAUDE.md`, `.opencode/INSTALL.md`, `LICENSE` (copyright additions), `tests/claude-code/test-requesting-code-review.sh` (dual-reviewer prompt wording), plus mechanical namespace/path rebrand across `skills/`, `hooks/`, `tests/`.
- **Added:** `skills/formal-reasoning-foundations/`, `skills/formalizing-code/`, `skills/verifying-specs/`, `skills/formal-code-review/`, `skills/requesting-code-review/formal-reviewer.md`, `skills/subagent-driven-development/formal-verification-reviewer-prompt.md`, `scripts/check-structure.sh`.
- **Renamed:** `.opencode/plugins/superpowers.js` → `ultimatepowers.js`, `assets/superpowers-small.svg` → `ultimatepowers-small.svg`.
- **Removed (vs upstream):** upstream `docs/`, `RELEASE-NOTES.md`, `.github/`, `CODE_OF_CONDUCT.md`, `scripts/sync-to-codex-plugin.sh`, `tests/codex-plugin-sync/`.

## The basic workflow

1. **`brainstorming`** — Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves a design document.

2. **`using-git-worktrees`** — Activates after design approval. Creates an isolated workspace on a new branch, runs project setup, verifies a clean test baseline.

3. **`writing-plans`** — Activates with an approved design. Breaks work into bite-sized tasks; every task has exact file paths, complete code, verification steps.

4. **`subagent-driven-development`** or **`executing-plans`** — Activates with a plan. Dispatches a fresh subagent per task with staged review (spec compliance first, then code quality + formal verification in parallel), or executes in batches with human checkpoints.

5. **`test-driven-development`** — Activates during implementation. Enforces RED-GREEN-REFACTOR: write a failing test, watch it fail, write minimal code, watch it pass, commit.

6. **`requesting-code-review`** — Activates between tasks. Dispatches conventional + formal reviewers in parallel; merged report; Critical from either blocks.

7. **`finishing-a-development-branch`** — Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up the worktree.

The agent checks for relevant skills before any task. These are mandatory workflows, not suggestions.

## What's inside

**Testing**
- **test-driven-development** — RED-GREEN-REFACTOR cycle (includes a testing anti-patterns reference)

**Debugging**
- **systematic-debugging** — 4-phase root-cause process (includes root-cause-tracing, defense-in-depth, and condition-based-waiting techniques)
- **verification-before-completion** — run the verification, read the output, then claim success

**Collaboration**
- **brainstorming** — Socratic design refinement
- **writing-plans** — detailed implementation plans
- **executing-plans** — batch execution with checkpoints
- **dispatching-parallel-agents** — concurrent subagent workflows
- **requesting-code-review** — parallel conventional + formal review with a merged verdict
- **receiving-code-review** — responding to feedback with rigor, not performative agreement
- **using-git-worktrees** — isolated workspaces for feature work
- **finishing-a-development-branch** — merge/PR decision workflow
- **subagent-driven-development** — fresh subagent per task with staged review

**Formal verification**
- **formal-reasoning-foundations** — the notation, proof-system, and claim-shape reference behind the formal skills (includes `references/claim-shapes.md`)
- **formalizing-code** — intent capture, per-function reachability claims in K notation, per-loop and recursion circularities
- **verifying-specs** — proof construction: symbolic execution, circularity discharge, verification conditions, escalation boundaries, honest status labels
- **formal-code-review** — orchestrates the two skills above over a git diff during review and maps proof-derived findings into review severities

**Meta**
- **writing-skills** — create new skills following best practices
- **using-superpowers** — the skills-system bootstrap (directory name unchanged from upstream; the session-start hook depends on it)

## Testing

- `tests/` — the behavioral test harness inherited from upstream (rebranded), including skill-triggering, Claude Code integration, and OpenCode tests. See `tests/claude-code/run-skill-tests.sh`.
- `scripts/check-structure.sh` — the structural checker: SKILL.md frontmatter, namespace-reference resolution, stale-reference detection, manifest parsing, hook executability, and the formal-verification surface.

Documented follow-up: adapt `tests/claude-code/test-requesting-code-review.sh` (the planted SQL-injection test) to also assert that the formal reviewer dispatches and flags the vulnerability as Critical.

## Credits & licensing

- Ultimatepowers is a derivative of [obra/superpowers](https://github.com/obra/superpowers) v5.1.0 by Jesse Vincent (MIT) — all core skills, hooks, tests, and platform integrations originate there.
- The formal-verification skills digest [grosu/formal-verification-kit](https://github.com/grosu/formal-verification-kit) by Grigore Rosu (MIT) — K-as-notation method, claim shapes, findings discipline, and honesty rules.
- Both upstreams are pinned as read-only submodules under `reference/`. Do not PR rebrand changes upstream.

The formal method stands on this published work:

- Roșu, *Matching Logic* (LMCS 2017)
- Roșu & Ștefănescu, *From Hoare Logic to Matching Logic Reachability* (FM 2012)
- Roșu, Ștefănescu, Ciobâcă & Moore, *One-Path Reachability Logic* (LICS 2013)
- Chen & Roșu, *Matching μ-Logic* (LICS 2019)
- Chen, Peña, Rodrigues, Roșu & Trinh, *Unified fixpoint reasoning* (OOPSLA 2020)
- K Framework Tutorial 1, Lesson 22

**License:** MIT (see [LICENSE](LICENSE) — retains both upstream copyright notices).
