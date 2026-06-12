# SPEC — ultimatepowers integration branch (final review)

- **Feature:** ultimatepowers plugin build (plan `docs/ultimatepowers/plans/2026-06-12-ultimatepowers-integration.md`)
- **Range:** `eeed686..55ef0d5` (15 commits, whole branch)
- **Mode:** Final-review (whole-branch scope; mixed diff — trivial hunks recorded as non-formal in FINDINGS.md)
- **Status:** constructed (escalation-bounded) — **constructed, not machine-checked**

## 1. Scope partition

The diff (128 files, +15949) partitions into:

| Class | Files | Formal treatment |
|---|---|---|
| New markdown/JSON/assets (formal skills, templates, manifests, README, LICENSE, test prompts, plan docs) | ~115 | Non-formal (docs/config) — trivial path, recorded in FINDINGS.md §1 |
| Executable files byte-identical to pinned upstream `reference/superpowers` @ 6fd4507 (bump-version.sh, run-hook.cmd, hooks.json, brainstorming server.cjs/helper.js/start/stop, render-graphs.js, find-polluter.sh, most tests) | ~60 | Equality vs upstream verified by executed `diff -rq` — no new logic, no claims |
| Rebrand-only files (round-trip proven: inverse brand map reproduces upstream byte-exactly) | 44 (43 sweep files + `.opencode/plugins/ultimatepowers.js`) | Equality-modulo-brand-map verified by executed round-trip; no new logic |
| Rebrand + declared hand-edits (`hooks/session-start` comment, `frame-template.html` link, `test-tools.sh` grammar, `gemini-tools.md` rows, 3 wiring SKILL.md edits) | 7 | Residual diffs traced 1:1 to plan tasks / commit messages (FINDINGS.md §3) |
| **New executable logic** | `scripts/check-structure.sh` | **Formal target** — claims below |

## 2. Intent sources (priority order)

1. Plan Task 8 (`plans/2026-06-12-ultimatepowers-integration.md:1098-1226`): the verbatim script (implementation is **byte-identical** to it — executed diff), the six checks, fail-accumulation, "expected final line: STRUCTURE CHECK PASSED", fix-forward semantics ("each `FAIL:` line names the file and invariant"), allowlist policy ("the only legitimate checker change is adding a genuinely-allowed file to an allowlist").
2. Design spec (`specs/2026-06-12-ultimatepowers-design.md` §Verification): "every manifest path resolves; every `ultimatepowers:<skill>` reference resolves; **zero dangling `superpowers:` refs outside LICENSE/credits/submodules/research docs**; JSON manifests parse; frontmatter on all skills has exactly `name` + `description`".
3. Commit `55ef0d5` "feat: add structural validation script; full check passing".
4. Script header comments (the six check banners).

Note: sources 1 and 2 disagree on the check-3 allowlist (finding F3); source 1's "names the file" promise disagrees with check 2's `grep -h` (finding F7).

## 3. Semantics fragment (mini-bash, K notation — sketch, review mode)

Constructs actually used by the script: global assignment, command substitution, `for x in <words>`, `[ … ] || cmd`, function definition/call, `printf`, `if/then/fi`, `exit n`. External tools (`awk, grep, sed, cut, sort, tr, jq, ls, wc, basename, dirname, bash -n`) have no in-repo definition — per the diff-scoped expansion rule they are modeled as **oracle functions over an abstract file tree**, not given contracts.

