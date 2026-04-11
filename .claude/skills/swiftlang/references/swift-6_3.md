# Swift 6.3 Features

Released 2026-03-24. C interop, module disambiguation, performance control, and ecosystem expansion.

> Also read: `references/swift-6_0.md`, `references/swift-6_1.md`, and `references/swift-6_2.md` for prior features.

---

## C Interop

### @c Attribute — SE-0495

Official replacement for `@_cdecl`. Expose Swift functions and enums to C:

```swift
@c
func processBuffer(_ ptr: UnsafePointer<UInt8>, _ count: Int) -> Int32 {
    // Appears in generated C header
}

@c("custom_name")
func swiftImplementation() { ... }

// Implement a function declared in a C header:
@c @implementation
func existing_c_function() { ... }

// C-compatible enum:
@c enum Color: Int32 { case red, green, blue }
```

---

## Modules

### Module Selectors — SE-0491

Resolve name conflicts with `::` syntax:

```swift
import ModuleA
import ModuleB

let a = ModuleA::getValue()
let b = ModuleB::getValue()
```

Also resolves local shadowing. Works within macros.

### Swift Namespace Qualification

`Swift.Task`, `Swift.Regex` etc. — concurrency and string processing types can be qualified with `Swift.` prefix instead of `_Concurrency`/`_StringProcessing`.

---

## Language

### @nonexhaustive Enum — SE-0487

Mark a public enum as extensible in non-resilient libraries:

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

Use `@nonexhaustive(warn)` for gradual adoption.

### Async Defer — SE-0493

`defer` blocks can now contain `await`:

```swift
func processFile() async throws {
    let handle = try await openFile()
    defer { await handle.close() }  // Implicitly awaited at scope exit
    // ...
}
```

Only available inside async functions.

### @section / @used — SE-0492

Place global/static variables in specific binary sections:

```swift
@section("__DATA,plugins")
@used
static let registration = PluginInfo(name: "MyPlugin")
```

Use `#if objectFormat(ELF)` / `#if objectFormat(MachO)` for platform-specific section names. Useful for runtime test discovery, plugin systems, embedded.

---

## Performance Attributes

### @inline(always) Guarantee — SE-0496

Now guarantees inlining for direct calls (was hint-only). Compile error if impossible. Implicitly requires `@inlinable` for public functions.

### @export — SE-0497

Controls how a function's implementation is shared:

- `@export(implementation)` — emit definition into client (enables inlining/specialization, no symbol). Replaces `@_alwaysEmitIntoClient`.
- `@export(interface)` — generate symbol only, hide definition.

---

## Testing

- **Warning issues**: `Issue.record()` with severity parameter
- **Test cancellation**: `try Test.cancel()` for test and task hierarchy
- **Image attachments**: Cross-platform on Apple and Windows

## Build & Tooling

- **Swift Build** (preview): Unified cross-platform build engine integrated into SwiftPM (open-sourced from Xcode's internal engine)
- **DocC**: Markdown output generation, static HTML (`<noscript>` for SEO), code block annotations (`nocopy`, `highlight`, `showLineNumbers`, `wrap`)
- `swift package show-traits` command

## Platform

- **Android**: First official Swift SDK for Android. Swift Java / Swift Java JNI Core libraries.
- **Embedded Swift**: Enhanced C interop, improved debugging

## Breaking Changes

- `@nonexhaustive` enum requires `@unknown default` in external switch statements
