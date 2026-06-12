# PROOF — `scripts/check-structure.sh` (final review, deep mode)

**Status: constructed (escalation-bounded) — constructed, not machine-checked.**
Correctness scope: **total correctness** at script level (termination established via L-FIN), *modulo* oracle termination (external tools on finite input — trusted base).

## §1 The reachability spec

Math form. Let `T` range over repo trees, and let the implemented check predicates be
`Φ1(T)…Φ6(T)` (frontmatter, ref-resolution, stale-refs, manifests, hook-exec, formal-surface — each defined as the spec-only fold `¬hasViolₖ`, SPEC.md §4). Then:

> For every `T`: the script terminates; if `Φ(T) = Φ1∧…∧Φ6` it writes the six `ok:` lines and `STRUCTURE CHECK PASSED` and exits 0 with zero `FAIL:` lines; otherwise it writes one `FAIL:` line per violation, then `STRUCTURE CHECK FAILED`, and exits 1.

K claim: SPEC.md §4 (MAIN), `[all-path]`.

## §2 The loop circularities

Four `for` loops, one circularity each — (LOOP-1) over `glob("skills/*/SKILL.md")`, (LOOP-2) over `refsIn(T)`, (LOOP-4) over the 9-manifest word list, (LOOP-6) over the 7-path word list. Each is generalized over the remaining list `GS` and the entry accumulator `F:Bool` (never pinned to entry values):

```
<env> ... FAIL |-> (F:Bool => F orBool hasViolK(GS, T)) ... </env>
<out> ... .List => failLinesK(GS, T) </out>
```

No soundness side condition on a counter is needed: the "counter" is the list itself and the fold is total on lists (structural recursion on a finite list — not a numeric counter that could overshoot). The shape is the list-fold/relational pair 01/09 from the claim-shape catalog, not the arithmetic 02/03 pair.

## §3 Informal proof

Fix `T`. After `cd` (oracle; finding F8 covers its unguarded failure mode — assume the in-domain precondition "script invoked from an intact checkout") and `FAIL=0`, the store satisfies the entry condition of (LOOP-1) with `F=false`, `GS=glob(...)`.

Each loop: Case Analysis on `GS`. If `.List`, Reflexivity-of-shape gives the exit branch: `F orBool hasViolK(.List)=F orBool false=F`, no output — the claim collapses. Otherwise `GS=ListItem(P) L`: one genuine `=>⁺` step consumes the head (the loop-step rule fires — guardedness paid), the body executes straight-line: command substitutions evaluate via oracle axioms; each `[test] || err` either skips (test holds — no store change) or calls `err`, which by (ERR) appends exactly one `FAIL:` line and sets `FAIL` to `true`. The body's effect is precisely `F := F ∨ viol(P)`, `out ++= failLines(P)`. The circularity hypothesis is then invoked on the shifted state `{GS := L, F := F ∨ viol(P)}` — its precondition (none beyond sort constraints) holds — closing the branch. Both branches land on the claimed post-state. ∎ (per loop)

Composition (Transitivity): chain `cd → FAIL=0 → (LOOP-1) → ok → (LOOP-2) → ok → check-3 straight-line → ok → (LOOP-4) → 12 manifest tests → ok → check-5 (3 tests) → ok → (LOOP-6) → 5 grep tests → ok → gate`. L-MONO (FAIL written only by `err`, only to `true`) and L-TOP (every `err` call site is top-level — all 24 sites inspected; none inside `$( )` or a pipe) let framing carry `FAIL = ∨(all violations so far)` through every segment. L-SETU rules out `set -u` aborts (all variables assigned before use on every path), there is no `set -e`, and the only `exit` is inside the gate — so **all six groups always execute**; no short-circuit exists.

Gate: Case Analysis on `FAIL`. `true` ⇒ `echo FAILED; exit 1` (matches the ¬Φ disjunct: by the loop posts, FAIL=true ⟺ some `hasViolₖ` ⟺ ¬Φ(T), and ≥1 `FAIL:` line was emitted by the very `err` that set it). `false` ⇒ the `if` falls through, final `echo PASSED` exits 0 (status of last command). ∎

Termination: every loop is structural recursion on a finite list (L-FIN); the awk oracle halts at the second `---` or EOF; no `while`, no recursion. Total. ∎

## §4 Machine-detailed sketch

Steps cite the fragment rules (SPEC.md §3). Representative trace for one (LOOP-1) iteration on `ListItem(P) L`:

1. `loop-step` (Axiom): unfolds body with `f:=P` — **the genuine `=>⁺` step that earns the circularity** for this iteration.
2. `asgn-substitution` ×3 (Axiom + oracle): `dir := basename(dirname(P))`, `fm := awkFM(P)`, `keys := keysOf(fm)` — heating/cooling of `$( )` operands are the seqstrict micro-steps.
3. `test-or-skip` / `test-or-run` (Axiom, Case Analysis on `holds`): keys test; on `false` branch, `call err` → (ERR).
4. `asgn` `name := nameOf(fm)`; second test likewise.
5. Circularity hypothesis (LOOP-1) on `{GS:=L, F:=F∨viol(P)}` — used after step 1's genuine step: guarded. ✓

