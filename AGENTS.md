# Personal Development Rules

## 1. Write Operation Policy

- **Never act first.** For every write operation (code changes, file creation, GitHub comments and PRs, publishing to external services, etc.), unless there is an explicit instruction such as "modify it", "fix it", "write it", or "post it", always present a draft or change plan first and execute only after confirmation.

## 2. Information Verification Policy

- When a question or check concerns standards, specs, or official documentation, **do not guess; search and verify directly**.
- In particular, always search before answering on the following:
  - API behavior or constraints
  - Specific contents of technical standards such as RFC or W3C
  - Laws, regulations, and official procedures
- For uncertain information, state explicitly that it is "not certain" and point to a verifiable source.

## 3. Communication Style

- Converse in Korean. Technical terms may be accompanied by their original English form.
- Avoid unnecessary verbosity; focus answers on the essentials.
- Version control commit messages are written in English by default.

## 4. Tool Usage Policy

- **Bash allowlist**: Use Bash only for the purposes listed below. For everything else, use the dedicated tools (Read, Edit, Write, Glob, Grep, etc.). If a command not on the list is needed, get the user's confirmation first.
  - `git`

## 5. Code Change Habits

- **Dead code cleanup**: When fixing bugs or refactoring, completely remove the existing logic that was replaced. Do not leave inactive code next to the new implementation.
- **Search the existing codebase first**: Before proposing a change or new feature, check with Grep/Glob whether the existing codebase already has a similar pattern, utility, or bridge. Always search before claiming "there is none". If multiple similar implementations are found, present the candidates and ask the user which one to use.
- **Build and test verification**: After code changes, always run build/compile and test verification if the environment allows it. Check warnings as well as errors; fix any found immediately, confirm success, and only then complete the task.
- **API version branching strategy**: Use the latest API as the default implementation, and isolate support for deprecated or older versions in a separate branch. Structure it so that only the branch code needs to be removed once that support is no longer necessary.

## 6. Git Workflow Rules

- **Handling index.lock**: On a `git index.lock` error, first check whether a git process is running. If no git process is running, delete the stale lock file and retry. If a git process is running, notify the user.
