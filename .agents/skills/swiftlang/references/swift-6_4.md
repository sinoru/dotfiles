# Swift 6.4 Features (Preview)

**Not yet released** as of 2026-08-29. In development on `release/6.4.x` (nightly snapshots via `swiftly install 6.4.x-snapshot`); expected to ship in the fall 2026 Xcode cycle. Do not use these features in code that must build on a stable toolchain — and do not present them as available when reviewing code targeting 6.3 or earlier.

> Also read: `references/swift-6_0.md` through `references/swift-6_3.md` for released features.

---

## Language (Implemented in 6.4 branch)

### Async Defer — SE-0493

`defer` blocks can contain `await` inside async functions:

```swift
func processFile() async throws {
    let handle = try await openFile()
    defer { await handle.close() }  // Awaited at scope exit
    // ...
}
```

### Borrow and Mutate Accessors — SE-0507

New `borrow` / `mutate` accessor keywords for copy-free property access; works with noncopyable values. (This is the shipped successor to the never-released "yielding accessors" experiment, SE-0474.)

### Explicit Sendable Suppression — SE-0518

`~Sendable` on a type declaration suppresses implicit `Sendable` inference — for types that are structurally Sendable but semantically not.

### Optional Sugar for `some` / `any` — SE-0521

`some P?` and `any P?` now parse without parentheses (previously `(some P)?`).

### @diagnose — SE-0522

Per-declaration control of diagnostics — ignore/warn/error for e.g. deprecations or strict-memory-safety findings, scoped to one declaration instead of a whole-module flag.

### Memberwise Initializer Variant — SE-0502

Structs get a second memberwise initializer that excludes `private` properties with default values.

### anyAppleOS Availability

`@available(anyAppleOS 26.0, *)` and `#if os(anyAppleOS)` shorthand covering all Apple platforms at once (compiler change, no SE proposal).

## Concurrency

- **Task Cancellation Shields — SE-0504**: `withTaskCancellationShield { }` protects a critical section from cooperative cancellation.
- **Discarded throwing Task warning — SE-0520**: creating a throwing `Task` and never reading its `value`/`result` now warns — silent error-swallowing becomes visible. Likely the most widely felt change when 6.4 lands.
- **Noncopyable `Continuation` — SE-0528**: compile-time enforcement of single resume for unsafe continuations.
- **Async `Result` — SE-0530**: `Result` initializers/accessors work with async throwing closures.

## Type System & Stdlib

- **`Ref` / `MutableRef` — SE-0519**: safe first-class borrows of a single value.
- **`Equatable`/`Comparable`/`Hashable` for `~Copyable`/`~Escapable` — SE-0499**.
- **`UniqueArray` — SE-0527**: noncopyable array in the stdlib.
- **`withTemporaryAllocation` — SE-0524** using `OutputSpan`/`OutputRawSpan`; **safe `RawSpan` loading — SE-0525**.
- **`isTriviallyIdentical(to:)` — SE-0494**: fast identity check for CoW types.
- **`demangle` — SE-0498** in the Runtime module; **advanced Observation tracking — SE-0506**; **trailing closures after array literals — SE-0508**.

## Accepted, landing in the 6.4 cycle

`Iterable` protocol for borrowing for-loops (SE-0516), `UniqueBox` (SE-0517), stdlib `FilePath` (SE-0529), `Dictionary.mapKeyedValues` (SE-0510), `withDeadline` absolute-time timeouts (SE-0526), noncopyable/nonescapable associated types (SE-0503).

## Tooling & Ecosystem (6.4 cycle)

- **Swift Build becomes the default SwiftPM build engine** (was preview in 6.3)
- **Swift Testing ↔ XCTest interop**: assertions cross-report between frameworks; `swift test` gains repeat-until-pass/fail
- **SwiftPM**: SBOM generation (SE-0509), add-target plugin (SE-0511)
- **Subprocess 1.0** source-stable; Foundation `ProgressManager`; unified Swift NSURL/CFURL implementation
- **Embedded Swift**: existentials, untyped throws, DWARF-based coredump debugging

Breaking changes by version: see `references/swift-migration.md`.
