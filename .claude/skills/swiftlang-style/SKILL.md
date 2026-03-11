---
name: swiftlang-style
description: "Swift code style — formatting, naming, patterns, and conventions. TRIGGER when: about to write or modify Swift code. Invoke before the first code edit, even if the conversation started as analysis or discussion. DO NOT TRIGGER when: only reading, researching, or reviewing Swift code without any planned changes."
---

# Swift Code Style

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).

## Fundamentals

- **Clarity at the point of use** is the most important goal. Entities are declared once but used repeatedly — optimize for the use site.
- **Clarity over brevity.** Compact code is a side-effect of Swift's type system, not a goal in itself.
- **Write documentation comments** for every declaration. If you struggle to describe the API simply, you may have designed the wrong API.

## Formatting

### Indentation & Line Length

- **4 spaces** for indentation (no tabs).
- **100 characters** maximum per line. Exceptions: long URLs in comments, import statements.

### Braces

- **K&R style** — opening `{` on the same line as the statement.
- Closing `}` on its own line, aligned with the statement that opened the block.
- `} else {` stays on the same line.

### Spacing

- Single space before `{` and after `}` when code follows on the same line.
- Space on both sides of binary/ternary operators and `=`. No space around `.` and range operators (`..<`, `...`).
- Space after `,`, `:`, and `//`. At least two spaces before trailing `//` comments.

### General

- **No parentheses** around top-level conditions: `if condition {` — not `if (condition) {`.
- **No semicolons.**

### Trailing Commas

- **Required** in multi-line collection literals and multi-line parameter lists — produces cleaner diffs.

### Line-Wrapping

**Cardinal rules:**

1. If it fits on one line, keep it on one line.
2. Comma-delimited lists are **one direction only** — all on one line OR each on its own line. No mixing.
3. Continuation lines in vertically-oriented comma lists are indented **+4** from the original line.
4. Opening `{` goes on the same line as the last continuation, unless that line is already +4 indented — then `{` on its own line to avoid visual blending.

**Function declarations:**

```swift
func generateStars(
    at location: Point,
    count: Int
) -> String {
```

Generic constraints with `where` — break before `where`, each constraint on its own line:

```swift
func index<Elements: Collection, Element>(
    of element: Element,
    in collection: Elements
) -> Elements.Index?
where
    Elements.Element == Element,
    Element: Equatable
{
```

**Function calls** — each argument on its own line, closing `)` always on its own line:

```swift
let idx = index(
    of: element,
    in: collection
)
```

**Type & extension declarations** — inheritance list each on its own line, `where` clause likewise:

```swift
class MyContainer<BaseCollection>:
    MySuperclass,
    MyProtocol,
    SomeFrameworkProtocol
where
    BaseCollection: Collection,
    BaseCollection.Element: Equatable
{
    // ...
}
```

**Control flow** — break after keyword, indent conditions +4:

```swift
if
    let galaxy,
    galaxy.name == "Milky Way"
{
    // ...
}
```

- Multi-line `guard` places `else` on a separate line; single-line keeps it together.
- `for-where` wraps `where` to a new line if needed:

```swift
for element in collection
    where element.hasVeryLongPropertyName
{
    // ...
}
```

**Other expressions** — continuation lines +4 from original. If too complex, split into temporary variables.

## File Organization

- **One primary type per file.** File name matches the type: `MyType.swift`.
- Protocol conformance extensions in separate files: `MyType+Protocol.swift`.
- Use **`// MARK:`** to organize members within a file.
- **Import statements** at the top, grouped and sorted alphabetically:
  1. Module imports
  2. Individual declaration imports
  3. `@testable` imports (test targets only)

## Documentation

- Use **`///`** (triple-slash). Block comments `/** */` are forbidden.
- Use `//` for inline comments within function bodies. Avoid `/* */` block comments.
- Begin with a **single-sentence summary** (a fragment, ending with a period).
- Add detail in subsequent paragraphs separated by blank lines.
- Use recognized symbol commands: `- Parameter`, `- Returns`, `- Throws`, `- Complexity`, `- Note`, `- Important`, `- Warning`, `- SeeAlso`, etc.

## Naming

### Promote Clear Usage

- **Include all words needed to avoid ambiguity** at the use site.
  - `employees.remove(at: x)` — not `employees.remove(x)` (position vs. search)
- **Omit needless words** — especially those that repeat type information.
  - ✅ `remove(_ member: Element)` — ❌ `removeElement(_ member: Element)`
- **Name variables and parameters by their role**, not their type.
  - ✅ `var greeting: String` — ❌ `var string: String`
- **Compensate for weak type information.** When a parameter type is `Any`, `NSObject`, or a fundamental type, prepend a descriptive noun to the label.
  - ✅ `addObserver(_ observer: NSObject, forKeyPath path: String)` — ❌ `add(_ observer: NSObject, for keyPath: String)`

