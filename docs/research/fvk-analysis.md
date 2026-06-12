# FVK Analysis — `grosu/formal-verification-kit` for ultimatepowers integration

- **Analyzed:** 2026-06-12
- **Source:** submodule `/home/xc/Projects/ultimatepowers/reference/formal-verification-kit`
  (pinned commit `d0d07bad2d500467f7e1e9ccc4a3aa2af638a38d`, 2026-06-10, author Grigore Rosu;
  remote `https://github.com/grosu/formal-verification-kit.git`)
- **Purpose of this doc:** canonical research reference for authoring ultimatepowers skills that
  bring FVK-style formal analysis into the code-review phase. The knowledge digest (§3) is written
  so a skill author who never read the originals can produce a high-quality skill from it alone.

---

## 1. What FVK is, structurally

FVK is **not** a plugin, not a Claude Code skill set, and not a tool. It is a **provider-neutral,
plain-markdown "kit"**: a repo any coding agent reads to *learn* a methodology, plus two
prompt-convention "commands" (`/formalize`, `/verify`) that are defined entirely in markdown.
There is nothing to install, no scripts, no build, no SDK. The repo's own design doc
(`docs/superpowers/specs/...-design.md`) states: "No agent-specific command/plugin files in the
MVP. The two 'commands' are conventions defined in `AGENTS.md`; an agent honors `/formalize` and
`/verify` after reading the kit."

