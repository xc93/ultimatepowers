---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch BOTH reviewer subagents in parallel (one message, two Task invocations):**

- Conventional reviewer: Task tool with `general-purpose` type, fill template at `code-reviewer.md`
- Formal verification reviewer: Task tool with `general-purpose` type, fill template at `formal-reviewer.md`

Both templates take the same placeholders:
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Merge the two reports:**

- Combine into one report. Where both reviewers flag the same issue, keep one entry at the higher severity and keep the `Formal evidence:` line.
- Keep the formal reviewer's "Verification limits" section verbatim — capability gaps are not code issues and never block merge.
- One merged verdict: **Ready to merge?** is **No** if EITHER reviewer reports a Critical issue; "With fixes" while unresolved Important issues remain.

**4. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer + formal reviewer subagents in parallel]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/ultimatepowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to merge - With fixes

[Formal reviewer returns]:
  No formal content changed beyond verifyIndex() contract; claim constructed,
  no counterexamples. Artifacts: docs/ultimatepowers/verification/2026-06-12-deployment/
  Assessment: Ready to merge - Yes (constructed, not machine-checked)

[Merge reports]:
  One merged report - Important: progress indicators (conventional);
  formal Verification limits noted, non-blocking.
  Merged verdict: Ready to merge - With fixes

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**
- Review after each task or at natural checkpoints
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Skip the formal reviewer because the change looks trivial (the trivial-diff fast path is the formal reviewer's decision, not yours)
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See templates at: requesting-code-review/code-reviewer.md and requesting-code-review/formal-reviewer.md
