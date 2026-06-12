# FINDINGS — ultimatepowers integration branch (final review)

- **Range:** `eeed686..55ef0d5` · **Mode:** Final-review (mixed diff) · **Date:** 2026-06-12
- **Status:** constructed (escalation-bounded) — **constructed, not machine-checked**
- Counterexamples below were **demonstrated by executing the script's exact pipelines** on synthetic trees (commands in PROOF.md §7); "current tree" facts were verified by executed greps.

## §1 Non-formal portion (mixed-diff rule record)

**No formal content changed** in: all new skill/template/plan markdown (~115 files), all JSON manifests, assets, test prompt `.txt` files, README/LICENSE/CLAUDE.md/AGENTS.md(symlink)/GEMINI.md, and `.gitmodules`. These hunks are docs/config-only; no claims constructed. Manifests are additionally covered by executed evidence: `scripts/check-structure.sh` (exit 0) and `scripts/bump-version.sh --audit` (clean, 6 files at 1.0.0) both pass on the current tree.

## §2 Formal target: `scripts/check-structure.sh`

### Proven (constructed) properties — see PROOF.md

- **P1 Accumulation/gate contract (MAIN):** exit 0 + `STRUCTURE CHECK PASSED` ⟺ all six implemented predicates Φ1–Φ6 hold; otherwise exit 1 + `STRUCTURE CHECK FAILED` + ≥1 `FAIL:` line. No `err` path can be lost (L-MONO, L-TOP) and no check short-circuits later checks (L-SETU; no `set -e`, no early `exit`). Total correctness (L-FIN).
- **P2 Plan fidelity:** the file is byte-identical to the plan Task 8 verbatim script (executed diff).

### Findings (Φ as-implemented vs Ψ intended)

**F1 — check 1 accepts frontmatter that is not at the top of the file.**
- Classification: **missing precondition (silent wrong verdict)** / test gap at a proof-exposed domain boundary.
- Evidence: oracle axiom for `awkFM` — `awk '/^---$/{n++; next} n==1{print} n>=2{exit}'` skips every line while `n==0`, so any preamble before the first `---` is silently ignored. Demonstrated:

| input SKILL.md | checker (observed) | platform loader (expected) | agree? |
|---|---|---|---|
| `# stray title\n---\nname: foo\ndescription: bar\n---\n` | ok (keys=`description name `) | frontmatter must start at line 1 → skill broken | ✗ |
| `---\nname: foo\ndescription: bar\n---\n` | ok | ok | ✓ |

- Why it matters: the checker's whole purpose is regression-guarding future skill files; this class of broken file passes. (Latent: all 18 current SKILL.md files start with `---` — executed check.)
- Question for the author: should check 1 also require the first line of the file to be `---`?
- Recommended change: prepend `[ "$(head -1 "$f")" = "---" ] || err "$f frontmatter not at line 1"`.
- Tests: add a checker self-test tree with a preamble'd SKILL.md (none exist today).

**F2 — check 1 key regex under-matches exotic keys.**
- Classification: **non-universal postcondition** (checker under-match).
- Evidence: `grep -E '^[A-Za-z_-]+:'` requires the colon to follow a letter/underscore/hyphen run from column 0. Demonstrated: frontmatter `name: foo / description: bar / x2: sneaky` → keys=`description name ` → **PASSES** ("exactly name + description" violated; `x2:` invisible because `2` breaks the run).
- Why it matters: weakens the "exactly two keys" invariant, though realistic YAML keys here are `[a-z-]+`.
- Recommended change: `grep -E '^[^[:space:]:]+:'` (any non-space key) if strictness is wanted.
- Tests: optional self-test case.

**F3 — check 3 allowlist is wider than the design spec's, and `--exclude` is basename-wide.**
- Classification: **unenforced documented precondition / underspecified-contradicted intent** (plan vs spec disagree).
- Evidence: design spec §Verification: "zero dangling `superpowers:` refs **outside LICENSE/credits/submodules/research docs**". The implementation (= plan verbatim) excludes by **basename**: `--exclude=README.md` and `--exclude=CLAUDE.md` exclude *every* file with that basename anywhere, and `--exclude-dir=docs` excludes all of `docs/`. Demonstrated: a stale `superpowers:test-driven-development` planted in `tests/sub/README.md` produces **zero hits** under the exact exclusion set (expected per spec: FAIL).
- Why it matters: a stale ref reintroduced in `tests/claude-code/README.md` (a real file, currently clean — executed grep: 0 hits) would pass the checker forever.
- Question for the author: is the allowlist intended to be root-`README.md`/root-`CLAUDE.md` only (spec reading), or any-basename (plan-verbatim reading)?
- Recommended change: replace basename excludes with path-anchored filtering, e.g. pipe through `grep -v -E '^\./(README\.md|CLAUDE\.md|LICENSE):'`.
- Tests: checker self-test with a stale ref in a nested README.md.

