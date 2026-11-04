# Design System Inspired by Bumble

## 1. Visual Theme & Atmosphere

Bumble's design system radiates warmth, optimism, and approachability through a distinctive palette anchored by energetic golden yellows and complemented by sophisticated neutrals. The visual language balances playful energy with professional clarity, creating a welcoming yet trustworthy environment. Bold typography, generous spacing, and carefully rounded corners establish a modern, friendly aesthetic that feels both premium and accessible. The design celebrates connection and safety—core to Bumble's mission—through deliberate use of accent colors that draw focus to primary actions while maintaining elegant restraint in the neutral backbone.

**Key Characteristics:**

- Warm, optimistic color story centered on golden yellow as the signature accent
- Clean, contemporary typography with generous line heights for readability
- Rounded corner language (16px radius) that feels approachable and modern
- High contrast between dark text and bright backgrounds for clarity and accessibility
- Subtle shadows and elevation create depth without heaviness
- Balanced spacing that encourages visual breathing room
- Safety-focused green accents signal trust and positive outcomes

## 2. Color Palette & Roles

### Primary

- **Signature Yellow** (`#FFDB5B`): The dominant brand accent used for hero sections, call-to-action backgrounds, and highlights. Conveys optimism and draws immediate visual attention.
- **Golden Amber** (`#C38F00`): Darker yellow tone used for interaction states, hover effects, and secondary emphasis. Provides depth variation within the yellow family.

### Accent Colors

- **Coral Orange** (`#FF6224`): Supporting accent for secondary highlights, badges, and supporting call-to-action elements. Adds warmth and energy.
- **Teal Accents** (`#AECFC2`, `#5EAE91`, `#228F67`, `#038153`, `#186146`): Gradient range of green-teal tones used in accent cards, supporting visual elements, and thematic sections. Ranges from light muted teal to deep forest green.

### Interactive

- **Link Text** (`#202020`): Primary interactive text uses the dark charcoal, maintaining hierarchy and scannability.
- **Button Text** (`#202020`): Default button text in dark charcoal for high contrast and accessibility.
- **Ghost Button Border** (`#202020`): Transparent backgrounds with charcoal borders for secondary actions.

### Neutral Scale

- **Charcoal Dark** (`#202020`): Dominant text color across headings, body copy, and UI elements. Primary foreground color used 502 times, establishing strong visual hierarchy.
- **Medium Gray** (`#575656`): Secondary text for supporting copy, hints, and reduced-emphasis labels.
- **White** (`#FFFFFF`): Pure white for contrast-rich backgrounds and floating surfaces.
- **Light Gray** (`#F3F3F3`): Subtle background for input fields, cards, and grouped content areas.
- **Off-White** (`#F8F9F9`): Softer background alternative for secondary surfaces.
- **Black** (`#000000`): Pure black for maximum contrast in specific critical elements.

### Surface & Borders

- **Default Surface** (`#FFFFFF`): Primary container background for cards, modals, and floating elements.
- **Soft Surface** (`#F3F3F3`): Secondary surface for grouped sections and input backgrounds.
- **Light Teal Surface** (`#EDF8F4`): Gentle background for teal-themed content sections or accent areas.
- **Teal Border** (`#D1E8DF`): Subtle border or divider in teal-accented sections.

### Semantic / Status

- **Success Green** (`#00A656`): Positive confirmation states, success messages, and validated actions.
- **Warning Orange** (`#F79A3E`): Alert states, cautions, and informational warnings requiring user attention.

## 3. Typography Rules

### Font Family

