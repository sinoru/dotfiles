# Swift Package Manager

SwiftPM 공식 문서(docs.swift.org/swiftpm) 기반. 서버 프로젝트 전용 패턴(Vapor Package.swift 템플릿, 폴더 구조 등)은 **swiftlang-server** 스킬 참조.

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

첫 번째 줄에 반드시 선언. 최소 필요 컴파일러 버전이자 manifest 파싱 방식을 결정한다.

```swift
// swift-tools-version:6.1
```

- 세 자리 semver (major.minor.patch). patch 생략 시 `.0`
- `swift package tools-version` 명령으로 조회/변경 가능

### 기본 구조

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

### Product 타입

| 타입 | 설명 |
|------|------|
| `.library(name:targets:)` | 다른 패키지에서 import할 수 있는 모듈 |
| `.library(name:type:.static,targets:)` | 정적 라이브러리 (명시) |
| `.library(name:type:.dynamic,targets:)` | 동적 라이브러리 (명시) |
| `.executable(name:targets:)` | 실행 가능한 프로그램 |
| `.plugin(name:targets:)` | SwiftPM 플러그인 |

### Target 타입

| 타입 | 설명 |
|------|------|
| `.target` | 일반 라이브러리 모듈 |
| `.executableTarget` | 실행 가능 타겟 (`@main` 진입점) |
| `.testTarget` | 테스트 타겟 |
| `.macro` | Swift 매크로 타겟 (swift-syntax 의존) |
| `.binaryTarget` | 사전 컴파일된 바이너리 (XCFramework) |
| `.plugin` | 빌드/커맨드 플러그인 |
| `.systemLibrary` | 시스템에 설치된 C 라이브러리 래퍼 |

