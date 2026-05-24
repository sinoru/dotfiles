# Combine & Reactive Patterns Reference

## 현재 상태

Combine은 **사실상 유지보수 모드**. 공식 deprecated는 아니지만 WWDC 2022 이후 새 세션이나 API 추가가 없다.
Apple의 투자는 Swift Concurrency(`async/await`, `AsyncSequence`, `@Observable`)로 완전히 이동.

핵심 시그널:
- WWDC 2023: `@Observable` 매크로 도입 → `ObservableObject` + `@Published`(Combine 기반)의 주요 사용처 대체
- Swift Async Algorithms 패키지: `debounce`, `throttle`, `merge`, `combineLatest` 등 Combine 핵심 operator의 async 버전 제공
- Combine은 Swift 6 strict concurrency annotation을 받지 못함

## 언제 Combine을 쓸까

- **iOS 13-14 / macOS 10.15-11** 타겟 (AsyncSequence는 iOS 15+)
- **명시적 back-pressure**가 필요한 복잡한 스트림 조합
- **기존 대규모 Combine 코드베이스** — 마이그레이션 비용 > 이점
- **SwiftUI `onReceive`** — 여전히 Combine `Publisher` 필요
- **`switchToLatest`, `share`/`multicast`, `buffer` 정책** — async 대응 없음

## 언제 AsyncSequence를 쓸까

- **새 프로젝트 (iOS 15+ / macOS 12+)** — async/await가 기본
- **SwiftUI + `@Observable` (iOS 17+)** — Combine 불필요
- **`.task { }` 수정자** — 뷰 라이프사이클 연동 async
- **서버 사이드 Swift** — Combine은 Apple 전용, AsyncSequence는 표준 라이브러리

## Migration Patterns

### Publisher → AsyncSequence (.values)

```swift
// Failure == Never인 Publisher
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

### @Observable이 ObservableObject를 대체

```swift
// 이전: Combine 기반
class Library: ObservableObject {
    @Published var books: [Book] = []
}
// @StateObject, @ObservedObject, @EnvironmentObject 사용

// 이후: Combine 불필요
@Observable class Library {
    var books: [Book] = []
}
// @State, plain property, @Environment(Type.self) 사용
```

주의: `@Observable`에서 `$` 접두사는 Combine `Publisher`가 아니라 SwiftUI `Binding`을 생성.
`.debounce` 같은 Combine 체이닝 불가 — Swift Async Algorithms 또는 `Task` 기반 debounce 사용.

## Operator 대응표

| Combine | Async 대응 | 출처 |
|---------|-----------|------|
| `map`, `compactMap`, `filter`, `flatMap` | 동명 메서드 | stdlib |
| `reduce`, `first(where:)`, `prefix`, `dropFirst` | 동명 메서드 | stdlib |
| `debounce`, `throttle` | `debounce(for:clock:)`, `throttle(for:clock:)` | swift-async-algorithms |
| `merge`, `combineLatest`, `zip` | `merge`, `combineLatest`, `zip` | swift-async-algorithms |
| `removeDuplicates` | `removeDuplicates` | swift-async-algorithms |
| `Timer.publish` | `AsyncTimerSequence` | swift-async-algorithms |
| `sink` | `for await` 루프 | — |
| `assign(to:)` | `for await` 안에서 직접 할당 | — |
| `receive(on: .main)` | `@MainActor` 격리 | — |
| `scan`, `switchToLatest`, `share`/`multicast` | **대응 없음** | — |

## SwiftUI와의 통합

- **iOS 17+**: `@Observable` + `@State`로 Combine 없이 데이터 흐름 완성
- **`onReceive`**: Combine Publisher를 뷰에서 소비하는 유일한 방법 (여전히 유효)
  ```swift
  .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
      refreshData()
  }
  ```
- **`.task(id:)`로 debounce 대체**:
  ```swift
  .task(id: searchQuery) {
      try? await Task.sleep(for: .milliseconds(300))
      await search(query: searchQuery)
  }
  ```

## 요약

새 코드는 `async/await` + `@Observable`. Combine은 `.values`로 점진적 마이그레이션.
고유 기능(`switchToLatest`, back-pressure, `onReceive`)이 필요할 때만 Combine 유지.
