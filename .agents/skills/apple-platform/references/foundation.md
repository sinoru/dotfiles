# Foundation Reference

## Table of Contents
1. [FormatStyle — Modern Formatting](#formatstyle--modern-formatting)
2. [AttributedString](#attributedstring)
3. [Async Foundation API](#async-foundation-api)
4. [KVO in Swift vs @Observable](#kvo-in-swift-vs-observable)
5. [Codable Patterns](#codable-patterns)
6. [Predicate](#predicate)
7. [RegexBuilder](#regexbuilder)
8. [Duration & Clock](#duration--clock)
9. [FileManager & Data](#filemanager--data)
10. [UserDefaults](#userdefaults)
11. [Deprecated Pattern Mapping](#deprecated-pattern-mapping)

---

## FormatStyle — Modern Formatting

### iOS 15+ / macOS 12+

Replaces `DateFormatter`, `NumberFormatter`, etc. Foundation automatically caches identical FormatStyle instances, so the old "cache your formatter" boilerplate is unnecessary.

### Date

```swift
Date.now.formatted()                                          // default
Date.now.formatted(date: .abbreviated, time: .shortened)      // preset
Date.now.formatted(.dateTime.year().month(.wide).day())        // custom fields
Date.now.formatted(.iso8601.year().month().day())              // ISO 8601
startDate.formatted(.relative(presentation: .numeric))        // "2 hours ago"
```

### Number

```swift
42.5.formatted(.number)
0.425.formatted(.percent)
1000.formatted(.currency(code: "USD"))
42.formatted(.number.notation(.scientific))
```

### Parsing

```swift
let date = try Date("2021-04-11", strategy: .iso8601)
```

### Attributed Output

```swift
let attributed = Date.now.formatted(.dateTime.attributed)
// Returns AttributedString — separate styling can be applied per field
```

### Other FormatStyles

`ListFormatStyle`, `ByteCountFormatStyle`, `Measurement.FormatStyle`,
`PersonNameComponents.FormatStyle`, `URL.FormatStyle`,
`Duration.TimeFormatStyle`, `Duration.UnitsFormatStyle`

---

## AttributedString

### iOS 15+ / macOS 12+

Swift-native replacement for `NSAttributedString`. Value type, Codable, Sendable.

```swift
// Create and modify
var str = AttributedString("Hello")
str.font = .title
str[range].foregroundColor = .orange

// Set in bulk via Attribute container
var container = AttributeContainer()
container.font = .body
str.mergeAttributes(container)

// Markdown support
let md = try AttributedString(markdown: "**Bold** and _italic_")

// Convert to NSAttributedString
let ns = NSAttributedString(str)
```

### Custom Attributes

```swift
struct RainbowAttribute: AttributedStringKey {
    typealias Value = Bool
    static let name = "rainbow"
}
```

### Differences from NSAttributedString

| NSAttributedString | AttributedString |
|---|---|
| Reference type (class) | Value type (struct) |
| NSRange (UTF-16) | String.Index (Character) |
| Runtime key (`NSAttributedString.Key`) | Compile-time type safety |
| Not Codable | Codable, Sendable |

---

## Async Foundation API

### NotificationCenter (iOS 15+)

```swift
for await notification in NotificationCenter.default.notifications(named: .myNotification) {
    // Only extract and process Sendable values
}
```

Replaces selector-based `addObserver`. Integrates naturally with structured concurrency.

### URLSession (iOS 15+)

```swift
// Data
let (data, response) = try await URLSession.shared.data(from: url)

// Download (returns file URL, caller must clean up)
let (fileURL, response) = try await URLSession.shared.download(from: url)

// Upload
let (data, response) = try await URLSession.shared.upload(for: request, from: bodyData)

// Streaming bytes
let (bytes, response) = try await URLSession.shared.bytes(from: url)
for try await line in bytes.lines {
    // Process line by line as it arrives
}

// Per-task delegate (auth challenges, etc.)
let (data, response) = try await URLSession.shared.data(from: url, delegate: myDelegate)
```

Completely replaces completion-handler-based APIs.

### URL / FileHandle

```swift
for try await line in url.lines { ... }
for try await byte in url.resourceBytes { ... }
```

---

## KVO in Swift vs @Observable

### KVO (NSObject only)

```swift
class MyModel: NSObject {
    @objc dynamic var name: String = ""
}

// Block-based observation
let observation = model.observe(\.name, options: [.old, .new]) { obj, change in
    print(change.newValue!)
}

// Combine KVO publisher
let cancellable = model.publisher(for: \.name)
    .sink { value in print(value) }
```

Only works on `@objc dynamic` properties. Requires NSObject inheritance.

### @Observable (iOS 17+) — Modern Replacement

```swift
@Observable
class MyModel {
    var name: String = ""  // No @objc dynamic needed, no @Published needed
}
```

SwiftUI tracks automatically. Outside SwiftUI, use `withObservationTracking`.

### When to Use Which

| Pattern | Use |
|------|------|
| `@Observable` | New code, SwiftUI (iOS 17+) |
| KVO + Combine publisher | Observing UIKit/AppKit system API properties |
| Raw KVO | Legacy code, ObjC interop |

---

## Codable Patterns

### JSONEncoder / JSONDecoder

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
encoder.dateEncodingStrategy = .iso8601
encoder.keyEncodingStrategy = .convertToSnakeCase

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.allowsJSON5 = true  // JSON5 support
```

### CodingKeyRepresentable (Swift 5.6+)

Encodes non-String/Int-keyed Dictionaries as objects instead of arrays:

```swift
struct ID: Hashable, CodingKeyRepresentable {
    let stringValue: String
    var codingKey: CodingKey { ... }
    init?<T: CodingKey>(codingKey: T) { ... }
}
// [ID: String] → {"id1": "value1"} (object, not array)
```

`RawRepresentable` enums (String/Int raw value) conform automatically.

---

## Predicate

### iOS 17+ / macOS 14+

Swift-native replacement for `NSPredicate`. Compile-time type checking.

```swift
let predicate = #Predicate<Message> { message in
    message.length < 100 && message.sender == "Jeremy"
}

// Nested
let complex = #Predicate<Message> { message in
    message.recipients.contains { $0.firstName == message.sender.firstName }
}

// Evaluate
let result = try predicate.evaluate(someMessage)
```

Used centrally in SwiftData's `FetchDescriptor`:

```swift
let descriptor = FetchDescriptor<Dog>(
    predicate: #Predicate { $0.age > 3 },
    sortBy: [SortDescriptor(\.name)]
)
```

Supported operations: arithmetic, comparison, logic, optionals, type casting, sequences (filter, contains, allSatisfy), strings (contains, localizedStandardContains).

Codable + Sendable — can be archived with `PredicateCodableConfiguration`.

---

## RegexBuilder

### iOS 16+ / macOS 13+ / Swift 5.7

Three ways to create one:

```swift
// 1. Literal
let pattern = /(.+?): (.+)/

// 2. String (runtime)
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

### Foundation Integration

Use FormatStyle directly as a regex component — type-safe parsing:

```swift
let regex = Regex {
    Capture { .date(.iso8601) }
    " "
    Capture { .localizedInteger }
}
```

### String Matching Methods

`contains(_:)`, `firstMatch(of:)`, `matches(of:)`, `prefixMatch(of:)`, `wholeMatch(of:)`

---

## Duration & Clock

### iOS 16+ / macOS 13+

Replaces `DispatchTime`/`DispatchQueue.asyncAfter`.

```swift
// Duration — attosecond precision
let d = Duration.seconds(5)
let d2 = Duration.milliseconds(500)
d.formatted()  // Localized hours:minutes:seconds

// Arithmetic
let total = d + d2
let doubled = d * 2
```

### Clock Protocol

| Clock | Characteristics |
|-------|------|
| `ContinuousClock` | Keeps advancing during system sleep (wall clock) |
| `SuspendingClock` | Pauses during sleep (execution time) |

```swift
let clock = ContinuousClock()
let elapsed = await clock.measure {
    await someAsyncWork()
}
try await clock.sleep(for: .seconds(1))
```

---

## FileManager & Data

### Use URL-based APIs

Prefer URL-based APIs over string path APIs. Apple's official guidance: "The use of the NSURL class is generally preferred."

```swift
// Preferred
try fileManager.copyItem(at: sourceURL, to: destURL)
try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)

// Not preferred
try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
```

### Safe Saving

On removable/network volumes, use `itemReplacementDirectory` for atomic saves.

### Data

File I/O is synchronous (`Data(contentsOf:)`, `data.write(to:options:)`).
Conforms to `Sendable`, `Transferable`.

---

## UserDefaults

- Do not store sensitive data (stored unencrypted on disk)
- `register(defaults:)` — register fallback values instead of nil checks
- App Group sharing: `UserDefaults(suiteName: "group.com.example")`
- `synchronize()` — deprecated/unnecessary. Persistence is automatic.
- `NSUbiquitousKeyValueStore` — for cross-device sync (not UserDefaults)
- Declare usage in `PrivacyInfo.xcprivacy` (fingerprinting concern)

---

## Deprecated Pattern Mapping

| Legacy | Modern Replacement | Since |
|--------|-----------|------|
| `DateFormatter` | `Date.FormatStyle` / `.formatted()` | iOS 15 |
| `NumberFormatter` | `IntegerFormatStyle` / `.formatted()` | iOS 15 |
| `NSAttributedString` (direct use) | `AttributedString` (value type) | iOS 15 |
| `NSSortDescriptor` | `SortDescriptor` (generic, Codable) | iOS 15 |
| `NSPredicate` (string-based) | `#Predicate` macro (type-safe) | iOS 17 |
| `NSRegularExpression` | `Regex` / `RegexBuilder` | iOS 16 |
| URLSession completion handler | URLSession async/await | iOS 15 |
| `NotificationCenter.addObserver` (selector) | `.notifications(named:)` async sequence | iOS 15 |
| `DispatchTime` / `.asyncAfter` | `Duration` / `Clock.sleep(for:)` | iOS 16 |
| FileManager string-path API | FileManager URL-based API | Long-standing |
| `UserDefaults.synchronize()` | Remove the call (automatic persistence) | Long-standing |
| `swift-corelibs-foundation` (C-based) | `swift-foundation` (pure Swift, unified) | Swift 6 |
