# AppKit Reference

For per-version feature history, see the `wwdc/` year files.

## Table of Contents
1. [NSWindow & NSViewController](#nswindow--nsviewcontroller)
2. [Toolbar & Menus](#toolbar--menus)
3. [SwiftUI Bridge](#swiftui-bridge)
4. [Liquid Glass (macOS 26 Tahoe+)](#liquid-glass-macos-26-tahoe)

---

## NSWindow & NSViewController

### NSWindow Essentials

- **Key window**: receives keyboard/mouse events
- **Main window**: the active document window
- Window level controls z-order
- Tabs: group related windows with `tabbingIdentifier`
- Restoration: preserve state with `isRestorable` and a frame autosave name

### Toolbar Styles

| Style | Description |
|--------|------|
| `.automatic` | System default |
| `.expanded` | Below the title |
| `.preference` | Below the title, centered |
| `.unified` | Next to the title |
| `.unifiedCompact` | Next to the title, reduced margins |

### @ViewLoading / @WindowLoading (macOS 14+)

Removes optionality from NSViewController/NSWindowController properties:

```swift
class MyVC: NSViewController {
    @ViewLoading var label: NSTextField
    // Initialized in viewDidLoad, non-optional access afterward
}
```

---

## Toolbar & Menus

### NSToolbar

- `allowsUserCustomization`, `autosavesConfiguration` — user customization + persistence
- macOS 15+: `.toolbar(removing:)`, `.toolbarBackgroundVisibility()` (SwiftUI)
- macOS Tahoe: items render as glass automatically. Use `isBordered = false` to display non-interactive items.

### Menu System (macOS 14+)

- `NSMenuItem.sectionHeader(title:)` — section header
- Palette menu: `.presentationStyle = .palette`
- Menu badge support

### Activation (macOS 14+)

`activate(ignoringOtherApps:)` deprecated → `activate()` (request-based) + `yieldActivation(to:)`.

---

## SwiftUI Bridge

### NSViewRepresentable

```swift
struct MyAppKitView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSTextField { NSTextField() }
    func updateNSView(_ nsView: NSTextField, context: Context) { /* Reflect state */ }
    func makeCoordinator() -> Coordinator { Coordinator() }
}
```

Do not modify frame/bounds directly.

### NSHostingView / NSHostingController

Embed SwiftUI in AppKit. With `sceneBridgingOptions`, SwiftUI modifiers (`.toolbar`, `.navigationTitle`) are reflected onto the NSWindow.

### NSHostingMenu (macOS 15+)

Use a menu defined in SwiftUI from AppKit:

```swift
let menu = NSHostingMenu(rootView: menuView)
```

### SwiftUI Animations (macOS 15+)

The SwiftUI `Animation` type can be used inside `NSAnimationContext.runAnimationGroup`.

---

## Liquid Glass (macOS 26 Tahoe+)

### Automatic Application

Building with SDK 26 automatically applies Liquid Glass to all standard components.

### NSGlassEffectView

```swift
let glass = NSGlassEffectView()
glass.contentView = targetView
glass.cornerRadius = 12
glass.tintColor = .systemBlue
```

### NSGlassEffectContainerView

Groups multiple glass elements. Fluid merge/split animation, uniform adaptation, correct sampling.

### NSBackgroundExtensionView

Extends content (artwork) beneath a floating sidebar. Mirror/blur duplication.

### Layout Region

`NSView.LayoutRegion` — layout that is aware of Liquid Glass rounded corners.
Constrain with Auto Layout via the `layoutGuide()` method.

### ScrollEdgeEffect

`.soft` (gradual fade/blur) / `.hard` (opaque backing) — beneath toolbars/accessories.

### Control Size Changes

Extra Large added. Mini/Small/Medium heights increased.
Use `prefersCompactControlSizeMetrics = true` to keep the previous sizes.

### Caveats

- Remove the existing `NSVisualEffectView` from the sidebar — it blocks the glass material
- Use `isBordered = false` to display non-interactive toolbar items
- Use `NSItemBadge` for content indicators
