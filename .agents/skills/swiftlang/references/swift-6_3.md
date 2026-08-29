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

### weak let — SE-0481

Weak references can now be `let` constants — the *reference* is immutable even though the referent may still be deallocated. This unblocks `Sendable` conformance for classes with weak stored properties and makes explicit `weak` closure captures immutable like every other capture:

```swift
final class Observer: Sendable {
    weak let target: Target?   // OK in 6.3 — was forced to be `var` before
}
```

### Clock Epochs — SE-0473

`ContinuousClock` and `SuspendingClock` gain a `systemEpoch` property — the system-specific "zero" instant (set at boot on most platforms). Enables uptime-style measurements and cross-process correlation on the same machine:

```swift
let uptime = ContinuousClock().now - ContinuousClock().systemEpoch
```

### Codable Error Descriptions — SE-0489

`EncodingError` and `DecodingError` now conform to `CustomDebugStringConvertible` — printed decoding failures are human-readable (coding path, type, context) instead of the old nested-enum dump. No code change needed; stop writing custom Codable-error formatters.

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

Now guarantees inlining for direct calls (was hint-only). Compile error if impossible. Implies `@inlinable` for `public`/`package` functions (not for `internal` and below).

### @specialized — SE-0460

Pre-generate specializations of a generic function for concrete types; the unspecialized entry point re-dispatches to them at runtime. Use for hot generic code whose call sites the optimizer can't see:

```swift
@specialized(where T == Int)
@specialized(where T == Double)
func sum<T: BinaryInteger>(_ values: [T]) -> T { ... }
```

Note the spelling is `@specialized` (the release blog's `@specialize` is a typo).

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

Breaking changes by version: see `references/swift-migration.md`.
