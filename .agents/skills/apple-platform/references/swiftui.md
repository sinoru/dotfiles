# SwiftUI Reference

## Table of Contents
1. [State Management & Observation](#state-management--observation)
2. [Navigation](#navigation)
3. [SwiftData Integration](#swiftdata-integration)
4. [Performance](#performance)
5. [UIKit/AppKit Interop](#uikitappkit-interop)
6. [iOS 26 / WWDC 2025 Additions](#ios-26--wwdc-2025-additions)

---

## State Management & Observation

### @Observable (iOS 17+)

`ObservableObject` + `@Published`를 대체하는 매크로. 프로퍼티별 추적으로 불필요한 뷰 업데이트를 방지한다.

```swift
@Observable
class Library {
    var books: [Book] = []       // 자동 추적, @Published 불필요
    var isLoading = false
    @ObservationIgnored var cache: [String: Data] = [:]  // 추적 제외
}
```

핵심 차이: `ObservableObject`는 `@Published` 프로퍼티가 하나만 바뀌어도 모든 구독 뷰를 업데이트.
`@Observable`은 `body`에서 실제 읽은 프로퍼티가 바뀔 때만 해당 뷰를 업데이트.

### Property Wrapper 선택 (iOS 17+)

| Wrapper | 용도 |
|---------|------|
| `@State` | 뷰가 소유하는 데이터. 값 타입과 `@Observable` 클래스 모두 가능. `@StateObject` 대체. |
| `@Binding` | 다른 곳의 state에 대한 양방향 참조. `$` 접두사로 생성. |
| `@Bindable` | `@Observable` 객체에서 바인딩 생성 (`$property`). `@ObservedObject` 대체. |
| `@Environment(Type.self)` | 환경에서 `@Observable` 객체 읽기. `@EnvironmentObject` 대체. |
| `@Environment(\.keyPath)` | 환경 값 읽기. `@Entry` 매크로로 정의 가능. |
| (wrapper 없음) | `@Observable` 객체를 plain property로 전달. 가장 일반적인 자식 뷰 패턴. |

### Migration Map

| Old | New (iOS 17+) |
|-----|---------------|
| `class Foo: ObservableObject` | `@Observable class Foo` |
| `@Published var x` | `var x` |
| `@StateObject private var foo = Foo()` | `@State private var foo = Foo()` |
| `@ObservedObject var foo: Foo` | `var foo: Foo` 또는 `@Bindable var foo: Foo` |
| `.environmentObject(foo)` | `.environment(foo)` |
| `@EnvironmentObject var foo: Foo` | `@Environment(Foo.self) var foo` |

두 시스템은 공존 가능. 점진적 마이그레이션 지원.

### @Bindable 사용

바인딩이 필요할 때만 사용:

```swift
struct BookEditView: View {
    @Bindable var book: Book  // @Observable class

    var body: some View {
        TextField("Title", text: $book.title)
    }
}

// body 안에서 로컬로도 가능
var body: some View {
    List(books) { book in
        @Bindable var book = book
        TextField("Title", text: $book.title)
    }
}
```

### @Entry 매크로 (iOS 18+, iOS 13까지 back-deploy)

`EnvironmentKey` 보일러플레이트 제거:

```swift
// 기존
private struct MyKey: EnvironmentKey {
    static let defaultValue: String = "default"
}
extension EnvironmentValues {
    var myValue: String {
        get { self[MyKey.self] }
        set { self[MyKey.self] = newValue }
    }
}

// @Entry 사용
extension EnvironmentValues {
    @Entry var myValue: String = "default"
}
```

`EnvironmentValues`, `Transaction`, `ContainerValues`, `FocusedValues`에 사용 가능.

---

## Navigation

### NavigationStack (iOS 16+)

`NavigationView`를 대체. 값 기반 프로그래매틱 네비게이션:

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

// 프로그래매틱 제어
func showPark(_ park: Park) { path.append(park) }
func popToRoot() { path.removeAll() }
```

### NavigationPath (iOS 16+)

여러 타입을 담는 type-erased path:

```swift
@State private var path = NavigationPath()
// path.append(somePark)  // Park
// path.append(someAnimal)  // Animal — 다른 타입도 가능
```

`Codable` 값이면 `path.codable`로 상태 복원 가능.

### NavigationSplitView (iOS 16+)

멀티 컬럼 네비게이션 (iPad/Mac):

```swift
NavigationSplitView {
    List(parks, selection: $selectedPark) { park in
        Text(park.name)
    }
} detail: {
    if let park = selectedPark { ParkDetailView(park: park) }
}
```

- 2열/3열 지원. compact에서 자동 스택으로 축소.
- `NavigationSplitViewVisibility`로 컬럼 가시성 제어.
- iPadOS 26: 리사이즈 가능 윈도우에서 자동 컬럼 show/hide.

### navigationDestination 변형

```swift
.navigationDestination(for: Type.self) { value in ... }      // 값 기반
.navigationDestination(isPresented: $bool) { ... }            // Bool 기반
.navigationDestination(item: $optionalItem) { item in ... }   // Optional 바인딩
```

---

## SwiftData Integration

### @Model (iOS 17+)

`@Observable` 위에 구축된 영속 모델:

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

### Container 설정

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

뷰에서 모델 데이터를 선언적으로 fetch + observe:

```swift
struct TripListView: View {
    @Query(sort: \Trip.startDate, order: .reverse) var trips: [Trip]

    @Query(filter: #Predicate<Trip> { $0.destination == "Paris" },
           sort: [SortDescriptor(\.startDate)])
    var parisTrips: [Trip]
}
```

### ModelContext 조작

```swift
@Environment(\.modelContext) private var context

context.insert(trip)       // 생성
trip.name = "Updated"      // 수정 — 프로퍼티 직접 변경
context.delete(trip)       // 삭제
try context.save()         // 저장
```

### @ModelActor — 백그라운드 작업

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

### @Observable 세분화

`@Observable`은 `body`에서 읽은 프로퍼티만 추적. `book.title`을 표시하는 뷰는 `book.author` 변경에 반응하지 않는다. 중간 뷰를 거쳐 전달해도 실제 읽는 뷰만 업데이트.

### .task 수정자 (iOS 15+)

뷰 라이프사이클에 연결된 async 작업:

```swift
.task { await loadData() }

// id 변경 시 이전 task 취소 후 재실행
.task(id: selectedItem) {
    await loadDetails(for: selectedItem)
}
```

뷰가 사라지면 자동 취소.

### Lazy Loading

`LazyVStack` / `LazyHStack` — 화면에 보이는 뷰만 생성. iOS 26+에서 중첩 스크롤뷰에서도 정상 동작.

### 스크롤 성능 (iOS 17+)

```swift
.onScrollGeometryChange(of: \.contentOffset) { old, new in /* ... */ }
.onScrollVisibilityChange(threshold: 0.5) { isVisible in /* ... */ }
```

`GeometryReader` 없이 효율적인 스크롤 추적.

---

## UIKit/AppKit Interop

### UIViewRepresentable (iOS 13+)

```swift
struct MyMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> MKMapView { MKMapView() }
    func updateUIView(_ uiView: MKMapView, context: Context) { /* SwiftUI 상태 반영 */ }
    func makeCoordinator() -> Coordinator { Coordinator() }
}
```

SwiftUI가 `center`, `bounds`, `frame`, `transform`을 소유 — 직접 수정 금지.

### UIHostingController (iOS 13+)

```swift
let hosting = UIHostingController(rootView: MySwiftUIView())
addChild(hosting)
view.addSubview(hosting.view)
hosting.didMove(toParent: self)
```

### UIHostingConfiguration (iOS 16+)

UIKit 셀에 SwiftUI 직접 사용:

```swift
cell.contentConfiguration = UIHostingConfiguration {
    HStack { Image(systemName: "star"); Text(item.title) }
}.margins(.all, 16)
```

### 제스처 통합 (iOS 18+)

`UIGestureRecognizerRepresentable` — UIKit 제스처를 SwiftUI에서 사용.
크로스 프레임워크 제스처 의존성 설정 가능.

---

## iOS 26 / WWDC 2025 Additions

### Liquid Glass

```swift
Text("Label")
    .glassEffect()
    .glassEffect(in: .rect(cornerRadius: 16))
    .glassEffect(.regular.tint(.blue).interactive())
```

표준 네비게이션/툴바/탭바는 자동 적용.

### WebView

```swift
@State private var page = WebPage()
WebView(page)
    .onAppear { page.url = URL(string: "https://example.com")! }
```

### Rich Text Editing

`TextEditor`가 `AttributedString` 바인딩 지원.

### @Animatable 매크로

```swift
@Animatable
struct MyData {
    var progress: Double
    @AnimatableIgnored var label: String
}
```

### 기타

- `Chart3D` — 3D 차트 (visionOS 26)
- `RemoteImmersiveSpace` — Mac에서 Vision Pro로 스트리밍 (macOS Tahoe)
- macOS `List` 100k+ 항목: 6배 빠른 로딩, 16배 빠른 업데이트
- SwiftUI Performance Instrument (Xcode)
- RealityKit 엔티티가 `Observable` 프로토콜 적합
