---
name: swiftlang-server
description: >-
  Server-side Swift guide: Vapor, SwiftNIO, Fluent.
  TRIGGER when: imports Vapor/SwiftNIO/Fluent OR Package.swift
  has vapor/swift-nio deps OR uses EventLoop/Channel/Request types OR
  discusses routes, middleware, or server-side Swift.
  Use with swiftlang.
---

# Server-Side Swift Development Guide

This skill covers server-specific frameworks, architecture, and patterns for Vapor and the SwiftNIO ecosystem. For Swift language fundamentals, concurrency theory (actors, Sendable, data race safety), and style guidelines, refer to the **swiftlang** skill. This skill focuses on how those features apply in a server context.

## When to Read Reference Files

This SKILL.md covers core principles, project setup, and critical rules. For detailed API patterns, read the appropriate reference file:

- **`references/vapor.md`** — Routing, controllers, middleware, Fluent ORM & migrations, authentication, HTTP client, WebSocket, sessions, validation, content system, environment, error handling, server configuration, testing, Docker deployment. Read when writing or modifying Vapor application code.
- **`references/vapor-extras.md`** — Queues (job system), JWT, APNS, Leaf templating, Redis, custom commands, Files API, Services/DI, distributed tracing middleware. Read when integrating these Vapor add-on packages.
- **`references/swiftnio.md`** — EventLoop, Channel, ChannelHandler, ChannelPipeline, Bootstrap, ByteBuffer, NIOAsyncChannel, Swift Concurrency bridging. Read when working at the NIO layer or debugging concurrency/performance issues.
- **`references/ecosystem.md`** — swift-log, swift-metrics, swift-distributed-tracing, swift-service-lifecycle, AsyncHTTPClient, gRPC Swift 2, Swift OpenAPI Generator. Read when integrating observability, managing service lifecycle, or using these libraries.

---

## Project Setup

### Package.swift Template

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(name: "App", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Fluent", package: "fluent"),
            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        ]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
            // Or for Swift Testing: .product(name: "VaporTesting", package: "vapor")
        ]),
    ]
)
```

### Standard Folder Layout

```
.
├── Public/                  # Static assets (served via FileMiddleware)
├── Sources/
│   └── App/
│       ├── Controllers/     # RouteCollection-conforming controllers
│       ├── Migrations/      # AsyncMigration types
│       ├── Models/          # Model + Content types
│       ├── configure.swift  # Register services, DB, migrations
│       ├── entrypoint.swift # @main entry point
│       └── routes.swift     # Register route handlers
├── Tests/
│   └── AppTests/
└── Package.swift
```

### Scaffolding

```bash
# Install Vapor toolbox via Homebrew
brew install vapor

# Create new project (-n answers no to all prompts for a bare template)
vapor new MyApp -n
```

---

## Core Architectural Principles

### 1. Never Block an EventLoop

This is the single most important rule in server-side Swift. SwiftNIO uses one EventLoop per CPU core. Each EventLoop handles many connections. Blocking one blocks ALL clients on that loop.

**Forbidden on EventLoop threads:**
- `Thread.sleep()`, `sleep()`, `usleep()`
- Synchronous file I/O (`FileManager`, synchronous `Data(contentsOf:)`)
- `.wait()` on an EventLoopFuture
- Any long-running computation without yielding

**For CPU-intensive work** (e.g., Bcrypt hashing, image processing):
```swift
// Offload to the thread pool
try await req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
    Bcrypt.hash(password, cost: 12)
}
```

### 2. Prefer async/await Over EventLoopFuture

Vapor 4.76+ and SwiftNIO 2.81+ fully support async/await. Use it as the default for all new code. EventLoopFuture APIs are legacy but still present in older code and some libraries. See [Server-Side Concurrency Patterns](#server-side-concurrency-patterns) for bridging.

### 3. Request Lifecycle

A request flows through middleware in order, reaches the route handler, and the response flows back through middleware in reverse:

```
Request  → MiddlewareA → MiddlewareB → Handler
Response ← MiddlewareA ← MiddlewareB ← Handler
```

All processing happens on the request's assigned EventLoop. Stay non-blocking throughout.

### 4. Content Negotiation

Vapor uses the `Content` protocol (which extends `Codable`) for automatic JSON encoding/decoding. Models that conform to both `Model` and `Content` can be returned directly from route handlers.

```swift
// Decoding request body
let input = try req.content.decode(CreateUserInput.self)

// Returning as response (auto-encodes to JSON)
func index(req: Request) async throws -> [User] {
    try await User.query(on: req.db).all()
}
```

---

## Server-Side Concurrency Patterns

For general Swift concurrency concepts (actors, Sendable, structured concurrency, data race safety), see the **swiftlang** skill. This section covers server-specific patterns.

### EventLoop ↔ async/await Bridging

```swift
// EventLoopFuture → async/await
let result = try await someFuture.get()
// Warning: does NOT respect structured concurrency cancellation

