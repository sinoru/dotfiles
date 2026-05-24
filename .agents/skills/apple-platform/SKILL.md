---
name: apple-platform
description: >-
  Apple platform guide: SwiftUI, UIKit, AppKit, Combine, Obj-C
  for iOS/macOS/watchOS/tvOS/visionOS.
  TRIGGER when: discussing, planning, or developing for Apple
  platforms OR imports SwiftUI/UIKit/AppKit/Combine OR editing
  .m/.mm files. Use with swiftlang.
---

# Apple Platform Development Guide

Guide for Apple platform (iOS, macOS, watchOS, tvOS, visionOS) frameworks.
For the Swift language itself (syntax, concurrency, API design guidelines), refer to the **swiftlang** skill.
This skill focuses on using platform frameworks correctly.

## Core Principles

### Prefer the Latest, Avoid the Deprecated

- Always prefer the latest API and patterns available within the project's deployment target.
- Do not use APIs that Apple has marked as deprecated. Use the replacement API instead.
- If a deprecated API is unavoidable, document the reason explicitly.
- When using newer-only APIs, branch with `if #available` / `@available` and provide a fallback.
- If a core feature depends on an API unavailable at the deployment target, explain the trade-offs first.
- **When uncertain, verify with the sosumi skill.** Do not guess API behavior or availability.

### Follow the Framework's Grain

Each Apple framework has its own design patterns. Rather than layering external architecture methodologies (MVVM, VIPER, etc.) on top, structure code the way the framework intends.

- **SwiftUI** — `@Observable` for shared state, `@State` for view-local state, `@Environment` for dependency injection. The framework's data flow is the architecture. A separate "ViewModel" layer is not always necessary.
- **UIKit** — Keep view controllers lightweight with Delegate, DataSource, and Composition patterns. Use system-provided modern patterns like UIContentConfiguration, DiffableDataSource.
- **AppKit** — Follow Cocoa patterns: NSDocument, NSWindowController, delegate/target-action.
- **Objective-C** — Cocoa's delegate/target-action/notification/KVO patterns.

### Follow Apple Framework Conventions

- Follow existing patterns and naming conventions of Apple frameworks.
- First parameter of delegate methods is the caller (delegate source):
  ```swift
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  ```
  ```objc
  - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
  ```

### Design with HIG in Mind

Consider Apple Human Interface Guidelines when writing code:

- **Accessibility**: minimum touch target 44×44pt (visionOS 60×60pt), color contrast 4.5:1 (body text), Dynamic Type support
- **System colors/fonts**: use semantic colors (`label`, `systemBackground`) and text styles (`.body`, `.headline`) instead of hardcoded values
- **Platform conventions**: follow each platform's navigation/interaction patterns (iOS tab bar, macOS menu bar, tvOS focus, visionOS gaze+pinch)
- **Dark Mode**: support light/dark mode on all platforms. Automatic with semantic colors.
- **Liquid Glass** (iOS 26+, macOS Tahoe+): latest design system. Standard components adopt it automatically.

See `references/hig.md` for detailed metrics and per-platform design principles.

---

## Framework Selection

Choose the appropriate framework based on the project context when writing new UI code:

| Scenario | Recommended | Reason |
|----------|-------------|--------|
| New project, latest OS target | **SwiftUI** | Declarative, multi-platform, actively invested by Apple |
| Existing UIKit/AppKit codebase | **Keep existing framework** + consider SwiftUI for new screens | Consistency first, gradual adoption |
| Advanced custom UI difficult in SwiftUI | **UIKit/AppKit** + integrate via Representable | Wrap in SwiftUI |

SwiftUI ↔ UIKit/AppKit integration patterns:
- `UIHostingController` / `NSHostingController` — embed SwiftUI in UIKit/AppKit
- `UIHostingConfiguration` (iOS 16+) — use SwiftUI directly in UIKit cells
- `UIViewRepresentable` / `NSViewRepresentable` — embed UIKit/AppKit views in SwiftUI

---

## Objective-C Essentials

Essential rules for writing Objective-C code or bridging with Swift.

### Nullability — Apply to All Public Headers

```objc
NS_ASSUME_NONNULL_BEGIN
@interface MYService : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, nullable) id<MYDelegate> delegate;
- (void)fetchWithCompletion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion;
@end
NS_ASSUME_NONNULL_END
```

Without annotations, Swift imports as `!` (implicitly unwrapped optional) — always annotate.

### Swift Bridging Annotations

| Annotation | Purpose |
|---|---|
| `NS_SWIFT_NAME(name)` | Specify name in Swift |
| `NS_REFINED_FOR_SWIFT` | Hide with `__` prefix, encourage Swift wrapper |
| `NS_SWIFT_UNAVAILABLE("msg")` | Completely hide from Swift |
| `NS_CLOSED_ENUM` | Frozen enum allowing exhaustive switch |
| `NS_TYPED_ENUM` / `NS_TYPED_EXTENSIBLE_ENUM` | Map constant groups to struct |
| `NS_SWIFT_ASYNC_NAME("name")` | Specify name for async import |
| `NS_SWIFT_SENDABLE` / `NS_SWIFT_NONSENDABLE` | Control Sendable conformance |

### ARC & Retain Cycle Prevention

```objc
__weak __typeof(self) weakSelf = self;
[self doSomethingWithBlock:^{
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    [strongSelf doWork];
}];
```

- Delegates are always `weak`. Timer targets are also `weak`.
- A retain cycle occurs when a block captures self and self retains the block.

See `references/objective-c.md` for the full annotation list, bridging setup, and concurrency bridging.

---

## Key Deprecations to Know

Notable deprecated patterns and their replacements:

