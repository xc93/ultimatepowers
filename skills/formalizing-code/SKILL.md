---
name: formalizing-code
description: Use when formal contracts are needed for new or changed code, before any proof construction - covers intent capture, per-function reachability claims, per-loop and recursion circularities, and findings reporting
---

# Formalizing Code

## Overview

Read intent and implementation, then write the formal specification: one reachability claim per in-scope function, one circularity per loop or recursive function, and a plain-language findings report. K is notation here — nothing is compiled or run. The findings report is a first-class deliverable, not a by-product: writing a clean spec forces every input to be accounted for, and the inputs it cannot account for are the bugs.

**Core principle:** Spec-difficulty is itself a bug signal — if you cannot find a clean precondition, closed form, or side condition, do not paper over it; that difficulty is a reportable finding.

This skill derives contracts and reports findings. It never modifies the target.

**Announce at start:** "I'm using the formalizing-code skill to derive formal contracts."

**REQUIRED BACKGROUND:** You MUST understand ultimatepowers:formal-reasoning-foundations before using this skill. It supplies the claim notation, the reachability proof system, circularity + guardedness, the status-label vocabulary, and escalation routing. Before writing any claim, pick the closest shape from `formal-reasoning-foundations/references/claim-shapes.md` — its dispatch block routes by code structure (never by problem domain) to the numbered shape to imitate.

## Scoping

Two modes — confirm which one applies before enumerating targets:

| Mode | Scope |
|---|---|
| **Whole-target** | Every function and every loop of the named files. FVK's default; use for standalone or deep formalization. |
| **Diff-scoped** | Only the functions/loops/branches a diff touches, plus any function whose contract a touched function's proof must invoke. The ultimatepowers review default — an extension over upstream FVK, which is whole-project only. |

**Diff-scoped expansion rule:** a touched function's proof must invoke the contract of every function it calls within the analyzed body, so those callees enter scope **contract-only** — state their claim so the caller's proof can invoke it, but do not re-verify their bodies unless the diff also touched them. Expansion stops at calls with no in-repo definition (stdlib/builtins): model their documented behavior as Step 2 semantics rules instead of giving them contracts.

## The Workflow

Create a TodoWrite entry for each numbered step.

### Step 1: Read the target — intent AND implementation

Enumerate every in-scope function and loop. For each, infer the *intended* behavior first; then read the code as the implementation being checked against that intent.

Intent evidence priority order: plan/spec docs under `docs/ultimatepowers/` → commit messages → code comments/docstrings/tests.

Default is **intent-spec mode**: formalize the intended behavior and check the code against it. The *as-built* reading (formalizing whatever the code happens to do) is a secondary note used only when intent is unavailable — and say so when you fall back to it. The switch fires only when none of the evidence sources yields a behavioral claim (names and type signatures alone do not count); then formalize as-built and label the spec note as-built.

**Intent↔code divergence is exactly what becomes a finding. Missing or contradicted intent is reported as a finding, never silently assumed.**

### Step 2: Sketch the semantics fragment

Sketch a mini-X (mini-Python, mini-TS, …) covering ONLY the constructs the code uses: syntax, configuration cells, one rewrite rule per construct. In review mode, fenced K blocks inside the report suffice; full `.k` files are deep-mode artifacts. Reuse and extend one fragment across the tasks of a feature instead of re-sketching it per task. Don't invent K features to force a fit — a construct the fragment cannot faithfully cover is an escalation, not an invitation to improvise.

### Step 3: Per function — a reachability claim

State each function's contract as `φ_pre ⇒ φ_post`: the LHS `<k>` defines and calls the function on symbolic arguments; `requires` is the precondition; the rewritten cells are the postcondition. Uppercase logical variables (`S`, `I`, `N`), lowercase program variables (`s`, `i`, `n`).

```
claim
  <k>
    def sum_to_n ( n ) : INDENT
      s = 0
      i = 1
      while i <= n : INDENT s += i  i += 1 DEDENT
      return s
    DEDENT
    result = sum_to_n ( N:Int )
  => .K ... </k>
  <funcs> .Map => ?_:Map </funcs>
  <store> result |-> (_:Int => N *Int (N +Int 1) /Int 2) </store>
  <stack> .List </stack>
  requires N >=Int 0
  [all-path]
```

Reading: define the function, call it on symbolic `N`; for every `N >=Int 0`, execution terminates with `result |-> N*(N+1)/2`.

### Step 4: Per loop or recursive function — a circularity

