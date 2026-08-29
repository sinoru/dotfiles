# macOS Platform Reference

## Table of Contents
1. [App Lifecycle](#app-lifecycle)
2. [Window Management](#window-management)
3. [Menu Bar Apps](#menu-bar-apps)
4. [Document-Based Apps](#document-based-apps)
5. [Menus & Keyboard Shortcuts](#menus--keyboard-shortcuts)
6. [Settings](#settings)
7. [Sandboxing & Security](#sandboxing--security)
8. [Notarization & Distribution](#notarization--distribution)
9. [macOS-Specific SwiftUI Patterns](#macos-specific-swiftui-patterns)

---

## App Lifecycle

### Activation Policy

| Policy | Dock Icon | Menu Bar | Window |
|------|------------|--------|--------|
| `.regular` | O | O | O |
| `.accessory` | X | X | O (can be activated) |
| `.prohibited` | X | X | X (background only) |

### NSApplicationDelegate Essentials

- `applicationShouldTerminateAfterLastWindowClosed(_:)` → terminates automatically when it returns `true`
- `applicationShouldHandleReopen(_:hasVisibleWindows:)` → handles Dock clicks
- `applicationDockMenu(_:)` → Dock right-click menu

---

## Window Management

### SwiftUI Scene Types

**WindowGroup** — multiple windows of the same structure:
```swift
WindowGroup {
    ContentView()
}
.defaultSize(CGSize(width: 600, height: 400))
.defaultPosition(.center)
```

**Window** (macOS 13+) — a single unique window:
```swift
Window("Connection Doctor", id: "connection-doctor") {
    ConnectionDoctor()
}
```

**UtilityWindow** (macOS 15+) — floating tool palette/inspector:
```swift
UtilityWindow("Photo Info", id: "photo-info") {
    PhotoInfoViewer()
}
```
- Receives FocusedValues from the focused main scene
- Automatically hides when the parent loses focus
- Automatically adds a show/hide item to the View menu

### Window Size & Position (macOS 13+)

```swift
.defaultSize(width: 600, height: 400)
.defaultPosition(.topLeading)
.windowResizability(.contentSize)        // fixed to content
.windowResizability(.contentMinSize)     // expandable
.defaultWindowPlacement { content, context in ... }  // macOS 15+
```

### Programmatic Control

```swift
@Environment(\.openWindow) private var openWindow
@Environment(\.dismiss) private var dismiss

openWindow(id: "mail-viewer")
openWindow(id: "message", value: messageID)  // Hashable + Codable data
```

---

## Menu Bar Apps

### MenuBarExtra (SwiftUI, macOS 13+)

```swift
@main
struct UtilityApp: App {
    var body: some Scene {
        MenuBarExtra("Utility", systemImage: "hammer") {
            AppMenu()
        }
    }
}
```

- `.menuBarExtraStyle(.window)` — popover style
- Control visibility with the `isInserted` binding
- App without a Dock icon: `LSUIElement = true` (Info.plist)

---

## Document-Based Apps

### DocumentGroup (SwiftUI)

```swift
DocumentGroup(newDocument: TextFile()) { config in
    ContentView(document: config.$document)
}
```

- `FileDocument` (value type, `Sendable`) or `ReferenceFileDocument` (reference type)
- Do not perform serialization on `@MainActor`
- SwiftData-based document support

---

## Menus & Keyboard Shortcuts

### Commands (macOS 11+)

```swift
.commands {
    CommandMenu("MyMenu") {
        Button("Do Something") { ... }
            .keyboardShortcut("d", modifiers: .command)
    }
    CommandGroup(after: .newItem) {
        Button("New Special Doc") { ... }
    }
}
```

- `CommandGroupPlacement`: `.appInfo`, `.appSettings`, `.newItem`, `.saveItem`, `.undoRedo`, `.pasteboard`, `.sidebar`, `.toolbar`, `.help`, etc.
- `.commandsRemoved()` — removes default commands
- `onKeyPress` (macOS 14+) — hardware keyboard input in a focusable view

### FocusedValues — Multi-Window

`@FocusedValue` — observes values from the focused view hierarchy. The key to connecting menus/commands to the active window's state.

---

## Settings

### Settings Scene (macOS 11+)

```swift
#if os(macOS)
Settings {
    TabView {
        Tab("General", systemImage: "gear") { GeneralSettingsView() }
        Tab("Advanced", systemImage: "star") { AdvancedSettingsView() }
    }
    .scenePadding()
    .frame(maxWidth: 350, minHeight: 100)
}
#endif
```

Automatically creates the Settings menu item (Cmd+,).
`SettingsLink` (macOS 14+), programmatic access via the `openSettings` environment action.

---

## Sandboxing & Security

### Key App Sandbox Entitlements

| entitlement | Purpose |
|---|---|
| `com.apple.security.app-sandbox` | Enables sandboxing (required for Mac App Store) |
| `.network.client` | Outbound network |
| `.network.server` | Inbound network |
| `.device.camera` | Camera |
| `.device.microphone` | Microphone |
| `.files.user-selected.read-write` | Read/write user-selected files |
| `.files.downloads.read-write` | Downloads folder |

### Security-Scoped URL

```swift
let gotAccess = url.startAccessingSecurityScopedResource()
defer { url.stopAccessingSecurityScopedResource() }
// use url
```

Required for URLs obtained via `fileImporter`, etc.

---

## Notarization & Distribution

### Requirements

- Code sign with a Developer ID certificate
- Enable Hardened Runtime
- Include a secure timestamp
- Remove the `com.apple.security.get-task-allow` entitlement

### Workflow

- **Xcode**: Archive → Organizer → Distribute App → Developer ID → Upload (automatic stapling)
- **CLI**: Use `notarytool` (`altool` deprecated as of 2023.11)
- Processing time: usually under 1 hour

### Distribution Paths

- **Mac App Store**: No notarization needed (included in the submission process)
- **Developer ID**: Notarization required

---

## macOS-Specific SwiftUI Patterns

### Inspector (macOS 14+)

```swift
.inspector(isPresented: $showInspector) {
    InspectorView()
}
.inspectorColumnWidth(min: 200, ideal: 300, max: 400)
```

macOS: trailing sidebar. In compact: sheet.

### Context Menu

macOS: right-click (no preview, unlike iOS).
`contextMenu(forSelectionType:menu:primaryAction:)` — recognizes List/Table selection.

### Hover

```swift
.onHover { isHovering in ... }
.onContinuousHover { phase in ... }  // coordinate tracking
```

### External Event Routing

```swift
.handlesExternalEvents(matching: Set<String>)     // scene level
.handlesExternalEvents(preferring:allowing:)       // view level — URL routing
```

### macOS vs iOS Differences

| macOS | iOS |
|-------|-----|
| Multiple resizable windows | Single window (limited multi on iPad) |
| Full menu bar + Cmd shortcuts | No menu bar |
| Keyboard-first navigation | Touch-first |
| hover, right-click | touch, long-press |
| 5 toolbar styles | Standard navigation bar |
| Settings scene (Cmd+,) | In-app settings or Settings.app |
| App Store or Developer ID | App Store only |
