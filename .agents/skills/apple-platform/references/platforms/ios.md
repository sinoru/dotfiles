# iOS Platform Reference

## Table of Contents
1. [Scene-Based Lifecycle](#scene-based-lifecycle)
2. [iPad Multitasking](#ipad-multitasking)
3. [WidgetKit](#widgetkit)
4. [Live Activities / ActivityKit](#live-activities--activitykit)
5. [App Intents](#app-intents)
6. [StoreKit 2](#storekit-2)
7. [Background Processing](#background-processing)
8. [Push Notifications](#push-notifications)
9. [TipKit](#tipkit)

---

## Scene-Based Lifecycle

### UISceneDelegate (iOS 13+, required in iOS 27)

```
willConnectTo → willEnterForeground → didBecomeActive
                                       ↕
didEnterBackground ← willResignActive ← didDisconnect
```

- `sceneDidEnterBackground`: Save data, release camera/shared hardware, hide sensitive information
- UIKit captures a UI snapshot for the app switcher — dismiss alerts/temporary interfaces first

### iOS 26 → 27 Changes

- iOS 26: All inits other than `UIWindow(windowScene:)` deprecated, legacy `UIApplicationDelegate` callbacks deprecated
- iOS 27 SDK: Apps that haven't adopted the scene lifecycle fail to launch. A launch screen is also required (App Store rejects apps without one)

---

## iPad Multitasking

- `UIApplicationSupportsMultipleScenes` (Info.plist) — enables multiple windows
- `UISceneSizeRestrictions` — minimum/maximum window size
- Stage Manager: uses `UIWindowScene` geometry preferences
- iPadOS 18: `UITab` / `UITabGroup` — combines tab bar + sidebar

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

- New widgets use `AppIntentTimelineProvider` (`IntentTimelineProvider` is legacy)
- Refresh budget: 40-70 times per 24 hours. Foreground app/audio/navigation sessions are exempt from the budget.

### Widget Families

System: `systemSmall`, `systemMedium`, `systemLarge`, `systemExtraLarge`
Lock screen/watch: `accessoryCircular`, `accessoryRectangular`, `accessoryInline`, `accessoryCorner`

### Interactive Widgets (iOS 17+)

Only `Button` and `Toggle` are supported. Execute actions with `AppIntent`:

```swift
Button(intent: LogDrinkIntent()) {
    Label("Log", systemImage: "cup.and.saucer")
}
```

### Control Center Controls (iOS 18+)

`ControlWidget` — placed in Control Center, the lock screen, and the Action button.

### Widget Push Notifications (iOS 26)

Push-based widget updates via the `WidgetPushHandler` protocol.

---

## Live Activities / ActivityKit

### Data Model

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

### Lifecycle

pending → active → stale → ended/dismissed

```swift
// Start (foreground only, or via Live Activity Intent)
let activity = try Activity.request(attributes: attrs, content: content, pushType: .token)

// Update (can run in background)
await activity.update(content)

// End
await activity.end(content, dismissalPolicy: .default)
```

### Dynamic Island

- **Compact**: leading + trailing (single activity)
- **Minimal**: Abbreviated display (multiple activities)
- **Expanded**: On tap: center, leading, trailing, bottom regions

### Constraints

- Active for up to 8 hours, remains on the lock screen for 12 hours after ending
- static + dynamic data combined ≤ 4KB
- No network/location access within the widget extension

---

## App Intents

### Basic Structure (iOS 16+)

```swift
struct MyIntent: AppIntent {
    static var title: LocalizedStringResource = "Do Something"
    @Parameter var item: String
    func perform() async throws -> some IntentResult { .result() }
}
```

Integration points: Siri, Shortcuts, Spotlight, widgets, Control Center, Apple Intelligence.

### App Intent Domains (iOS 18)

Predefined schemas across 12 domains (the domain is included in the schema key path):

```swift
@AssistantIntent(schema: .mail.compose)
struct ComposeMailIntent: AppIntent { ... }
```

Entities/enums use `@AssistantEntity(schema:)` / `@AssistantEnum(schema:)`.

### IndexedEntity (iOS 18)

Provides entities for Spotlight semantic search. Searching "pets" returns cats, dogs results.

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

### Transaction Management

- `Transaction.updates` — async sequence for external/cross-device purchases
- `Transaction.currentEntitlements` — current entitlements
- JWS verification via `VerificationResult`

### SwiftUI Views (iOS 17+)

- `ProductView` — individual product
- `StoreView` — product collection
- `SubscriptionStoreView` — subscription management (iOS 18: win-back offers, custom control styles)

---

## Background Processing

### BGTaskScheduler (iOS 13+)

```swift
BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.app.refresh", using: nil) { task in
    handleRefresh(task: task as! BGAppRefreshTask)
}

let request = BGAppRefreshTaskRequest(identifier: "com.app.refresh")
request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
try BGTaskScheduler.shared.submit(request)
```

- `BGAppRefreshTask` — periodic updates
- `BGProcessingTask` — long-running computation (external power/network)
- `BGContinuedProcessingTask` — continues a foreground task in the background, GPU access

---

## Push Notifications

### UNUserNotificationCenter

- Interruption levels: `.passive`, `.active`, `.timeSensitive`, `.critical`
- Triggers: `UNCalendarNotificationTrigger`, `UNTimeIntervalNotificationTrigger`, `UNLocationNotificationTrigger`
- Category/action: `UNNotificationCategory` + `UNNotificationAction`

### Notification Service Extension

Activated when `mutable-content: 1` is set. Content modification, media download, etc.

---

## TipKit

### Basics (iOS 17+)

```swift
struct FavoriteTip: Tip {
    var title: Text { Text("Add to Favorites") }
    var message: Text? { Text("Tap the heart icon") }
}

// Inline
TipView(FavoriteTip())

// Popover
.popoverTip(FavoriteTip())
```

- Rules: Parameter-based (persistent state) + Event-based (`donate()`)
- `.maxDisplayCount`, `.invalidate(reason: .userPerformedAction)`
- Automatic iCloud sync
