# Foundation Reference

## Table of Contents
1. [FormatStyle — 현대적 포매팅](#formatstyle--현대적-포매팅)
2. [AttributedString](#attributedstring)
3. [Async Foundation API](#async-foundation-api)
4. [KVO in Swift vs @Observable](#kvo-in-swift-vs-observable)
5. [Codable 패턴](#codable-패턴)
6. [Predicate](#predicate)
7. [RegexBuilder](#regexbuilder)
8. [Duration & Clock](#duration--clock)
9. [FileManager & Data](#filemanager--data)
10. [UserDefaults](#userdefaults)
11. [Deprecated 패턴 대응표](#deprecated-패턴-대응표)

---

## FormatStyle — 현대적 포매팅

### iOS 15+ / macOS 12+

`DateFormatter`, `NumberFormatter` 등을 대체. Foundation이 동일 FormatStyle 인스턴스를 자동 캐싱하므로 기존의 "formatter를 캐싱하라" 보일러플레이트 불필요.

### Date

```swift
Date.now.formatted()                                          // 기본
Date.now.formatted(date: .abbreviated, time: .shortened)      // 프리셋
Date.now.formatted(.dateTime.year().month(.wide).day())        // 커스텀 필드
Date.now.formatted(.iso8601.year().month().day())              // ISO 8601
startDate.formatted(.relative(presentation: .numeric))        // "2시간 전"
```

### Number

```swift
42.5.formatted(.number)
0.425.formatted(.percent)
1000.formatted(.currency(code: "USD"))
42.formatted(.number.notation(.scientific))
```

### 파싱

```swift
let date = try Date("2021-04-11", strategy: .iso8601)
```

### Attributed 출력

```swift
let attributed = Date.now.formatted(.dateTime.attributed)
// AttributedString 반환 — 각 필드에 별도 스타일 적용 가능
```

### 기타 FormatStyle

`ListFormatStyle`, `ByteCountFormatStyle`, `Measurement.FormatStyle`,
`PersonNameComponents.FormatStyle`, `URL.FormatStyle`,
`Duration.TimeFormatStyle`, `Duration.UnitsFormatStyle`

---

## AttributedString

### iOS 15+ / macOS 12+

`NSAttributedString`의 Swift 네이티브 대체. 값 타입, Codable, Sendable.

```swift
// 생성 및 수정
var str = AttributedString("Hello")
str.font = .title
str[range].foregroundColor = .orange

// Attribute container로 일괄 설정
var container = AttributeContainer()
container.font = .body
str.mergeAttributes(container)

// Markdown 지원
let md = try AttributedString(markdown: "**Bold** and _italic_")

// NSAttributedString 변환
let ns = NSAttributedString(str)
```

### 커스텀 속성

```swift
struct RainbowAttribute: AttributedStringKey {
    typealias Value = Bool
    static let name = "rainbow"
}
```

### NSAttributedString과의 차이

| NSAttributedString | AttributedString |
|---|---|
| 참조 타입 (class) | 값 타입 (struct) |
| NSRange (UTF-16) | String.Index (Character) |
| 런타임 키 (`NSAttributedString.Key`) | 컴파일 타임 타입 안전 |
| Codable 아님 | Codable, Sendable |

---

## Async Foundation API

### NotificationCenter (iOS 15+)

```swift
for await notification in NotificationCenter.default.notifications(named: .myNotification) {
    // Sendable 값만 추출하여 처리
}
```

selector 기반 `addObserver` 대체. 구조적 동시성과 자연스럽게 통합.

### URLSession (iOS 15+)

```swift
// Data
let (data, response) = try await URLSession.shared.data(from: url)

// Download (파일 URL 반환, 호출자가 정리)
let (fileURL, response) = try await URLSession.shared.download(from: url)

// Upload
let (data, response) = try await URLSession.shared.upload(for: request, from: bodyData)

// 스트리밍 bytes
let (bytes, response) = try await URLSession.shared.bytes(from: url)
for try await line in bytes.lines {
    // 도착하는 대로 줄 단위 처리
}

// 태스크별 delegate (인증 챌린지 등)
let (data, response) = try await URLSession.shared.data(from: url, delegate: myDelegate)
```

completion handler 기반 API를 완전히 대체.

### URL / FileHandle

```swift
for try await line in url.lines { ... }
for try await byte in url.resourceBytes { ... }
```

---

## KVO in Swift vs @Observable

### KVO (NSObject 전용)

```swift
class MyModel: NSObject {
    @objc dynamic var name: String = ""
}

// Block 기반 관찰
let observation = model.observe(\.name, options: [.old, .new]) { obj, change in
    print(change.newValue!)
}

// Combine KVO publisher
let cancellable = model.publisher(for: \.name)
    .sink { value in print(value) }
```

`@objc dynamic` 프로퍼티에서만 동작. NSObject 상속 필수.

### @Observable (iOS 17+) — 현대적 대체

```swift
@Observable
class MyModel {
    var name: String = ""  // @objc dynamic 불필요, @Published 불필요
}
```

SwiftUI가 자동 추적. 비-SwiftUI에서는 `withObservationTracking` 사용.

### 언제 어떤 것을 쓸까

| 패턴 | 용도 |
|------|------|
| `@Observable` | 새 코드, SwiftUI (iOS 17+) |
| KVO + Combine publisher | UIKit/AppKit 시스템 API 프로퍼티 관찰 |
| Raw KVO | 레거시 코드, ObjC interop |

---

## Codable 패턴

### JSONEncoder / JSONDecoder

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
encoder.dateEncodingStrategy = .iso8601
encoder.keyEncodingStrategy = .convertToSnakeCase

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.allowsJSON5 = true  // JSON5 지원
```

### CodingKeyRepresentable (Swift 5.6+)

non-String/Int 키 Dictionary가 배열 대신 객체로 인코딩:

```swift
struct ID: Hashable, CodingKeyRepresentable {
    let stringValue: String
    var codingKey: CodingKey { ... }
    init?<T: CodingKey>(codingKey: T) { ... }
}
// [ID: String] → {"id1": "value1"} (배열이 아닌 객체)
```

`RawRepresentable` enum (String/Int raw value)은 자동 적합.

---

## Predicate

### iOS 17+ / macOS 14+

`NSPredicate`의 Swift 네이티브 대체. 컴파일 타임 타입 체크.

```swift
let predicate = #Predicate<Message> { message in
    message.length < 100 && message.sender == "Jeremy"
}

// 중첩
let complex = #Predicate<Message> { message in
    message.recipients.contains { $0.firstName == message.sender.firstName }
}

// 평가
let result = try predicate.evaluate(someMessage)
```

SwiftData `FetchDescriptor`에서 핵심적으로 사용:

```swift
let descriptor = FetchDescriptor<Dog>(
    predicate: #Predicate { $0.age > 3 },
    sortBy: [SortDescriptor(\.name)]
)
```

지원 연산: 산술, 비교, 논리, optionals, 타입 캐스팅, 시퀀스(filter, contains, allSatisfy), 문자열(contains, localizedStandardContains).

Codable + Sendable — `PredicateCodableConfiguration`으로 아카이빙 가능.

---

## RegexBuilder

### iOS 16+ / macOS 13+ / Swift 5.7

3가지 생성 방식:

```swift
// 1. 리터럴
let pattern = /(.+?): (.+)/

// 2. 문자열 (런타임)
let pattern = try Regex("[0-9]+")

// 3. RegexBuilder DSL
import RegexBuilder
let pattern = Regex {
    Anchor.startOfLine
    Capture { OneOrMore(.word) }
    ": "
    Capture { OneOrMore(.any) }
    Anchor.endOfLine
}
```

### Foundation 통합

FormatStyle을 regex 컴포넌트로 직접 사용 — 타입 안전 파싱:

```swift
let regex = Regex {
    Capture { .date(.iso8601) }
    " "
    Capture { .localizedInteger }
}
```

### String 매칭 메서드

`contains(_:)`, `firstMatch(of:)`, `matches(of:)`, `prefixMatch(of:)`, `wholeMatch(of:)`

---

## Duration & Clock

### iOS 16+ / macOS 13+

`DispatchTime`/`DispatchQueue.asyncAfter` 대체.

```swift
// Duration — attosecond 정밀도
let d = Duration.seconds(5)
let d2 = Duration.milliseconds(500)
d.formatted()  // 로컬라이즈된 시:분:초

// 산술
let total = d + d2
let doubled = d * 2
```

### Clock 프로토콜

| Clock | 특성 |
|-------|------|
| `ContinuousClock` | 시스템 sleep 중에도 진행 (벽시계) |
| `SuspendingClock` | sleep 시 일시정지 (실행 시간) |

```swift
let clock = ContinuousClock()
let elapsed = await clock.measure {
    await someAsyncWork()
}
try await clock.sleep(for: .seconds(1))
```

---

## FileManager & Data

### URL 기반 API 사용

string path API 대신 URL 기반을 선호한다. Apple 공식: "The use of the NSURL class is generally preferred."

```swift
// 선호
try fileManager.copyItem(at: sourceURL, to: destURL)
try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)

// 비선호
try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
```

### 안전한 저장

이동식/네트워크 볼륨에서는 `itemReplacementDirectory`로 atomic 저장.

### Data

파일 I/O는 동기적 (`Data(contentsOf:)`, `data.write(to:options:)`).
`Sendable`, `Transferable` 적합.

---

## UserDefaults

- 민감 데이터 저장 금지 (디스크에 암호화 없이 저장)
- `register(defaults:)` — nil 체크 대신 fallback 값 등록
- App Group 공유: `UserDefaults(suiteName: "group.com.example")`
- `synchronize()` — deprecated/불필요. 자동 영속.
- `NSUbiquitousKeyValueStore` — 크로스 디바이스 동기화용 (UserDefaults 아님)
- `PrivacyInfo.xcprivacy`에 사용 선언 (핑거프린팅 우려)

---

## Deprecated 패턴 대응표

| 레거시 | 현대적 대체 | 시점 |
|--------|-----------|------|
| `DateFormatter` | `Date.FormatStyle` / `.formatted()` | iOS 15 |
| `NumberFormatter` | `IntegerFormatStyle` / `.formatted()` | iOS 15 |
| `NSAttributedString` (직접 사용) | `AttributedString` (값 타입) | iOS 15 |
| `NSSortDescriptor` | `SortDescriptor` (generic, Codable) | iOS 15 |
| `NSPredicate` (문자열 기반) | `#Predicate` 매크로 (타입 안전) | iOS 17 |
| `NSRegularExpression` | `Regex` / `RegexBuilder` | iOS 16 |
| URLSession completion handler | URLSession async/await | iOS 15 |
| `NotificationCenter.addObserver` (selector) | `.notifications(named:)` async sequence | iOS 15 |
| `DispatchTime` / `.asyncAfter` | `Duration` / `Clock.sleep(for:)` | iOS 16 |
| FileManager string-path API | FileManager URL-based API | 오래전 |
| `UserDefaults.synchronize()` | 호출 제거 (자동 영속) | 오래전 |
| `swift-corelibs-foundation` (C 기반) | `swift-foundation` (순수 Swift, 통합) | Swift 6 |
