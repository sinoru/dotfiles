---
name: swiftlang
description: >-
  Load this before you explore, read, or edit anything in a Swift codebase —
  one with Package.swift, an .xcodeproj, or .swift files under Sources/ or
  Tests/. That includes tasks that never say "Swift": a bug report or GitHub
  issue to fix, a flaky test, a feature to implement, a README or CI workflow
  for a Swift package, or a SwiftUI/UIKit screen to fix (use it together with
  apple-platform there). Every app for an Apple platform counts, Objective-C
  files included. No edit is too small: adding a property, renaming a method,
  adding an enum case. It carries the naming, idiom, concurrency, and testing
  rules every Swift change must follow, plus Swift 6 and Sendable migration,
  XCTest to Swift Testing, macros, Package.swift and dependencies, toolchain
  and swiftly/PATH questions, Swift language features, evolution proposals,
  and WWDC sessions, and server-side Swift (Vapor, Fluent, SwiftNIO, SSWG)
  including performance and deployment. Not for other languages, Xcode
  signing, pbxproj, or TestFlight administration.
---

# Swift Language Guide

Guidance for Swift development grounded in the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and updated for Swift 6.3 (latest stable; 6.4 is in development — see `references/swift-6_4.md`). One skill covers the language, the package ecosystem (SwiftPM, official packages), and server-side Swift (Vapor, Fluent, SwiftNIO — see `references/server/`).

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
- **Trailing commas required** in multi-line lists — collections always; parameters/generics/captures only on Swift 6.1+ toolchains
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
- **`async defer`** is **Swift 6.4 (unreleased)** — do not use or suggest it on stable toolchains

**Type System:**

- **Typed throws** `throws(MyError)` (6.0+) for precise error contracts
- **`InlineArray`** / `[N of Element]` (6.2+) for fixed-size stack-allocated buffers
- **`@nonexhaustive` enum** (6.2.3+) for library enums that may grow cases
- **`weak let`** (6.3+) — immutable weak references; unblocks `Sendable` classes with weak stored properties

**Interop & Modules:**

- **`@c`** (6.3+) replaces `@_cdecl` for C interop — use the official attribute
- **Module selectors `ModuleA::symbol`** (6.3+) resolve name conflicts without renaming imports
- **Import access control** `public import` / `internal import` (6.0+) to control dependency exposure

**Performance:**

- **`@inline(always)`** (6.3+) now guarantees inlining (was hint-only before)
- **`@export(implementation)`** (6.3+) replaces `@_alwaysEmitIntoClient`
- **Span / MutableSpan** (6.2+) for safe contiguous memory access without unsafe pointers

### Server-Side Essentials

Server code (Vapor, Fluent, SwiftNIO, SSWG packages) follows everything above plus a few rules that matter more on a server than anywhere else. These are only the headlines — read `references/server/overview.md` before writing or reviewing server code.

- **Never block an EventLoop.** One EventLoop serves many connections, so `Thread.sleep`, synchronous file I/O, `.wait()`, and long CPU work stall every client on that loop. Offload CPU-bound work (Bcrypt, image processing) with `req.application.threadPool.runIfActive(eventLoop:)`.
- **async/await is the default.** `EventLoopFuture` is legacy — bridge with `try await future.get()` / `promise.completeWithTask { }` only at the boundary with older APIs.
- **Swift 6 shapes the types.** Vapor 4.118+ requires Swift 6: `Content`/`View` are `Sendable`, Fluent models are `final class … Model, Content, @unchecked Sendable` with an empty `init() {}`, and a DTO `struct` is the cleaner way to shape API responses.
- **Prefer the async-first APIs.** `Application.make()` + `asyncShutdown()` over the deprecated synchronous `Application()`; `VaporTesting` (`withApp`, `app.testing()`) over `XCTVapor`; `NIOAsyncChannel` with `executeThenClose` for async channel I/O.

## Detailed References

Read the relevant reference file when you need rules beyond this quick reference.

### `references/style-guide.md` — Full Style Guide

When to read: detailed formatting and line-wrapping rules, naming conventions with examples, documentation comment standards, file organization patterns, access control guidelines, pattern matching rules, trailing closure conventions, delegate naming, `self` usage, optional handling, attribute ordering, and performance coding practices.

### Swift 6.x Feature References (version-split)

Read the file matching the target Swift version. Each file instructs to also read lower-version files.

