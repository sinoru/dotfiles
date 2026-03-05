---
name: swiftlang-style
description: "Swift API Design Guidelines and naming conventions. TRIGGER when: about to write, modify, or review *.swift files. Invoke once at the start of a coding task, before writing code. DO NOT TRIGGER when: only reading/researching code without making changes."
---

# Swift Code Style

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).

## Fundamentals

- **Clarity at the point of use** is the most important goal. Entities are declared once but used repeatedly — optimize for the use site.
- **Clarity over brevity.** Compact code is a side-effect of Swift's type system, not a goal in itself.
- **Write documentation comments** for every declaration. If you struggle to describe the API simply, you may have designed the wrong API.

## Documentation

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
- **Case conventions:**
  - Types and Protocols → `UpperCamelCase`
  - Everything else → `lowerCamelCase`
  - **Acronyms** follow uniform casing: `utf8Bytes`, `HTTPSConnection`, `isRepresentableAsASCII`
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

## Performance

Coding practices that help both the compiler and the optimizer — see [Improving build efficiency](https://developer.apple.com/documentation/xcode/improving-build-efficiency-with-good-coding-practices) and [Writing High-Performance Swift Code](https://github.com/swiftlang/swift/blob/main/docs/OptimizationTips.rst).

### Compile Time

- **Provide explicit type annotations** for complex expressions (compound initializers, chained calls, `reduce` results).
  - ✅ `let total: Double = items.reduce(0) { $0 + $1.price }` — ❌ omitting the type annotation
- **Simplify complex expressions.** Break long single-line closures and deeply nested conditionals into multi-line statements to prevent compiler timeouts.
- **Define delegates with explicit protocols**, not `AnyObject?`. Concrete protocol types enable faster method resolution.

### Access Control & Dispatch

- **Use `private` / `fileprivate`** to minimize symbol visibility. This reduces compiler work (fewer exported symbols, smaller generated headers) *and* enables the optimizer to infer `final` for runtime dispatch.
- **Mark classes and members `final`** when they are not designed for subclassing — enables direct calls instead of vtable lookups.
- **`internal` (default) + Whole Module Optimization** — the optimizer sees the entire module and can infer `final` for internal declarations never overridden.

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