// async → EventLoopFuture
let promise = req.eventLoop.makePromise(of: String.self)
promise.completeWithTask { try await someAsyncFunction() }
let future = promise.futureResult
```

### EventLoop as SerialExecutor

SwiftNIO's EventLoop conforms to `SerialExecutor` (macOS 14+/iOS 17+), enabling actors to run on a specific EventLoop via `NIOSerialEventLoopExecutor`. This bridges structured concurrency with NIO's execution model.

### NIOLoopBound

For safely passing non-`Sendable` values that are bound to a specific EventLoop:

```swift
let bound = NIOLoopBound(nonSendableValue, eventLoop: eventLoop)
// Safe to transfer across concurrency domains — access only on the bound EventLoop
```

### CPU-Intensive Work Offloading

Never run heavy computation on an EventLoop. Offload to the thread pool:

```swift
try await req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
    Bcrypt.hash(password, cost: 12)
}
```

---

## Swift 6 Migration Notes

Vapor 4.118.0+ requires Swift 6.0. For general Swift 6 migration guidance (data race safety, Sendable theory, breaking changes by version), see the **swiftlang** skill's `references/swift-migration.md`. Below are Vapor/NIO-specific changes.

### Sendable Requirements (Vapor-Specific)

`Content` and `View` protocols now have Sendable requirements (breaking change in 4.107.0). Fluent models need `@unchecked Sendable` because property wrappers (`@Field`, `@ID`, etc.) are not Sendable:

```swift
final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    init() { }
}
```

Alternatively, use a separate DTO struct for API responses (avoids exposing model internals):

```swift
final class User: Model, @unchecked Sendable { ... }

struct UserResponse: Content {  // Content implies Sendable — structs are fine
    let id: UUID
    let name: String
}
```

### Deprecated Blocking APIs

`Application.init()` (synchronous) is deprecated since 4.113.0. Use async initialization:

```swift
// Deprecated
let app = Application()

// Preferred
let app = try await Application.make()
defer { try await app.asyncShutdown() }
```

### VaporTesting (Swift Testing)

New `VaporTesting` module (4.110.0+) replaces `XCTVapor` for Swift Testing compatibility:

```swift
import VaporTesting

@Test func helloWorld() async throws {
    try await withApp(configure: configure) { app in
        try await app.testing().test(.GET, "hello") { res in
            #expect(res.status == .ok)
            #expect(res.body.string == "Hello, world!")
        }
    }
}
```

| Deprecated (XCTVapor) | Replacement (VaporTesting) |
|----------------------|---------------------------|
| `XCTAssertContent` | `expectContent` |
| `XCTAssertContains` | `expectContains` |
| `XCTAssertEqualJSON` | `expectEqualJSON` |
| `app.testable()` | `app.testing()` |

### NIOAsyncChannel (SwiftNIO)

The recommended async-first Channel API. Deprecated `.inbound`/`.outbound` properties in favor of `executeThenClose`:

```swift
let channel = try NIOAsyncChannel<ByteBuffer, ByteBuffer>(
    wrappingChannelSynchronously: rawChannel
)
try await channel.executeThenClose { inbound, outbound in
    for try await buffer in inbound {
        try await outbound.write(buffer)
    }
}
```

---

## Critical Gotchas

| Issue | Detail |
|-------|--------|
| `.wait()` on EventLoop | Causes assertion failure / deadlock. Never do this. |
| Body size limit | Default 16KB. For larger payloads: `app.on(.POST, "upload", body: .collect(maxSize: "1mb"))` or `body: .stream` |
| CORS middleware order | `CORSMiddleware` must be registered at `.beginning` — before `ErrorMiddleware`, or error responses lack CORS headers |
| Migration order | Register migrations in dependency order — parent tables before child tables |
| Empty model init | Fluent models require `init() { }` — Fluent needs it for hydration |
| Parent ID assignment | Set via `self.$parent.id = parentID`, not the relation property |
| Route closure syntax | Async uses `{ req async throws -> Type in }` — `async` is in the closure signature |
| Parameter extraction | `req.parameters.get("id")` returns optional — always guard/unwrap |
| Bcrypt CPU cost | Deliberately expensive — offload to thread pool in high-traffic apps |
| Swift 6 concurrency | Vapor 4.121+ uses swift-tools-version 6.0 with strict concurrency checking |

---

## Version Reference

| Package | Current Version | Swift Requirement | Depend With |
|---------|----------------|-------------------|-------------|
| Vapor | 4.121.x | Swift 6.0+ | `from: "4.76.0"` |
| SwiftNIO | 2.97.x | Swift 6.0+ (2.87+) | `from: "2.0.0"` |
| Fluent | 4.x | Swift 5.8+ | `from: "4.0.0"` |
| FluentPostgresDriver | 2.x | Swift 5.8+ | `from: "2.0.0"` |
| JWT (vapor/jwt) | 5.x | Swift 6.0+ | `from: "5.0.0"` |
| Queues Redis Driver | 1.x | Swift 5.9+ | `from: "1.0.0"` |
| APNS (vapor/apns) | 4.x | Swift 5.9+ | `from: "4.0.0"` |
| Leaf | 4.x | Swift 5.8+ | `from: "4.0.0"` |
| Redis (vapor/redis) | 4.x | Swift 5.8+ | `from: "4.0.0"` |
| AsyncHTTPClient | 1.33.x | Swift 6.0+ | `from: "1.24.0"` |
| swift-log | 1.11.x | Swift 5.8+ | `from: "1.6.0"` |
| swift-metrics | 2.8.x | Swift 5.8+ | `from: "2.5.0"` |
| swift-service-lifecycle | 2.11.x | Swift 6.0+ | `from: "2.0.0"` |

---

## Upstream Sources

The reference files in this skill are derived from the sources below. Consult them when information is insufficient or freshness is uncertain. Also use these sources when updating reference files.

- **Vapor**: [docs.vapor.codes](https://docs.vapor.codes), [api.vapor.codes](https://api.vapor.codes)
- **Server-side Swift overview**: [swift.org/documentation/server](https://www.swift.org/documentation/server/)
- **Server ecosystem packages**: each package's repository README or [Swift Package Index](https://swiftpackageindex.com)
