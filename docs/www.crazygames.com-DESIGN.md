---
version: alpha
name: Crazygames
description: |
  CrazyGames' design system embodies a vibrant, gaming-forward aesthetic set
  against a deeply immersive dark canvas. The visual identity radiates energy
  through bold typography, luminous accent colors, and layered gradients that
  evoke the excitement and variety of the game library. The palette balances a
  near-black background with bright, near-white text and energetic accent hues,
  creating high contrast and visual clarity. This is a system built for fast
  scanning, quick navigation, and celebratory moments—think arcade cabinets
  reimagined for the modern web. The design prioritizes playfulness through
  rounded interactive elements, vibrant decorative gradients, and generous use
  of interactive transforms that respond eagerly to user input.
source:
  url: "https://www.crazygames.com/vn/"
  pagesAnalyzed: 1
  extractedAt: 2026-11-02
  tokensMeasured: true
colors:
  primary: "#FFFFFF"
  canvas: "#0C0D14"
  on-primary: "#0F1A00"
  ink: "#FFFFFF"
  body: "#E5E6EE"
  muted: "#BDBFCE"
  accent-1: "#7361FF"
  accent-2: "#6842FF"
  accent-3: "#878A9E"
  accent-4: "#2F3148"
  accent-5: "#A48EFF"
  accent-6: "#C7FF5B"
  neutral-1: "#DCDFE8"
  neutral-2: "#EFF0F7"
typography:
  heading-sm:
    fontFamily: "APK Protocol"
    fontSize: 24px
    fontWeight: 900
    lineHeight: 1.29
    letterSpacing: 0px
  heading-xs:
    fontFamily: "APK Protocol"
    fontSize: 16.38px
    fontWeight: 900
    letterSpacing: 0px
  body-xl:
    fontFamily: "Artex SemiExtended"
    fontSize: 20px
    fontWeight: 700
    lineHeight: 1.4
    letterSpacing: 0px
  body-lg:
    fontFamily: "APK Protocol"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.25
    letterSpacing: 0px
  body-lg-strong:
    fontFamily: "APK Protocol"
    fontSize: 16px
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: 0px
  body-lg-2:
    fontFamily: "APK Protocol"
    fontSize: 16px
    fontWeight: 900
    letterSpacing: 0px
  body-md:
    fontFamily: "APK Protocol"
    fontSize: 14px
    fontWeight: 400
    letterSpacing: 0px
  button-md:
    fontFamily: "APK Protocol"
    fontSize: 16px
    fontWeight: 800
    letterSpacing: 0px
  button-sm:
    fontFamily: "APK Protocol"
    fontSize: 14px
    fontWeight: 700
    lineHeight: 1.43
    letterSpacing: 0px
  button-sm-strong:
    fontFamily: "APK Protocol"
    fontSize: 14px
    fontWeight: 800
    letterSpacing: 0px
  caption:
    fontFamily: "APK Protocol"
    fontSize: 12px
    fontWeight: 700
    lineHeight: 1.35
    letterSpacing: 0px
rounded:
  none: 0px
  xs: 16px
  sm: 22px
  full: 9999px
spacing:
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 20px
  xl: 32px
  xxl: 48px
  xxxl: 60px
  section: 68px
borderWidths:
  thin: 1px
  medium: 2px
shadows:
  sm: "rgba(0, 0, 0, 0.7) 0px 10px 30px 0px"
elevationStrategy: single-tier
themes:
  derived: light   # the other theme is the site's measured palette
  light:
    bg: "#FBFBFB"
    surface: "#F1F1F1"
    surfaceRaised: "#E9E9E9"
    text: "#1D1D1D"
    textMuted: "#707070"
    border: "#D8D8D8"
    accent: "#707070"
    accentFg: "#FFFFFF"
    focusRing: "#8F8F8F"
    elevation: shadow
  dark:
    bg: "#0C0D14"
    surface: "#0C0D13"
    surfaceRaised: "#1F2026"
    text: "#FFFFFF"
    textMuted: "#E5E6EE"
    border: "#292A30"
    accent: "#FFFFFF"
    accentFg: "#0B0B0C"
    focusRing: "#FFFFFF"
    elevation: "border+surface"
