---
name: review-diff
description: "Review locally changed code (git diff) for bugs and code quality. Use when the user explicitly runs /review-diff."
context: fork
disable-model-invocation: true
allowed-tools:
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(git status*)
  - Bash(git blame*)
  - Read
  - Glob
  - Grep
  - Agent
---

# Diff Code Review

Review all uncommitted local changes for bugs, project convention compliance, and code quality.

## Evaluation Dimensions

Evaluate changes across five dimensions:

1. **Appropriate Complexity** — Is the complexity level justified by actual requirements? Too much abstraction is waste; too little is a maintenance trap.
2. **Readability** — Can a developer understand this quickly? Does the structure communicate intent?
3. **Performance** — Are there unnecessary allocations, redundant operations, or inefficient patterns that matter in this context?
4. **Best Practices** — Does the code follow established conventions and idioms for its language/framework?
5. **Security** — Does the code introduce vulnerabilities exploitable by an attacker?

## Instructions

1. **CLAUDE.md 탐색** — Launch a sonnet Agent to discover project conventions:
   - Use Glob to find `CLAUDE.md` files in the project root and in directories containing changed files
   - Read all discovered CLAUDE.md files and summarize the conventions, rules, and guidelines
   - Pass the collected context to subsequent review agents
2. Run `git diff HEAD --stat` to get an overview of changed files and their modification scale
3. If there are no changes, say so and stop
4. Run `git diff HEAD` to get the full diff
5. Launch 5 parallel agents to review the changes independently:
   - **Agent 1 — Convention & Best Practices**: Check changes against project conventions (naming, patterns, access control, language-specific guidelines, etc.). Include CLAUDE.md context in the prompt so the agent can verify compliance with project-specific rules.
   - **Agent 2 — Bug & Edge Cases**: Scan for bugs, logic errors, race conditions, missing error context, and unvalidated external inputs. Focus on real issues, not nitpicks.
   - **Agent 3 — Complexity & Readability**: Evaluate whether complexity is appropriate for the requirements. Detect both over-engineering and under-engineering:
     - **Over-engineering**: premature abstraction, unnecessary indirection, speculative generality, cargo cult patterns, verbose ceremonies
     - **Under-engineering**: missing boundary validation, insufficient error context, tight coupling that will hurt, absent separation where it counts, ignored edge cases
   - **Agent 4 — Git History & Context**: Use `git log` and `git blame` on changed files to analyze:
     - Areas that are repeatedly modified (churn hotspots)
     - Recent related changes that provide context
     - Intentional design decisions visible in commit history
     - Whether the current changes align with or contradict historical patterns
   - **Agent 5 — Security**: 공격자 관점에서 보안 취약점을 검토한다.
     3단계 분석:
     (1) Context Research — Glob/Grep으로 기존 보안 프레임워크, 검증 패턴, 인증 미들웨어 등을 파악
     (2) Comparative Analysis — 변경된 코드가 기존 보안 패턴을 따르는지, 새로운 공격 표면을 도입하는지 비교
     (3) Vulnerability Assessment — 사용자 입력에서 민감 연산까지 데이터 흐름 추적, 권한 경계 교차 확인

     검사 카테고리:
     - Input Validation: SQL injection, command injection, XXE, template injection, path traversal
     - Auth & Authorization: 인증 우회, 권한 상승, 세션 관리, JWT, 인가 로직
     - Crypto & Secrets: 하드코딩 키/토큰, 약한 암호화, 키 관리, 난수, 인증서 검증
     - Injection & Code Execution: 역직렬화 RCE, eval injection, XSS (reflected/stored/DOM)
     - Data Exposure: 민감 데이터 로깅, PII, API 엔드포인트 누출, 디버그 정보

     Hard Exclusions (보고하지 않음):
     - DOS / 리소스 고갈
     - 디스크상 시크릿 (별도 프로세스 관할)
     - 테스트 전용 파일
     - 메모리 안전 언어의 메모리 안전 이슈 (Rust, Go 등)
     - 환경 변수 / CLI 플래그 기반 공격 (신뢰 값)
     - 경로만 제어 가능한 SSRF (호스트/프로토콜 제어 불가 시)
     - 이론적 레이스 컨디션
     - 문서 파일 (*.md 등)
     - 보안 강화 미비 (구체적 취약점만 보고)

     Precedents:
     - React/Angular는 dangerouslySetInnerHTML 등 unsafe 메서드 없이는 XSS 면제
     - 클라이언트 사이드 인증/인가 체크 부재는 취약점 아님 (서버 책임)
     - UUID는 추측 불가로 간주
     - 비-PII 로깅은 취약점 아님
     - 셸 스크립트 command injection은 비신뢰 입력 경로가 구체적일 때만 보고
6. Collect results from all agents
7. **Confidence Scoring** — Assign a confidence score (0–100) to each issue:
   - **0**: False positive or pre-existing issue
   - **25**: Plausible but no supporting evidence found in code
   - **50**: Likely — context suggests this path is reachable
   - **75**: Confirmed — code path verified through trace
   - **100**: Certain — directly observable in code with no ambiguity
8. **Severity Classification** — Assign a severity to each issue:
   - **High**: 운영 장애, 데이터 손실, 보안 취약점 등 즉시 대응 필요
   - **Medium**: 유지보수성 저하, 잠재적 버그, 컨벤션 위반 등 조기 수정 권장
   - **Low**: 사소한 개선점, 스타일 제안 등 선택적 수정
9. **Filter out issues where confidence < 80 OR severity = Low** — only report high-confidence, meaningful findings
10. **Acknowledge justified complexity** — if an abstraction or pattern earns its place, say so explicitly rather than forcing simplification
11. Present a consolidated review

## Output Format

For each issue:

### Issue: [Concise title]
**Category**: Over-Engineering | Under-Engineering | Bug | Convention | Readability | Performance | Security
**Severity**: High | Medium | Low
**Confidence**: [0–100]
**File**: `path/to/file` (lines X-Y)

**What's happening**: A clear, non-judgmental explanation. Acknowledge the likely reasoning behind the current approach.

**Exploit Scenario** (Security only): 구체적 공격 시나리오 — 공격자가 어떻게 이 취약점을 악용할 수 있는지

**Trade-off**: What you gain and what (if anything) you lose by changing it.

---

End with a summary:

**Summary**
- **High**: X issues
- **Medium**: X issues
- **Filtered out**: X issues (confidence < 80 or Low severity)
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
- Output language must follow the user's communication preferences