### Strive for Fluent Usage

- **Method calls should read as grammatical English phrases.**
  - ✅ `x.insert(y, at: z)` → "x, insert y at z" — ❌ `x.insert(y, position: z)`
- **Factory methods** begin with `make`: `makeIterator()`
- **Initializer and factory-method arguments** form an independent phrase, not one with the base name.
  - ✅ `Color(red: 32, green: 64, blue: 128)` — ❌ `Color(havingRGBValuesRed: 32, ...)`

### Name According to Side-Effects

- **No side-effects → noun phrase**: `x.distance(to: y)`, `i.successor()`
- **Side-effects → imperative verb phrase**: `print(x)`, `x.sort()`, `x.append(y)`

### Mutating / Non-mutating Pairs

When the operation is described by a **verb**:

| Mutating (imperative) | Non-mutating (-ed / -ing) |
|---|---|
| `x.sort()` | `z = x.sorted()` |
| `x.append(y)` | `z = x.appending(y)` |
| `x.stripNewlines()` | `z = x.strippingNewlines()` |

When the operation is described by a **noun**:

| Non-mutating (noun) | Mutating (form + noun) |
|---|---|
| `x = y.union(z)` | `y.formUnion(z)` |

### Booleans

- Read as **assertions about the receiver**: `isEmpty`, `isDisjoint(with:)`, `canBecomeFirstResponder`, `intersects(_:)`

### Protocols

- Protocols describing **what something is** → noun: `Collection`, `StringProtocol`
- Protocols describing **a capability** → `-able` / `-ible` / `-ing`: `Equatable`, `Hashable`, `ProgressReporting`

### Case Conventions

- Types and Protocols → `UpperCamelCase`
- Everything else → `lowerCamelCase`
- **Acronyms** follow uniform casing: `utf8Bytes`, `HTTPSConnection`, `isRepresentableAsASCII`

### Terminology

- **Avoid obscure terms** when a common word conveys meaning equally well.
- **Stick to established meaning.** Don't repurpose a term of art.
- **Avoid abbreviations**, especially non-standard ones.
- **Embrace precedent.** Prefer `Array` over `List` to match existing programmer expectations.

## Conventions

### General

- **Document computational complexity** of any property that is not O(1).
- **Prefer methods and properties** over free functions. Use free functions only when:
  - There is no obvious `self`: `min(x, y, z)`
  - The function is an unconstrained generic: `print(x)`
  - Domain notation uses function syntax: `sin(x)`
- **Methods can share a base name** when they have the same basic meaning or operate in distinct domains. Avoid overloading on return type alone.

### Parameters

- **Choose parameter names that serve documentation.** Names should make the function declaration read naturally.
- **Use default parameter values** to simplify common use cases. Prefer defaults over families of methods that differ only in parameters.
- **Place parameters with defaults toward the end** of the parameter list.

### Argument Labels

- **Omit all labels** when arguments cannot be usefully distinguished: `min(number1, number2)`, `zip(sequence1, sequence2)`
- **Omit the first label in value-preserving type conversions**: `Int64(someUInt32)`
  - Exception: narrowing / lossy conversions need a descriptive label: `UInt32(truncating: value)`
- **When the first argument forms a prepositional phrase**, give it a label: `removeBoxes(havingLength: 12)`
  - Exception: when two arguments form a single abstraction: `moveTo(x: 3, y: 5)` — not `move(toX: 3, y: 5)`
- **When the first argument is part of a grammatical phrase** with the function name, omit its label: `addSubview(y)`
- **Label all other arguments.**

### Closures and Tuples

- **Label closure parameters** used in return types or top-level API for clarity.
- **Name tuple members** that appear in public API to improve documentation and expressiveness.

### Unconstrained Polymorphism

- **Take extra care** with `Any`, `AnyObject`, and unconstrained generic parameters to avoid ambiguity. Disambiguate with descriptive labels like `append(contentsOf:)` vs `append(_:)`.

## Patterns

### Type Inference & Shorthand

- **Omit type annotations** when the type is obvious from the right-hand side. (Exception: complex expressions — see Performance > Compile Time.)
  - ✅ `let sun = Star(mass: 1.989e30)` — ❌ `let sun: Star = Star(mass: 1.989e30)`
- **Use shorthand type syntax**: `[Element]`, `String?`, `[Key: Value]` — not `Array<Element>`, `Optional<String>`, `Dictionary<Key, Value>`.
- **Omit `-> Void`** in function declarations. In closure types, use `Void`: `() -> Void` — not `() -> ()`.
- **Omit `.init`** when not required: `Universe()` — not `Universe.init()`.

### Control Flow

