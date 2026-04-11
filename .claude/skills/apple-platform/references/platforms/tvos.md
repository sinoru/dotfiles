# tvOS Reference

## Table of Contents
1. [앱 아키텍처](#앱-아키텍처)
2. [Focus Engine](#focus-engine)
3. [UI 패턴](#ui-패턴)
4. [리모컨 인터랙션](#리모컨-인터랙션)
5. [미디어 재생](#미디어-재생)
6. [SwiftUI on tvOS — iOS와의 차이](#swiftui-on-tvos--ios와의-차이)
7. [Deprecated 패턴](#deprecated-패턴)

---

## 앱 아키텍처

### 핵심 제약

- **영속 저장소 없음**: `UserDefaults` ~500KB만 영속. `.cachesDirectory` 퍼지 가능. `.documentDirectory` **존재하지 않음** (크래시). 모든 데이터는 iCloud/원격 서버에 저장.
- **단일 윈도우**: `WindowGroup`이 복수 윈도우 열지 않음
- **공격적 suspend**: iOS보다 빠르게 앱 suspend/terminate

### TVML/TVMLKit — deprecated (tvOS 18)

SwiftUI로 마이그레이션. WWDC 2024 세션 10207 참조.

---

## Focus Engine

### 핵심 규칙

- **사용자만** 방향적 포커스 변경 가능 — 앱이 프로그래매틱하게 방향 이동 불가
- **단일 포커스** — 동시에 하나의 요소만
- 앱은 `setNeedsFocusUpdate()` / `updateFocusIfNeeded()`로 업데이트 요청 가능, 대상은 시스템이 결정

### SwiftUI Focus API

| API | 최소 버전 | 용도 |
|-----|----------|------|
| `focusable(_:)` | tvOS 13 | 뷰를 포커스 가능하게 |
| `@FocusState` | tvOS 15 | 포커스 상태 추적 |
| `focused(_:equals:)` | tvOS 15 | 포커스를 값에 바인딩 |
| `focusSection()` | tvOS 15 | 방향 포커스 이동용 그룹핑 (**필수**) |
| `prefersDefaultFocus(_:in:)` | tvOS 14 | 기본 포커스 대상 지정 |
| `defaultFocus(_:_:priority:)` | tvOS 16 | 우선순위 포커스 할당 |

### UIFocusGuide (UIKit)

보이지 않는 포커스 영역으로 포커스 리디렉션:

```swift
let guide = UIFocusGuide()
view.addLayoutGuide(guide)
guide.preferredFocusEnvironments = [targetView]
```

### 시각 상태

5가지: Unfocused → **Focused** (확대 + parallax) → **Highlighted** (선택 즉시 피드백) → Selected → Unavailable

---

## UI 패턴

### Content Lockup (표준 카드)

```swift
Button { /* action */ } label: {
    Image("poster")
        .resizable()
        .aspectRatio(250/375, contentMode: .fit)
        .containerRelativeFrame(.horizontal, count: 6, spacing: 40)
    Text("Title")
}
.buttonStyle(.borderless)  // lift, specular highlight, gimbal tilt 표준 효과
```

대안: `.buttonStyle(.card)` — platter 배경의 정보 카드 (tvOS 14+).

### Content Shelf

```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 40) {
        ForEach(items) { item in /* lockup */ }
    }
}
.scrollClipDisabled()  // 필수: 포커스 효과가 스크롤 경계 밖으로 확장
.buttonStyle(.borderless)
```

**`.scrollClipDisabled()` 없으면** 포커스 스케일/그림자가 잘림.

### Top Shelf (TVServices)

```swift
class MyProvider: TVTopShelfContentProvider {
    func topShelfItems() async -> [TVTopShelfItem] {
        // TVTopShelfCarouselItem — 미리보기 영상, HDR 배지
        // TVTopShelfSectionedContent — 이미지 그리드
    }
}
```

`topShelfContentDidChange()`로 업데이트 알림.

### Landing Page (tvOS 18+)

Above/below-the-fold 패턴:
- `containerRelativeFrame(.vertical)` — 헤더 크기
- `onScrollVisibilityChange` — fold 감지
- `scrollTargetBehavior(.viewAligned)` — snap 스크롤

### TabView

```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Search", systemImage: "magnifyingglass") { SearchView() }
}
.tabViewStyle(.sidebarAdaptable)  // tvOS 18+: 사이드바 스타일
```

tvOS: 상단 탭바 (기본) 또는 사이드바.

---

## 리모컨 인터랙션

### SwiftUI 커맨드

```swift
.onMoveCommand { direction in /* .up, .down, .left, .right */ }
.onPlayPauseCommand { /* 재생/일시정지 */ }
.onExitCommand { /* 메뉴 버튼 */ }
```

### 제스처 제한

`DragGesture`, `MagnificationGesture`, `RotationGesture`, `LongPressGesture` **사용 불가**.
`contextMenu`는 가능 (리모컨 터치 표면 롱프레스).

### Game Controller

```swift
// Siri Remote: GCMicroGamepad
// Full controller: GCExtendedGamepad
GCController.controllers()  // 연결된 컨트롤러
// GCControllerDidConnect / GCControllerDidDisconnect 노티피케이션
```

---

## 미디어 재생

### AVPlayerViewController

tvOS 네이티브 전송 컨트롤 자동 제공.

tvOS 전용 프로퍼티:
- `playbackControlsIncludeTransportBar` — 전송 바
- `transportBarCustomMenuItems` — 커스텀 액션
- `customInfoViewControllers` — 콘텐츠 탭
- `contextualActions` — 재생 중 액션
- `customOverlayViewController` — 오버레이

콘텐츠 기능:
- `AVNavigationMarkersGroup` — 챕터 네비게이션
- `AVInterstitialTimeRange` — 광고/인터스티셜 (스킵 제한)
- `AVContentProposal` — "다음 콘텐츠" 제안

Siri 통합 자동: "15초 건너뛰기", "뭐라고 했어?" 음성 명령.

---

## SwiftUI on tvOS — iOS와의 차이

1. **모든 인터랙션이 포커스 기반** — 탭 제스처 없음, 포커스 + 선택
2. **`.borderless` 버튼** → tvOS에서 표준 lockup 효과 (lift/parallax). iOS에서는 plain 텍스트
3. **`.card` 버튼** → tvOS 전용 (tvOS 14+)
4. **`focusSection()`** → 방향 네비게이션에 **필수**
5. **`.scrollClipDisabled()`** → 포커스 효과 클리핑 방지에 **필수**
6. **`containerRelativeFrame`** (tvOS 17+) → 수동 크기 계산 대체
7. **`TabView`** → 상단 배치 (iOS: 하단)

---

## Deprecated 패턴

| Deprecated | 대체 | 시점 |
|---|---|---|
| TVML / TVMLKit | SwiftUI | tvOS 18 |
| `TVUserManager.currentUserIdentifier` | `shouldStorePreferencesForCurrentUser` | — |
| `UIScreen.mainScreen` | `UIScreen.main` | tvOS 26 deprecated |
| TLS 1.0/1.1 | TLS 1.2 최소 | tvOS 26 |

### 선호 패턴

- SwiftUI > UIKit (특히 미디어 카탈로그)
- `.borderless` 버튼 (커스텀 스타일 아님)
- `containerRelativeFrame` (수동 frame 아님)
- `focusSection()` + `.scrollClipDisabled()` 필수