Notably, FVK was itself **built with superpowers** — `docs/superpowers/` contains a brainstormed
design spec and a superpowers-style implementation plan (referencing
`superpowers:subagent-driven-development` / `executing-plans`). It even references
"UltimatePowers" as the intent-elicitation layer that should consume its findings
(`commands/verify.md` Step 3: "**UltimatePowers question** — the next question the
intent-elicitation layer should ask the user"). So the integration direction we're pursuing is
the one the kit itself anticipates.

### 1.1 Complete file tree (excluding .git)

```
formal-verification-kit/
├── README.md                  # pitch: 2 benefits, quick start, honest status, vision, layout
├── AGENTS.md                  # universal entrypoint: BOOTSTRAP + /formalize & /verify triggers
├── LICENSE                    # MIT, Copyright (c) 2026 Grigore Rosu
├── commands/
│   ├── formalize.md           # the /formalize workflow (7 ordered steps)
│   └── verify.md              # the /verify workflow (6 ordered steps + honesty gate)
├── knowledge/                 # THE CORE — distilled "learning", read at bootstrap
│   ├── matching-logic.md      # 153 ln: patterns-as-sets, definedness ladder, μ, proof system
│   ├── k-framework.md         # 345 ln: K definitions, claims, kprove, heating, gotchas
│   ├── reachability-and-circularities.md  # 295 ln: proof system, Circularity, THE RECIPE
│   └── sources.md             # 85 ln: papers index + WHEN-TO-ESCALATE routing + --refresh
├── docs/superpowers/          # internal design docs (not user-facing kit)
│   ├── specs/2026-06-07-formal-verification-kit-design.md
│   └── plans/2026-06-07-formal-verification-kit.md
└── examples/                  # 13 worked examples + catalog README
    ├── README.md              # catalog (by shape/complexity), anatomy, production discipline
    ├── 01-average/            # list mean; ZeroDivisionError showcase
    ├── 02-sum-up/             # THE reference template (count-up loop)
    ├── 03-sum-down/           # count-down loop, "remaining-work" invariant
    ├── 04-fibonacci/          # coupled two-variable invariant; spec-only fib symbol
    ├── 05-gcd/                # preserved-relation invariant; Euclid identity escalates
    ├── 06-sum-recursive/      # recursion circularity (REC); positive guard findings
    ├── 07-factorial/          # recursion + non-polynomial spec-only fact symbol
    ├── 08-is-even-odd/        # mutual recursion: two contracts discharge each other
    ├── 09-array-max/          # arrays, ∀-quantified postcondition, no escalation
    ├── 10-binary-search/      # sortedness precondition; famous overflow finding
    ├── 11-reverse/            # index-relation post + permutation (escalates)
    ├── 12-insertion-sort/     # nested loops + relational spec; canonical escalation
    └── 13-tree-height/        # recursive data structure (Tree value sort); frontier
```

Each example folder contains (uniform anatomy): the program (`*.py`), `mini-python.k`
(fragment semantics), `mini-python-spec.k` (claims), `SPEC.md`, `FINDINGS.md`, `PROOF.md`,
`README.md`, `PROMPTS.md`. (`07-factorial` additionally has `test_factorial.py`.)

### 1.2 How it's meant to be installed/used

Per README quick start: point any agent at the repo ("Learn the Formal Verification Kit … read
its `AGENTS.md` and follow the BOOTSTRAP"), then say **"run /formalize"** and **"run /verify"**
(phrased with "run" because a bare leading `/` gets intercepted by agents' native slash-command
handling). `AGENTS.md` defines:

- **BOOTSTRAP** (one-time): read the three knowledge primers
  (`matching-logic.md`, `k-framework.md`, `reachability-and-circularities.md`), escalate to
  `sources.md` when not covered, then tell the user you're ready and **wait**.
- **TRIGGERS**: `/formalize` → follow `commands/formalize.md`; `/verify` → follow
  `commands/verify.md`. No arguments → whole project, every function and every loop.
- **TEMPLATE**: imitate the **closest example by shape** from the catalog (reference pair:
  `02-sum-up` / `03-sum-down`).

The intended **outer loop** (README + AGENTS.md): problem prompt → conventional code generation →
learn kit → `/formalize` → `/verify` → **stop with an evidence package** (`FINDINGS.md`,
`SPEC.md`, `PROOF.md`, `.k` artifacts, next-iteration guidance) for the next code-generation
pass. The kit must **not** silently patch/regenerate code unless the user explicitly asks for a
repair pass.

### 1.3 CRITICAL: does FVK actually run K?

**No.** This is explicit and repeated ("Honest status (MVP)" in README; "MVP scope" in
verify.md; the design doc §6 "Decision … the MVP does **not** invoke `kompile`/`kprove`"):

- `/verify` **constructs** the proof (symbolic execution on paper, circularity discharge,
  VC analysis) and **emits the exact `kompile`/`kprove` commands**, but **never invokes the
  toolchain**. Every artifact is labeled **"constructed, not machine-checked."**
- A `kprove` run returning `#Top` is what *would* upgrade "constructed" → "machine-verified".
- The K `.k` files are nonetheless written to be genuinely runnable (real K syntax, Haskell
  backend, Z3 side conditions) — K-as-notation is engineered so the escape hatch to real
  machine-checking stays open.
- The **Findings report does not depend on machine-checking** ("solid today"); only the
  *test-removal recommendation* is gated on actually running `kprove` (the "Honesty gate").

So FVK is precisely **"K-as-notation-for-rigorous-LLM-reasoning"** with a designed-in path to
real verification. For ultimatepowers this means: no toolchain dependency whatsoever; the value
is the disciplined reasoning method and report formats.

---

## 2. The workflow pipeline

### 2.1 `/formalize` (from `commands/formalize.md`, ordered steps)

1. **Learn** — read the three primers if not already internalized this session
   (`--refresh` variant additionally re-fetches live sources from `sources.md`).
2. **Read the target — intent AND implementation.** Enumerate **every function and every
   loop**. Infer *intended* behavior from all intent evidence: original prompt, conversation
   history, issues/requirements, `PROMPTS.md`, names, docstrings, comments, tests. Then read the
   code as the implementation being checked **against** that intent. Default mode is
   **intent-spec mode** — do *not* formalize "whatever the code happens to do" as if it were the
   spec (the *as-built* reading is only a secondary note when intent is unavailable).
   **Intent↔code divergence is exactly what becomes a finding.**
3. **Semantics — build a mini-X K fragment.** A minimal K semantics of *only* the constructs the
   code uses (mini-Python, mini-TS, …): a `*-SYNTAX` module + a main module with a
   `configuration` of cells and one rewrite rule per construct. Don't invent K features; check
   against the manual / Lesson 1.22. (Explicit MVP stopgap; roadmap = full per-language K
   semantics.)
4. **Specify each function — a reachability rule** `φ_pre ⇒ φ_post` as a K `claim`: LHS `<k>`
   defines the function and calls it on a symbolic argument; `requires` = precondition; the
   rewritten cells = postcondition. Convention: **uppercase math variables (`S`,`I`,`N`) for
   logical values, lowercase for program variables (`s`,`i`,`n`)** so they never clash.
5. **Specify each loop (or recursive function) — a circularity.** Loop claim **generalized over
   accumulator and counter** (never pinned to entry values), with the **soundness side
   condition** bounding the counter (e.g. `I <=Int N +Int 1`). For recursion: a
   **function-contract circularity** `f(args) ⇒ result` generalized over symbolic args.
   Input-validation guards (`isinstance`/`assert`/`if n<0: raise`) are **no-ops on the verified
   domain**: model the reduced in-domain body, do *not* model `raise`/exceptions, and turn each
   guard into a (often *positive*) Finding.
6. **Write artifacts** alongside the code: `<mod>.k`, `<mod>-spec.k` (+ any `[simplification]`
   lemmas the arithmetic needs), and a human-readable spec note.
7. **Findings report** (first-class, plain language, non-blocking; never edits code).
   Each finding is a concrete **`input → observed vs expected`**. Required coverage:
   missing preconditions/side conditions; forgotten corner cases (empty/zero/negative/boundary/
   overflow/off-by-one); undefined or intent-contradicting behavior; non-universal
   postconditions; dead/unreachable code. **Spec-difficulty = bug signal**: if a clean spec is
   hard or impossible to write (no clean precondition, awkward case splits, no clean loop
   invariant), *say so explicitly* — that difficulty is itself a finding; never paper over it to
   force a tidy claim.

**Output contract:** artifacts + Findings report; non-blocking advice only.

### 2.2 `/verify` (from `commands/verify.md`, ordered steps)

1. **Ensure the specs exist** — if `<mod>.k`/`<mod>-spec.k`/spec note are missing, run
   `/formalize` first. "Do not invent specs here; `/verify`'s job is to *prove* a stated
   contract, not to choose it."
2. **Construct the proof** by symbolic execution against the K semantics. Three moving parts:
   - **Symbolic execution**: drive `<k>` with semantic rules; `seqstrict` heating/cooling
     evaluates subexpressions (these micro-steps are the manual lookup/add/leq steps of a paper
     proof); chain via **Transitivity**; carry untouched cells/bindings/constraints via
     **framing** (K's automatic `...` cell-completion).
   - **Circularity discharge** (loop or recursive call) by **guarded coinduction**: every claim
     in the module is a hypothesis; it may assume itself only **after ≥1 genuine `=>⁺` step**
     (guard evaluation, or the `call` step for recursion). Case-split on the guard (`#Or`):
     body-taken branch invokes the circularity on the shifted state (precondition re-checked);
     exit branch pins the counter and collapses the closed form.
   - **Arithmetic VCs** via Consequence: linear facts → Z3; symbolic-product/truncating-`/Int`
     facts → `[simplification]` lemmas (e.g. VC-EXACT exact-halving, map-extensionality).
   - **Compose the function proof** by Transitivity: `def` files the function → `call` binds
     params in a fresh scope → body init → **loop via its circularity used as a lemma**
     (instantiated at entry, precondition discharged) → `return` pops the frame. Result:
     `A ⊢ φ_pre ⇒ φ_post`.
   - Default scope: **partial correctness**. Termination is a recommendation; when asked, add a
     decreasing measure (e.g. `N − i`, bounded below, strictly decreasing) and discharge it.
   - **If construction fails or gets stuck — that is a finding, not a dead end.** But
     distinguish **correctness gaps** (code bugs) from **capability gaps** (VCs beyond the
     bundled tier — inductive predicates, multisets): the latter are explicit
     `[ESCALATION BOUNDARY]` obligations, **never** admitted as `[trusted]` ("that fakes
     confidence the kit does not have").
3. **Accumulate proof-derived findings for the next generation.** Append a "Proof-derived
   findings from `/verify`" section to `FINDINGS.md`. Every entry has: **Evidence** (exact
   claim/branch/VC/side condition), **Classification** (code bug | missing precondition |
   underspecified intent | needed code guard | termination/performance gap | test gap | proof
   capability gap/escalation), an **UltimatePowers question** (the next clarifying question for
   the user, e.g. "Should negative `n` raise, return 0, or be outside the domain?"),
   **Recommended next code/spec change**, and **Tests** (add/keep/conditionally remove).
4. **Test-redundancy report.** Map existing tests onto the verified spec: flag as redundant any
   test whose assertion is **entailed by the proof within the verified domain** (one-line reason
   each, e.g. `sum_to_n(5)==15 → 5*6/2=15, 5≥0 → subsumed`), with CI-time-saved estimate;
   explicitly **keep** out-of-domain tests (often exactly where a Findings bug lives),
   termination/performance tests, and integration tests. **Recommendation-only, never
   auto-delete** (an opt-in `--apply` is a later feature).
5. **Emit artifacts**: proof write-up (PROOF.md shape), updated FINDINGS.md, the `.k` files, and
   the exact run-commands:
   ```sh
   kompile <mod>.k --backend haskell        # compile fragment semantics (Haskell backend)
   kast    --backend haskell <mod>-spec.k   # (optional) confirm claims parse to one AST
   kprove  <mod>-spec.k                     # discharge claims; expected: #Top (all proved)
   ```
   Label everything **"constructed, not machine-checked."**
6. **Report**: what's proved (plain language); residual risk (partial vs total correctness; the
   **trusted base** = adequacy of the mini-X fragment, the reachability metatheory/`kprove`,
   the SMT/`[simplification]` oracle; the not-machine-checked caveat); test-redundancy
   recommendation; Findings — failures/stuck points surfaced **prominently as a strong bug
   signal** with a concrete `input → observed vs expected`.

**Honesty gate (verbatim intent):** test removal is conditioned on machine-checking; never
auto-delete; never claim confidence the un-machine-checked proof doesn't have; the Findings
report does NOT depend on machine-checking — report those with full confidence.

### 2.3 Inputs the workflow needs

- **Whole files/projects**, not diffs: "No arguments → operate on the whole current program,
  writing a spec for *each* function and *each* loop." (Per-function targeting is a noted later
  feature.) For a code-review integration we will need to define diff→function mapping ourselves.
- **All intent evidence available**: original prompts, conversation history, issue text,
  docstrings, names, comments, tests. Intent is a first-class input, not an extra.
- No toolchain, no network needed (knowledge is bundled; `--refresh` optionally re-fetches
  papers/docs listed in `sources.md`).

---

## 3. Knowledge digest (the CRITICAL part)

This section digests all four knowledge docs faithfully, with notation reproduced precisely.

### 3.1 `knowledge/matching-logic.md` — the logic underneath

**The single idea: one logic for both terms and formulas, because a pattern denotes a set.**
That is why K can write a program configuration and a logical constraint in the same formula,
and why `#And`/`#Or`/`#Equals`/`#Not`/`#Exists` in a K claim are literally matching-logic
connectives.

1. **Patterns are sets.** Fix a carrier set `M` (the model). Every pattern `φ` is interpreted
   as a subset `|φ| ⊆ M` — the set of elements that match it. A term like `5` or `cons(x, xs)`
   is a pattern whose set is a singleton (or empty, for a partial application). A formula like
   `x = 5` denotes `M` (true) or `∅` (false). Terms and formulas differ only in *how big* their
   set is.

2. **Connectives are set operations:**

   | pattern | meaning | as a set |
   | --- | --- | --- |
   | `⊥` | bottom | `∅` |
   | `⊤` | top | `M` |
   | `φ₁ ∧ φ₂` | and | `\|φ₁\| ∩ \|φ₂\|` |
   | `φ₁ ∨ φ₂` | or | `\|φ₁\| ∪ \|φ₂\|` |
   | `¬φ` | not | `M \ \|φ\|` (complement) |
   | `∃x. φ` | exists | `⋃` over all witnesses for `x` |
   | `φ₁ → φ₂` | implies | `¬φ₁ ∨ φ₂` |

   A pattern is **valid** iff its set is all of `M`. `∃` is union-over-witnesses, so it mixes
   freely with structure: `∃x. cons(x, nil)` = "all one-element lists". Lowercase = element
   variables; capitals reserved for set variables (§μ). `∀x. φ ≡ ¬∃x. ¬φ`.

3. **Symbols, application, functions.** A symbol is interpreted as a relation lifted to the
   powerset; **application is pointwise**: `|σ(φ)| = ⋃ { |σ|(a) : a ∈ |φ| }`. Special shapes,
   not extra primitives: a **function** returns a singleton per argument tuple; a **partial
   function** may return `∅` (e.g. `head(nil)` — partiality with no error value needed); a
   **relation** returns any subset. K builtins (`+Int`, `<=Int`, `/Int`), MAP symbols
   (`_|->_`, `_[_<-_]`), and configuration cells are all just symbols — all patterns.

4. **The definedness ladder (everything DERIVED from one symbol).** One extra ingredient: the
   definedness symbol `⌈_⌉` with the single axiom `⌈x⌉ = ⊤` (for a variable `x`). Read `⌈φ⌉` as
   "`φ` is defined / matches something": `|⌈φ⌉| = M` when `|φ| ≠ ∅`, else `∅`. Derived:
   - **Totality:** `⌊φ⌋ ≡ ¬⌈¬φ⌉` — "`φ` matches everything."
   - **Equality:** `φ₁ = φ₂ ≡ ⌊φ₁ ↔ φ₂⌋` — **two-valued** (set is `M` or `∅`), which FOL `↔`
     cannot express; this is what makes `#Equals` in K a real equality.
   - **Membership:** `x ∈ φ ≡ ⌈x ∧ φ⌉`.
   - **Sorts:** a sort `s` is an inhabitant symbol `⟦s⟧`; "`φ` has sort `s`" is `φ → ⟦s⟧` —
     sorts are patterns too, no separate machinery.

5. **μ — matching μ-logic (induction, recursion, reachability).** Add **set variables** `X` and
   the **least-fixpoint binder** `μX. φ`, well-formed when `X` occurs only positively (under an
   even number of `¬`). Positivity ⇒ monotone ⇒ Knaster–Tarski least fixpoint exists. Greatest
   fixpoint derived: `νX. φ ≡ ¬μX. ¬φ[¬X/X]`. Fixpoints define recursive data
   (`μX. nil ∨ (∃Y. cons(Y, X))`), inductive predicates, reachability (`◇φ`), and give
   **induction** as a proof principle. **The Circularity rule is fixpoint reasoning in
   disguise.**

6. **Proof system (recognize, don't hand-apply):** propositional tautologies + Modus Ponens;
   ∃-rules + Generalization; **Frame** (propagate a proof under a symbol context) and
   **Propagation** (push connectives through application: `σ(φ₁ ∨ φ₂) = σ(φ₁) ∨ σ(φ₂)`,
   `σ(⊥) = ⊥`); **Pre-Fixpoint** (`φ[μX.φ / X] → μX.φ`) + **Knaster–Tarski**
   (`φ[ψ/X] → ψ ⊢ μX.φ → ψ`) which together give induction.

7. **What it unifies — as THEORIES, not logic extensions:** FOL(+LFP), modal/temporal logics
   (`LTL`/`CTL` operators as fixpoints), separation logic (`*`, `−*` as symbols over a heap
   model; recursive heap predicates via `μ`), **reachability logic** (`φ ⇒ φ'`, the basis of
   the kit's proofs), λ-calculus/type systems.

8. **Why it matters for K:** K is matching logic made executable. A K configuration is a
   pattern (cells are symbols); a K claim `<k> LHS => RHS …</k> requires P ensures Q` is a
   reachability formula; the prover speaks matching-logic connectives:
   `#And` = `∧`, `#Or` = `∨`, `#Not` = `¬`, `#Exists` = `∃`, `#Equals` = derived two-valued
   `=`, **`#Top` = `⊤` = the prover's success token** (a goal reduced to `#Top` is discharged).

9. **LIMITS + ESCALATION:** the primer covers arithmetic + maps + a loop. Escalate (via
   `sources.md`) for: separation logic with recursive predicates; binders (λ, substitution);
   concurrency/full temporal reasoning; full metatheory. **"When a clean spec is hard to write,
   that difficulty is itself a signal: either the code has a missing precondition/corner case
   (report it — that's a found bug), or the case is genuinely beyond this primer (escalate).
   Don't invent matching-logic features to force it."**

### 3.2 `knowledge/k-framework.md` — writing a K definition and a `kprove` claim

1. **What K is:** a framework for rewrite-based executable semantics. One definition yields:
   - `kompile def.k --backend haskell` — compile (Haskell backend = the symbolic/verification
     backend; LLVM backend = fast concrete interpreter).
   - `krun program` — concrete execution (sanity-check semantics before proving).
   - `kprove spec.k` — proves reachability **claims** via symbolic execution; arithmetic/map
     side conditions discharged by **Z3**. Output **`#Top`** = all claims proved; anything else
     is a residual obligation.

   A rule `LHS => RHS` is both an execution step and a logical statement; a claim `LHS => RHS`
   is a reachability property — that overlap is why one semantics both runs and verifies.

2. **Shape of a definition** — `*-SYNTAX` module (BNF) + same-named main module
   (configuration + rules):

   ```
   module MINI-PYTHON-SYNTAX
     imports INT-SYNTAX
     imports BOOL-SYNTAX
     imports ID-SYNTAX

     syntax IExp ::= Id | Int
                   | "(" IExp ")"      [bracket]              // parsing only, no node
                   > IExp "+" IExp     [seqstrict, left]      // > = lower precedence
                   | Id "(" IExps ")"  [strict(2)]

     syntax KResult ::= Int | Bool | Ints                     // "fully evaluated" sorts
   endmodule
   ```

   Key attributes: **`strict`/`seqstrict`** declare evaluation order (generate the small-step
   machinery; `strict(2)` = evaluate 2nd argument first); **`left`** associativity;
   **`bracket`** = grouping only; **`token`** makes a literal lex as a terminal (not needed when
   program vars are lowercase `Id`s — they never collide with K's uppercase/`?`-prefixed logical
   variables); **`syntax KResult ::= ...`** declares value sorts (what `isKResult` checks — get
   it wrong and evaluation never stops heating or stops too early).

   ```
   module MINI-PYTHON
     imports MINI-PYTHON-SYNTAX
     imports INT     // +Int, -Int, *Int, <=Int, /Int, modInt, ...
     imports BOOL    // andBool, orBool, notBool, ...
     imports MAP     // M[K <- V] update,  K |-> V binding,  .Map empty
     imports LIST    // ListItem(_),  .List empty

     configuration
       <k> $PGM:Stmt </k>        // the computation: a ~>-separated list of work
       <store> .Map  </store>    // program variables   Id |-> Int
       <funcs> .Map  </funcs>    // function table      Id |-> (def ...)
       <stack> .List </stack>    // call stack of saved (continuation, store)

     rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
     rule <k> X:Id => V ... </k>  <store> ... X |-> V ... </store>
   endmodule
   ```

   - The **configuration** is a tuple of named **cells**. `<k>` holds the computation as a
     `~>`-separated list: **`~>` is the cons of the computation list** ("do this, then that"),
     **`.K` is the empty computation**.
   - Rules rewrite with `=>`. **`...` inside a cell = "the rest is unchanged/irrelevant"** —
     `<k> X => V ... </k>` rewrites only the head; `<store> ... X |-> V ... </store>` matches
     anywhere in the map. (This is the frame condition, for free.)
   - **`requires`** adds a Bool side condition for the rule to fire, e.g.
     `rule <k> I1 / I2 => I1 /Int I2 ... </k> requires I2 =/=Int 0`.
   - Builtins to lean on: `+Int`, `<=Int`, **`/Int` (truncates toward zero; `divInt` floors
     toward −∞ — a repeatedly-flagged distinction)**, `modInt`; map update `M[K <- V]`, binding
     `K |-> V`; `LIST` with `ListItem(_)`, `.List`, `size(L)`, read `L[I]`, functional update
     `L[I <- V]`, slice `range(L, dropFront, dropBack)`.

3. **Strictness ⇒ heating/cooling (the small-step engine).** You never hand-write stepping for
   `a + b`; `seqstrict` auto-generates `[heat]`/`[cool]` rules that pull a subexpression to the
   front of `<k>`, evaluate, and plug back:

   ```
   rule <k> HOLE +  E2:IExp => HOLE ~>  [] + E2 ... </k> requires notBool isKResult(HOLE) [heat]
   rule <k> E1:IExp  + HOLE => HOLE ~> E1 +  [] ... </k> requires isKResult(E1)            [heat]
   rule <k> HOLE ~>  [] + E2:IExp => HOLE +  E2 ... </k>                                   [cool]
   rule <k> HOLE ~> E1:IExp +  [] => E1  + HOLE ... </k>                                   [cool]
   ```

   `seqstrict` sequences left-then-right (gates the 2nd heat on the 1st being a `KResult`);
   plain `strict` is order-nondeterministic. You only write the value-level rules
   (`I1:Int + I2:Int => I1 +Int I2`).

   **`while` gotcha:** keep an **unevaluated copy of the guard frozen** inside a helper and
   evaluate a fresh copy at the head of `<k>` — heating rewrites only the head, so the frozen
   copy survives for the next iteration:

   ```
   syntax KItem ::= #whileLoop(BExp, Suite)
   rule <k> while B:BExp : S:Suite => B ~> #whileLoop(B, S) ... </k>
   rule <k> true  ~> #whileLoop(B:BExp, S:Suite) => S ~> while B : S ... </k>
   rule <k> false ~> #whileLoop(_:BExp, _:Suite) => .K ... </k>
   ```

4. **Claims: the spec module.** A spec file `requires` the semantics; a `VERIFICATION` module
   imports the semantics + symbolic helpers (+ holds `[simplification]` lemmas); a spec module
   holds the claims:

   ```
   requires "mini-python.k"

   module MINI-PYTHON-SPEC-SYNTAX
     imports MINI-PYTHON-SYNTAX
   endmodule

   module VERIFICATION
     imports MINI-PYTHON-SPEC-SYNTAX
     imports MINI-PYTHON
     imports MAP-SYMBOLIC             // symbolic reasoning over maps (extensionality etc.)
     imports K-EQUAL                  // #Equals and friends
     // ... simplification lemmas ...
   endmodule

   module MINI-PYTHON-SPEC
     imports VERIFICATION
     // ... claims ...
   endmodule
   ```

   A **claim** has configuration shape with `=>` rewrites and symbolic variables:

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

   Reading: `<k> LHS => RHS ...` asserts the program runs from LHS to RHS (`=> .K` = "and
   terminates"); store rewrites `x |-> (OLD => NEW)` give before/after per variable; untouched
   bindings (`n |-> N`) constrain inputs; **`requires`** = precondition on symbolic inputs;
   **`ensures`** = postcondition constraints after execution, with **`?`-prefixed
   existentials** for "some value exists" (`?C:Int` in the config +
   `ensures (?C ==Int A) orBool (?C ==Int B)`); `<funcs> .Map => ?_:Map` = "ends in some
   unconstrained map". **`[all-path]`** = every execution path reaches RHS (what the examples
   use; in a deterministic language all-path coincides with one-path); **`[one-path]`** = some
   path does.

5. **Circularities.** K's reachability prover treats **every claim in the module as a
   coinduction hypothesis** (a circularity) — a loop claim **discharges its own loop**; other
   claims reuse it as a lemma. Two attributes:
   - **`[trusted]`** — assume a claim as proven (use sparingly; FVK *forbids* using it to fake
     escalation-boundary obligations).
   - **`[simplification]`** — user lemmas applied wherever their LHS matches (they don't
     complete to the top of the configuration). They are the **VC oracle**: sound to add as
     needed, but *you own their soundness* (must preserve definedness).

6. **The Lesson 1.22 pattern** (K Tutorial 1, Lesson 22 — "Basics of Deductive Program
   Verification using K" — verifies this exact sum function; the canonical template):
   - Configuration `<k> / <store> / <funcs> / <stack>` with `state(continuation, store)` frames.
   - Statements: assignment, `if`, `while`, `def`, `return`, call.
   - Two `[all-path]` claims: a loop-invariant claim (proves itself by circularity) + a
     function claim (reuses the loop claim). `kprove` success = `#Top`.
   - **The Bot/Bots shared-`klabel` list trick** (needed so a seqstrict argument list can cool
     to a `KResult`):

     ```
     syntax Bot
     syntax Bots  ::= List{Bot,  ","} [klabel(exps)]
     syntax Ints  ::= List{Int,  ","} [klabel(exps)] | Bots   // evaluated args, a KResult
     syntax Ids   ::= List{Id,   ","} [klabel(exps)] | Bots   // parameters
     syntax IExps ::= List{IExp, ","} [klabel(exps), seqstrict] | Ints | Ids
     ```

     The shared `[klabel(exps)]` makes `Ints` and `Ids` subsorts of the strict `IExps`, so an
     evaluated `IS:Ints` is a legal call argument and `.Bots` is the shared empty terminator.
   - The two `[simplification]` lemmas the up-counting sum needs (down-counting needs none):

     ```
     // map extensionality: closes the post-store implication (result <- V)
     rule { M:Map [ K <- V ] #Equals M:Map [ K <- V' ] } => { V #Equals V' } [simplification]

     // exact halving of an always-even product of consecutive integers
     rule (X:Int *Int (X +Int 1)) /Int 2 *Int 2 => X *Int (X +Int 1) [simplification]
     rule ((A:Int +Int B:Int) *Int C:Int) /Int 2 *Int 2 => (A +Int B) *Int C
       requires ((A +Int B) *Int C) modInt 2 ==Int 0 [simplification]
     ```

7. **Common gotchas** (each bit the original sum build; surfacing them early is part of the
   "spec-difficulty is a bug signal" discipline):
   - **List-sort / `KResult` subsorting** — skip the Bot/Bots trick and the seqstrict arg list
     never cools; the call rule can't fire; `kprove` stalls before the interesting goal.
   - **Statement-sequencing parse ambiguity** — sequencing `Stmt Stmt [left]` must bind
     *looser* than suite-headed statements, and a Suite (`INDENT Stmt DEDENT`) must be
     self-delimiting, or the parser can't tell where a `while`/`def` body ends.
   - **Map extensionality `[simplification]`** — postconditions land as `STORE[result <- V]`;
     without the lemma the ensures/store goal stays open.
   - **Exact-halving `[simplification]`** — `/Int` truncates; Z3 won't equate `(P /Int 2) *Int 2`
     with `P` for a symbolic product without the evenness-guarded lemma.

8. **Lists/arrays & spec-only abstraction functions.** Model a Python list as K's builtin
   `List` (a *value* sort): copy semantics and non-aliasing fall out free (`list(L)` is
   identity; index-assign rebinds to a new List). When a postcondition is **relational**
   (sorted, permutation) rather than a closed form, declare **spec-only abstraction functions**
   `[function]` in `VERIFICATION` and use them in `ensures` — e.g. `isSorted(List)` (inductive
   Bool) and a multiset `bag(List)` (value→count Map, so `bag(X) ==K bag(Y)` *is* "permutation").
   These are **spec vocabulary, not language constructs**. **Caveat:** the bundled
   `[simplification]` tier does NOT discharge inductive-predicate/multiset VCs — state those as
   `[ESCALATION BOUNDARY]`, never `[trusted]`.

9. **LIMITS:** fast path = imperative function over ints/maps/lists, loop-invariant claim +
   function contract, Lesson-1.22 style. Escalate for recursive/heap data structures, binders/
   closures, concurrency/nondeterminism/exceptions/I/O, real per-language semantics. "Do not
   invent K features to force a fit… Worked examples are the growth lever."

### 3.3 `knowledge/reachability-and-circularities.md` — the engine room

1. **A reachability rule generalizes a Hoare triple.**

   ```
       φ  ⇒  φ'
   ```

   read: *every (terminating) execution starting from a state matching `φ` reaches a state
   matching `φ'`.* Each `φ` is a matching-logic pattern — a symbolic configuration (`<k>`,
   `<store>`, …) conjoined (`#And`) with a first-order side constraint (`requires`). It is a
   Hoare triple `{Pre} code {Post}` recast so **the code lives inside the pattern** (in `<k>`).
   The win: **one operational semantics serves both execution and proof** — no separate
   axiomatic semantics to keep in sync (a classic source of soundness bugs); pre/postconditions,
   frame conditions, and program text are all parts of one pattern.

2. **The reachability proof system** — prove `A ⊢ φ ⇒ φ'` (semantics `A` entails the rule):

   | Rule | What it does |
   |---|---|
   | **Reflexivity** | `A ⊢ φ ⇒ φ` (zero steps). This is where guardedness bites: a circularity hypothesis is *forbidden* from closing a goal via Reflexivity alone. |
   | **Axiom** (+framing) | Apply one semantic rule from `A` (with substitution). Framing carries the untouched parts — rest of `<k>`, unmentioned store bindings, the side constraint — i.e. K's automatic `...` cell-completion. |
   | **Transitivity** | Chain `φ ⇒ φ₁` and `φ₁ ⇒ φ'`. |
   | **Consequence** | Strengthen pre / weaken post via a FOL implication discharged by SMT (Z3) or `[simplification]` lemmas. Where arithmetic VCs are dispatched. |
   | **Case Analysis** | Split a disjunctive precondition `φ ≡ φ₁ #Or φ₂` — e.g. loop guard true vs false. |
   | **Abstraction** | Existentially quantify away variables in the pre but not the post (e.g. overwritten initial values `∃S₀,I₀`). |
   | **Circularity** | Use a rule as its own hypothesis — see below. |

   (K realization: `seqstrict` heating ↔ operand micro-steps of Axiom; `#Or` ↔ Case Analysis;
   SMT/`[simplification]` ↔ Consequence; `...` ↔ framing. Heating/cooling rules are themselves
   auto-generated semantic rules applied *via* Axiom.)

3. **The Circularity rule — the key idea:**

   ```
       A ∪ {φ ⇒ φ'}  ⊢  φ ⇒ φ'
       ─────────────────────────
           A  ⊢  φ ⇒ φ'
   ```

   You may **assume the very rule you are proving** — *provided* the hypothesis is only used
   **after at least one genuine `=>⁺` step** (one real semantic transition). This proviso is
   **guardedness** — sound guarded coinduction: every appeal to the hypothesis is "paid for" by
   real progress. Enforced concretely by forbidding the hypothesis from closing a goal via
   Reflexivity alone. *That single side condition is the whole soundness story.*

   **It replaces the loop invariant.** Classically you invent `Inv`, prove established/
   preserved/implies-post. Here: the loop's **own reachability claim is the coinductive
   hypothesis**. Run the loop one step (guard evaluation = the genuine `=>⁺` earning the
   hypothesis), case-split on the guard; the body-taken branch reaches the same loop in a
   shifted state and **invokes the claim on itself** (e.g. at `{S := S+I, I := I+1}`, with the
   precondition re-checked); the exit branch pins the counter (`I = N+1`) and the closed form
   collapses (empty sum `0`). The role the invariant played is now played by the **closed-form
   expression in the claim's postcondition, generalized over accumulator/counter** (e.g. the
   running sum `S + (I+N)·(N−I+1)/2`). K realizes this with zero ceremony: every `claim` in the
   module is automatically a circularity hypothesis.

   **The same principle covers recursion.** A recursive function's back-edge is the recursive
   call, so the **function's own contract is the coinductive hypothesis**: `f(N) ⇒ result(N)`
   discharges its inner call `f(N−1)`. Guardedness is paid by the **`call` step**; the base
   case is the exit branch. (Mutual recursion: two contracts discharge *each other's* calls —
   `08-is-even-odd`. Nested loops: one claim per loop, **inner used as a lemma by the outer** —
   `12-insertion-sort`.)

4. **THE RECIPE** (what `/formalize` + `/verify` actually do):
   1. Get a K semantics of the fragment (mini-X): syntax + configuration cells + rewrite rules.
   2. State the function spec as a reachability rule `φ_pre ⇒ φ_post`: a claim whose `<k>`
      rewrites the program to `.K`, store/output cells assert the post, `requires` is the pre.
   3. For each loop (or recursive function), state the circularity claim, **generalized over
      accumulator and counter**, with the **soundness side condition** bounding the counter.
      The side condition is not cosmetic: without `I ≤ N+1` the sum-loop claim is *false* —
      for `I ≥ N+2` the body never runs (true added sum `0`) but the closed form
      `(I+N)·(N−I+1)/2` goes **negative** (`N=0, I=2` gives `−1`).
   4. Prove by symbolic execution: heating/cooling micro-steps; case-split on the guard (or
      base-vs-recursive branch); after the body step (or `call`), invoke the circularity on the
      shifted state; discharge arithmetic VCs by Consequence (Z3 linear; `[simplification]`
      for the rest).
   5. Compose function-level via Transitivity: `def` → `call` binds params fresh → body init →
      loop via circularity-as-lemma (instantiated at entry, precondition discharged) → `return`
      pops the frame. Result: `A ⊢ φ_pre ⇒ φ_post`.

   **Beyond arithmetic:** postconditions can be **predicates** (sorted/permutation) via
   spec-only `[function]` abstractions; **nested loops nest their circularities**.

5. **Partial vs total correctness.** Circularity gives **partial correctness** (if/when the
   loop terminates, the post holds) — guardedness yields coinductive soundness **without a
   variant**, so termination is simply not established. **Total correctness** needs a
   **decreasing measure** (e.g. `N − i`, bounded below by `0`, strictly decreasing per
   iteration). Kit default: partial; flag total as a recommendation; when asked, add the
   variant to the loop claim and discharge "strictly decreases, bounded below" with the VCs.

6. **Discharging the VCs — two tiers:**
   - **Linear facts → Z3**: `N ≥ 0 ⇒ 1 ≤ N+1`, `I ≤ N ⇒ I+1 ≤ N+1`, zero-factor exits.
   - **Nonlinear / division-by-even → `[simplification]` lemmas**: e.g. **VC-EXACT** (product
     of consecutive integers is even, so `/Int 2` is exact, `(A−B)/2 = A/2 − B/2` on the even
     subgroup), plus map-extensionality to reduce a cell `#Equals` to a scalar one. Worked VCs
     for sum-up: **VC1** (loop step `I + cf(I+1,N) = cf(I,N)`), **VC2** (exit, zero factor),
     **VC3** (init `cf(1,N) = N*(N+1)/2`).

   > **Spec-difficulty is a bug signal** (verbatim discipline): "If you *cannot* find a clean
   > closed form, a clean precondition, or a clean side condition — or the VCs refuse to
   > discharge — do not paper over it. Surface it… A side condition you are *forced* to add
   > (like `I ≤ N+1`, or a function precondition like `N ≥ 0`) is often a precondition the code
   > silently assumed and never checked."

7. **Limits & escalation.** Sweet spot: simple counting loops *and* simple recursion (one
   accumulator/argument, integer/map state, polynomial closed form). Escalate for:
   non-polynomial/multiplicative VCs (factorial's `N!/(I−1)!` — needs a recursively-defined
   symbol + its own lemmas); recursive/inductive data structures and relational postconditions
   (sortedness, permutation — needs inductive predicates + multiset reasoning, often `μ`);
   binders; concurrency/nondeterminism (where `[all-path]` vs one-path genuinely diverge).

   **Escalation done right (the pattern to copy):** "Escalating is **not** giving up." Build the
   semantics, state **all** claims well-formed, define the spec-only abstractions, discharge
   every VC the bundled tier *can*, and mark the rest as explicit **`[ESCALATION BOUNDARY]`**
   obligations — **never fake them as `[trusted]`**. "The open obligations are **specified**,
   not hidden." Then route by topic to the papers.

### 3.4 `knowledge/sources.md` — escalation routing

Papers at `https://fsl.cs.illinois.edu/publications/<slug>.pdf`:

| Slug | Title | Underpins |
|---|---|---|
| `rosu-2017-lmcs` | Matching Logic (LMCS 2017) | foundational: patterns-as-sets, definedness ladder, proof system |
| `chen-rosu-2019-lics` | Matching μ-Logic (LICS 2019) | set variables + `μ` → induction, recursion, reachability |
| `chen-lucanu-rosu-2020-tr` | Initial Algebra Semantics in ML (TR) | inductive-sort semantics |
| `rosu-stefanescu-2012-fm` | From Hoare Logic to Matching Logic Reachability (FM 2012) | `φ ⇒ φ'` generalizing Hoare; one semantics for execution + proof |
| `rosu-stefanescu-ciobaca-moore-2013-lics` | One-Path Reachability Logic (LICS 2013) | the **Circularity** rule + full proof system |
| `chen-pena-rodrigues-rosu-trinh-2020-oopsla` | Unified fixpoint reasoning (OOPSLA 2020) | inductive/recursive data structures (heap predicates, lists, trees) |
| `chen-rosu-2020-icfp` | A General Approach to Define Binders (ICFP 2020) | binders, scoping, α-equivalence |

Plus: `matching-logic.org` (TLS cert altname broken — `curl -sk`, WebFetch fails);
`github.com/runtimeverification/k` (`docs/user_manual.md`; Lesson 1.22 at
`k-distribution/k-tutorial/1_basic/22_proofs`); `kframework.org`; full per-language semantics
(KEVM, C semantics, …) under the `runtimeverification` org.

**WHEN TO ESCALATE table** (routes by topic): recursive heap predicates → OOPSLA'20; binders →
ICFP'20; induction/`μ` → LICS'19; reachability/Circularity mechanics → FM'12 + LICS'13;
definedness/equality/sorts → LMCS'17; deep K syntax → user manual; a worked end-to-end claim →
Lesson 1.22; concurrency/other → matching-logic.org footnotes.

**`--refresh`**: `/formalize --refresh` / `/verify --refresh` re-fetch those URLs into the
current run's context. Opt-in; default is the offline fast path.

---

## 4. The worked-example library (templates + claim-shape catalog)

Examples are **numbered by increasing complexity** and chosen for **shape diversity** ("a second
counting loop teaches an agent nothing new; a first *recursive* or *array* example teaches a
whole new pattern"). The agent picks the **closest example by shape**. Status legend:
**machine-checked** (`kprove` → `#Top`; none currently), **constructed** (written + reviewed,
not machine-checked — the MVP default), **constructed (escalation-bounded)** (additionally some
VCs need a theory beyond the bundled tier, stated as `[ESCALATION BOUNDARY]`).

| # | Example | Shape / technique taught | Status |
|---|---|---|---|
| 01 | average | running-sum loop invariant over a list; bug showcase (`average([])` → ZeroDivisionError); spec-only range fold `listsum` | constructed (esc: only `listsum` totality) |
| 02 | sum-up | count-up loop; additive polynomial invariant + circularity (`I ≤ N+1`); the `n < 0` missing-precondition finding | constructed |
| 03 | sum-down | count-down loop; "remaining-work" invariant `T + I*(I+1)/2`, side condition `I >= 0`; `n` framed out of (LOOP) by `...` | constructed |
| 04 | fibonacci | **coupled two-variable invariant** `prev |-> (fib(I) => fib(N))`, `curr |-> (fib(I+1) => fib(N+1))`; spec-only recursive `fib` symbol with `[simplification]` defining rules | constructed (esc: `fib` totality) |
| 05 | gcd | invariant is a **preserved relation** (`a |-> (A => gcd(A,B))`), not an accumulator; clean termination variant `b`; Euclid identity `gcd(a,b)=gcd(b,a mod b)` escalates (number theory) | constructed (esc) |
| 06 | sum-recursive | **recursion circularity** `(REC)`: `sum_recursive(N) ~> CONT => N*(N+1)/2 ~> CONT`; guards (`isinstance`, `raise`) become *positive* findings | constructed |
| 07 | factorial | recursion + **non-polynomial** result via spec-only `fact(Int)` symbol; VCs discharge by definitional unfolding (no halving lemma) | constructed (esc: `fact` totality) |
| 08 | is-even-odd | **mutual recursion**: `(EVEN)`/`(ODD)` contracts discharge *each other's* call; post = `N modInt 2 ==Int 0/1`; headline finding: `n<0` **does not terminate** | constructed (no escalation) |
| 09 | array-max | arrays with **∀-quantified postcondition** via inductive `isUpperBound(List,Int)` + `inList`; `ensures isUpperBound(A,?M) andBool inList(?M,A)`; running-max invariant `R ==Int maxPrefix(A,I)` | constructed (no escalation) |
| 10 | binary-search | **sortedness precondition** (`requires isSorted(A)`); narrowing-window invariant; found-half clean / not-present-half escalates (VC-M1/M2); the famous `mid=(lo+hi)//2` overflow finding | constructed (esc: membership half) |
| 11 | reverse | index-relation postcondition (clean) + permutation (escalates); in-place mutation finding | constructed (esc: permutation) |
| 12 | insertion-sort | **nested loops + relational spec**: three nested circularities `(SORT)`/`(OUTER)`/`(INNER)`; spec-only `isSorted`, `allGt`, `take`/`seg`, multiset `bag`; canonical honest escalation | constructed (esc) |
| 13 | tree-height | **recursive data structure**: first-class K value sort `syntax Tree ::= "none" | node(Int, Tree, Tree)`; verified helper `(MAX2)` + branching `(REC)`; structural induction escalates | constructed (esc) |

**The `sum-*` cluster teaching payload:** 02, 03, 06 all compute the same contract
(`n·(n+1)/2`) by count-up / count-down / recursion — **the proof obligations differ even when
the spec does not** (different invariant shapes; recursion uses the call contract instead).

**"Programs are self-contained" policy:** no imports, no high-level builtins (`sum`, `max`,
`sorted`, slicing, `.append`, `list()`) — only operators, indexing, `len`, `while`/`if`,
assignment, own helpers. Rationale: a builtin is an unspecified black box (or forces a spec-only
fold that escalates); written-out helpers mean **every function gets its own reachability rule**
— more verified surface, more places to catch a bug — and the mini-X stays minimal.

**Production discipline (anti-overfitting):** examples are produced by an **isolated newcomer**
agent that wrote the program in a separate project *before* seeing the kit, then learned the kit
and ran the commands. Each cold run is a usability test of the kit ("where the fresh agent
stalls … that is a bug in the kit"). Promotion standardizes only the **skeleton** (file layout,
catalog row, status label), never the producer's voice/findings ("uniform skeleton, authentic
content"). Vary the producing model when possible.

### 4.1 Reference claim shapes (verbatim, for skill authoring)

**(SUM) function contract** (02-sum-up) — define + call on symbolic arg; pre in `requires`;
post in rewritten cells:

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

**(LOOP) circularity** (02-sum-up) — generalized over `S`, `I`; soundness side condition:
see §3.2(4) above. Down-counting variant (03) uses `total |-> (T:Int => T +Int I *Int (I +Int 1) /Int 2)`,
`i |-> (I:Int => 0)`, `requires I >=Int 0`, and a `...` store frame (no `n`).

**(REC) recursion circularity** (06) — call-with-continuation shape; store/stack net-unchanged:

```
claim
  <k> sum_recursive ( N:Int ) ~> CONT:K
   => N *Int (N +Int 1) /Int 2 ~> CONT </k>
  <funcs> ... sum_recursive |-> def sum_recursive ( n ) : INDENT ... DEDENT ... </funcs>
  <store> STORE </store>
  <stack> STK:List </stack>
  requires N >=Int 0
  [all-path]
```

**Mutual recursion** (08): two such claims, `(EVEN)` reducing to `( N modInt 2 ==Int 0 ) ~> CONT`
and `(ODD)` to `( N modInt 2 ==Int 1 ) ~> CONT`, each `<funcs>` listing **both** defs; each is
the coinduction hypothesis for the *other's* inner call.

**Preserved-relation invariant** (05-gcd): the spec-only math symbol *is* the invariant —

```
syntax Int ::= gcd(Int, Int) [function, total, smtlib(gcd)]
rule gcd(A:Int, 0) => A  [simplification]            // base: bundled-dischargeable
// (EUCLID) gcd(a,b) = gcd(b, a mod b) for b =/= 0   // stated, NOT [simplification],
//                                                   // NOT [trusted]: [ESCALATION BOUNDARY]
claim
  <k> while b : INDENT a , b = b , a % b DEDENT => .K ... </k>
  <store> a |-> (A:Int => gcd(A, B))  b |-> (B:Int => 0) </store>
  requires A >=Int 0 andBool B >=Int 0
  [all-path]
```

**Coupled accumulators** (04-fib): `prev |-> (fib(I) => fib(N))`,
`curr |-> (fib(I +Int 1) => fib(N +Int 1))`, `requires 0 <=Int I andBool I <=Int N`, with
`syntax Int ::= fib(Int) [function, total, smtlib(fib)]` and three `[simplification]` defining
rules (`fib(0)=>0`, `fib(1)=>1`, `fib(N)=>fib(N-1)+fib(N-2) requires N>Int 1`).

**∀-quantified post via inductive spec functions** (09-array-max):

```
syntax Bool ::= isUpperBound(List, Int) [function, total]
rule isUpperBound(.List, _)                  => true
rule isUpperBound(ListItem(X:Int) L, B:Int)  => X <=Int B andBool isUpperBound(L, B)

syntax Bool ::= inList(Int, List) [function, total]
rule inList(_, .List)                  => false
rule inList(X:Int, ListItem(Y:Int) L)  => X ==Int Y orBool inList(X, L)
...
claim ... requires size(A) >=Int 1
      ensures  isUpperBound(A, ?M) andBool inList(?M, A)  [all-path]
```

**Relational spec + multiset + nested circularities** (12-insertion-sort):

```
syntax Bool ::= isSorted(List) [function, total]
rule isSorted(.List)                          => true
rule isSorted(ListItem(_))                    => true
rule isSorted(ListItem(X:Int) ListItem(Y:Int) L)
     => X <=Int Y andBool isSorted(ListItem(Y) L)

syntax Map ::= bag(List)        [function, total]    // bag(X) ==K bag(Y) <=> permutation
             | incr(Map, Int)   [function, total]
rule bag(.List)                 => .Map
rule bag(ListItem(X:Int) L)     => incr(bag(L), X)
rule incr(M:Map, X:Int) => M [ X <- (({M[X]}:>Int) +Int 1) ] requires X in_keys(M)
rule incr(M:Map, X:Int) => M [ X <- 1 ]                      requires notBool X in_keys(M)
```

with `(SORT)` `ensures size(?R) ==Int size(A) andBool isSorted(?R) andBool bag(?R) ==K bag(A)`,
`(OUTER)` invariant "prefix `[0,I)` sorted", `(INNER)` the "insert key into a hole" invariant
(`isSorted(take(C, J+1))`, `allGt(seg(C, J+2, I+1), KEY)`, hole-fill bag link). The multiset/
sorted-composition lemmas (L1, L2) are written **as comments** marked `[ESCALATION BOUNDARY]` —
deliberately *not* `rule … [simplification]` and *not* `[trusted]`.

**Recursive data structure** (13-tree-height): model the Python `None`-or-tuple tree as a
first-class K value sort `syntax Tree ::= "none" | "node" "(" Int "," Tree "," Tree ")"`;
spec-only partial selectors `left(node(_,L,_)) => L`, height measure
`h(none) => 0`, `h(node(_,L,R)) => 1 +Int max2Int(h(L), h(R))`; the structural-induction
principle `(T-IND)` is the stated escalation boundary.

### 4.2 PROOF.md anatomy (the `/verify` write-up template, from 02-sum-up)

1. **§1 The reachability spec** — the function claim, shown both in math form
   (`φ_pre ≡ ⟨…⟩_k ⟨…⟩_store … ∧ N ≥ 0`; `φ_post ≡ ⟨.K⟩_k …`) and as the K claim.
2. **§2 The loop circularity** — compact form
   `⟨while…| s↦S, i↦I, n↦N⟩ ∧ I ≤ N+1 ⇒ ⟨.K | s ↦ S+(I+N)·(N−I+1)/2, i ↦ N+1, n ↦ N⟩` + K claim.
3. **§3 Informal proof (English)** — guarded-coinduction narrative: one genuine step earns the
   hypothesis; guard-true branch invokes the claim at the shifted state; guard-false branch
   collapses; then the function proof composes def→call→init→loop-as-lemma→return. Ends ∎.
4. **§4 Machine-detailed proof sketch** — every step cites a named rule of the semantics
   (`(while)`, `(lookup)`, `(leq)`, `(augasgn)`, `(call)`, `(return)`…), guardedness called out,
   and a **VC table**: VC | statement | discharged-by (Z3 vs which `[simplification]`).
5. **§5 FINDINGS** — the headline bug with `input → observed vs expected` table.
6. **§6 TEST REDUNDANCY** — per-test subsumption reasons; out-of-domain tests kept;
   "Conditioned on machine-checking" caveat.
7. **Reproduce the machine check** — the three commands; "`#Top` upgrades constructed →
   machine-verified, and only then are the §6 test deletions safe."
8. Citations footer (kframework.org, Lesson 1.22, LMCS 2017, LICS 2019, FM 2012/LICS 2013).

### 4.3 PROMPTS.md (reproducibility recipe — relevant to our UX design)

The actual session shape that produced each example (02-sum-up's P1–P7): write program → learn
kit → **P3: "discuss the approach first — walk through the planned invariant and side condition
before generating artifacts"** → run /formalize → **P5: "If I tell you /verify, what exactly are
you going to verify — given you have already found bugs?"** → run /verify → package. The notes
call P3/P5 "the two highest-value turns": P5 surfaces that **verification certifies conformance
to a contract, not the absence of bugs** (the precondition *quarantines* the `n ≤ −2` bug rather
than fixing it; options: A verify-as-written / B verify as-built over all ℤ / C fix-then-verify).
Also: treat every generated semantics/proof as something to **review, not trust** — append
"be exhaustive and adversarially verify this."

---

## 5. Artifacts: what FVK produces, formats, naming, placement

All artifacts are written **alongside the code** ("do not bury them elsewhere"):

| Artifact | Produced by | Content / format |
|---|---|---|
| `<mod>.k` (e.g. `mini-python.k`) | `/formalize` | mini-X fragment K semantics: `*-SYNTAX` module + main module (configuration + rules), heavily commented, modeling decisions documented in a header banner (e.g. the INDENT/DEDENT note, `+=` desugaring caveat) |
| `<mod>-spec.k` (e.g. `mini-python-spec.k`) | `/formalize` | `requires "<mod>.k"`; `*-SPEC-SYNTAX`, `VERIFICATION` (spec-only `[function]` abstractions + `[simplification]` lemmas + commented `[ESCALATION BOUNDARY]` obligations), `*-SPEC` (named claims `(SUM)`, `(LOOP)`, `(REC)`, …); header banner includes the kompile/kast/kprove commands and an honesty/scope banner where applicable |
| `SPEC.md` | `/formalize` | plain-English spec note: per function/loop — precondition, postcondition, side conditions, how the proof will compose, which arithmetic lemmas will be needed, mini-X scope, status label |
| `FINDINGS.md` | `/formalize`, extended by `/verify` | plain-language findings, each `input → observed vs expected` (often as a table), classified, with recommendations; "non-blocking … never edits or deletes your code"; `/verify` appends a "Proof-derived findings" section |
| `PROOF.md` | `/verify` | the constructed proof (anatomy in §4.2), test-redundancy recommendation, run-commands, all labeled "constructed, not machine-checked" |
| `README.md` (per example) | packaging | 1-paragraph summary + file table + status |
| `PROMPTS.md` (per example) | packaging | exact reproduction prompts |

Status labels are part of the format: **machine-checked / constructed / constructed
(escalation-bounded)**, plus per-obligation `[ESCALATION BOUNDARY]` markers inside `.k` files.

---

## 6. Why the findings are good (the quality mechanics)

The method systematically produces findings conventional review misses, through identifiable
mechanisms:

1. **Universal quantification forces total case coverage.** A contract must hold for *every*
   input in the domain; stating it flushes out the inputs where it can't. The signature finding
   pattern is a **forced precondition**: sum's `requires N >=Int 0` exposes that `sum_to_n(-3)`
   returns `0` while the intended closed form gives `3` — including the subtlety that the code
   is *coincidentally* correct at `n = 0` and `n = -1` but genuinely wrong for `n <= -2`.
2. **Loop side conditions are load-bearing and point at the same bugs from a second
   direction.** `(LOOP)`'s `I ≤ N+1` is provably necessary (the closed form goes negative
   outside it); "that gap `I ∈ {N+2, …}` is precisely where Finding 1's bug lives — the loop
   spec and the function spec point at the same missing precondition from two directions."
3. **Spec-difficulty = bug signal** — institutionalized: if no clean precondition/invariant/
   closed form exists, *that is itself a reportable finding*, with what looks suspicious named.
4. **Stuck semantics = runtime exceptions.** A rule guard like `requires I2 =/=Int 0` that
   cannot fire = a stuck configuration = the runtime crash (average's `ZeroDivisionError` on
   `[]` is "the formal mirror" of the division rule's side condition). The formal model and the
   bug coincide.
5. **Exhaustive case analysis from the rewrite rules.** Every guard induces an `#Or` split that
   must be closed on *both* branches — nothing falls through. Binary search's postcondition
   splits into found-half (clean) and not-present-half (needs quantified membership — and the
   method *says which half it can't close and why*).
6. **Modeling choices become explicit, reportable assumptions.** Modeling elements as `Int`
   surfaces the unstated "elements must be totally ordered" precondition (NaN poisons the
   order; mixed types raise). Modeling `/` as `/Int` surfaces Python true-division vs
   integer-division intent — cross-checked against the test suite (`average([1,2]) == 1.5` pins
   the float intent). The famous `mid = (lo+hi)//2` overflow: "verifying the index `mid` stays
   in range forces the assumption '`lo + hi` does not wrap'" — free in Python, a real silent
   precondition in C/Java (Bloch 2006).
7. **Intent-vs-implementation diffing, not as-built rubber-stamping.** Intent-spec mode means
   divergence is the finding; the docstring "sorted list a" with nothing enforcing sortedness
   becomes an executed false-negative demonstration (`binary_search([2,5,1,9,3], 2)` → `-1`
   though `2` is at index 0).
8. **Intent-relevant subtleties surface from the proof text.** Insertion sort's **stability
   hinges on the strict `>`** in the inner guard — "had the guard been `>=`, still a sorted
   permutation but no longer stable. This `>` vs `>=` choice is load-bearing for stability and
   invisible to a quick read." Duplicates in binary search: the contract's existential
   `a[?r] == x` makes "returns *some* matching index, not the leftmost" explicit.
9. **Termination treated separately and sharply.** Partial-vs-total is always stated; even-odd's
   headline: for `n < 0` the mutual recursion **never terminates** (`requires N >= 0` is what
   makes the recursion well-founded *at all* — sharper than a closed-form bound). Recursion
   examples *measure* the real-world boundary: CPython default limit ⇒ smallest failing input
   `n = 998` ("the implementation provably fails to return for `n >= 998`").
10. **Positive findings and deliberate non-findings.** Guards that enforce the spec's
    precondition are reported as the code doing the right thing (sum-recursive's
    `if n < 0: raise ValueError`; its `isinstance(n, bool)` exclusion — `bool` subclasses `int`,
    so `True` would silently sum as `1`). Non-issues are stated *because a reviewer will ask*
    (Python bigints ⇒ no overflow; empty-list handled ✓ with executed evidence). This calibrates
    trust in the report.
11. **Honesty boundaries are findings infrastructure.** Capability gaps (`[ESCALATION
    BOUNDARY]`) are explicitly distinguished from code bugs, never faked as `[trusted]`; "the
    open obligations are specified, not hidden."
12. **Empirical grounding.** Later FINDINGS execute the claimed counterexamples against the
    real code and say so ("executed, not merely conjectured"), with transcript-style tables.
13. **Every finding is actionable**: classification + recommendation + which tests to add/keep,
    plus (from `/verify`) the next **clarifying question for the user** — e.g. "Should negative
    `n` raise, return `0`, or be outside the domain?"; "For duplicates, do you want any match or
    the leftmost match?"

**Finding taxonomy used across the corpus:** missing precondition (silent wrong value) ·
unenforced documented precondition (sortedness) · undefined behavior / crash (stuck config) ·
non-termination on bad input · resource boundary (recursion depth, measured) · intent-relevant
implementation choice (stability, duplicate policy, int-vs-float, in-place mutation/aliasing) ·
cross-language portability hazard (overflow) · spec-difficulty signal · positive finding
(guard enforces spec) · deliberate non-finding (stated and checked) · escalation boundary
(capability, not code).

---

## 7. License & attribution

- **MIT License, Copyright (c) 2026 Grigore Rosu** (`LICENSE`). We may use, copy, modify,
  merge, publish, and redistribute, including in derivative skills, **provided the copyright
  notice and permission notice are included in all copies or substantial portions**.
- Practical obligation for ultimatepowers: where we substantially port FVK text/knowledge into
  skill reference docs, include an attribution note (e.g. "Derived from
  grosu/formal-verification-kit, MIT License, Copyright (c) 2026 Grigore Rosu") and carry the
  MIT notice in the plugin's third-party-licenses file. Re-deriving the *method* in our own
  words needs no license mechanics, but attribution is good practice and cheap.
- The knowledge content itself distills published academic work (Roșu et al. — LMCS 2017,
  LICS 2013/2019, FM 2012, OOPSLA 2020, ICFP 2020, K tutorial Lesson 1.22); cite those papers
  in our reference docs as FVK does.

---

## 8. Integration assessment for ultimatepowers

### 8.1 (a) Core transferable knowledge — carry into skill reference docs

Worth porting nearly wholesale (rewritten/condensed, with attribution):

1. **The reasoning core** (§3.3): reachability rules generalize Hoare triples; the 7-rule proof
   system; the **Circularity rule + guardedness**; circularity-instead-of-invariant for loops,
   recursion, mutual recursion, nested loops; partial-vs-total + decreasing measures; the
   two-tier VC discharge model. This is the engine; it's also the most LLM-native part (it's
   exactly "rigorous symbolic execution with disciplined self-reference").
2. **The claim-writing conventions** (§3.2 + §4.1): configuration cells; `x |-> (OLD => NEW)`
   store rewrites; `requires`/`ensures`; `?`-existentials; `[all-path]`; uppercase-logical vs
   lowercase-program variables; generalize-over-accumulator; **soundness side conditions**;
   spec-only `[function]` abstractions (`isSorted`, `bag`, `inList`, folds, measures);
   `[simplification]`-as-lemma; map-extensionality + exact-halving as canonical lemma examples;
   the `/Int`-truncates-vs-`divInt`-floors trap.
3. **The findings discipline** (§6): `input → observed vs expected`; the finding taxonomy;
   **spec-difficulty = bug signal**; positive findings + deliberate non-findings; executed
   counterexamples; intent-spec mode vs as-built mode; classification + recommendation +
   next-question per finding.
4. **The honesty machinery**: "constructed, not machine-checked" labeling; `[ESCALATION
   BOUNDARY]` vs `[trusted]` (never fake); correctness-gap vs capability-gap distinction;
   recommendation-only test guidance; the explicit trusted base in reports.
5. **A condensed claim-shape catalog** distilled from the 13 examples (the table + verbatim
   shapes in §4.1) — this is the "pick the closest example by shape" mechanism and the single
   highest-leverage teaching asset.
6. Optionally, a slim **matching-logic background** (§3.1) — useful for *why* the notation is
   sound, but the workflow runs fine on §3.2+§3.3 alone; keep it as deep-reference, not
   required reading.

### 8.2 (b) Workflow worth re-implementing superpowers-style

- The **two-phase pipeline** (`/formalize` then `/verify`) maps cleanly onto a code-review
  flow: phase 1 = derive intent + contracts + findings; phase 2 = adversarial proof
  construction + proof-derived findings. For ultimatepowers' review phase, both can run inside
  one review skill (or one skill + one subagent pass), keyed to **changed functions/loops in
  the diff** rather than whole-project (FVK is whole-project-only today; we add diff targeting).
- **Bootstrap-then-act**: superpowers skills already encode "read the reference docs first";
  FVK's BOOTSTRAP step becomes the skill's required-reading frontmatter/reference links.
- **Findings report as the user-facing deliverable**, formal artifacts as appendix. For code
  review, FINDINGS.md content style is the review comment format; SPEC/PROOF condense into a
  per-function "contract + proof sketch + residual risk" block.
- **The honesty gate** must transfer verbatim in spirit: never claim machine-checked
  confidence; never auto-delete tests; distinguish capability gaps from code bugs.
- The **proof-derived findings classification** (evidence / classification / question-for-user /
  recommended change / tests) is a ready-made schema for review findings.
- **PROMPTS.md's P3/P5 detours** ("discuss the invariant before writing artifacts"; "what
  exactly will you verify?") are worth building in as explicit checkpoints — they are the
  kit's own assessment of its highest-value turns.
- The **test-redundancy report** is optional for review (it's a CI-optimization feature);
  consider keeping it as an opt-in extra rather than core review output.

### 8.3 (c) Scaffolding to drop

- **`AGENTS.md` trigger conventions** ("say run /formalize") — replaced by native skill
  invocation/frontmatter.
- **`--refresh` live-fetching + the matching-logic.org curl quirk** — replace with our own
  curated escalation references; keep the *routing-by-topic table* concept.
- **The fine-tuned-model vision, README marketing, design docs** (`docs/superpowers/`) —
  context only.
- **Full `.k`-file generation as a mandatory artifact.** For review purposes the mini-X
  semantics + claims can live as fenced blocks inside the review report; writing
  `mini-python.k` files into the user's repo is the formalize-product workflow, not review.
  Keep the *capability* (emit real runnable K + kprove commands) as an opt-in "deep formal
  mode", since that is FVK's escape hatch to genuine machine-checking.
- **Whole-project no-args scoping** — replaced by diff-driven function/loop selection.
- The K toolchain itself: nothing to drop because **nothing ever depended on it** — confirm: no
  scripts, no binaries, no CI in the repo; pure markdown + `.k` text files.

### 8.4 Recommended skill shape (proposal)

Four skills + one shared reference dir mirrors both FVK's own decomposition and superpowers
granularity:

1. **`formal-reasoning-foundations`** (reference-heavy skill or pure reference doc): digest of
   §3.1–§3.3 — patterns/connectives (brief), K claim notation, reachability proof system,
   Circularity + guardedness, partial-vs-total, VC tiers, gotchas. The bootstrap read.
2. **`formalizing-code`** (≈ `/formalize`): intent gathering → per-function contracts +
   per-loop/recursion circularities (in K notation, fenced) → findings taxonomy + report
   format; spec-difficulty discipline; guard handling; spec-only abstraction functions;
   claim-shape catalog as the imitation library.
3. **`verifying-specs`** (≈ `/verify`): symbolic-execution proof construction recipe;
   circularity discharge; VC discharge + when to write `[simplification]` lemmas; escalation
   boundaries; proof-derived findings schema; honesty gate; (opt-in) test-redundancy and
   kompile/kprove emission.
4. **`formal-code-review`** (the ultimatepowers integration): orchestrates 2+3 over a diff —
   select changed functions/loops, run intent-spec formalization, construct proofs, and emit a
   reviewer-facing findings report (FINDINGS.md style) with classifications, executed
   counterexamples where possible, and questions-for-the-author. This is the skill the review
   phase auto-invokes.

Carry a **condensed examples/shape catalog** (one file: the §4 table + ~8 verbatim claim
shapes) as shared reference; link the full FVK submodule for deep dives. Include MIT
attribution in every derived reference doc.

### 8.5 Risks / gaps to design around

- **Token cost**: full-fidelity mini-X semantics per review is heavy. Mitigation: for review
  mode, allow "claims + invariants + findings without a full `.k` semantics" (semantics
  sketched only where the proof needs a rule), reserving full artifacts for deep mode.
- **FVK is Python-only in examples**; the method is language-agnostic ("mini-X") but our skills
  should say explicitly how to handle TS/Go/etc. fragments (the kit's design already names
  mini-TS).
- **No machine check means constructed proofs can be wrong.** FVK's own mitigation (adopt it):
  adversarial self-verification prompts, treat proofs as review targets, never overstate, and
  the findings (not the proof) are the primary deliverable.
- **Floats/rationals, exceptions, concurrency, heap aliasing are all escalation cases** — the
  review skill must recognize and *say* when a diff falls outside the fast path (per the
  escalation-done-right pattern) instead of producing confident nonsense.
