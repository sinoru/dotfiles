---
name: apple-platform
description: >-
  Apple platform development guide covering SwiftUI, UIKit, AppKit, Combine,
  Objective-C, and cross-platform patterns for iOS, macOS, watchOS, tvOS, and
  visionOS. Use this skill whenever writing, modifying, reviewing, or discussing
  Apple platform UI/framework code — including SwiftUI views, UIKit view
  controllers, AppKit windows, Combine pipelines, Objective-C source files (.m,
  .mm), or Swift-ObjC bridging. Trigger when editing .swift files that import
  Apple frameworks (SwiftUI, UIKit, AppKit, Combine, Foundation on Apple
  platforms), .m/.mm files, .xib/.storyboard references, or when the user asks
  about Apple HIG, WWDC best practices, or platform-specific architecture. Even
  without explicit mention, trigger when context involves Apple platform UI, app
  lifecycle, widgets, Live Activities, or framework integration. Also trigger for
  watchOS complications, tvOS focus-based UI, visionOS spatial computing, or any
  Apple platform design decisions. This skill complements the swiftlang skill
  (Swift language itself) — use both together when working on Apple platform Swift code.
---

# Apple Platform Development Guide

Apple 플랫폼(iOS, macOS, watchOS, tvOS, visionOS) 프레임워크 활용 가이드.
Swift 언어 자체(문법, 동시성, API 디자인 가이드라인)는 **swiftlang** 스킬을 참조.
이 스킬은 플랫폼 프레임워크를 올바르게 사용하는 방법에 집중한다.

## Core Principles

### Prefer the Latest, Avoid the Deprecated

- 프로젝트의 deployment target 내에서 가장 최신 API와 패턴을 우선 사용한다.
- Apple이 deprecated로 표시한 API는 사용하지 않는다. 대체 API가 있으면 그것을 쓴다.
- deprecated API를 불가피하게 써야 하면 이유를 명시한다.
- 최신 전용 API 사용 시 `if #available` / `@available`로 분기하고 fallback을 제공한다.
- 핵심 기능이 deployment target에서 쓸 수 없는 API에 의존할 경우, 트레이드오프를 먼저 설명한다.
- **불확실하면 sosumi 스킬로 공식 문서를 확인한다.** API 동작이나 가용성을 추측하지 않는다.

### Follow the Framework's Grain

Apple 프레임워크는 각자의 설계 패턴을 갖고 있다. 외부 아키텍처 방법론(MVVM, VIPER 등)을 프레임워크 위에 덧씌우기보다, 프레임워크가 의도한 방식으로 코드를 구성한다.

- **SwiftUI** — `@Observable`로 공유 상태, `@State`로 뷰 로컬 상태, `@Environment`로 의존성 주입. 프레임워크의 데이터 흐름이 곧 아키텍처. 별도 "ViewModel" 레이어가 반드시 필요한 건 아니다.
- **UIKit** — Delegate, DataSource, Composition 패턴으로 뷰 컨트롤러를 가볍게 유지. UIContentConfiguration, DiffableDataSource 등 시스템이 제공하는 최신 패턴 활용.
- **AppKit** — NSDocument, NSWindowController, delegate/target-action 등 Cocoa 패턴 준수.
- **Objective-C** — Cocoa의 delegate/target-action/notification/KVO 패턴.

### Follow Apple Framework Conventions

- Apple 프레임워크의 기존 패턴과 네이밍 관례를 따른다.
- Delegate 메서드 첫 번째 파라미터는 호출자(delegate source):
  ```swift
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  ```
  ```objc
  - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
  ```

### Design with HIG in Mind

코드를 작성할 때 Apple Human Interface Guidelines를 고려한다:

- **접근성**: 최소 터치 타겟 44×44pt (visionOS 60×60pt), 색상 대비 4.5:1 (본문), Dynamic Type 지원
- **시스템 컬러/폰트**: 하드코딩 대신 semantic 색상(`label`, `systemBackground`)과 text style(`.body`, `.headline`) 사용
- **플랫폼 관례**: 각 플랫폼의 네비게이션/인터랙션 패턴 준수 (iOS 탭바, macOS 메뉴바, tvOS 포커스, visionOS 시선+핀치)
- **Dark Mode**: 모든 플랫폼에서 light/dark 모드 지원. semantic 색상 사용으로 자동 대응.
- **Liquid Glass** (iOS 26+, macOS Tahoe+): 최신 디자인 시스템. 표준 컴포넌트는 자동 적용.

상세 기준값과 플랫폼별 디자인 원칙은 `references/hig.md` 참조.

