# Swift 6.0 Features

Released 2024-09-17. The foundational Swift 6 release — data race safety and major type system enhancements.

---

## Data Race Safety (flagship feature)

The Swift 6 language mode enforces compile-time data race safety. Concurrency bugs that were warnings in 5.10 become errors.

- Opt-in per module — not all-or-nothing across a project
- Enable with `-strict-concurrency=complete` first to see warnings, then switch to Swift 6 mode
- Region-based isolation (SE-0414) dramatically reduces false positives from the Sendable checker

### Key Concurrency Proposals

| SE | Feature | Description |
|---|---|---|
| SE-0414 | Region-Based Isolation | Compiler proves non-Sendable values can safely cross isolation boundaries when nothing else references them post-send |
| SE-0418 | Automatic Sendable Inference | Auto-applies `Sendable` to functions and key-path literals. `@Sendable` on instance methods of non-Sendable types is now disallowed |
| SE-0420 | Caller Isolation Inheritance | `isolated (any Actor)? = #isolation` parameter eliminates unwanted scheduling changes |
| SE-0423 | `@preconcurrency` Conformance | Dynamic isolation checks for synchronous nonisolated protocol requirement witnesses |
| SE-0424 | `checkIsolation()` | Custom executor isolation detection |
| SE-0430 | `sending` Annotation | Mark parameters/results as disconnected at function boundaries for safe cross-isolation transfer |
| SE-0431 | `@isolated(any)` Functions | Function values carry dynamic actor isolation via `.isolation` property |
| SE-0417 | Task Executor Preference | `withTaskExecutorPreference` for custom executor fallback |

### Synchronization Library

Low-level concurrency primitives: `Atomic`, `Mutex`. Use when structured concurrency patterns don't fit (lock-free data structures, bridging legacy code).

---

## Type System

### Typed Throws — SE-0413

```swift
func parse(_ input: String) throws(ParseError) -> AST { ... }
```

- `throws` = `throws(any Error)`, non-throwing = `throws(Never)`
- Enables precise generic error propagation — more expressive than `rethrows`

### Noncopyable Types

- `~Copyable` suppression on protocols, generics, existentials (SE-0427)
- Pattern matching on noncopyable enums without consuming (SE-0432)
- Individual field consumption of noncopyable structs (SE-0429)

### Pack Iteration — SE-0408

Iterate over value parameter packs with `for`-in syntax. Elements are evaluated on demand.

### Opening Existentials — SE-0352

In Swift 6 mode, existential values (e.g., `any Error`) passed to generic functions are automatically opened.

### 128-bit Integers

`Int128`, `UInt128` available on all platforms.

---

## Interop & Modules

### Import Access Control — SE-0409

```swift
public import Foundation       // Re-exported to consumers
internal import ImplementationDetail  // Hidden
```

Default is currently `public` but will change to `internal`. Add explicit `internal import` now to future-proof.

---

## Standard Library

- `count(where:)` — count elements matching a predicate
- `RangeSet<Bound>` — discontiguous index sets (SE-0270): `indices(where:)`, `moveSubranges`, subscript access
- `@TaskLocal` reimplemented as macro — task locals can be declared as global properties

---

## Swift Testing Framework

Built into the Swift 6 toolchain:

```swift
@Test("User can log in")
func login() async throws {
    let user = try await AuthService.login(email: "test@example.com", password: "valid")
    #expect(user.isAuthenticated)
}
```

- `@Test` / `@Suite` for declaration — no `XCTest` subclassing needed
- `#expect` / `#require` for assertions with rich failure messages

---

## Embedded Swift (preview)

Language subset for ARM and RISC-V bare-metal microcontrollers.

## Foundation

Fully rewritten in Swift — unified cross-platform. `FoundationEssentials` for lightweight use.

## Breaking Changes

- Data race safety enforced in Swift 6 mode (warnings → errors)
- Property wrapper actor isolation inference removed (SE-0401): `@Published` no longer implies `@MainActor`
- `@Sendable` on instance methods of non-Sendable types disallowed (SE-0418)
- Closure parameter syntax with only a type and no name rejected
