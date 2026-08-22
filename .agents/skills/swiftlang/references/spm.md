# Swift Package Manager

Based on the official SwiftPM documentation (docs.swift.org/swiftpm). For server-project-specific patterns (the Vapor Package.swift template, folder layout, etc.), see `references/server/overview.md`.

## Table of Contents

1. [Package.swift Manifest](#packageswift-manifest)
2. [Dependencies](#dependencies)
3. [Resolution & Package.resolved](#resolution--packageresolved)
4. [Resources](#resources)
5. [Build Settings](#build-settings)
6. [C/C++/ObjC Targets](#ccobjc-targets)
7. [Module Aliasing](#module-aliasing)
8. [Plugins](#plugins)
9. [Version-Specific Packaging](#version-specific-packaging)
10. [Security](#security)
11. [Swift Build (6.3 Preview)](#swift-build-63-preview)

---

## Package.swift Manifest

### Swift Tools Version

Must be declared on the first line. It is both the minimum compiler version required and what determines how the manifest is parsed.

```swift
// swift-tools-version:6.1
```

- Three-component semver (major.minor.patch). A missing patch is treated as `.0`
- Query or change it with `swift package tools-version`

### Basic Structure

```swift
// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "MyPackage",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "MyLibrary", targets: ["MyLibrary"]),
        .executable(name: "MyTool", targets: ["MyTool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "MyLibrary",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
            ]
        ),
        .executableTarget(name: "MyTool", dependencies: ["MyLibrary"]),
        .testTarget(name: "MyLibraryTests", dependencies: ["MyLibrary"]),
    ]
)
```

### Product Types

| Type | Description |
|------|-------------|
| `.library(name:targets:)` | A module other packages can import |
| `.library(name:type:.static,targets:)` | Static library (explicit) |
| `.library(name:type:.dynamic,targets:)` | Dynamic library (explicit) |
| `.executable(name:targets:)` | An executable program |
| `.plugin(name:targets:)` | A SwiftPM plugin |

### Target Types

| Type | Description |
|------|-------------|
| `.target` | Regular library module |
| `.executableTarget` | Executable target (`@main` entry point) |
| `.testTarget` | Test target |
| `.macro` | Swift macro target (depends on swift-syntax) |
| `.binaryTarget` | Precompiled binary (XCFramework) |
| `.plugin` | Build/command plugin |
| `.systemLibrary` | Wrapper around a C library installed on the system |

### Directory Conventions

```
├── Package.swift
├── Sources/
│   ├── MyLibrary/          # .target(name: "MyLibrary")
│   │   └── MyLibrary.swift
│   └── MyTool/             # .executableTarget(name: "MyTool")
│       └── main.swift
├── Tests/
│   └── MyLibraryTests/     # .testTarget(name: "MyLibraryTests")
│       └── MyLibraryTests.swift
└── Plugins/                # sources for .plugin targets
```

### Scaffolding

```bash
swift package init                # library
swift package init --type executable  # executable
swift package init --type tool        # CLI tool (includes swift-argument-parser)
swift package init --type macro       # macro (includes swift-syntax)
```

---

## Dependencies

### Version Requirements

```swift
dependencies: [
    // Up to the next major version (most common)
    .package(url: "https://github.com/org/repo.git", from: "2.0.0"),

    // Exact version
    .package(url: "https://github.com/org/repo.git", exact: "2.1.3"),

    // Up to the next minor version
    .package(url: "https://github.com/org/repo.git", .upToNextMinor(from: "2.1.0")),

    // Range
    .package(url: "https://github.com/org/repo.git", "2.0.0"..<"3.0.0"),

    // Branch (development/testing)
    .package(url: "https://github.com/org/repo.git", branch: "develop"),

    // Specific commit (debugging)
    .package(url: "https://github.com/org/repo.git", revision: "abc123"),
]
```

Git tags must be three-component semver (major.minor.patch). Two-component tags are ignored.

### Wiring Dependencies into a Target

```swift
.target(
    name: "MyTarget",
    dependencies: [
        // A target in the same package
        "OtherTarget",

        // A product from an external package
        .product(name: "Collections", package: "swift-collections"),

        // Conditional dependency
        .target(name: "LinuxHelper", condition: .when(platforms: [.linux])),
    ]
)
```

### Local Dependencies

```swift
dependencies: [
    .package(path: "../my-local-package"),
]
```

Uses whatever is currently at that path, with no version constraint.

### Binary Targets

Apple platforms only. A prebuilt binary distributed as an XCFramework.

```swift
targets: [
    // Remote binary
    .binaryTarget(
        name: "MyBinary",
        url: "https://example.com/MyBinary.xcframework.zip",
        checksum: "abc123..."
    ),
    // Local binary
    .binaryTarget(name: "MyBinary", path: "Frameworks/MyBinary.xcframework"),
]
```

### Traits (6.1+)

A mechanism for a package to offer optional APIs and dependencies.

```swift
// Use the default traits (no extra configuration needed)
.package(url: "https://github.com/org/repo.git", from: "1.0.0")

// Disable all traits
.package(url: "https://github.com/org/repo.git", from: "1.0.0", traits: [])

// Enable specific traits
.package(url: "https://github.com/org/repo.git", from: "1.0.0", traits: ["FeatureX"])
```

The enabled traits are the union of the trait requests from every package that depends on that package.

---

## Resolution & Package.resolved

### Package.resolved

Records the result of dependency resolution for the root package.

**Key behavior:**
- **Leaf projects** (apps, final executables): the resolved file guarantees reproducible builds. **Recommended to check into source control.**
- **Library packages**: when used as a dependency of another package, the resolved file is **ignored**. Adding it to `.gitignore` is fine.

### Commands

```bash
# Resolve dependencies (uses the versions in Package.resolved if present)
swift package resolve

# Force the versions recorded in Package.resolved
swift package resolve --force-resolved-versions

# Update to the latest eligible versions and refresh Package.resolved
swift package update

# Update only a specific package
swift package update swift-collections
```

### Implicit Resolution

`swift build`, `swift run`, and `swift test` automatically resolve first.

---

## Resources

Swift tools version 5.3+. Bundles resource files alongside source code.

### Declaration

```swift
.target(
    name: "MyLibrary",
    resources: [
        .process("Resources/data.json"),     // platform-specific optimization applied
        .copy("Resources/templates"),         // copied as-is, directory structure preserved
    ],
    exclude: ["Resources/notes.md"]          // left out of the bundle
)
```

### `.process()` vs `.copy()`

| Rule | Behavior | When to use |
|------|----------|-------------|
| `.process()` | Platform-specific optimization (image compression, asset catalog compilation, etc.). Copied as-is when no special processing applies | Most cases (the default choice) |
| `.copy()` | Copied unchanged. Directories keep their structure | When the directory structure matters or you don't want any transformation |

### Access

```swift
// Bundle.module — always use this
let url = Bundle.module.url(forResource: "data", withExtension: "json")!
let data = try Data(contentsOf: url)
```

`Bundle.module` is an `internal static` extension generated by the compiler. Never use `Bundle.main` for package resources.

### Directory Convention

```
Sources/MyLibrary/
├── MyLibrary.swift
└── Resources/           # keep resource files separate (recommended)
    ├── data.json
    └── Assets.xcassets
```

---

## Build Settings

### Debug vs Release

| Setting | Debug (default) | Release (`-c release`) |
|---------|-----------------|------------------------|
| Swift optimization | `-Onone` | `-O` + `-whole-module-optimization` |
| C optimization | `-O0` | `-O2` |
| Debug info | `-g` | — |
| Testing support | `-enable-testing` | — |
| Build output | `.build/debug/` | `.build/release/` |

### Target-Level Settings

```swift
.target(
    name: "MyTarget",
    swiftSettings: [
        .define("FEATURE_FLAG"),
        .unsafeFlags(["-enable-bare-slash-regex"]),
    ],
    cSettings: [
        .define("NDEBUG", .when(configuration: .release)),
        .headerSearchPath("include"),
    ],
    linkerSettings: [
        .linkedLibrary("z"),
        .linkedFramework("Security", .when(platforms: [.macOS, .iOS])),
    ]
)
```

### Command-Line Flags

```bash
swift build -Xswiftc -warnings-as-errors
swift build -Xcc -Wall
swift build -Xlinker -rpath -Xlinker /usr/local/lib
```

`-Xcc`, `-Xswiftc`, and `-Xlinker` apply to every target. For per-target control, use the settings in the manifest.

---

## C/C++/ObjC Targets

A Swift package can host C, C++, and Objective-C code as modules.

### Directory Structure

```
Sources/MyCLib/
├── include/           # public headers (default path)
│   └── MyCLib.h
└── source.c
```

### Module Map Auto-Generation Rules

SwiftPM generates a module map automatically based on the layout of `include/`:

1. `include/Foo/Foo.h` — used as the umbrella header
2. `include/Foo.h` (no subdirectory) — used as the umbrella header
3. Otherwise — all of `include/` is used as the umbrella directory

For more complex layouts, write `include/module.modulemap` yourself.

### Custom Header Path

```swift
.target(
    name: "MyCLib",
    publicHeadersPath: "headers"  // a path other than include/
)
```

### Using It from Swift

```swift
import MyCLib  // import by the auto-generated module name
```

---

## Module Aliasing

Swift 5.7+. Resolves conflicts when different packages provide modules with the same name.

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "Utils", package: "swift-draw"),
        .product(
            name: "Utils",
            package: "swift-game",
            moduleAliases: ["Utils": "SwiftGameUtils"]
        ),
    ]
)
```

In Swift code:
```swift
import Utils           // Utils from swift-draw
import SwiftGameUtils  // Utils from swift-game (aliased)
```

### Limitations

- **Pure Swift only** — not available for ObjC/C/C++ modules, and the `@objc(name)` attribute cannot be used
- **Source-based only** — not available for prebuilt binaries
- **No runtime string conversion** — cannot be used with `NSClassFromString()` and the like

---

## Plugins

Swift 5.6+. Executable code that extends the build process or package commands.

### Build Plugin vs Command Plugin

| | Build Plugin | Command Plugin |
|---|---|---|
| When it runs | Automatically during the build | Manually from the `swift package` CLI |
| Modifies sources | No | Yes, after user approval |
| Can invoke build/test | No | Yes |
| Typical use | Code generation, preprocessing | Formatting, linting, custom tasks |

### Sandboxing

Every plugin runs isolated in a separate process:
- No network access
- Restricted filesystem writes (temporary directory only)
- Source modifications by command plugins require user approval

### Using a Plugin

```swift
.target(
    name: "MyTarget",
    plugins: [
        .plugin(name: "SwiftGenPlugin", package: "SwiftGen"),
    ]
)
```

---

## Version-Specific Packaging

When multiple Swift versions must be supported, you can provide per-version manifests.

### Version-Specific Manifest Files

```
├── Package.swift              # latest (swift-tools-version:6.1)
├── Package@swift-5.10.swift   # for Swift 5.10
└── Package@swift-5.9.swift    # for Swift 5.9
```

Resolution order:
1. `Package@swift-MAJOR.MINOR.PATCH.swift`
2. `Package@swift-MAJOR.MINOR.swift`
3. `Package@swift-MAJOR.swift`
4. No match → the manifest with the most compatible tools version is chosen

**Best practice**: keep `Package.swift` on the latest tools version and add version-specific files only for older versions.

### Version-Specific Git Tags

```
1.0.0           # all Swift versions
1.2.0@swift-5   # Swift 5.x only
1.3.0           # Swift 6.0+ (not visible to 5.x)
```

Don't add a version suffix to tags meant for the latest Swift version. Use suffixes only when older versions need to be supported.

---

## Security

### Trust on First Use (TOFU)

The fingerprint is recorded the first time a package version is downloaded and checked against on later downloads.

| Source | Fingerprint |
|--------|-------------|
| Git repository | Git revision hash |
| Package registry | Source archive checksum |

Stored under: `~/.swiftpm/security/fingerprints/`

A fingerprint mismatch is an error (a possible-tampering warning). `--resolver-fingerprint-checking warn` downgrades it to a warning.

### Package Signing

Packages distributed through a registry can be signed.

```bash
swift package-registry publish \
    --signing-identity "Developer ID" \
    # or
    --private-key-path key.pem \
    --cert-chain-paths cert.pem
```

Signing certificate requirements:
- Extended Key Usage includes Code Signing
- Key strength: 256-bit EC (recommended) or 2048-bit RSA
- Within its validity period and not revoked (OCSP)
- Complete chain to a trusted root

### Trust Store

Custom root certificates: `~/.swiftpm/security/trust-root-certs/` (DER-encoded)

---

## Swift Build (6.3 Preview)

A new build system under development as a replacement for the existing native build system.

```bash
swift build --build-system swiftbuild
swift test --build-system swiftbuild
swift run --build-system swiftbuild
```

### Key Differences

- **Stricter validation**: `--static-swift-stdlib` is an error on unsupported platforms (previously ignored)
- **Universal binary support** (Apple platforms):
  ```bash
  swift build --build-system swiftbuild --arch arm64 --arch x86_64
  ```
- **Apple platform resources**: the same resource-processing rules as xcodebuild apply
- **Build output path changed**: check with `swift build --show-bin-path`
- **Integrated Swift driver**: the `--use-integrated-swift-driver` option is deprecated

### Current Status

Preview stage. Known limitations:
- Windows: no CodeView debug info
- Sanitizers (`scudo`, `fuzzer`) unsupported
- Dependencies between test targets unsupported

Report problems as issues at [swiftlang/swift-package-manager](https://github.com/swiftlang/swift-package-manager/issues).
