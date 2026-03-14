---
name: commit
description: "Commit all local changes with a descriptive conventional commit message. Do NOT use automatically — only when the user explicitly runs /commit."
disable-model-invocation: true
allowed-tools:
  - Bash(git status*)
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(git add *)
  - Bash(git commit *)
  - Read
  - Edit
  - Glob
  - Grep
---

# Commit

Commit all local changes with a descriptive message.

## Instructions

> The shell's working directory is already set to the repository root. All `git` commands run in the correct directory automatically — do NOT use `git -C` or `cd` to specify a path. The path may contain spaces, but this is handled automatically.

1. Run `git status` to identify all changed, added, and deleted files
2. Run `git diff` (staged + unstaged) to understand the changes
3. Run `git log -20` to match the repository's commit message style (title, body, and footer)
4. Stage all relevant files (prefer explicit file names over `git add -A`)
5. Check if `CHANGELOG.md` exists at the repository root using `Glob`
   - If it does not exist, skip this step entirely
   - If it exists, `Read` it and verify it follows Keep a Changelog format by checking for **both**: a `## [Unreleased]` section AND at least one `### Added/Changed/Deprecated/Removed/Fixed/Security` heading anywhere in the file. If either is missing, skip this step
   - `Read` the rules reference at `${CLAUDE_SKILL_DIR}/keep-a-changelog-rules.md` and follow them precisely
   - Use `Edit` to add entries under `## [Unreleased]` in the appropriate category based on the diff analysis
   - Stage the updated `CHANGELOG.md` together with other changes
6. Write a concise conventional commit message based on the diff — focus on "why" not "what"
7. Commit (do NOT push)
8. Run `git status` to confirm the commit succeeded

## Rules

- Do NOT use `cd` or `git -C` — all git commands must start exactly with `git status`, `git diff`, `git log`, `git add`, or `git commit` as listed in allowed-tools
- Do NOT push to remote — the user will push manually after review
- Do NOT amend existing commits unless explicitly asked
- If changes include files that may contain secrets (`.env`, credentials, etc.), warn the user and ask for confirmation before staging them
- If there are no changes to commit, say so and stop
- Do NOT create a new `CHANGELOG.md` — only update an existing one that follows Keep a Changelog format
- Do NOT modify version release sections in `CHANGELOG.md` — only edit under `## [Unreleased]`

## Additional resources

- For Keep a Changelog formatting rules, see [keep-a-changelog-rules.md](keep-a-changelog-rules.md)
