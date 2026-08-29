# Swift 6.2 Features

Released 2025-09-15. Major concurrency simplification and systems programming enhancements.

> Also read: `references/swift-6_0.md` and `references/swift-6_1.md` for prior features.

---

## Concurrency Model Overhaul

### Default MainActor Isolation — SE-0466

Set an entire module's default isolation to `@MainActor`:

```swift
// Package.swift
.target(name: "MyApp", swiftSettings: [.defaultIsolation(MainActor.self)])
```

Eliminates boilerplate `@MainActor` annotations for app targets.

### Nonisolated Nonsending — SE-0461

**Behavioral change**: `nonisolated async` functions now stay on the caller's executor instead of hopping to the global concurrent executor.

```swift
// Before 6.2: this hopped off MainActor to global executor
// After 6.2: this stays on caller's executor
nonisolated func processData() async -> Result { ... }

// When you actually need parallel execution:
@concurrent
func heavyComputation() async -> Result { ... }
```

Enable via upcoming feature `NonisolatedNonsendingByDefault` or per-function `nonisolated(nonsending)`. This is the most significant behavioral change — review any `nonisolated async` function that assumes background execution.

### @concurrent — SE-0461

Explicitly opt an async function into parallel execution on the global executor. Required when you need work off the caller's isolation domain.

### Isolated Conformances — SE-0470

Protocol conformances valid only within a specific actor's domain:

```swift
@MainActor class ViewModel: @MainActor Equatable { ... }
```

### Isolated Deinit — SE-0471

`actor` and `@MainActor` types can declare `isolated deinit` to safely access isolated state during deinitialization.

### Task Improvements

| SE | Feature | Description |
|---|---|---|
| SE-0472 | `Task.immediate` | Run immediately in caller's context — no scheduling overhead |
| SE-0469 | Task Naming | `Task("Fetch user \(id)") { ... }` for debugging |
| SE-0462 | Priority Escalation | Explicit API + `withTaskPriorityEscalationHandler` |

---

## Systems Programming

### InlineArray — SE-0453, SE-0483

Fixed-size, stack-allocated array:

```swift
var buffer: InlineArray<4, UInt8> = [0, 0, 0, 0]
var sprites: [40 of Sprite] = ...  // Sugar syntax
```

No heap allocation. Ideal for embedded, performance-critical, or fixed-size buffers.

### Span / MutableSpan — SE-0446, SE-0467

Safe contiguous memory views — the safe replacement for `UnsafeBufferPointer`. Non-escapable (`~Escapable`) — compiler prevents dangling references.

---

## API Evolution

### @nonexhaustive Enum — SE-0487 (6.2.3)

Mark a public enum as extensible in non-resilient libraries (shipped in the 6.2.3 patch release):

```swift
@nonexhaustive
public enum ConnectionState {
    case connecting, connected, disconnected
}

// External code must handle unknown future cases:
switch state {
case .connecting: ...
case .connected: ...
case .disconnected: ...
@unknown default: ...
}
```

Use `@nonexhaustive(warn)` for gradual adoption — external exhaustive switches get a warning instead of an error.

---

## Safety & Diagnostics

### Strict Memory Safety — SE-0458

Opt-in `-strict-memory-safety`. Compiler warns on unsafe constructs. Suppress with `unsafe` expression:

```swift
return unsafe Int(bitPattern: malloc(size))
```

### Runtime Module — SE-0419

`import Runtime` provides `Backtrace.capture()` and `.symbolicated()` for programmatic stack traces.

---

## Syntax

### Raw Identifiers — SE-0451

```swift
@Test func `square returns x * x`() { ... }
```

Backtick-delimited identifiers allow any characters. Useful for descriptive test names and code generation.

---

## Standard Library & Frameworks

- **`Subprocess`** package: Concurrency-friendly external process management (preview at 6.2 release; now source-stable at 1.0)
- **Foundation NotificationCenter**: Type-safe API replacing string-based notifications
- **Observation**: `Observations` async sequence with transactional batching

## Testing

- **Exit testing**: Verify process termination conditions in separate processes
- **Attachments**: Strings, images, logs attached to test results

## Tooling

- **`swift package migrate`** (SE-0486): `swift package migrate --to-feature ExistentialAny`
- **SwiftPM Warning Control**: `treatWarning`, `treatAllWarnings` per target
- **VS Code Extension**: Official SourceKit-LSP with background indexing and live DocC
- **LLDB**: Async stepping, task context visibility, named tasks

## Platform

- **WebAssembly**: Full support for browser and server
- **Embedded Swift**: Complete String API, `any` types, InlineArray, Span

Breaking changes by version: see `references/swift-migration.md`.