gradients:
  - context: section
    kind: linear
    value: "linear-gradient(285deg, rgb(23, 29, 46) 20%, rgb(21, 74, 111) 100%)"
  - context: section
    kind: linear
    value: "linear-gradient(285deg, rgb(23, 29, 46) 20%, rgb(104, 41, 77) 100%)"
  - context: section
    kind: linear
    value: "linear-gradient(285deg, rgb(23, 29, 46) 20%, rgb(31, 100, 92) 100%)"
  - context: section
    kind: linear
    value: "linear-gradient(285deg, rgb(23, 29, 46) 20%, rgb(88, 82, 44) 100%)"
  - context: section
    kind: linear
    value: "linear-gradient(285deg, rgb(23, 29, 46) 20%, rgb(46, 97, 54) 100%)"
  - context: section
    kind: linear
    value: "linear-gradient(285deg, rgb(23, 29, 46) 20%, rgb(61, 47, 115) 100%)"
components:
  button-filled:
    typography: "{typography.button-sm}"
    textColor: "{colors.on-primary}"
    height: 40px
    padding: "10px 14px 10px 14px"
    rounded: "{rounded.full}"
    backgroundColor: "{colors.accent-6}"
  button-primary:
    typography: "{typography.button-sm}"
    textColor: "{colors.ink}"
    height: 40px
    padding: "10px 10px 10px 10px"
    rounded: "{rounded.full}"
    backgroundColor: "rgba(255, 255, 255, 0.1)"
  button-filled-sm:
    typography: "{typography.button-sm-strong}"
    textColor: "{colors.accent-4}"
    height: 34px
    padding: "8px 16px 8px 16px"
    rounded: 30px
    backgroundColor: "rgb(249, 250, 255)"
  button-icon:
    textColor: "{colors.ink}"
    height: 28px
    fontSize: 13.3333px
    fontFamily: "APK Protocol"
    fontWeight: 400
  button-icon-lg:
    typography: "{typography.button-md}"
    textColor: "{colors.accent-5}"
    height: 48px
    rounded: 30px
  badge-filled:
    typography: "{typography.body-md}"
    textColor: "{colors.ink}"
    height: 18px
    padding: "0px 5.5px 0px 5.5px"
    rounded: "{rounded.full}"
    backgroundColor: "rgb(240, 0, 27)"
  badge-text:
    textColor: "{colors.body}"
    height: 28px
    fontSize: 16px
    fontFamily: "APK Protocol"
    fontWeight: 400
  navigation:
    typography: "{typography.body-md}"
    textColor: "{colors.ink}"
    backgroundColor: "{colors.canvas}"
  link:
    textColor: "{colors.ink}"
    fontSize: 14px
    fontFamily: "APK Protocol"
    fontWeight: 700
    rounded: "{rounded.xs}"
    backgroundColor: "rgba(255, 255, 255, 0.07)"
  link-sm:
    textColor: "{colors.ink}"
    fontSize: 14px
    fontFamily: "APK Protocol"
    fontWeight: 700
states:
  other-disabled:
    target: other
    state: disabled
    opacity: 0.4
  other-focus:
    target: other
    state: focus
    outline: none
  other-hover:
    target: other
    state: hover
    opacity: 1
  other-active:
    target: other
    state: active
    opacity: 0
  button-active:
    target: button
    state: active
    opacity: 0.7
breakpoints:
  - width: 375
    containerWidth: 375
    gridColumns: 8
    navLinksVisible: 22
    menuToggleVisible: false
    headingPx: 24
    bodyPx: 14
    sectionPaddingX: 0
  - width: 768
    containerWidth: 768
    gridColumns: 8
    navLinksVisible: 22
    menuToggleVisible: false
    headingPx: 24
    bodyPx: 14
    sectionPaddingX: 0
  - width: 1024
    containerWidth: 1024
    gridColumns: 8
    navLinksVisible: 22
    menuToggleVisible: false
    headingPx: 24
    bodyPx: 14
    sectionPaddingX: 0
  - width: 1280
    containerWidth: 1280
    gridColumns: 8
    navLinksVisible: 22
    menuToggleVisible: false
    headingPx: 24
    bodyPx: 14
    sectionPaddingX: 0
  - width: 1440
    containerWidth: 1440
    gridColumns: 8
    navLinksVisible: 22
    menuToggleVisible: false
    headingPx: 24
    bodyPx: 14
    sectionPaddingX: 0
