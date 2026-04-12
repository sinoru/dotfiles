---
name: swiftlang
description: >-
  Comprehensive Swift language guide covering code style, API design guidelines,
  concurrency patterns, and modern Swift 6.x features (through Swift 6.3).
  TRIGGER when: editing or discussing .swift files; Package.swift present in
  project; user mentions Swift, SwiftUI, actors, Sendable, async/await, protocols,
  extensions, property wrappers, result builders, or any Swift language feature;
  code context clearly involves Swift even without explicit mention. This skill
  MUST be loaded for ANY Swift-related development context without exception.
---

# Swift Language Guide

Guidance for Swift development grounded in the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and updated for Swift 6.3.

## Core Principles

1. **Clarity at the point of use.** Entities are declared once but used repeatedly — optimize for the reader at the call site, not the author at the declaration site.
2. **Clarity over brevity.** Concise code is a welcome side-effect of Swift's type system, not a goal to pursue by itself.
3. **Safety by default.** Swift 6 enforces data race safety at compile time. Treat the compiler as a collaborator — when it complains, the code likely has a real concurrency bug.
4. **Progressive disclosure.** Simple tasks should require simple code. Expose complexity only when the caller needs it.

## Quick Reference

### Naming Essentials

- Name by **role**, not type: `var greeting: String` — not `var string: String`
- Method calls read as **grammatical English**: `x.insert(y, at: z)` — not `x.insert(y, position: z)`
- No side-effects → **noun**: `x.distance(to: y)` / Side-effects → **imperative verb**: `x.sort()`
- Mutating / non-mutating pairs: `sort()` / `sorted()`, `formUnion()` / `union()`
- Booleans read as **assertions**: `isEmpty`, `isDisjoint(with:)`, `canBecomeFirstResponder`
- Types & protocols → `UpperCamelCase` / Everything else → `lowerCamelCase`
- Acronyms follow uniform casing: `utf8Bytes`, `HTTPSConnection`

### Formatting Essentials

- **4 spaces** indentation, **100 characters** max line width
- **K&R braces** — opening `{` on same line, `} else {` together
- **No parentheses** around conditions: `if condition {`
- **No semicolons**
- **Trailing commas required** in multi-line lists (collections, parameters, generics, captures)
- **One primary type per file**, filename matches the type

### Safety Essentials

- **Force unwrap (`!`) and force cast (`as!`) are strongly discouraged.** If used, a comment explaining why it is safe is required.
- **`try!` is generally forbidden.** Exception: tests, or compile-time-provable safety (e.g., regex from literal).
- **Avoid implicitly unwrapped optionals** — use regular `Optional` or non-optional.
- **Prefer `weak` over `unowned`** to prevent crashes from deallocated objects.

### Swift 6.x Key Patterns

These are the most impactful modern Swift patterns. Read the version-specific reference files for details.

**Concurrency (biggest area of change):**

- Enable **Swift 6 language mode** for compile-time data race safety
- Use **module-level `defaultIsolation`** (6.2+) instead of annotating every type with `@MainActor`
- `nonisolated async` functions now **stay on the caller's executor** (6.2+) — use **`@concurrent`** when you actually need parallel execution
- Prefer **`nonisolated`** on types/extensions (6.1+) to opt out of inherited actor isolation cleanly
- **`async defer`** (6.3+) — `defer` blocks can now `await`

**Type System:**

- **Typed throws** `throws(MyError)` (6.0+) for precise error contracts
- **`InlineArray`** / `[N of Element]` (6.2+) for fixed-size stack-allocated buffers
- **`@nonexhaustive` enum** (6.3+) for library enums that may grow cases

**Interop & Modules:**

- **`@c`** (6.3+) replaces `@_cdecl` for C interop — use the official attribute
- **Module selectors `ModuleA::symbol`** (6.3+) resolve name conflicts without renaming imports
- **Import access control** `public import` / `internal import` (6.0+) to control dependency exposure

**Performance:**

- **`@inline(always)`** (6.3+) now guarantees inlining (was hint-only before)
- **`@export(implementation)`** (6.3+) replaces `@_alwaysEmitIntoClient`
- **Span / MutableSpan** (6.2+) for safe contiguous memory access without unsafe pointers

## Detailed References

Read the relevant reference file when you need rules beyond this quick reference.

### `references/style-guide.md` — Full Style Guide

When to read: detailed formatting and line-wrapping rules, naming conventions with examples, documentation comment standards, file organization patterns, access control guidelines, pattern matching rules, trailing closure conventions, delegate naming, `self` usage, optional handling, attribute ordering, and performance coding practices.

### Swift 6.x Feature References (version-split)

Read the file matching the target Swift version. Each file instructs to also read lower-version files.

- **`references/swift-6_0.md`** — Data race safety, typed throws, noncopyable types, import access control
- **`references/swift-6_1.md`** — `nonisolated` on types, TaskGroup inference, trailing comma expansion
- **`references/swift-6_2.md`** — Default MainActor, `@concurrent`, InlineArray, Span, strict memory safety
- **`references/swift-6_3.md`** — `@c` interop, module selectors `::`, `@nonexhaustive` enum, async defer

### `references/swift-migration.md` — Migration & Best Practices

When to read: migrating to Swift 6 language mode, deciding which modern patterns to adopt/avoid, understanding breaking changes across versions.

### `references/official-packages.md` — Official Swift Packages

When to read: choosing the right data structure (Collections), applying sequence/collection algorithms (Algorithms), working with async streams (Async Algorithms), or doing numerical computing (Numerics). These are official Apple-maintained packages that may eventually graduate to the standard library.

### `references/spm.md` — Swift Package Manager

When to read: writing Package.swift, managing dependencies (version requirements, local/binary targets, traits), resource bundling, build settings (swiftSettings/cSettings), mixed C/ObjC targets, plugins, module aliasing, package security (signing/TOFU), version-specific packaging.

## Upstream Sources

The reference files in this skill are derived from the sources below. Consult them when information is insufficient or freshness is uncertain. Also use these sources when updating reference files.

- **Swift language changes**: [CHANGELOG.md](https://github.com/swiftlang/swift/blob/main/CHANGELOG.md), [Swift Evolution](https://www.swift.org/swift-evolution/)
- **Swift official docs**: [swift.org/documentation](https://www.swift.org/documentation/)
- **Swift blog**: [swift.org/blog](https://www.swift.org/blog/) — covers language changes, official packages, and ecosystem news
- **Apple developer docs / WWDC**: search via the sosumi skill
- **Official packages**: each package's repository README or [Swift Package Index](https://swiftpackageindex.com)
