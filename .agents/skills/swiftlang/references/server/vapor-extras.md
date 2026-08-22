# Vapor Add-on Packages

Reference for Vapor ecosystem packages beyond the core framework. Read this when integrating job queues, JWT, push notifications, templating, Redis, custom CLI commands, or the services/DI pattern.

## Table of Contents

1. [Queues (Job System)](#queues)
2. [JWT](#jwt)
3. [APNS (Push Notifications)](#apns)
4. [Leaf Templating](#leaf-templating)
5. [Redis](#redis)
6. [Custom Commands](#custom-commands)
7. [Services / Dependency Injection](#services--dependency-injection)

---

## Queues

Async job queue system. Requires a driver — Redis is the primary one (`vapor/queues-redis-driver`).

### Job Definition

```swift
struct EmailJob: AsyncJob {
    typealias Payload = Email  // must be Codable

    func dequeue(_ context: QueueContext, _ payload: Email) async throws {
        try await sendEmail(payload)
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Email) async throws {
        context.logger.error("Email failed: \(error)")
    }
}

// Register in configure.swift
app.queues.add(EmailJob())
```

### Dispatching Jobs

```swift
try await req.queue.dispatch(EmailJob.self,
    Email(to: "user@example.com", message: "Hello"),
    maxRetryCount: 3,
    delayUntil: Date().addingTimeInterval(60)  // delay 1 minute
)
```

### Named Queues

```swift
extension QueueName {
    static let emails = QueueName(string: "emails")
    static let serialEmails = QueueName(string: "serial-emails", workerCount: 1)
}
try await req.queues(.emails).dispatch(EmailJob.self, payload)
```

### Running Workers

```bash
swift run App queues                    # all queues
swift run App queues --queue emails     # specific queue
```

Or in-process: `try app.queues.startInProcessJobs(on: .default)`

### Scheduled Jobs

```swift
struct CleanupJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        // periodic cleanup
    }
}
app.queues.schedule(CleanupJob()).daily().at(.midnight)
app.queues.schedule(CleanupJob()).every(hours: 6)
```

### Testing

```swift
app.queues.use(.asyncTest)  // deterministic, no Redis needed
```

### Gotcha

Redis cluster: use hash tags to avoid CROSSSLOT errors:
```swift
app.queues.configuration.persistenceKey = "vapor-queues-{queues}"
```

---

## JWT

Package: `vapor/jwt` (5.0.0+). Built on JWTKit + SwiftCrypto.

### Key Management

Actor-based, thread-safe:

```swift
// HMAC
await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)

// ECDSA
await app.jwt.keys.add(ecdsa: ES256PublicKey(pem: pemString))

// EdDSA (recommended)
await app.jwt.keys.add(eddsa: EdDSA.PrivateKey(curve: .ed25519))

// RSA (legacy)
await app.jwt.keys.add(rsa: Insecure.RSA.PublicKey(pem: pem), digestAlgorithm: .sha256)

// Key rotation via kid
await app.jwt.keys.add(hmac: "key-v2", digestAlgorithm: .sha256, kid: "v2")
```

### Payload

```swift
struct MyPayload: JWTPayload {
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var isAdmin: Bool

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}
```

### Sign & Verify

```swift
// Sign
let token = try await req.jwt.sign(MyPayload(
    subject: "user-123",
    expiration: .init(value: Date().addingTimeInterval(3600)),
    isAdmin: false
))

// Verify from Bearer header automatically
let payload = try await req.jwt.verify(as: MyPayload.self)
```

### Built-in Claims

`SubjectClaim`, `ExpirationClaim`, `IssuedAtClaim`, `AudienceClaim`, `IssuerClaim`, `NotBeforeClaim`, `IDClaim`, `LocaleClaim`

### Third-Party Identity Providers

```swift
let apple = try await req.jwt.apple.verify()       // AppleIdentityToken
let google = try await req.jwt.google.verify()      // GoogleIdentityToken
let microsoft = try await req.jwt.microsoft.verify() // MicrosoftIdentityToken
```

### JWKS Support

```swift
try await app.jwt.keys.use(jwksJSON: json)
```

---

## APNS

Package: `vapor/apns` (4.0.0+). Built on APNSwift.

### Configuration (JWT-based, recommended)

```swift
let config = APNSClientConfiguration(
    authenticationMethod: .jwt(
        privateKey: try .loadFrom(string: p8Content),
        keyIdentifier: "KEY_ID",
        teamIdentifier: "TEAM_ID"
    ),
    environment: .development  // or .production
)
app.apns.containers.use(config,
    eventLoopGroupProvider: .shared(app.eventLoopGroup),
    responseDecoder: JSONDecoder(),
    requestEncoder: JSONEncoder(),
    as: .default
)
```

### Sending Notifications

```swift
try await req.apns.client.sendAlertNotification(
    APNSAlertNotification(
        alert: .init(title: .raw("Hello"), subtitle: .raw("New message")),
        expiration: .immediately,
        priority: .immediately,
        topic: "com.example.MyApp",
        payload: MyCustomPayload(userId: "123")
    ),
    deviceToken: deviceToken,
    deadline: .distantFuture
)
```

---

## Leaf Templating

Swift-inspired template syntax with `#` tags. Package: `vapor/leaf` (4.0.0+).

### Setup

```swift
app.views.use(.leaf)
```

### Rendering

```swift
// In route handler
return req.view.render("home", ["title": "Welcome", "items": items])
```

### Template Syntax

```html
<!-- Variables -->
<h1>#(title)</h1>

<!-- Conditionals -->
#if(showBanner):
    <div class="banner">Hello!</div>
#elseif(showAlt):
    <div>Alt content</div>
#else:
    <div>Default</div>
#endif

<!-- Loops -->
<ul>
#for(item in items):
    <li>#(item.name)</li>
#endfor
</ul>

<!-- Template inheritance -->
#extend("base"):
    #export("content"):
        <p>Page-specific content</p>
    #endexport
#endextend
```

### Built-in Helpers

`#count`, `#lowercased`, `#uppercased`, `#capitalized`, `#contains`, `#date`, `#unsafeHTML`, `#dumpContext`

**Security:** `#unsafeHTML` bypasses HTML escaping — XSS risk with user input.

---

## Redis

Package: `vapor/redis` (4.0.0+). Built on RediStack.

### Configuration

```swift
app.redis.configuration = try RedisConfiguration(hostname: "localhost")
```

### Commands

```swift
// Get/Set
try await app.redis.set("key", to: "value")
let value = try await app.redis.get("key", as: String.self)

// Raw commands
let res = try await app.redis.send(command: "PING", with: ["hello"])
```

### Pub/Sub

```swift
app.redis.subscribe(to: "channel_1", "channel_2",
    messageReceiver: { channel, message in
        print("Received on \(channel): \(message)")
    },
    onUnsubscribe: { channel, count in
        print("Unsubscribed from \(channel)")
    }
)
```

### Gotcha

`SELECT` (database selection) is not maintained by the connection pool. Avoid manual `SELECT` commands.

---

## Custom Commands

Default commands: `serve`, `routes`, `migrate`.

```swift
struct SeedCommand: AsyncCommand {
    struct Signature: CommandSignature {
        @Argument(name: "count") var count: Int
        @Option(name: "env", short: "e") var environment: String?
        @Flag(name: "verbose") var verbose: Bool
    }

    var help: String { "Seed the database with sample data" }

    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("Seeding \(signature.count) records...")
    }
}

// Register
app.asyncCommands.use(SeedCommand(), as: "seed")
```

```bash
swift run App seed 100 --env production --verbose
```

---

## Services / Dependency Injection

### Read-Only Service (Computed Property)

```swift
extension Request {
    var paymentService: PaymentService {
        PaymentService(client: self.client, logger: self.logger)
    }
}
```

### Writable Service (Storage Pattern)

```swift
struct MyConfigKey: StorageKey {
    typealias Value = MyConfig
}

extension Application {
    var myConfig: MyConfig? {
        get { storage[MyConfigKey.self] }
        set { storage[MyConfigKey.self] = newValue }
    }
}
```

### Lifecycle Hooks

```swift
struct DatabaseSeeder: LifecycleHandler {
    func willBoot(_ app: Application) throws { /* before boot */ }
    func didBoot(_ app: Application) throws { /* after boot */ }
    func shutdown(_ app: Application) { /* cleanup */ }
}
app.lifecycle.use(DatabaseSeeder())
```

### Thread-Safe Locking

```swift
struct CacheKey: LockKey {}
app.locks.lock(for: CacheKey.self).withLock { /* exclusive access */ }
```
