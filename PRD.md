# harmony — Product Requirements Document

## Overview

**harmony** is a private, couple-only mobile app for collecting and revisiting shared memories. Two people — and only two — use the app to build a visual diary of their relationship through swipeable photo cards with notes and dates.

---

## Design Language

| Token        | Value       | Usage                          |
|--------------|-------------|-------------------------------|
| Background   | `#000000`   | App background                 |
| Card         | `#121212`   | Card surfaces                  |
| Secondary    | `#1A1A1A`   | Input backgrounds, borders     |
| Primary      | `#FF7070`   | Accents, icons, badges         |
| Accent       | `#C1FF00`   | CTAs, glow effects             |
| Foreground   | `#FFFFFF`   | Main text                      |
| Muted FG     | `#888888`   | Timestamps, secondary labels   |

**Fonts:** Figtree (body) · Jost (headings) · Playfair Display (serif notes) · JetBrains Mono (mono details)

**Corner radius:** 2rem base, 3rem on cards

**Visual style:** Dark, minimal, cinematic. Frosted glass overlays on card badges. Subtle card stack depth effect (rotated shadow card behind main card).

---

## Core Features (v1)

### 1. Memory Card Stack (Home Screen)
- Full-screen swipeable card stack (Tinder-style)
- Each card shows a **photo** filling the card
- **Date badge** (top-left, frosted glass pill): e.g. `AUG 22, 2024`
- **Location badge** (bottom-left, frosted glass pill): e.g. `Berlin` (optional)
- Subtle background card peeking behind (-2deg rotation, 0.98 scale)
- Swipe **right** → heart/favourite (visual feedback)
- Swipe **left** → next card
- Tap card → open memory detail
- **Bottom controls:** Dismiss (×), big Heart button (primary CTA), Share

### 2. Memory Detail View
- Full-screen photo at top
- Date + location pills
- **Note text** in Playfair Display italic, large and airy
- "Added X ago" timestamp in mono/uppercase tracking
- Edit button

### 3. Add Memory
- Pick photo from gallery or take a photo
- Set date (defaults to today)
- Set location (optional, free text for now)
- Write a note (free text)
- Save → card appears at top of stack

### 4. Settings Screen
- Partner name / your name configuration
- App theme accent color picker (future)
- Export memories (future)

---

## Data Model

```dart
class Memory {
  final String id;          // UUID
  final String photoPath;   // Local file path
  final DateTime date;      // Memory date
  final String? location;   // Optional location string
  final String? note;       // Optional note text
  final DateTime createdAt; // When it was added to the app
  final bool isFavourite;   // Hearted or not
}
```

---

## Technical Stack

| Layer         | Choice                                      |
|---------------|---------------------------------------------|
| Framework     | Flutter (iOS + Android primary)             |
| State Mgmt    | Riverpod                                    |
| Local DB      | Hive (fast, no-setup NoSQL for local data)  |
| Image Picking | image_picker                                |
| Image Storage | Local app documents directory               |
| Swipe Cards   | Custom gesture detector (or `appinio_swiper`) |
| Routing       | go_router                                   |
| Fonts         | google_fonts                                |

---

## Screens

```
/ (home)          → Card stack
/add              → Add new memory
/memory/:id       → Memory detail
/settings         → Settings
```

---

## Implementation Phases

### Phase 1 — Foundation (current sprint)
- [x] PRD
- [ ] Project setup: dependencies, theme, fonts, routing
- [ ] Data layer: Hive model + repository
- [ ] Home screen: swipeable card stack with sample data
- [ ] Add memory screen: photo picker + form
- [ ] Memory detail screen

### Phase 2 — Polish
- [ ] Swipe animations with rotation + opacity feedback
- [ ] Heart/dismiss animations on swipe
- [ ] Onboarding: enter names for both partners
- [ ] Favourite filter (see only hearted memories)
- [ ] Empty state illustrations

### Phase 3 — Extras
- [ ] Timeline view (scrollable list by date)
- [ ] Anniversary countdown widget
- [ ] Memory of the day (random daily card)
- [ ] Haptic feedback on swipe actions
- [ ] Share memory as image card
- [ ] iCloud / Google Drive backup

---

## Out of Scope (v1)
- No backend, no auth, no accounts
- No multi-user sync — app lives on both phones independently
- No video support (photos only)
- No push notifications

---

## Success Criteria
The app is a success if opening it feels like opening a warm, intimate photo album — not a productivity tool. Every interaction should feel personal, smooth, and slightly magical.
