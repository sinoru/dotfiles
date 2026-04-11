# Modern UIKit Reference

## Table of Contents
1. [Collection/Table View 모던 패턴](#collectiontable-view-모던-패턴)
2. [뷰 컨트롤러 라이프사이클](#뷰-컨트롤러-라이프사이클)
3. [Trait 시스템](#trait-시스템)
4. [SwiftUI 통합](#swiftui-통합)
5. [iOS 26 / Liquid Glass](#ios-26--liquid-glass)

---

## Collection/Table View 모던 패턴

### CellRegistration (iOS 14+)

`register` + `dequeueReusableCell(withReuseIdentifier:)` 대체:

```swift
let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
    cell, indexPath, item in
    var content = cell.defaultContentConfiguration()
    content.text = item.title
    content.image = item.icon
    cell.contentConfiguration = content
}

// DiffableDataSource cell provider에서:
collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
```

CellRegistration을 cell provider 클로저 안에서 생성하지 말 것 — 재사용 실패/크래시.

### UIContentConfiguration (iOS 14+)

`textLabel`/`detailTextLabel` 대체:

- `UIListContentConfiguration` — `.cell()`, `.subtitleCell()`, `.valueCell()`, `.sidebarCell()` 등
- `UIContentUnavailableConfiguration` (iOS 17+) — 빈 상태: `.empty()`, `.loading()`, `.search()`

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

- `SectionID`, `ItemID` 모두 `Hashable` + `Sendable`
- `NSDiffableDataSourceSectionSnapshot` — 섹션 단위 계층적 데이터
- 한번 설정한 data source는 바꾸지 않는다

### CompositionalLayout (iOS 13+)

Item → Group → Section → Layout 계층:

```swift
UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(.insetGrouped))
```

iOS 17: `NSCollectionLayoutDimension.uniformAcrossSiblings` — 형제 중 가장 큰 크기에 통일.

### UIHostingConfiguration (iOS 16+)

UIKit 셀에 SwiftUI 직접 사용:

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

`swipeActions`, separator alignment, 네이티브 셀 재활용 지원.

---

## 뷰 컨트롤러 라이프사이클

### viewIsAppearing (iOS 13+ back-deployed)

appearance 전환당 1회 호출. `viewWillAppear` 이후, `viewDidAppear` 이전.
뷰가 계층에 있고, traits/geometry가 정확. **geometry 의존 설정은 여기서.**

```
viewWillAppear → viewIsAppearing → viewDidAppear
                 ↑ 뷰 계층 O, traits 정확
```

- `viewWillAppear`: transition coordinator 접근, 균형 setup/teardown
- `viewIsAppearing`: geometry 의존 설정 (가장 적합)
- `viewDidAppear`: 애니메이션 완료 후 작업

### Scene 기반 라이프사이클 (iOS 13+, iOS 27 필수)

`UISceneDelegate` / `UIWindowSceneDelegate` 사용:

```
willConnectTo → willEnterForeground → didBecomeActive
                                      ↕
didEnterBackground ← willResignActive
```

iOS 26: `UIWindow(windowScene:)` 외 모든 init deprecated.
iOS 27: scene lifecycle 필수.

---

## Trait 시스템

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

### 자동 Trait 추적 (iOS 18+)

`layoutSubviews`, `drawRect` 등에서 접근한 trait이 변경되면 자동으로 뷰 무효화.
수동 등록 불필요. `traitCollectionDidChange` override 대체.

### Trait 브릿지 (iOS 17+)

커스텀 UIKit trait ↔ SwiftUI environment key 양방향 브릿지 가능.

---

## SwiftUI 통합

### UIHostingController

```swift
let hosting = UIHostingController(rootView: MySwiftUIView())
// sizingOptions로 콘텐츠 크기 추적 가능
```

### UIViewRepresentable / UIViewControllerRepresentable

SwiftUI에서 UIKit 래핑. `makeCoordinator()`로 delegate/target-action 브릿지.
SwiftUI가 layout 속성 소유 — `frame`/`bounds`/`center`/`transform` 직접 수정 금지.

### 제스처 통합 (iOS 18+)

`UIGestureRecognizerRepresentable` — UIKit 제스처를 SwiftUI에서 사용.
크로스 프레임워크 의존성, 속도 보존 지원.

### 애니메이션 브릿지 (iOS 18+)

SwiftUI `Animation` 타입으로 UIKit 뷰 애니메이션:

```swift
UIView.animate(springDuration: 0.5) {
    // UIKit 뷰 변경, SwiftUI 스프링 타이밍 적용
}
```

---

## iOS 26 / Liquid Glass

### 자동 적용

Xcode 26 SDK로 빌드하면 표준 UIKit 컨트롤이 자동으로 Liquid Glass 스타일 적용.
탭바 투명화, 네비게이션바 투명 기본값.

### UIGlassEffect / UIGlassContainerEffect

```swift
let glassEffect = UIGlassEffect()
// UIGlassContainerEffect로 여러 glass 요소 그룹핑
```

### 버튼

```swift
var config = UIButton.Configuration.glass()
// 또는 .prominentGlass()
```

### Observable 통합 (iOS 26)

`layoutSubviews`, cell configuration handler에서 `@Observable` 자동 추적.
`updateProperties()` — layout 전에 실행.

### UITab / UITabGroup (iOS 18+)

탭바 + 사이드바 결합 경험:

```swift
let tab = UITab(title: "Home", image: UIImage(systemName: "house")) { _ in
    HomeViewController()
}
```

드래그 앤 드롭 커스터마이제이션 지원.

### UIUpdateLink (iOS 18+)

`CADisplayLink`보다 세밀한 디스플레이 업데이트 제어.
뷰 가시성에 따라 자동 활성화/비활성화.
