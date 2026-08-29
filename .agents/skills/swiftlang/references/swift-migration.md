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

The adoption checklist lives in SKILL.md ("Swift 6.x Key Patterns") — it is always in context, so it is not repeated here. Per-feature detail is in the matching `swift-6_x.md` file. Two adoption notes that only matter during migration:

- **Swift Testing** (6.0+): prefer `@Test` / `#expect` for new test code; migrate XCTest suites opportunistically, not as a big-bang rewrite.
- **`Task.immediate`** (6.2+): when replacing `DispatchQueue.main.async` hops, this avoids re-introducing scheduling latency.

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
| `@nonexhaustive` enum (SE-0487, shipped in 6.2.3) | External switch statements over an enum so marked need `@unknown default` |

### Swift 6.3

No major source-breaking changes. Deprecated spellings replaced (`@_cdecl` → `@c`, `@_alwaysEmitIntoClient` → `@export(implementation)`); the old underscored forms still compile.

### Swift 6.4 (in development — not yet released)

Expect a new warning for silently discarded results/errors of throwing `Task`s (SE-0520). See `references/swift-6_4.md` for the full preview.
