# visionOS Reference

## Table of Contents
1. [앱 유형: Window, Volume, ImmersiveSpace](#앱-유형)
2. [SwiftUI on visionOS](#swiftui-on-visionos)
3. [RealityKit](#realitykit)
4. [공간 입력](#공간-입력)
5. [iOS/iPadOS에서 포팅](#iosipados에서-포팅)
6. [디자인 원칙](#디자인-원칙)
7. [visionOS 2 (2024)](#visionos-2-2024)
8. [visionOS 3 (2025)](#visionos-3-2025)
9. [성능](#성능)

---

## 앱 유형

### Window

기존 2D 콘텐츠. glass material 배경. 다른 앱과 Shared Space에서 공존.
Model3D로 인라인 3D 콘텐츠 혼합 가능.

```swift
WindowGroup { ContentView() }
```

### Volume (visionOS 1+)

개발자가 3축 크기를 제어하는 제한된 3D 컨테이너:

```swift
WindowGroup {
    Model3D(named: "Globe")
}
.windowStyle(.volumetric)
.defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)
```

- Shared Space에서 다른 앱과 공존
- visionOS 2: 리사이즈 가능 (`.windowResizability(.contentSize)`)
- visionOS 2: `.volumeBaseplateVisibility`, `.onVolumeViewpointChange`

### ImmersiveSpace (visionOS 1+)

무한 캔버스. 시스템 전체에서 하나만 열 수 있음.

```swift
ImmersiveSpace(id: "solarSystem") {
    SolarSystem()
}
.immersionStyle(selection: $style, in: .mixed, .progressive, .full)
```

3가지 스타일:
- **Mixed** (기본): 현실 위에 가상 오버레이
- **Progressive**: 포탈형, Digital Crown으로 몰입도 제어
- **Full**: 패스스루 완전 대체

```swift
@Environment(\.openImmersiveSpace) var openImmersiveSpace
@Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

Task { await openImmersiveSpace(id: "solarSystem") }
```

**설계 원칙**: 항상 윈도우에서 시작. 몰입 경험 진입/퇴장은 명시적 컨트롤 제공.

---

## SwiftUI on visionOS

### 자동 전이되는 것

모든 표준 SwiftUI 뷰, 레이아웃, 네비게이션, 제스처, 애니메이션, 접근성.

### visionOS 전용

**Glass Material**:
```swift
.glassBackgroundEffect()
```

**Ornaments** (뷰 외부 부속 요소):
```swift
.toolbar {
    ToolbarItem(placement: .bottomOrnament) { PlaybackControls() }
}
// 커스텀:
.ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .center) {
    HStack { /* content */ }.glassBackgroundEffect()
}
```

**Hover Effect** (인터랙션 피드백에 필수):
```swift
.hoverEffect()
.contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 8))
```

**3D 패딩**:
```swift
.padding3D(.back, 20)
```

**기타**:
- `.preferredSurroundingsEffect(.dark)` — 패스스루 어둡게
- `.upperLimbVisibility(false)` — 실제 손 숨기기

### 좌표계

SwiftUI Y축: 아래. RealityKit Y축: 위. Immersive Space 원점: 사용자 발 근처.

### TabView → 사이드바

visionOS에서 TabView는 윈도우 왼쪽 수직 배치, 시선으로 자동 확장. 사이드바보다 선호.

---

## RealityKit

### Model3D — 단순 3D 모델 (AsyncImage 유사)

```swift
Model3D(named: "toy_robot") { model in
    model.resizable()
} placeholder: {
    ProgressView()
}
```

### RealityView — 복잡한 3D 씬

```swift
RealityView { content in
    let entity = try await ModelEntity(named: "Earth")
    content.add(entity)
} update: { content in
    // SwiftUI 상태 변경 시에만 호출 (렌더 루프 아님!)
} attachments: {
    Attachment(id: "label") {
        Text("Earth").padding().glassBackgroundEffect()
    }
}
```

- visionOS 1+, iOS 18+, macOS 15+ (크로스 플랫폼)
- visionOS 26: 엔티티가 `Observable` 프로토콜 적합

### Entity Component System

- `ModelComponent` — 3D 모델
- `InputTargetComponent` + `CollisionComponent` — 제스처 수신에 **둘 다 필요**
- `HoverEffectComponent` — 호버 시각 피드백
- `SpatialAudioComponent` — 3D 위치 오디오

### 제스처 on 엔티티

```swift
RealityView { content in /* ... */ }
    .gesture(TapGesture().targetedToAnyEntity())
```

### Materials

- `PhysicallyBasedMaterial` — PBR, 조명 반응
- `SimpleMaterial` — 간단한 매개변수
- `UnlitMaterial` — 일정한 외관
- `VideoMaterial` — 비디오 표면
- `ShaderGraphMaterial` — Reality Composer Pro / MaterialX

---

## 공간 입력

### 간접 입력 (기본, 가장 편안함)

시선(eye tracking)으로 대상 식별 + 핀치 제스처로 선택.
앱은 정확한 시선 좌표를 받지 **않음** (프라이버시). hover effect 알림만.

### 직접 입력

가까운 콘텐츠를 직접 터치. 조작 중심 경험에 적합하지만 팔 피로 유발.

### Hand Tracking (ARKit)

```swift
let provider = HandTrackingProvider()
// HandAnchor → HandSkeleton (27 joints)
```

- 명시적 사용자 인가 필요
- Full Space에서만 가능
- visionOS 2: display-rate 전달, 예측 API

### 디자인 제약

- 최소 터치 타겟: **60pt**
- 원형/캡슐/둥근 사각형 모양 사용 (시선 타겟팅용)
- 인터랙티브 콘텐츠를 편안한 시야각 내에 배치

---

## iOS/iPadOS에서 포팅

### 자동 적용

iPad 변형 선호 (iPhone도 지원). 시스템이 네이티브 간격, glass material, hover effect 적용.

### 필요한 수정

- 불투명 배경 → **glass material** (`.glassBackgroundEffect()`)
- 비트맵 에셋 → **벡터 에셋** (거리에 따른 스케일링)
- 인터랙티브 요소에 **`.hoverEffect()`** 추가
- 고정 색상 → **semantic/vibrancy 색상**
- 사이드바 → **TabView** (윈도우가 화면 바운드에 고정되지 않음)
- light/dark 모드 구분 불필요 (adaptive vibrancy 자동 처리)

---

## 디자인 원칙

- **깊이**: 시각적 계층에 활용. 먼 것 = 크게, 가까운 것 = 작지만 두드러지게
- **Grounding shadow**: `GroundingShadowComponent`로 공간 관계 표현
- **텍스트는 평면으로**: 3D는 오브젝트용
- **인체공학**: 가로 레이아웃, 콘텐츠를 공간에 고정 (사용자 시점에 고정하지 않음), 극단적 각도 회피
- **접근성**: VoiceOver, Dwell Control, Switch Control 모두 지원

---

## visionOS 2 (2024)

- 리사이즈 가능 Volume + baseplate 가시성 + viewpoint 인식
- 커스텀 Hover Effect (`CustomHoverEffect` 프로토콜)
- Room Tracking (`RoomTrackingProvider`), Object Tracking
- 동적 조명/그림자 (spotlight, directional, point)
- Portal Crossing (`PortalCrossingComponent`)
- 물리 관절 (fixed, spherical, revolute, prismatic, distance)
- Enterprise API: 카메라, 바코드, Neural Engine (관리 entitlement)
- TabletopKit: 공간 테이블탑 게임

---

## visionOS 3 (2025)

- 3D 레이아웃: `Alignment3D`, `SpatialContainer`, `SpatialOverlay`
- 환경 오클루전 (가상 객체가 실제 물체에 가려짐)
- `.manipulable` modifier — 손 제스처로 객체 이동/회전
- Look-to-Scroll — 핸즈프리 시선 스크롤
- `RemoteImmersiveSpace` — macOS Tahoe에서 Vision Pro로 스트리밍
- PS VR2 Sense 컨트롤러 지원
- 3배 빠른 hand tracking
- Volume 내 alert/sheet/popover 표시 가능
- 콘텐츠가 정의 경계 밖으로 확장 가능 ("peeking")

---

## 성능

### 렌더링

- 선언적: 콘텐츠 기술 → 시스템이 양쪽 눈 자동 렌더
- 목표 프레임: 90Hz
- Foveated rendering: 시선 방향 고해상도, 주변부 저해상도 (RealityKit 자동)

### Shared Space vs Full Space

- Shared Space: 다른 앱과 렌더링 자원 공유, 제한된 GPU
- Full Space: 전용 렌더링 자원, 다른 앱 숨김

### 최적화

- `GroundingShadowComponent` (전체 동적 그림자보다 저렴)
- Image-Based Lighting (IBL)
- 세밀 geometry → 큰 삼각형 + opacity 텍스처 (주변부)
- CompositorServices: 커스텀 Metal 파이프라인 필요 시에만 (대부분 RealityKit 사용)
