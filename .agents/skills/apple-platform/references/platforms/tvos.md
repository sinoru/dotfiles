# tvOS Reference

## Table of Contents
1. [App Architecture](#app-architecture)
2. [Focus Engine](#focus-engine)
3. [UI Patterns](#ui-patterns)
4. [Remote Interaction](#remote-interaction)
5. [Media Playback](#media-playback)
6. [SwiftUI on tvOS — Differences from iOS](#swiftui-on-tvos--differences-from-ios)
7. [Deprecated Patterns](#deprecated-patterns)

---

## App Architecture

### Core Constraints

- **No persistent storage**: Only `UserDefaults` persists (~500KB). `.cachesDirectory` can be purged. `.documentDirectory` **does not exist** (crashes). Store all data in iCloud/remote servers.
- **Single window**: `WindowGroup` does not open multiple windows
- **Aggressive suspend**: App suspends/terminates faster than on iOS
- **Dynamic Type** (tvOS 27+): System-wide large text introduced — custom video players and other UI must support text scaling

### TVML/TVMLKit — Deprecated (tvOS 18)

Migrate to SwiftUI. See WWDC 2024 session 10207.

---

## Focus Engine

### Core Rules

- **Only the user** can change directional focus — the app cannot move focus programmatically
- **Single focus** — only one element at a time
- The app can request an update via `setNeedsFocusUpdate()` / `updateFocusIfNeeded()`, but the system decides the target

### SwiftUI Focus API

| API | Minimum Version | Purpose |
|-----|----------|------|
| `focusable(_:)` | tvOS 13 | Make a view focusable |
| `@FocusState` | tvOS 15 | Track focus state |
| `focused(_:equals:)` | tvOS 15 | Bind focus to a value |
| `focusSection()` | tvOS 15 | Group for directional focus movement (**required**) |
| `prefersDefaultFocus(_:in:)` | tvOS 14 | Specify the default focus target |
| `defaultFocus(_:_:priority:)` | tvOS 16 | Assign priority-based focus |

### UIFocusGuide (UIKit)

Redirect focus with an invisible focus area:

```swift
let guide = UIFocusGuide()
view.addLayoutGuide(guide)
guide.preferredFocusEnvironments = [targetView]
```

### Visual States

5 states: Unfocused → **Focused** (scale up + parallax) → **Highlighted** (immediate feedback on selection) → Selected → Unavailable

---

## UI Patterns

### Content Lockup (standard card)

```swift
Button { /* action */ } label: {
    Image("poster")
        .resizable()
        .aspectRatio(250/375, contentMode: .fit)
        .containerRelativeFrame(.horizontal, count: 6, spacing: 40)
    Text("Title")
}
.buttonStyle(.borderless)  // lift, specular highlight, gimbal tilt standard effects
```

Alternative: `.buttonStyle(.card)` — an info card with a platter background (tvOS 14+).

### Content Shelf

```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 40) {
        ForEach(items) { item in /* lockup */ }
    }
}
.scrollClipDisabled()  // required: focus effects extend beyond scroll bounds
.buttonStyle(.borderless)
```

**Without `.scrollClipDisabled()`**, the focus scale/shadow gets clipped.

### Top Shelf (TVServices)

```swift
class MyProvider: TVTopShelfContentProvider {
    func topShelfItems() async -> [TVTopShelfItem] {
        // TVTopShelfCarouselItem — preview video, HDR badge
        // TVTopShelfSectionedContent — image grid
    }
}
```

Notify updates with `topShelfContentDidChange()`.

### Landing Page (tvOS 18+)

Above/below-the-fold pattern:
- `containerRelativeFrame(.vertical)` — header size
- `onScrollVisibilityChange` — fold detection
- `scrollTargetBehavior(.viewAligned)` — snap scrolling

### TabView

```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Search", systemImage: "magnifyingglass") { SearchView() }
}
.tabViewStyle(.sidebarAdaptable)  // tvOS 18+: sidebar style
```

tvOS: top tab bar (default) or sidebar.

---

## Remote Interaction

### SwiftUI Commands

```swift
.onMoveCommand { direction in /* .up, .down, .left, .right */ }
.onPlayPauseCommand { /* play/pause */ }
.onExitCommand { /* Menu button */ }
```

### Gesture Limitations

`DragGesture`, `MagnificationGesture`, `RotationGesture`, `LongPressGesture` **cannot be used**.
`contextMenu` is available (long-press on the remote's touch surface).

### Game Controller

```swift
// Siri Remote: GCMicroGamepad
// Full controller: GCExtendedGamepad
GCController.controllers()  // connected controllers
// GCControllerDidConnect / GCControllerDidDisconnect notifications
```

---

## Media Playback

### AVPlayerViewController

Provides tvOS native transport controls automatically.

tvOS-specific properties:
- `playbackControlsIncludeTransportBar` — transport bar
- `transportBarCustomMenuItems` — custom actions
- `customInfoViewControllers` — content tabs
- `contextualActions` — actions during playback
- `customOverlayViewController` — overlay

Content features:
- `AVNavigationMarkersGroup` — chapter navigation
- `AVInterstitialTimeRange` — ads/interstitials (skip restrictions)
- `AVContentProposal` — "up next" content suggestion

Automatic Siri integration: voice commands like "skip 15 seconds", "what did she say?".

---

## SwiftUI on tvOS — Differences from iOS

1. **All interaction is focus-based** — no tap gestures, focus + selection
2. **`.borderless` button** → standard lockup effect on tvOS (lift/parallax). Plain text on iOS
3. **`.card` button** → tvOS-only (tvOS 14+)
4. **`focusSection()`** → **required** for directional navigation
5. **`.scrollClipDisabled()`** → **required** to prevent focus effects from being clipped
6. **`containerRelativeFrame`** (tvOS 17+) → replaces manual size calculations
7. **`TabView`** → positioned at top (iOS: bottom)

---

## Deprecated Patterns

| Deprecated | Replacement | When |
|---|---|---|
| TVML / TVMLKit | SwiftUI | tvOS 18 |
| `TVUserManager.currentUserIdentifier` | `shouldStorePreferencesForCurrentUser` | — |
| `UIScreen.mainScreen` | `UIScreen.main` | tvOS 26 deprecated |
| TLS 1.0/1.1 | TLS 1.2 minimum | tvOS 26 |

### Preferred Patterns

- SwiftUI > UIKit (especially for media catalogs)
- `.borderless` buttons (not custom styles)
- `containerRelativeFrame` (not manual frames)
- `focusSection()` + `.scrollClipDisabled()` required
