# Swift Server Ecosystem

Reference for the broader Swift server ecosystem libraries. Read this when integrating observability, managing service lifecycle, making HTTP requests, or using gRPC / OpenAPI.

## Table of Contents

1. [swift-log](#swift-log)
2. [swift-metrics](#swift-metrics)
3. [swift-distributed-tracing](#swift-distributed-tracing)
4. [swift-service-lifecycle](#swift-service-lifecycle)
5. [AsyncHTTPClient](#asynchttpclient)
6. [gRPC Swift 2](#grpc-swift-2)
7. [Swift OpenAPI Generator](#swift-openapi-generator)

---

## swift-log

Unified logging API for the Swift server ecosystem. Provides `Logger` type with pluggable backends.

**Dependency**: `from: "1.6.0"` (current: 1.11.x)

### Usage

```swift
import Logging

let logger = Logger(label: "com.example.MyApp")

logger.info("Server started", metadata: ["port": "\(port)"])
logger.error("Request failed", metadata: ["error": "\(error)"])
logger.debug("Processing request", metadata: ["request-id": "\(requestID)"])
```

### Log Levels

`trace` < `debug` < `info` < `notice` < `warning` < `error` < `critical`

### Structured Metadata

```swift
var logger = Logger(label: "com.example.MyApp")
logger[metadataKey: "request-id"] = "\(UUID())"
// All subsequent log calls include the request-id
logger.info("Processing")  // includes request-id in output
```

### Key Rules

- **Libraries accept a logger parameter** — never create your own bootstrap. Let the application choose the backend.
- **Applications bootstrap the backend once** at startup:
  ```swift
  LoggingSystem.bootstrap(MyLogHandler.init)
  ```
- **Vapor provides its own logger** — access via `req.logger` or `app.logger`. No manual bootstrap needed in Vapor apps.

---

## swift-metrics

Unified metrics API with pluggable backends.

**Dependency**: `from: "2.5.0"` (current: 2.8.x)

### Metric Types

| Type | Usage |
|------|-------|
| `Counter` | Monotonically increasing value (requests served, errors) |
| `FloatingPointCounter` | Counter with floating point increments |
| `Gauge` | Point-in-time value (current connections, memory usage) |
| `Meter` | Rate of events |
| `Recorder` | Distribution of values (response sizes) |
| `Timer` | Duration measurements (request latency) |

### Usage

```swift
import Metrics

// Create ONCE at init — reuse across requests
let requestCounter = Counter(label: "http_requests_total",
                             dimensions: [("method", "GET")])
let requestDuration = Timer(label: "http_request_duration_seconds")

// In request handler
requestCounter.increment()
requestDuration.recordNanoseconds(elapsed)
```

### Critical Rule

**Create metric objects once at initialization. Reuse across requests.** Never create metrics with per-request dimensions — this causes unbounded cardinality and memory growth.

```swift
// WRONG — creates new metric per request
Counter(label: "requests", dimensions: [("user_id", userID)]).increment()

// RIGHT — use fixed dimensions, filter in your metrics backend
Counter(label: "requests", dimensions: [("endpoint", "/users")]).increment()
```

### Backend Bootstrap

```swift
// Application startup — once
MetricsSystem.bootstrap(PrometheusMetricsFactory())
```

Compatible backends: SwiftPrometheus, StatsD Client, OpenTelemetry Swift.

---

## swift-distributed-tracing

Distributed tracing API using `ServiceContext` for context propagation.

**Dependency**: `from: "1.0.0"` (current: 1.4.x)

### Integration

Built-in tracing support in:
- AsyncHTTPClient 1.29.0+
- Vapor (built-in)
- Hummingbird
- gRPC Swift 2 (via extras middleware)

### Primary Backend

**Swift OTel** (`swift-otel/swift-otel`) — exports to OpenTelemetry Collector, compatible with Zipkin, X-Ray, Jaeger.

### Context Propagation

Uses `ServiceContext` from `swift-service-context` (zero dependencies) for propagating trace context across async boundaries.

---

## swift-service-lifecycle

Manages graceful startup and shutdown of server applications.

**Dependency**: `from: "2.0.0"` (current: 2.11.x)

### Service Protocol

```swift
import ServiceLifecycle

struct MyService: Service {
    func run() async throws {
        // Service logic here
        // Runs until cancelled or graceful shutdown is triggered
        try await gracefulShutdown()
    }
}
```

### ServiceGroup

Orchestrates multiple services with graceful shutdown:

```swift
import ServiceLifecycle

let serviceGroup = ServiceGroup(
    services: [httpServer, backgroundWorker, metricsReporter],
    gracefulShutdownSignals: [.sigterm, .sigint],
    logger: logger
)
try await serviceGroup.run()
```

### Key Concepts

- Each service runs in its own child task (structured concurrency)
- `ServiceGroup` listens for OS signals and triggers graceful shutdown
- Services should check for cancellation or call `gracefulShutdown()` to participate in graceful shutdown
- Both Vapor and Hummingbird integrate with service-lifecycle

---

## AsyncHTTPClient

Production HTTP client for server-side Swift, built on SwiftNIO.

**Dependency**: `from: "1.24.0"` (current: 1.33.x)

### Usage

```swift
import AsyncHTTPClient

// Shared singleton (recommended for most cases)
let response = try await HTTPClient.shared.execute(
    HTTPClientRequest(url: "https://api.example.com/data"),
    timeout: .seconds(30)
)
let body = try await response.body.collect(upTo: 1024 * 1024)  // 1MB max

// Custom client (for specific configuration)
let client = HTTPClient(eventLoopGroupProvider: .singleton)
defer { try? client.syncShutdown() }
```

### Features

- HTTP/2 over HTTPS (automatic)
- Streaming response bodies via `AsyncSequence`
- Connection pooling
- Redirect following
- Distributed tracing support (1.29.0+)
- TLS via swift-nio-ssl

### In Vapor

Vapor provides `req.client` which wraps AsyncHTTPClient:

```swift
let response = try await req.client.get("https://api.example.com/data")
let data = try response.content.decode(MyResponse.self)
```

---

## gRPC Swift 2

Swift gRPC implementation, rewritten for Swift 6 concurrency.

### Multi-Repository Structure

| Package | Purpose | Depend With |
|---------|---------|-------------|
| `grpc-swift` | `GRPCCore` (transport-agnostic) | `from: "2.0.0"` |
| `grpc-swift-nio-transport` | HTTP/2 transport on SwiftNIO | `from: "1.0.0"` |
| `grpc-swift-protobuf` | SwiftProtobuf serialization | `from: "1.0.0"` |
| `grpc-swift-extras` | Tracing middleware, etc. | `from: "1.0.0"` |

**Requirements**: Swift 6.0+, macOS 15.0+ (for NIO transport)

### Architecture

- Transport-agnostic core — `GRPCCore` defines protocols, any transport can implement them
- Full structured concurrency — no EventLoopFuture APIs
- Interceptor/middleware pattern via `grpc-swift-extras`

---

## Swift OpenAPI Generator

Generates client and server code from OpenAPI 3.0/3.1/3.2 documents.

**Package**: `apple/swift-openapi-generator` (current: 1.11.x)

### Key Features

- **Build-time code generation** via SwiftPM plugin — always in sync, no committed generated code
- Transport abstraction: client transports (URLSession, AsyncHTTPClient), server transports (Vapor, Hummingbird)
- Streaming request/response bodies
- JSON, multipart, form-encoded, base64, plain text content types
- Client and server middleware abstractions

### Setup

1. Add the generator plugin and runtime to `Package.swift`
2. Place your `openapi.yaml` in the target's source directory
3. Create `openapi-generator-config.yaml` specifying what to generate (types, client, server)
4. Build — generated code is produced at build time

### Vapor Integration

Use `swift-openapi-vapor` as the server transport:

```swift
// Package.swift
.package(url: "https://github.com/swift-server/swift-openapi-vapor.git", from: "1.0.0")
```

This allows implementing OpenAPI-defined endpoints as a Vapor `RouteCollection`.

### AsyncHTTPClient Integration

Use `swift-openapi-async-http-client` as the client transport for server-side API clients.
