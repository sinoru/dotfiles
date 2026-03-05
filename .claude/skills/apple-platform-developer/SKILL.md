---
name: apple-platform-developer
description: "Apple platform version policy, framework conventions, and availability handling. TRIGGER when: working in a project targeting Apple platforms (.xcodeproj, .xcworkspace, or Apple framework imports like SwiftUI/UIKit/AppKit/WebKit). Invoke once at the start of a coding task, before writing code. DO NOT TRIGGER when: server-side Swift without Apple platform targets, or pure research tasks with no code changes."
---

# Apple Platform Conventions

## OS 버전 정책

- **최신 OS 기술 우선**: 코드 설계와 구현은 가장 최신 OS의 API와 패턴을 기준으로 사고한다.
- **최근 2년간 OS 지원 필수**: 최신 OS 포함 직전 2개 메이저 버전까지 런타임 지원이 되어야 한다.
  - 2026 기준: iOS 26.0+ / macOS 26.0+ / watchOS 26.0+ / tvOS 26.0+
  - 이 버전 범위는 매년 새로운 OS 출시에 따라 갱신된다.

## Availability 처리

- 최신 전용 API는 `if #available` / `@available`로 분기하고, fallback을 반드시 제공한다.
- Deployment target에서 사용 불가한 API를 무분별하게 쓰지 않는다.
- 핵심 기능이 최신 OS 전용 API에 의존하는 경우, 트레이드오프를 먼저 설명하고 컨펌을 받는다.

## Deprecated API

- Apple이 deprecated로 표시한 API는 가능한 한 사용하지 않고, 대체 API를 우선 사용한다.
- deprecated API를 써야 하는 상황이라면 이유를 명시한다.

## Apple 프레임워크 관례

- Apple 프레임워크의 기존 패턴과 네이밍 관례를 최대한 따른다.
- Delegate 메서드는 첫 번째 파라미터를 호출자(delegate source)로 한다:
  ```swift
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
  ```
- Cocoa/UIKit 등 기존 API와의 일관성을 유지한다.