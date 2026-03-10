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
  - Glob
  - Grep
---

# Commit

Commit all local changes with a descriptive message.

## Instructions

1. Run `git status` to identify all changed, added, and deleted files
2. Run `git diff` (staged + unstaged) to understand the changes
3. Run `git log -20` to match the repository's commit message style (title, body, and footer)
4. Stage all relevant files (prefer explicit file names over `git add -A`)
5. Write a concise conventional commit message based on the diff — focus on "why" not "what"
6. Commit (do NOT push)
7. Run `git status` to confirm the commit succeeded

## Rules

- Do NOT push to remote — the user will push manually after review
- Do NOT amend existing commits unless explicitly asked
- If changes include files that may contain secrets (`.env`, credentials, etc.), warn the user and ask for confirmation before staging them
- If there are no changes to commit, say so and stop
