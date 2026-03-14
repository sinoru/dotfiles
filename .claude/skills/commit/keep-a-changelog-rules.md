# Keep a Changelog Rules Reference

> Based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/)

## Change Type Categories

Only these six categories are allowed, in this recommended order:

| Category | Meaning |
|---|---|
| `### Added` | New features |
| `### Changed` | Changes in existing functionality |
| `### Deprecated` | Soon-to-be removed features |
| `### Removed` | Now removed features |
| `### Fixed` | Bug fixes |
| `### Security` | Vulnerability patches |

## Markdown Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New feature description

## [1.0.0] - 2024-01-15

### Changed

- Existing feature modification

[unreleased]: https://github.com/user/project/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/user/project/releases/tag/v1.0.0
```

## Formatting Rules

1. **Heading levels**: `# Changelog` (H1), `## [Version]` (H2), `### Category` (H3)
2. **Version heading format**: `## [X.Y.Z] - YYYY-MM-DD`
3. **Unreleased heading**: `## [Unreleased]` (no date)
4. **Date format**: ISO 8601 — `YYYY-MM-DD` only. Never regional formats
5. **Ordering**: Latest version first, oldest last
6. **Each change**: A bullet point (`- `) with a human-readable description
7. **Yanked releases**: Append `[YANKED]` — e.g., `## [0.0.5] - 2014-12-13 [YANKED]`
8. **Comparison links**: Place at the bottom of the file, linking each version to a diff

## Writing Guidelines

- Write for **humans**, not machines — clear, concise descriptions
- Focus on **notable** changes — skip trivial internal refactors that don't affect users
- Group same types of changes under the same category heading
- Do not duplicate commit messages verbatim — summarize the user-facing impact
- Consistently document all important changes — an incomplete changelog can be worse than none

## Anti-Patterns to Avoid

1. **Commit log dumps**: Never paste raw commit messages. They contain noise (merge commits, typo fixes, internal changes) that makes the changelog useless
2. **Ignoring deprecations**: Always document deprecations so users can prepare before removals
3. **Inconsistent coverage**: Don't document some changes and skip others of equal importance
4. **Regional date formats**: Never use MM/DD/YYYY or DD/MM/YYYY — always YYYY-MM-DD

## Rules for Editing

- Only add entries under `## [Unreleased]` — never modify released version sections
- Create the category heading (e.g., `### Fixed`) under `## [Unreleased]` if it doesn't already exist
- Maintain the recommended category order when creating new headings
- Keep entries concise — one bullet per distinct change
- If comparison links exist at the bottom, do not break them
