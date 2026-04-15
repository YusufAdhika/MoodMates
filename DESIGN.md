# Design System — Moodmates

## Product Context
- **What this is:** A Social-Emotional Learning (SEL) mobile game that teaches children to recognize and name emotions through three interactive mini-games.
- **Who it's for:** Indonesian kindergarteners ages 4–6 (primary), with parents and teachers as secondary users of the dashboard.
- **Space/industry:** Children's edugames, SEL, early childhood education.
- **Project type:** Flutter mobile app — portrait orientation, single-device use.

---

## Aesthetic Direction
- **Direction:** Playful-Warm
- **Decoration level:** Intentional — colored offset shadows make buttons feel tactile and pressable. No gradients, no decorative blobs.
- **Mood:** A child's first touchscreen game should feel like pressing big soft buttons, not tapping a form. Bold, physically inviting, warm. The parent dashboard is the same color family but calmer — same house, different room.

---

## Typography

- **Display / Game titles:** Baloo 2 (weight 700–800) — rounded letterforms, excellent multilingual support, designed to feel approachable. Used for screen titles, game card labels, greeting text, celebration messages.
- **Body / Parent UI:** DM Sans (weight 400–600) — clean, warm, informative. Used for descriptions, dashboard text, instructions, dialogs.
- **UI labels / Subtitles:** DM Sans 500 — same as body, slightly smaller.
- **Numbers / Stats:** DM Sans tabular-nums — for accuracy percentages, session counts, star counts in the parent dashboard.
- **Loading:** Google Fonts CDN for preview/web. For Flutter: add `baloo_2` and `dm_sans` packages (or bundle .ttf files in `assets/fonts/`).

### Scale
| Token | Size | Weight | Font | Usage |
|-------|------|--------|------|-------|
| display-xl | 28–36px | 800 | Baloo 2 | Hero greetings |
| display-lg | 22–26px | 700 | Baloo 2 | Game titles, celebration |
| display-md | 18–20px | 700 | Baloo 2 | Card labels, appbar |
| body-lg | 18px | 400 | DM Sans | Game descriptions, scenarios |
| body-md | 16px | 400/500 | DM Sans | Standard body text |
| body-sm | 13–14px | 400 | DM Sans | Subtitles, hints, captions |
| label | 11–12px | 700 | DM Sans | UPPERCASE section labels (letter-spacing: 1.5px) |

---

## Color System

### Approach: Zoned — three game colors that own their screens

| Token | Hex | Usage |
|-------|-----|-------|
| brand-orange | `#FF9A3C` | Primary brand, home screen header, parent appbar |
| background | `#FFF8E7` | App background, home screen, parent screens |
| text | `#3D2B1A` | All primary text |
| text-muted | `#8D6E63` | Secondary text, labels, hints |
| accent-gold | `#FFD54F` | Stars, celebrations, correct-answer highlights |

### Game Zones
Each mini-game owns its full color identity. When a child enters a game, the entire screen shifts to that game's zone color (appbar, background tint, card shadows). This creates spatial memory: "orange = face game, blue = camera game."

| Zone | Primary | Background | Shadow tint | Game |
|------|---------|------------|-------------|------|
| Emotion | `#FF9A3C` | `#FFF3E0` | `rgba(200,90,0,0.45)` | Kenali Emosi |
| Mirror | `#4BA3C3` | `#E8F4FD` | `rgba(20,100,160,0.40)` | Tiru Ekspresi |
| Social | `#4CAF6E` | `#F0F9F0` | `rgba(20,130,70,0.40)` | Situasi Sosial |

### Semantic Colors
| Token | Hex | Usage |
|-------|-----|-------|
| success | `#4CAF6E` | Correct answer border, confirmation |
| error | `#E53935` | Wrong answer border, destructive actions |
| warning | `#FF9A3C` | Same as brand orange — alerts, cautions |

### Dark mode
Reduce surface brightness: background `#261A10`, cards `#2E1F13`. Keep zone colors at full saturation — kids need high contrast. Reduce shadow opacity by ~30%.

---

## Spacing

- **Base unit:** 8px
- **Density:** Comfortable (children need breathing room between touch targets)

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, tight padding |
| sm | 8px | Internal card padding, row gaps |
| md | 16px | Standard section padding |
| lg | 24px | Screen edge padding |
| xl | 32px | Between major sections |
| 2xl | 48px | Hero breathing room |

### Touch targets
**Minimum 64dp** for all interactive elements in child-facing screens. Material Design minimum (48dp) is too small for ages 4–6. Parent screens may use 48dp minimums.

---

## Layout

- **Approach:** Grid-disciplined for game screens (predictable, no surprises for young children), editorial for parent dashboard (scannable, data-forward).
- **Grid:** 1-column for game screens, 2-column for choice grids (2×2 emotion cards).
- **Max content width:** Full-bleed on mobile (320–430px). No desktop layout required.
- **Border radius scale:**
  | Token | Value | Usage |
  |-------|-------|-------|
  | r-sm | 8px | Small UI elements, tags |
  | r-md | 12px | Buttons, input fields |
  | r-lg | 20px | Game cards, large containers |
  | r-xl | 24px | Celebration dialog, modals |
  | r-full | 9999px | Pills, circular buttons, PIN dots |

---

## Motion

- **Approach:** Intentional — bouncy entrance for celebration (spring curve), instant transitions for game actions (children notice and dislike latency).
- **Easing:** enter → `cubic-bezier(0.34, 1.56, 0.64, 1)` (spring, slight overshoot); exit → `ease-in`; move → `ease-in-out`.

| Token | Duration | Usage |
|-------|----------|-------|
| micro | 50–100ms | Tap feedback, button press |
| short | 150–200ms | Card reveal, state change |
| medium | 250–350ms | Screen transitions, dialog entrance |
| celebration | 500–700ms | Confetti, star bounce |

---

## Differentiating Design Choices

### 1. Colored Offset Shadows
Every interactive card and button uses an offset shadow tinted with its own zone color — not grey or black. An orange game card gets an amber-brown shadow (`rgba(200,90,0,0.45)`). A blue button gets a navy shadow. This creates a physically tactile, toy-like feel. Children respond to this.

**Flutter implementation:**
```dart
BoxShadow(
  color: zoneColor.withValues(alpha: 0.45),
  offset: const Offset(4, 6),
  blurRadius: 0, // hard offset, not blurred
)
```

### 2. Full Zone Color Shifts
Entering a game changes the screen's entire color identity: appbar background, page background tint, card shadows, all accents shift to that game's zone color. The home screen uses brand orange. The parent dashboard breaks the pattern with white/neutral treatment (signals "adult mode").

---

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-16 | Baloo 2 as display font | Rounded letterforms, excellent Indonesian/multilingual support, designed for approachability — right for ages 4–6 |
| 2026-04-16 | DM Sans as body font | Clean, warm, avoids the overused Inter/Roboto trap, good at small sizes for parent UI |
| 2026-04-16 | Colored offset shadows (not blurred) | Tactile feel, physically inviting for young children. Blurred shadows feel digital; hard offsets feel like objects |
| 2026-04-16 | Full zone color shifts per game | Spatial color memory for pre-readers — they learn the game by its color before they read the name |
| 2026-04-16 | 64dp minimum touch targets | Material 48dp is insufficient for ages 4–6. 64dp validated in children's UX research |
| 2026-04-16 | Initial design system created | Created by /design-consultation based on codebase analysis |