coverage:
  statesFound: 61
  gradientsFound: 8
  rolesUnassigned: 8
  archetypesUnnamed: 0
  archetypesDetected: 0
  responsiveMeasured: true
  stylesheetsBlocked: true
  semanticRampDeclared: false
---

# Design System Inspired by CrazyGames

## 1. Visual Theme & Atmosphere

CrazyGames' design system embodies a vibrant, gaming-forward aesthetic set against a deeply immersive dark canvas. The visual identity radiates energy through bold typography, luminous accent colors, and layered gradients that evoke the excitement and variety of the game library. The palette balances a near-black background with bright, near-white text and energetic accent hues, creating high contrast and visual clarity. This is a system built for fast scanning, quick navigation, and celebratory moments—think arcade cabinets reimagined for the modern web. The design prioritizes playfulness through rounded interactive elements, vibrant decorative gradients, and generous use of interactive transforms that respond eagerly to user input.

**Key Characteristics**
- Dark, immersive canvas background with bright primary text
- Bold, energetic typography (APK Protocol and Artex SemiExtended)
- Luminous accent palette: purples, lime greens, and vibrant teal
- Rounded, pill-shaped interactive elements
- Layered linear gradients on section backgrounds for visual variety
- High contrast for accessibility and impact
- Generous, playful hover states with transforms and brightness shifts
- Game-card grid layout with consistent spacing and depth

## 2. Color Palette & Roles

### Primary
- **Primary / Brand** (`{colors.primary}` — `#FFFFFF`): Primary text, headings, active states, and brand accent. Used for maximum contrast against dark surfaces.
- **On Primary** (`{colors.on-primary}` — `#0F1A00`): Label and small text on brand-colored surfaces; rarely deployed due to the bright primary choice.

### Accent Colors (Decorative)
- **Accent Purple 1** (`{colors.accent-1}` — `#7361FF`): Decorative use in gradients and visual flourishes; no assigned semantic role.
- **Accent Purple 2** (`{colors.accent-2}` — `#6842FF`): Decorative use in gradients and visual flourishes; no assigned semantic role.
- **Accent Purple 3** (`{colors.accent-3}` — `#878A9E`): Decorative use in gradients and visual flourishes; no assigned semantic role.
- **Accent Dark Slate** (`{colors.accent-4}` — `#2F3148`): Decorative use in gradients and visual flourishes; no assigned semantic role.
- **Accent Lavender** (`{colors.accent-5}` — `#A48EFF`): Decorative use in gradients and visual flourishes; no assigned semantic role.
- **Accent Lime** (`{colors.accent-6}` — `#C7FF5B`): Decorative use in gradients and visual flourishes; no assigned semantic role.

### Interactive
- **CTA Fill** (`#C7FF5B`): Filled primary button background; high-contrast lime green for standout call-to-action elements.
- **CTA Overlay** (`rgba(255, 255, 255, 0.1)`): Semi-transparent white for secondary buttons; allows layering on dark backgrounds.

### Neutral Scale
- **Canvas** (`{colors.canvas}` — `#0C0D14`): Default page and surface background; deep near-black.
- **Body** (`{colors.body}` — `#E5E6EE`): Standard body copy and readable text.
- **Muted** (`{colors.muted}` — `#BDBFCE`): Captions, secondary text, and de-emphasized content.
- **Neutral 1** (`{colors.neutral-1}` — `#DCDFE8`): Light neutral; used in raised or highlighted surfaces.
- **Neutral 2** (`{colors.neutral-2}` — `#EFF0F7`): Brightest neutral; small text or minimal accents.

### Surface & Borders
- **Link Surface** (`rgba(255, 255, 255, 0.07)`): Semi-transparent white background for link cards; provides subtle containment without heavy fill.
- **Disabled Surface** (`rgba(47, 49, 72, 0.4)`): Dimmed interactive surface for disabled states; maintains legibility while signaling unavailability.

## 3. Typography Rules

### Font Family
- **Primary:** APK Protocol (black, bold, extra-bold weights)
- **Secondary:** Artex SemiExtended (bold weight)
- **Fallback stack:** system-ui, -apple-system, sans-serif

### Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Notes |
|---|---|---|---|---|---|---|
| Display / Heading (Large) | APK Protocol | 24px | 900 | 1.29 | 0px | Main page title and hero headings; ultra-bold for impact |
| Heading (Medium) | APK Protocol | 16.38px | 900 | not measured | 0px | Section headings and card titles |
| Body (Large) | Artex SemiExtended | 20px | 700 | 1.4 | 0px | Feature callouts and prominent text |
| Body (Large, Strong) | APK Protocol | 16px | 700 | 1.1 | 0px | Emphasized body paragraphs |
| Body (Large, Extra Bold) | APK Protocol | 16px | 900 | not measured | 0px | Strong emphasis body text |
| Body (Standard) | APK Protocol | 16px | 400 | 1.25 | 0px | Standard readable body copy |
| Body (Medium) | APK Protocol | 14px | 400 | not measured | 0px | Default body text and descriptions |
| Button (Medium) | APK Protocol | 16px | 800 | not measured | 0px | Large button labels |
| Button (Small) | APK Protocol | 14px | 700 | 1.43 | 0px | Standard button labels |
| Button (Small, Extra Bold) | APK Protocol | 14px | 800 | not measured | 0px | Emphasis button labels |
| Caption / Badge | APK Protocol | 12px | 700 | 1.35 | 0px | Small labels, badge text, and meta information |

### Principles
- **Weight hierarchy:** Weight drives emphasis more than size; APK Protocol's extended weight range (400–900) creates clear visual distinctions.
- **Line height:** Generous line heights (1.25–1.43) on body and button text ensure readability over dark backgrounds.
- **All caps / gaming aesthetic:** Bold, ultra-heavy weights and tight tracking reinforce the energetic, arcade-like character.
- **Contrast:** High-weight typography (700+) pairs with `{colors.primary}` (`#FFFFFF`) on dark `{colors.canvas}` for maximum clarity.

## 4. Component Stylings

### Buttons

#### Filled (Primary CTA)
- **Background:** `#C7FF5B` (lime green)
- **Text color:** `#0F1A00` (dark on-primary)
- **Padding:** `{spacing.sm}` 14px `{spacing.sm}` 14px (10px 14px)
- **Font:** APK Protocol, 14px, weight 700
- **Line height:** 1.43 (20px)
- **Border radius:** `{rounded.full}` (9999px, pill-shaped)
- **Border:** 0px (none)
- **Box shadow (default):** `rgba(0, 0, 0, 0) 0px 0px 0px 1.5px inset`
- **Hover:** Inset shadow remains; background color shifts to slightly darker shade
- **Active:** Inset shadow persists; background updates to active state color
- **Focus visible:** `2px solid` outline in button outline color; inset shadow in focus color
- **Disabled:** Opacity 0.4; background returns to default; inset shadow visible

#### Filled Small
- **Background:** `#F9FAFB` (near-white)
- **Text color:** `#2F3148` (dark slate)
- **Padding:** `{spacing.xs}` 16px `{spacing.xs}` 16px (8px 16px)
- **Font:** APK Protocol, 14px, weight 800
- **Border radius:** 30px
- **Border:** 0px (none)
- **Box shadow:** none

#### Primary (Secondary CTA)
- **Background:** `rgba(255, 255, 255, 0.1)` (semi-transparent white overlay)
- **Text color:** `#FFFFFF`
- **Padding:** `{spacing.sm}` `{spacing.sm}` `{spacing.sm}` `{spacing.sm}` (10px)
- **Font:** APK Protocol, 14px, weight 700
- **Line height:** 1.43 (20px)
- **Border radius:** `{rounded.full}` (9999px, pill-shaped)
- **Border:** 0px (none)
- **Box shadow (default):** `rgba(0, 0, 0, 0) 0px 0px 0px 1.5px inset`
- **Hover:** Opacity shifts; inset shadow updates
- **Active:** Opacity 0; background reverts to initial
- **Focus visible:** `2px solid` outline in button outline color; inset shadow in focus color
- **Disabled:** Opacity 0.4; inset shadow visible

#### Icon
- **Background:** transparent
- **Text color:** `#FFFFFF`
- **Width & height:** 28px
- **Padding:** 0px (no padding)
- **Font:** APK Protocol, 13.33px, weight 400
- **Border radius:** `{rounded.none}` (0px, sharp)
- **Border:** 0px (none)
- **Box shadow:** none

