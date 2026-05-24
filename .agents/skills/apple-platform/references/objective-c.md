# Objective-C & Swift Interop Reference

## Table of Contents
1. [Nullability Annotations](#nullability-annotations)
2. [Naming & API Refinement](#naming--api-refinement)
3. [Enum & Constant Grouping](#enum--constant-grouping)
4. [Concurrency Annotations](#concurrency-annotations)
5. [Bridging Configuration](#bridging-configuration)
6. [Swift → ObjC (Calling ObjC from Swift)](#swift--objc)
7. [ObjC → Swift (Exposing Swift to ObjC)](#objc--swift)
8. [SE-0436: @objc @implementation](#se-0436-objc-implementation)
9. [ARC Best Practices](#arc-best-practices)
10. [Common Pitfalls](#common-pitfalls)

---

## Nullability Annotations

| Annotation | Swift에서의 타입 |
|---|---|
| `nonnull` (기본, `NS_ASSUME_NONNULL` 영역 내) | Non-optional (`String`) |
| `nullable` | Optional (`String?`) |
| `null_resettable` | Implicitly unwrapped (`String!`) |
| `_Nonnull` / `_Nullable` | 복잡한 포인터 타입용 qualifier 형태 |
| annotation 없음 | Implicitly unwrapped (`!`) — 반드시 피한다 |

```objc
NS_ASSUME_NONNULL_BEGIN
@interface MYUser : NSObject
@property (copy) NSString *name;              // → String
@property (nullable, copy) NSString *bio;     // → String?
- (nullable MYUser *)friendWithName:(NSString *)name; // → MYUser?
@end
NS_ASSUME_NONNULL_END
```

모든 공개 ObjC 헤더에 nullability annotation을 적용한다.

---

## Naming & API Refinement

| Annotation | 용도 |
|---|---|
| `NS_SWIFT_NAME(name)` | Swift import 이름 지정. free function → type member 변환 가능 |
| `NS_REFINED_FOR_SWIFT` | `__` 접두사 추가, autocomplete 숨김. Swift wrapper 작성 유도 |
| `NS_SWIFT_UNAVAILABLE("msg")` | Swift에서 완전 숨김 + 컴파일 에러 메시지 |

```objc
+ (instancetype)colorWithGrayLevel:(CGFloat)gray
    NS_SWIFT_NAME(init(grayLevel:));
// Swift: Color(grayLevel: 0.5)

- (NSInteger)rawValueForOption:(MYOption)option
    NS_REFINED_FOR_SWIFT;
// Swift: __rawValueForOption → extension에서 래핑
```

---

## Enum & Constant Grouping

| Annotation | Swift 매핑 |
|---|---|
| `NS_ENUM` | `@objc enum` (open, `default` 필요) |
| `NS_CLOSED_ENUM` | `@frozen @objc enum` (exhaustive `switch`) |
| `NS_OPTIONS` | `OptionSet` struct |
| `NS_TYPED_ENUM` | `RawRepresentable` struct + static members |
| `NS_TYPED_EXTENSIBLE_ENUM` | 확장 가능한 `RawRepresentable` struct |

```objc
typedef NS_CLOSED_ENUM(NSInteger, MYDirection) {
    MYDirectionNorth, MYDirectionSouth, MYDirectionEast, MYDirectionWest
};
// Swift: switch에서 default 불필요

typedef NSString *MYNotificationName NS_EXTENSIBLE_STRING_ENUM;
// Swift extension으로 case 추가 가능
```

---

## Concurrency Annotations

| Annotation | 용도 |
|---|---|
| `NS_SWIFT_ASYNC(N)` | 파라미터 N을 completion handler로 명시 |
| `NS_SWIFT_ASYNC(NONE)` | async import 비활성화 |
| `NS_SWIFT_ASYNC_NAME("name")` | async 메서드 시그니처 지정 |
| `NS_SWIFT_UI_ACTOR` | `@MainActor` 격리 |
| `_Nullable_result` | completion 결과를 async에서 optional로 반환 |
| `NS_SWIFT_SENDABLE` / `NS_SWIFT_NONSENDABLE` | Sendable 적합성 |
| `NS_SWIFT_NONISOLATED` | nonisolated 표시 |

자동 async import 조건: void 반환 + completion handler 블록(void 반환) + 모든 경로에서 정확히 1회 호출.

```objc
- (void)fetchDataWithCompletion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion;
// Swift에서 두 버전 모두 사용 가능:
//   func fetchData(completion: @escaping (Data?, Error?) -> Void)
//   func fetchData() async throws -> Data
```

---

## Bridging Configuration

### App Target: Bridging Header
- Xcode가 `[ModuleName]-Bridging-Header.h` 자동 생성
- 여기 나열된 ObjC 헤더가 모든 Swift 파일에서 접근 가능

### Framework Target: Umbrella Header + Module
- Build Settings > "Defines Module" = Yes
- umbrella header에 공개 헤더 import
- bridging header 사용 불가 (framework에서는)

### Swift → ObjC: Generated Header
- Xcode가 `[ModuleName]-Swift.h` 자동 생성
- `.m` 파일에서 `#import "ModuleName-Swift.h"`
- `.h` 파일에서는 import 불가 (순환 의존) → `@class`, `@protocol` forward declaration 사용

---

## Swift → ObjC

### 자동 브릿징

| Objective-C | Swift |
|---|---|
| `NSString *` | `String` |
| `NSArray<NSString *> *` | `[String]` |
| `NSDictionary<K, V> *` | `[K: V]` |
| `NSError **` out-parameter | `throws` |
| `BOOL` | `Bool` |
| `id` | `Any` |
| Block types | Closure types |

### 이름 변환
- `init` 제거, `With` 제거 후 소문자화
- `instancetype` 반환 factory → convenience initializer
- `NSError **` 마지막 파라미터 + BOOL/optional 반환 → `throws`

---

## ObjC → Swift

### @objc

```swift
@objc class MyManager: NSObject {
    @objc func reload() { }
    @objc(reloadItemWithIdentifier:)
    func reload(item id: String) { }
}
```

- `NSObject` 상속 필수
- 클래스에 `@objc`만으로는 멤버 노출 안 됨 — 각 멤버에도 필요

### @objcMembers

```swift
@objcMembers class MyModel: NSObject {
    var name: String = ""   // 자동 @objc
    func save() { }         // 자동 @objc
}
```

### ObjC에 노출 불가

Swift structs, 연관값 enum, generics, actors(`nonisolated`/`async` 멤버만 가능), nested types, 튜플.

---

## SE-0436: @objc @implementation

ObjC 헤더를 수동 작성하고 Swift로 구현:

```objc
// MyClass.h
@interface MYFlippableVC : UIViewController
@property (strong) UIView *frontView;
- (void)flip;
@end
```
```swift
@objc @implementation
extension MYFlippableVC {
    var frontView: UIView!
    func flip() { /* Swift 구현 */ }
}
```

결과 클래스가 순수 ObjC처럼 동작 — ObjC 서브클래싱, method swizzling 가능.

---

## ARC Best Practices

### Weak-Strong Dance (ObjC)

```objc
__weak __typeof(self) weakSelf = self;
[self doSomethingWithBlock:^{
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    [strongSelf doWork];
}];
```

### Swift 동등

```swift
doSomething { [weak self] in
    guard let self else { return }
    self.doWork()
}
```

### 규칙

- **Delegate**: 항상 `weak`
- **Timer target**: `weak`
- **self를 참조하는 block을 프로퍼티에 저장**: `weak` capture
- `@autoreleasepool` — 대량 임시 객체 생성 루프에서 필요

---

## Common Pitfalls

1. **Nullability 누락** → Swift에서 `!` 타입, 런타임 크래시 위험
2. **`.h`에서 `-Swift.h` import** → 순환 의존. forward declaration 사용
3. **Lightweight generics 오해** → `NSArray`/`NSDictionary`/`NSSet`만 브릿지. 커스텀 클래스 generics는 Swift에서 무시
4. **Completion handler 0회 또는 2회+ 호출** → async 브릿지에서 런타임 trap
5. **`NS_NOESCAPE` 누락** → Swift에서 `@escaping` 취급, 불필요한 `self.` 필요
6. **KVO 프로퍼티에 `dynamic` 누락** → `@objc`와 `dynamic` 둘 다 필요
7. **ObjC에서 Swift 클래스 서브클래싱** → SE-0436 `@objc @implementation` 사용
8. **`NS_ENUM` vs `NS_CLOSED_ENUM` 혼동** → 확장 불가 enum은 `NS_CLOSED_ENUM`으로
9. **bare `id` 타입** → `instancetype`, `id<Protocol>`, 구체 타입 사용
10. **informal protocol** → Swift에 브릿지 안 됨. `@protocol` 사용