- **`guard` for early exits and preconditions.** Keeps the main logic flush-left and failure conditions coupled to their triggers.
- **`for-where`** when the entire loop body is a single `if`: `for item in items where item.isValid {`
- **`for` over `.forEach()`** — unless `.forEach` is the last element in a functional chain.

### self

- **Omit `self`** unless required for disambiguation or by the language (closures, initializers).
- **`guard let self else { return }`** when upgrading a weak self reference.

### Optionals & Safety

- **Force unwrap and force cast are strongly discouraged.** If used, include a comment explaining why it is safe. Exception: tests.
- **Avoid implicitly unwrapped optionals** — use regular `Optional` or non-optional. Exceptions: `@IBOutlet`, properties initialized in `viewDidLoad` / `setUp()`.
- **Prefer `weak` over `unowned`** to prevent crashes from deallocated objects.
- **`try!` is generally forbidden** — equivalent to `fatalError` without a message. Exception: tests, or compile-time-provable safety (e.g., regex from string literal).

## Attributes & Access Control

### Attribute Ordering

Declarations follow this order: **doc comment → `@` attributes → access control + other modifiers → declaration keyword**.

Each `@` attribute occupies its own line. Access control and other modifiers stay on the same line as the declaration.

```swift
/// Fetches the user profile.
@MainActor
@available(iOS 17.0, *)
@discardableResult
public final func fetchProfile() -> Profile { }

@Published
private var name: String
```

### Access Control

- **Use the strictest level possible.** Prefer `public` over `open`, `private` over `fileprivate`.
- **Omit `internal`** — it is the default.
- **Do not put access control on extensions.** Specify it on each member individually.
- **Mark classes and members `final`** when not designed for subclassing — enables direct dispatch instead of vtable lookups.

## Concurrency

### Isolation

- **`@MainActor` for UI code and ViewModels.** `async` ≠ background — use `@concurrent` to explicitly move work off-thread.
- **`nonisolated` runs on the caller's executor** — prefer for library APIs.
- **Introduce `actor` only when you have non-Sendable mutable state to protect.** Keep model classes on `@MainActor` or non-Sendable.
- **Prefer `@MainActor` annotation** over `MainActor.run`.
- **Finish all mutations on non-Sendable objects** before sending across isolation boundaries.

### Sendable

- **Value types** (struct, enum) with Sendable stored data are implicitly Sendable. Actors and `@MainActor` types likewise.
- **Classes** must be `final` with immutable stored properties. Use `@unchecked Sendable` sparingly with manual synchronization.
- **Prefer keeping types non-Sendable** to let the compiler prevent unsafe sharing.

### Structured Concurrency

- **`async let`** for fixed-count parallel work; **`TaskGroup`** for dynamic count.
- In SwiftUI, **prefer `.task` modifier** over unmanaged `Task { }`.
- **Cancellation is cooperative** — check with `Task.checkCancellation()` or `Task.isCancelled`.
- **`Task.detached`** breaks isolation inheritance — use sparingly.
- **Never block the cooperative thread pool** with semaphores or synchronous waits.

## Performance

Coding practices that help both the compiler and the optimizer — see [Improving build efficiency](https://developer.apple.com/documentation/xcode/improving-build-efficiency-with-good-coding-practices) and [Writing High-Performance Swift Code](https://github.com/swiftlang/swift/blob/main/docs/OptimizationTips.rst).

### Compile Time

- **Provide explicit type annotations** for complex expressions (compound initializers, chained calls, `reduce` results).
  - ✅ `let total: Double = items.reduce(0) { $0 + $1.price }` — ❌ omitting the type annotation
- **Simplify complex expressions.** Break long single-line closures and deeply nested conditionals into multi-line statements to prevent compiler timeouts.
- **Define delegates with explicit protocols**, not `AnyObject?`. Concrete protocol types enable faster method resolution.

### Containers & COW

- **Prefer value types (structs, enums, tuples) in arrays** to avoid NSArray bridging and reduce reference-counting traffic.
- **Use `ContiguousArray`** for arrays of reference types when NSArray bridging is not needed.
- **Mutate collections via `inout`** to preserve COW uniqueness. Avoid copy-then-reassign patterns: ✅ `func appendOne(_ a: inout [Int]) { a.append(1) }`

### Generics

- **Keep generic declarations in the same module** as their call sites so the optimizer can *specialize* — generating concrete code and eliminating generic abstraction overhead.

### Protocols

- **Constrain class-only protocols with `AnyObject`** to enable ARC optimizations: `protocol Pingable: AnyObject { func ping() -> Int }`

### Closures

- **Prefer capturing `let` constants** in escaping closures. Capturing a `var` forces a heap-allocated box; a `let` capture copies the value directly without boxing.
