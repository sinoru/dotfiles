# watchOS Reference

## Table of Contents
1. [App Architecture](#app-architecture)
2. [watchOS 10 Navigation Paradigm](#watchos-10-navigation-paradigm)
3. [WidgetKit Complications](#widgetkit-complications)
4. [Digital Crown](#digital-crown)
5. [Watch Connectivity](#watch-connectivity)
6. [Workout / HealthKit](#workout--healthkit)
7. [Live Activities (watchOS 11)](#live-activities-watchos-11)
8. [Performance & Background](#performance--background)
9. [Deprecated Patterns](#deprecated-patterns)

---

## App Architecture

### SwiftUI Lifecycle (watchOS 7+, Recommended)

```swift
@main
struct MyWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- `WKInterfaceController` (storyboard-based) is legacy — all new development uses SwiftUI
- Standalone execution: `WKRunsIndependentlyOfCompanionApp` (Info.plist)
- Watch-only: `WKWatchOnly`

---

## watchOS 10 Navigation Paradigm

Navigation was completely overhauled in watchOS 10.

### Vertical TabView (watchOS 10+)

Changed from horizontal swipe to vertical Digital Crown paging:

```swift
TabView {
    SummaryView()
        .containerBackground(.blue.gradient, for: .tabView)
    DetailView()
        .containerBackground(.green.gradient, for: .tabView)
    SettingsView()  // scrollable content goes in the last tab
}
```

- Switch tabs with the Digital Crown; the page indicator appears next to the crown
- Place scrollable content in the last tab

### NavigationSplitView (watchOS 9+, Redesigned in watchOS 10)

source-list → detail relationship. Collapses to a stack on watchOS. Shows the detail view directly at app launch; access the source list via the top-left tap.

### containerBackground (watchOS 10+)

```swift
.containerBackground(.blue.gradient, for: .navigation)
.containerBackground(.fill, for: .widget)
```

Placement: `.tabView`, `.navigation`, `.widget`, `.navigationSplitView`

### 3 Basic Layouts

- **Dial** — circular information display
- **Infographic** — chart/data visualization
- **List** — scrollable content

### Toolbar (watchOS 10)

- `.topBarTrailing`, `.topBarLeading` — new placements
- bottom bar — interactive controls
- `.controlSize(.large)` — emphasized button

---

## WidgetKit Complications

ClockKit deprecated → use WidgetKit.

### Accessory Families

- `accessoryCircular` — circular
- `accessoryCorner` — corner
- `accessoryRectangular` — rectangular
- `accessoryInline` — single line of text

### Smart Stack Relevance

```swift
TimelineEntryRelevance(score: 75, duration: 3600)
```

### Migration

Automatic migration from ClockKit → WidgetKit via `CLKComplicationStaticWidgetMigrationConfiguration`, etc.

### AccessoryWidgetGroup (watchOS 11+)

```swift
AccessoryWidgetGroup("Weather", systemImage: "cloud.sun.fill") {
    TemperatureWidgetView(entry.temperature)
    ConditionsWidgetView(entry.conditions)
    UVIndexWidgetView(entry.UVIndex)
}
.accessoryWidgetGroupStyle(.circular)
```

Lays out 3 views horizontally in `.accessoryRectangular`.

---

## Digital Crown

```swift
.digitalCrownRotation(
    $value,
    from: 0.0, through: 10.0, by: 0.1,
    sensitivity: .low,
    isContinuous: true,
    isHapticFeedbackEnabled: true
)
```

In watchOS 10, the Digital Crown was strengthened as the primary navigation input.

---

## Watch Connectivity

### WCSession Setup

```swift
if WCSession.isSupported() {
    let session = WCSession.default
    session.delegate = self
    session.activate()
}
```

### 5 Communication Patterns

| Pattern | Method | Characteristics |
|------|--------|------|
| Immediate Messages | `sendMessage(_:replyHandler:errorHandler:)` | Real-time, requires reachability |
| Application Context | `updateApplicationContext(_:)` | Latest value only, delivered in background |
| User Info Transfer | `transferUserInfo(_:)` | Queued, survives power cycles |
| File Transfer | `transferFile(_:metadata:)` | Background, progress monitoring |
| Complication Data | `transferCurrentComplicationUserInfo(_:)` | Priority, budget-limited |

### Status Properties

`isPaired`, `isWatchAppInstalled`, `isCompanionAppInstalled`, `isReachable`

---

## Workout / HealthKit

### HKWorkoutSession (watchOS 2+)

```swift
session.prepare()
session.startActivity(with: Date())
session.pause()
session.resume()
session.stopActivity(with: Date())
session.end()
```

- Only one workout session can run at a time
- Sensor optimization (e.g., high-frequency heart rate)

### HKLiveWorkoutBuilder (watchOS 5+)

- Incrementally builds workout samples from live data
- `elapsedTime` — elapsed time including pauses

### Mirroring (Multi-Device)

`startMirroringToCompanionDevice` — bidirectional workout mirroring between iPhone and Watch.

---

## Live Activities (watchOS 11)

iOS Live Activities automatically appear in the Smart Stack. No additional code required.

### Watch Custom Layout

```swift
.supplementalActivityFamilies([.small])
```

Provide a watch-specific layout via the `activityFamily` environment value.

### Always On Display

Adjust bright elements via the `isLuminanceReduced` environment value.

---

## Performance & Background

### Background Refresh Budget

- Apps with an active complication: ~4 times per hour
- watchOS 9+: the `.backgroundTask(_:action:)` SwiftUI modifier is preferred

### Extended Runtime Session (watchOS 6+)

Self Care, Mindfulness, Physical Therapy, Smart Alarm types.
Supports Bluetooth, audio, and haptics with the screen off.

### Constraints

- Design concise interactions (under 1 minute)
- Minimize navigation hierarchy
- Prefer full-width controls (max 2-3 side by side)

---

## Deprecated Patterns

| Deprecated | Replacement | When |
|---|---|---|
| ClockKit complications | WidgetKit accessory families | watchOS 9+ |
| `WKInterfaceController` (storyboard) | SwiftUI `@main` App | watchOS 7+ |
| Horizontal page navigation | Vertical TabView + Digital Crown | watchOS 10 |
| `ignoresSafeArea` (widget) | `contentMarginsDisabled()` | watchOS 10 |
| `WKExtension` delegate | `WKApplication` delegate or SwiftUI | — |
| Manual background refresh scheduling | `.backgroundTask` SwiftUI modifier | watchOS 9+ |
