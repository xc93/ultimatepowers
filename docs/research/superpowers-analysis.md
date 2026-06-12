# obra/superpowers — Full Analysis for the `ultimatepowers` Derived Plugin

**Analyzed snapshot:** submodule at `/home/xc/Projects/ultimatepowers/reference/superpowers`,
commit `6fd4507659784c351abbd2bc264c7162cfd386dc` (2026-05-29, `main`, tag `v5.1.0` + 1 commit).
**Plugin version:** 5.1.0. **Author:** Jesse Vincent <jesse@fsck.com>. **License:** MIT.

This is the canonical reference for implementation agents building **ultimatepowers** =
superpowers + an integrated formal-verification review capability, renamed to plugin
namespace `ultimatepowers` with skill names kept identical.

---

## 1. Full Structure & Component Inventory

146 files total (excluding `.git`). Top-level layout:

```
superpowers/
├── .claude-plugin/            # Claude Code plugin identity
│   ├── plugin.json            # name=superpowers, v5.1.0, MIT
│   └── marketplace.json       # dev marketplace "superpowers-dev", 1 plugin entry (source "./")
├── .codex-plugin/plugin.json  # Codex CLI/App manifest (rich "interface" metadata, skills: ./skills/)
├── .cursor-plugin/plugin.json # Cursor manifest (skills/agents/commands/hooks pointers — see §2.4 note)
├── .opencode/                 # OpenCode integration
│   ├── INSTALL.md
│   └── plugins/superpowers.js # 135-line JS plugin: injects bootstrap via system-prompt transform
├── gemini-extension.json      # Gemini CLI extension manifest (contextFileName: GEMINI.md)
├── GEMINI.md                  # 2 lines: @-includes using-superpowers SKILL.md + gemini-tools.md
├── CLAUDE.md                  # Contributor guidelines (AGENTS.md is a symlink to it)
├── hooks/
│   ├── hooks.json             # Claude Code hook registration (SessionStart only)
│   ├── hooks-cursor.json      # Cursor variant (sessionStart)
│   ├── run-hook.cmd           # cmd/bash polyglot wrapper (Windows support)
│   └── session-start          # bash script: injects using-superpowers SKILL.md as context
├── skills/                    # 14 skills, 45 files total (no nested namespace; flat dirs)
├── scripts/
│   ├── bump-version.sh        # version bump driven by .version-bump.json (drift detect + audit)
│   └── sync-to-codex-plugin.sh# mirrors repo → OpenAI codex plugins fork (upstream-specific)
├── tests/                     # 7 test suites (~50 files) — see §7
├── docs/
│   ├── superpowers/specs/     # 5 real design docs (dogfooding the artifact convention)
│   ├── superpowers/plans/     # 5 real implementation plans
│   ├── plans/                 # 4 older plans (pre-convention path)
│   ├── testing.md             # integration-test how-to
│   ├── README.opencode.md
│   └── windows/polyglot-hooks.md
├── assets/                    # app-icon.png, superpowers-small.svg
├── .github/                   # ISSUE_TEMPLATEs (3), PULL_REQUEST_TEMPLATE.md, FUNDING.yml
├── README.md, RELEASE-NOTES.md, LICENSE, CODE_OF_CONDUCT.md
├── package.json               # name=superpowers, main=.opencode/plugins/superpowers.js
├── .version-bump.json         # declares the 6 files carrying the version string
├── .gitignore                 # .worktrees/, .private-journal/, .claude/, node_modules/ …
└── .gitattributes             # LF enforcement for sh/cmd/md/json; binary marks
```

**There is NO `commands/` directory and NO `agents/` directory.** v5.1.0 release notes
confirm both were deliberately removed:
- Legacy slash commands `/brainstorm`, `/execute-plan`, `/write-plan` deleted (deprecated stubs).
- The `superpowers:code-reviewer` **named agent** was removed; its persona/checklist was merged
  into `skills/requesting-code-review/code-reviewer.md` as a self-contained Task-dispatch
  prompt template. All subagents are now dispatched as `Task (general-purpose)` + prompt template.

**Component counts:** 14 skills · 4 hook files (1 registered hook event) · 0 commands ·
0 agents · 6 plugin manifests (5 platforms + marketplace) · 2 scripts · 7 test suites ·
1 OpenCode JS plugin · 2 assets.

### 1.1 The 14 skills

| Skill | Files | Supporting files |
|---|---|---|
| brainstorming | 8 | spec-document-reviewer-prompt.md, visual-companion.md, scripts/ (server.cjs, helper.js, frame-template.html, start/stop-server.sh) |
| dispatching-parallel-agents | 1 | — |
| executing-plans | 1 | — |
| finishing-a-development-branch | 1 | — |
| receiving-code-review | 1 | — |
| requesting-code-review | 2 | **code-reviewer.md** (the review prompt template) |
| subagent-driven-development | 4 | implementer-prompt.md, spec-reviewer-prompt.md, code-quality-reviewer-prompt.md |
| systematic-debugging | 10 | root-cause-tracing.md, defense-in-depth.md, condition-based-waiting.md (+example.ts), find-polluter.sh, CREATION-LOG.md, test-academic.md, test-pressure-{1,2,3}.md |
| test-driven-development | 2 | testing-anti-patterns.md |
| using-git-worktrees | 1 | — |
| using-superpowers | 4 | references/{codex,copilot,gemini}-tools.md |
| verification-before-completion | 1 | — |
| writing-plans | 2 | plan-document-reviewer-prompt.md |
| writing-skills | 7 | anthropic-best-practices.md, persuasion-principles.md, testing-skills-with-subagents.md, graphviz-conventions.dot, render-graphs.js, examples/CLAUDE_MD_TESTING.md |