**Primary Font:** BumbleSans (or system sans-serif stack: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`)

**Secondary Font:** Same as primary for consistency across all text roles.

### Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Notes |
|------|------|------|--------|-------------|----------------|-------|
| Display / H2 | BumbleSans | 68px | 600 | 70px | 0px | Hero headlines, page titles |
| Heading 1 | BumbleSans | 32px | 400 | 48px | 0px | Section headers, primary headings |
| Body / Paragraph | BumbleSans | 20px | 400 | 25px | 0px | Long-form content, descriptions |
| Link / Navigation | BumbleSans | 17px | 500 | 22px | 0px | Primary links, navigation items, buttons |
| Span / Caption | BumbleSans | 15px | 400 | 22.5px | 0px | Secondary text, labels, supporting copy |
| Input / Form | BumbleSans | 16px | 400 | 18.4px | 0px | Form field placeholder and value text |

### Principles

- **Generous Line Height:** All text uses elevated line heights (1.4x–2.4x font size) to maximize readability and create visual breathing room.
- **Weight Hierarchy:** Font weight restraint (primarily 400 and 500) maintains elegance; 600 reserved for maximum emphasis only.
- **Scale-Driven:** Typography follows a strict modular scale to ensure visual coherence and rhythm.
- **Accessibility First:** Large base sizes (minimum 16px for inputs, 15px for UI text) ensure readability across all users and devices.
- **Consistent Family:** Single typeface system eliminates cognitive friction and strengthens brand identity.

## 4. Component Stylings

### Buttons

#### Primary Button
- **Background:** `#FFDB5B` (Signature Yellow)
- **Text Color:** `#202020` (Charcoal Dark)
- **Font Size:** `17px`
- **Font Weight:** `500`
- **Padding:** `14px 24px`
- **Border Radius:** `16px`
- **Border:** `0px none`
- **Height:** `50px`
- **Line Height:** `22px`
- **Box Shadow:** `none`
- **Hover State:** Background `#C38F00` (Golden Amber), text remains `#202020`
- **Active State:** Background darkens to `#A87600`, text `#202020`
- **Disabled State:** Background `#F3F3F3`, text `#575656`, cursor not-allowed

#### Secondary Button
- **Background:** `rgba(0, 0, 0, 0)` (transparent)
- **Text Color:** `#202020` (Charcoal Dark)
- **Font Size:** `17px`
- **Font Weight:** `500`
- **Padding:** `14px 24px`
- **Border:** `2px solid #202020` (Charcoal Dark)
- **Border Radius:** `16px`
- **Height:** `50px`
- **Line Height:** `22px`
- **Box Shadow:** `none`
- **Hover State:** Background `#F3F3F3`, text `#202020`, border `#202020`
- **Active State:** Background `#E8E8E8`, text `#202020`
- **Disabled State:** Border `#D1D1D1`, text `#575656`, cursor not-allowed

#### Ghost Button
- **Background:** `rgba(0, 0, 0, 0)` (transparent)
- **Text Color:** `#202020` (Charcoal Dark)
- **Font Size:** `17px`
- **Font Weight:** `500`
- **Padding:** `14px 24px`
- **Border:** `0px none`
- **Border Radius:** `16px`
- **Height:** `50px`
- **Line Height:** `22px`
- **Text Decoration:** underline
- **Hover State:** Background `rgba(32, 32, 32, 0.05)`, text `#202020`
- **Active State:** Background `rgba(32, 32, 32, 0.1)`, text `#202020`

#### Accent Button (Coral)
- **Background:** `#FF6224` (Coral Orange)
- **Text Color:** `#FFFFFF` (White)
- **Font Size:** `17px`
- **Font Weight:** `500`
- **Padding:** `14px 24px`
- **Border Radius:** `16px`
- **Height:** `50px`
- **Line Height:** `22px`
- **Hover State:** Background `#E34A10`, text `#FFFFFF`
- **Active State:** Background `#CC3F0D`, text `#FFFFFF`

### Cards & Containers

#### Content Card
- **Background:** `#FFFFFF` (White)
- **Border:** `0px none`
- **Border Radius:** `12px`
- **Padding:** `24px`
- **Box Shadow:** `rgba(32, 32, 32, 0.12) 0px 1px 8px 0px`
- **Text Color:** `#202020` (Charcoal Dark)

#### Section Card (Light Gray)
- **Background:** `#F3F3F3` (Light Gray)
- **Border:** `0px none`
- **Border Radius:** `12px`
- **Padding:** `24px`
- **Box Shadow:** `none`
- **Text Color:** `#202020` (Charcoal Dark)

#### Accent Card (Teal)
- **Background:** `#EDF8F4` (Light Teal Surface)
- **Border:** `1px solid #D1E8DF` (Teal Border)
- **Border Radius:** `12px`
- **Padding:** `24px`
- **Box Shadow:** `none`
- **Text Color:** `#202020` (Charcoal Dark)

#### Hero Section
- **Background:** `#FFDB5B` (Signature Yellow)
- **Border Radius:** `20px`
- **Padding:** `80px 40px`
- **Text Color:** `#202020` (Charcoal Dark)
- **Box Shadow:** `none`

### Inputs & Forms

#### Text Input
- **Background:** `#F3F3F3` (Light Gray)
- **Text Color:** `#202020` (Charcoal Dark)
- **Placeholder Color:** `#575656` (Medium Gray)
- **Font Size:** `16px`
- **Font Weight:** `400`
- **Padding:** `14px 40px` (left padding increased for icon space)
- **Border:** `0px none`
- **Border Radius:** `16px`
- **Height:** `48px`
- **Line Height:** `18.4px`
- **Focus State:** Background `#FFFFFF`, border `2px solid #FFDB5B`, box-shadow `0px 0px 0px 3px rgba(255, 219, 91, 0.2)`
- **Error State:** Background `#FFF5F0`, border `2px solid #FF6224`, text `#202020`
- **Disabled State:** Background `#EEEEEE`, text `#A0A0A0`, cursor not-allowed

#### Search Input
- **Background:** `#FFFFFF` (White)
- **Text Color:** `#202020` (Charcoal Dark)
- **Icon Color:** `#575656` (Medium Gray)
- **Font Size:** `16px`
- **Padding:** `14px 48px 14px 40px` (icon space on both sides)
- **Border:** `0px none`
- **Border Radius:** `16px`
- **Height:** `48px`
- **Line Height:** `18.4px`
- **Box Shadow:** `rgba(32, 32, 32, 0.08) 0px 2px 6px 0px`
- **Focus State:** Border `2px solid #FFDB5B`, text `#202020`

#### Form Label
- **Font Size:** `15px`
- **Font Weight:** `500`
- **Color:** `#202020` (Charcoal Dark)
- **Line Height:** `22.5px`
- **Margin Bottom:** `8px`

#### Form Help Text
- **Font Size:** `13px`
- **Font Weight:** `400`
- **Color:** `#575656` (Medium Gray)
- **Margin Top:** `4px`

### Navigation

#### Top Navigation Bar
- **Background:** `rgba(255, 255, 255, 0.8)` (White with transparency)
- **Text Color:** `#202020` (Charcoal Dark)
- **Font Size:** `15px`
- **Font Weight:** `400`
- **Padding:** `16px 24px`
- **Height:** `50px`
- **Box Shadow:** `rgba(32, 32, 32, 0.12) 0px 1px 12px 0px`
- **Border Radius:** `0px`
- **Backdrop Filter:** `blur(10px)` (optional, for glass effect)

#### Navigation Link
- **Color:** `#202020` (Charcoal Dark)
- **Font Size:** `15px`
- **Font Weight:** `400`
- **Text Decoration:** none
- **Padding:** `8px 12px`
- **Hover State:** Color `#575656`, background `rgba(0, 0, 0, 0.05)`, border-radius `8px`
- **Active State:** Color `#FFDB5B`, font-weight `500`

#### Navigation Link (Secondary)
- **Color:** `#202020` (Charcoal Dark)
- **Font Size:** `15px`
- **Font Weight:** `400`
- **Text Decoration:** underline
- **Padding:** `0px`
- **Hover State:** Color `#575656`
- **Active State:** Color `#202020`, font-weight `500`

#### Sign In Button (Navigation)
- **Background:** `#202020` (Charcoal Dark)
- **Text Color:** `#FFFFFF` (White)
- **Font Size:** `15px`
- **Font Weight:** `500`
- **Padding:** `12px 20px`
- **Border Radius:** `8px`
- **Border:** `0px none`
- **Height:** `auto`
- **Hover State:** Background `#000000`, text `#FFFFFF`

#### Expandable List Item
- **Background:** `#F3F3F3` (Light Gray)
- **Text Color:** `#202020` (Charcoal Dark)
- **Font Size:** `17px`
- **Font Weight:** `400`
- **Padding:** `16px 20px`
- **Border Radius:** `8px`
- **Border:** `0px none`
- **Margin Bottom:** `12px`
- **Chevron Icon:** `#575656` (Medium Gray)
- **Chevron Icon (Active):** `#202020` (Charcoal Dark)
- **Hover State:** Background `#EEEEEE`, text `#202020`

### Badges & Tags

#### Success Badge
- **Background:** `#E8F5E9`
- **Text Color:** `#00A656` (Success Green)
- **Font Size:** `13px`
- **Font Weight:** `500`
- **Padding:** `6px 12px`
- **Border Radius:** `12px`
- **Border:** `0px none`

#### Warning Badge
- **Background:** `#FFF3E0`
- **Text Color:** `#F79A3E` (Warning Orange)
- **Font Size:** `13px`
- **Font Weight:** `500`
- **Padding:** `6px 12px`
- **Border Radius:** `12px`
- **Border:** `0px none`

### Links

#### Primary Link (Underlined)
- **Color:** `#202020` (Charcoal Dark)
- **Font Size:** `15px`
- **Font Weight:** `400`
- **Text Decoration:** underline
- **Padding:** `0px`
- **Hover State:** Color `#575656`, text-decoration underline
- **Active State:** Color `#202020`, font-weight `500`

#### CTA Link (Button Style)
- **Background:** `#202020` (Charcoal Dark)
- **Text Color:** `#FFFFFF` (White)
- **Font Size:** `17px`
- **Font Weight:** `500`
- **Padding:** `16px 24px`
- **Border Radius:** `0px`
- **Border:** `0px none`
- **Height:** `54px`
- **Line Height:** `22px`
- **Hover State:** Background `#000000`, text `#FFFFFF`
- **Active State:** Background `#1A1A1A`, text `#FFFFFF`

## 5. Layout Principles

### Spacing System

**Base Unit:** `8px`

**Spacing Scale:**
- `8px` – tight spacing for icon-only elements, minimal gaps
- `12px` – small gaps between form elements, compact sections
- `16px` – default padding for cards, input internals, small containers
- `20px` – navigation and button internal padding variations
- `24px` – standard card padding, section spacing, component margins
- `28px` – medium-large gaps between related content blocks
- `32px` – large section separators, major layout divisions
- `36px` – extra spacing for emphasis
- `40px` – section internal padding, container breathing room
- `80px` – hero section padding, full-width section spacing
- `120px` – maximum internal padding for very large sections
- `156px` – top-level layout margins for full-page spacing

**Usage Context:**
- Gaps between inline elements: `8px`–`16px`
- Card padding: `24px`–`40px`
- Section margins: `32px`–`80px`
- Hero section padding: `80px` (vertical), `40px` (horizontal)
- Container padding: `40px`–`120px`

### Grid & Container

- **Max Container Width:** `1280px` (desktop), `100%` (mobile/tablet with side padding)
- **Column Strategy:** 12-column flexible grid with gutter `24px`
- **Side Padding:** `24px` (mobile), `40px` (tablet), `80px` (desktop)
- **Section Pattern:** Full-width colored backgrounds with centered content container inside
- **Hero Section:** Full-width, centered content, asymmetric padding (80px top/bottom, 40px left/right)
- **Card Grid:** 3-column grid on desktop, collapses to 1–2 columns on smaller screens

### Whitespace Philosophy

Bumble's design philosophy embraces generous whitespace as a tool for clarity and focus. Every element benefits from breathing room; section spacing is uniform and predictable, establishing visual rhythm. Cards and content blocks float within spacious containers rather than filling greedily. The abundant use of `24px`–`40px` padding and `32px`–`80px` margins creates a premium, uncluttered aesthetic that prioritizes user comprehension and reduces cognitive load.

### Border Radius Scale

- `0px` – full-width bars, full-bleed sections, specific UI cases
- `8px` – secondary buttons, input focus states, small card elements
- `12px` – cards, containers, medium components
- `16px` – primary buttons, input fields, navigation elements, major components
- `20px` – hero sections, large featured containers, accent backgrounds

## 6. Depth & Elevation

| Level | Treatment | Use |
|-------|-----------|-----|
| Flat (Base) | No shadow, `box-shadow: none` | Background surfaces, flat sections, body text areas |
| Raised (Small) | `rgba(32, 32, 32, 0.12) 0px 1px 8px 0px` | Content cards, dropdowns, subtle lift |
| Elevated (Medium) | `rgba(32, 32, 32, 0.12) 0px 1px 12px 0px` | Navigation bar, modal headers, primary containers |
| Floating (Large) | `rgba(32, 32, 32, 0.16) 0px 4px 16px 0px` | Modals, floating action buttons, maximum prominence |

**Shadow Philosophy:**

Bumble uses subtle, reserved shadows to create spatial separation without visual heaviness. Shadows are always dark-based (`#202020` at low opacity) and employ soft blur to feel natural and approachable rather than harsh. Elevation is used sparingly—most components remain flat or use minimal shadows. The approach prioritizes clarity and reduces visual clutter while establishing a clear hierarchy. Shadows increase in intensity and blur radius as components rise in z-order, creating a coherent depth system that aids in user understanding of interactive hierarchy and focus states.

## 7. Do's and Don'ts

### Do

- **Use the signature yellow (`#FFDB5B`) strategically** for primary actions and hero highlights; it's the brand's most recognizable accent.
- **Maintain 16px minimum font size** for all body text to ensure accessibility across all viewing contexts.
- **Apply consistent 24px padding** to cards and 32px+ margins between sections for visual rhythm.
- **Pair charcoal text (`#202020`) with white or light backgrounds** for maximum contrast and readability.
- **Round corners to 16px on buttons and inputs** to maintain the friendly, modern aesthetic.
- **Use the teal accent family (`#038153`–`#AECFC2`)** for supporting sections, secondary highlights, and thematic grouping.
- **Test hover and focus states** on all interactive elements to ensure sufficient color contrast.
- **Embrace generous whitespace** to create a premium, uncluttered appearance.
- **Use box-shadow sparingly** (`0px 1px 8px` for raised, `0px 1px 12px` for elevated) to avoid visual noise.
- **Implement clear status colors** – green (`#00A656`) for success, orange (`#F79A3E`) for warnings.

### Don't

- **Don't overuse the signature yellow**—reserve it for primary CTAs and hero sections; excessive use dilutes impact.
- **Don't decrease font sizes below 15px** for UI labels or 16px for inputs; prioritize readability.
- **Don't use pure black (`#000000`) as primary text**—charcoal (`#202020`) is the correct choice for body copy.
- **Don't apply border-radius < 8px** for interactive elements; maintain the friendly, rounded aesthetic.
- **Don't mix accent colors arbitrarily**; use the defined teal family and coral orange intentionally, not randomly.
- **Don't create buttons without adequate padding** (minimum `14px 24px`); insufficient spacing feels cramped.
- **Don't apply heavy shadows** (blur > 12px, spread > 0px) to non-modal components; keep elevation subtle.
- **Don't use light gray backgrounds (`#F3F3F3`) for primary content**; reserve for secondary surfaces and inputs.
- **Don't neglect focus states**; every interactive element must have a clear focus indicator for accessibility.
- **Don't reduce line-height below 1.4x font size**; generous line heights improve readability and visual comfort.

## 8. Responsive Behavior

### Breakpoints

| Name | Width | Key Changes |
|------|-------|-------------|
| Mobile | 360px–767px | Single-column layout, full-width cards, 24px side padding, 32px section margins, font sizes remain consistent |
| Tablet | 768px–1024px | 2-column grid, cards stack vertically in groups, 40px side padding, 24px card gutter |
| Desktop | 1025px–1280px | 3-column grid, full layout width, 80px side padding, 24px card gutter, all hover states active |
| Large Desktop | 1281px+ | Max-width container `1280px` centered with side margins, full feature set |

### Touch Targets

- **Minimum Interactive Size:** `44px × 44px` (buttons, links, form controls)
- **Recommended Interactive Size:** `50px × 50px` (primary buttons, navigation items)
- **Minimum Spacing Between Targets:** `8px` to prevent accidental mis-taps
- **Form Input Height:** `48px` minimum for comfortable touch interaction
- **Navigation Link Padding:** `12px` vertical, `16px` horizontal for touch-friendly targets

### Collapsing Strategy

- **Hero Section:** Padding reduces from `80px 40px` (desktop) to `48px 24px` (mobile); text size remains but reflows
- **Card Grid:** 3 columns (desktop) → 2 columns (tablet) → 1 column (mobile)
- **Navigation:** Horizontal nav bar (desktop) → horizontal scrollable (tablet) → hamburger menu (mobile < 640px)
- **Spacing:** `80px` section margins reduce to `40px` (tablet), `32px` (mobile)
- **Side Padding:** `80px` desktop → `40px` tablet → `24px` mobile
- **Hero Text:** Heading stays responsive; paragraph text reflows naturally
- **Inputs:** Width adjusts from `100%` desktop to `100%` mobile with full-width layout
- **Buttons:** Width expands to full container width on mobile for accessibility
- **Footer:** Multi-column grid (desktop) → 2-column (tablet) → single column (mobile)

## 9. Agent Prompt Guide

### Quick Color Reference

- **Primary CTA:** Signature Yellow (`#FFDB5B`) – Use for primary actions, hero backgrounds, and maximum emphasis
- **Secondary CTA:** Golden Amber (`#C38F00`) – Hover state for yellow buttons and supporting accents
- **Accent CTA:** Coral Orange (`#FF6224`) – Alternative accent for secondary highlights
- **Primary Text:** Charcoal Dark (`#202020`) – All headings, body copy, and default text
- **Secondary Text:** Medium Gray (`#575656`) – Supporting copy, hints, and reduced-emphasis labels
- **Background:** White (`#FFFFFF`) – Primary container and floating surfaces
- **Secondary Background:** Light Gray (`#F3F3F3`) – Input fields, secondary cards, grouped sections
- **Success State:** Success Green (`#00A656`) – Confirmation messages and positive feedback
- **Warning State:** Warning Orange (`#F79A3E`) – Alerts, cautions, and attention-requiring states
- **Neutral Border:** Teal Border (`#D1E8DF`) – Subtle divisions and accent section borders
- **Accent Surface:** Light Teal (`#EDF8F4`) – Background for teal-themed sections

### Iteration Guide

1. **Always use `#FFDB5B` (Signature Yellow) for primary buttons and hero sections** — this is Bumble's most distinctive color and drives brand recognition.

2. **Apply `#202020` (Charcoal Dark) as the universal text color for contrast and readability** — never use pure black (`#000000`) for body text.

3. **Maintain minimum `16px` font size for inputs and `15px` for UI labels** — accessibility is non-negotiable across all screen sizes.

4. **Use `16px` border-radius on all buttons and input fields** — this rounded aesthetic is core to Bumble's friendly, modern identity.

5. **Implement `24px` default padding inside cards and `32px`+ margins between sections** — consistent spacing creates visual rhythm and premium feel.

6. **Reserve box-shadow to `rgba(32, 32, 32, 0.12) 0px 1px 8px 0px` for cards and `0px 1px 12px 0px` for navigation** — keep shadows subtle to avoid visual clutter.

7. **Apply line-height of 1.4x–2.4x font size (e.g., 22px for 16px text)** — generous line height dramatically improves readability and visual comfort.

8. **Use the green-teal family (`#038153`–`#AECFC2`) for supporting accents and thematic grouping**, never as primary UI.

9. **Implement success green (`#00A656`) and warning orange (`#F79A3E`) consistently for status and feedback states** — semantic colors must not vary.

10. **Test all components at mobile (360px), tablet (768px), and desktop (1280px) breakpoints** — responsive behavior must maintain brand integrity and usability at all sizes.