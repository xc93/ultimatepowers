# Claim-Shape Catalog

Before writing any claim, **imitate the closest shape** below — closest by shape (invariant / VC pattern), not by topic. The reference pair is the count-up / count-down loop (shapes 02/03): the same contract proved with two genuinely different invariant shapes. Shapes are numbered by increasing complexity. Deep source for every shape: `examples/<nn>-<name>/mini-python-spec.k` in grosu/formal-verification-kit.

## Catalog

| # | Example | Shape / technique taught | Status |
|---|---|---|---|
| 01 | average | running-sum loop invariant over a list; bug showcase (`average([])` → ZeroDivisionError); spec-only range fold `listsum` | constructed (esc: only `listsum` totality) |
| 02 | sum-up | count-up loop; additive polynomial invariant + circularity (`I <= N+1`); the `n < 0` missing-precondition finding | constructed |
| 03 | sum-down | count-down loop; "remaining-work" invariant `T + I*(I+1)/2`, side condition `I >= 0`; `n` framed out of the loop claim by `...` | constructed |
| 04 | fibonacci | coupled two-variable invariant — `prev`/`curr` track consecutive `fib` values; spec-only recursive `fib` symbol with `[simplification]` defining rules | constructed (esc: `fib` totality) |
| 05 | gcd | invariant is a preserved relation (`gcd(a,b)` constant across iterations), not an accumulator; clean termination variant `b`; the Euclid identity escalates (number theory) | constructed (esc) |
| 06 | sum-recursive | recursion circularity `(REC)` on the recursive call's contract; guards (`isinstance`, `raise`) become *positive* findings | constructed |
| 07 | factorial | recursion + non-polynomial result via spec-only `fact(Int)` symbol; VCs discharge by definitional unfolding (no halving lemma) | constructed (esc: `fact` totality) |
| 08 | is-even-odd | mutual recursion: `(EVEN)`/`(ODD)` contracts discharge *each other's* call; post = `N modInt 2 ==Int 0/1`; headline finding: `n < 0` does not terminate | constructed (no escalation) |
| 09 | array-max | arrays with ∀-quantified postcondition via inductive `isUpperBound(List,Int)` + `inList`; running-max invariant `R ==Int maxPrefix(A,I)` | constructed (no escalation) |
| 10 | binary-search | sortedness precondition (`requires isSorted(A)`); narrowing-window invariant; found-half clean / not-present-half escalates; the famous `mid = (lo+hi)//2` overflow finding | constructed (esc: membership half) |
| 11 | reverse | index-relation postcondition (clean) + permutation (escalates); in-place mutation finding | constructed (esc: permutation) |
| 12 | insertion-sort | nested loops + relational spec: three nested circularities `(SORT)`/`(OUTER)`/`(INNER)`; spec-only `isSorted`, `allGt`, `take`/`seg`, multiset `bag`; canonical honest escalation | constructed (esc) |
| 13 | tree-height | recursive data structure: first-class K value sort `Tree`; verified helper `(MAX2)` + branching `(REC)`; structural induction escalates | constructed (esc) |

Status legend (the frozen vocabulary): **machine-checked** — `kprove` returned `#Top` (none currently); **constructed** — written and reviewed, not machine-checked (the default); **constructed (escalation-bounded)** — abbreviated `esc:` above; some VCs additionally need a theory beyond the bundled tier and are stated as explicit `[ESCALATION BOUNDARY]` obligations, never faked `[trusted]`.

## Function contract — (SUM), 02-sum-up

Use for any function with a closed-form result: define the function and call it on a symbolic argument inside `<k>`; the precondition goes in `requires`; the postcondition is the rewritten cells.

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

## Loop circularity — (LOOP), 02-sum-up / 03-sum-down

Use for every loop: a second claim for the loop alone, **generalized over accumulator and counter** (never pinned to entry values), the closed form in the postcondition, and the soundness side condition bounding the counter. Count-up (the running example of the skill):

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

Count-down variant — a genuinely different "remaining-work" invariant. The guard compares to the constant `1`, so `n` does not occur in the claim at all: it is framed out by `...` in `<store>`.

```
claim
  <k>
    while i >= 1 : INDENT total += i  i -= 1 DEDENT => .K ...
  </k>
  <store>
    total |-> (T:Int => T +Int I *Int (I +Int 1) /Int 2)
    i     |-> (I:Int => 0)
    ...
  </store>
  requires I >=Int 0
  [all-path]
```