### 디렉토리 규칙

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
└── Plugins/                # .plugin 타겟 소스
```

### Scaffolding

```bash
swift package init                # 라이브러리
swift package init --type executable  # 실행파일
swift package init --type tool        # CLI 도구 (swift-argument-parser 포함)
swift package init --type macro       # 매크로 (swift-syntax 포함)
```

---

## Dependencies

### 버전 요구사항

```swift
dependencies: [
    // 다음 major 버전 미만까지 (가장 일반적)
    .package(url: "https://github.com/org/repo.git", from: "2.0.0"),

    // 정확한 버전
    .package(url: "https://github.com/org/repo.git", exact: "2.1.3"),

    // 다음 minor 버전 미만까지
    .package(url: "https://github.com/org/repo.git", .upToNextMinor(from: "2.1.0")),

    // 범위
    .package(url: "https://github.com/org/repo.git", "2.0.0"..<"3.0.0"),

    // 브랜치 (개발/테스트용)
    .package(url: "https://github.com/org/repo.git", branch: "develop"),

    // 특정 커밋 (디버깅용)
    .package(url: "https://github.com/org/repo.git", revision: "abc123"),
]
```

Git 태그는 반드시 세 자리 semver(major.minor.patch). 두 자리 태그는 무시된다.

### Target에 의존성 연결

```swift
.target(
    name: "MyTarget",
    dependencies: [
        // 같은 패키지 내 타겟
        "OtherTarget",

        // 외부 패키지의 product
        .product(name: "Collections", package: "swift-collections"),

        // 조건부 의존성
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

버전 제약 없이 해당 경로의 현재 상태를 사용한다.

### Binary Targets

Apple 플랫폼 전용. XCFramework 형태의 사전 빌드 바이너리.

```swift
targets: [
    // 원격 바이너리
    .binaryTarget(
        name: "MyBinary",
        url: "https://example.com/MyBinary.xcframework.zip",
        checksum: "abc123..."
    ),
    // 로컬 바이너리
    .binaryTarget(name: "MyBinary", path: "Frameworks/MyBinary.xcframework"),
]
```

### Traits (6.1+)

패키지가 선택적 API와 의존성을 제공하는 메커니즘.

```swift
// 기본 trait 사용 (별도 설정 불필요)
.package(url: "https://github.com/org/repo.git", from: "1.0.0")

// 모든 trait 비활성화
.package(url: "https://github.com/org/repo.git", from: "1.0.0", traits: [])

// 특정 trait 활성화
.package(url: "https://github.com/org/repo.git", from: "1.0.0", traits: ["FeatureX"])
```

활성화된 trait는 해당 패키지에 의존하는 모든 패키지의 trait 요청을 합산(union)한다.

---

## Resolution & Package.resolved

### Package.resolved

최상위 패키지의 의존성 resolution 결과를 기록하는 파일.

**핵심 동작:**
- **leaf 프로젝트** (앱, 최종 실행 파일): resolved 파일이 빌드 재현성을 보장. **소스 컨트롤에 포함 권장.**
- **라이브러리 패키지**: 다른 패키지의 의존성으로 쓰일 때 resolved 파일은 **무시됨**. `.gitignore`에 추가해도 됨.

### 명령어

```bash
# 의존성 해결 (Package.resolved 있으면 해당 버전 사용)
swift package resolve

# 강제로 Package.resolved의 버전 사용
swift package resolve --force-resolved-versions

# 최신 eligible 버전으로 업데이트 + Package.resolved 갱신
swift package update

# 특정 패키지만 업데이트
swift package update swift-collections
```

### 암시적 Resolution

`swift build`, `swift run`, `swift test` 실행 시 자동으로 resolve가 먼저 수행된다.

---

## Resources

Swift tools version 5.3+. 소스 코드와 함께 리소스 파일을 번들링.

### 선언

```swift
.target(
    name: "MyLibrary",
    resources: [
        .process("Resources/data.json"),     // 플랫폼별 최적화 적용
        .copy("Resources/templates"),         // 디렉토리 구조 그대로 복사
    ],
    exclude: ["Resources/notes.md"]          // 번들에서 제외
)
```

### `.process()` vs `.copy()`

| 규칙 | 동작 | 사용 시점 |
|------|------|-----------|
| `.process()` | 플랫폼별 최적화 (이미지 압축, asset catalog 컴파일 등). 특별한 처리가 없으면 그대로 복사 | 대부분의 경우 (기본 선택) |
| `.copy()` | 변경 없이 그대로 복사. 디렉토리면 구조 유지 | 디렉토리 구조가 중요하거나 변환을 원치 않을 때 |

### 접근

```swift
// Bundle.module — 반드시 이것을 사용
let url = Bundle.module.url(forResource: "data", withExtension: "json")!
let data = try Data(contentsOf: url)
```

`Bundle.module`은 컴파일러가 자동 생성하는 `internal static` 확장이다. `Bundle.main` 사용 금지.

### 디렉토리 관례

```
Sources/MyLibrary/
├── MyLibrary.swift
└── Resources/           # 리소스 파일 분리 (권장)
    ├── data.json
    └── Assets.xcassets
```

---

## Build Settings

### Debug vs Release

| 설정 | Debug (기본) | Release (`-c release`) |
|------|-------------|----------------------|
| Swift 최적화 | `-Onone` | `-O` + `-whole-module-optimization` |
| C 최적화 | `-O0` | `-O2` |
| 디버그 정보 | `-g` | — |
| 테스트 지원 | `-enable-testing` | — |
| 빌드 결과 | `.build/debug/` | `.build/release/` |

### Target-level 설정

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

### 커맨드라인 플래그

```bash
swift build -Xswiftc -warnings-as-errors
swift build -Xcc -Wall
swift build -Xlinker -rpath -Xlinker /usr/local/lib
```

`-Xcc`, `-Xswiftc`, `-Xlinker`는 모든 타겟에 적용된다. 타겟별 제어는 manifest의 settings 사용.

---

## C/C++/ObjC Targets

Swift 패키지에서 C, C++, Objective-C 코드를 모듈로 호스팅 가능.

### 디렉토리 구조

```
Sources/MyCLib/
├── include/           # public 헤더 (기본 경로)
│   └── MyCLib.h
└── source.c
```

### Module Map 자동 생성 규칙

SwiftPM이 `include/` 디렉토리 구조에 따라 자동으로 module map을 생성한다:

1. `include/Foo/Foo.h` — umbrella header로 사용
2. `include/Foo.h` (하위 디렉토리 없음) — umbrella header로 사용
3. 그 외 — `include/` 전체를 umbrella directory로 사용

복잡한 레이아웃이면 `include/module.modulemap`을 직접 작성.

### 커스텀 헤더 경로

```swift
.target(
    name: "MyCLib",
    publicHeadersPath: "headers"  // include/ 대신 다른 경로
)
```

### Swift에서 사용

```swift
import MyCLib  // 자동 생성된 모듈 이름으로 import
```

---

## Module Aliasing

Swift 5.7+. 서로 다른 패키지가 같은 이름의 모듈을 제공할 때 충돌 해결.

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

Swift 코드에서:
```swift
import Utils           // swift-draw의 Utils
import SwiftGameUtils  // swift-game의 Utils (별칭)
```

### 제약사항

- **순수 Swift만** — ObjC/C/C++ 모듈 불가. `@objc(name)` 어트리뷰트 사용 불가
- **소스 기반만** — 사전 빌드 바이너리 불가
- **런타임 문자열 변환 불가** — `NSClassFromString()` 등에서 사용 불가

---

## Plugins

Swift 5.6+. 빌드 과정이나 패키지 명령을 확장하는 실행 코드.

### Build Plugin vs Command Plugin

| | Build Plugin | Command Plugin |
|---|---|---|
| 실행 시점 | 빌드 중 자동 | `swift package` CLI에서 수동 |
| 소스 수정 | 불가 | 사용자 승인 후 가능 |
| 빌드/테스트 호출 | 불가 | 가능 |
| 용도 | 코드 생성, 전처리 | 포매팅, 린팅, 커스텀 작업 |

### 샌드박싱

모든 플러그인은 별도 프로세스에서 격리 실행:
- 네트워크 접근 불가
- 파일시스템 쓰기 제한 (임시 디렉토리만 허용)
- Command plugin의 소스 수정은 사용자 승인 필요

### 플러그인 사용

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

여러 Swift 버전을 지원해야 할 때, 버전별 manifest를 제공할 수 있다.

### 버전별 Manifest 파일

```
├── Package.swift              # 최신 (swift-tools-version:6.1)
├── Package@swift-5.10.swift   # Swift 5.10용
└── Package@swift-5.9.swift    # Swift 5.9용
```

해석 우선순위:
1. `Package@swift-MAJOR.MINOR.PATCH.swift`
2. `Package@swift-MAJOR.MINOR.swift`
3. `Package@swift-MAJOR.swift`
4. 매치 없으면 → 가장 호환되는 tools version의 manifest 선택

**모범 사례**: `Package.swift`는 최신 tools version, 버전별 파일은 이전 버전만 지정.

### 버전별 Git 태그

```
1.0.0           # 모든 Swift 버전
1.2.0@swift-5   # Swift 5.x 전용
1.3.0           # Swift 6.0+ (5.x에서는 보이지 않음)
```

최신 Swift 버전용 태그에는 버전 접미사를 붙이지 않는다. 이전 버전 지원이 필요한 경우에만 사용.

---

## Security

### Trust on First Use (TOFU)

패키지 버전 최초 다운로드 시 fingerprint를 기록하고, 이후 다운로드에서 대조한다.

| 출처 | Fingerprint |
|------|-------------|
| Git repository | Git revision hash |
| Package registry | Source archive checksum |

저장 위치: `~/.swiftpm/security/fingerprints/`

fingerprint 불일치 시 에러 발생 (변조 가능성 경고). `--resolver-fingerprint-checking warn`으로 경고 수준 변경 가능.

### 패키지 서명

Registry를 통해 배포하는 패키지에 서명을 추가할 수 있다.

```bash
swift package-registry publish \
    --signing-identity "Developer ID" \
    # 또는
    --private-key-path key.pem \
    --cert-chain-paths cert.pem
```

서명 인증서 요구사항:
- Extended Key Usage: Code Signing 포함
- 키 강도: 256-bit EC (권장) 또는 2048-bit RSA
- 유효 기간 내 + 미취소 (OCSP)
- 신뢰 루트 체인 완성

### 신뢰 저장소

커스텀 루트 인증서: `~/.swiftpm/security/trust-root-certs/` (DER 인코딩)

---

## Swift Build (6.3 Preview)

기존 네이티브 빌드 시스템의 대체로 개발 중인 새 빌드 시스템.

```bash
swift build --build-system swiftbuild
swift test --build-system swiftbuild
swift run --build-system swiftbuild
```

### 주요 차이

- **Stricter validation**: `--static-swift-stdlib` 미지원 플랫폼에서 에러 (기존: 무시)
- **Universal binary 지원** (Apple 플랫폼):
  ```bash
  swift build --build-system swiftbuild --arch arm64 --arch x86_64
  ```
- **Apple 플랫폼 리소스**: xcodebuild과 동일한 리소스 처리 규칙 적용
- **빌드 결과 경로 변경**: `swift build --show-bin-path`로 확인
- **통합 Swift driver**: `--use-integrated-swift-driver` 옵션 deprecated

### 현재 상태

Preview 단계. 알려진 제한사항:
- Windows: CodeView 디버그 정보 미지원
- sanitizer(`scudo`, `fuzzer`) 미지원
- 테스트 타겟 간 의존성 미지원

문제 발견 시 [swiftlang/swift-package-manager](https://github.com/swiftlang/swift-package-manager/issues) 이슈 등록.
