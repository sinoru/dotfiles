# Server-Side Swift Guide

Server-specific frameworks, architecture, and patterns for Vapor and the SwiftNIO ecosystem. Swift language fundamentals, concurrency theory (actors, Sendable, data race safety), and style rules are covered by `SKILL.md` and the language references (`references/style-guide.md`, `references/swift-6_*.md`); this file focuses on how those features apply in a server context.

## Files in This Directory

This overview covers core principles, project setup, and critical rules. For detailed API patterns, read the matching file (paths are relative to the skill root):

- **`references/server/vapor.md`** — Routing, controllers, middleware (incl. TracingMiddleware), Fluent ORM & migrations, authentication, HTTP client, WebSocket, sessions, validation, content system, environment, error handling, server configuration, testing, Files API (streaming), Docker deployment. Read when writing or modifying Vapor application code.
- **`references/server/vapor-extras.md`** — Queues (job system), JWT, APNS, Leaf templating, Redis, custom commands, Services/DI. Read when integrating these Vapor add-on packages.
- **`references/server/swiftnio.md`** — EventLoop, Channel, ChannelHandler, ChannelPipeline, Bootstrap, ByteBuffer, NIOAsyncChannel, Swift Concurrency bridging. Read when working at the NIO layer or debugging concurrency/performance issues.
- **`references/server/ecosystem.md`** — swift-log, swift-metrics, swift-distributed-tracing, swift-service-lifecycle, AsyncHTTPClient, gRPC Swift 2, Swift OpenAPI Generator. Read when integrating observability, managing service lifecycle, or using these libraries (in servers, CLI tools, and daemons alike).

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
        .package(url: "https://github.com/vapor/vapor.git", from: "4.118.0"),
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
            .product(name: "VaporTesting", package: "vapor"),
            // Legacy XCTest suites: .product(name: "XCTVapor", package: "vapor")
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

For general Swift concurrency concepts (actors, Sendable, structured concurrency, data race safety), see `SKILL.md` and the `references/swift-6_x.md` files. The server-specific bridging tools live in **`references/server/swiftnio.md`** (code examples there):

- **EventLoopFuture ↔ async/await bridging** — `try await future.get()` (does NOT respect structured-concurrency cancellation) and `promise.completeWithTask { }`
- **EventLoop as SerialExecutor** — run actors on a specific EventLoop via `NIOSerialEventLoopExecutor`
- **NIOLoopBound** — safely pass non-`Sendable` values bound to one EventLoop
- **CPU offloading** — never run heavy computation on an EventLoop; use the thread-pool pattern from Principle 1 above

---

## Swift 6 Migration Notes

Vapor 4.118.0+ requires Swift 6.0. For general Swift 6 migration guidance (data race safety, Sendable theory, breaking changes by version), see `references/swift-migration.md`. Below are Vapor/NIO-specific changes.

Vapor/NIO-specific changes, with code examples in the detail files:

- **Sendable requirements** (breaking in 4.107.0): `Content` and `View` are `Sendable`. Fluent models are declared `final class … Model, Content, @unchecked Sendable` (property wrappers aren't Sendable) with an empty `init() {}`; a DTO `struct` conforming to `Content` is the cleaner shape for API responses. See "Model Definition" in `vapor.md`.
- **Deprecated blocking APIs** (4.113.0): synchronous `Application()` is deprecated — use `try await Application.make()` + `try await app.asyncShutdown()`.
- **VaporTesting** (4.110.0+): Swift Testing support via `withApp` / `app.testing()`, replacing `XCTVapor`/`app.testable()`. See "Testing" in `vapor.md` for the full example and the XCTVapor→VaporTesting rename table.
- **NIOAsyncChannel**: the async-first Channel API — `executeThenClose` replaces the deprecated `.inbound`/`.outbound` properties. See `swiftnio.md`.

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

This table is the **single source of truth for versions** in this directory — the other files intentionally do not repeat version pins. Verified 2026-08; versions rot, so double-check the package's releases page when precision matters.

| Package | Current Version | Swift Requirement | Depend With |
|---------|----------------|-------------------|-------------|
| Vapor | 4.122.x | Swift 6.0+ (4.118+) | `from: "4.118.0"` |
| SwiftNIO | 2.101.x | Swift 6.0+ (2.87+) | `from: "2.81.0"` |
| Fluent | 4.13.x | Swift 6.0+ (4.13+) | `from: "4.0.0"` |
| FluentPostgresDriver | 2.x | Swift 5.8+ | `from: "2.0.0"` |
| JWT (vapor/jwt) | 5.x | Swift 6.0+ | `from: "5.0.0"` |
| Queues Redis Driver | 1.x | Swift 5.9+ | `from: "1.0.0"` |
| APNS (vapor/apns) | 4.x | Swift 5.9+ | `from: "4.0.0"` |
| Leaf | 4.x (LeafKit ≥ 1.14.2 — XSS fixes) | Swift 5.8+ | `from: "4.0.0"` |
| Redis (vapor/redis) | 4.14.x | Swift 5.8+ | `from: "4.0.0"` |
| AsyncHTTPClient | 1.36.x | Swift 6.0+ | `from: "1.24.0"` |
| swift-log | 1.15.x | Swift 5.8+ | `from: "1.6.0"` |
| swift-metrics | 2.11.x | Swift 5.8+ | `from: "2.5.0"` |
| swift-service-lifecycle | 2.12.x | Swift 6.1+ (2.12+) | `from: "2.0.0"` |
| grpc-swift-2 (repo: `grpc/grpc-swift-2`) | 2.4.x | Swift 6.0+ | `from: "2.0.0"` |

**Vapor 5** is in early alpha (`5.0.0-alpha.x`) — a ground-up rewrite on structured concurrency with macro-based type-safe routing. Vapor 4 remains the supported production line; do not suggest Vapor 5 for real projects yet.

Upstream sources for the files in this directory (Vapor docs, swift.org server documentation, package READMEs) are listed under **Upstream Sources** in `SKILL.md`.
