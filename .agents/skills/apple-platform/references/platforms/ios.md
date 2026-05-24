# iOS Platform Reference

## Table of Contents
1. [Scene 기반 라이프사이클](#scene-기반-라이프사이클)
2. [iPad 멀티태스킹](#ipad-멀티태스킹)
3. [WidgetKit](#widgetkit)
4. [Live Activities / ActivityKit](#live-activities--activitykit)
5. [App Intents](#app-intents)
6. [StoreKit 2](#storekit-2)
7. [백그라운드 처리](#백그라운드-처리)
8. [푸시 알림](#푸시-알림)
9. [TipKit](#tipkit)

---

## Scene 기반 라이프사이클

### UISceneDelegate (iOS 13+, iOS 27 필수)

```
willConnectTo → willEnterForeground → didBecomeActive
                                       ↕
didEnterBackground ← willResignActive ← didDisconnect
```

- `sceneDidEnterBackground`: 데이터 저장, 카메라/공유 하드웨어 해제, 민감 정보 숨김
- UIKit이 앱 스위처용 UI 스냅샷 캡처 — alert/임시 인터페이스 먼저 dismiss

### iOS 26 변경

- `UIWindow(windowScene:)` 외 모든 init deprecated
- 레거시 `UIApplicationDelegate` 콜백 deprecated
- iOS 27에서 scene lifecycle 필수화

---

## iPad 멀티태스킹

- `UIApplicationSupportsMultipleScenes` (Info.plist) — 멀티 윈도우 활성화
- `UISceneSizeRestrictions` — 최소/최대 윈도우 크기
- Stage Manager: `UIWindowScene` geometry preferences 사용
- iPadOS 18: `UITab` / `UITabGroup` — 탭바 + 사이드바 결합

---

## WidgetKit

### Timeline Provider

```swift
struct MyProvider: AppIntentTimelineProvider {
    func snapshot(for configuration: MyIntent, in context: Context) async -> MyEntry { ... }
    func timeline(for configuration: MyIntent, in context: Context) async -> Timeline<MyEntry> {
        Timeline(entries: entries, policy: .atEnd)
    }
}
```

- 새 위젯은 `AppIntentTimelineProvider` 사용 (`IntentTimelineProvider`는 레거시)
- 갱신 예산: 24시간당 40-70회. 포그라운드 앱/오디오/네비게이션 세션은 예산 면제.

### Widget Families

시스템: `systemSmall`, `systemMedium`, `systemLarge`, `systemExtraLarge`
잠금화면/워치: `accessoryCircular`, `accessoryRectangular`, `accessoryInline`, `accessoryCorner`

### Interactive Widgets (iOS 17+)

`Button`과 `Toggle`만 지원. `AppIntent`로 액션 실행:

```swift
Button(intent: LogDrinkIntent()) {
    Label("Log", systemImage: "cup.and.saucer")
}
```

### Control Center Controls (iOS 18+)

`ControlWidget` — Control Center, 잠금화면, Action 버튼에 배치.

### Widget 푸시 알림 (iOS 26)

`WidgetPushHandler` 프로토콜로 푸시 기반 위젯 갱신.

---

## Live Activities / ActivityKit

### 데이터 모델

```swift
struct PizzaDeliveryAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var driverName: String
        var deliveryTimer: ClosedRange<Date>
    }
    var numberOfPizzas: Int    // static
    var totalAmount: String    // static
}
```

### 라이프사이클

pending → active → stale → ended/dismissed

```swift
// 시작 (포그라운드에서만, 또는 Live Activity Intent)
let activity = try Activity.request(attributes: attrs, content: content, pushType: .token)

// 업데이트 (백그라운드 가능)
await activity.update(content)

// 종료
await activity.end(content, dismissalPolicy: .default)
```

### Dynamic Island

- **Compact**: leading + trailing (단일 활동)
- **Minimal**: 축약 표시 (복수 활동)
- **Expanded**: 터치 시 center, leading, trailing, bottom 영역

### 제약

- 최대 8시간 활성, 종료 후 잠금화면에 12시간
- static + dynamic 데이터 합계 ≤ 4KB
- 위젯 extension 내 네트워크/위치 접근 불가

---

## App Intents

### 기본 구조 (iOS 16+)

```swift
struct MyIntent: AppIntent {
    static var title: LocalizedStringResource = "Do Something"
    @Parameter var item: String
    func perform() async throws -> some IntentResult { .result() }
}
```

통합 포인트: Siri, Shortcuts, Spotlight, 위젯, Control Center, Apple Intelligence.

### App Intent Domains (iOS 18)

12개 도메인 + 100+ 미리 빌드된 스키마:

```swift
@AssistantIntent(domain: .mail, schema: .mail.compose)
struct ComposeMailIntent: AppIntent { ... }
```

### IndexedEntity (iOS 18)

Spotlight 시맨틱 검색에 엔티티 제공. "pets"로 검색하면 cats, dogs 결과.

---

## StoreKit 2

### Modern API (iOS 15+, Original API iOS 18 deprecated)

```swift
let products = try await Product.products(for: ["com.app.premium"])

let result = try await product.purchase(options: [.appAccountToken(uuid)])
switch result {
case .success(let verification):
    let transaction = try checkVerified(verification)
    await transaction.finish()
case .userCancelled, .pending: break
}
```

### Transaction 관리

- `Transaction.updates` — 외부/크로스 디바이스 구매 async sequence
- `Transaction.currentEntitlements` — 현재 자격
- JWS 검증 via `VerificationResult`

### SwiftUI Views (iOS 17+)

- `ProductView` — 개별 상품
- `StoreView` — 상품 컬렉션
- `SubscriptionStoreView` — 구독 관리 (iOS 18: win-back 오퍼, 커스텀 컨트롤 스타일)

---

## 백그라운드 처리

### BGTaskScheduler (iOS 13+)

```swift
BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.app.refresh", using: nil) { task in
    handleRefresh(task: task as! BGAppRefreshTask)
}

let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
try BGTaskScheduler.shared.submit(request)
```

- `BGAppRefreshTask` — 주기적 업데이트
- `BGProcessingTask` — 장시간 계산 (외부 전원/네트워크)
- `BGContinuedProcessingTask` — 포그라운드 작업의 백그라운드 계속, GPU 접근

---

## 푸시 알림

### UNUserNotificationCenter

- 인터럽션 레벨: `.passive`, `.active`, `.timeSensitive`, `.critical`
- 트리거: `UNCalendarNotificationTrigger`, `UNTimeIntervalNotificationTrigger`, `UNLocationNotificationTrigger`
- 카테고리/액션: `UNNotificationCategory` + `UNNotificationAction`

### Notification Service Extension

`mutable-content: 1` 시 활성화. 콘텐츠 수정, 미디어 다운로드 등.

---

## TipKit

### 기본 (iOS 17+)

```swift
struct FavoriteTip: Tip {
    var title: Text { Text("Add to Favorites") }
    var message: Text? { Text("Tap the heart icon") }
}

// 인라인
TipView(FavoriteTip())

// 팝오버
.popoverTip(FavoriteTip())
```

- 규칙: Parameter 기반 (영속 상태) + Event 기반 (`donate()`)
- `.maxDisplayCount`, `.invalidate(reason: .userPerformedAction)`
- iCloud 동기화 자동
