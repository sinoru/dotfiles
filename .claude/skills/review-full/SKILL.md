---
name: review-full
description: "Review entire files or directories for bugs and code quality. Use when the user explicitly runs /review-full."
context: fork
disable-model-invocation: true
allowed-tools:
  - Bash(git log*)
  - Bash(git blame*)
  - Bash(git diff*)
  - Bash(git rev-parse*)
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

Evaluate code across five dimensions:

1. **Appropriate Complexity** — Is the complexity level justified by actual requirements? Too much abstraction is waste; too little is a maintenance trap.
2. **Readability** — Can a developer understand this quickly? Does the structure communicate intent?
3. **Performance** — Are there unnecessary allocations, redundant operations, or inefficient patterns that matter in this context?
4. **Best Practices** — Does the code follow established conventions and idioms for its language/framework?
5. **Security** — Does the code introduce vulnerabilities exploitable by an attacker?

## Instructions

1. **CLAUDE.md Discovery** — Launch a sonnet Agent to discover project conventions:
   - Use Glob to find `CLAUDE.md` files in the project root and in directories containing the review targets
   - Read all discovered CLAUDE.md files and summarize the conventions, rules, and guidelines
   - Pass the collected context to subsequent review agents
2. **Check Git Availability** — Run `git rev-parse --is-inside-work-tree` to check if git is available. Store the result as a flag for conditional steps below.
3. Determine the review target:
   - If paths are provided, use those
   - If no paths are provided, use Glob to discover all source files in the project (exclude build artifacts, dependencies, generated files)
4. Launch 5 parallel agents to review the target files independently, each from its own perspective:
   - **Agent 1 — Convention & Best Practices**: Check code against project conventions (naming, patterns, access control, language-specific guidelines, etc.). Include CLAUDE.md context in the prompt so the agent can verify compliance with project-specific rules. Each agent reads all target files through its own lens. If files are numerous, group them logically within the agent.
   - **Agent 2 — Bug & Edge Cases**: Scan for bugs, logic errors, race conditions, missing error context, and unvalidated external inputs. Focus on real issues, not nitpicks.
   - **Agent 3 — Complexity & Readability**: Evaluate whether complexity is appropriate for the requirements. Detect both over-engineering and under-engineering:
     - **Over-engineering**: premature abstraction, unnecessary indirection, speculative generality, cargo cult patterns, verbose ceremonies
     - **Under-engineering**: missing boundary validation, insufficient error context, tight coupling that will hurt, absent separation where it counts, ignored edge cases
   - **Agent 4 — Git History & Context** (only when git is available): Use `git log` and `git blame` on reviewed files to analyze:
     - Areas that are repeatedly modified (churn hotspots)
     - Recent related changes that provide context
     - Intentional design decisions visible in commit history
     - Whether the current code aligns with or contradicts historical patterns
   - **Agent 5 — Security**: Review target code for security vulnerabilities from an attacker's perspective.
     Three-phase analysis:
     (1) Context Research — Use Glob/Grep to identify existing security frameworks, validation patterns, auth middleware, etc.
     (2) Comparative Analysis — Compare whether target code follows existing security patterns or exposes attack surfaces
     (3) Vulnerability Assessment — Trace data flow from user input to sensitive operations, verify privilege boundary crossings

     Inspection categories:
     - Input Validation: SQL injection, command injection, XXE, template injection, path traversal
     - Auth & Authorization: authentication bypass, privilege escalation, session management, JWT, authorization logic
     - Crypto & Secrets: hardcoded keys/tokens, weak encryption, key management, randomness, certificate validation
     - Injection & Code Execution: deserialization RCE, eval injection, XSS (reflected/stored/DOM)
     - Data Exposure: sensitive data logging, PII, API endpoint leakage, debug information

     Hard Exclusions (do not report):
     - DOS / resource exhaustion
     - Secrets on disk (handled by separate process)
     - Test-only files
     - Memory safety issues in memory-safe languages (Rust, Go, etc.)
     - Attacks via environment variables / CLI flags (trusted values)
     - SSRF where only the path is controllable (no host/protocol control)
     - Theoretical race conditions
     - Documentation files (*.md, etc.)
     - Missing hardening (report only concrete vulnerabilities)

     Precedents:
     - React/Angular are exempt from XSS unless unsafe methods like dangerouslySetInnerHTML are used
     - Absence of client-side auth/authorization checks is not a vulnerability (server responsibility)
     - UUIDs are considered unguessable
     - Non-PII logging is not a vulnerability
     - Shell script command injection is only reported when an untrusted input path is concrete

   Each agent reads all target files through its own lens. If files are numerous, group them logically within the agent.
5. Collect results from all agents
6. **Confidence Scoring** — Assign a confidence score (0–100) to each issue:
   - **0**: False positive or pre-existing issue
   - **25**: Plausible but no supporting evidence found in code
   - **50**: Likely — context suggests this path is reachable
   - **75**: Confirmed — code path verified through trace
   - **100**: Certain — directly observable in code with no ambiguity
7. **Severity Classification** — Assign a severity to each issue:
   - **High**: Requires immediate attention: outages, data loss, security vulnerabilities
   - **Medium**: Should be fixed early: maintainability issues, potential bugs, convention violations
   - **Low**: Optional improvements: minor enhancements, style suggestions
8. **Filter out issues where confidence < 80 OR severity = Low** — only report high-confidence, meaningful findings
9. **Acknowledge justified complexity** — if an abstraction or pattern earns its place, say so explicitly rather than forcing simplification
10. Present a consolidated review

## Output Format

For each issue:

### Issue: [Concise title]
**Category**: Over-Engineering | Under-Engineering | Bug | Convention | Readability | Performance | Security
**Severity**: High | Medium | Low
**Confidence**: [0–100]
**File**: `path/to/file` (lines X-Y)

**What's happening**: A clear, non-judgmental explanation. Acknowledge the likely reasoning behind the current approach.

**Exploit Scenario** (Security only): Concrete attack scenario — how an attacker could exploit this vulnerability

**Trade-off**: What you gain and what (if anything) you lose by changing it.

---

End with a summary:

**Summary**
- **High**: X issues
- **Medium**: X issues
- **Filtered out**: X issues (confidence < 80 or Low severity)
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
