# Talay Design System - MASTER

## 1. Core Identity
- **Name**: Talay
- **Product Type**: Team Management & Workshop Coordination
- **Target Audience**: Tech teams, workshop-based organizations, SMEs.
- **Vibe**: Futuristic, High-tech, Clean, Professional, Immersive.

## 2. Visual Style: Futuristic Dark Glassmorphism
- **Background**: OLED-optimized deep navy/black (#020617).
- **Cards**: Glassmorphic Bento Grid style.
  - Background: `rgba(255, 255, 255, 0.05)` (frosted)
  - Backdrop Blur: `20px`
  - Border: `1px solid rgba(255, 255, 255, 0.1)`
  - Shadow: Soft multi-layered glow (`0 8px 32px rgba(0, 0, 0, 0.3)`)
- **Corners**: Rounded `24px`.
- **Accents**: Subtle neon glows (Cyan & Purple).

## 3. Color Palette: Quantum Night
- **Background**: `#020617`
- **Primary (Cyan)**: `#00FFFF` (User interaction, primary buttons)
- **Secondary (Purple)**: `#7B61FF` (Hierarchy, secondary actions)
- **Accent (Magenta)**: `#FF00FF` (Alerts, highlights)
- **Success**: `#00E676`
- **Warning**: `#FBBF24`
- **Text Primary**: `#F8FAFC`
- **Text Secondary**: `#94A3B8`

## 4. Typography: Geometric Modern
- **Heading Font**: `Outfit` (Sans-serif) - Bold, futuristic geometry.
- **Body Font**: `Work Sans` (Sans-serif) - Highly readable.
- **Hierarchy**:
  - H1: 32px / Bold / 1.2 line-height
  - H2: 24px / Semi-bold / 1.3 line-height
  - Body: 16px / Regular / 1.5 line-height
  - Small: 12px / Medium / 1.4 line-height

## 5. Components & UI Elements
- **Navigation**: Floating bottom navigation bar with glassmorphic background & active indicator glow.
- **Buttons**:
  - Primary: Cyan gradient, 12px rounded, white text.
  - Secondary: Glassmorphic with purple border.
- **Indicator**: Compass-style direction indicator for dashboard.
- **Map**: Dark-themed map (Mapbox style) with cyan/purple location markers.
- **Cards**: Bento Grid layout for dashboard.

## 6. Micro-animations
- **Transitions**: Smooth `300ms` ease-in-out.
- **Hover/Touch**: Subtle scale `1.02` and increase in glow brightness.
- **Loading**: Pulse animation on glassmorphic skeletons.

## 7. UX Principles
- **One-hand usage**: All primary actions within bottom 40% of screen.
- **Hierarchy**: Use depth (Z-index/Glass layering) to show focus.
- **Visual Feedback**: Neon pulse on success, magenta subtle bloom on error.