Write the loop's claim generalized over accumulator and counter (never pinned to entry values), with the explicit soundness side condition bounding the counter (e.g. `I <=Int N +Int 1` — without it the claim is false):

```
claim
  <k> while i <= n : INDENT s += i  i += 1 DEDENT => .K ... </k>
  <store>
    s |-> (S:Int => S +Int (I +Int N) *Int (N -Int I +Int 1) /Int 2)
    i |-> (I:Int => N +Int 1)
    n |-> N:Int
  </store>
  requires I <=Int N +Int 1
  [all-path]
```

The claim is its own coinduction hypothesis; the closed form in the postcondition plays the role the classical invariant used to.

For recursion: a **function-contract circularity** over symbolic arguments — the contract discharges its own recursive call; the base case is the exit branch.

Input-validation guards (`isinstance` / `assert` / `if n < 0: raise`) are no-ops on the verified domain: model the reduced in-domain body, do not model `raise`, and turn each guard into a (often *positive*) finding.

### Step 5: Findings report

Write the findings per the format below. Non-blocking; this skill NEVER edits code.

## Findings Format

Every finding is a concrete `input → observed vs expected` — as a table where possible:

| input `n` | code returns (observed) | `n*(n+1)/2` (expected) | agree? |
|---|---|---|---|
| `-3` | `0` | `3` | ✗ |
| `0` | `0` | `0` | ✓ |

Required coverage — check every item for every in-scope function:

- **Missing preconditions / side conditions** — inputs the code silently assumes.
- **Forgotten corner cases** — empty, zero, negative, boundary, overflow, off-by-one.
- **Undefined or intent-contradicting behavior** — results that are meaningless or disagree with stated/inferred intent.
- **Non-universal postconditions** — claimed behavior that fails for some in-domain input.
- **Dead / unreachable code** — branches or statements that can never execute.

**Stuck semantics = runtime exception.** A rule guard that cannot fire is the formal mirror of the crash — a division rule requiring `I2 =/=Int 0` that cannot fire IS the ZeroDivisionError.

Report **positive findings** (a guard that enforces the spec's precondition is the code doing the right thing) and **deliberate non-findings** (stated because a reviewer will ask, with executed evidence where possible). Deep model: `grosu/formal-verification-kit/examples/02-sum-up/FINDINGS.md`.

## Finding Classification Taxonomy

Tag every finding with exactly one classification:

- missing precondition (silent wrong value)
- unenforced documented precondition
- undefined behavior / crash (stuck config)
- non-termination on bad input
- resource boundary (e.g. recursion depth, measured)
- intent-relevant implementation choice (stability, duplicate policy, int-vs-float, in-place mutation/aliasing)
- cross-language portability hazard (overflow)
- spec-difficulty signal
- positive finding
- deliberate non-finding
- escalation boundary (capability, not code)

## Red Flags

| Excuse | Reality |
|--------|---------|
| "The code obviously works" | State the claim anyway; universal quantification is where hidden inputs surface. |
| "No clean invariant exists, skip this loop" | That difficulty IS the finding; report what looks suspicious. |
| "I'll just formalize what the code does" | As-built mode only when intent is unavailable, and label it as-built. |
| "The guard handles it, nothing to report" | A guard that enforces the spec is a positive finding; record it. |
| "This side condition is just bookkeeping" | Forced side conditions are usually silent preconditions; report them. |

## Output Contract

1. **Claims** — fenced K: one reachability claim per function, one circularity per loop/recursive function. A function containing a loop needs **both** artifacts: its function claim (Step 3) **and** the loop's circularity (Step 4).
2. **Spec note** (SPEC.md-style) — per function/loop, in plain English: precondition, postcondition, side conditions, how the proof will compose, which lemmas will be needed, fragment scope, status label. Deep model: `grosu/formal-verification-kit/examples/02-sum-up/SPEC.md`.
3. **Findings** — FINDINGS.md-style content per the format above.

Status label is always `constructed` at this stage — upstream's own spec-stage status line: specs "**constructed, not machine-checked**". Here `constructed` qualifies the *claims*: they are stated via constructed symbolic reasoning, no proof has been constructed yet, and nothing is machine-checked; the proof-level sense of `constructed` (a proof written and reviewed) is applied later, by the verification stage. When the claims and findings are complete, proof construction proceeds via `ultimatepowers:verifying-specs`, which gates on these artifacts existing.

*Derived from grosu/formal-verification-kit (MIT, Copyright (c) 2026 Grigore Rosu). See LICENSE and README credits.*