```k
configuration
  <k> $PGM:Stmts </k>
  <env> .Map </env>          // shell vars: Id |-> String  (FAIL abstracted to Bool in claims)
  <fs>  $FS:FsTree </fs>     // the repo tree — the symbolic input
  <out> .List </out>         // stdout, as a list of lines
  <ret> 0 </ret>             // process exit status

// representative rules (one per construct)
rule <k> X:Id = E:Exp ; S => S </k> <env> M => M [ X <- eval(E, M) ] </env>
rule <k> for X in .List do _ done ; S => S </k>                          // loop exit
rule <k> for X in (ListItem(W) L) do B done ; S
      => B [ X / W ] ~> for X in L do B done ; S </k>                    // loop step
rule <k> [ T:Test ] || C ; S => S </k>      requires holds(T)
rule <k> [ T:Test ] || C ; S => C ; S </k>  requires notBool holds(T)
rule <k> exit N ; _ => .K </k> <ret> _ => N </ret>

// oracle axioms (Step-2 semantics rules for external tools; trusted base — see PROOF.md §4)
syntax List ::= glob(String, FsTree)        [function]  // pathname expansion
syntax String ::= awkFM(File)               [function]  // lines strictly between 1st and 2nd /^---$/
syntax String ::= keysOf(String)            [function]  // sorted ^[A-Za-z_-]+: keys, space-joined+trailing
syntax String ::= nameOf(String)            [function]  // value of the name: line(s)
syntax List ::= refsIn(FsTree)              [function]  // sorted-unique ultimatepowers:[a-z0-9-]+ tokens in skills|hooks|tests
syntax String ::= staleHits(FsTree)         [function]  // grep -rn 'superpowers:' . minus exclusions
syntax Bool ::= jqParses(File) | isDir(String, FsTree) | isFile(String, FsTree)
              | isExec(String, FsTree) | bashSyntaxOk(File) | grepQ(String, File) [function]
```

## 4. Claims

### (ERR) / (OK) — function contracts

```k
claim <k> err ( MSG:String ) ~> CONT:K => CONT </k>
      <env> ... FAIL |-> (_:Bool => true) ... </env>
      <out> ... .List => ListItem("FAIL: " +String MSG) </out>
      [all-path]

claim <k> ok ( MSG:String ) ~> CONT:K => CONT </k>
      <env> ... FAIL |-> F:Bool ... </env>            // FAIL framed: ok never writes it
      <out> ... .List => ListItem("ok: " +String MSG) </out>
      [all-path]
```

Plain language: `err` appends one `FAIL:` line and sets the global `FAIL` to 1, unconditionally; `ok` appends one `ok:` line and touches nothing else. Both are total. Side condition: both are only ever invoked from the **top-level shell** (lemma L-TOP below) — an `err` inside `$( … )` would mutate a subshell copy and be lost; the script has no such call site.

### (LOOP-1) — check-1 loop circularity (shape: list fold, catalog 01/09)

Generalized over the *remaining* glob list `GS` and entry accumulator `F` — never pinned to entry values:

```k
claim
  <k> for f in GS:List do CHECK1BODY done => .K ... </k>
  <env> ... FAIL |-> (F:Bool => F orBool hasViol1(GS, T)) ... </env>
  <fs> T:FsTree </fs>
  <out> ... .List => failLines1(GS, T) </out>
  [all-path]
```

with spec-only folds (spec vocabulary, not language constructs):

```k
syntax Bool ::= hasViol1(List, FsTree) [function, total]
rule hasViol1(.List, _) => false
rule hasViol1(ListItem(P) L, T)
  => (keysOf(awkFM(P)) =/=String "description name "
      orBool nameOf(awkFM(P)) =/=String basename(dirname(P)))
     orBool hasViol1(L, T)
```

`failLines1` is the matching line-list fold. Loops over `refsIn` (check 2), the 9 manifests (check 4), and the 7 surface paths (check 6) take the same shape with their own `hasViolₖ`/`failLinesₖ` folds; check 3 and check 5 are straight-line (no circularity needed).

### (MAIN) — whole-script contract

Let `Φ(T) ≜ Φ1(T) ∧ … ∧ Φ6(T)` where `Φk(T) ≜ ¬hasViolₖ(inputsₖ(T), T)` — the **as-implemented** predicates (this is intent-spec mode for the accumulation/gate semantics, and the Φₖ are then audited against the intended invariants Ψₖ; Φ ≠ Ψ exactly at findings F1–F6).