**F4 — check 2's scope misses refs in README.md / CLAUDE.md; its comment over-claims.**
- Classification: **intent-relevant implementation choice** (comment says "Every ultimatepowers:<x> reference resolves"; the grep covers only `skills/ hooks/ tests/`).
- Evidence: executed: `ultimatepowers:writing-skills` occurs in CLAUDE.md — outside check-2's scope (it happens to resolve). Counterexample: a typo'd `ultimatepowers:writing-skils` in CLAUDE.md or README.md → checker passes.
- Recommended change: add root `README.md CLAUDE.md` to the grep file set, or scope the comment.

**F5 — skill dir without SKILL.md is invisible to every check; ok-line overcounts.**
- Classification: **forgotten corner case** (empty/missing).
- Evidence: demonstrated — `mkdir skills/empty-skill` → glob `skills/*/SKILL.md` never visits it (no err), while `ok "... on $(ls skills | wc -l) skills"` counts it: glob visited 1 file, message claims 2 skills.
- Why it matters: a half-created skill directory passes "structural validation"; the ok message reports validation that did not happen.
- Recommended change: `for d in skills/*/; do [ -f "$d/SKILL.md" ] || err "$d has no SKILL.md"; done`, and count validated files, not `ls skills`.

**F6 — latent false-FAIL inputs (loud direction — safe).**
- Classification: **deliberate non-finding territory, recorded as Minor**: all fail toward noise, never toward silent pass.
  - Hyphen-compound prose: demonstrated — `ultimatepowers:verifying-specs-style` extracts token `verifying-specs-style` → would err though no real ref is broken. (Trailing `.` is handled correctly: `ultimatepowers:formal-code-review.` → clean token — positive.)
  - `using-superpowers:`-with-colon prose would trip check 3 (substring `superpowers:`). Executed: zero occurrences today.
  - CRLF or trailing-space `name:` values fail the `[ "$name" = "$dir" ]` test (loud).

**F7 — check 2 FAIL lines do not name the file (plan promise contradicted).**
- Classification: **intent-contradicting behavior**, diagnostic-only (verdict unaffected).
- Evidence: plan Task 8 Step 3: "each `FAIL:` line names the file and invariant". Check 2 uses `grep -rhoE` (`-h` = suppress filenames), so its err is `reference 'ultimatepowers:x' does not resolve…` with no file. Checks 1/3/4/5/6 do name files.
- Severity note (judgment call, recorded): the violated promise is about diagnostic completeness in the plan's prose, not the verdict contract (P1 holds) → Minor, not Critical.
- Recommended change: on failure, re-grep with filenames: `grep -rlE "ultimatepowers:$s\b" skills/ hooks/ tests/`.

**F8 — unguarded `cd` at line 6; oracle-failure vacuous passes.**
- Classification: **needed code guard** (out of intended domain).
- Evidence: `cd "$(cd "$(dirname "$0")/.." && pwd)"` — if the inner `cd` fails the outer runs `cd ""`, which fails, and (no `set -e`) the script proceeds in the caller's CWD. Most realistic failure is loud (every check errs on missing files); a silent wrong-tree PASS requires the caller's CWD to itself be a valid plugin tree (contrived). Similarly, `2>/dev/null` on the check-2/check-3 greps converts I/O errors (e.g. unreadable dir) into vacuous passes of those two checks.
- Recommended change: `cd … || exit 1`; drop `2>/dev/null` or test `$?` ≤ 1.

### Positive findings (code doing the right thing)

