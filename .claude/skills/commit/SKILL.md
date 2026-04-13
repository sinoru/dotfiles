---
name: commit
description: "Commit all local changes with a descriptive commit message."
allowed-tools:
  - Bash(git *)
  - Read
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# Commit

Commit all local changes with a descriptive message.

## Current repository state

### Status
!`git status`

### Staged changes
!`git diff --cached --stat`

### Unstaged changes
!`git diff --stat`

### Recent commits (style reference)
!`git log -20`

## Instructions

> The shell's working directory is already set to the repository root. All `git` commands run in the correct directory automatically — do NOT use `git -C` or `cd` to specify a path. The path may contain spaces, but this is handled automatically.

1. Review the repository state above
2. **Staging decision**:
   - If staged changes exist (shown above) → do NOT stage anything else; commit only what is already staged
   - If no staged changes → stage all relevant files (prefer explicit file names over `git add -A`); warn about secrets
3. Run `git diff --cached` to analyze the full staged changes
   - If the diff is large, inspect key files individually
4. Check if `CHANGELOG.md` exists at the repository root using `Glob`
   - If it does not exist, skip this step entirely
   - If it exists, `Read` it and verify it follows Keep a Changelog format by checking for **both**: a `## [Unreleased]` section AND at least one `### Added/Changed/Deprecated/Removed/Fixed/Security` heading anywhere in the file. If either is missing, skip this step
   - `Read` the rules reference at `${CLAUDE_SKILL_DIR}/keep-a-changelog-rules.md` and follow them precisely
   - Analyze the staged diff and determine suggested changelog categories (Added/Changed/Fixed etc.) and entries
   - Use `AskUserQuestion` to ask what entries to add to the changelog. Present your analysis — suggested categories and entries, or an explicit note that the changes appear purely internal with no user-facing impact — so the user can confirm, adjust, skip, or provide their own description
   - If the user indicates there is nothing to add, skip the changelog update
   - Otherwise, use `Edit` to add entries under `## [Unreleased]` in the appropriate category based on the user's answer
   - Stage the updated `CHANGELOG.md` together with other changes
5. Write a commit message:
   - **Format**: follow the repository's conventions observed in the recent commits above (prefix style, tense, scope notation, etc.)
   - **Quality baseline** (always enforced regardless of repo style):
     - Title: concise, specific, focused on "why" over "what"
     - Body: add when the change spans multiple files or needs context on motivation/trade-offs; skip for trivial single-file changes
     - Avoid vague messages like "fix bug" or "update code" even if the repo has such history
6. Commit (do NOT push)
7. Run `git status` to confirm the commit succeeded

## Rules

- Do NOT use `cd` or `git -C`
- Do NOT push to remote — the user will push manually after review
- Do NOT amend existing commits unless explicitly asked
- If changes include files that may contain secrets (`.env`, credentials, etc.), warn the user and ask for confirmation before staging them
- If there are no changes to commit, say so and stop
- Do NOT create a new `CHANGELOG.md` — only update an existing one that follows Keep a Changelog format
- Do NOT modify version release sections in `CHANGELOG.md` — only edit under `## [Unreleased]`

## Additional resources

- For Keep a Changelog formatting rules, see [keep-a-changelog-rules.md](keep-a-changelog-rules.md)
