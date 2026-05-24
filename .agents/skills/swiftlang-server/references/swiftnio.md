# SwiftNIO Architecture & Patterns

Reference for SwiftNIO internals and low-level server patterns. Read this when working at the NIO layer, implementing custom channel handlers, or debugging concurrency/performance issues.

## Table of Contents

1. [Core Building Blocks](#core-building-blocks)
2. [Module Organization](#module-organization)
3. [Channel Pipeline](#channel-pipeline)
4. [Bootstrap](#bootstrap)
5. [ByteBuffer](#bytebuffer)
6. [Swift Concurrency Integration](#swift-concurrency-integration)
7. [Testing with NIOEmbedded](#testing-with-nioembedded)

---

## Core Building Blocks

SwiftNIO has 8 fundamental types, all from NIOCore:

### 1. EventLoopGroup

Distributes work across EventLoops. Production implementation: `MultiThreadedEventLoopGroup` (from NIOPosix). Creates N threads, each with one EventLoop.

```swift
let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
defer { try! group.syncShutdownGracefully() }
```

### 2. EventLoop

The fundamental I/O primitive. One per thread. Waits for events via kqueue (macOS) or epoll (Linux), fires callbacks. Runs for the application lifetime. All NIO work is dispatched through EventLoops.

### 3. Channel

Owns a file descriptor, manages its lifetime. Implementations:
- `ServerSocketChannel` — accepts connections
- `SocketChannel` — TCP connections
- `DatagramChannel` — UDP
- `EmbeddedChannel` — testing (no real I/O)

### 4. ChannelHandler

Processes events in a pipeline. Two directions:
- **Inbound** (`ChannelInboundHandler`) — processes reads and remote events
- **Outbound** (`ChannelOutboundHandler`) — processes writes and connection attempts

Designed to be small, reusable, and composable.

### 5. ChannelPipeline

Ordered sequence of ChannelHandlers. Thread-safe. All code runs on the owning EventLoop's thread.

### 6. Bootstrap

High-level channel creation:
- `ServerBootstrap` — listening for connections
- `ClientBootstrap` — TCP client (supports Happy Eyeballs for dual-stack)
- `DatagramBootstrap` — UDP

### 7. ByteBuffer

Copy-on-write byte buffer. The primary data shuttle in NIO. Has safe and unsafe access modes.

### 8. EventLoopFuture / EventLoopPromise

Async result containers. Callbacks are always dispatched on the creating EventLoop's thread.

---

## Module Organization

| Module | Purpose | When to Import |
|--------|---------|----------------|
| `NIO` | Umbrella — reexports NIOCore + NIOEmbedded + NIOPosix | Quick prototyping |
| `NIOCore` | Core abstractions (EventLoop, Channel, ByteBuffer, etc.) | Library code — depend on this, not NIO |
| `NIOPosix` | Production EventLoopGroup using kqueue/epoll | Application entry point |
| `NIOEmbedded` | EmbeddedChannel + EmbeddedEventLoop | Tests |
| `NIOHTTP1` | HTTP/1.1 codec | HTTP protocol handling |
| `NIOWebSocket` | WebSocket codec | WebSocket handling |
| `NIOFoundationCompat` | Foundation `Data` bridging | When bridging with Foundation types |
| `NIOConcurrencyHelpers` | Locks, atomics | Low-level synchronization |
| `NIOTestUtils` | Test helpers | Tests |
| `NIOTLS` | TLS abstraction layer | TLS implementations |

**Best practice for libraries**: Depend on `NIOCore`, not `NIO`. Only application targets should import `NIOPosix` directly.

### Related Repositories

| Repository | Purpose | Depend With |
|------------|---------|-------------|
| swift-nio-ssl | TLS via BoringSSL | `from: "2.0.0"` |
| swift-nio-http2 | HTTP/2 protocol | `from: "1.0.0"` |
| swift-nio-extras | Additional handlers (line-based frame decoder, etc.) | `from: "1.0.0"` |
| swift-nio-transport-services | Apple Network.framework transport | `from: "1.0.0"` |

---

## Channel Pipeline

The central design pattern. Data flows through a chain of handlers:

```
Inbound:   Head → HandlerA → HandlerB → HandlerC → Tail
Outbound:  Head ← HandlerA ← HandlerB ← HandlerC ← Tail
```

- Inbound events flow front-to-back (from network toward application)
- Outbound events flow back-to-front (from application toward network)
- Each handler can transform, split, coalesce, or delay events
- `ChannelHandlerContext` tracks position and enables forwarding

### Writing a ChannelHandler

```swift
final class EchoHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // Echo the data back
        context.write(data, promise: nil)
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}
```

### Codec Pattern

Separate encoding/decoding into a codec handler that sits before business logic:

```swift
// Decode: ByteBuffer → MyMessage (inbound)
// Encode: MyMessage → ByteBuffer (outbound)
final class MyMessageCodec: ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = MyMessage
    typealias OutboundIn = MyMessage
    typealias OutboundOut = ByteBuffer
    // ...
}
```

---

## Bootstrap

### Server

```swift
let server = try await ServerBootstrap(group: group)
    .serverChannelOption(.backlog, value: 256)
    .childChannelInitializer { channel in
        channel.pipeline.addHandlers([
            BackPressureHandler(),
            MyBusinessHandler()
        ])
    }
    .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
    .childChannelOption(.maxMessagesPerRead, value: 16)
    .bind(host: "0.0.0.0", port: 8080)
    .get()
```

### Client

```swift
let client = try await ClientBootstrap(group: group)
    .channelInitializer { channel in
        channel.pipeline.addHandler(MyClientHandler())
    }
    .connect(host: "example.com", port: 80)
    .get()
```

---

## ByteBuffer

```swift
var buffer = ByteBufferAllocator().buffer(capacity: 256)

// Writing
buffer.writeString("Hello")
buffer.writeInteger(42, as: UInt32.self)
buffer.writeBytes([0x01, 0x02, 0x03])

// Reading (moves reader index)
let str = buffer.readString(length: 5)
let num = buffer.readInteger(as: UInt32.self)

// Peeking (does not move reader index)
let peek = buffer.getString(at: 0, length: 5)

// Slicing
let slice = buffer.readSlice(length: 10)  // Shares storage (CoW)
```

---

## Swift Concurrency Integration

### EventLoopFuture ↔ async/await

```swift
// Future → async (primary bridging pattern)
let result = try await someFuture.get()
// Warning: does NOT respect structured concurrency cancellation

// async → Future
let promise = eventLoop.makePromise(of: String.self)
promise.completeWithTask {
    try await someAsyncFunction()
}
let future = promise.futureResult
```

### NIOAsyncChannel

The recommended async-first Channel API for new code. Wraps a Channel and provides AsyncSequence-based reading and writer-based writing.

```swift
let channel = try NIOAsyncChannel<ByteBuffer, ByteBuffer>(
    wrappingChannelSynchronously: rawChannel
)

// Primary usage pattern — closure-based, ensures proper cleanup
try await channel.executeThenClose { inbound, outbound in
    for try await buffer in inbound {
        // Process inbound data
        try await outbound.write(processedBuffer)
    }
}
```

**Key details:**
- `Inbound` and `Outbound` generic parameters must be `Sendable`
- `executeThenClose` provides inbound stream and outbound writer, then closes automatically
- Back-pressure via `NIOAsyncSequenceProducerBackPressureStrategies.HighLowWatermark`
- Actor isolation overloads use `#isolation` and `sending` return type (Swift 6)

**Deprecated APIs:**
| Deprecated | Replacement |
|-----------|-------------|
| `.inbound` property | Use `executeThenClose` closure parameter |
| `.outbound` property | Use `executeThenClose` closure parameter |
| `init(synchronouslyWrapping:)` | `init(wrappingChannelSynchronously:)` |

### EventLoop as SerialExecutor

Available on macOS 14+ / iOS 17+. Allows actors to use an EventLoop as their executor:

```swift
// NIOSerialEventLoopExecutor protocol enables this
// Actors can run on a specific EventLoop, bridging structured concurrency with NIO
```

### NIOLoopBound

Safely binds a non-Sendable value to a specific EventLoop:

```swift
let bound = NIOLoopBound(nonSendableValue, eventLoop: eventLoop)
// Safe to transfer across concurrency domains
// Must only access on the bound EventLoop
```

### Key Rules

1. **Never call `.wait()` on an EventLoop thread** — deadlock guaranteed
2. **`.get()` does not support cancellation** — the underlying operation continues even if the Task is cancelled
3. **Libraries should depend on NIOCore** — let the application choose the EventLoopGroup implementation
4. **New code should prefer async/await** — use NIOAsyncChannel for channel-level integration

---

## Testing with NIOEmbedded

`EmbeddedChannel` lets you unit test ChannelHandlers without real I/O:

```swift
import NIOEmbedded

let channel = EmbeddedChannel()
try channel.pipeline.addHandler(MyHandler()).wait()  // .wait() is OK here — not a real EventLoop

// Write inbound data
var buffer = channel.allocator.buffer(capacity: 16)
buffer.writeString("test input")
try channel.writeInbound(buffer)

// Read the handler's output
let output: ByteBuffer = try channel.readOutbound()!
XCTAssertEqual(output.getString(at: 0, length: output.readableBytes), "expected output")

// Verify no errors
XCTAssertNoThrow(try channel.finish())
```

`EmbeddedEventLoop` provides a controllable EventLoop for testing time-dependent behavior:

```swift
let loop = EmbeddedEventLoop()
// Schedule work, then advance time manually
loop.advanceTime(by: .seconds(5))
```
