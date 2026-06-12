---
name: verifying-specs
description: Use when reachability claims exist and need proof construction - covers symbolic execution, circularity discharge, verification conditions, escalation boundaries, and honest status labeling
---

# Verifying Specs

## Overview

Construct the proof of stated reachability claims: symbolic execution against the semantics fragment, circularities discharged by guarded coinduction, verification conditions dispatched by tier, the function proof composed by Transitivity — then report what was and was not established, with honest labels. No K toolchain runs: the proof is constructed on paper, and the proof-derived findings are as much the product as the proof.

**Core principle:** Verification certifies conformance to a stated contract, not the absence of bugs — and a constructed proof is never machine-checked.

**Announce at start:** "I'm using the verifying-specs skill to construct the proof."

**REQUIRED BACKGROUND:** You MUST understand ultimatepowers:formal-reasoning-foundations.

**Gate:** If the claims/specs do not exist yet, STOP and use `ultimatepowers:formalizing-code` first — do not invent specs here; this skill proves a stated contract, not chooses it.

## Proof Construction

Work claim by claim:

- **Symbolic execution.** Drive `<k>` with the semantics rules; the `seqstrict` heating/cooling micro-steps are the manual lookup/add/compare steps of a paper proof. Chain steps via Transitivity; carry untouched cells, bindings, and constraints by framing (`...`).
- **Circularity discharge by guarded coinduction.** Every claim in the module is a hypothesis, usable only after ≥1 genuine `=>⁺` step (guard evaluation earns it). Case-split on the guard (`#Or`): the body-taken branch invokes the circularity on the shifted state (e.g. `{S := S+I, I := I+1}`) with the precondition re-checked; the exit branch pins the counter (e.g. `I = N+1`) and the closed form collapses to the empty sum. Both branches must land on the claimed post-state. Recursion is the same move — guardedness is paid by the `call` step, the case split is base vs recursive branch.
- **Arithmetic VCs via Consequence.** Linear facts (`N ≥ 0 ⇒ 1 ≤ N+1`, `I ≤ N ⇒ I+1 ≤ N+1`, zero-factor exits) → the Z3 tier. Symbolic products, truncating `/Int`, and map equalities → `[simplification]` lemmas (the canonical pair: exact-halving and map-extensionality). Name each lemma you introduce; you own its soundness.
- **Compose the function proof by Transitivity.** `def` files the function → `call` binds params in a fresh scope → body init (the assignment statements execute symbolically to reach the loop-entry store: `s = 0` drives `s |-> (_ => 0)`, `i = 1` drives `i |-> (_ => 1)`) → loop via its circularity used as a lemma (instantiated at that entry store, e.g. `{S := 0, I := 1}`, precondition discharged) → `return` pops the frame. Result: `A ⊢ φ_pre ⇒ φ_post`.
- **Scope.** Partial correctness by default. The termination upgrade is a decreasing measure (bounded below, strictly decreasing per iteration), stated and discharged only when requested. Always state which one was established.

## Failure Is Data

If construction fails or gets stuck — a VC won't discharge, a side condition must be invented, a postcondition fails on an in-domain input, no clean closed form exists — that is a finding, not a dead end. Distinguish the two kinds of gap:

| Gap | What it is | What to do |
|---|---|---|
| **Correctness gap** | A code bug | Report with a concrete `input → observed vs expected`, with full confidence, prominently |
| **Capability gap** | A VC beyond the bundled tier — inductive predicates, multisets, structural induction | State as an explicit `[ESCALATION BOUNDARY]` obligation; route by the foundations escalation table |

A capability gap is **never** admitted as `[trusted]` — that fakes confidence the kit does not have — and it is never reported as a code bug: it is a limit of the kit, not a defect in the code.

Mixed proofs are normal: when some branches close and some VCs stick, keep everything that was established and classify each stuck VC individually by the table above — a partial proof is still evidence. The label then follows from what remains open: a clean construction (all VCs discharged, no open obligations) is `constructed`; open `[ESCALATION BOUNDARY]` obligations make the artifact `constructed (escalation-bounded)`; only an actual `kprove` run returning `#Top` yields `machine-checked`.