```k
claim
  <k> check-structure.sh => .K </k>
  <fs> T:FsTree </fs>
  <env> .Map => ?_:Map </env>
  <out> .List => ?OUT:List </out>
  <ret> 0 => ?E:Int </ret>
  ensures ( Phi(T) andBool ?E ==Int 0 andBool last(?OUT) ==String "STRUCTURE CHECK PASSED"
            andBool countFail(?OUT) ==Int 0 )
   orBool ( notBool Phi(T) andBool ?E ==Int 1 andBool last(?OUT) ==String "STRUCTURE CHECK FAILED"
            andBool countFail(?OUT) >=Int 1 )
  [all-path]
```

Plain language: on every repo tree `T`, the script terminates; it exits 0 printing `STRUCTURE CHECK PASSED` iff all six implemented predicates hold; otherwise it exits 1 printing `STRUCTURE CHECK FAILED` after at least one `FAIL:` line. **No check short-circuits a later one** — all six groups always execute (no `set -e`, no `exit` before the gate, no unset-variable abort; see VC table).

### (REBRAND) — file-equality claims (executed, not symbolic)

For every file `f` in the sweep zone that differs from upstream: `f = brandmap(upstream(f))`, where `brandmap` is the plan Task 2 sed (with the `using-superpowers` sentinel). **Demonstrated by executed inverse-map round-trip** for 44/51 files; the 7 residuals are each byte-traced to a declared plan edit or commit (FINDINGS.md §3). Files absent from `diff -rq` output are byte-identical to upstream @ 6fd4507.

## 5. Lemmas / side conditions

- **L-MONO (FAIL monotonicity):** `FAIL` is assigned exactly twice in the program text — `FAIL=0` (line 7, before any check) and `FAIL=1` (inside `err`). Hence FAIL is monotone non-decreasing across the run; once any `err` fires, the gate must take the failure branch.
- **L-TOP (top-level err):** every syntactic call site of `err` is a top-level `|| err …` list (checks 1–6); none occurs inside `$( … )` or a pipeline, so the `FAIL=1` write lands in the gate's shell. (Verified by inspection of all 24 call sites.)
- **L-FIN (termination):** every loop ranges over a finite list (glob expansion, `sort -u` output, two literal word lists); the awk program exits at the 2nd `---` or EOF; all oracle tools terminate on finite input (oracle axiom). ⇒ **total correctness** at script level, modulo oracle termination.
- **L-SETU (no abort):** under `set -u`, every expanded variable (`f dir fm keys name r s hits j p FAIL` and `$*`/`$0`) is assigned before use on every path ⇒ no nounset abort; `pipefail` affects only statuses that the script never branches on.
- **Abstraction note:** shell stores `FAIL` as the strings `"0"`/`"1"`; claims abstract it to Bool. `[ "$FAIL" -ne 0 ]` is the Bool test under that abstraction (sound: only those two values are ever assigned).

## 6. How the proof composes

(MAIN) = sequential Transitivity through: `cd` (oracle; see F8) → `FAIL=0` → [check-1 via (LOOP-1)] → `ok` → [check-2 via (LOOP-2)] → `ok` → [check-3 straight-line] → `ok` → [check-4 via (LOOP-4) + 12 straight-line manifest tests] → `ok` → [check-5 straight-line] → `ok` → [check-6 via (LOOP-6) + 5 grep tests] → `ok` → gate (Case Analysis on FAIL) → final echo. Each loop is discharged by its circularity (guardedness paid by the list-head consumption step); L-MONO + L-TOP carry `FAIL = ∨ of all violations so far` through the chain by framing. See PROOF.md.

*Derived from grosu/formal-verification-kit (MIT, Copyright (c) 2026 Grigore Rosu). See LICENSE and README credits.*
