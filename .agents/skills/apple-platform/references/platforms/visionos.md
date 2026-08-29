# visionOS Reference

For per-version feature history (visionOS 2 = 2024, visionOS 26 = 2025, visionOS 27 = 2026), see the `../wwdc/` year files.

## Table of Contents
1. [App Types: Window, Volume, ImmersiveSpace](#app-types)
2. [SwiftUI on visionOS](#swiftui-on-visionos)
3. [RealityKit](#realitykit)
4. [Spatial Input](#spatial-input)
5. [Porting from iOS/iPadOS](#porting-from-iosipados)
6. [Design Principles](#design-principles)
7. [Performance](#performance)

---

## App Types

### Window

Traditional 2D content. Glass material background. Coexists with other apps in the Shared Space.
Can mix in inline 3D content with Model3D.

```swift
WindowGroup { ContentView() }
```

### Volume (visionOS 1+)

A bounded 3D container where the developer controls the size along all 3 axes:

```swift
WindowGroup {
    Model3D(named: "Globe")
}
.windowStyle(.volumetric)
.defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)
```

- Coexists with other apps in the Shared Space
- visionOS 2: resizable (`.windowResizability(.contentSize)`)
- visionOS 2: `.volumeBaseplateVisibility`, `.onVolumeViewpointChange`

### ImmersiveSpace (visionOS 1+)

Infinite canvas. Only one can be open system-wide.

```swift
ImmersiveSpace(id: "solarSystem") {
    SolarSystem()
}
.immersionStyle(selection: $style, in: .mixed, .progressive, .full)
```

3 styles:
- **Mixed** (default): virtual overlay on top of reality
- **Progressive**: portal-style, immersion controlled with the Digital Crown
- **Full**: fully replaces passthrough

```swift
@Environment(\.openImmersiveSpace) var openImmersiveSpace
@Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

Task { await openImmersiveSpace(id: "solarSystem") }
```

**Design principle**: Always start in a window. Provide explicit controls for entering/exiting the immersive experience.

---

## SwiftUI on visionOS

### What Carries Over Automatically

All standard SwiftUI views, layout, navigation, gestures, animation, accessibility.

### visionOS-Specific

**Glass Material**:
```swift
.glassBackgroundEffect()
```

**Ornaments** (accessory elements outside the view):
```swift
.toolbar {
    ToolbarItem(placement: .bottomOrnament) { PlaybackControls() }
}
// Custom:
.ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .center) {
    HStack { /* content */ }.glassBackgroundEffect()
}
```

**Hover Effect** (required for interaction feedback):
```swift
.hoverEffect()
.contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 8))
```

**3D Padding**:
```swift
.padding3D(.back, 20)
```

**Others**:
- `.preferredSurroundingsEffect(.dark)` — darkens passthrough
- `.upperLimbVisibility(false)` — hides real hands

### Coordinate System

SwiftUI Y axis: down. RealityKit Y axis: up. Immersive Space origin: near the user's feet.

### TabView → Sidebar

On visionOS, TabView is placed vertically on the left side of the window and expands automatically on gaze. Preferred over a sidebar.

---

## RealityKit

### Model3D — Simple 3D Models (Similar to AsyncImage)

```swift
Model3D(named: "toy_robot") { model in
    model.resizable()
} placeholder: {
    ProgressView()
}
```

### RealityView — Complex 3D Scenes

```swift
RealityView { content in
    let entity = try await ModelEntity(named: "Earth")
    content.add(entity)
} update: { content in
    // Called only when SwiftUI state changes (not the render loop!)
} attachments: {
    Attachment(id: "label") {
        Text("Earth").padding().glassBackgroundEffect()
    }
}
```

- visionOS 1+, iOS 18+, macOS 15+ (cross-platform)
- visionOS 26: entities conform to the `Observable` protocol

### Entity Component System

- `ModelComponent` — 3D model
- `InputTargetComponent` + `CollisionComponent` — **both required** to receive gestures
- `HoverEffectComponent` — hover visual feedback
- `SpatialAudioComponent` — 3D positional audio

### Gestures on Entities

```swift
RealityView { content in /* ... */ }
    .gesture(TapGesture().targetedToAnyEntity())
```

### Materials

- `PhysicallyBasedMaterial` — PBR, responds to lighting
- `SimpleMaterial` — simple parameters
- `UnlitMaterial` — constant appearance
- `VideoMaterial` — video surface
- `ShaderGraphMaterial` — Reality Composer Pro / MaterialX

---

## Spatial Input

### Indirect Input (default, most comfortable)

Identify the target via eye tracking, select with a pinch gesture.
The app **does not** receive exact gaze coordinates (privacy). Only hover effect notifications.

### Direct Input

Directly touch nearby content. Suited to manipulation-focused experiences but causes arm fatigue.

### Hand Tracking (ARKit)

```swift
let provider = HandTrackingProvider()
// HandAnchor → HandSkeleton (27 joints)
```

- Requires explicit user authorization
- Only available in Full Space
- visionOS 2: display-rate delivery, prediction API

### Design Constraints

- Minimum touch target: **60pt**
- Use circular/capsule/rounded rectangle shapes (for gaze targeting)
- Place interactive content within a comfortable field of view

---

## Porting from iOS/iPadOS

### Applied Automatically

iPad variant preferred (iPhone also supported). The system applies native spacing, glass material, and hover effect.

### Required Changes

- Opaque backgrounds → **glass material** (`.glassBackgroundEffect()`)
- Bitmap assets → **vector assets** (scaling by distance)
- Add **`.hoverEffect()`** to interactive elements
- Fixed colors → **semantic/vibrancy colors**
- Sidebar → **TabView** (windows are not bound to screen bounds)
- No need to distinguish light/dark mode (adaptive vibrancy handles it automatically)

---

## Design Principles

- **Depth**: use it for visual hierarchy. Distant = large, close = small but prominent
- **Grounding shadow**: express spatial relationships with `GroundingShadowComponent`
- **Keep text flat**: 3D is for objects
- **Ergonomics**: horizontal layout, anchor content to the space (not to the user's viewpoint), avoid extreme angles
- **Accessibility**: support VoiceOver, Dwell Control, and Switch Control all

---

## Performance

### Rendering

- Declarative: describe the content → the system automatically renders both eyes
- Target frame rate: 90Hz
- Foveated rendering: high resolution in the gaze direction, low resolution in the periphery (automatic in RealityKit)

### Shared Space vs Full Space

- Shared Space: shares rendering resources with other apps, limited GPU
- Full Space: dedicated rendering resources, hides other apps

### Optimization

- `GroundingShadowComponent` (cheaper than full dynamic shadows)
- Image-Based Lighting (IBL)
- Fine geometry → large triangles + opacity textures (periphery)
- CompositorServices: only when a custom Metal pipeline is needed (most use RealityKit)
