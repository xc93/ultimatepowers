# Formal Verification Reviewer Prompt Template

Use this template when dispatching a formal verification reviewer subagent.

**Purpose:** Run automatic formal analysis (K-notation contracts + constructed
proofs) over the task's diff and report proof-derived findings.

**Only dispatch after spec compliance review passes. Dispatch in parallel with
the code quality reviewer (same message, two Task invocations). Both must
approve before the task is complete.**

```
Task tool (general-purpose):
  Use template at requesting-code-review/formal-reviewer.md

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

**Notes for per-task reviews:**
- The reviewer operates in per-task mode (diff-scoped claims; trivial diffs
  take the fast path) — that selection is the reviewer's job, not yours.
- Artifacts APPEND to the feature's existing
  `docs/ultimatepowers/verification/YYYY-MM-DD-<topic>/` directory.
- "Verification limits" entries are capability gaps, not blocking issues.

**Reviewer returns:** Strengths, Issues (Critical/Important/Minor) with formal
evidence, Verification limits, Assessment + artifact path