- **PF1:** `set -uo pipefail` *without* `-e` is exactly right for fail-accumulation semantics; with `-e` the first failing test would abort before the gate.
- **PF2:** unclosed frontmatter (single `---`) fails loudly: `n==1` runs to EOF, body keys pollute `$keys`, err fires.
- **PF3:** missing jq fields fail safe: `jq -r` prints `null` → `[ -d null ]`/`[ -f null ]` false → err. Missing jq binary fails every manifest check loudly (message wording misleading, behavior safe).
- **PF4:** check-2 token regex handles trailing punctuation (`.`, backtick, `'s`) correctly — demonstrated.
- **PF5:** duplicate frontmatter keys (`name:` twice) are caught (`name name ` ≠ expected; two-line `$name` ≠ dir).
- **PF6:** the script excludes itself from check 3 (`--exclude=check-structure.sh`) — necessary self-allowlist (it contains the pattern in code/comments).

## §3 Rebrand / scaffold verification (executed evidence)

- **Byte-identical to upstream @ 6fd4507:** every file not listed by `diff -rq` vs `reference/superpowers` — includes all untouched executables (`scripts/bump-version.sh`, `hooks/run-hook.cmd`, `hooks/hooks.json`, brainstorming `server.cjs`/`helper.js`, `render-graphs.js`, `find-polluter.sh`, most tests).
- **Round-trip-proven rebrand-only (44 files):** applying the inverse brand map (with `using-superpowers` sentinel) reproduces the upstream file byte-exactly — incl. `.opencode/plugins/ultimatepowers.js` (so its edits are brand tokens only) and `tests/claude-code/README.md`.
- **Seven residuals, each traced to declared intent:**

  | File | Residual (post-inverse-map) | Intent source |
  |---|---|---|
  | `hooks/session-start` | line 45 only: upstream issue URL → `(upstream workaround for bash 5.3+ heredoc hang)` — comment-only | plan Task 2 Step 1 contingency ("If more [obra/superpowers URLs] appear, hand-fix each") |
  | `skills/brainstorming/scripts/frame-template.html` | line 199 `<h1>` link removal | plan Task 2 Step 2 (verbatim) |
  | `tests/opencode/test-tools.sh` | `a` → `an` in one echo string | commit 45a5396 |
  | `skills/using-superpowers/references/gemini-tools.md` | 4 table rows rephrased (removes `superpowers:implementer` pseudo-namespace refs that would break check 2) + formal-reviewer row added | plan Task 6 Step 6 (verbatim find/replace) |
  | `skills/using-superpowers/SKILL.md` | adds "Built-In Formal Review" section | plan Task 6 / design §Wiring item 4 |
  | `skills/requesting-code-review/SKILL.md` | dual parallel dispatch, merge rules (Critical-from-either blocks), formal-evidence retention, red-flag line, template pointers | plan Task 6 / design §Wiring item 2; fix commits 5fcd74b, 1a4841e |
  | `skills/subagent-driven-development/SKILL.md` | staged review = quality + formal in parallel; final review = full two-reviewer requesting-code-review (final-review mode) | plan Task 6 / design §Wiring item 3 |

- **`AGENTS.md`:** a `-> CLAUDE.md` symlink in both trees; its apparent divergence is CLAUDE.md's declared rewrite seen through the link. **Not** a separate delta.
- **`hooks/session-start` behavior note (deliberate, recorded):** `legacy_skills_dir` now points at `~/.config/ultimatepowers/skills` per the rebrand policy ("`~/.config/superpowers/` legacy paths → `~/.config/ultimatepowers/`"). Consequence: the migration warning is in practice unreachable (no ultimatepowers legacy era exists), and users migrating *from superpowers* (who have `~/.config/superpowers/skills`) get no warning. Intent-consistent with the plan; flagged as a Minor author question, not a bug.
- **Submodules pinned** exactly as the design names: superpowers @ 6fd4507 (v5.1.0), formal-verification-kit @ d0d07ba — executed `git submodule status`.

## §4 Intent-trace summary

Every file in the delta surface is in exactly one bucket: plan-declared create/rewrite/delete/rename, round-trip-proven rebrand, or residual-traced hand edit. **No undeclared divergence was found.** The two intra-intent contradictions found (F3: spec-vs-plan allowlist; F7: plan prose vs `grep -h`) are reported above rather than silently resolved.

*Derived from grosu/formal-verification-kit (MIT, Copyright (c) 2026 Grigore Rosu). See LICENSE and README credits.*
