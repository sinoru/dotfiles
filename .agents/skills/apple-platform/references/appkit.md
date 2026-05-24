# AppKit Reference

## Table of Contents
1. [NSWindow & NSViewController](#nswindow--nsviewcontroller)
2. [툴바 & 메뉴](#툴바--메뉴)
3. [SwiftUI 브릿지](#swiftui-브릿지)
4. [macOS Sonoma (14) 추가](#macos-sonoma-14-추가)
5. [macOS Sequoia (15) 추가](#macos-sequoia-15-추가)
6. [macOS Tahoe (26) / Liquid Glass](#macos-tahoe-26--liquid-glass)

---

## NSWindow & NSViewController

### NSWindow 핵심

- **Key window**: 키보드/마우스 이벤트 수신
- **Main window**: 활성 문서 윈도우
- 윈도우 레벨로 z-order 제어
- 탭: `tabbingIdentifier`로 관련 윈도우 그룹핑
- 복원: `isRestorable`, frame autosave name으로 상태 유지

### 툴바 스타일

| 스타일 | 설명 |
|--------|------|
| `.automatic` | 시스템 기본 |
| `.expanded` | 타이틀 아래 |
| `.preference` | 타이틀 아래, 중앙 정렬 |
| `.unified` | 타이틀 옆 |
| `.unifiedCompact` | 타이틀 옆, 축소 마진 |

### @ViewLoading / @WindowLoading (macOS 14+)

NSViewController/NSWindowController 프로퍼티에서 optionality 제거:

```swift
class MyVC: NSViewController {
    @ViewLoading var label: NSTextField
    // viewDidLoad에서 초기화, 이후 non-optional 접근
}
```

---

## 툴바 & 메뉴

### NSToolbar

- `allowsUserCustomization`, `autosavesConfiguration` — 사용자 커스터마이제이션 + 영속
- macOS 15+: `.toolbar(removing:)`, `.toolbarBackgroundVisibility()` (SwiftUI)
- macOS Tahoe: 아이템 자동 glass 렌더링. `isBordered = false`로 비인터랙티브 아이템 표시.

### 메뉴 시스템 (macOS 14+)

- `NSMenuItem.sectionHeader(title:)` — 섹션 헤더
- palette 메뉴: `.presentationStyle = .palette`
- 메뉴 배지 지원

### 활성화 (macOS 14+)

`activate(ignoringOtherApps:)` deprecated → `activate()` (요청 기반) + `yieldActivation(to:)`.

---

## SwiftUI 브릿지

### NSViewRepresentable

```swift
struct MyAppKitView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSTextField { NSTextField() }
    func updateNSView(_ nsView: NSTextField, context: Context) { /* 상태 반영 */ }
    func makeCoordinator() -> Coordinator { Coordinator() }
}
```

frame/bounds 직접 수정 금지.

### NSHostingView / NSHostingController

AppKit에 SwiftUI 임베딩. `sceneBridgingOptions`로 SwiftUI modifier(`.toolbar`, `.navigationTitle`)가 NSWindow에 반영.

### NSHostingMenu (macOS 15+)

SwiftUI로 정의된 메뉴를 AppKit에서 사용:

```swift
let menu = NSHostingMenu(rootView: menuView)
```

### SwiftUI 애니메이션 (macOS 15+)

`NSAnimationContext.runAnimationGroup`에서 SwiftUI `Animation` 타입 사용 가능.

---

## macOS Sonoma (14) 추가

- Inspector API: trailing split view, Big Sur까지 back-deploy
- NSPopover: 툴바 앵커링, full-size content
- NSBezierPath.cgPath: CGPath 변환
- CADisplayLink on macOS (`NSView.displayLink`)
- NSColor system fills: `systemFill` ~ `quinarySystemFill`
- 뷰가 기본적으로 bounds 클리핑하지 않음
- Symbol effects: `addSymbolEffect()` (NSImageView)
- HDR: NSImageView 네이티브 HDR 표시
- NSColor, NSShadow: `Sendable`
- NSImage, NSColor, NSSound: `Transferable`
- Preview 매크로 for AppKit 뷰

---

## macOS Sequoia (15) 추가

- 텍스트 하이라이트: `textHighlight` attributed string 속성
- 텍스트 입력 제안: `NSTextField.suggestionsDelegate`
- 커서 API: `NSCursor.frameResize`, `.columnResize`, `.zoomIn`, `.zoomOut`
- NSSavePanel.showsContentTypes: 파일 형식 피커
- UtilityWindow scene (SwiftUI)
- 윈도우 배치 API: `.defaultWindowPlacement()`, `.windowIdealPlacement()`
- Plain window style: 경계 없는 윈도우
- 윈도우 타일링: `cascadingReferenceFrame`

---

## macOS Tahoe (26) / Liquid Glass

### 자동 적용

SDK 26으로 빌드하면 모든 표준 컴포넌트가 Liquid Glass 자동 적용.

### NSGlassEffectView

```swift
let glass = NSGlassEffectView()
glass.contentView = targetView
glass.cornerRadius = 12
glass.tintColor = .systemBlue
```

### NSGlassEffectContainerView

여러 glass 요소를 그룹핑. 유동적 합류/분리 애니메이션, 균일 적응, 올바른 샘플링.

### NSBackgroundExtensionView

플로팅 사이드바 아래로 콘텐츠(아트워크) 확장. 미러/블러 복제.

### Layout Region

`NSView.LayoutRegion` — Liquid Glass 라운드 코너를 인식하는 레이아웃.
`layoutGuide()` 메서드로 Auto Layout 제약.

### ScrollEdgeEffect

`.soft` (점진적 페이드/블러) / `.hard` (불투명 배킹) — 툴바/액세서리 아래.

### 컨트롤 크기 변경

Extra Large 추가. Mini/Small/Medium 높이 증가.
`prefersCompactControlSizeMetrics = true`로 기존 크기 유지 가능.

### 주의사항

- 사이드바에서 기존 `NSVisualEffectView` 제거 — glass material 차단
- `isBordered = false`로 비인터랙티브 툴바 아이템 표시
- `NSItemBadge`로 콘텐츠 인디케이터