#### Icon Large
- **Background:** transparent
- **Text color:** `#A48EFF` (lavender accent)
- **Width:** 34.94px, **height:** 48px
- **Padding:** 0px
- **Font:** APK Protocol, 16px, weight 800
- **Border radius:** 30px
- **Border:** 0px (none)
- **Box shadow:** none

### Cards & Containers

#### Link Card / Game Card
- **Background:** `rgba(255, 255, 255, 0.07)` (semi-transparent white overlay)
- **Border:** `2px solid rgba(0, 0, 0, 0)` (initially transparent border)
- **Border radius:** `{rounded.xs}` (16px, soft rounded corners)
- **Padding:** varies by card type
- **Text color:** `#FFFFFF`
- **Font:** APK Protocol, 14px, weight 700
- **Hover:** Border color shifts to brand; opacity and scale adjustments applied
- **Active:** Border color fades; background effects vary by card variant

#### Link Card Small
- **Background:** transparent
- **Border:** 0px (none)
- **Border radius:** `{rounded.none}` (0px, sharp)
- **Text color:** `#FFFFFF`
- **Font:** APK Protocol, 14px, weight 700
- **Padding:** 0px

### Badges

#### Filled Badge
- **Background:** `#F0001B` (bright red)
- **Text color:** `#FFFFFF`
- **Width & height:** 18px
- **Padding:** 0px 5.5px 0px 5.5px
- **Font:** APK Protocol, 14px, weight 400
- **Border radius:** `{rounded.full}` (9999px, circle)
- **Border:** 0px (none)

#### Text Badge
- **Background:** transparent
- **Text color:** `{colors.body}` (`#E5E6EE`)
- **Font:** APK Protocol, 16px, weight 400
- **Border radius:** `{rounded.none}` (0px, no rounding)
- **Border:** 0px (none)
- **Padding:** 0px

### Navigation

#### Default Navigation (Sidebar / Menu)
- **Background:** `{colors.canvas}` (`#0C0D14`)
- **Text color:** `#FFFFFF`
- **Width:** 68px
- **Height:** 840px
- **Padding:** 0px
- **Font:** APK Protocol, 14px, weight 400
- **Border radius:** `{rounded.none}` (0px, sharp)
- **Border:** 0px (none)
- **Box shadow:** none

### Inputs

#### Input Focus State
- **Outline:** `2px solid` `#FFFFFF` (white outline on focus-visible)
- **Background:** Inherits from surface (typically dark canvas or overlay)
- **Text color:** `#FFFFFF`
- **Border radius:** `{rounded.full}` (9999px, pill-shaped for text inputs)

## 5. Layout Principles

### Spacing System
The spacing system follows an 8-base unit scale with clear progression for consistent rhythm:
- **`{spacing.xxs}`** = 4px — Micro gaps; icon padding, tight list item spacing
- **`{spacing.xs}`** = 8px — Small gaps; button padding, minor list separators
- **`{spacing.sm}`** = 12px — Standard gap; badge padding, minor content separation
- **`{spacing.md}`** = 16px — Default gap; button padding, card internal spacing
- **`{spacing.lg}`** = 20px — Large gap; section separators, heading underlines
- **`{spacing.xl}`** = 32px — Extra-large gap; feature block spacing
- **`{spacing.xxl}`** = 48px — Section spacing; major layout breaks
- **`{spacing.xxxl}`** = 60px — Jumbo spacing; page section margins
- **`{spacing.section}`** = 68px — Full section vertical padding; hero to content transitions

### Grid & Container
- **Column structure:** 8-column grid across all measured breakpoints (375px through 1440px)
- **Max content width:** Full viewport width (375px–1440px); no fixed max-width constraint observed
- **Section padding (horizontal):** 0px across all breakpoints; content edge-to-edge on mobile, expanding symmetrically on desktop
- **Consistent container model:** Sections fill viewport width; card grids adapt column count via CSS grid or flex wrapping without explicit breakpoint rule changes

### Whitespace Philosophy
Whitespace is deployed generously to create visual breathing room and establish clear hierarchy. Large vertical spacing (`{spacing.xxl}` and `{spacing.section}`) separates major content blocks, while tighter gaps (`{spacing.xs}` through `{spacing.md}`) maintain compact button groups and inline elements. The dark canvas background amplifies the visual impact of white text and bright accents, making whitespace feel less like emptiness and more like intentional containment. Section gradients (see Decorative Depth section) divide visual zones without hard lines, reinforcing spatial relationships.

