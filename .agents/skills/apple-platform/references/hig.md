# Human Interface Guidelines Reference

## Table of Contents
1. [Core Principles](#core-principles)
2. [Platform-Specific Design Characteristics](#platform-specific-design-characteristics)
3. [Navigation Patterns](#navigation-patterns)
4. [Typography](#typography)
5. [Color](#color)
6. [Layout & Spacing](#layout--spacing)
7. [Accessibility](#accessibility)
8. [Material & Liquid Glass](#material--liquid-glass)
9. [Key Component Guidelines](#key-component-guidelines)

---

## Core Principles

- **Clarity**: Focus on text legibility, icon clarity, and function
- **Deference**: Fluid motion and a clean interface so content doesn't compete with the UI
- **Depth**: Convey hierarchy through visual layers and realistic motion

---

## Platform-Specific Design Characteristics

### iOS
- Medium-sized high-resolution display, viewed from 30-60cm
- Content-focused, minimize on-screen controls
- Place controls within thumb reach, in the middle/bottom area
- Support portrait + landscape, Dynamic Type, Dark Mode

### macOS
- Large display, viewed from 30-90cm, while seated
- More content with less nesting, fewer modalities
- Menu bar + keyboard shortcuts are essential
- High-precision input, customizable windows/toolbars

### watchOS
- Small display, on the wrist, within 30cm
- Brief interactions under 1 minute
- Digital Crown as the default navigation
- Always On Display; complications may be used more than the app itself

### tvOS
- Large display, viewed from 2.4m+
- Directional navigation via the focus system
- Edge-to-edge artwork, fluid animation
- Long sessions, PiP support

### visionOS
- Infinite canvas: windows, volumes, 3D objects
- Gaze + pinch input, direct touch
- Bring content to the user (never force them to move)
- Express hierarchy with glass material and depth

---

## Navigation Patterns

### Tab Bar
- Top-level section navigation (not actions — actions belong in the toolbar)
- Minimize the number of tabs, avoid a "More" tab
- Labels below/beside icons, filled SF Symbols
- Don't disable/hide tab buttons — explain why content is unavailable
- visionOS: Always vertical, symbol + short text required

### Sidebar
- Left side of the view, shows a flat hierarchy
- Avoid on iOS (consumes too much space)
- iPadOS: Can switch to a tab bar with the `sidebarAdaptable` style
- Keep hierarchy within 2 levels

### Split View
- Multiple adjacent panels
- Persistently highlight the current selection
- Drag and drop between panels

---

## Typography

### Default/Minimum Font Sizes

| Platform | Default | Minimum |
|--------|------|------|
| iOS/iPadOS | 17pt | 11pt |
| macOS | 13pt | 10pt |
| tvOS | 29pt | 23pt |
| visionOS | 17pt | 12pt |
| watchOS | 16pt | 12pt |

### System Fonts

- **SF Pro** — default for iOS, iPadOS, macOS, tvOS, visionOS
- **SF Compact** — watchOS
- **SF Mono** — fixed-width
- **New York** — serif, used alongside SF or on its own

### Weights

Prefer Regular, Medium, Semibold, Bold. Ultralight, Thin, and Light have legibility issues.

### Dynamic Type

Supported on iOS, iPadOS, visionOS, watchOS. tvOS supports it starting with tvOS 27 (not supported on macOS).
Layout must adapt at all sizes. Minimize truncation at large sizes. Consider a stacked layout at accessibility sizes.

---

## Color

### Use Semantic Colors

System color APIs instead of hardcoding:

**Background (iOS)**:
- `systemBackground`, `secondarySystemBackground`, `tertiarySystemBackground`
- `systemGroupedBackground`, `secondarySystemGroupedBackground`, `tertiarySystemGroupedBackground`

**Foreground**:
- `label`, `secondaryLabel`, `tertiaryLabel`, `quaternaryLabel`
- `placeholderText`, `separator`, `link`

### Color Space

sRGB is the standard. Display P3 on compatible displays. P3 is 16bit/channel. Asset catalogs provide per-color-space variants.

### Inclusive Design

- Don't rely on color alone — supplement with labels/shapes
- Consider cultural color meanings (red = danger in Western culture, positive in Chinese culture)

### Liquid Glass Color

Reflects the color behind the content. Apply color to glass material sparingly. Use colored backgrounds only for emphasis elements.

---

## Layout & Spacing

### Safe Area

The area not obscured by system components (toolbar, tab bar, Dynamic Island, etc.).
- tvOS: 60pt inset from every edge
- watchOS: The bezel provides natural padding

### Size Class

| Device | portrait | landscape |
|------|----------|-----------|
| iPad (all) | Regular × Regular | Regular × Regular |
| iPhone (portrait) | Compact × Regular | — |
| iPhone (landscape) | Varies by model | — |

Delay switching to a compact layout as long as possible.

### Key Device Sizes (portrait, pt)

- iPad Pro 12.9": 1024×1366
- iPhone 16 Pro Max: 440×956
- iPhone 16: 393×852
- iPhone SE: 320×568

### watchOS Controls

Max 2-3 per row (3 glyphs or 2 text items). Prefer full-width.

### visionOS

Minimum center-to-center spacing of **60pt** for interactive elements.

---

## Accessibility

### Color Contrast (WCAG AA)

- Text 17pt and under: **4.5:1** minimum
- 18pt+ or bold: **3:1** minimum

### Minimum Touch Target

| Platform | Default | Minimum |
|--------|------|------|
| iOS/iPadOS | 44×44pt | 28×28pt |
| macOS | 28×28pt | 20×20pt |
| tvOS | 66×66pt | 56×56pt |
| visionOS | 60×60pt | 28×28pt |
| watchOS | 44×44pt | 28×28pt |

### Spacing

~12pt around bezel elements, ~24pt around non-bezel elements

### Text Scaling

Support at least 200% scaling (watchOS: 140%)

### Reduce Motion

When enabled: reduce automatic animations, tighten springs, replace transitions with fades, avoid depth-axis animation

### Simple Gestures

Use simple gestures for common interactions. Always provide an alternative (swipe + on-screen button).

### VoiceOver

Accessibility labels on every element. Set appropriate traits on custom controls.

### visionOS Accessibility

- Dwell Control: hands-free selection by fixing gaze
- Place elements within the field of view
- Prefer horizontal layouts
- Limit fast movement/intensity

---

## Material & Liquid Glass

### Liquid Glass (iOS 26+, macOS Tahoe+)

A translucent dynamic material that behaves like real glass.

- **Regular**: blur, luminosity adjustment
- **Clear**: high transparency
- Scales from the smallest elements (buttons, switches) to large ones (tab bars, sidebars)
- Cross-platform: iOS, iPadOS, macOS, watchOS, tvOS

### App Icons (Liquid Glass)

Layered design + Liquid Glass effects (specular highlight, frosting, translucency).
6 automatic variants: default, dark, clear light, clear dark, tinted light, tinted dark.
Created with the Xcode Icon Composer tool.

### Standard Materials (iOS)

Ultra Thin, Thin, Regular, Thick — background blur levels.

### Vibrancy

Labels (4 levels), Fills (3 levels), Separators (1 level).

### visionOS Glass

Not customizable, automatically adapts to luminosity. No separate Dark Mode.

---

## Key Component Guidelines

### Button
- Minimum hit area 44×44pt (visionOS 60×60pt)
- Prominent style: max 1-2 per view
- 4 roles: Normal, Primary (accent), Cancel, Destructive (red)
- Never assign the Primary role to a destructive action
- visionOS: icon = circular, text = capsule, center spacing 60pt+

### Sheet
- A task scoped to the current context
- Cancel (left), Done (right), Back (hierarchical navigation)
- iOS: detents (large=full, medium=half), grabber
- Don't use for complex/long workflows or media content

### Alert
- Use only for important information requiring immediate attention — don't overuse
- Max 3 buttons
- Destructive styling: only for destructive actions not initiated by the user
- Most likely choice trailing, Cancel leading

### List
- iOS: grouped style + header/footer
- macOS: multi-column, sorting, resizing, alternating row colors
- Prioritize text display, keep items concise

### Progress Indicator
- When duration is known: determinate (progress bar / circular)
- When duration is unknown: indeterminate (spinning)
- Prefer determinate when possible
