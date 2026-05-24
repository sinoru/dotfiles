# Official Swift Packages

Apple-maintained Swift packages organized by category. These are production-quality libraries — prefer them over third-party alternatives or hand-rolled implementations.

> For SwiftNIO and server-side networking packages, see the `server-side-swift` skill.

## Table of Contents

1. [Data Structures & Algorithms](#data-structures--algorithms)
2. [Concurrency & System](#concurrency--system)
3. [HTTP](#http)
4. [Security & Cryptography](#security--cryptography)
5. [Serialization & Data Formats](#serialization--data-formats)
6. [Observability](#observability)
7. [API Generation](#api-generation)
8. [Developer Tools](#developer-tools)
9. [Quick Reference](#quick-reference)

---

## Data Structures & Algorithms

### swift-collections — `apple/swift-collections`

High-performance data structures beyond the standard library.

| Type | Module | Description |
|---|---|---|
| `Deque<Element>` | `DequeModule` | O(1) prepend/append, O(1) popFirst/popLast. Use instead of Array for FIFO queues |
| `OrderedSet<Element>` | `OrderedCollections` | Insertion-ordered + unique. O(1) membership. `.unordered` view for SetAlgebra |
| `OrderedDictionary<K,V>` | `OrderedCollections` | Insertion-ordered key-value. Positional access via `index(forKey:)` |
| `Heap<Element>` | `HeapModule` | Min-max heap for priority queues |
| `BitSet`, `BitArray` | `BitCollections` | Compact bit-level collections |
| `TreeSet`, `TreeDictionary` | `HashTreeCollections` | Persistent hash array mapped trie. Efficient structural sharing |

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

### swift-numerics — `apple/swift-numerics`

Generic numerical computing building blocks.

- **`Real` protocol**: Combines `ElementaryFunctions` + `RealFunctions` for generic floating-point code
- **`Complex<T: Real>`**: Complex number arithmetic, significantly faster than C/C++ for multiply/divide
- Use case: `func compute<T: Real>(_ x: T) -> T` — works across `Float`, `Double`, `Float80`

---

## Concurrency & System

### swift-atomics — `apple/swift-atomics`

Low-level atomic operations with explicit memory orderings.

- **`ManagedAtomic<T>`**: Heap-allocated atomic (most common)
- **`UnsafeAtomic<T>`**: Inline storage for advanced use
- Memory orderings: `.relaxed`, `.acquiring`, `.releasing`, `.acquiringAndReleasing`, `.sequentiallyConsistent`
- **When to use**: Lock-free data structures, custom synchronization. Prefer actors/structured concurrency for application code.

### swift-system — `apple/swift-system`

Idiomatic Swift wrappers for low-level system calls.

- **`FilePath`**: Type-safe file path manipulation
- **`FileDescriptor`**: POSIX file descriptor wrapper with `open`, `close`, `read`, `write`, `seek`
- **`Errno`**: System error codes
- **When to use**: Low-level file I/O, system call interop without raw C pointers

### swift-subprocess — `swiftlang/swift-subprocess`

Concurrency-friendly child process management. Requires Swift 6.1+.

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

## Observability

### swift-log — `apple/swift-log`

Unified structured logging API with pluggable backends.

```swift
var logger = Logger(label: "com.example.app")
logger.info("Request received", metadata: ["requestId": "\(id)"])
```

### swift-metrics — `apple/swift-metrics`

Unified metrics API: `Counter`, `Timer`, `Gauge`, `Histogram`. Pluggable backends (Prometheus, StatsD, etc.).

### swift-distributed-tracing — `apple/swift-distributed-tracing`

Distributed tracing API: `Tracer`, `Span`, trace context propagation. Compatible with OpenTelemetry.

### swift-service-context — `apple/swift-service-context`

Zero-dependency context propagation using task-local values. Carries cross-cutting metadata (trace IDs, request IDs) across async call chains.

---

## API Generation

### swift-openapi-generator — `apple/swift-openapi-generator`

SwiftPM build plugin generating type-safe client and server code from OpenAPI 3.0/3.1/3.2 specs.

- Code generated at build time — no manual maintenance
- `swift-openapi-runtime`: Common types and transport protocols
- `swift-openapi-urlsession`: URLSession-based client transport

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

---

## Quick Reference

| Category | Package | Key Types/APIs |
|---|---|---|
| Data Structures | swift-collections | `Deque`, `OrderedSet`, `OrderedDictionary`, `Heap`, `BitSet` |
| Algorithms | swift-algorithms | `chunked`, `combinations`, `uniqued`, `product`, `indexed` |
| Async Algorithms | swift-async-algorithms | `merge`, `zip`, `combineLatest`, `debounce`, `throttle` |
| Numerics | swift-numerics | `Real`, `Complex<T>` |
| Atomics | swift-atomics | `ManagedAtomic<T>` |
| System | swift-system | `FilePath`, `FileDescriptor` |
| Subprocess | swift-subprocess | `Subprocess.run()` |
| HTTP Types | swift-http-types | `HTTPRequest`, `HTTPResponse`, `HTTPFields` |
| Crypto | swift-crypto | SHA, AES-GCM, ECDSA, Ed25519, HKDF |
| Certificates | swift-certificates | X.509 parse/create/verify |
| Protobuf | swift-protobuf | `SwiftProtobuf` runtime + codegen |
| Logging | swift-log | `Logger` |
| Metrics | swift-metrics | `Counter`, `Timer`, `Gauge` |
| Tracing | swift-distributed-tracing | `Tracer`, `Span` |
| OpenAPI | swift-openapi-generator | Build-time client/server codegen |
| CLI Parsing | swift-argument-parser | `ParsableCommand`, `@Argument`, `@Option` |
| Syntax | swift-syntax | Macro infrastructure, AST |
| Formatting | swift-format | Code formatter |
| Testing | swift-testing | `@Test`, `#expect` |
