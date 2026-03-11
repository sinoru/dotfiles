---
name: review
description: "Review locally changed code for bugs, CLAUDE.md compliance, and code quality. Use when the user explicitly runs /review."
context: fork
disable-model-invocation: true
allowed-tools:
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(git status*)
  - Read
  - Glob
  - Grep
  - Agent
---

# Code Review

Review all uncommitted local changes for bugs, project convention compliance, and code quality.

## Evaluation Dimensions

Evaluate changes across four dimensions:

1. **Appropriate Complexity** — Is the complexity level justified by actual requirements? Too much abstraction is waste; too little is a maintenance trap.
2. **Readability** — Can a developer understand this quickly? Does the structure communicate intent?
3. **Performance** — Are there unnecessary allocations, redundant operations, or inefficient patterns that matter in this context?
4. **Best Practices** — Does the code follow established conventions and idioms for its language/framework?

## Instructions

1. Run `git diff` to get all uncommitted changes (staged + unstaged)
2. Run `git diff --name-only` to list changed files
3. If there are no changes, say so and stop
4. Read relevant CLAUDE.md files (root and any in directories of changed files)
5. Launch 3 parallel agents to review the changes independently:
   - **Agent 1 — Convention & Best Practices**: Check changes against CLAUDE.md and project conventions (naming, patterns, access control, Swift API Design Guidelines, etc.)
   - **Agent 2 — Bug & Edge Cases**: Scan for bugs, logic errors, race conditions, missing error context, and unvalidated external inputs. Focus on real issues, not nitpicks.
   - **Agent 3 — Complexity & Readability**: Evaluate whether complexity is appropriate for the requirements. Detect both over-engineering and under-engineering:
     - **Over-engineering**: premature abstraction, unnecessary indirection, speculative generality, cargo cult patterns, verbose ceremonies
     - **Under-engineering**: missing boundary validation, insufficient error context, tight coupling that will hurt, absent separation where it counts, ignored edge cases
6. Collect results from all agents
7. Filter out false positives and nitpicks — only report issues a senior engineer would flag
8. **Acknowledge justified complexity** — if an abstraction or pattern earns its place, say so explicitly rather than forcing simplification
9. Present a consolidated review

## Output Format

For each issue:

### Issue: [Concise title]
**Category**: Over-Engineering | Under-Engineering | Bug | Convention | Readability | Performance
**Severity**: High | Medium
**File**: `path/to/file` (lines X-Y)

**What's happening**: A clear, non-judgmental explanation. Acknowledge the likely reasoning behind the current approach.

**Trade-off**: What you gain and what (if anything) you lose by changing it.

---

End with a summary:

**Summary**
- **High**: X issues
- **Medium**: X issues
- **Justified complexity noted**: X instances (if any — acknowledge complexity that earns its keep)
- **Recommended approach**: [Brief suggestion on what to tackle first and why]

If no issues are found, say: "No issues found. The changes are well-structured with appropriate complexity."

## Rules

- Do NOT modify any code — review only
- Do NOT report issues on lines that were not changed
- Ignore formatting/style issues that a linter would catch
- Ignore pre-existing issues not introduced by the current changes
- Focus on the "why" — explain the impact of each issue, not just what's wrong
- Respect intent — understand what the developer was trying to achieve before flagging issues
- Don't suggest changes for the sake of change — if code is clear, appropriately complex, and follows conventions, say so
- Group related issues — if multiple issues stem from the same root cause, present them as one
