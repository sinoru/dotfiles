# Combine & Reactive Patterns Reference

## Current Status

Combine is **effectively in maintenance mode**. It is not officially deprecated, but there have been no new sessions or API additions since WWDC 2022.
Apple's investment has fully shifted to Swift Concurrency (`async/await`, `AsyncSequence`, `@Observable`).

Key signals:
- WWDC 2023: `@Observable` macro introduced → replaces the main use case of `ObservableObject` + `@Published` (Combine-based)
- Swift Async Algorithms package: provides async versions of Combine's core operators — `debounce`, `throttle`, `merge`, `combineLatest`, etc.
- Combine does not receive Swift 6 strict concurrency annotations

## When to Use Combine

- **iOS 13-14 / macOS 10.15-11** targets (AsyncSequence is iOS 15+)
- Complex stream composition requiring **explicit back-pressure**
- **Existing large-scale Combine codebases** — migration cost > benefit
- **SwiftUI `onReceive`** — still requires a Combine `Publisher`
- **`switchToLatest`, `share`/`multicast`, `buffer` policies** — no async equivalent

## When to Use AsyncSequence

- **New projects (iOS 15+ / macOS 12+)** — async/await is the default
- **SwiftUI + `@Observable` (iOS 17+)** — Combine unnecessary
- **`.task { }` modifier** — async tied to view lifecycle
- **Server-side Swift** — Combine is Apple-only, AsyncSequence is part of the standard library

## Migration Patterns

### Publisher → AsyncSequence (.values)

```swift
// Publisher where Failure == Never
for await value in publisher.values {
    process(value)
}
// throwing publisher
for try await data in throwingPublisher.values { ... }
```

### async → Publisher (Future)

```swift
let publisher = Future<Data, Error> { promise in
    Task {
        do { promise(.success(try await fetchData())) }
        catch { promise(.failure(error)) }
    }
}
```

### @Observable Replaces ObservableObject

```swift
// Before: Combine-based
class Library: ObservableObject {
    @Published var books: [Book] = []
}
// Use @StateObject, @ObservedObject, @EnvironmentObject

// After: Combine unnecessary
@Observable class Library {
    var books: [Book] = []
}
// Use @State, plain property, @Environment(Type.self)
```

Note: with `@Observable`, the `$` prefix produces a SwiftUI `Binding`, not a Combine `Publisher`.
Combine chaining like `.debounce` is not possible — use Swift Async Algorithms or a `Task`-based debounce.

## Operator Mapping

| Combine | Async Equivalent | Source |
|---------|-----------|------|
| `map`, `compactMap`, `filter`, `flatMap` | Same-named methods | stdlib |
| `reduce`, `first(where:)`, `prefix`, `dropFirst` | Same-named methods | stdlib |
| `debounce`, `throttle` | `debounce(for:clock:)`, `throttle(for:clock:)` | swift-async-algorithms |
| `merge`, `combineLatest`, `zip` | `merge`, `combineLatest`, `zip` | swift-async-algorithms |
| `removeDuplicates` | `removeDuplicates` | swift-async-algorithms |
| `Timer.publish` | `AsyncTimerSequence` | swift-async-algorithms |
| `sink` | `for await` loop | — |
| `assign(to:)` | Direct assignment inside `for await` | — |
| `receive(on: .main)` | `@MainActor` isolation | — |
| `scan`, `switchToLatest`, `share`/`multicast` | **No equivalent** | — |

## Integration with SwiftUI

- **iOS 17+**: `@Observable` + `@State` completes data flow without Combine
- **`onReceive`**: the only way to consume a Combine Publisher from a view (still valid)
  ```swift
  .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
      refreshData()
  }
  ```
- **Replacing debounce with `.task(id:)`**:
  ```swift
  .task(id: searchQuery) {
      try? await Task.sleep(for: .milliseconds(300))
      await search(query: searchQuery)
  }
  ```

## Summary

New code should use `async/await` + `@Observable`. Migrate Combine incrementally via `.values`.
Keep Combine only when a unique capability (`switchToLatest`, back-pressure, `onReceive`) is needed.
