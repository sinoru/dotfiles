# Modern UIKit Reference

For per-version feature history, see the `wwdc/` year files.

## Table of Contents
1. [Collection/Table View Modern Patterns](#collectiontable-view-modern-patterns)
2. [View Controller Lifecycle](#view-controller-lifecycle)
3. [Trait System](#trait-system)
4. [SwiftUI Integration](#swiftui-integration)
5. [Tab Bar — UITab / UITabGroup](#tab-bar--uitab--uitabgroup-ios-18)
6. [Observable Integration](#observable-integration-ios-26)
7. [Liquid Glass](#liquid-glass-ios-26)

---

## Collection/Table View Modern Patterns

### CellRegistration (iOS 14+)

Replaces `register` + `dequeueReusableCell(withReuseIdentifier:)`:

```swift
let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
    cell, indexPath, item in
    var content = cell.defaultContentConfiguration()
    content.text = item.title
    content.image = item.icon
    cell.contentConfiguration = content
}

// In the DiffableDataSource cell provider:
collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
```

Do not create CellRegistration inside the cell provider closure — causes reuse failures/crashes.

### UIContentConfiguration (iOS 14+)

Replaces `textLabel`/`detailTextLabel`:

- `UIListContentConfiguration` — `.cell()`, `.subtitleCell()`, `.valueCell()`, `.sidebarCell()`, etc.
- `UIContentUnavailableConfiguration` (iOS 17+) — empty states: `.empty()`, `.loading()`, `.search()`

```swift
override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
    contentUnavailableConfiguration = searchResults.isEmpty ? .search() : nil
}
```

### DiffableDataSource (iOS 13+)

```swift
let dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
    collectionView, indexPath, item in
    collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
}

var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
snapshot.appendSections([.main])
snapshot.appendItems(items, toSection: .main)
dataSource.apply(snapshot, animatingDifferences: true)
```

- `SectionID`, `ItemID` both `Hashable` + `Sendable`
- `NSDiffableDataSourceSectionSnapshot` — hierarchical data per section
- Do not swap out a data source once it's been set

### CompositionalLayout (iOS 13+)

Item → Group → Section → Layout hierarchy:

```swift
UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(.insetGrouped))
```

iOS 17: `NSCollectionLayoutDimension.uniformAcrossSiblings` — unifies to the largest size among siblings.

### UIHostingConfiguration (iOS 16+)

Use SwiftUI directly in a UIKit cell:

```swift
cell.contentConfiguration = UIHostingConfiguration {
    HStack {
        Image(systemName: "star")
        Text(item.title)
    }
}
.margins(.all, 16)
.background(.blue.gradient)
```

Supports `swipeActions`, separator alignment, native cell reuse.

---

## View Controller Lifecycle

### viewIsAppearing (iOS 13+ back-deployed)

Called once per appearance transition. After `viewWillAppear`, before `viewDidAppear`.
The view is in the hierarchy, and traits/geometry are accurate. **Do geometry-dependent setup here.**

```
viewWillAppear → viewIsAppearing → viewDidAppear
                 ↑ in view hierarchy, traits accurate
```

- `viewWillAppear`: transition coordinator access, balanced setup/teardown
- `viewIsAppearing`: geometry-dependent setup (best fit)
- `viewDidAppear`: work after animation completes

### Scene-Based Lifecycle (iOS 13+, required in iOS 27)

Uses `UISceneDelegate` / `UIWindowSceneDelegate`:

```
willConnectTo → willEnterForeground → didBecomeActive
                                      ↕
didEnterBackground ← willResignActive
```

iOS 26: every init other than `UIWindow(windowScene:)` is deprecated.
iOS 27 SDK: apps that haven't adopted the scene lifecycle **fail to launch at all** (binaries built with older SDKs keep working).

---

## Trait System

### Custom Traits (iOS 17+)

```swift
struct MyCustomTrait: UITraitDefinition {
    static let defaultValue: Bool = false
}
extension UITraitCollection {
    var myCustomTrait: Bool { self[MyCustomTrait.self] }
}
extension UIMutableTraits {
    var myCustomTrait: Bool {
        get { self[MyCustomTrait.self] }
        set { self[MyCustomTrait.self] = newValue }
    }
}
```

### Automatic Trait Tracking (iOS 18+)

A trait accessed in `layoutSubviews`, `drawRect`, etc. automatically invalidates the view when it changes.
No manual registration needed. Replaces the `traitCollectionDidChange` override.

### Trait Bridging (iOS 17+)

Custom UIKit traits ↔ SwiftUI environment keys can be bridged bidirectionally.

---

## SwiftUI Integration

### UIHostingController

```swift
let hosting = UIHostingController(rootView: MySwiftUIView())
// Content size tracking possible via sizingOptions
```

### UIViewRepresentable / UIViewControllerRepresentable

Wraps UIKit in SwiftUI. Bridge delegate/target-action via `makeCoordinator()`.
SwiftUI owns layout properties — do not modify `frame`/`bounds`/`center`/`transform` directly.

### Gesture Integration (iOS 18+)

`UIGestureRecognizerRepresentable` — use UIKit gestures in SwiftUI.
Supports cross-framework dependencies and velocity preservation.

### Animation Bridging (iOS 18+)

Animate UIKit views with the SwiftUI `Animation` type:

```swift
UIView.animate(springDuration: 0.5) {
    // UIKit view changes, SwiftUI spring timing applied
}
```

---

## Tab Bar — UITab / UITabGroup (iOS 18+)

A combined tab bar + sidebar experience (iPadOS floating tab bar):

```swift
let tab = UITab(title: "Home", image: UIImage(systemName: "house")) { _ in
    HomeViewController()
}
```

Supports drag-and-drop customization.

---

## Observable Integration (iOS 26+)

`@Observable` is automatically tracked in `layoutSubviews` and cell configuration handlers — automatically invalidates when a read property changes.
`updateProperties()` — a lifecycle method dedicated to property updates that runs before layout.

---

## Liquid Glass (iOS 26+)

### Automatic Application

Building with the Xcode 26 SDK automatically applies the Liquid Glass style to standard UIKit controls.
Tab bar becomes transparent; navigation bar transparency is the default.

### UIGlassEffect / UIGlassContainerEffect

```swift
let glassEffect = UIGlassEffect()
// Group multiple glass elements with UIGlassContainerEffect
```

### Buttons

```swift
var config = UIButton.Configuration.glass()
// Or .prominentGlass()
```