VC table (Consequence steps; all propositional/equational — no arithmetic tier needed):

| VC | Statement | Discharged by |
|---|---|---|
| VC-1 | `(F ∨ viol(P)) ∨ hasViol1(L) = F ∨ hasViol1(ListItem(P) L)` | fold unfolding + ∨-assoc/comm (propositional; by inspection — Z3-trivial) |
| VC-2 | `failLines1(ListItem(P) L) = failLines(P) ++ failLines1(L)` | definitional unfolding of the fold |
| VC-3 | err post: `true = F ∨ true`; skip post: `F = F ∨ false` | propositional |
| VC-4 | gate: `FAIL=true ⟺ ¬Φ(T)` at gate entry | Transitivity through the six segment posts + L-MONO |
| VC-5 | exit status: failure branch ret=1 (`exit 1` rule); success branch ret=0 (status of final `echo`) | Axiom application |
| VC-6 | `Φk(T) ⟺ ¬hasViolₖ(inputsₖ(T))` matches each shell test's oracle reading (e.g. `[ "$keys" = "description name " ]` ⟺ `keysOf(awkFM(P)) = "description name "`) | oracle axioms — **trusted base**, empirically spot-validated (§7 runs A, A2, B, C, D) |

No `[simplification]` lemmas were needed (no nonlinear arithmetic, no `/Int`, no map-update equalities). No obligation was admitted `[trusted]`.

**[ESCALATION BOUNDARY] E1 — runnable artifacts.** Deep mode calls for runnable `<mod>.k` / `<mod>-spec.k`. A *faithful* runnable K semantics for this target requires defining POSIX-sh word splitting, pathname expansion, command substitution, and the observable behavior of `awk/grep/sed/cut/sort/tr/jq/ls/wc` — far beyond the bundled mini-imperative fragment, and inventing K features to force the fit is prohibited (formalizing-code Step 2). Open obligation, specified: a mini-bash K definition + a tool axiomatization, after which the §1/§2 claims as written can be transcribed into a `-spec.k` and run. Until then no `kprove` target exists; the machine-check escape hatch for THIS artifact is the executed-command evidence package in §7 (real, reproducible commands — but not `kprove`, hence the label stays `constructed`).

**[ESCALATION BOUNDARY] E2 — oracle adequacy.** VC-6 equates shell pipelines with their oracle axioms. This is the fragment-adequacy assumption instantiated for external tools; it was *empirically validated* on the five counterexample inputs (§7) but not proved. A misaxiomatized corner of `grep`/`awk` semantics would move a finding, not the P1 contract (P1 depends only on shell-level rules).

## §5 Findings

See FINDINGS.md (F1–F8, PF1–PF6). The proof-derived ones: F1/F2/F5 fell out of stating `Φ1` precisely (the awk/grep oracle axioms refused to support the intended `Ψ1`); F3/F4 out of `Φ2`/`Φ3` vs the spec's quantifiers; F7 out of the (ERR) output shape vs the plan's diagnostic promise; F8 out of the unguarded first Transitivity link.

## §6 Test redundancy

None recommended. Test-removal advice is gated on an actual `kprove` → `#Top`, which does not exist here (and the repo's test suites target skill behavior, not this script — keep all).

## §7 Reproduce the evidence

Machine-check commands (BLOCKED on E1 — no runnable fragment exists; listed for the escape hatch):

```sh
kompile mini-bash.k --backend haskell      # [ESCALATION BOUNDARY E1: mini-bash.k not constructible in bundled tier]
kast    --backend haskell check-structure-spec.k
kprove  check-structure-spec.k             # expected: #Top — would upgrade constructed → machine-checked
```

Executed evidence (these DID run, 2026-06-12, all reproducible from repo root):

```sh
# P2: implementation == plan verbatim
sed -n '1106,1193p' docs/ultimatepowers/plans/2026-06-12-ultimatepowers-integration.md | diff - scripts/check-structure.sh
# current tree passes; version audit clean
./scripts/check-structure.sh; scripts/bump-version.sh --audit
# rebrand round-trip (per differing file f):
sed -e 's/using-superpowers/__K__/g' -e 's/ULTIMATEPOWERS/SUPERPOWERS/g' \
    -e 's/Ultimatepowers/Superpowers/g' -e 's/ultimatepowers/superpowers/g' \
    -e 's/__K__/using-superpowers/g' "$f" | diff - "reference/superpowers/$f"
# counterexamples A, A2, B, C, D: synthetic tree under /tmp running the script's exact pipelines
# (transcripts embedded in the review report; constructions described in FINDINGS.md F1–F6)
```

## Citations

- Roşu, *Matching Logic*, LMCS 2017 — pattern semantics behind the claims.
- Roşu & Ştefănescu, *From Hoare Logic to Matching Logic Reachability*, FM 2012; + LICS 2013 — the reachability proof system (Circularity, guardedness) used in §3/§4.
- grosu/formal-verification-kit @ d0d07ba — claim shapes, status-label vocabulary, honesty gate.

*Derived from grosu/formal-verification-kit (MIT, Copyright (c) 2026 Grigore Rosu). See LICENSE and README credits.*