- **`references/swift-6_0.md`** — Data race safety, typed throws, noncopyable types, import access control
- **`references/swift-6_1.md`** — `nonisolated` on types, TaskGroup inference, trailing comma expansion
- **`references/swift-6_2.md`** — Default MainActor, `@concurrent`, InlineArray, Span, `@nonexhaustive` (6.2.3), strict memory safety
- **`references/swift-6_3.md`** — `@c` interop, module selectors `::`, `weak let`, `@specialized`, `@inline(always)`, `@export`
- **`references/swift-6_4.md`** — **Unreleased preview** (async defer, borrow/mutate accessors, `~Sendable`, `@diagnose`). Read to know what's coming — not for code targeting stable toolchains.

### `references/swift-migration.md` — Migration & Best Practices

When to read: migrating to Swift 6 language mode, deciding which modern patterns to adopt/avoid, understanding breaking changes across versions.

### `references/official-packages.md` — Official Swift Packages

When to read: choosing the right data structure (Collections), applying sequence/collection algorithms (Algorithms), working with async streams (Async Algorithms), or doing numerical computing (Numerics). These are official Apple-maintained packages that may eventually graduate to the standard library.

### `references/spm.md` — Swift Package Manager

When to read: writing Package.swift, managing dependencies (version requirements, local/binary targets, traits), resource bundling, build settings (swiftSettings/cSettings), mixed C/ObjC targets, plugins, module aliasing, package security (signing/TOFU), version-specific packaging.

### `references/server/` — Server-Side Swift (Vapor, Fluent, SwiftNIO, SSWG ecosystem)

Server-side Swift used to be a separate skill; it lives here now so that one skill covers all Swift work. Reach for this directory when `Package.swift` depends on vapor, fluent, swift-nio, or SSWG packages, when code imports `Vapor`, `Fluent`, `NIO*`, or `AsyncHTTPClient`, or when the discussion is about server architecture (routing, middleware, ORM, deployment).

- **`references/server/overview.md`** — Start here for any Vapor/NIO project: Package.swift template and folder layout, core architectural principles (never block an EventLoop, async/await over EventLoopFuture, request lifecycle, content negotiation), EventLoop ↔ async/await bridging, Vapor-specific Swift 6 migration notes, critical gotchas table, package version table.
- **`references/server/vapor.md`** — Routing, controllers, middleware (incl. TracingMiddleware), Fluent ORM & migrations, authentication, HTTP client, WebSocket, sessions, validation, content system, environment, error handling, server configuration, testing, Files API (streaming), Docker deployment. Read when writing or modifying Vapor application code.
- **`references/server/vapor-extras.md`** — Queues (job system), JWT, APNS, Leaf templating, Redis, custom commands, Services/DI. Read when integrating these Vapor add-on packages.
- **`references/server/swiftnio.md`** — EventLoop, Channel, ChannelHandler, ChannelPipeline, Bootstrap, ByteBuffer, NIOAsyncChannel, Swift Concurrency bridging. Read when working at the NIO layer or debugging concurrency/performance issues.
- **`references/server/ecosystem.md`** — swift-log, swift-metrics, swift-distributed-tracing, swift-service-lifecycle, AsyncHTTPClient, gRPC Swift 2, Swift OpenAPI Generator. Read when integrating observability, service lifecycle, or these libraries — CLI tools and daemons use them as much as servers do, so read it even when no web framework is involved.

## Upstream Sources

The reference files in this skill are derived from the sources below. Consult them when information is insufficient or freshness is uncertain. Also use these sources when updating reference files.

- **Swift language changes**: [CHANGELOG.md](https://github.com/swiftlang/swift/blob/main/CHANGELOG.md), [Swift Evolution](https://www.swift.org/swift-evolution/)
- **Swift official docs**: [swift.org/documentation](https://www.swift.org/documentation/)
- **Swift blog**: [swift.org/blog](https://www.swift.org/blog/) — covers language changes, official packages, and ecosystem news
- **Apple developer docs / WWDC**: search via the sosumi skill
- **Official & server ecosystem packages**: each package's repository README or [Swift Package Index](https://swiftpackageindex.com)
- **Vapor**: [docs.vapor.codes](https://docs.vapor.codes), [api.vapor.codes](https://api.vapor.codes)
- **Server-side Swift overview**: [swift.org/documentation/server](https://www.swift.org/documentation/server/)