---

## 2. Plugin Infrastructure

### 2.1 `.claude-plugin/plugin.json` (exact contents)

```json
{
  "name": "superpowers",
  "description": "Core skills library for Claude Code: TDD, debugging, collaboration patterns, and proven techniques",
  "version": "5.1.0",
  "author": { "name": "Jesse Vincent", "email": "jesse@fsck.com" },
  "homepage": "https://github.com/obra/superpowers",
  "repository": "https://github.com/obra/superpowers",
  "license": "MIT",
  "keywords": ["skills", "tdd", "debugging", "collaboration", "best-practices", "workflows"]
}
```

No explicit `skills`/`hooks` keys — Claude Code auto-discovers `skills/` and `hooks/hooks.json`
by convention from the plugin root.

### 2.2 `.claude-plugin/marketplace.json` (exact contents)

```json
{
  "name": "superpowers-dev",
  "description": "Development marketplace for Superpowers core skills library",
  "owner": { "name": "Jesse Vincent", "email": "jesse@fsck.com" },
  "plugins": [
    { "name": "superpowers",
      "description": "Core skills library for Claude Code: TDD, debugging, collaboration patterns, and proven techniques",
      "version": "5.1.0",
      "source": "./",
      "author": { "name": "Jesse Vincent", "email": "jesse@fsck.com" } }
  ]
}
```

Purpose: local development marketplace (`/plugin marketplace add <repo-dir>` →
`superpowers@superpowers-dev`). Tests rely on `"superpowers@superpowers-dev": true`
in `~/.claude/settings.json` `enabledPlugins`, or on `claude --plugin-dir`.

### 2.3 Hooks — registration and behavior

`hooks/hooks.json` registers **one** hook:

```json
{ "hooks": { "SessionStart": [ {
    "matcher": "startup|clear|compact",
    "hooks": [ { "type": "command",
                 "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
                 "async": false } ] } ] } }
```

`run-hook.cmd` is a cmd.exe/bash **polyglot wrapper** (Windows: finds Git-Bash and runs
`bash hooks/<name>`; Unix: `exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}"`). Hook scripts are
extensionless ("session-start", not ".sh") to dodge Claude Code's Windows `.sh` auto-bash
detection.

`hooks/session-start` (bash) does:
1. Computes `PLUGIN_ROOT` from its own location.
2. Legacy check: if `~/.config/superpowers/skills` exists, builds a warning telling the user
   to move custom skills to `~/.claude/skills`.
3. **Reads `skills/using-superpowers/SKILL.md` in full** and JSON-escapes it (pure-bash
   parameter substitution; no jq dependency — "zero-dependency plugin by design").
4. Wraps it as:
   `<EXTREMELY_IMPORTANT>\nYou have superpowers.\n\n**Below is the full content of your
   'superpowers:using-superpowers' skill - your introduction to using skills. For all other
   skills, use the 'Skill' tool:**\n\n${content}\n\n${warning}\n</EXTREMELY_IMPORTANT>`
