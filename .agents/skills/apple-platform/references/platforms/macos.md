# macOS Platform Reference

## Table of Contents
1. [앱 라이프사이클](#앱-라이프사이클)
2. [윈도우 관리](#윈도우-관리)
3. [메뉴바 앱](#메뉴바-앱)
4. [문서 기반 앱](#문서-기반-앱)
5. [메뉴 & 키보드 단축키](#메뉴--키보드-단축키)
6. [Settings](#settings)
7. [샌드박싱 & 보안](#샌드박싱--보안)
8. [공증 & 배포](#공증--배포)
9. [macOS 고유 SwiftUI 패턴](#macos-고유-swiftui-패턴)

---

## 앱 라이프사이클

### Activation Policy

| 정책 | Dock 아이콘 | 메뉴바 | 윈도우 |
|------|------------|--------|--------|
| `.regular` | O | O | O |
| `.accessory` | X | X | O (활성화 가능) |
| `.prohibited` | X | X | X (백그라운드 전용) |

### NSApplicationDelegate 핵심

- `applicationShouldTerminateAfterLastWindowClosed(_:)` → `true` 반환 시 자동 종료
- `applicationShouldHandleReopen(_:hasVisibleWindows:)` → Dock 클릭 처리
- `applicationDockMenu(_:)` → Dock 우클릭 메뉴

---

## 윈도우 관리

### SwiftUI Scene 타입

**WindowGroup** — 동일 구조의 복수 윈도우:
```swift
WindowGroup {
    ContentView()
}
.defaultSize(CGSize(width: 600, height: 400))
.defaultPosition(.center)
```

**Window** (macOS 13+) — 단일 고유 윈도우:
```swift
Window("Connection Doctor", id: "connection-doctor") {
    ConnectionDoctor()
}
```

**UtilityWindow** (macOS 15+) — 플로팅 도구 팔레트/인스펙터:
```swift
UtilityWindow("Photo Info", id: "photo-info") {
    PhotoInfoViewer()
}
```
- FocusedValues를 포커스된 메인 씬에서 수신
- 부모 포커스 잃으면 자동 숨김
- View 메뉴에 show/hide 항목 자동 추가

### 윈도우 크기 & 위치 (macOS 13+)

```swift
.defaultSize(width: 600, height: 400)
.defaultPosition(.topLeading)
.windowResizability(.contentSize)        // 콘텐츠에 고정
.windowResizability(.contentMinSize)     // 확장 가능
.defaultWindowPlacement { content, context in ... }  // macOS 15+
```

### 프로그래매틱 제어

```swift
@Environment(\.openWindow) private var openWindow
@Environment(\.dismiss) private var dismiss

openWindow(id: "mail-viewer")
openWindow(id: "message", value: messageID)  // Hashable + Codable 데이터
```

---

## 메뉴바 앱

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

- `.menuBarExtraStyle(.window)` — 팝오버 스타일
- `isInserted` 바인딩으로 가시성 제어
- Dock 없는 앱: `LSUIElement = true` (Info.plist)

---

## 문서 기반 앱

### DocumentGroup (SwiftUI)

```swift
DocumentGroup(newDocument: TextFile()) { config in
    ContentView(document: config.$document)
}
```

- `FileDocument` (값 타입, `Sendable`) 또는 `ReferenceFileDocument` (참조 타입)
- 직렬화를 `@MainActor`에서 수행하지 않는다
- SwiftData 기반 문서 지원

---

## 메뉴 & 키보드 단축키

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

- `CommandGroupPlacement`: `.appInfo`, `.appSettings`, `.newItem`, `.saveItem`, `.undoRedo`, `.pasteboard`, `.sidebar`, `.toolbar`, `.help` 등
- `.commandsRemoved()` — 기본 커맨드 제거
- `onKeyPress` (macOS 14+) — focusable 뷰에서 하드웨어 키보드 입력

### FocusedValues — 멀티 윈도우

`@FocusedValue` — 포커스된 뷰 계층의 값 관찰. 메뉴/커맨드를 활성 윈도우 상태에 연결하는 핵심.

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

자동으로 Settings 메뉴 항목 (Cmd+,) 생성.
`SettingsLink` (macOS 14+), `openSettings` environment action으로 프로그래매틱 접근.

---

## 샌드박싱 & 보안

### App Sandbox 주요 entitlement

| entitlement | 용도 |
|---|---|
| `com.apple.security.app-sandbox` | 샌드박스 활성화 (Mac App Store 필수) |
| `.network.client` | 아웃바운드 네트워크 |
| `.network.server` | 인바운드 네트워크 |
| `.device.camera` | 카메라 |
| `.device.microphone` | 마이크 |
| `.files.user-selected.read-write` | 사용자 선택 파일 읽기/쓰기 |
| `.files.downloads.read-write` | Downloads 폴더 |

### Security-Scoped URL

```swift
let gotAccess = url.startAccessingSecurityScopedResource()
defer { url.stopAccessingSecurityScopedResource() }
// url 사용
```

`fileImporter` 등으로 얻은 URL에서 필요.

---

## 공증 & 배포

### 요구사항

- Developer ID 인증서로 코드 서명
- Hardened Runtime 활성화
- secure timestamp 포함
- `com.apple.security.get-task-allow` entitlement 제거

### 워크플로우

- **Xcode**: Archive → Organizer → Distribute App → Developer ID → Upload (자동 staple)
- **CLI**: `notarytool` 사용 (`altool`은 2023.11 deprecated)
- 처리 시간: 보통 1시간 이내

### 배포 경로

- **Mac App Store**: 공증 불필요 (제출 과정에 포함)
- **Developer ID**: 공증 필수

---

## macOS 고유 SwiftUI 패턴

### Inspector (macOS 14+)

```swift
.inspector(isPresented: $showInspector) {
    InspectorView()
}
.inspectorColumnWidth(min: 200, ideal: 300, max: 400)
```

macOS: trailing 사이드바. compact에서: sheet.

### Context Menu

macOS: 우클릭 (미리보기 없음, iOS와 다름).
`contextMenu(forSelectionType:menu:primaryAction:)` — List/Table 선택 인식.

### Hover

```swift
.onHover { isHovering in ... }
.onContinuousHover { phase in ... }  // 좌표 추적
```

### External Event Routing

```swift
.handlesExternalEvents(matching: Set<String>)     // scene 수준
.handlesExternalEvents(preferring:allowing:)       // view 수준 — URL 라우팅
```

### macOS vs iOS 차이

| macOS | iOS |
|-------|-----|
| 다중 리사이즈 가능 윈도우 | 단일 윈도우 (iPad 제한적 멀티) |
| 전체 메뉴바 + Cmd 단축키 | 메뉴바 없음 |
| 키보드 우선 네비게이션 | 터치 우선 |
| hover, 우클릭 | 터치, 롱프레스 |
| 5가지 툴바 스타일 | 표준 네비게이션바 |
| Settings scene (Cmd+,) | 인앱 설정 또는 Settings.app |
| App Store 또는 Developer ID | App Store 전용 |