## Recursion circularity — (REC), 06-sum-recursive

Use for a recursive function (no loop, so no loop-invariant claim): the circularity is the **recursive call's contract**, in call-with-continuation shape — the call at the head of `<k>` rewrites to its value, threading `CONT` through unchanged; `<store>`/`<stack>` net unchanged. The claim discharges its own inner call `sum_recursive(N-1)`; guardedness is paid by the `call` step.

```
claim
  <k> sum_recursive ( N:Int ) ~> CONT:K
   => N *Int (N +Int 1) /Int 2 ~> CONT </k>
  <funcs>
    ... sum_recursive |-> def sum_recursive ( n ) : INDENT
          if n == 0 : INDENT return 0 DEDENT
          return n + sum_recursive ( n - 1 )
        DEDENT ...
  </funcs>
  <store> STORE </store>
  <stack> STK:List </stack>
  requires N >=Int 0
  [all-path]
```

## Mutual recursion — (EVEN)/(ODD), 08-is-even-odd

Use when functions recurse through each other: one contract claim per function, each `<funcs>` listing **both** definitions (they are mutually dependent), and each claim is the coinduction hypothesis discharging the *other's* inner call. `(EVEN)` reduces to `( N modInt 2 ==Int 0 ) ~> CONT`:

```
claim
  <k> is_even ( N:Int ) ~> CONT:K
   => ( N modInt 2 ==Int 0 ) ~> CONT </k>
  <funcs>
    ... is_even |-> def is_even ( n ) : INDENT
          if n == 0 : INDENT return true DEDENT
          return is_odd ( n - 1 )
        DEDENT
        is_odd |-> def is_odd ( n ) : INDENT
          if n == 0 : INDENT return false DEDENT
          return is_even ( n - 1 )
        DEDENT ...
  </funcs>
  <store> STORE </store>
  <stack> STK:List </stack>
  requires N >=Int 0
  [all-path]
```

`(ODD)` is symmetric, reducing to `( N modInt 2 ==Int 1 ) ~> CONT` over the same two-function `<funcs>`.

## Preserved-relation invariant — 05-gcd

Use when the loop carries no accumulator and the invariant is a **relation preserved** across iterations: the spec-only math symbol *is* the invariant. Each iteration rewrites `(a, b)` to `(b, a % b)` and `gcd` is constant across that step. The base rule is bundled-dischargeable; the Euclid identity is inductive number theory — stated as a comment marked `[ESCALATION BOUNDARY]`, NOT `[simplification]`, NOT `[trusted]`.

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

## Coupled accumulators — 04-fibonacci

Use when two (or more) variables advance together: state the coupling in the LHS store — the entry values *are* the invariant. The computed quantity is itself defined by a recurrence, so declare a spec-only recursive symbol with `[simplification]` defining rules; the inductive step then discharges by unfolding the definition (definitional — no halving lemma).

```
syntax Int ::= fib(Int) [function, total, smtlib(fib)]
rule fib(0) => 0                                    [simplification]
rule fib(1) => 1                                    [simplification]
rule fib(N:Int) => fib(N -Int 1) +Int fib(N -Int 2)
  requires N >Int 1                                 [simplification]
```

```
claim
  <k>
    while i < n : INDENT prev , curr = curr , prev + curr  i = i + 1 DEDENT => .K ...
  </k>
  <store>
    prev |-> (fib(I) => fib(N))
    curr |-> (fib(I +Int 1) => fib(N +Int 1))
    i    |-> (I:Int => N)
    n    |-> N:Int
  </store>
  requires 0 <=Int I andBool I <=Int N
  [all-path]
```

## ∀-quantified postcondition — 09-array-max

Use when the postcondition quantifies over a structure ("the result bounds every element, and is itself an element"): write the bounded `forall` and the membership as clean inductive spec-only functions, and bind the result to a `?`-existential pinned by `ensures` — the result cell is `result |-> (_:KResult => ?M:Int)`. No multiset is involved, so this stays in the bundled tier (no escalation).

```
syntax Bool ::= isUpperBound(List, Int) [function, total]
rule isUpperBound(.List, _)                  => true
rule isUpperBound(ListItem(X:Int) L, B:Int)  => X <=Int B andBool isUpperBound(L, B)

syntax Bool ::= inList(Int, List) [function, total]
rule inList(_, .List)                  => false
rule inList(X:Int, ListItem(Y:Int) L)  => X ==Int Y orBool inList(X, L)
```

