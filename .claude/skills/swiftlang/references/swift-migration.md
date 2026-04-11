# Swift Migration & Best Practices

Cross-version migration guidance, patterns to adopt, patterns to avoid, and a complete breaking changes reference.

---

## Migration to Swift 6 Language Mode

### Step-by-Step

1. **Audit phase**: Enable `-strict-concurrency=complete` in Swift 5 mode. Fix all warnings.
2. **Module-by-module**: Switch individual targets to Swift 6 language mode. Leaf modules first, then work inward.
3. **Use `swift package migrate`** (6.2+) for automated fixes: `swift package migrate --to-feature ExistentialAny`
4. **Common fixes**:
   - Add `Sendable` conformance or use `sending` (SE-0430) for cross-isolation values
   - Use `@MainActor` or `nonisolated` to make isolation explicit
   - Replace `DispatchQueue.main.async` with `@MainActor` functions
   - Wrap mutable shared state in `actor` or use `Mutex` / `Atomic`

### Concurrency Model Evolution

| Version | Default behavior of `nonisolated async` | How to run on background |
|---|---|---|
| 5.5–6.1 | Hops to global concurrent executor | Already the default |
| 6.2+ | Stays on caller's executor | Use `@concurrent` |

This is the most impactful behavioral change. Any `nonisolated async` function doing CPU-heavy work that relied on implicit background execution needs `@concurrent` added.

---

## Patterns to Adopt

### Concurrency

1. **Swift 6 language mode** — Enable per-module for data race safety
2. **Module-level `defaultIsolation`** (6.2+) — `MainActor` as default for app targets eliminates boilerplate
3. **`@concurrent` for parallel work** (6.2+) — Required since nonisolated async stays on caller's executor
4. **`Task.immediate`** (6.2+) — Avoid scheduling overhead when isolation is compatible
5. **`async defer`** (6.3+) — Clean resource cleanup in async contexts

### Type System & Safety

6. **Typed throws** (6.0+) — `throws(MyError)` for public API error contracts
7. **`InlineArray` / `[N of Element]`** (6.2+) — Stack allocation for fixed-size buffers
8. **`Span` over `UnsafeBufferPointer`** (6.2+) — Safe memory access with lifetime enforcement
9. **`@nonexhaustive` on library enums** (6.3+) — Plan for extensibility in public API
10. **Swift Testing** (6.0+) — Prefer `@Test` / `#expect` over XCTest for new test code

### Interop & Modules

11. **`internal import`** (6.0+) — Hide implementation dependencies. Future-proofs against default change.
12. **`@c` for C interop** (6.3+) — Official attribute replacing `@_cdecl`
13. **Module selectors `::`** (6.3+) — Cleaner than typealiases for disambiguation

### Performance

14. **`@inline(always)`** (6.3+) — Guaranteed inlining (was hint-only)
15. **`@export(implementation)`** (6.3+) — Replaces `@_alwaysEmitIntoClient`

---

## Patterns to Avoid

| Pattern | Replacement | Since |
|---|---|---|
| `@_cdecl` | `@c` | 6.3 |
| `@_alwaysEmitIntoClient` | `@export(implementation)` | 6.3 |
| Property wrapper actor isolation inference | Explicit `@MainActor` | 6.0 |
| Assuming nonisolated async runs on background | `@concurrent` | 6.2 |
| `withTaskGroup(of: Type.self)` | Omit — type inference | 6.1 |
| `UnsafeBufferPointer` for new code | `Span` / `MutableSpan` | 6.2 |
| `rethrows` | Typed throws `throws(E)` | 6.0 |
| Relying on transitive imports | Direct imports (SE-0444) | 6.1 |

---

## Breaking Changes by Version

### Swift 6.0

| Change | Impact |
|---|---|
| Data race safety enforced | Concurrency warnings → errors in Swift 6 mode |
| Property wrapper actor isolation removed (SE-0401) | `@Published` no longer implies `@MainActor` |
| `@Sendable` on non-Sendable type methods disallowed (SE-0418) | Compile error |
| Closure parameter syntax (type-only, no name) rejected | Was warned since 5.2 |

### Swift 6.1

| Change | Impact |
|---|---|
| `any` enforcement downgraded to warning | Re-escalate with `-Werror ExistentialAny` |

### Swift 6.2

| Change | Impact |
|---|---|
| Nonisolated async default changed (SE-0461) | Background execution requires explicit `@concurrent` |
| Unavailability diagnostics relaxed | May cause new overload resolution ambiguities |

### Swift 6.3

| Change | Impact |
|---|---|
| `@nonexhaustive` enum | External switch statements need `@unknown default` |
