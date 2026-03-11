---
name: review-full
description: "Review entire files or directories for bugs and code quality. Use when the user explicitly runs /review-full."
context: fork
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
---

# Full Code Review

Review specified files or the entire project for bugs, project convention compliance, and code quality.

## Arguments

- Optional: file or directory paths to review (e.g., `/review-full src/` or `/review-full main.swift utils.swift`)
- If no paths are specified, review all source files in the project

## Evaluation Dimensions

Evaluate code across four dimensions:

1. **Appropriate Complexity** — Is the complexity level justified by actual requirements? Too much abstraction is waste; too little is a maintenance trap.
2. **Readability** — Can a developer understand this quickly? Does the structure communicate intent?
3. **Performance** — Are there unnecessary allocations, redundant operations, or inefficient patterns that matter in this context?
4. **Best Practices** — Does the code follow established conventions and idioms for its language/framework?

## Instructions

1. Determine the review target:
   - If paths are provided, use those
   - If no paths are provided, use Glob to discover all source files in the project (exclude build artifacts, dependencies, generated files)
2. Group files by logical area (module, directory, or feature)
3. Launch parallel agents to review each group independently. Each agent evaluates:
   - **Convention & Best Practices**: Check code against project conventions (naming, patterns, access control, language-specific guidelines, etc.)
   - **Bug & Edge Cases**: Scan for bugs, logic errors, race conditions, missing error context, and unvalidated external inputs. Focus on real issues, not nitpicks.
   - **Complexity & Readability**: Evaluate whether complexity is appropriate for the requirements. Detect both over-engineering and under-engineering:
     - **Over-engineering**: premature abstraction, unnecessary indirection, speculative generality, cargo cult patterns, verbose ceremonies
     - **Under-engineering**: missing boundary validation, insufficient error context, tight coupling that will hurt, absent separation where it counts, ignored edge cases
4. Collect results from all agents
5. Filter out false positives and nitpicks — only report issues a senior engineer would flag
6. **Acknowledge justified complexity** — if an abstraction or pattern earns its place, say so explicitly rather than forcing simplification
7. Present a consolidated review

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

If no issues are found, say: "No issues found. The code is well-structured with appropriate complexity."

## Rules

- Do NOT modify any code — review only
- Ignore formatting/style issues that a linter would catch
- Focus on the "why" — explain the impact of each issue, not just what's wrong
- Respect intent — understand what the developer was trying to achieve before flagging issues
- Don't suggest changes for the sake of change — if code is clear, appropriately complex, and follows conventions, say so
- Group related issues — if multiple issues stem from the same root cause, present them as one
- Output language must follow the user's communication preferences