The function claim closes with:

```
requires size(A) >=Int 1
ensures  isUpperBound(A, ?M) andBool inList(?M, A)
[all-path]
```

## Relational spec + multiset + nested circularities — 12-insertion-sort

Use when the postcondition is relational (a sorted permutation, not a closed form) and loops nest. Declare the relational vocabulary as spec-only functions — `bag(X) ==K bag(Y)` *is* "X is a permutation of Y":

```
syntax Bool ::= isSorted(List) [function, total]
rule isSorted(.List)                          => true
rule isSorted(ListItem(_))                    => true
rule isSorted(ListItem(X:Int) ListItem(Y:Int) L)
     => X <=Int Y andBool isSorted(ListItem(Y) L)

syntax Map ::= bag(List)        [function, total]
             | incr(Map, Int)   [function, total]
rule bag(.List)                 => .Map
rule bag(ListItem(X:Int) L)     => incr(bag(L), X)
rule incr(M:Map, X:Int) => M [ X <- (({M[X]}:>Int) +Int 1) ] requires X in_keys(M)
rule incr(M:Map, X:Int) => M [ X <- 1 ]                      requires notBool X in_keys(M)
```

Three claims nest exactly like the algorithm. `(SORT)`, the function contract, binds the returned list to `?R:List` and ensures:

```
ensures  size(?R) ==Int size(A)
 andBool isSorted(?R)
 andBool bag(?R) ==K bag(A)
```

`(OUTER)` is the outer-loop circularity — invariant "prefix `[0,I)` sorted": `requires 1 <=Int I andBool I <=Int size(B) andBool isSorted(take(B, I))` — and it reuses `(INNER)`, the inner-loop "insert key into a hole" circularity (`isSorted(take(C, J +Int 1))`, `allGt(seg(C, J +Int 2, I +Int 1), KEY)`, and the hole-fill bag link `bag(C[J+1<-KEY]) ==K bag(?D[?J2+1<-KEY])`). The multiset / sorted-composition lemmas (L1, L2) the inner and outer steps need are written **as comments marked `[ESCALATION BOUNDARY]`** — deliberately *not* `rule ... [simplification]` and *not* `[trusted]`.

## Recursive data structure — 13-tree-height

Use when the data itself is recursive: model it as a first-class K **value sort** (`syntax Tree ::= "none" | node(Int, Tree, Tree)` — by-value structure and non-aliasing fall out for free), give the spec partial selectors and an inductive measure, and state the recursion circularity over the sort.

```
syntax Tree ::= left(Tree)  [function]
              | right(Tree) [function]
rule left(node(_, L, _))  => L
rule right(node(_, _, R)) => R

syntax Int ::= h(Tree) [function]
rule h(none)          => 0
rule h(node(_, L, R)) => 1 +Int max2Int(h(L), h(R))                 [simplification]
```

The recursion circularity `(REC)` is the branching analog of 06's:

```
claim
  <k> tree_height ( T:Tree ) ~> CONT:K
   => h(T) ~> CONT </k>
```

(`<funcs>` carries both `tree_height` and its helper `max2`; `<store>`/`<stack>` net unchanged, as in the (REC) shape above.) It discharges **both** child calls `tree_height(left(T))` and `tree_height(right(T))` — branching recursion, two back-edges, each earned by its own `call` step; the verified helper contract `(MAX2)` handles the combine step (`max2Int` is its spec-side math twin). The base case and the per-node step are bundled-tier clean; the structural-induction principle `(T-IND)` — lifting base + step to "every finite Tree" — is the stated `[ESCALATION BOUNDARY]`, routed to the μ-logic papers, not admitted as `[trusted]`.

## The sum-* cluster: one contract, three proofs

`02-sum-up`, `03-sum-down`, and `06-sum-recursive` all prove the *same* contract (`result = N *Int (N +Int 1) /Int 2` for `N >=Int 0`) — by counting up, by counting down, and by recursion. **The proof obligations differ even when the spec does not**: a different invariant shape for each loop, and a recursive-call contract instead of a loop invariant for the recursion. Pick the shape that matches the *implementation*, not the contract.

*Derived from grosu/formal-verification-kit (MIT, Copyright (c) 2026 Grigore Rosu). See LICENSE and README credits.*
