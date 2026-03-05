# Personal Development Rules

## 1. 코드 수정 정책

- **절대로 코드를 먼저 수정하지 않는다.** 명시적으로 "수정해", "고쳐", "작성해"라는 지시가 없는 한, 반드시 변경 계획을 먼저 설명하고 컨펌을 받은 뒤 실행한다.
- 코드 리뷰나 분석 요청 시에는 문제점과 개선 방향만 제시하고, 실제 코드 변경은 승인 후 진행한다.
- 여러 파일에 걸친 변경이 필요한 경우, 변경 범위와 영향도를 먼저 요약한다.

## 2. Swift 코드 스타일

Swift 코드 작성 시 [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)를 따른다.

### 핵심 원칙
- **Clarity at the point of use**: 사용 지점에서의 명확성이 최우선. 간결함보다 명확성을 우선한다.
- **Naming reads as English phrases**: 메서드 호출이 자연스러운 영어 구문처럼 읽히도록 한다.
  - `x.insert(y, at: z)` → "x, insert y at z"
  - `x.subviews(havingColor: y)` → "x's subviews having color y"
- **Omit needless words**: 타입 정보 등 문맥에서 유추 가능한 단어는 생략한다.
  - ✅ `removeElement(_ member: Element)` → `remove(_ member: Element)`

### 네이밍 규칙
- Types, Protocols → `UpperCamelCase`
- Methods, Properties, Variables, Constants → `lowerCamelCase`
- 약어가 통용되는 경우(예: `min`, `sin`, `ASCII`) 관례를 따른다.
- Bool 프로퍼티는 `is`, `has`, `can`, `should` 접두사를 사용한다.
- Protocol: "무엇인가"를 설명하면 명사(`Collection`), "능력"을 설명하면 `-able`/`-ible`/`-ing` 접미사(`Equatable`, `ProgressReporting`).
- Mutating/Non-mutating 쌍: 동사 → `x.sort()` / `x.sorted()`, 명사 → `x.union(y)` / `x.formUnion(y)`
- Factory 메서드는 `make`로 시작: `makeIterator()`

### Apple API 호환성
- Apple 프레임워크의 기존 패턴과 네이밍 관례를 최대한 따른다.
- Delegate 메서드는 첫 번째 파라미터를 호출자(delegate source)로 한다: `func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)`
- Cocoa/UIKit 등 기존 API와의 일관성을 유지한다.

## 3. Apple Platform 버전 정책

- **최신 OS 기술 우선**: 코드 설계와 구현은 가장 최신 OS의 API와 패턴을 기준으로 사고한다.
- **최근 2년간 OS 지원 필수**: 다만, 최신 OS 포함 직전 2개 메이저 버전까지 런타임 지원이 되어야 한다.
  - 예시 2026 기준: iOS 26.0+ / macOS 26.0+ / watchOS 26.0+ / tvOS 26.0+
  - 이 버전 범위는 매년 새로운 OS 출시에 따라 갱신된다.
- **Availability 처리 원칙**:
  - 최신 전용 API는 `if #available` / `@available`로 분기하고, fallback을 반드시 제공한다.
  - Deployment target에서 사용 불가한 API를 무분별하게 쓰지 않는다.
  - 단, 핵심 기능이 최신 OS 전용 API에 의존하는 경우, 그 트레이드오프를 먼저 설명하고 컨펌을 받는다.
- **Deprecated API 지양**: Apple이 deprecated로 표시한 API는 가능한 한 사용하지 않고, 대체 API를 우선 사용한다. deprecated API를 써야 하는 상황이라면 이유를 명시한다.

## 4. 정보 검증 정책

- 표준, 스펙, 공식 문서에 대한 질문이나 확인이 필요한 경우, **추측하지 말고 직접 검색하여 확인**한다.
- 특히 다음 항목은 반드시 검색 후 답변한다:
  - Swift/Apple 프레임워크의 API 동작이나 제약사항
  - 특정 iOS/macOS 버전별 가용성 (Availability)
  - RFC, W3C 등 기술 표준의 구체적 내용
  - 법률, 규정, 공식 절차 관련 사항
- 불확실한 정보는 "확실하지 않다"고 명시하고, 검증 가능한 출처를 안내한다.

## 5. 커뮤니케이션 스타일

- 한국어로 대화한다. 기술 용어는 영문 원어를 병기해도 좋다.
- 불필요하게 장황하지 않게, 핵심 위주로 답변한다.
- 코드 예시는 Swift를 기본으로 한다 (다른 언어가 명시되지 않는 한).
- 버전 관리 툴의 커밋 메시지는 기본적으로 영어로 작성한다.