## Honesty Gate

Mandatory — apply before emitting any status label or final output:

- Every artifact is labeled `constructed, not machine-checked`. Never claim confidence the un-machine-checked proof doesn't have.
- The findings do NOT depend on machine-checking — report those with full confidence.
- Capability gaps are never reported as code bugs.
- Partial vs total correctness is always stated.
- Disclose the trusted base: adequacy of the mini-X fragment; the reachability metatheory; the Z3/`[simplification]` oracle.
- **Test removal is recommendation-only and conditioned on an actual `kprove` → `#Top` run. Never delete a test, and never instruct deletion of a test.**

## Proof-Derived Findings Schema

Every proof obstacle and proof-discovered fact becomes an entry with these fields:

- **Evidence** (exact claim/branch/VC/side condition)
- **Classification** (code bug | missing precondition | underspecified intent | needed code guard | termination/performance gap | test gap | proof capability gap/escalation)
- **Question for the author** (the next clarifying question, e.g. "Should negative `n` raise, return 0, or be outside the domain?")
- **Recommended next code/spec change**
- **Tests** (add / keep / conditionally remove — gated as above)

Worked instance: `sum_to_n`'s proof needs `N >= 0` → classification: missing precondition / needed code guard; question for the author: reject negatives, return `0`, or define a signed sum?

Stop with the findings and feedback. Do not patch or regenerate code unless the user explicitly asks for a repair pass — the output is an evidence package.

## Test-Redundancy Report (Optional Output)

- Flag a test as redundant **only** when its assertion is entailed by the proof within the verified domain, with a one-line reason each (e.g. `sum_to_n(5) == 15` → `5*6/2 = 15`, `5 ≥ 0` → subsumed).
- Keep, explicitly: **out-of-domain tests** (often exactly where a finding lives), **termination/performance tests**, **integration tests**. A `sum_to_n(-1) == 0` boundary test stays.
- A CI-time-saved estimate is optional.
- Recommendation only. Test files are never touched.

## Deep Mode (Opt-In by the Caller)

When the caller asks for deep mode (e.g. a final review), emit runnable `<mod>.k` / `<mod>-spec.k` artifacts and the exact commands:

```sh
kompile <mod>.k --backend haskell        # compile fragment semantics (Haskell backend)
kast    --backend haskell <mod>-spec.k   # (optional) confirm claims parse to one AST
kprove  <mod>-spec.k                     # discharge claims; expected: #Top (all proved)
```

`#Top` upgrades `constructed` → `machine-checked`, and only then are conditional test removals safe. When the target language exceeds the bundled mini-imperative fragment family, runnable-artifact emission is itself an `[ESCALATION BOUNDARY]` obligation — state it; never invent K features to force a fit.

## Proof Write-Up Anatomy

When a PROOF.md is produced (final/deep reviews), use this structure:

- **§1** The reachability spec — math form + the K claim
- **§2** The loop circularity
- **§3** Informal proof — the guarded-coinduction narrative; ends ∎
- **§4** Machine-detailed sketch — every step cites a named semantics rule, guardedness called out, plus a VC table (VC | statement | discharged-by Z3-vs-which-lemma)
- **§5** Findings
- **§6** Test redundancy, with the machine-check caveat
- Reproduce-the-machine-check commands (the block above)
- Citations footer

## Red Flags

| Excuse | Reality |
|--------|---------|
| "Mark it [trusted] so the proof closes" | Forbidden; state `[ESCALATION BOUNDARY]`. |
| "The proof failed, so there's nothing to report" | A stuck proof is a strong bug signal; report it prominently. |
| "Call it verified" | Say `constructed`; only `#Top` makes it machine-checked. |
| "Delete the redundant tests" | Recommendation only, machine-check-gated. |
| "The capability gap means the code is buggy" | Capability gaps are kit limits, not code defects. |

*Derived from grosu/formal-verification-kit (MIT, Copyright (c) 2026 Grigore Rosu). See LICENSE and README credits.*
