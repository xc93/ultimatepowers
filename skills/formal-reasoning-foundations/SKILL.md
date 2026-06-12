---
name: formal-reasoning-foundations
description: Use when writing or reading K-notation reachability claims, circularities, proof sketches, or formal findings - the notation, proof-system, and claim-shape reference behind the formal verification skills
---

# Formal Reasoning Foundations

## Overview

K is used here as **notation for rigorous reasoning, not as a tool**: no K toolchain is ever run. The value is disciplined symbolic reasoning — real K syntax, Z3-dischargeable side conditions — written so the designed-in escape hatch to genuine machine-checking (`kompile`/`kprove`) stays open. Everything produced this way is labeled `constructed`, never `machine-checked`.

The notation works because matching logic is **one logic for both terms and formulas: a pattern denotes a set** (a subset of the model `M`). A term like `5` or `cons(x, xs)` is a pattern whose set is a singleton; a formula like `x = 5` denotes `M` (true) or `∅` (false) — terms and formulas differ only in how big their set is. Connectives are set operations: `∧` is intersection, `∨` is union, `¬` is complement, `∃x` is union over witnesses. That is why a K claim can hold a program configuration and a logical constraint in the same formula — `#And`/`#Or`/`#Not`/`#Exists`/`#Equals` in a K claim are literally matching-logic connectives.

This skill is the required background for `ultimatepowers:formalizing-code`, `ultimatepowers:verifying-specs`, and `ultimatepowers:formal-code-review`.

## Reachability claims generalize Hoare triples

A reachability rule is a pair of configuration patterns

```
    φ  ⇒  φ'
```

read: *every (terminating) execution starting from a state matching `φ` reaches a state matching `φ'`.* Each `φ` is a matching-logic pattern — a symbolic configuration (the K cells `<k>`, `<store>`, ...) conjoined with a first-order side constraint (`#And` a `requires`). It is a Hoare triple `{Pre} code {Post}` recast so **the code itself lives inside the pattern** (in the `<k>` cell). The win: **one operational semantics serves both execution and proof** — the same rewrite rules that run a program are the axioms you reason with; there is no separate axiomatic semantics to write, keep in sync, and trust (a classic source of soundness bugs). Pre/postconditions, frame conditions, and program text are all parts of one pattern. A K `claim` *is* a reachability rule.

## K claim notation

The working core. Each element, with its gloss:

- **Configuration cells** `<k> <store> <funcs> <stack>` — the computation, the program-variable store, the function table, the call stack.
- **`~>`** — "then": the cons of the computation list in `<k>`. **`.K`** — the empty computation; `=> .K` means "runs to completion".
- **Store rewrites** `x |-> (OLD => NEW)` — variable `x` starts as `OLD` and ends as `NEW`, before/after per variable.
- **Untouched bindings** (`n |-> N:Int`) constrain the inputs without asserting change.
- **`...`** — framing: "the rest of this cell is unchanged/irrelevant". `<k> X => V ... </k>` rewrites only the head; `<store> ... X |-> V ... </store>` matches anywhere in the map. This is the frame condition, for free.
- **`requires`** — the precondition on the symbolic inputs. **`ensures`** — the postcondition: constraints that must hold after execution, with `?`-prefixed existentials for "some value exists" (`?C:Int` in the configuration plus `ensures (?C ==Int A) orBool (?C ==Int B)`; `<funcs> .Map => ?_:Map` is the idiom for "ends in some unconstrained map").
- **`[all-path]`** — every execution path from LHS reaches RHS (`[one-path]`: some path does).
- **Variable convention** — uppercase logical variables (`S`, `I`, `N`) for math values; lowercase program variables (`s`, `i`, `n`). They never clash: program variables lex as `Id`.
- **`/Int` truncates toward zero; `divInt` floors toward −∞** — a repeatedly-flagged trap when moving between code and closed forms.

The running example (the count-up sum loop — every formal skill builds on this claim):

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

Reading it: from any state with `i = I`, `s = S`, `n = N` and `I <=Int N +Int 1`, running the loop terminates (`=> .K`), adds `(I+N)*(N-I+1)/2` (the sum from `I` to `N`) to `s`, and leaves `i = N+1`.

## The reachability proof system

You prove `A ⊢ φ ⇒ φ'` (the semantics `A` entails the rule) with seven rules. The first six are routine symbolic execution plus glue; the seventh, Circularity, is the whole point.

