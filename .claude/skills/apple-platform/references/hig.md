# Human Interface Guidelines Reference

## Table of Contents
1. [핵심 원칙](#핵심-원칙)
2. [플랫폼별 디자인 특성](#플랫폼별-디자인-특성)
3. [네비게이션 패턴](#네비게이션-패턴)
4. [타이포그래피](#타이포그래피)
5. [컬러](#컬러)
6. [레이아웃 & 간격](#레이아웃--간격)
7. [접근성](#접근성)
8. [Material & Liquid Glass](#material--liquid-glass)
9. [주요 컴포넌트 가이드라인](#주요-컴포넌트-가이드라인)

---

## 핵심 원칙

- **Clarity**: 텍스트 가독성, 아이콘 명확성, 기능에 집중
- **Deference**: 유동적 모션과 깔끔한 인터페이스로 콘텐츠가 UI와 경쟁하지 않게
- **Depth**: 시각적 계층과 사실적 모션으로 계층 전달

---

## 플랫폼별 디자인 특성

### iOS
- 중간 크기 고해상도 디스플레이, 30-60cm 거리
- 콘텐츠 중심, 화면 컨트롤 최소화
- 엄지 닿는 중간/하단 영역에 컨트롤 배치
- portrait + landscape 지원, Dynamic Type, Dark Mode

### macOS
- 대형 디스플레이, 30-90cm 거리, 착석
- 더 많은 콘텐츠를 적은 중첩으로, 적은 모달리티
- 메뉴바 + 키보드 단축키 필수
- 높은 정밀도 입력, 커스터마이즈 가능한 윈도우/툴바

### watchOS
- 소형 디스플레이, 손목, 30cm 이내
- 1분 이내 간결한 인터랙션
- Digital Crown 기본 네비게이션
- Always On Display, complications이 앱보다 더 많이 사용될 수 있음

### tvOS
- 대형 디스플레이, 2.4m+ 거리
- 포커스 시스템으로 방향 탐색
- 가장자리 채우는 아트워크, 유동적 애니메이션
- 장시간 세션, PiP 지원

### visionOS
- 무한 캔버스: 윈도우, 볼륨, 3D 오브젝트
- 시선 + 핀치 입력, 직접 터치
- 콘텐츠를 사용자에게 가져오기 (이동 강요 금지)
- glass material, depth로 계층 표현

---

## 네비게이션 패턴

### Tab Bar
- 최상위 섹션 네비게이션 (액션 아님 — 액션은 툴바)
- 탭 수 최소화, "More" 탭 피하기
- 아이콘 아래/옆에 레이블, 채워진 SF Symbols
- 탭 버튼 비활성화/숨기기 금지 — 콘텐츠 불가 이유 설명
- visionOS: 항상 수직, 심볼 + 짧은 텍스트 필수

### Sidebar
- 뷰 왼쪽, 플랫 계층 표시
- iOS에서는 피하기 (공간 과다 소비)
- iPadOS: `sidebarAdaptable` 스타일로 탭바 전환 가능
- 계층 2단계 이내

### Split View
- 복수 인접 패널
- 현재 선택 영속적으로 하이라이트
- 패널 간 드래그 앤 드롭

---

## 타이포그래피

### 기본/최소 폰트 크기

| 플랫폼 | 기본 | 최소 |
|--------|------|------|
| iOS/iPadOS | 17pt | 11pt |
| macOS | 13pt | 10pt |
| tvOS | 29pt | 23pt |
| visionOS | 17pt | 12pt |
| watchOS | 16pt | 12pt |

### 시스템 폰트

- **SF Pro** — iOS, iPadOS, macOS, tvOS, visionOS 기본
- **SF Compact** — watchOS
- **SF Mono** — 고정폭
- **New York** — serif, SF와 함께 또는 단독 사용

### 가중치

Regular, Medium, Semibold, Bold 선호. Ultralight, Thin, Light는 가독성 문제.

### Dynamic Type

iOS, iPadOS, tvOS, visionOS, watchOS 지원 (macOS 미지원).
모든 크기에서 레이아웃 적응 필수. 큰 크기에서 truncation 최소화. 접근성 크기에서 stacked 레이아웃 고려.

---

## 컬러

### Semantic 색상 사용

하드코딩 대신 시스템 색상 API:

**배경 (iOS)**:
- `systemBackground`, `secondarySystemBackground`, `tertiarySystemBackground`
- `systemGroupedBackground`, `secondarySystemGroupedBackground`, `tertiarySystemGroupedBackground`

**전경**:
- `label`, `secondaryLabel`, `tertiaryLabel`, `quaternaryLabel`
- `placeholderText`, `separator`, `link`

### 색상 공간

sRGB 표준. Display P3는 호환 디스플레이에서. P3는 16bit/channel. 에셋 카탈로그에서 색상 공간별 변형 제공.

### 포용적 디자인

- 색상에만 의존하지 않기 — 레이블/모양으로 보충
- 문화적 색상 의미 고려 (빨강 = 서양 위험, 중국 문화 긍정)

### Liquid Glass 색상

콘텐츠 뒤의 색상을 반영. glass material에 색상을 절제하여 적용. 강조 요소에만 colored background.

---

## 레이아웃 & 간격

### Safe Area

시스템 컴포넌트(툴바, 탭바, Dynamic Island 등)에 가려지지 않는 영역.
- tvOS: 모든 가장자리에서 60pt 안쪽
- watchOS: 베젤이 자연 패딩 제공

### Size Class

| 기기 | portrait | landscape |
|------|----------|-----------|
| iPad 전체 | Regular × Regular | Regular × Regular |
| iPhone (portrait) | Compact × Regular | — |
| iPhone (landscape) | 모델별 상이 | — |

compact 레이아웃 전환을 최대한 늦추기.

### 주요 기기 크기 (portrait, pt)

- iPad Pro 12.9": 1024×1366
- iPhone 16 Pro Max: 440×956
- iPhone 16: 393×852
- iPhone SE: 320×568

### watchOS 컨트롤

한 행에 최대 2-3개 (글리프 3개 또는 텍스트 2개). full-width 선호.

### visionOS

인터랙티브 요소 중심 간격 최소 **60pt**.

---

## 접근성

### 색상 대비 (WCAG AA)

- 17pt 이하 텍스트: **4.5:1** 최소
- 18pt+ 또는 볼드: **3:1** 최소

### 최소 터치 타겟

| 플랫폼 | 기본 | 최소 |
|--------|------|------|
| iOS/iPadOS | 44×44pt | 28×28pt |
| macOS | 28×28pt | 20×20pt |
| tvOS | 66×66pt | 56×56pt |
| visionOS | 60×60pt | 28×28pt |
| watchOS | 44×44pt | 28×28pt |

### 간격

베젤 요소 주변 ~12pt, 비베젤 요소 주변 ~24pt

### 텍스트 확대

최소 200% 확대 지원 (watchOS: 140%)

### Reduce Motion

활성화 시: 자동 애니메이션 축소, 스프링 타이트닝, 전환을 페이드로 대체, depth 축 애니메이션 회피

### 단순 제스처

일반 인터랙션에 단순 제스처 사용. 항상 대안 제공 (스와이프 + 화면 버튼).

### VoiceOver

모든 요소에 접근성 레이블. 커스텀 컨트롤에 적절한 trait 설정.

### visionOS 접근성

- Dwell Control: 핸즈프리 시선 고정 선택
- 요소를 시야각 내 배치
- 가로 레이아웃 선호
- 빠른 움직임/강도 제한

---

## Material & Liquid Glass

### Liquid Glass (iOS 26+, macOS Tahoe+)

실제 유리처럼 동작하는 반투명 dynamic material.

- **Regular**: 블러, 광도 조정
- **Clear**: 높은 투과성
- 가장 작은 요소(버튼, 스위치)부터 큰 요소(탭바, 사이드바)까지 확장
- 크로스 플랫폼: iOS, iPadOS, macOS, watchOS, tvOS

### 앱 아이콘 (Liquid Glass)

레이어 디자인 + Liquid Glass 효과 (specular highlight, frosting, 반투명).
6가지 자동 변형: default, dark, clear light, clear dark, tinted light, tinted dark.
Xcode Icon Composer 도구로 제작.

### Standard Materials (iOS)

Ultra Thin, Thin, Regular, Thick — 배경 블러 레벨.

### Vibrancy

Labels (4레벨), Fills (3레벨), Separators (1레벨).

### visionOS Glass

수정 불가, 광도에 자동 적응. 별도 Dark Mode 없음.

---

## 주요 컴포넌트 가이드라인

### Button
- 최소 hit 영역 44×44pt (visionOS 60×60pt)
- Prominent 스타일: 뷰당 1-2개 최대
- 4가지 역할: Normal, Primary (accent), Cancel, Destructive (빨강)
- 파괴적 액션에 Primary 역할 할당 금지
- visionOS: 아이콘=원형, 텍스트=캡슐, 중심 간격 60pt+

### Sheet
- 현재 컨텍스트의 범위 작업
- Cancel (좌), Done (우), Back (계층 네비게이션)
- iOS: detents (large=전체, medium=절반), grabber
- 복잡한/장기 워크플로우나 미디어 콘텐츠에 사용 금지

### Alert
- 즉각 주의가 필요한 중요 정보에만 사용 — 남용 금지
- 최대 3개 버튼
- 파괴적 스타일링: 사용자가 시작하지 않은 파괴적 액션에만
- 가장 가능한 선택 trailing, Cancel leading

### List
- iOS: grouped 스타일 + header/footer
- macOS: 멀티 컬럼, 정렬, 리사이즈, 교차 행 색상
- 텍스트 표시 우선, 항목 간결하게

### Progress Indicator
- 기간 알 때: determinate (프로그레스 바 / 원형)
- 기간 모를 때: indeterminate (회전)
- 가능하면 determinate 선호
