# SwiftUI Reference

For per-version feature history (Liquid Glass, WebView, @Animatable, etc.), see the `wwdc/` year files.

## Table of Contents
1. [State Management & Observation](#state-management--observation)
2. [Navigation](#navigation)
3. [SwiftData Integration](#swiftdata-integration)
4. [Performance](#performance)
5. [UIKit/AppKit Interop](#uikitappkit-interop)
6. [Liquid Glass](#liquid-glass-ios-26)

---

## State Management & Observation

### @Observable (iOS 17+)

Macro that replaces `ObservableObject` + `@Published`. Per-property tracking prevents unnecessary view updates.

```swift
@Observable
class Library {
    var books: [Book] = []       // Automatically tracked, no @Published needed
    var isLoading = false
    @ObservationIgnored var cache: [String: Data] = [:]  // Excluded from tracking
}
```

Key difference: `ObservableObject` updates all subscribing views even if only one `@Published` property changes.
`@Observable` updates a view only when a property it actually reads in `body` changes.

### Property Wrapper Selection (iOS 17+)

| Wrapper | Use |
|---------|------|
| `@State` | Data owned by the view. Works with both value types and `@Observable` classes. Replaces `@StateObject`. |
| `@Binding` | Two-way reference to state owned elsewhere. Created with the `$` prefix. |
| `@Bindable` | Creates bindings from an `@Observable` object (`$property`). Replaces `@ObservedObject`. |
| `@Environment(Type.self)` | Reads an `@Observable` object from the environment. Replaces `@EnvironmentObject`. |
| `@Environment(\.keyPath)` | Reads an environment value. Can be defined with the `@Entry` macro. |
| (no wrapper) | Passes an `@Observable` object as a plain property. The most common pattern for child views. |

### Migration Map

| Old | New (iOS 17+) |
|-----|---------------|
| `class Foo: ObservableObject` | `@Observable class Foo` |
| `@Published var x` | `var x` |
| `@StateObject private var foo = Foo()` | `@State private var foo = Foo()` |
| `@ObservedObject var foo: Foo` | `var foo: Foo` or `@Bindable var foo: Foo` |
| `.environmentObject(foo)` | `.environment(foo)` |
| `@EnvironmentObject var foo: Foo` | `@Environment(Foo.self) var foo` |

Both systems can coexist. Supports incremental migration.

### @Bindable Usage

Use only when a binding is needed:

```swift
struct BookEditView: View {
    @Bindable var book: Book  // @Observable class

    var body: some View {
        TextField("Title", text: $book.title)
    }
}

// Also usable locally inside body
var body: some View {
    List(books) { book in
        @Bindable var book = book
        TextField("Title", text: $book.title)
    }
}
```

### @Entry Macro (iOS 18+, back-deployed to iOS 13)

Removes `EnvironmentKey` boilerplate:

```swift
// Before
private struct MyKey: EnvironmentKey {
    static let defaultValue: String = "default"
}
extension EnvironmentValues {
    var myValue: String {
        get { self[MyKey.self] }
        set { self[MyKey.self] = newValue }
    }
}

// Using @Entry
extension EnvironmentValues {
    @Entry var myValue: String = "default"
}
```

Usable with `EnvironmentValues`, `Transaction`, `ContainerValues`, `FocusedValues`.

---

## Navigation

### NavigationStack (iOS 16+)

Replaces `NavigationView`. Value-based programmatic navigation:

```swift
@State private var path: [Park] = []

NavigationStack(path: $path) {
    List(parks) { park in
        NavigationLink(park.name, value: park)
    }
    .navigationDestination(for: Park.self) { park in
        ParkDetailView(park: park)
    }
}

// Programmatic control
func showPark(_ park: Park) { path.append(park) }
func popToRoot() { path.removeAll() }
```

### NavigationPath (iOS 16+)

A type-erased path that can hold multiple types:

```swift
@State private var path = NavigationPath()
// path.append(somePark)  // Park
// path.append(someAnimal)  // Animal — other types work too
```

If the value is `Codable`, state restoration is possible via `path.codable`.

### NavigationSplitView (iOS 16+)

Multi-column navigation (iPad/Mac):

```swift
NavigationSplitView {
    List(parks, selection: $selectedPark) { park in
        Text(park.name)
    }
} detail: {
    if let park = selectedPark { ParkDetailView(park: park) }
}
```

- Supports 2-column/3-column layouts. Collapses to an automatic stack in compact.
- Control column visibility with `NavigationSplitViewVisibility`.
- iPadOS 26: automatic column show/hide in resizable windows.

### navigationDestination Variants

```swift
.navigationDestination(for: Type.self) { value in ... }      // Value-based
.navigationDestination(isPresented: $bool) { ... }            // Bool-based
.navigationDestination(item: $optionalItem) { item in ... }   // Optional binding
```

---

## SwiftData Integration

### @Model (iOS 17+)

A persistent model built on top of `@Observable`:

```swift
@Model
class Trip {
    var name: String
    var destination: String
    @Attribute(.unique) var id: UUID
    @Relationship(deleteRule: .cascade) var events: [Event]
    @Transient var temporaryNotes: String = ""

    init(name: String, destination: String) {
        self.name = name
        self.destination = destination
        self.id = UUID()
    }
}
```

### Container Setup

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: [Trip.self, Event.self])
    }
}
```

### @Query

Declaratively fetch + observe model data in a view:

```swift
struct TripListView: View {
    @Query(sort: \Trip.startDate, order: .reverse) var trips: [Trip]

    @Query(filter: #Predicate<Trip> { $0.destination == "Paris" },
           sort: [SortDescriptor(\.startDate)])
    var parisTrips: [Trip]
}
```

### ModelContext Operations

```swift
@Environment(\.modelContext) private var context

context.insert(trip)       // Create
trip.name = "Updated"      // Update — modify the property directly
context.delete(trip)       // Delete
try context.save()         // Save
```

### @ModelActor — Background Work

```swift
@ModelActor
actor DataHandler {
    func importData(_ items: [ImportItem]) throws {
        for item in items {
            modelContext.insert(Trip(name: item.name, destination: item.dest))
        }
        try modelContext.save()
    }
}
```

---

## Performance

### @Observable Granularity

`@Observable` tracks only the properties read in `body`. A view that displays `book.title` does not react to changes in `book.author`. Even when passed through intermediate views, only the view that actually reads the property is updated.

### .task Modifier (iOS 15+)

Async work tied to the view lifecycle:

```swift
.task { await loadData() }

// Cancels the previous task and reruns when id changes
.task(id: selectedItem) {
    await loadDetails(for: selectedItem)
}
```

Automatically cancelled when the view disappears.

### Lazy Loading

`LazyVStack` / `LazyHStack` — creates only the views visible on screen. Works correctly even in nested scroll views on iOS 26+.

### Scroll Performance (iOS 17+)

```swift
.onScrollGeometryChange(of: \.contentOffset) { old, new in /* ... */ }
.onScrollVisibilityChange(threshold: 0.5) { isVisible in /* ... */ }
```

Efficient scroll tracking without `GeometryReader`.

---

## UIKit/AppKit Interop

### UIViewRepresentable (iOS 13+)

```swift
struct MyMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView { MKMapView() }
    func updateUIView(_ uiView: MKMapView, context: Context) { /* Reflect SwiftUI state */ }
    func makeCoordinator() -> Coordinator { Coordinator() }
}
```

SwiftUI owns `center`, `bounds`, `frame`, `transform` — do not modify directly.

### UIHostingController (iOS 13+)

```swift
let hosting = UIHostingController(rootView: MySwiftUIView())
addChild(hosting)
view.addSubview(hosting.view)
hosting.didMove(toParent: self)
```

### UIHostingConfiguration (iOS 16+)

Use SwiftUI directly in a UIKit cell:

```swift
cell.contentConfiguration = UIHostingConfiguration {
    HStack { Image(systemName: "star"); Text(item.title) }
}.margins(.all, 16)
```

### Gesture Integration (iOS 18+)

`UIGestureRecognizerRepresentable` — use UIKit gestures in SwiftUI.
Cross-framework gesture dependencies can be configured.

---

## Liquid Glass (iOS 26+)

```swift
Text("Label")
    .glassEffect()
    .glassEffect(in: .rect(cornerRadius: 16))
    .glassEffect(.regular.tint(.blue).interactive())
```

Standard navigation/toolbar/tab bars apply it automatically. Use `GlassEffectContainer` to group custom elements.