| Rule | What it does |
|---|---|
| **Reflexivity** | `A ⊢ φ ⇒ φ` — the zero-step execution. This is precisely where guardedness bites: a circularity hypothesis is forbidden from closing a goal via Reflexivity alone. |
| **Axiom** (+ framing) | Apply one semantic rule from `A` (with a substitution). Framing carries the untouched parts — the rest of `<k>`, unmentioned store bindings, the side constraint — unchanged around the step. |
| **Transitivity** | Chain `A ⊢ φ ⇒ φ₁` and `A ⊢ φ₁ ⇒ φ'` into `A ⊢ φ ⇒ φ'`. |
| **Consequence** | Strengthen the pre / weaken the post via a first-order implication discharged by SMT (Z3) or `[simplification]` lemmas. This is where arithmetic VCs are dispatched. |
| **Case Analysis** | Split a goal whose precondition is a disjunction `φ ≡ φ₁ #Or φ₂` and prove each branch — e.g. the loop guard `true` vs `false`. |
| **Abstraction** | Existentially quantify away variables that occur in the precondition but not the postcondition (e.g. overwritten initial values `∃S₀,I₀`). |
| **Circularity** | Use a rule as its own hypothesis — next section. |

K realizations: `seqstrict` heating/cooling ↔ the operand micro-steps of Axiom (heating/cooling rules are themselves auto-generated semantic rules, so they are applied *via* Axiom, not a separate proof rule); `#Or` ↔ Case Analysis; the SMT/`[simplification]` oracle ↔ Consequence; `...` ↔ framing (K's automatic cell-completion).

## Circularity + guardedness

```
    A ∪ {φ ⇒ φ'}  ⊢  φ ⇒ φ'
    ─────────────────────────
        A  ⊢  φ ⇒ φ'
```

You may **assume the very rule you are proving** — *provided* the hypothesis is only ever used **after at least one genuine `=>⁺` step** (one real semantic transition). This proviso is **guardedness**, and it is the whole soundness story: it makes the otherwise-circular argument a sound guarded coinduction, because every appeal to the hypothesis is paid for by real progress. Concretely, the hypothesis may never close a goal via Reflexivity alone (zero steps).

**It replaces the loop invariant.** Classically you invent `Inv` and prove it established, preserved, and implies-the-post. Here instead:

- **Loops** — the loop's own claim, **generalized over accumulator and counter**, is the coinductive hypothesis. Evaluating the guard is the genuine step that earns it; the guard-true branch reaches the same loop in a shifted state and invokes the claim on itself (precondition re-checked, e.g. at `{S := S+I, I := I+1}`); the guard-false branch pins the counter (`I = N+1`) and the closed form collapses (empty sum `0`). The role the invariant played is now played by the closed-form expression in the claim's postcondition.
- **Recursion** — a recursive function's back-edge is the recursive call, so the **function's own contract is the hypothesis**: `f(N) ⇒ result(N)` discharges its inner call `f(N−1)`. Guardedness is paid by the `call` step; the base case is the exit branch.
- **Mutual recursion** — two contracts discharge *each other's* inner calls (every claim in the module is a hypothesis while proving any of them).
- **Nested loops** — one claim per loop; the inner claim is used as a lemma by the outer.

K realizes this with zero ceremony: **every `claim` in the module is automatically a circularity available as a hypothesis.**

## Soundness side conditions are load-bearing

Without `I <=Int N +Int 1` the sum-loop claim above is **false**: for `I >= N+2` the body never runs, so the true added sum is `0`, but the closed form `(I+N)*(N-I+1)/2` goes **negative** — `N=0, I=2` gives `−1`. The side condition is not cosmetic; it is part of what makes the claim true at all.

A side condition you are *forced* to add (like `I <= N+1`, or a function precondition like `N >= 0`) is often a precondition the code silently assumed and never checked. Spec-difficulty is a bug signal: if you cannot find a clean closed form, a clean precondition, or a clean side condition — or the VCs refuse to discharge — do not paper over it; surface it as a finding.

## Partial vs total correctness

Circularity gives **partial correctness**: *if and when* the loop terminates, the postcondition holds. Guardedness yields coinductive soundness without a variant, so termination is simply not established. **Total correctness** additionally requires a **decreasing measure** (e.g. `N − i`, bounded below by `0`, strictly decreasing each iteration). Default is partial correctness; flag total correctness as a recommendation, and when asked, add the variant to the loop claim and discharge "strictly decreases, bounded below" alongside the other VCs. Always state which one a proof establishes.

## Two-tier VC discharge

Consequence steps generate first-order verification conditions (VCs). Two tiers:

- **Linear facts → Z3 tier.** `N ≥ 0 ⇒ 1 ≤ N+1`, `I ≤ N ⇒ I+1 ≤ N+1`, zero-factor exits. Treat these as discharged when they are elementary linear arithmetic.
- **Nonlinear / truncating-division / map facts → named `[simplification]` lemmas.** When a VC equates two distinct symbolic products under truncating `/Int`, or pins a result through a map update, supply lemmas. The canonical pair:

```
// map extensionality: closes the post-store implication (result <- V)
rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' } [simplification]

// exact halving of an always-even product of consecutive integers
rule (X:Int *Int (X +Int 1)) /Int 2 *Int 2 => X *Int (X +Int 1) [simplification]
rule ((A:Int +Int B:Int) *Int C:Int) /Int 2 *Int 2 => (A +Int B) *Int C
  requires ((A +Int B) *Int C) modInt 2 ==Int 0 [simplification]
```

The exact-halving pair is **VC-EXACT**: a product of two consecutive integers is always even, so each `/Int 2` is exact — Z3 will not equate `(P /Int 2) *Int 2` with a symbolic product `P` without the evenness-guarded lemma. `[simplification]` rules are the VC oracle, applied wherever their LHS matches; they are sound to add as needed, but **you own each lemma's soundness** (it must preserve definedness).

## Spec-only abstraction functions

When a postcondition is **relational** (sorted, permutation, membership, a bound) rather than an arithmetic closed form, declare **spec-only abstraction functions** — `[function]` symbols in the spec vocabulary (the `VERIFICATION` module) — and use them in `ensures`: `isSorted(List)` (inductive Bool), the multiset `bag(List)` (value→count Map, so `bag(X) ==K bag(Y)` *is* "permutation"), `inList`, folds (`listsum`), measures (`h(Tree)`). These are **spec vocabulary, not language constructs** — the program never mentions them.

The bundled `[simplification]` tier does **not** discharge inductive-predicate or multiset VCs: state those as explicit `[ESCALATION BOUNDARY]` obligations, never `[trusted]`.

## Status labels & honesty

Frozen vocabulary — every formal artifact carries exactly one of these labels:

| Label | Meaning |
|---|---|
| `constructed` | The proof is written and reviewed but **not** machine-checked. The default. |
| `machine-checked` | `kprove` returned `#Top`; the K toolchain verified the proof. |
| `constructed (escalation-bounded)` | Constructed, and additionally some VCs need a theory beyond the bundled tier — each stated as an explicit `[ESCALATION BOUNDARY]` obligation. |

- **`#Top` from `kprove` is the only thing that upgrades `constructed` to `machine-checked`.** Never claim confidence a constructed proof does not have.
- **`[trusted]` is never used to fake an obligation** the bundled tier cannot discharge — that manufactures confidence that does not exist.
- **Escalating is not giving up**: state all claims well-formed, define the spec-only abstractions, discharge every VC the bundled tier can, and mark the rest `[ESCALATION BOUNDARY]`. The open obligations are **specified, not hidden**.

## Limits & escalation routing

The fast path is an imperative function over ints/maps/lists with counting loops or simple recursion (one accumulator/argument, polynomial closed form). Beyond it, route by topic — papers resolve to `https://fsl.cs.illinois.edu/publications/<slug>.pdf`:

| Topic | Escalation target |
|---|---|
| Recursive heap predicates / linked structures (lists, trees) | OOPSLA 2020, *Unified fixpoint reasoning* (`chen-pena-rodrigues-rosu-trinh-2020-oopsla`) |
| Binders, scoping, α-equivalence (λ, quantifiers, locals) | ICFP 2020, *A General Approach to Define Binders* (`chen-rosu-2020-icfp`) |
| Induction / least-fixpoint `μ` reasoning, well-founded data | LICS 2019, *Matching μ-Logic* (`chen-rosu-2019-lics`) |
| Reachability rule mechanics, the Circularity rule, soundness | FM 2012, *From Hoare Logic to Matching Logic Reachability* (`rosu-stefanescu-2012-fm`) + LICS 2013, *One-Path Reachability Logic* (`rosu-stefanescu-ciobaca-moore-2013-lics`) |
| Definedness / equality / membership / sorts, the proof system | LMCS 2017, *Matching Logic* (`rosu-2017-lmcs`) |
| A worked, end-to-end claim to imitate | K Tutorial Lesson 1.22, "Basics of Deductive Program Verification using K" |

Escalate per the pattern above: name the obligation, keep the claims well-formed, route — never produce confident nonsense outside the fast path.

## Claim-shape catalog

Pick the closest shape before writing any claim: see `references/claim-shapes.md`.

*Derived from grosu/formal-verification-kit (MIT, Copyright (c) 2026 Grigore Rosu). See LICENSE and README credits.*