---

## Framework Selection

새 UI 코드를 작성할 때 프로젝트 상황에 맞는 프레임워크를 선택한다:

| 상황 | 권장 | 이유 |
|------|------|------|
| 새 프로젝트, 최신 OS 타겟 | **SwiftUI** | 선언적, 멀티 플랫폼, Apple이 적극 투자 중 |
| 기존 UIKit/AppKit 코드베이스 | **기존 프레임워크 유지** + 새 화면은 SwiftUI 검토 | 일관성 우선, 점진적 도입 |
| SwiftUI로 어려운 고급 커스텀 UI | **UIKit/AppKit** + Representable로 통합 | SwiftUI에서 감싸서 사용 |

SwiftUI ↔ UIKit/AppKit 통합 패턴:
- `UIHostingController` / `NSHostingController` — SwiftUI를 UIKit/AppKit에 임베딩
- `UIHostingConfiguration` (iOS 16+) — UIKit 셀에 SwiftUI 직접 사용
- `UIViewRepresentable` / `NSViewRepresentable` — UIKit/AppKit 뷰를 SwiftUI에 임베딩

---

## Objective-C Essentials

Objective-C 코드를 작성하거나 Swift와 연동할 때의 핵심 규칙.

### Nullability — 모든 공개 헤더에 적용

```objc
NS_ASSUME_NONNULL_BEGIN
@interface MYService : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, nullable) id<MYDelegate> delegate;
- (void)fetchWithCompletion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion;
@end
NS_ASSUME_NONNULL_END
```

annotation이 없으면 Swift에서 `!` (implicitly unwrapped optional)로 들어오므로, 반드시 annotate한다.

### Swift Bridging Annotations

| Annotation | 용도 |
|---|---|
| `NS_SWIFT_NAME(name)` | Swift에서의 이름 지정 |
| `NS_REFINED_FOR_SWIFT` | `__` 접두사로 숨기고 Swift wrapper 작성 유도 |
| `NS_SWIFT_UNAVAILABLE("msg")` | Swift에서 완전 숨김 |
| `NS_CLOSED_ENUM` | exhaustive switch 가능한 frozen enum |
| `NS_TYPED_ENUM` / `NS_TYPED_EXTENSIBLE_ENUM` | 상수 그룹을 struct로 매핑 |
| `NS_SWIFT_ASYNC_NAME("name")` | async import 시 이름 지정 |
| `NS_SWIFT_SENDABLE` / `NS_SWIFT_NONSENDABLE` | Sendable 적합성 제어 |

### ARC & Retain Cycle 방지

```objc
__weak __typeof(self) weakSelf = self;
[self doSomethingWithBlock:^{
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    [strongSelf doWork];
}];
```

- Delegate는 항상 `weak`. Timer target도 `weak`.
- Block이 self를 캡처하고 self가 block을 retain하면 cycle 발생.

상세한 annotation 목록, bridging 설정, 동시성 브릿징은 `references/objective-c.md` 참조.

---

## Key Deprecations to Know

최근 주요 deprecated 패턴과 대체:

| Deprecated | 대체 | 시점 |
|---|---|---|
| `NavigationView` | `NavigationStack` / `NavigationSplitView` | iOS 16 |
| `ObservableObject` + `@Published` | `@Observable` 매크로 | iOS 17 |
| `@StateObject` | `@State` (with `@Observable`) | iOS 17 |
| `@ObservedObject` | plain property 또는 `@Bindable` | iOS 17 |
| `@EnvironmentObject` | `@Environment(Type.self)` | iOS 17 |
| `ClockKit` complications | WidgetKit accessory families | watchOS 9 |
| TVML / TVMLKit | SwiftUI | tvOS 18 |
| Original StoreKit API | StoreKit 2 | iOS 18 (deprecated) |
| `UIApplicationDelegate`-only lifecycle | `UISceneDelegate` | iOS 13 (필수: iOS 27) |

---

## Detailed References

아래 레퍼런스 파일에서 프레임워크/플랫폼별 상세 패턴을 확인할 수 있다.
관련 파일만 필요할 때 읽으면 된다.

### Framework References

**`references/foundation.md`** — Modern Foundation
FormatStyle(.formatted()), AttributedString, #Predicate, RegexBuilder,
URLSession async/await, NotificationCenter.notifications, Duration/Clock,
KVO in Swift vs @Observable, Codable 고급 패턴, UserDefaults.
**읽을 시점**: Foundation API 사용, 레거시 Formatter/NSPredicate 대체, 비동기 네트워킹 시.

