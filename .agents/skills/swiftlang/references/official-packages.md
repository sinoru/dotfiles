# Official Swift Packages

Apple-maintained Swift packages organized by category. These are production-quality libraries — prefer them over third-party alternatives or hand-rolled implementations.

> For SwiftNIO, server-side networking, and observability packages (swift-log, swift-metrics, tracing, OpenAPI, gRPC), see `references/server/` — start with `server/ecosystem.md`.

## Table of Contents

1. [Data Structures & Algorithms](#data-structures--algorithms)
2. [Concurrency & System](#concurrency--system)
3. [HTTP](#http)
4. [Security & Cryptography](#security--cryptography)
5. [Serialization & Data Formats](#serialization--data-formats)
6. [Observability & API Generation](#observability--api-generation)
7. [Developer Tools](#developer-tools)

---

## Data Structures & Algorithms

### swift-collections — `apple/swift-collections`

High-performance data structures beyond the standard library.

| Type | Module | Description |
|---|---|---|
| `Deque<Element>` | `DequeModule` | O(1) prepend/append, O(1) popFirst/popLast. Use instead of Array for FIFO queues |
| `OrderedSet<Element>` | `OrderedCollections` | Insertion-ordered + unique. O(1) membership. `.unordered` view for SetAlgebra |
| `OrderedDictionary<K,V>` | `OrderedCollections` | Insertion-ordered key-value. Positional access via `index(forKey:)`. 1.5+: `replaceElement(at:withKey:value:)`, `moveSubrange(_:to:)` reordering |
| `Heap<Element>` | `HeapModule` | Min-max heap for priority queues |
| `BitSet`, `BitArray` | `BitCollections` | Compact bit-level collections |
| `TreeSet`, `TreeDictionary` | `HashTreeCollections` | Persistent hash array mapped trie. Efficient structural sharing |
| `UniqueArray`, `RigidArray` | `BasicContainers` (1.3+) | Ownership-aware noncopyable containers — `Unique*` grows, `Rigid*` is fixed-capacity. Pair with `InlineArray`/`Span` for systems code |
| `UniqueDeque`, `RigidDeque` | `DequeModule` (1.4+) | Noncopyable deque variants |
| `TrailingArray` | `TrailingElements` (1.3+) | C-style header-plus-trailing-elements layouts for interop |

Experimental (opt-in via package traits, 1.4+): `UniqueSet`/`RigidSet`/`UniqueDictionary`/`RigidDictionary` (`UnstableHashedContainers`), `SortedSet`/`SortedDictionary` (`UnstableSortedCollections`).

### swift-algorithms — `apple/swift-algorithms`

Sequence and collection algorithms replacing hand-written loops.

| Algorithm | Description |
|---|---|
| `chunked(by:)` / `chunked(on:)` | Break into consecutive subsequences |
| `windows(ofCount:)` | Sliding window over collection |
| `combinations(ofCount:)` | All combinations of given size |
| `permutations(ofCount:)` | All permutations |
| `product(_:_:)` | Cartesian product of two sequences |
| `chain(_:_:)` | Concatenate two sequences |
| `uniqued()` / `uniqued(on:)` | Remove duplicates preserving order |
| `indexed()` | Pair each element with its index |
| `partitioned(by:)` | Divide by predicate |
| `randomSample(count:)` | Random sampling |

### swift-async-algorithms — `apple/swift-async-algorithms`

Operations on `AsyncSequence` — combining, rate-limiting, transforming async streams.

| API | Description |
|---|---|
| `merge(_:_:)` | Combine same-type async sequences |
| `zip(_:_:)` | Combine into tuples |
| `combineLatest(_:_:)` | Emit on any source update |
| `chain(_:_:)` | Concatenate end-to-end |
| `debounce(for:)` | Wait for quiet period (search-as-you-type) |
| `throttle(for:)` | Rate-limit emission |
| `AsyncChannel` | Sendable async sequence for producer-consumer |
| `AsyncTimerSequence` | Clock-based periodic emission |
| `MultiProducerSingleConsumerChannel` (1.1+) | Backpressure-aware channel; multiple producers, single consumer (duplex variant in 1.1.5) |
| `flatMapLatest` (1.1.3+) | Switch to the newest inner sequence, cancelling the previous one |

### swift-numerics — `apple/swift-numerics`

Generic numerical computing building blocks.

- **`Real` protocol**: Combines `ElementaryFunctions` + `RealFunctions` for generic floating-point code
- **`Complex<T: Real>`**: Complex number arithmetic, significantly faster than C/C++ for multiply/divide
- Use case: `func compute<T: Real>(_ x: T) -> T` — works across `Float`, `Double`, `Float80`

---

## Concurrency & System

### Atomics: stdlib `Synchronization` first, swift-atomics for older toolchains

On Swift 6.0+, the standard library's **`Synchronization` module (`Atomic<T>`, `Mutex`, SE-0410)** is the first choice — no dependency needed. Reach for `apple/swift-atomics` only when supporting pre-6.0 toolchains:

- **`ManagedAtomic<T>`**: Heap-allocated atomic (most common)
- Memory orderings: `.relaxed`, `.acquiring`, `.releasing`, `.acquiringAndReleasing`, `.sequentiallyConsistent`
- **When to use either**: Lock-free data structures, custom synchronization. Prefer actors/structured concurrency for application code.

### swift-system — `apple/swift-system`

Idiomatic Swift wrappers for low-level system calls.

- **`FilePath`**: Type-safe file path manipulation
- **`FileDescriptor`**: POSIX file descriptor wrapper with `open`, `close`, `read`, `write`, `seek`
- **`Errno`**: System error codes
- **When to use**: Low-level file I/O, system call interop without raw C pointers

### swift-subprocess — `swiftlang/swift-subprocess`

Concurrency-friendly child process management. Requires Swift 6.1+; source-stable since 1.0.

```swift
let result = try await Subprocess.run(.name("git"), arguments: ["status"])
```

Replaces `Foundation.Process` with async/await API.

---

## HTTP

### swift-http-types — `apple/swift-http-types`

Version-independent HTTP currency types shared between clients and servers.

- **`HTTPRequest`**, **`HTTPResponse`**: Core request/response types
- **`HTTPFields`**: Ordered, case-insensitive header collection
- **`HTTPField.Name`**: Predefined header names with static properties
- **`HTTPTypesFoundation`**: Bridges to/from `URLRequest`/`URLResponse`
- **When to use**: As the common HTTP type layer. URLSession (Foundation) and SwiftNIO both support these types.

### swift-http-structured-headers — `apple/swift-http-structured-headers`

RFC 9651 Structured Field Values parser/serializer.

- `RawStructuredFieldValues`: No Foundation dependency
- `StructuredFieldValues`: `Codable` integration
- **When to use**: Parsing/generating structured HTTP headers per RFC spec (e.g., `Accept`, `Cache-Control`)

---

## Security & Cryptography

### swift-crypto — `apple/swift-crypto`

Cross-platform CryptoKit API. On Apple platforms delegates to CryptoKit; elsewhere uses BoringSSL.

| Category | APIs |
|---|---|
| Hashing | SHA256, SHA384, SHA512 |
| HMAC | HMAC\<SHA256\>, HMAC\<SHA384\>, HMAC\<SHA512\> |
| Symmetric Encryption | AES-GCM, ChaChaPoly |
| Key Agreement | P256, P384, P521, Curve25519 |
| Signatures | ECDSA, Ed25519 |
| Key Derivation | HKDF |
| `_CryptoExtras` | RSA, AES-CBC, and other server-specific algorithms |

### swift-certificates — `apple/swift-certificates`

X.509 certificate handling: parse, create, verify. Built-in verifier with customizable policies.

### swift-asn1 — `apple/swift-asn1`

ASN.1/DER encoding and decoding. Foundation for swift-certificates.

---

## Serialization & Data Formats

### swift-protobuf — `apple/swift-protobuf`

Protocol Buffers runtime + `protoc-gen-swift` code generator.

- Generated structs are value types with COW
- Binary and JSON serialization
- **When to use**: gRPC services, cross-language serialization

### swift-binary-parsing — `apple/swift-binary-parsing`

Safe binary format parsing without manual pointer arithmetic.

- **`ParserSpan`**: Safe view into binary data
- Overflow-safe arithmetic operators (`*?`, `+?`)
- **When to use**: Parsing binary file formats (images, network packets, archives)

---

## Observability & API Generation

swift-log, swift-metrics, swift-distributed-tracing, swift-service-context, and swift-openapi-generator are covered in depth in **`references/server/ecosystem.md`** — read that file instead (CLI tools and daemons use these as much as servers do).

---

## Developer Tools

### swift-argument-parser — `apple/swift-argument-parser`

De facto standard for Swift CLI argument parsing.

```swift
@main
struct Greet: ParsableCommand {
    @Argument var name: String
    @Option(name: .shortAndLong) var count: Int = 1
    func run() { for _ in 0..<count { print("Hello, \(name)!") } }
}
```

### swift-syntax — `swiftlang/swift-syntax`

Source-accurate Swift syntax tree. Foundation for macros, linters, code generation.

### swift-format — `swiftlang/swift-format`

Official Swift code formatter. Powers SourceKit-LSP formatting.

### swift-markdown — `swiftlang/swift-markdown`

Markdown AST parser/builder based on cmark-gfm. Parse, build, edit, analyze Markdown documents.

### swift-testing — `swiftlang/swift-testing`

Modern testing framework: `@Test`, `#expect`, `#require`, parameterized tests, traits. Ships with Swift 6.0+ toolchains.