### Border Radius Scale
- **`{rounded.none}`** = 0px — Sharp corners; icons, badges, images, navigation panels
- **`{rounded.xs}`** = 16px — Soft rounded corners; link cards, game tiles, container backgrounds
- **`{rounded.sm}`** = 22px — Medium rounding; button fills (non-pill buttons)
- **`{rounded.full}`** = 9999px — Pill-shaped / circular; primary buttons, secondary buttons, text input fields, icon badges

### Border Widths
- **Thin** (1px): Divider lines and subtle separators
- **Medium** (2px): Link card and interactive element borders; active or hover states on cards and buttons

## 6. Depth & Elevation

| Level | Treatment | Use |
|---|---|---|
| Flat | No shadow; transparent or light overlay background | Icons, badges, text labels, disabled states |
| Shallow (Inset) | `rgba(0, 0, 0, 0) 0px 0px 0px 1.5px inset` (clear/invisible inset) | Button default state; visual boundary without visual lift |
| Mid-Depth | `rgba(0, 0, 0, 0.7) 0px 10px 30px 0px` (dark shadow, 10px offset, 30px blur) | Button hover state; raised interactive prominence |
| Deep (Custom) | `rgb(29, 0, 104) 0px 10px 40px 0px` (purple-tinted shadow); `rgba(0, 0, 0, 0.57) 0px 0px 7px 1px` (tight glow) | Special hover states on premium buttons or decorative elements |

**Shadow Philosophy:**
The system employs a progressive depth model where elevation is subtle by default. Buttons and cards sit flat (`rgba(0, 0, 0, 0)` inset stroke) until interaction, at which point a generous dark shadow (`rgba(0, 0, 0, 0.7)`) creates clear visual feedback. The inset stroke is technically a 1.5px border rendered as an inset box-shadow, providing a hairline visual edge without CSS border overhead. Premium or accent buttons may deploy colored shadows (purple tints) to reinforce their special role. This approach keeps the interface clean at rest while ensuring interactive states feel responsive and tangible.

### Opacity Levels
- **30% (0.30):** Standard opacity reduction for decorative overlays, semi-transparent surfaces, and visual filters

### Z-index / Layering
- **Base (1, 2, 4, 5, 9):** Standard stacking for cards, containers, and default interactive elements
- **Dropdown (11, 12):** Menu overlays, tooltips, and contextual popovers; rises above base content

## 7. Do's and Don'ts

### Do
- Use `{colors.primary}` (`#FFFFFF`) for all primary text, headings, and active states; it is the system's workhorse for legibility and brand presence.
- Deploy rounded corners (`{rounded.full}` pill-shape for buttons; `{rounded.xs}` for cards) consistently to reinforce the energetic, modern gaming aesthetic.
- Pair dark backgrounds (`{colors.canvas}`) with high-weight typography (700–900 weight) to maximize contrast and readability.
- Apply hover states with transforms (`scale(1.1)`, `scale(1.2)`) and shadow shifts to give interactive elements tactile, responsive feedback.
- Use the 8-base spacing scale religiously; never invent intermediate values. Stick to `{spacing.xs}`, `{spacing.md}`, `{spacing.lg}`, etc.
- Leverage the accent palette (`{colors.accent-1}` through `{colors.accent-6}`) in section gradients and decorative backgrounds; these colors lack semantic roles and are purely visual flourishes.
- Implement lime green (`#C7FF5B`) for primary call-to-action buttons to ensure they command attention and feel celebratory.
- Maintain the inset box-shadow (`1.5px inset`) on buttons as a hairline edge; it reinforces button boundaries without heavy borders.

### Don't
- Do not invent semantic colors (error red, success green, warning amber). The system has no declared error/success/warning palette; use the neutral scale or accent colors for any secondary messaging.
- Do not break the 8-column grid structure; even at mobile, content organizes within 8 columns.
- Do not apply rounded corners to images or navigation panels; these components measure `{rounded.none}` (0px).
- Do not use anything other than APK Protocol or Artex SemiExtended for display and body text; substituting system fonts will break the bold, gaming-forward personality.
- Do not create new opacity levels outside of the 30% observed range; if opacity is needed for disabled or overlay states, default to 30% or 40%.
- Do not forget the inset box-shadow on buttons; it is a signature detail that differentiates this system from flat-button designs.
- Do not scale buttons or cards beyond a 1.2x multiplier on hover; the system reserves larger scales (1.6x, 2x) for special icon interactions.
- Do not apply borders to buttons unless the design explicitly calls for a 2px `rgba(0, 0, 0, 0)` transparent initial border (as on link cards).

