# Swift Style Guide

Comprehensive formatting, naming, and coding conventions based on the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and the [Google Swift Style Guide](https://google.github.io/swift/).

## Table of Contents

1. [Formatting](#formatting)
2. [Line-Wrapping](#line-wrapping)
3. [File Organization](#file-organization)
4. [Documentation](#documentation)
5. [Naming](#naming)
6. [Conventions](#conventions)
7. [Attributes & Access Control](#attributes--access-control)
8. [Concurrency Patterns](#concurrency-patterns)
9. [Performance](#performance)

---

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
- Space on both sides of binary/ternary operators, `=`, `->`, `&` (protocol composition). No space around `.` and range operators (`..<`, `...`).
- Space after `,`, `:`, and `//`. At least two spaces before trailing `//` comments.
- Space between control-flow keyword (`if`, `guard`, `while`, `switch`) and `(` that follows.

### General

- **No parentheses** around top-level conditions: `if condition {` — not `if (condition) {`. Optional grouping parentheses are fine to clarify complex expressions.
- **No semicolons.** Not to terminate, not to separate.
- **One statement per line.** Exception: single-statement blocks may appear on the same line:

```swift
guard let value = value else { return 0 }
defer { file.close() }
var someProperty: Int { return otherObject.value }
```

### Trailing Commas

- **Required** in multi-line collection literals, parameter lists, generic parameters, closure capture lists, and tuple elements.

### Switch Statements

- `case` at **same indentation level** as `switch`.
- Statements inside case indented +4 from `case`.
- Combine cases using ranges (`2...4`) or comma lists (`5, 7`) instead of `fallthrough`.

### Numeric Literals

- Use `_` separators for readability: thousands for decimal (`1_000_000`), 4-digit groups for hex (`0xFF_EC_01_28`).

### Horizontal Alignment

- **Forbidden** except for obviously tabular data. Alignment creates maintenance burden and obscures the logical structure of code.

---

## Line-Wrapping

### Cardinal Rules

1. If it fits on one line, keep it on one line.
2. Comma-delimited lists go **one direction only** — all on one line OR each on its own line. No mixing.
3. Continuation lines in vertically-oriented comma lists are indented **+4** from the original line.
4. Opening `{` goes on the same line as the last continuation, unless that line is already +4 indented — then `{` on its own line to avoid visual blending.

### Function Declarations

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

### Function Calls

Each argument on its own line when wrapping, closing `)` always on its own line:

```swift
let idx = index(
    of: element,
    in: collection
)
```

### Type & Extension Declarations

Inheritance list each on its own line, `where` clause likewise:

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

### Control Flow

Break after keyword, indent conditions +4:

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

### Other Expressions

Continuation lines +4 from original. If too complex, split into temporary variables.

---

## File Organization

- **One primary type per file.** File name matches the type: `MyType.swift`.
- Protocol conformance extensions in separate files: `MyType+Protocol.swift`.
- Use **`// MARK:`** to organize members within a file. Use `// MARK: -` for dividers.
- **Import statements** at the top, grouped and sorted lexicographically with blank lines between groups:
  1. Module imports
  2. Individual declaration imports (`import func`, `import struct`, etc.)
  3. `@testable` imports (test targets only)

```swift
import CoreLocation
import Foundation
import UIKit

import func Darwin.C.isatty

@testable import MyModuleUnderTest
```

- Import exactly what is needed. Do not rely on transitive imports. Use `internal import` (SE-0409) to hide implementation dependencies from consumers.

---

## Documentation

- Use **`///`** (triple-slash). Block comments `/** */` are forbidden for documentation.
- Use `//` for inline comments. Avoid `/* */` block comments.
- Begin with a **single-sentence summary** (a fragment, ending with a period).
- **Describe what functions do and what they return**, omitting null effects and `Void` returns.
- **Describe what subscripts access**, what initializers create, and what other declarations are.
- Add detail in subsequent paragraphs separated by blank `///` lines.
- Use recognized symbol commands: `- Parameter`, `- Returns`, `- Throws`, `- Complexity`, `- Note`, `- Important`, `- Warning`, `- SeeAlso`, etc.
- Order: Parameters first, then Returns, then Throws.
- Write documentation comments for every public declaration. If you struggle to describe the API simply, you may have designed the wrong API.

---

## Naming

### Promote Clear Usage

- **Include all words needed to avoid ambiguity** at the use site.
  - `employees.remove(at: x)` — not `employees.remove(x)` (position vs. search)
- **Omit needless words** — especially those that repeat type information.
  - `remove(_ member: Element)` — not `removeElement(_ member: Element)`
- **Name variables and parameters by their role**, not their type.
  - `var greeting: String` — not `var string: String`
- **Compensate for weak type information.** When a parameter type is `Any`, `NSObject`, or a fundamental type, prepend a descriptive noun to the label.
  - `addObserver(_ observer: NSObject, forKeyPath path: String)` — not `add(_ observer: NSObject, for keyPath: String)`

### Strive for Fluent Usage

- **Method calls should read as grammatical English phrases.**
  - `x.insert(y, at: z)` → "x, insert y at z" — not `x.insert(y, position: z)`
- **Factory methods** begin with `make`: `makeIterator()`
- **Initializer and factory-method arguments** form an independent phrase, not one with the base name.
  - `Color(red: 32, green: 64, blue: 128)` — not `Color(havingRGBValuesRed: 32, ...)`

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
- **Global constants** use `lowerCamelCase`. No Hungarian notation: `secondsPerMinute` — not `kSecondsPerMinute` or `SECONDS_PER_MINUTE`.

### Delegate Methods

- First argument is always the delegate's source object (unlabeled).
- Source + returns Void: `func scrollViewDidBeginScrolling(_ scrollView: UIScrollView)`
- Source + returns Bool: `func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool`
- Source + additional args: `func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)`

### Terminology

- **Avoid obscure terms** when a common word conveys meaning equally well.
- **Stick to established meaning.** Don't repurpose a term of art.
- **Avoid abbreviations**, especially non-standard ones.
- **Embrace precedent.** Prefer `Array` over `List` to match existing programmer expectations.

---

## Conventions

### General

- **Document computational complexity** of any property that is not O(1).
- **Prefer methods and properties** over free functions. Use free functions only when:
  - There is no obvious `self`: `min(x, y, z)`
  - The function is an unconstrained generic: `print(x)`
  - Domain notation uses function syntax: `sin(x)`
- **Methods can share a base name** when they have the same basic meaning or operate in distinct domains. **Avoid overloading on return type alone.**

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

### Trailing Closures

- **Single closure as final argument**: always use trailing closure syntax.
  - Exception: when needed to disambiguate overloads, or when it would be parsed as a control-flow body.
- **Multiple closure arguments**: do not use trailing closure syntax; label all closures inside parentheses.
- **No empty `()`** before trailing closure: `[1, 2, 3].map { $0 * $0 }` — not `.map() { ... }`

### Pattern Matching

- **Per-element `let`/`var`** in pattern bindings. The shorthand form distributing across the entire pattern is avoided:

```swift
// Preferred
case .labeled(let label, let value):

// Avoided
case let .labeled(label, value):
```

### Namespacing

- Use **caseless `enum`** for namespace constructs (automatically non-instantiable):

```swift
enum Dimensions {
    static let tileMargin: CGFloat = 8
    static let tilePadding: CGFloat = 4
}
```

- Do not use `struct` with `private init()` for this purpose.

### Control Flow

- **`guard` for early exits and preconditions.** Keeps main logic flush-left and failure conditions coupled to their triggers.
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

### Unconstrained Polymorphism

- Take extra care with `Any`, `AnyObject`, and unconstrained generic parameters to avoid ambiguity. Disambiguate with descriptive labels like `append(contentsOf:)` vs `append(_:)`.

### Type Inference & Shorthand

- **Omit type annotations** when the type is obvious from the right-hand side. Exception: complex expressions (see Performance).
  - `let sun = Star(mass: 1.989e30)` — not `let sun: Star = Star(mass: 1.989e30)`
- **Use shorthand type syntax**: `[Element]`, `String?`, `[Key: Value]` — not `Array<Element>`, `Optional<String>`, `Dictionary<Key, Value>`.
- **Omit `-> Void`** in function declarations. In closure types, use `Void`: `() -> Void` — not `() -> ()`.
- **Omit `.init`** when not required: `Universe()` — not `Universe.init()`.

---

## Attributes & Access Control

### Attribute Ordering

Declarations follow this order: **doc comment → `@` attributes → access control + other modifiers → declaration keyword**.

Each `@` attribute occupies its own line, lexicographically ordered. Access control and other modifiers stay on the same line as the declaration.

```swift
/// Fetches the user profile.
@MainActor
@available(iOS 17.0, *)
@discardableResult
public final func fetchProfile() -> Profile { }
```

### Access Control

- **Use the strictest level possible.** Prefer `public` over `open`, `private` over `fileprivate`.
- **Omit `internal`** — it is the default.
- **Do not put access control on extensions.** Specify it on each member individually:

```swift
// Correct
extension String {
    public var isUppercase: Bool { ... }
    public var isLowercase: Bool { ... }
}

// Wrong
public extension String {
    var isUppercase: Bool { ... }
}
```

- **Mark classes and members `final`** when not designed for subclassing — enables direct dispatch instead of vtable lookups.

---

## Concurrency Patterns

### Isolation

- **`@MainActor` for UI code and ViewModels.** Consider module-level `defaultIsolation` (Swift 6.2+) to apply this by default.
- **`@concurrent`** (6.2+) to explicitly move async work off the caller's executor — nonisolated async functions now stay on the caller's executor by default.
- **`nonisolated`** on types/extensions (6.1+) to cleanly opt out of inherited actor isolation.
- Introduce **`actor`** only when you have non-Sendable mutable state to protect. Keep model classes on `@MainActor` or non-Sendable.
- Prefer **`@MainActor` annotation** over `MainActor.run`.
- Finish all mutations on non-Sendable objects before sending across isolation boundaries.

### Sendable

- **Value types** (struct, enum) with Sendable stored data are implicitly Sendable. Actors and `@MainActor` types likewise.
- **Classes** must be `final` with immutable stored properties. Use `@unchecked Sendable` sparingly with manual synchronization.
- Prefer keeping types **non-Sendable** to let the compiler prevent unsafe sharing.

### Structured Concurrency

- **`async let`** for fixed-count parallel work; **`TaskGroup`** for dynamic count.
- In SwiftUI, prefer **`.task` modifier** over unmanaged `Task { }`.
- **Cancellation is cooperative** — check with `Task.checkCancellation()` or `Task.isCancelled`.
- **`Task.detached`** breaks isolation inheritance — use sparingly.
- Never block the cooperative thread pool with semaphores or synchronous waits.

---

## Performance

Practices that help both the compiler and the optimizer. Reference: [Writing High-Performance Swift Code](https://github.com/swiftlang/swift/blob/main/docs/OptimizationTips.rst).

### Compiler Settings

- Enable **Whole Module Optimization (WMO)** for production builds. WMO enables cross-file inlining, devirtualization, and generic specialization.
- Use `-O` for speed-critical code, `-Osize` for most production code.

### Reducing Dynamic Dispatch

- **`final`** on classes/methods/properties enables direct calls and inlining.
- **`private` / `fileprivate`** lets the compiler auto-infer `final` within the file.
- **`internal` + WMO** gives the compiler module-wide visibility to devirtualize automatically.

### Compile Time

- **Provide explicit type annotations** for complex expressions (compound initializers, chained calls, `reduce` results).
  - `let total: Double = items.reduce(0) { $0 + $1.price }` — not omitting the annotation
- **Simplify complex expressions.** Break long single-line closures and deeply nested conditionals into multi-line statements to prevent compiler timeouts.

### Containers & COW

- **Prefer value types (structs, enums, tuples) in arrays** to avoid NSArray bridging and reduce reference-counting traffic.
- **Use `ContiguousArray`** for arrays of reference types when NSArray bridging is not needed.
- **Mutate collections via `inout`** to preserve COW uniqueness. Avoid copy-then-reassign patterns:

```swift
// Good: mutates in place, no copy
func appendOne(_ a: inout [Int]) {
    a.append(1)
}

// Bad: may trigger unnecessary copy
func appendOne(_ a: [Int]) -> [Int] {
    var a = a
    a.append(1)
    return a
}
```

### Generics

- **Keep generic declarations in the same module** as their call sites so the optimizer can specialize — generating concrete code and eliminating generic abstraction overhead.

### Protocols

- **Constrain class-only protocols with `AnyObject`** to enable ARC optimizations: `protocol Pingable: AnyObject { func ping() -> Int }`

### Closures

- **Prefer capturing `let` constants** in escaping closures. Capturing a `var` forces a heap-allocated box; a `let` capture copies the value directly without boxing.

### Arithmetic

- **Wrapping operators** (`&+`, `&-`, `&*`) skip overflow checks. Use only when you can prove overflow will not occur or wrapping is desired (e.g., hashing, cryptography). Include a comment explaining the safety rationale.

### Large Value Types

- For large value types (e.g., tree structures), implement **COW semantics** by wrapping data in a reference-counted box with `isKnownUniquelyReferenced`.