| Deprecated | Replacement | Since |
|---|---|---|
| `NavigationView` | `NavigationStack` / `NavigationSplitView` | iOS 16 |
| `ObservableObject` + `@Published` | `@Observable` macro | iOS 17 |
| `@StateObject` | `@State` (with `@Observable`) | iOS 17 |
| `@ObservedObject` | plain property or `@Bindable` | iOS 17 |
| `@EnvironmentObject` | `@Environment(Type.self)` | iOS 17 |
| `ClockKit` complications | WidgetKit accessory families | watchOS 9 |
| TVML / TVMLKit | SwiftUI | tvOS 18 |
| Original StoreKit API | StoreKit 2 | iOS 18 (deprecated) |
| `UIApplicationDelegate`-only lifecycle | `UISceneDelegate` | iOS 13 (required: iOS 27) |

---

## Upstream Sources

The reference files in this skill are derived from the sources below. Consult them when information is insufficient or freshness is uncertain. Also use these sources when updating reference files.

- **Apple developer docs**: search via the sosumi skill's `searchAppleDocumentation`
- **Human Interface Guidelines**: fetch via sosumi at `/design/human-interface-guidelines/` path
- **WWDC sessions**: fetch via sosumi at `/videos/play/wwdc{year}/{id}` path
- **Third-party / open-source frameworks**: sosumi `fetchExternalDocumentation` or [Swift Package Index](https://swiftpackageindex.com)

---

## Detailed References

Read the relevant reference file for detailed per-framework/per-platform patterns.
Only read the files you need.

### Framework References

**`references/foundation.md`** — Modern Foundation
FormatStyle(.formatted()), AttributedString, #Predicate, RegexBuilder,
URLSession async/await, NotificationCenter.notifications, Duration/Clock,
KVO in Swift vs @Observable, advanced Codable patterns, UserDefaults.
**When to read**: using Foundation APIs, replacing legacy Formatter/NSPredicate, async networking.

**`references/swiftui.md`** — SwiftUI Deep Dive
State management (@State, @Binding, @Environment, @Observable, @Bindable, @Entry), Navigation
(NavigationStack, NavigationSplitView), SwiftData integration (@Model, @Query, ModelContainer),
performance optimization, UIKit/AppKit interop. **When to read**: writing SwiftUI views, designing data flow, using SwiftData.

**`references/uikit.md`** — Modern UIKit
CellRegistration, UIContentConfiguration, DiffableDataSource, CompositionalLayout,
viewIsAppearing, Trait system, automatic trait tracking (iOS 18), Observable integration (iOS 26),
Liquid Glass. **When to read**: writing/modifying UIKit code, UIKit↔SwiftUI integration.

**`references/appkit.md`** — macOS AppKit
NSWindow/NSViewController, toolbars, menus, NSGlassEffectView (macOS Tahoe),
SwiftUI bridging (NSHostingView, sceneBridgingOptions).
**When to read**: writing native macOS AppKit code.

**`references/combine.md`** — Combine & Reactive Patterns
Combine current status (effectively in maintenance mode), AsyncSequence migration, .values bridge,
operator correspondence table, when Combine is still the right choice.
**When to read**: writing/migrating Combine code, choosing reactive patterns.

**`references/objective-c.md`** — Objective-C Deep Dive
Full annotation list, bridging setup (headers/module maps), bidirectional Swift↔ObjC patterns,
concurrency bridging (completion handler ↔ async), SE-0436 `@objc @implementation`.
**When to read**: writing ObjC code, designing Swift-ObjC interop.

### Platform References

**`references/platforms/ios.md`** — iOS Platform
Scene-based lifecycle, iPad multitasking, WidgetKit/Live Activities/ActivityKit,
App Intents/Apple Intelligence, StoreKit 2, background processing, push notifications, TipKit.
**When to read**: implementing iOS app features (widgets, Live Activity, IAP, background, etc.).

**`references/platforms/macos.md`** — macOS Platform
Window management (WindowGroup, Window, UtilityWindow), MenuBarExtra, document-based apps,
menus/toolbars/keyboard shortcuts, Settings scene, sandboxing/notarization, FocusedValues.
**When to read**: implementing macOS app features (windows, menu bar, distribution, etc.).

**`references/platforms/watchos.md`** — watchOS
SwiftUI lifecycle, watchOS 10 navigation paradigm (vertical TabView + Digital Crown),
WidgetKit complications, WatchConnectivity, Live Activities (watchOS 11), workout/HealthKit.
**When to read**: developing watchOS apps/complications.

**`references/platforms/tvos.md`** — tvOS
Focus engine, remote interaction, Top Shelf, content shelf/lockup patterns,
media playback (AVPlayerViewController), TVML→SwiftUI migration.
**When to read**: developing tvOS apps.

**`references/platforms/visionos.md`** — visionOS
Window/Volume/ImmersiveSpace, RealityKit(RealityView, Model3D, ECS),
spatial input (gaze+pinch), ornaments, hover effects, iOS→visionOS porting.
**When to read**: developing visionOS apps, implementing spatial computing features.

### Cross-Cutting References

**`references/cross-platform.md`** — Multi-Platform Strategy
Conditional compilation (`#if canImport` > `#if os`), project structure,
per-platform adaptation patterns (NavigationSplitView, TabView, toolbar placement).
**When to read**: designing multi-platform apps, writing platform-branching code.

**`references/hig.md`** — Human Interface Guidelines
Design principles (Clarity, Deference, Depth), per-platform design characteristics,
typography/color metrics, layout/spacing, accessibility metrics, navigation patterns,
Liquid Glass design system.
**When to read**: UI design decisions, accessibility review, checking per-platform design differences.
