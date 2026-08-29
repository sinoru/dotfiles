# Cross-Platform Reference

## Table of Contents
1. [Conditional Compilation](#conditional-compilation)
2. [Project Structure](#project-structure)
3. [Platform-Specific Adaptation Patterns](#platform-specific-adaptation-patterns)
4. [Scene Type Availability](#scene-type-availability)
5. [Key API Minimum Versions](#key-api-minimum-versions)

---

## Conditional Compilation

### Order of Preference

1. **`@available` / `if #available`** — version-gated APIs
2. **`#if canImport()`** — framework-conditional code
3. **`#if os()`** — only when OS-level distinction is needed
4. **`#if targetEnvironment()`** — simulator/Catalyst edge cases

### #if canImport() — Framework Availability

```swift
#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif
```

Preferred over `#if os()` — automatically compiles when the framework is added to a new platform.
More accurate on Mac Catalyst.

### #if os() — Platform-Specific Code

```swift
#if os(iOS)
// iOS only
#elseif os(macOS)
// macOS only
#elseif os(visionOS)
// visionOS only
#endif
```

Valid names: `iOS`, `macOS`, `watchOS`, `tvOS`, `visionOS`, `Linux`, `Windows`, `Android`

### #if targetEnvironment()

```swift
#if targetEnvironment(simulator)
// Simulator only (sensor substitute)
#endif

#if targetEnvironment(macCatalyst)
// Mac Catalyst-only adjustments
#endif
```

### Runtime Checks

```swift
if #available(iOS 17, macOS 14, visionOS 1, *) {
    // Use new API
} else {
    // fallback
}

@available(iOS 17, macOS 14, visionOS 1, *)
func useNewFeature() { ... }
```

---

## Project Structure

### Method 1: Multiplatform Xcode Project (recommended for apps)

- Single target + multiple platform destinations
- Add via General > Supported Destinations
- Platform-specific code via `#if os()` / `#if canImport()`

### Method 2: Swift Package (shared logic)

```swift
let package = Package(
    name: "SharedKit",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .tvOS(.v17), .visionOS(.v1)],
    products: [.library(name: "SharedKit", targets: ["SharedKit"])],
    targets: [.target(name: "SharedKit")]
)
```

### Recommended Directory Structure

```
MyApp/
├── Shared/           # Cross-platform views, models, utilities
├── iOS/              # iOS only
├── macOS/            # macOS only
├── watchOS/          # watchOS app & complications
├── tvOS/             # tvOS only
├── visionOS/         # Immersive content, volume
└── Packages/
    └── CoreKit/      # Business logic Swift package
```

### Principles

- Models and view models are 100% shared
- Start with shared SwiftUI views, specialize per platform only when necessary
- Responsive layout via `ViewThatFits`
- Animate layout transitions between size classes with `AnyLayout`

---

## Platform-Specific Adaptation Patterns

### NavigationSplitView Adaptation

| Platform | Behavior |
|--------|------|
| iPad (regular) | Multi-column |
| iPad (compact/Slide Over) | Collapses to a stack |
| iPhone | Always a stack |
| macOS | Multi-column + resizable sidebar |
| watchOS | Stack |
| tvOS | Stack |
| visionOS | Multi-column |

### TabView Adaptation

```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
}
.tabViewStyle(.sidebarAdaptable)
```

| Platform | Behavior |
|--------|------|
| iPhone | Bottom tab bar (iOS 26: compact) |
| iPad | Switches between sidebar ↔ tab bar |
| macOS | Sidebar or segmented control |
| tvOS | Top tab bar, sidebar on tvOS 18+ |
| visionOS | Vertical on the left, expands on gaze |
| watchOS | N/A (vertical TabView) |

### Toolbar Placement Differences

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) { /* platform-optimal placement */ }
    ToolbarItem(placement: .bottomOrnament) { /* visionOS-only ornament */ }
    ToolbarItem(placement: .bottomBar) { /* iOS bottom toolbar */ }
}
```

- `bottomOrnament` — visionOS only
- `automatic` — The system determines the optimal placement

### Input Method Differences

| Platform | Primary | Secondary |
|--------|------|------|
| iOS/iPadOS | Touch | Pencil, keyboard, pointer |
| macOS | Mouse/trackpad + keyboard | — |
| watchOS | Touch + Digital Crown | Double-tap gesture |
| tvOS | Siri Remote (focus) | Game controller |
| visionOS | Gaze + pinch | Trackpad, game controller |

---

## Scene Type Availability

| Scene | Platforms |
|-------|--------|
| `WindowGroup` | iOS 14+, macOS 11+, tvOS 14+, watchOS 7+, visionOS 1+ |
| `Window` | macOS 13+ |
| `ImmersiveSpace` | visionOS 1+ |
| `RemoteImmersiveSpace` | macOS 26+ |
| `DocumentGroup` | iOS 14+, macOS 11+ |
| `Settings` | macOS 11+ |
| `MenuBarExtra` | macOS 13+ |
| `UtilityWindow` | macOS 15+ |

---

## Key API Minimum Versions

| API | iOS | macOS | watchOS | tvOS | visionOS |
|-----|-----|-------|---------|------|----------|
| SwiftUI | 13 | 10.15 | 6 | 13 | 1 |
| NavigationStack/SplitView | 16 | 13 | 9 | 16 | 1 |
| `@Observable` | 17 | 14 | 10 | 17 | 1 |
| SwiftData | 17 | 14 | 10 | 17 | 1 |
| `@Entry` | 18 | 15 | 11 | 18 | 2 |
| sidebarAdaptable TabView | 18 | 15 | — | 18 | 2 |
| RealityView | 18 | 15 | — | — | 1 |
| Liquid Glass | 26 | 26 | 26 | 26 | 26 |

### Mac Catalyst

Relevance has declined as SwiftUI has matured. Useful for existing UIKit iPad codebases.
New projects should prefer SwiftUI + `#if os(macOS)` or `NSViewRepresentable`.

```swift
#if targetEnvironment(macCatalyst)
// Catalyst-only adjustments
#endif
```