## 8. Responsive Behavior

### Breakpoints

| Viewport Width | Content Column | Grid Columns | Heading Size | Body Size | Section Padding (X) |
|---|---|---|---|---|---|
| 375px (Mobile) | 375px | 8 | 24px | 14px | 0px |
| 768px (Tablet) | 768px | 8 | 24px | 14px | 0px |
| 1024px (Desktop) | 1024px | 8 | 24px | 14px | 0px |
| 1280px (Wide) | 1280px | 8 | 24px | 14px | 0px |
| 1440px (Ultra-Wide) | 1440px | 8 | 24px | 14px | 0px |

**Key observations:**
- Typography does not change across breakpoints; heading size remains 24px and body remains 14px from mobile through desktop.
- Grid column count is fixed at 8 across all breakpoints; responsive behavior is driven by grid-auto-flow and flex wrapping, not column redeclaration.
- Section horizontal padding is consistently 0px, indicating a full-bleed design philosophy where content spans edge-to-edge and whitespace is managed via card/container padding, not section insets.

### Touch Targets
- Minimum interactive element height: 28px (icons), 34px (small buttons), 40px (standard buttons, inputs)
- Minimum interactive element width: 28px (square icons), 40px+ (text buttons and inputs)
- Button padding ensures adequate tap area; combined with height, meets WCAG AAA touch target guidance.

### Collapsing Strategy
- **Grid cards:** Reflow via CSS grid `auto-fit` or flexbox wrapping; no breakpoint-triggered column changes observed because the 8-column grid already adapts proportionally.
- **Navigation:** No visible collapse from nav links to hamburger menu observed at 375px; "Nav links visible" and "Menu toggle" columns show no change, indicating the nav is either hidden by default at mobile or uses a different visibility strategy not captured in this extraction.
- **Padding & Margins:** Horizontal padding remains 0px across all widths; vertical spacing (`{spacing.md}`, `{spacing.lg}`, etc.) is consistent and does not compress at smaller viewports.
- **Typography:** No scaling; headings and body text maintain fixed pixel sizes across all breakpoints, relying on viewport width alone for adaptation.

## 9. Agent Prompt Guide

### Quick Color Reference
- **Primary CTA:** Lime Green (`#C7FF5B`) — filled primary buttons, standout interactive elements
- **Secondary CTA:** Semi-transparent White (`rgba(255, 255, 255, 0.1)`) — overlay buttons, secondary actions
- **Background (Canvas):** Dark Near-Black (`{colors.canvas}` — `#0C0D14`) — page background, main surface
- **Primary Text:** White (`{colors.primary}` — `#FFFFFF`) — headings, body text, labels, active states
- **Secondary Text:** Light Gray (`{colors.body}` — `#E5E6EE`) — body copy, standard legibility
- **Muted Text:** Medium Gray (`{colors.muted}` — `#BDBFCE`) — captions, de-emphasized content
- **Card Surface:** Semi-transparent White (`rgba(255, 255, 255, 0.07)`) — game cards, link tiles, content containers
- **Accent Decorative:** Purples, Lavender, Teal (`{colors.accent-1}` through `{colors.accent-5}`) — gradients, visual flourishes, no semantic role
- **Disabled Surface:** Dimmed Dark Slate (`rgba(47, 49, 72, 0.4)`) — disabled buttons and inputs