**`references/swiftui.md`** — SwiftUI 심화
State 관리(@State, @Binding, @Environment, @Observable, @Bindable, @Entry), Navigation
(NavigationStack, NavigationSplitView), SwiftData 통합(@Model, @Query, ModelContainer),
성능 최적화, UIKit/AppKit interop. **읽을 시점**: SwiftUI 뷰 작성, 데이터 흐름 설계, SwiftData 사용 시.

**`references/uikit.md`** — Modern UIKit
CellRegistration, UIContentConfiguration, DiffableDataSource, CompositionalLayout,
viewIsAppearing, Trait 시스템, 자동 trait 추적(iOS 18), Observable 통합(iOS 26),
Liquid Glass. **읽을 시점**: UIKit 코드 작성/수정, UIKit↔SwiftUI 통합 시.

**`references/appkit.md`** — macOS AppKit
NSWindow/NSViewController, 툴바, 메뉴, NSGlassEffectView(macOS Tahoe),
SwiftUI 브릿징(NSHostingView, sceneBridgingOptions).
**읽을 시점**: macOS 네이티브 AppKit 코드 작성 시.

**`references/combine.md`** — Combine & Reactive Patterns
Combine 현재 상태(사실상 유지보수 모드), AsyncSequence 마이그레이션, .values 브릿지,
operator 대응표, 언제 Combine을 여전히 써야 하는지.
**읽을 시점**: Combine 코드 작성/마이그레이션, reactive 패턴 결정 시.

**`references/objective-c.md`** — Objective-C 심화
전체 annotation 목록, bridging 설정(헤더/모듈맵), Swift↔ObjC 양방향 패턴,
동시성 브릿징(completion handler ↔ async), SE-0436 `@objc @implementation`.
**읽을 시점**: ObjC 코드 작성, Swift-ObjC interop 설계 시.

### Platform References

**`references/platforms/ios.md`** — iOS 플랫폼
Scene 기반 라이프사이클, iPad 멀티태스킹, WidgetKit/Live Activities/ActivityKit,
App Intents/Apple Intelligence, StoreKit 2, 백그라운드 처리, 푸시 알림, TipKit.
**읽을 시점**: iOS 앱 기능(위젯, Live Activity, IAP, 백그라운드 등) 구현 시.

**`references/platforms/macos.md`** — macOS 플랫폼
윈도우 관리(WindowGroup, Window, UtilityWindow), MenuBarExtra, 문서 기반 앱,
메뉴/툴바/키보드 단축키, Settings scene, 샌드박싱/공증, FocusedValues.
**읽을 시점**: macOS 앱 기능(윈도우, 메뉴바, 배포 등) 구현 시.

**`references/platforms/watchos.md`** — watchOS
SwiftUI 라이프사이클, watchOS 10 네비게이션 패러다임(수직 TabView + Digital Crown),
WidgetKit complications, WatchConnectivity, Live Activities(watchOS 11), workout/HealthKit.
**읽을 시점**: watchOS 앱/컴플리케이션 개발 시.

**`references/platforms/tvos.md`** — tvOS
Focus engine, 리모컨 인터랙션, Top Shelf, 컨텐츠 shelf/lockup 패턴,
미디어 재생(AVPlayerViewController), TVML→SwiftUI 마이그레이션.
**읽을 시점**: tvOS 앱 개발 시.

**`references/platforms/visionos.md`** — visionOS
Window/Volume/ImmersiveSpace, RealityKit(RealityView, Model3D, ECS),
공간 입력(시선+핀치), ornaments, 호버 이펙트, iOS→visionOS 포팅.
**읽을 시점**: visionOS 앱 개발, 공간 컴퓨팅 기능 구현 시.

### Cross-Cutting References

**`references/cross-platform.md`** — 멀티 플랫폼 전략
조건부 컴파일(`#if canImport` > `#if os`), 프로젝트 구조,
플랫폼별 적응 패턴(NavigationSplitView, TabView, toolbar 배치).
**읽을 시점**: 멀티 플랫폼 앱 설계, 플랫폼 분기 코드 작성 시.

**`references/hig.md`** — Human Interface Guidelines
디자인 원칙(Clarity, Deference, Depth), 플랫폼별 디자인 특성,
타이포그래피/컬러 기준값, 레이아웃/간격, 접근성 수치, 네비게이션 패턴,
Liquid Glass 디자인 시스템.
**읽을 시점**: UI 설계 결정, 접근성 검토, 플랫폼별 디자인 차이 확인 시.
