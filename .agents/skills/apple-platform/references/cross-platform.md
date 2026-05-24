# Cross-Platform Reference

## Table of Contents
1. [조건부 컴파일](#조건부-컴파일)
2. [프로젝트 구조](#프로젝트-구조)
3. [플랫폼별 적응 패턴](#플랫폼별-적응-패턴)
4. [Scene 타입 가용성](#scene-타입-가용성)
5. [주요 API 최소 버전](#주요-api-최소-버전)

---

## 조건부 컴파일

### 선호도 순서

1. **`@available` / `if #available`** — 버전 게이트 API
2. **`#if canImport()`** — 프레임워크 조건부 코드
3. **`#if os()`** — OS 수준 구분이 필요할 때만
4. **`#if targetEnvironment()`** — 시뮬레이터/Catalyst 엣지 케이스

### #if canImport() — 프레임워크 가용성

```swift
#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif
```

`#if os()`보다 선호 — 프레임워크가 새 플랫폼에 추가되면 자동 컴파일.
Mac Catalyst에서 더 정확.

### #if os() — 플랫폼별 코드

```swift
#if os(iOS)
// iOS 전용
#elseif os(macOS)
// macOS 전용
#elseif os(visionOS)
// visionOS 전용
#endif
```

유효 이름: `iOS`, `macOS`, `watchOS`, `tvOS`, `visionOS`, `Linux`, `Windows`, `Android`

### #if targetEnvironment()

```swift
#if targetEnvironment(simulator)
// 시뮬레이터 전용 (센서 대체)
#endif

#if targetEnvironment(macCatalyst)
// Mac Catalyst 전용 조정
#endif
```

### 런타임 체크

```swift
if #available(iOS 17, macOS 14, visionOS 1, *) {
    // 새 API 사용
} else {
    // fallback
}

@available(iOS 17, macOS 14, visionOS 1, *)
func useNewFeature() { ... }
```

---

## 프로젝트 구조

### 방법 1: Multiplatform Xcode Project (앱에 권장)

- 단일 타겟 + 복수 플랫폼 destination
- General > Supported Destinations에서 추가
- `#if os()` / `#if canImport()`로 플랫폼별 코드

### 방법 2: Swift Package (공유 로직)

```swift
let package = Package(
    name: "SharedKit",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10), .tvOS(.v17), .visionOS(.v1)],
    products: [.library(name: "SharedKit", targets: ["SharedKit"])],
    targets: [.target(name: "SharedKit")]
)
```

### 권장 디렉토리 구조

```
MyApp/
├── Shared/           # 크로스 플랫폼 뷰, 모델, 유틸리티
├── iOS/              # iOS 전용
├── macOS/            # macOS 전용
├── watchOS/          # watchOS 앱 & complications
├── tvOS/             # tvOS 전용
├── visionOS/         # 몰입형 콘텐츠, volume
└── Packages/
    └── CoreKit/      # 비즈니스 로직 Swift 패키지
```

### 원칙

- 모델, 뷰 모델은 100% 공유
- 공유 SwiftUI 뷰에서 시작, 필요할 때만 플랫폼 특화
- `ViewThatFits`로 반응형 레이아웃
- `AnyLayout`으로 사이즈 클래스 간 레이아웃 전환 애니메이션

---

## 플랫폼별 적응 패턴

### NavigationSplitView 적응

| 플랫폼 | 동작 |
|--------|------|
| iPad (regular) | 멀티 컬럼 |
| iPad (compact/Slide Over) | 스택으로 축소 |
| iPhone | 항상 스택 |
| macOS | 멀티 컬럼 + 리사이즈 사이드바 |
| watchOS | 스택 |
| tvOS | 스택 |
| visionOS | 멀티 컬럼 |

### TabView 적응

```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
}
.tabViewStyle(.sidebarAdaptable)
```

| 플랫폼 | 동작 |
|--------|------|
| iPhone | 하단 탭바 (iOS 26: 컴팩트) |
| iPad | 사이드바 ↔ 탭바 전환 |
| macOS | 사이드바 또는 세그먼트 컨트롤 |
| tvOS | 상단 탭바, tvOS 18+ 사이드바 |
| visionOS | 좌측 수직, 시선으로 확장 |
| watchOS | N/A (수직 TabView) |

### Toolbar 배치 차이

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) { /* 플랫폼별 최적 위치 */ }
    ToolbarItem(placement: .bottomOrnament) { /* visionOS 전용 ornament */ }
    ToolbarItem(placement: .bottomBar) { /* iOS 하단 툴바 */ }
}
```

- `bottomOrnament` — visionOS 전용
- `automatic` — 시스템이 최적 배치 결정

### 입력 방식 차이

| 플랫폼 | 기본 | 보조 |
|--------|------|------|
| iOS/iPadOS | 터치 | Pencil, 키보드, 포인터 |
| macOS | 마우스/트랙패드 + 키보드 | — |
| watchOS | 터치 + Digital Crown | 더블탭 제스처 |
| tvOS | Siri Remote (포커스) | 게임 컨트롤러 |
| visionOS | 시선 + 핀치 | 트랙패드, 게임 컨트롤러 |

---

## Scene 타입 가용성

| Scene | 플랫폼 |
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

## 주요 API 최소 버전

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

SwiftUI 성숙으로 관련성 감소. 기존 UIKit iPad 코드베이스에 유용.
새 프로젝트는 SwiftUI + `#if os(macOS)` 또는 `NSViewRepresentable` 선호.

```swift
#if targetEnvironment(macCatalyst)
// Catalyst 전용 조정
#endif
```
