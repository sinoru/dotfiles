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

| Annotation | Type in Swift |
|---|---|
| `nonnull` (default, within `NS_ASSUME_NONNULL` region) | Non-optional (`String`) |
| `nullable` | Optional (`String?`) |
| `null_resettable` | Implicitly unwrapped (`String!`) |
| `_Nonnull` / `_Nullable` | Qualifier form for complex pointer types |
| No annotation | Implicitly unwrapped (`!`) — always avoid this |

```objc
NS_ASSUME_NONNULL_BEGIN
@interface MYUser : NSObject
@property (copy) NSString *name;              // → String
@property (nullable, copy) NSString *bio;     // → String?
- (nullable MYUser *)friendWithName:(NSString *)name; // → MYUser?
@end
NS_ASSUME_NONNULL_END
```

Apply nullability annotations to every public ObjC header.

---

## Naming & API Refinement

| Annotation | Purpose |
|---|---|
| `NS_SWIFT_NAME(name)` | Specifies the Swift import name. Can convert a free function into a type member |
| `NS_REFINED_FOR_SWIFT` | Adds a `__` prefix, hides from autocomplete. Encourages writing a Swift wrapper |
| `NS_SWIFT_UNAVAILABLE("msg")` | Completely hides from Swift + compile error message |

```objc
+ (instancetype)colorWithGrayLevel:(CGFloat)gray
    NS_SWIFT_NAME(init(grayLevel:));
// Swift: Color(grayLevel: 0.5)

- (NSInteger)rawValueForOption:(MYOption)option
    NS_REFINED_FOR_SWIFT;
// Swift: __rawValueForOption → wrap in an extension
```

---

## Enum & Constant Grouping

| Annotation | Swift Mapping |
|---|---|
| `NS_ENUM` | `@objc enum` (open, requires `default`) |
| `NS_CLOSED_ENUM` | `@frozen @objc enum` (exhaustive `switch`) |
| `NS_OPTIONS` | `OptionSet` struct |
| `NS_TYPED_ENUM` | `RawRepresentable` struct + static members |
| `NS_TYPED_EXTENSIBLE_ENUM` | Extensible `RawRepresentable` struct |

```objc
typedef NS_CLOSED_ENUM(NSInteger, MYDirection) {
    MYDirectionNorth, MYDirectionSouth, MYDirectionEast, MYDirectionWest
};
// Swift: no default needed in switch

typedef NSString *MYNotificationName NS_EXTENSIBLE_STRING_ENUM;
// Cases can be added via a Swift extension
```

---

## Concurrency Annotations

| Annotation | Purpose |
|---|---|
| `NS_SWIFT_ASYNC(N)` | Specifies parameter N as the completion handler |
| `NS_SWIFT_ASYNC(NONE)` | Disables async import |
| `NS_SWIFT_ASYNC_NAME("name")` | Specifies the async method signature |
| `NS_SWIFT_UI_ACTOR` | `@MainActor` isolation |
| `_Nullable_result` | Returns the completion result as optional in async |
| `NS_SWIFT_SENDABLE` / `NS_SWIFT_NONSENDABLE` | Sendable conformance |
| `NS_SWIFT_NONISOLATED` | Marks as nonisolated |

Automatic async import conditions: void return + completion handler block (void return) + called exactly once on every path.

```objc
- (void)fetchDataWithCompletion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion;
// Both versions are usable from Swift:
//   func fetchData(completion: @escaping (Data?, Error?) -> Void)
//   func fetchData() async throws -> Data
```

---

## Bridging Configuration

### App Target: Bridging Header
- Xcode auto-generates `[ModuleName]-Bridging-Header.h`
- ObjC headers listed here are accessible from every Swift file

### Framework Target: Umbrella Header + Module
- Build Settings > "Defines Module" = Yes
- Import public headers in the umbrella header
- Bridging headers cannot be used (in frameworks)

### Swift → ObjC: Generated Header
- Xcode auto-generates `[ModuleName]-Swift.h`
- `#import "ModuleName-Swift.h"` in `.m` files
- Cannot import in `.h` files (circular dependency) → use `@class`, `@protocol` forward declarations

---

## Swift → ObjC

### Automatic Bridging

| Objective-C | Swift |
|---|---|
| `NSString *` | `String` |
| `NSArray<NSString *> *` | `[String]` |
| `NSDictionary<K, V> *` | `[K: V]` |
| `NSError **` out-parameter | `throws` |
| `BOOL` | `Bool` |
| `id` | `Any` |
| Block types | Closure types |

### Name Conversion
- Remove `init`, remove `With`, then lowercase
- `instancetype`-returning factory → convenience initializer
- `NSError **` last parameter + BOOL/optional return → `throws`

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

- Requires NSObject inheritance
- `@objc` on the class alone does not expose members — required on each member too

### @objcMembers

```swift
@objcMembers class MyModel: NSObject {
    var name: String = ""   // Automatically @objc
    func save() { }         // Automatically @objc
}
```

### Not Exposable to ObjC

Swift structs, enums with associated values, generics, actors (only `nonisolated`/`async` members are possible), nested types, tuples.

---

## SE-0436: @objc @implementation

Write the ObjC header manually and implement it in Swift:

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
    func flip() { /* Swift implementation */ }
}
```

The resulting class behaves like a pure ObjC class — ObjC subclassing and method swizzling are possible.

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

### Swift Equivalent

```swift
doSomething { [weak self] in
    guard let self else { return }
    self.doWork()
}
```

### Rules

- **Delegate**: always `weak`
- **Timer target**: `weak`
- **Storing a block that references self in a property**: `weak` capture
- `@autoreleasepool` — needed in loops that create large numbers of temporary objects

---

## Common Pitfalls

1. **Missing nullability** → `!` type in Swift, risk of runtime crash
2. **Importing `-Swift.h` in a `.h`** → circular dependency. Use forward declaration
3. **Misunderstanding lightweight generics** → only `NSArray`/`NSDictionary`/`NSSet` bridge. Custom class generics are ignored in Swift
4. **Completion handler called 0 times or 2+ times** → runtime trap in the async bridge
5. **Missing `NS_NOESCAPE`** → treated as `@escaping` in Swift, requires unnecessary `self.`
6. **Missing `dynamic` on a KVO property** → both `@objc` and `dynamic` are required
7. **Subclassing a Swift class from ObjC** → use SE-0436 `@objc @implementation`
8. **Confusing `NS_ENUM` vs `NS_CLOSED_ENUM`** → use `NS_CLOSED_ENUM` for non-extensible enums
9. **Bare `id` type** → use `instancetype`, `id<Protocol>`, or a concrete type
10. **Informal protocol** → does not bridge to Swift. Use `@protocol`
