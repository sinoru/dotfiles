# watchOS Reference

## Table of Contents
1. [앱 아키텍처](#앱-아키텍처)
2. [watchOS 10 네비게이션 패러다임](#watchos-10-네비게이션-패러다임)
3. [WidgetKit Complications](#widgetkit-complications)
4. [Digital Crown](#digital-crown)
5. [Watch Connectivity](#watch-connectivity)
6. [Workout / HealthKit](#workout--healthkit)
7. [Live Activities (watchOS 11)](#live-activities-watchos-11)
8. [성능 & 백그라운드](#성능--백그라운드)
9. [Deprecated 패턴](#deprecated-패턴)

---

## 앱 아키텍처

### SwiftUI 라이프사이클 (watchOS 7+, 권장)

```swift
@main
struct MyWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- `WKInterfaceController` (스토리보드 기반)는 레거시 — 모든 신규 개발은 SwiftUI
- 독립 실행: `WKRunsIndependentlyOfCompanionApp` (Info.plist)
- watch 전용: `WKWatchOnly`

---

## watchOS 10 네비게이션 패러다임

watchOS 10에서 네비게이션이 완전히 개편되었다.

### 수직 TabView (watchOS 10+)

수평 스와이프 → 수직 Digital Crown 페이징으로 변경:

```swift
TabView {
    SummaryView()
        .containerBackground(.blue.gradient, for: .tabView)
    DetailView()
        .containerBackground(.green.gradient, for: .tabView)
    SettingsView()  // 스크롤 콘텐츠는 마지막 탭에
}
```

- Digital Crown으로 탭 전환, 페이지 인디케이터가 crown 옆에 표시
- 스크롤 가능 콘텐츠는 마지막 탭에 배치

### NavigationSplitView (watchOS 9+, watchOS 10 재설계)

source-list → detail 관계. watchOS에서 스택으로 축소. 앱 시작 시 detail 뷰 직접 표시, 좌상단 탭으로 source list 접근.

### containerBackground (watchOS 10+)

```swift
.containerBackground(.blue.gradient, for: .navigation)
.containerBackground(.fill, for: .widget)
```

배치: `.tabView`, `.navigation`, `.widget`, `.navigationSplitView`

### 3가지 기본 레이아웃

- **Dial** — 원형 정보 표시
- **Infographic** — 차트/데이터 시각화
- **List** — 스크롤 가능 콘텐츠

### 툴바 (watchOS 10)

- `.topBarTrailing`, `.topBarLeading` — 새 배치
- bottom bar — 인터랙티브 컨트롤
- `.controlSize(.large)` — 강조 버튼

---

## WidgetKit Complications

ClockKit deprecated → WidgetKit 사용.

### Accessory Families

- `accessoryCircular` — 원형
- `accessoryCorner` — 모서리
- `accessoryRectangular` — 직사각형
- `accessoryInline` — 한 줄 텍스트

### Smart Stack Relevance

```swift
TimelineEntryRelevance(score: 75, duration: 3600)
```

### 마이그레이션

`CLKComplicationStaticWidgetMigrationConfiguration` 등으로 ClockKit → WidgetKit 자동 이관.

### AccessoryWidgetGroup (watchOS 11+)

```swift
AccessoryWidgetGroup("Weather", systemImage: "cloud.sun.fill") {
    TemperatureWidgetView(entry.temperature)
    ConditionsWidgetView(entry.conditions)
    UVIndexWidgetView(entry.UVIndex)
}
.accessoryWidgetGroupStyle(.circular)
```

`.accessoryRectangular`에서 3개 뷰 수평 배치.

---

## Digital Crown

```swift
.digitalCrownRotation(
    $value,
    from: 0.0, through: 10.0, by: 0.1,
    sensitivity: .low,
    isContinuous: true,
    isHapticFeedbackEnabled: true
)
```

watchOS 10에서 Digital Crown이 기본 네비게이션 입력으로 강화.

---

## Watch Connectivity

### WCSession 설정

```swift
if WCSession.isSupported() {
    let session = WCSession.default
    session.delegate = self
    session.activate()
}
```

### 5가지 통신 패턴

| 패턴 | 메서드 | 특성 |
|------|--------|------|
| Immediate Messages | `sendMessage(_:replyHandler:errorHandler:)` | 실시간, reachability 필요 |
| Application Context | `updateApplicationContext(_:)` | 최신값만, 백그라운드 전달 |
| User Info Transfer | `transferUserInfo(_:)` | 큐잉, 전원 주기 생존 |
| File Transfer | `transferFile(_:metadata:)` | 백그라운드, 진행 모니터링 |
| Complication Data | `transferCurrentComplicationUserInfo(_:)` | 우선순위, 예산 제한 |

### 상태 프로퍼티

`isPaired`, `isWatchAppInstalled`, `isCompanionAppInstalled`, `isReachable`

---

## Workout / HealthKit

### HKWorkoutSession (watchOS 2+)

```swift
session.prepare()
session.startActivity(with: Date())
session.pause()
session.resume()
session.stopActivity(with: Date())
session.end()
```

- 동시에 하나의 workout session만 실행
- 센서 최적화 (심박수 고빈도 등)

### HKLiveWorkoutBuilder (watchOS 5+)

- 라이브 데이터에서 workout 샘플 점진적 구성
- `elapsedTime` — 일시정지 포함 경과 시간

### 미러링 (멀티 디바이스)

`startMirroringToCompanionDevice` — iPhone ↔ Watch 양방향 workout 미러링.

---

## Live Activities (watchOS 11)

iOS Live Activities가 자동으로 Smart Stack에 표시. 추가 코드 불필요.

### Watch 커스텀 레이아웃

```swift
.supplementalActivityFamilies([.small])
```

`activityFamily` 환경 값으로 watch 전용 레이아웃 제공.

### Always On Display

`isLuminanceReduced` 환경 값으로 밝은 요소 조정.

---

## 성능 & 백그라운드

### 백그라운드 갱신 예산

- 활성 complication 있는 앱: 시간당 ~4회
- watchOS 9+: `.backgroundTask(_:action:)` SwiftUI modifier 선호

### Extended Runtime Session (watchOS 6+)

Self Care, Mindfulness, Physical Therapy, Smart Alarm 타입.
화면 꺼진 상태에서 Bluetooth, 오디오, 햅틱 지원.

### 제약

- 간결한 인터랙션 설계 (1분 이내)
- 네비게이션 계층 최소화
- full-width 컨트롤 선호 (2-3개 나란히 최대)

---

## Deprecated 패턴

| Deprecated | 대체 | 시점 |
|---|---|---|
| ClockKit complications | WidgetKit accessory families | watchOS 9+ |
| `WKInterfaceController` (스토리보드) | SwiftUI `@main` App | watchOS 7+ |
| 수평 페이지 네비게이션 | 수직 TabView + Digital Crown | watchOS 10 |
| `ignoresSafeArea` (위젯) | `contentMarginsDisabled()` | watchOS 10 |
| `WKExtension` delegate | `WKApplication` delegate 또는 SwiftUI | — |
| 수동 background refresh 스케줄링 | `.backgroundTask` SwiftUI modifier | watchOS 9+ |