### Iteration Guide
1. **Always use `#FFFFFF` for primary text and headings** on `#0C0D14` backgrounds; this pairing is the system's highest-contrast foundation.
2. **Buttons are pill-shaped by default** (`{rounded.full}` — 9999px); apply inset box-shadow (`1.5px inset rgba(0, 0, 0, 0)`) as a hairline edge; filled buttons use `#C7FF5B` with dark on-primary text; secondary buttons use `rgba(255, 255, 255, 0.1)` overlay.
3. **Spacing follows the 8-base scale strictly:** `{spacing.xs}` (8px), `{spacing.md}` (16px), `{spacing.lg}` (20px), `{spacing.xl}` (32px), `{spacing.xxl}` (48px), `{spacing.section}` (68px). Button padding = `{spacing.sm}` 14px or `{spacing.xs}` 16px. Card padding varies by role.
4. **Typography is bold-forward:** APK Protocol at weight 700–900 dominates; Artex SemiExtended (700 weight) handles large body callouts. Body text is 14–16px; never drop below 12px except for icon sizing.
5. **Cards and containers measure `{rounded.xs}` (16px)** for soft rounding; icons and navigation are sharp (`{rounded.none}` — 0px); interactive overlays (buttons, inputs) are pill-shaped (`{rounded.full}` — 9999px).
6. **Hover states are generous and playful:** Apply `transform: scale(1.1)` to 1.2x on cards and buttons; shift box-shadow from `rgba(0, 0, 0, 0) inset` to `rgba(0, 0, 0, 0.7) 0px 10px 30px 0px` for depth; adjust opacity (0.8–0.9) on nested elements.
7. **Accent colors (purples, lavender, lime, teal) live in gradients and decorative zones only.** Do not assign them semantic meaning (error, success, warning). Refer to the eight gradient definitions for exact RGB stops.
8. **Grid layout is 8-column fixed** across all breakpoints (375px–1440px); reflow via flex/grid auto-fit, not breakpoint media queries for column changes.
9. **Dark mode is the only mode;** the system has no light-mode variant. All surfaces and text are optimized for dark backgrounds and bright text.
10. **Disabled buttons and inputs apply 40% opacity** and shift background to `rgba(47, 49, 72, 0.4)` or maintain default with reduced alpha. Always preserve the inset stroke so disabled buttons remain visibly interactive even if unavailable.

## 10. Known Gaps

- **Semantic color palette:** The site does not declare error, success, warning, or info colors in its markup. No status color ramp exists; use the neutral scale or accent palette for any secondary messaging.
- **Eight accent colors (purples, lavender, lime, teal) lack assigned semantic roles.** They are measured decorative colors used in section gradients and visual flourishes. Do not invent jobs for them (e.g., do not assume purple = warning).
- **Interaction states on hover/active/focus/disabled for some components are incomplete.** Button hover and active states were partially captured, but not all interactive elements (badges, navigation items, inputs) have full state telemetry. Some stylesheets were cross-origin and unreadable, so CSS-declared hover/focus/active details may be missing.
- **Light mode / dark mode toggle:** One page was analyzed. No switch or alternate theme was observed or measured. The system is presented as dark-only; any light-mode behavior is unmeasured.
- **Surfaces behind authentication:** The site was not logged in; areas or features requiring authentication were not visited or analyzed.
- **Granular button state colors:** Hover and active background color values are referenced as CSS variables (`var(--button-background-hover)`, `var(--button-background-active)`) in the extracted stylesheets, but the resolved hex or RGB values were not captured. Use the filled button baseline (`#C7FF5B`) and apply darkening/saturation shifts (e.g., `brightness(0.85)`) on interaction until the exact variables are resolved.
- **Link underline and visited states:** No explicit underline or visited color was measured; links are rendered as text with no visible underline decoration by default.
- **Form validation and error messaging:** No error border, error text color, or validation feedback was captured. The system may support these, but they were not present in the analyzed page.
- **Print styles and reduced-motion preferences:** No `@media print` or `prefers-reduced-motion` rules were observed or extracted.
- **Component-specific border-width usage:** Medium (2px) and thin (1px) borders are measured, but not all components that may use borders were comprehensively covered. Cards and buttons are well-documented; other elements may have border variants not captured.
- **Gradients on interactive hover states:** Section gradients are documented; whether buttons, cards, or other interactive elements apply gradient overlays or color shifts on hover is partially unknown due to CSS variable references.

---

**Document Version:** 1.0  
**Last Updated:** [Extraction Date]  
**Source:** CrazyGames (https://www.crazygames.com/vn/)  
**Coverage:** 1 page analyzed; 13 colors, 10 typography roles, 9 spacing scales, 4 border-radius values, 2 border-width values, 2 shadow treatments, 1 opacity level, 8 gradient definitions, and 5+ component patterns extracted.