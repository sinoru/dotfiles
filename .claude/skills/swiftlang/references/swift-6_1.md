# Swift 6.1 Features

Released 2025-03-31. Incremental refinements to concurrency, Objective-C interop, and developer ergonomics.

> Also read: `references/swift-6_0.md` for foundational Swift 6 features.

---

## Concurrency

### Nonisolated on Types/Extensions — SE-0449

Apply `nonisolated` to an entire type or extension to prevent global actor isolation inheritance:

```swift
nonisolated struct DataProcessor: GloballyIsolatedProtocol {
    // All members are nonisolated — no need to mark each one
}
```

### TaskGroup Type Inference — SE-0442

`ChildTaskResult` type inferred from the closure body:

```swift
// Before: withTaskGroup(of: Message.self) { group in ... }
await withTaskGroup { group in
    group.addTask { await fetchMessage() }
}
```

---

## Objective-C Interop

### @implementation Attribute — SE-0436

Swift extensions can replace Objective-C `@implementation` blocks, enabling category-by-category migration:

```swift
@implementation extension MyObjCClass {
    // Replaces the Objective-C implementation
}
```

---

## Syntax

### Trailing Comma Expansion

Trailing commas now allowed in tuples, parameter/argument lists, generic parameters, closure capture lists, and string interpolations — not just collection literals.

### Member Import Visibility — SE-0444

Upcoming feature `MemberImportVisibility` requires direct imports for all used modules — prevents reliance on transitive imports. Start adding direct imports now to prepare.

---

## Testing

- **`TestScoping` protocol**: Custom test traits for setup/teardown logic
- `#expect(throws:)`, `#require(throws:)`: Return caught error for inspection

## Tooling

- **SwiftPM Package Traits**: Environment-specific API via `.trait(name:)`
- **Background Indexing**: SourceKit-LSP default for SwiftPM projects

## Breaking Changes

- `any` enforcement (SE-0335 / `ExistentialAny`) downgraded from error to warning. Re-escalate with `-Werror ExistentialAny`.
