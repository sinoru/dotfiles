# Vapor Detailed Patterns

Reference for Vapor-specific APIs and patterns. Read this when writing or modifying Vapor application code.

## Table of Contents

1. [Routing](#routing)
2. [Controllers](#controllers)
3. [Middleware](#middleware)
4. [Content System](#content-system)
5. [Validation](#validation)
6. [Error Handling](#error-handling)
7. [Environment Configuration](#environment-configuration)
8. [HTTP Client](#http-client)
9. [WebSockets](#websockets)
10. [Sessions](#sessions)
11. [Server Configuration](#server-configuration)
12. [Fluent ORM](#fluent-orm)
13. [Migrations](#migrations)
14. [Authentication](#authentication)
15. [Testing](#testing)
16. [Docker Deployment](#docker-deployment)

---

## Routing

### Basic Registration

```swift
app.get("foo", "bar") { req async throws -> String in "Hello" }
app.post("users") { req async throws -> User in ... }
app.on(.OPTIONS, "foo", "bar") { req async throws -> Response in ... }
```

### Path Components

Four types of path components:

| Type | Syntax | Behavior |
|------|--------|----------|
| Constant | `"foo"` | Exact string match |
| Parameter | `":name"` | Dynamic capture, access via `req.parameters.get("name")` |
| Anything | `"*"` | Matches one component, value discarded |
| Catchall | `"**"` | Matches one or more, access via `req.parameters.getCatchall()` |

### Typed Parameter Extraction

```swift
// Returns optional — always guard
guard let id = req.parameters.get("id", as: UUID.self) else {
    throw Abort(.badRequest)
}
```

### Route Groups

```swift
// Path grouping
let users = app.grouped("users")
users.get { req in ... }          // GET /users
users.get(":id") { req in ... }   // GET /users/:id

// Middleware grouping
app.group(RateLimitMiddleware()) { rateLimited in
    rateLimited.get("slow-thing") { req in ... }
}

// Nested grouping
users.group(":id") { user in
    user.get(use: show)
    user.put(use: update)
    user.delete(use: delete)
}
```

### Body Collection

Default maximum is 16KB. Configure per-route for larger payloads:

```swift
// Collect up to 1MB
app.on(.POST, "upload", body: .collect(maxSize: "1mb")) { req in ... }

// Stream without collecting (for very large uploads)
app.on(.POST, "upload", body: .stream) { req in ... }
```

### Redirects

```swift
req.redirect(to: "/new-path", redirectType: .permanent)  // 301
req.redirect(to: "/new-path", redirectType: .normal)      // 303
req.redirect(to: "/new-path", redirectType: .temporary)   // 307
```

### Misc

- Case-insensitive routing: `app.routes.caseInsensitive = true`

---

## Controllers

Controllers conform to `RouteCollection` and implement `boot(routes:)`:

```swift
struct TodosController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("todos")
        todos.get(use: index)
        todos.post(use: create)

        todos.group(":id") { todo in
            todo.get(use: show)
            todo.put(use: update)
            todo.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> [Todo] {
        try await Todo.query(on: req.db).all()
    }

    func create(req: Request) async throws -> Todo {
        let todo = try req.content.decode(Todo.self)
        try await todo.save(on: req.db)
        return todo
    }

    func show(req: Request) async throws -> Todo {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return todo
    }

    func update(req: Request) async throws -> Todo {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        let input = try req.content.decode(Todo.self)
        todo.title = input.title
        try await todo.save(on: req.db)
        return todo
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let todo = try await Todo.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await todo.delete(on: req.db)
        return .noContent
    }
}
```

Register in `routes.swift` or `configure.swift`:

```swift
try app.register(collection: TodosController())
```

Handler methods must accept `Request` and return something conforming to `ResponseEncodable`. Can be `async throws`.

---

## Middleware

### AsyncMiddleware Protocol

```swift
struct TimingMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let start = Date()
        let response = try await next.respond(to: request)
        let elapsed = Date().timeIntervalSince(start)
        response.headers.add(name: "X-Response-Time", value: "\(elapsed)s")
        return response
    }
}
```

### Registration

```swift
// Global
app.middleware.use(TimingMiddleware())

// At beginning (before ErrorMiddleware)
app.middleware.use(CORSMiddleware(configuration: corsConfig), at: .beginning)

// Per route group
let protected = app.grouped(AuthMiddleware())
```

### Built-in Middleware

**FileMiddleware** — serves static files from `Public/`:

```swift
app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
```

**CORSMiddleware** — must be registered at `.beginning`:

```swift
let corsConfig = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
    allowedHeaders: [.accept, .authorization, .contentType, .origin,
                     .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
app.middleware.use(CORSMiddleware(configuration: corsConfig), at: .beginning)
```

**ErrorMiddleware** — default error handling, implicitly registered.

**TracingMiddleware** (4.109.0+) — distributed tracing with OpenTelemetry-standard attributes:

```swift
app.middleware.use(TracingMiddleware())  // place before other middleware
```

---

## Content System

`Content` protocol extends `Codable` with HTTP encoding/decoding. Supports JSON, multipart/form-data, URL-encoded form, plaintext, HTML.

```swift
// Decode request body
let input = try req.content.decode(CreateUser.self)

// Decode query parameters
let filter = try req.query.decode(FilterParams.self)
// Or single query param
let name: String? = req.query["name"]
```

**Lifecycle hooks** for pre/post processing:

```swift
struct UserInput: Content {
    var name: String
    mutating func afterDecode() throws { name = name.trimmingCharacters(in: .whitespaces) }
    func beforeEncode() throws { /* validate before sending */ }
}
```

**Custom JSON encoder globally:**

```swift
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
ContentConfiguration.global.use(encoder: encoder, for: .json)
```

**Custom ResponseEncodable:**

```swift
struct HTMLResponse: AsyncResponseEncodable {
    let html: String
    func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        return .init(status: .ok, headers: headers, body: .init(string: html))
    }
}
```

---

## Validation

Validates BEFORE content decoding. Reports all failures at once (unlike Codable which stops at first).

```swift
extension CreateUser: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("username", as: String.self, is: .count(3...) && .alphanumeric)
        validations.add("age", as: Int.self, is: .range(13...))
        validations.add("email", as: String.self, is: .email)
        validations.add("favoriteColor", as: String?.self,
                        is: .nil || .in("red", "blue", "green"), required: false)
    }
}

// In route handler
try CreateUser.validate(content: req)
let user = try req.content.decode(CreateUser.self)
```

**Built-in validators:** `.ascii`, `.alphanumeric`, `.characterSet(_:)`, `.count(_:)`, `.email`, `.empty`, `.in(_:)`, `.nil`, `.range(_:)`, `.url`

**Operators:** `!` (invert), `&&` (both), `||` (either)

**Custom validator** (4.111.0+):

```swift
validations.add("field", as: String.self,
    is: .custom("must start with A") { $0.hasPrefix("A") })
```

---

## Error Handling

```swift
// Quick throw with status
throw Abort(.notFound)
throw Abort(.unauthorized, reason: "Invalid credentials")
```

**Custom errors** — conform to `AbortError`:

```swift
enum MyError: AbortError {
    case userNotFound
    var status: HTTPResponseStatus { .notFound }
    var reason: String { "User not found" }
}
```

**DebuggableError** adds `identifier`, `source`, `possibleCauses`, `suggestedFixes` — shown in debug builds, stripped in release.

---

## Environment Configuration

**Built-in:** `development` (default), `production`, `testing`

```bash
swift run App serve --env production   # or -e prod
```

**Environment variables:**

```swift
let dbHost = Environment.get("DATABASE_HOST") ?? "localhost"
let foo = Environment.process.FOO  // dynamic member lookup
```

**.env files:** Auto-loaded from CWD. `.env.development` overrides `.env` in dev. Process env vars take precedence. Never commit secrets.

**Custom environment:**

```swift
extension Environment {
    static var staging: Environment { .custom(name: "staging") }
}
```

---

## HTTP Client

Access via `req.client` in route handlers (preferred) or `app.client` at boot time only.

```swift
// GET
let response = try await req.client.get("https://api.example.com/data")

// POST with JSON body and auth
let response = try await req.client.post("https://api.example.com/users") { req in
    try req.content.encode(["name": "Alice"])
    req.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
}

// Decode response
let data = try response.content.decode(MyResponse.self)
```

**Configuration** (must be set before first use):

```swift
app.http.client.configuration.redirectConfiguration = .disallow
```

---

## WebSockets

**Server-side route:**

```swift
app.webSocket("echo") { req, ws in
    ws.onText { ws, text in
        ws.send(text)  // echo back
    }
    ws.onClose.whenComplete { _ in print("Disconnected") }
}
```

**Client connection:**

```swift
WebSocket.connect(to: "ws://localhost:8080/echo", on: app.eventLoopGroup) { ws in
    ws.send("Hello")
    ws.onText { ws, text in print("Received: \(text)") }
}
```

Supports middleware, route grouping, ping/pong keep-alive, and `try await ws.close()`.

---

## Sessions

Requires middleware setup:

```swift
app.middleware.use(app.sessions.middleware)
```

**Drivers:** `.memory` (default, testing only), `.fluent` (DB-backed, requires `SessionRecord.migration`), `.redis`

**Usage:**

```swift
req.session.data["name"] = "value"   // set (auto-creates session cookie)
let val = req.session.data["name"]   // read
req.session.destroy()                // destroy
```

**Gotcha:** Configure the session driver BEFORE adding the middleware.

---

## Server Configuration

Key settings via `app.http.server.configuration`:

| Setting | Default | Notes |
|---------|---------|-------|
| `hostname` | `127.0.0.1` | CLI: `-H` |
| `port` | `8080` | CLI: `-p`, combined: `-b 0.0.0.0:80` |
| `backlog` | `256` | Max pending connections |
| `responseCompression` | `.disabled` | `.enabled(initialByteBufferCapacity: 1024)` |
| `requestDecompression` | `.disabled` | `.enabled(limit: .ratio(10))` |
| `supportVersions` | HTTP/1+2 with TLS | `[.two]` for HTTP/2 only |
| `tlsConfiguration` | none | See TLS setup below |

**TLS:**

```swift
import NIOSSL
app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
    certificateChain: try NIOSSLCertificate.fromPEMFile("/path/cert.pem").map { .certificate($0) },
    privateKey: .privateKey(try NIOSSLPrivateKey(file: "/path/key.pem", format: .pem))
)
```

---

## Fluent ORM

### Supported Drivers

| Database | Package | Product | Depend With |
|----------|---------|---------|-------------|
| PostgreSQL (recommended) | `fluent-postgres-driver` | `FluentPostgresDriver` | `from: "2.0.0"` |
| SQLite | `fluent-sqlite-driver` | `FluentSQLiteDriver` | `from: "4.0.0"` |
| MySQL/MariaDB | `fluent-mysql-driver` | `FluentMySQLDriver` | `from: "4.0.0"` |
| MongoDB | `fluent-mongo-driver` | `FluentMongoDriver` | `from: "1.0.0"` |

### Database Configuration

```swift
// In configure.swift
import FluentPostgresDriver

app.databases.use(.postgres(configuration: .init(
    hostname: Environment.get("DATABASE_HOST") ?? "localhost",
    username: Environment.get("DATABASE_USERNAME") ?? "vapor",
    password: Environment.get("DATABASE_PASSWORD") ?? "vapor",
    database: Environment.get("DATABASE_NAME") ?? "vapor",
    tls: .disable
)), as: .psql)
```

### Model Definition

```swift
final class Galaxy: Model, Content {
    static let schema = "galaxies"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @OptionalField(key: "description")
    var description: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    // Required empty init for Fluent
    init() { }

    init(id: UUID? = nil, name: String, description: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
    }
}
```

### Property Wrappers

| Wrapper | Usage |
|---------|-------|
| `@ID(key: .id)` | Primary key (UUID) |
| `@Field(key:)` | Required stored property |
| `@OptionalField(key:)` | Optional stored property |
| `@Parent(key:)` | Belongs-to relation (stores foreign key) |
| `@Children(for:)` | Has-many relation (inverse of @Parent) |
| `@Siblings(through:from:to:)` | Many-to-many via pivot |
| `@Timestamp(key:on:)` | Auto-managed timestamp (.create, .update, .delete) |
| `@Enum(key:)` | Database enum type |

### Relations

```swift
// Child model — stores the foreign key
final class Star: Model, Content {
    static let schema = "stars"

    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String

    @Parent(key: "galaxy_id")
    var galaxy: Galaxy

    init() { }
    init(id: UUID? = nil, name: String, galaxyID: UUID) {
        self.id = id
        self.name = name
        self.$galaxy.id = galaxyID  // Note: $galaxy.id, not galaxy
    }
}

// Parent model — inverse relation
final class Galaxy: Model, Content {
    // ... other fields ...

    @Children(for: \.$galaxy)
    var stars: [Star]
}
```

### Querying

```swift
// All records
let galaxies = try await Galaxy.query(on: req.db).all()

// Filtered
let big = try await Galaxy.query(on: req.db)
    .filter(\.$name == "Milky Way")
    .first()

// With eager loading
let galaxies = try await Galaxy.query(on: req.db)
    .with(\.$stars)
    .all()

// Find by ID
let galaxy = try await Galaxy.find(id, on: req.db)

// Pagination
let page = try await Galaxy.query(on: req.db)
    .paginate(for: req)
```

---

## Migrations

### AsyncMigration Protocol

```swift
struct CreateGalaxy: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("galaxies")
            .id()
            .field("name", .string, .required)
            .field("description", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "name")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("galaxies").delete()
    }
}

struct CreateStar: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("stars")
            .id()
            .field("name", .string, .required)
            .field("galaxy_id", .uuid, .required, .references("galaxies", "id"))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("stars").delete()
    }
}
```

### Registration

Order matters — parent table migrations before child tables:

```swift
// In configure.swift
app.migrations.add(CreateGalaxy())
app.migrations.add(CreateStar())  // After CreateGalaxy — depends on galaxies table
```

### Running Migrations

```bash
# CLI
swift run App migrate
swift run App migrate --revert

# Auto-migrate on boot (development only)
swift run App serve --auto-migrate
```

```swift
// Programmatic
try await app.autoMigrate()
try await app.autoRevert()
```

---

## Authentication

### Basic Auth (Username/Password Login)

```swift
extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

// Route
let passwordProtected = app.grouped(User.authenticator())
passwordProtected.post("login") { req async throws -> UserToken in
    let user = try req.auth.require(User.self)
    let token = try user.generateToken()
    try await token.save(on: req.db)
    return token
}
```

### Bearer Token Auth (API Endpoints)

```swift
extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        // Add expiry logic here
        true
    }
}

let tokenProtected = app.grouped(UserToken.authenticator())
tokenProtected.get("me") { req async throws -> User in
    try req.auth.require(User.self)
}
```

### Guard Middleware

Throws 401 if no user is authenticated (use after authenticator):

```swift
let protected = app.grouped(
    UserToken.authenticator(),
    User.guardMiddleware()
)
```

### Session Auth (Web Apps)

```swift
app.middleware.use(app.sessions.middleware)
app.middleware.use(User.sessionAuthenticator())
```

### Composable Auth

Multiple authenticators can be chained — first successful one wins:

```swift
let flexible = app.grouped(
    User.authenticator(),        // Try Basic auth
    UserToken.authenticator(),   // Try Bearer token
    User.guardMiddleware()       // Require at least one to succeed
)
```

---

## Testing

### XCTVapor (XCTest)

```swift
import XCTVapor

final class AppTests: XCTestCase {
    func testHelloWorld() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        try routes(app)

        try await app.test(.GET, "hello") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "Hello, world!")
        }
    }
}
```

### VaporTesting (Swift Testing — Recommended)

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

**Request with body:**

```swift
try await app.testing().test(.POST, "todos", beforeRequest: { req in
    try req.content.encode(CreateTodoDTO(title: "Test"))
}, afterResponse: { res async throws in
    #expect(res.status == .ok)
    let todo = try res.content.decode(Todo.self)
    #expect(todo.title == "Test")
})
```

**Testing methods:** `.inMemory` (default, fast) vs `.running(port:)` (live HTTP server for integration tests)

**Database testing pattern:**

```swift
try await withApp(configure: configure) { app in
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    }
    try await app.autoMigrate()
    defer { try? await app.autoRevert() }
    // ... tests ...
}
```

### Logging in Tests

Access via `req.logger` (includes request UUID) or `app.logger`. Change level:

```bash
swift run App serve --log debug
# or
export LOG_LEVEL=debug
```

### Files API

Built on NIO's `NonBlockingFileIO`. All operations are non-blocking.

```swift
// Stream file as HTTP response (auto-sets ETag, Content-Type)
return req.fileio.streamFile(at: "/path/to/file")

// Read file into memory (caution: loads entire file)
let buffer = try await req.fileio.collectFile(at: "/path")

// Read in chunks (preferred for large files)
try await req.fileio.readFile(at: "/path") { chunk in
    process(chunk)
}

// Write
req.fileio.writeFile(ByteBuffer(string: "Hello"), at: "/path")
```

---

## Docker Deployment

### Key Points

- `vapor new` generates a multi-stage Dockerfile (build + slim runtime)
- Default port: **8080**
- Use environment variables for configuration in production:
  - `DATABASE_HOST`, `DATABASE_NAME`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`
  - `LOG_LEVEL`

### Commands

```bash
docker compose build
docker compose up app
docker compose run migrate
```

### Production Considerations

- Use `.env` or secrets management for credentials — never hardcode in production
- Multi-stage builds keep the runtime image small (slim Ubuntu base)
- Set `LOG_LEVEL=notice` or `LOG_LEVEL=info` for production logging
- Consider health check endpoints for orchestrator probes