5. Emits platform-appropriate JSON (branching on env vars):
   - Cursor (`CURSOR_PLUGIN_ROOT` set): `{"additional_context": "..."}`
   - Claude Code (`CLAUDE_PLUGIN_ROOT` set, no `COPILOT_CLI`):
     `{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "..."}}`
   - Copilot CLI / unknown: `{"additionalContext": "..."}`
   Uses `printf` not heredoc (bash 5.3+ heredoc hang, issue #571).

**This hook is the bootstrap that makes everything else auto-trigger.** The injected
using-superpowers content mandates: invoke the Skill tool before ANY response if there is
even a 1% chance a skill applies; process skills (brainstorming/debugging) before
implementation skills; user instructions > skills > system prompt.

### 2.4 Other-platform manifests

- `.codex-plugin/plugin.json`: same identity + `"skills": "./skills/"` + a large `interface`
  block (displayName "Superpowers", category Coding, brandColor `#F59E0B`,
  composerIcon `./assets/superpowers-small.svg`, logo `./assets/app-icon.png`, defaultPrompt).
- `.cursor-plugin/plugin.json`: identity + `"skills": "./skills/"`, `"hooks": "./hooks/hooks-cursor.json"`,
  **and stale pointers** `"agents": "./agents/"`, `"commands": "./commands/"` — those dirs do
  not exist (left over from pre-5.1.0). Harmless but should be dropped in a derivative.
- `gemini-extension.json` + `GEMINI.md`: Gemini loads GEMINI.md as context; it `@`-includes
  the using-superpowers skill + gemini tool mapping (this is the Gemini equivalent of the hook).
- `.opencode/plugins/superpowers.js`: ESM plugin; caches & strips frontmatter from
  using-superpowers SKILL.md, injects it via system-prompt transform, auto-registers the
  `skills/` directory via OpenCode config hook. `package.json` `main` points at it.
- `.version-bump.json` declares the 6 files carrying the version:
  package.json, .claude-plugin/plugin.json, .cursor-plugin/plugin.json,
  .codex-plugin/plugin.json, .claude-plugin/marketplace.json (`plugins.0.version`),
  gemini-extension.json. `scripts/bump-version.sh` bumps/checks/audits them (jq-based).

---

## 3. Skill Format Conventions

### 3.1 Frontmatter

Every SKILL.md has exactly **two** YAML fields (the only ones used anywhere):

```yaml
---
name: skill-name-in-hyphens        # matches directory name exactly
description: Use when <triggering conditions only>
---
```

Rules enforced by writing-skills:
- `name`: letters/numbers/hyphens only; gerund verb-first naming (`writing-plans`,
  `using-git-worktrees`); name = directory name.
- `description`: third person, starts with "Use when…", describes ONLY triggering
  conditions, **never the workflow** (documented failure mode: Claude follows a
  workflow-summarizing description instead of reading the skill body — "CSO" section).
  Max 1024 chars frontmatter total; <500 chars description preferred.
  Exception: brainstorming's description starts "You MUST use this before any creative
  work…" (deliberately tuned trigger language).
- Body conventions: Overview + core principle; graphviz `dot` digraphs for non-obvious
  decision flows ONLY; Red Flags lists; rationalization tables (| Excuse | Reality |);
  `<Good>`/`<Bad>` example tags; "Iron Law" pattern for discipline skills; "your human
  partner" terminology is deliberate (per CLAUDE.md, not to be reworded);
  "**Announce at start:** 'I'm using the X skill to …'" in workflow skills;
  `<HARD-GATE>`, `<EXTREMELY-IMPORTANT>`, `<SUBAGENT-STOP>` pseudo-tags for emphasis.

### 3.2 Supporting files

- Companion prompt templates live next to SKILL.md (`code-reviewer.md`,
  `implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`,
  `spec-document-reviewer-prompt.md`, `plan-document-reviewer-prompt.md`).
  SKILL.md refers to them as `./implementer-prompt.md` or
  `requesting-code-review/code-reviewer.md` (path relative to skills/).
- Heavy reference → separate .md (testing-anti-patterns.md, anthropic-best-practices.md).
- Reusable tools → scripts in skill dir (brainstorming/scripts/server.cjs, render-graphs.js).
- `references/` subdir used only by using-superpowers (platform tool mappings).
- In-body references use `@file.md` sparingly (writing-skills warns `@` force-loads files);
  preferred form is plain backticked relative paths.

### 3.3 Cross-references (`superpowers:<skill>` strings)

Convention: `**REQUIRED SUB-SKILL:** Use superpowers:<skill-name>` /
`**REQUIRED BACKGROUND:** You MUST understand superpowers:<skill-name>` — namespace-qualified,
no paths, no @-links.

**Where `superpowers:` references appear (production files):** 30 occurrences in 7 files
under `skills/`:

| File | Count | Referenced skills |
|---|---|---|
| skills/subagent-driven-development/SKILL.md | 8 | finishing-a-development-branch (x3, lines 66/85/273), using-git-worktrees, writing-plans, requesting-code-review, test-driven-development, executing-plans |
| skills/writing-plans/SKILL.md | 5 | using-git-worktrees (L16), subagent-driven-development + executing-plans (L52 header template, L147, L151) |
| skills/executing-plans/SKILL.md | 5 | subagent-driven-development (L14), finishing-a-development-branch (L36, L70), using-git-worktrees (L68), writing-plans (L69) |
| skills/writing-skills/SKILL.md | 4 | test-driven-development (x3: L18, L283, L393), systematic-debugging (L284) |
| skills/using-superpowers/references/gemini-tools.md | 4 | virtual agent names: `superpowers:implementer`, `superpowers:spec-reviewer`, `superpowers:code-reviewer`, `superpowers:code-quality-reviewer` (L27–30) |
| skills/systematic-debugging/SKILL.md | 3 | test-driven-development (L179, L287), verification-before-completion (L288) |
| skills/writing-skills/testing-skills-with-subagents.md | 1 | test-driven-development (L13) |

Plus non-skill files: `hooks/session-start` (the literal string
`'superpowers:using-superpowers'` in the injected banner);
tests (`tests/claude-code/test-requesting-code-review.sh` greps for
`"skill":"superpowers:requesting-code-review"`; test-subagent-driven-development-integration.sh,
tests/subagent-driven-dev/{run-test.sh, go-fractals, svelte-todo} prompt/scaffold files);
`RELEASE-NOTES.md` (historical mentions); `CLAUDE.md` (mentions superpowers:writing-skills).
Also note plan headers generated by writing-plans embed
"Use superpowers:subagent-driven-development … or superpowers:executing-plans" into every
user-project plan document.

---

## 4. The Development Workflow — Skill by Skill

The macro-flow (from README and skill terminal states):

```
SessionStart hook → using-superpowers bootstrap
  → brainstorming (design/spec, user-gated)
      → writes docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md, commits
      → terminal state: invoke writing-plans
  → using-git-worktrees (isolation; invoked at execution time)
  → writing-plans
      → writes docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md
      → offers: subagent-driven-development (recommended) | executing-plans
  → subagent-driven-development  (same session, subagents)
      per task: implementer → spec reviewer → code-quality reviewer (loops)
      after all tasks: final code reviewer over whole implementation
      → finishing-a-development-branch
  OR executing-plans (inline batch execution)
      → finishing-a-development-branch
  cross-cutting at all times: test-driven-development, systematic-debugging,
      verification-before-completion, requesting/receiving-code-review,
      dispatching-parallel-agents
```

### 4.1 using-superpowers (the bootstrap)

Injected verbatim at session start by the hook. Contents: `<SUBAGENT-STOP>` guard
(subagents executing a specific task skip it); the 1%-rule (`<EXTREMELY-IMPORTANT>`);
instruction priority (user CLAUDE.md > skills > system prompt); how to access skills per
platform (Claude Code `Skill` tool — "Never use the Read tool on skill files"); a dot
digraph: user message → might a skill apply? → invoke Skill tool → announce
"Using [skill] to [purpose]" → checklist? → TodoWrite per item → follow skill exactly;
special edge: about to EnterPlanMode → brainstorm first. 12-row Red Flags rationalization
table. Skill priority: process skills before implementation skills. Skill types:
Rigid (follow exactly) vs Flexible (adapt).

### 4.2 brainstorming

- Trigger: before ANY creative work. `<HARD-GATE>`: no implementation action until a design
  is presented and approved; explicitly counters "too simple to need design".
- 9-item checklist (each gets a TodoWrite task): explore context → offer visual companion
  (own message; browser-based mockup server in `scripts/`, guide in visual-companion.md) →
  clarifying questions one-at-a-time (multiple-choice preferred) → propose 2-3 approaches
  with recommendation → present design in sections w/ per-section approval → **write design
  doc** → spec self-review → **user reviews written spec** (explicit gate with quoted
  message) → invoke writing-plans.
- **Artifact:** `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` ("User preferences for
  spec location override this default"), committed to git.
- Spec self-review (inline, NOT a subagent in current version): placeholder scan, internal
  consistency, scope check, ambiguity check.
- Note: `spec-document-reviewer-prompt.md` still ships in this dir — a Task(general-purpose)
  reviewer template ("Dispatch after: spec document is written to docs/superpowers/specs/";
  output: Status Approved|Issues Found, Issues, Recommendations). The current SKILL.md uses
  inline self-review instead, but the template remains (used by test-document-review-system.sh).
  Large projects: decompose into sub-projects first; each gets its own spec → plan → impl cycle.

### 4.3 writing-plans

- Audience framing: plan written for "an enthusiastic junior engineer with poor taste, no
  judgement, no project context" — zero-context, complete code in every step.
- **Artifact:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md` (user prefs override).
- Mandatory plan header (template embedded in skill): title + blockquote
  "> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
  (recommended) or superpowers:executing-plans …" + Goal / Architecture / Tech Stack.
- Task structure: `### Task N: [Component]`, **Files:** (Create/Modify/Test exact paths,
  line ranges), then checkbox steps of 2-5 min each following TDD
  (write failing test → run to see FAIL → minimal impl → run to see PASS → commit), with
  literal code blocks and exact commands + expected output.
- "No Placeholders" list (TBD/TODO/"add validation"/"similar to Task N" are plan failures).
- Self-review (inline checklist, "not a subagent dispatch"): spec coverage, placeholder
  scan, type consistency across tasks.
- `plan-document-reviewer-prompt.md` ships alongside (subagent template: checks
  Completeness / Spec Alignment / Task Decomposition / Buildability; Approved|Issues Found).
- Execution handoff: verbatim menu offering Subagent-Driven (recommended) vs Inline
  Execution, then REQUIRED SUB-SKILL dispatch accordingly.

### 4.4 executing-plans (inline alternative)

Load plan → review critically → raise concerns → TodoWrite → execute each task's steps
exactly → run verifications → after all tasks REQUIRED SUB-SKILL
finishing-a-development-branch. Stop conditions: blockers, unclear instructions, repeated
verification failure ("Ask rather than guess"). Never start on main/master without consent.
Tells the user superpowers works better with subagent support; prefers
subagent-driven-development when subagents exist. Review cadence: "Review after each task
or at natural checkpoints" (per requesting-code-review's integration section).

### 4.5 subagent-driven-development (SDD) — the core engine

- Fresh subagent per task + **two-stage review per task** (spec compliance FIRST, then code
  quality), continuous execution with no human check-ins between tasks (stop only for
  BLOCKED/ambiguity/done).
- Controller protocol: read plan ONCE, extract ALL task texts up front, TodoWrite; never
  make a subagent read the plan file; provide full task text + scene-setting context.
- Per task digraph: dispatch implementer (`./implementer-prompt.md`) → answer its questions
  → it implements/tests/commits/self-reviews → dispatch spec reviewer
  (`./spec-reviewer-prompt.md`) → loop fixes until ✅ → dispatch code-quality reviewer
  (`./code-quality-reviewer-prompt.md`) → loop fixes until approved → mark complete →
  next task → after all tasks: **"Dispatch final code reviewer subagent for entire
  implementation"** → `superpowers:finishing-a-development-branch`.
- Model selection policy: mechanical 1-2-file tasks → cheap model; integration → standard;
  architecture/design/**review** → most capable model.
- Implementer status protocol: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED, with
  controller responses for each (more context / better model / split task / escalate to human).
- Red Flags: never skip either review, never start quality review before spec review is ✅,
  never proceed with open issues, never dispatch parallel implementers, fixes are made by
  the SAME implementer subagent then re-reviewed.

**Prompt templates (full structure):**
- `implementer-prompt.md` — Task(general-purpose); sections: Task Description (FULL text
  pasted), Context, "Before You Begin" (ask questions now), Your Job (implement → test
  (TDD if task says) → verify → commit → self-review → report), Code Organization rules,
  "When You're in Over Your Head" (escalation is OK; BLOCKED/NEEDS_CONTEXT), self-review
  rubric (Completeness/Quality/Discipline/Testing), Report Format with the 4 statuses.
- `spec-reviewer-prompt.md` — Task(general-purpose); sections: What Was Requested (full
  task text), What Implementer Claims They Built, "CRITICAL: Do Not Trust the Report"
  (read actual code; the implementer "finished suspiciously quickly"), checks: missing
  requirements / extra-unneeded work / misunderstandings. Returns `✅ Spec compliant` or
  `❌ Issues found: [list with file:line]`.
- `code-quality-reviewer-prompt.md` — thin wrapper: "Use template at
  requesting-code-review/code-reviewer.md" with DESCRIPTION (from implementer report),
  PLAN_OR_REQUIREMENTS ("Task N from [plan-file]"), BASE_SHA (commit before task),
  HEAD_SHA (current). Adds 4 extra file-structure checks (single responsibility, decomposed
  testable units, plan's file structure followed, new/grown large files). "Only dispatch
  after spec compliance review passes."

### 4.6 test-driven-development

Iron Law: `NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST`; code written before its test
gets deleted. RED → verify-RED (mandatory watch-it-fail) → GREEN minimal → verify-GREEN
(pristine output) → REFACTOR → repeat. Good/Bad examples (TypeScript), 11-row
rationalization table, red-flags list, bug-fix example, verification checklist, "When
Stuck" table. References `testing-anti-patterns.md` (@-link) for mock pitfalls. Exceptions
only with the human partner's permission (prototypes, generated code, config).

### 4.7 requesting-code-review — see §5 (maximum detail)

### 4.8 receiving-code-review

Response pattern: READ → UNDERSTAND (restate) → VERIFY against codebase → EVALUATE →
RESPOND (technical ack or reasoned pushback) → IMPLEMENT one item at a time, test each.
Forbidden: "You're absolutely right!", any gratitude/performative agreement. Unclear
feedback: stop, clarify ALL items before implementing any. External reviewers: verify
correctness for THIS codebase, check breakage/platform/context; YAGNI grep before
implementing "professional" features. Implementation order: blocking → simple → complex.
GitHub: reply in comment threads via
`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`. Includes safe-word signal
("Strange things are afoot at the Circle K") for uncomfortable pushback.

### 4.9 verification-before-completion

Iron Law: `NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE`. Gate function:
IDENTIFY command → RUN fully → READ output → VERIFY → only then claim. Claim-evidence
table (tests/linter/build/bug-fixed/regression-test red-green/agent-completed/requirements).
Notably: "Agent completed" requires checking the VCS diff, never trusting the subagent's
report — this is the controller-side safety net of SDD.

### 4.10 finishing-a-development-branch

Step 1 verify tests (stop if failing) → Step 2 detect environment
(`GIT_DIR` vs `GIT_COMMON`, normal repo vs worktree vs detached HEAD) → Step 3 determine
base branch → Step 4 present EXACTLY 4 options (merge locally / push+PR via `gh pr create`
with Summary+Test-Plan body / keep / discard with typed-"discard" confirmation) — 3 options
on detached HEAD (no local merge) → Step 5 execute → Step 6 provenance-based cleanup: only
remove worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`
(superpowers-owned); cd to main root first; `git worktree prune`; keep worktree for
options 2 & 3.

### 4.11 using-git-worktrees

Step 0 detect existing isolation (`GIT_DIR != GIT_COMMON`, with a submodule guard via
`git rev-parse --show-superproject-working-tree`) → ask consent → Step 1a prefer NATIVE
worktree tools (`EnterWorktree`, `/worktree`, `--worktree`) → Step 1b git fallback with
directory priority: declared preference > `.worktrees/` > `worktrees/` >
`~/.config/superpowers/worktrees/<project>/` (legacy global) > default `.worktrees/`;
must `git check-ignore` project-local dirs (add to .gitignore + commit if not) →
Step 3 auto-detect setup (npm/cargo/pip/poetry/go) → Step 4 verify clean test baseline,
report "Worktree ready at <path>".

### 4.12 dispatching-parallel-agents

For 2+ independent problem domains: one agent per domain, dispatched concurrently
(`Task(...)` x N in one block). Prompt structure: focused scope, self-contained context
(paste errors), explicit constraints ("Do NOT change production code"), specified return
("Summary of root cause and changes"). Controller then: review summaries, check conflicts,
run full suite, spot-check. Don't use for related failures/shared state.

### 4.13 writing-skills

"Writing skills IS TDD applied to process documentation." Iron Law: no skill (or skill
EDIT) without a failing test first — baseline pressure-test subagents WITHOUT the skill
(RED, capture verbatim rationalizations), write minimal skill (GREEN), close loopholes
(REFACTOR). Skill-type-specific test approaches (discipline/technique/pattern/reference).
CSO (Claude Search Optimization) doctrine for descriptions (§3.1). Token-efficiency
targets (<200 words for frequently-loaded, <500 otherwise — note: the flagship skills
themselves exceed this). Cross-reference rules (§3.3). Companion docs:
testing-skills-with-subagents.md (pressure-testing methodology),
anthropic-best-practices.md (official guidance, 5.7k words), persuasion-principles.md,
graphviz-conventions.dot + render-graphs.js. Personal skills live in `~/.claude/skills`
(Claude Code) / `~/.agents/skills/` (Codex).

---

## 5. The Review Flow — Maximum Detail

### 5.1 Three distinct review layers

1. **Document reviews** (spec, plan): currently inline self-review checklists in
   brainstorming/writing-plans; subagent templates still shipped
   (`spec-document-reviewer-prompt.md`, `plan-document-reviewer-prompt.md`) with output
   format `Status: Approved | Issues Found` + Issues + advisory Recommendations.
2. **Per-task two-stage review** in SDD: spec-compliance reviewer → code-quality reviewer
   (which reuses the code-reviewer.md template). Strict ordering, mandatory loops.
3. **Milestone code review** via requesting-code-review: after each task (SDD), after major
   features, before merge; plus a "final code reviewer subagent for entire implementation"
   at the end of SDD before finishing-a-development-branch.

### 5.2 requesting-code-review mechanics (exact)

1. Compute range: `BASE_SHA=$(git rev-parse HEAD~1)` (or origin/main, or the commit before
   the task), `HEAD_SHA=$(git rev-parse HEAD)`.
2. Dispatch **Task tool, `general-purpose` subagent type** (no named agent since v5.1.0),
   filling `skills/requesting-code-review/code-reviewer.md` with 4 placeholders:
   `{DESCRIPTION}`, `{PLAN_OR_REQUIREMENTS}` (plan file path / task text / requirements),
   `{BASE_SHA}`, `{HEAD_SHA}`.
3. The reviewer prompt (full template in code-reviewer.md):
   - Persona: "Senior Code Reviewer with expertise in software architecture, design
     patterns, and best practices."
   - Inputs: What Was Implemented, Requirements/Plan, Git Range with the literal commands
     `git diff --stat {BASE}..{HEAD}` and `git diff {BASE}..{HEAD}`.
   - Check categories: **Plan alignment** (matches plan? deviations justified? everything
     present?), **Code quality** (separation of concerns, error handling, type safety, DRY
     w/o premature abstraction, edge cases), **Architecture** (design, scalability/perf,
     security, integration), **Testing** (real behavior not mocks, edge cases, integration
     tests, all passing), **Production readiness** (migrations, backward compat, docs, bugs).
   - Calibration: categorize by ACTUAL severity; acknowledge strengths first; flag
     plan-deviations explicitly; flag plan bugs as plan bugs.
   - **Output format (the findings schema):**
     - `### Strengths`
     - `### Issues` with `#### Critical (Must Fix)` (bugs, security, data loss, broken
       functionality) / `#### Important (Should Fix)` (architecture problems, missing
       features, poor error handling, test gaps) / `#### Minor (Nice to Have)` (style,
       optimization, docs polish); each issue = file:line + what's wrong + why it matters
       + how to fix.
     - `### Recommendations`
     - `### Assessment` → `**Ready to merge?** [Yes | No | With fixes]` + 1-2 sentence
       reasoning.
   - Critical rules: be specific, explain WHY, give a clear verdict; don't rubber-stamp,
     don't mark nitpicks Critical, don't review unread code.
4. Acting on findings: **Critical → fix immediately; Important → fix before proceeding;
   Minor → note for later; push back with technical reasoning if the reviewer is wrong.**
5. **Artifact persistence: NONE.** Review results exist only as the subagent's return
   message in the conversation. There is no `docs/superpowers/reviews/` convention. (A
   formal-verification step could either keep that ephemeral pattern or introduce a
   persisted artifact dir.)

### 5.3 How executing-plans / SDD invoke review between tasks

- **SDD:** mandatory, automatic, twice per task. The code-quality stage = code-reviewer.md
  with `PLAN_OR_REQUIREMENTS: Task N from [plan-file]`, `BASE_SHA: commit before task`,
  `HEAD_SHA: current commit`. Loops: reviewer finds issues → same implementer subagent
  fixes → SAME reviewer re-reviews → repeat until ✅/approved. "Move to next task while
  either review has open issues" is a listed Red Flag. After the last task, one more
  code-reviewer dispatch covers the entire implementation (full branch range).
- **executing-plans:** review "after each task or at natural checkpoints"
  (requesting-code-review's Integration section); not enforced by digraph.
- Validation that this works: `tests/claude-code/test-requesting-code-review.sh` plants a
  SQL injection + plaintext-password logging in a second commit and asserts the dispatched
  reviewer (a) ran via the skill, (b) flagged injection, (c) flagged credentials,
  (d) used Critical/Important severity, (e) did NOT approve the merge.

### 5.4 Insertion points for a formal-verification review step (ultimatepowers)

Ranked by how naturally they slot into existing seams:

1. **New prompt template in subagent-driven-development** (e.g.
   `formal-verification-reviewer-prompt.md`) added to the per-task chain — the chain is
   defined in ONE place (the SKILL.md digraph + Red Flags + "Prompt Templates" list), and
   the existing precedent is exactly "thin wrapper template + stage ordering rule"
   (code-quality-reviewer-prompt.md is 26 lines). Natural slot: after spec compliance ✅,
   either before or parallel with code quality. Ordering language to mirror: "Only dispatch
   after spec compliance review passes."
2. **Extend code-reviewer.md** with a formal-verification check section (or a sibling
   template `formal-verifier.md` dispatched by requesting-code-review) — inherits the
   severity schema (verification failure / unproven obligation → Critical; missing
   spec annotations → Important) and the `Ready to merge?` verdict gate.
3. **The final whole-implementation review** in SDD before finishing-a-development-branch —
   right place for whole-module proofs / model checking that is too slow per-task.
4. **verification-before-completion** — add formal-verification evidence rows to the
   claim/evidence table ("Properties verified" requires prover/checker output, not "should
   hold"), making the gate enforce it before any completion claim.
5. **writing-plans** — plan header/task structure can require a "verification step" per
   task (the bite-sized-step format trivially accommodates "Run <verifier>, expected:
   0 obligations failed").
6. **brainstorming spec phase** — formal properties/invariants captured in the design doc
   (`docs/superpowers/specs/...`), giving the later verifier its specification source; the
   shipped-but-dormant document-reviewer templates show how a spec-level reviewer is dispatched.
7. **finishing-a-development-branch Step 1** — verify tests AND formal checks before
   presenting merge options.
A new skill (e.g. `formal-verification-review`) + template files follows the exact
existing pattern: skill dir + SKILL.md (two-field frontmatter, "Use when…" description)
+ companion prompt template, cross-referenced as
`**REQUIRED SUB-SKILL:** Use ultimatepowers:<skill>` from SDD/requesting-code-review.

---

## 6. Rebrand Touchpoints ("superpowers" → "ultimatepowers")

Strategy constraint: plugin name changes; **skill names stay identical** (including the
skill literally named `using-superpowers` — only its namespace prefix changes:
`superpowers:using-superpowers` → `ultimatepowers:using-superpowers`). Occurrence counts
are case-insensitive matches of "superpowers".

### 6.1 MUST rename

| # | Category | Files | Notes |
|---|---|---|---|
| 1 | Plugin identity manifests | 6 files: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (also marketplace name `superpowers-dev`), `.codex-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `gemini-extension.json`, `package.json` | `name`, descriptions, homepage/repository URLs, displayName, `interface.*` in codex manifest. `.version-bump.json` lists exactly these. |
| 2 | Session-start hook text | 1 file: `hooks/session-start` (16 occurrences incl. comments) | "You have superpowers." banner, `'superpowers:using-superpowers'` string, legacy-dir warning paths `~/.config/superpowers/skills` |
| 3 | Skill cross-refs `superpowers:<skill>` | 7 files / 30 occurrences in `skills/` (see §3.3 table) | mechanical replace `superpowers:` → `ultimatepowers:` |
| 4 | Artifact paths `docs/superpowers/{specs,plans}` | 5 skill files: brainstorming/SKILL.md (2), writing-plans/SKILL.md (2), requesting-code-review/SKILL.md (1, example), subagent-driven-development/SKILL.md (1, example), brainstorming/spec-document-reviewer-prompt.md (1) | → `docs/ultimatepowers/...`. Also baked into the writing-plans **plan header template** (the REQUIRED SUB-SKILL blockquote), which propagates into every generated plan. |
| 5 | Config/worktree paths `~/.config/superpowers/...` | 3 skill files: using-git-worktrees/SKILL.md (3x `worktrees`), finishing-a-development-branch/SKILL.md (2x), subagent-driven-development/SKILL.md (1x example `hooks/`); + hooks/session-start (skills dir) | Decision: these are LEGACY/back-compat paths. Either keep checking the old superpowers path (harmless compat) or swap to ultimatepowers; do not keep the legacy-skills warning verbatim. |
| 6 | OpenCode integration | `.opencode/plugins/superpowers.js` (filename + ~13 refs), `.opencode/INSTALL.md` (~20), `package.json` `main`, `docs/README.opencode.md` | rename file to `ultimatepowers.js`, update install snippet `superpowers@git+...` |
| 7 | Branding docs | `README.md` (41), `GEMINI.md` paths are name-neutral but the included skill is using-superpowers (fine), `CLAUDE.md`/`AGENTS.md` (6 — rewrite entirely: it's upstream's contributor policy, not ours), `.github/` templates (13) | README needs full rewrite: install commands `/plugin install superpowers@...`, marketplace refs `obra/superpowers-marketplace`, workflow description |
| 8 | Assets | `assets/superpowers-small.svg` (filename) + its reference in `.codex-plugin/plugin.json` `composerIcon` | rename or re-badge |
| 9 | Tests | ~15 scripts: tests/claude-code/* (plugin-dir comments, `"skill":"superpowers:..."` grep patterns, `docs/superpowers/...` fixture paths in test-helpers.sh `create_test_plan`, settings key `superpowers@superpowers-dev`), tests/skill-triggering/run-test.sh & explicit-skill-requests/* (`/tmp/superpowers-tests` output dirs, `docs/superpowers/plans` fixtures), tests/subagent-driven-dev/* (plan headers `superpowers:subagent-driven-development`), tests/opencode/*, tests/codex-plugin-sync/* | 179 occurrences across tests/ |
| 10 | Scripts | `scripts/sync-to-codex-plugin.sh` (14 occ; upstream-fork-specific — likely DROP for derivative rather than rename); `scripts/bump-version.sh` is name-agnostic (config-driven) | |
| 11 | docs/testing.md | settings key `"superpowers@superpowers-dev"`, paths | |

### 6.2 Should NOT be renamed (or needs care)

- **LICENSE**: `Copyright (c) 2025 Jesse Vincent` MUST be preserved verbatim (MIT
  condition). Add a second copyright line for ultimatepowers additions if desired.
- **Upstream attribution**: README of the derivative should credit obra/superpowers and
  Jesse Vincent and link the original repo/announcement; keep author fields honest in
  manifests (derived-from note) rather than erasing authorship history.
- **RELEASE-NOTES.md** (104 occurrences): historical upstream changelog — do not rewrite;
  either drop it from the derivative or keep as-is labeled "upstream history".
- **docs/superpowers/specs|plans/, docs/plans/** content (259 occurrences in docs/):
  upstream's own dogfooded design artifacts; historical — drop or keep unmodified.
- **CODE_OF_CONDUCT.md, .github/FUNDING.yml**: upstream community/funding config — replace
  with own or remove; do NOT ship Jesse's sponsorship links as ours.
- **Skill names/directories**: per project decision, identical — including
  `using-superpowers/` (dir + frontmatter `name:`). Renaming it would break the hook, the
  GEMINI.md @-includes, the OpenCode bootstrap, and the cross-platform sync conventions.
  Only the namespace prefix in references changes.
- **CLAUDE.md's "fork-specific changes" policy**: explicitly says rebrand PRs will be
  rejected upstream — ultimatepowers must live as its own plugin/repo, never PR'd back.
- **`superpowers-marketplace` install instructions in README**: belong to upstream; the
  derivative needs its own distribution story, not a renamed copy of these.

### 6.3 Mechanical rebrand checklist (for the implementation agent)

1. `grep -rIl 'superpowers' --exclude-dir=.git` and bucket every hit into §6.1/§6.2.
2. Replace namespace refs `superpowers:` → `ultimatepowers:` (skills/, tests/).
3. Replace artifact paths `docs/superpowers/` → `docs/ultimatepowers/`.
4. Decide legacy-path policy for `~/.config/superpowers/worktrees` (recommend: check BOTH
   old and new for provenance cleanup; create only new).
5. Update 6 manifests + `.version-bump.json` works unchanged; run
   `scripts/bump-version.sh --audit` afterwards — it greps the repo for stale version
   strings and is the perfect post-rebrand drift check.
6. Rewrite hook banner ("You have ultimatepowers."), keeping the JSON-escaping and
   platform-branching logic untouched.
7. Rewrite README/CLAUDE.md; new LICENSE file = MIT text w/ Jesse's line + ours; add
   attribution section.

---

## 7. Tests / Validation Harness (reusable for ultimatepowers)

All testing is **behavioral**, driving real `claude -p` headless sessions and parsing
session transcripts (JSONL in `~/.claude/projects/<normalized-cwd>/*.jsonl`). There is no
static linter/schema check for skills (the closest is bump-version.sh --audit for versions).

| Suite | What it does | Reuse value |
|---|---|---|
| `tests/claude-code/` | `run-skill-tests.sh` runner (--verbose/--test/--timeout/--integration). Fast test: skill content assertions via `claude -p`. Integration: full SDD run on a scaffolded project (verifies plan-read-once, full task text in prompts, self-review, spec-before-quality ordering, review loops, commits, tests pass) + **test-requesting-code-review.sh** (planted-bug reviewer test, §5.3) + test-document-review-system.sh (spec reviewer catches TODO/deferral) + test-worktree-native-preference.sh. `test-helpers.sh`: run_claude, assert_contains/not/count/**order**, create_test_project, create_test_plan (writes to `docs/superpowers/plans/`). `analyze-token-usage.py`: per-subagent token/cost breakdown from transcripts. | HIGH — direct template for testing a formal-verification reviewer (plant a property violation, assert it's flagged Critical and merge is blocked). Needs path/namespace rebrand. |
| `tests/skill-triggering/` | `run-test.sh <skill> <prompt-file>`: naive prompt (no skill mention) must auto-trigger the skill; checks transcript for `"name":"Skill"` + `"skill":"(ns:)?<name>"` via `--plugin-dir`, `--max-turns`, `stream-json`. 6 prompt fixtures. | HIGH — validates hook bootstrap + descriptions still auto-trigger after rebrand; add a prompt for the new verification skill. |
| `tests/explicit-skill-requests/` | User names a skill explicitly (9 prompt fixtures incl. multi-turn, haiku-model variants); isolated HOME; scaffolds `docs/superpowers/plans/auth-system.md`. | MEDIUM |
| `tests/subagent-driven-dev/` | Two realistic scaffolds (go-fractals, svelte-todo) with design.md + plan.md whose headers invoke `superpowers:subagent-driven-development`; run-test.sh drives a full session. | MEDIUM — end-to-end regression for the modified review chain. |
| `tests/brainstorm-server/` | Node tests for the zero-dep visual-companion server (server.test.js, ws-protocol, windows lifecycle). | LOW (unchanged subsystem) |
| `tests/opencode/` | OpenCode plugin loading/bootstrap-caching/priority/tools. | Only if OpenCode support kept |
| `tests/codex-plugin-sync/` | Tests the upstream mirror script. | DROP with the script |

Docs: `docs/testing.md` explains the methodology (headless mode, `--permission-mode
bypassPermissions`, `--add-dir`, transcript JSONL anatomy incl. `toolUseResult.agentId`
linking subagent usage, troubleshooting). `tests/claude-code/README.md` documents the
runner and per-test intent.

---

## 8. License & Attribution Requirements

- **MIT License, Copyright (c) 2025 Jesse Vincent** (LICENSE, 21 lines, standard text).
- Derivative obligations: include the copyright notice + permission notice "in all copies
  or substantial portions of the Software". Concretely for ultimatepowers:
  1. Ship the MIT LICENSE retaining "Copyright (c) 2025 Jesse Vincent" (may append e.g.
     "Copyright (c) 2026 <ultimatepowers authors> for modifications").
  2. State in README that ultimatepowers is derived from obra/superpowers (link), MIT.
  3. `license: "MIT"` stays in all manifests.
- No NOTICE file, no CLA, no trademark file exists. The name "Superpowers" itself isn't
  formally trademark-protected in the repo, but CLAUDE.md's contribution policy makes clear
  forks/rebrands must remain independent (never PR'd upstream) — which is exactly the
  ultimatepowers plan.
- Sponsorship (`.github/FUNDING.yml`, README sponsor section) and Discord/community links
  are personal to upstream — remove or clearly mark as upstream's in the derivative.

---

## 9. Key Design Facts to Preserve in the Derivative

1. **Zero dependencies** is a stated design principle (bash-only hook, no jq at runtime,
   pure-node visual server). A formal-verification integration that shells out to external
   tools should degrade gracefully / be detect-and-skip, or live as instructions rather
   than hard dependencies.
2. **Skills are behavior-shaping code**: descriptions must not summarize workflow (CSO);
   the "human partner" voice, Red Flags tables and rationalization tables are tested
   content. New verification skill should be authored via the writing-skills TDD loop
   (baseline subagent test first).
3. **All subagents are `Task(general-purpose)` + prompt template files** colocated with the
   dispatching skill — there is no agents/ registry to extend; a verification reviewer is a
   new `*-prompt.md` file plus digraph/Red-Flag edits in the dispatching SKILL.md.
4. **Review results are ephemeral** (subagent return values); artifact persistence exists
   only for specs (`docs/<ns>/specs/`) and plans (`docs/<ns>/plans/`). Introducing
   persisted verification reports would be a new convention, e.g. `docs/<ns>/verification/`.
5. **The session-start hook is the linchpin** — without the bootstrap injection, no skill
   auto-triggers (upstream's acceptance test: "Let's make a react todo list" must
   auto-trigger brainstorming in a clean session). Any rebrand must keep
   hooks.json → run-hook.cmd → session-start → skills/using-superpowers/SKILL.md intact.
