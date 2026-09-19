# ThreadStock Design System Engineering Contract

Version: 1.1

The detailed visual identity is defined in [VISUAL_IDENTITY.md](VISUAL_IDENTITY.md). The approved brand assets and reference screenshots under `assets/` are part of the implementation contract.

## Product character

ThreadStock is **editorial fashion + calm enterprise software**: warm silk/ivory environments, near-black ink typography, antique champagne accents, an editorial serif display voice, neutral sans-serif operational UI and minimal decoration.

Do not reinterpret ThreadStock as a generic beige SaaS theme. The fabric background, logo, editorial typography and antique-gold detailing are deliberate brand elements.

## Canonical visual tokens

All UI must consume semantic tokens. Do not hardcode visual values inside feature widgets.

### Light

- Brand ink: `#12120E`
- Antique gold: `#B69450`
- Soft champagne: `#D6BE89`
- Accessible bronze text: `#7A582B`
- Canvas: `#F3EBE4`
- Shell/sidebar: `#FAF6F1`
- Primary surface: `#FFFDFB`
- Secondary/AI surface: `#FBF6EF`
- Primary text: `#171513`
- Secondary text: `#6B655E`
- Muted text: `#918981`
- Subtle border: `#E7DCD1`
- Default interactive border: `#D9C8B7`
- Primary action: `#272624`
- AI border: `#D8B980`

### Dark companion

- Canvas: `#0F0E0C`
- Shell: `#14120F`
- Primary surface: `#1B1814`
- Secondary surface: `#211D18`
- Elevated surface: `#29241E`
- Primary text: `#F7F0E8`
- Secondary text: `#B2A99F`
- Muted text: `#817970`
- Subtle border: `#302A23`
- Antique gold: `#D6BE89`

Semantic status colors are restrained and must not be the only status signal.

## Typography

ThreadStock uses two typography systems:

- **Cormorant Garamond** - editorial/display typography for onboarding hero titles, major page titles, greetings and selected high-level metrics.
- **Inter** - operational UI typography for navigation, body copy, forms, buttons, tables, filters, labels and dense data.

Do not use the serif family inside dense data tables or operational form controls. Do not recreate the brand wordmark with a font when the approved logo asset should be used.

## Brand assets

Use the assets in `assets/brand/`:

- `threadstock-monogram.png`
- `threadstock-logo-lockup.png`
- `threadstock-silk-background.png`

Prefer the final Figma SVG export for production logo rendering when available. The supplied assets are the current visual reference.

## Background behavior

- Onboarding/authentication: full-bleed silk background with warm contrast scrim as needed.
- Overview/empty states: subtle ambient silk background is allowed.
- Data-heavy pages: use mostly flat/near-opaque warm surfaces; fabric texture must not compete with tables/forms.
- Scanner: camera view is functional and takes precedence over brand background.

Avoid applying the fabric background uniformly at full intensity to every page.

## Layout rules

### Desktop

- Persistent compact sidebar and stable top bar.
- Main workspace uses hierarchy and spacing first.
- Cards/panels exist for real business objects, not every section.
- Data-heavy modules use professional tables and a contextual right inspector.
- Bulk actions appear when rows are selected.
- Keyboard navigation and visible focus are required.

### Mobile

Primary navigation: `Home / Inventory / Scan / Sales / AI`.

- One primary story per screen.
- Bottom sheets for selection, filters and lightweight edits.
- Full-screen pages for substantial workflows.
- Scanner is a first-class interaction surface.
- Never shrink desktop tables into phones; convert them to entity lists or grouped variant views.

## Spacing and geometry

Use an 8-point foundation with 4-point micro spacing. Prefer 16/24/32 for section rhythm.

- Standard desktop panel radius: 12-14 px.
- Onboarding/setup panel: 16-18 px.
- Input radius: 8-10 px.
- Mobile sheet top radius: 20-24 px.
- Default border: 1 px.
- Shadows are restrained; prefer warm borders and surface separation.

## Primary actions

Primary buttons use near-black `#272624` with warm-white text. Gold is an accent, not the default primary button fill.

Use antique gold for selected details, AI/intelligence marks, fine borders, progress steps and small premium emphasis.

## Components

Create/reuse canonical components for:

- buttons (primary, secondary, tertiary, ghost, danger);
- text/search/number/currency fields;
- selects and mobile selection sheets;
- tabs/segments/filter chips;
- status label;
- product thumbnail/row;
- color swatch/size chip/variant cell;
- data table + toolbar;
- mobile entity rows;
- metric display;
- AI insight/action/review;
- approval row;
- timeline/activity row;
- right inspector;
- bottom sheet/modal/drawer;
- toast/banner/empty/loading/error/offline states.

Do not create a one-off component if a documented component can be extended safely.

## AI visual language

AI uses the ThreadStock intelligence mark, antique-gold accent and warm quiet surface. Do not introduce purple/blue AI gradients, robot icons or excessive sparkles. Use large ink text for AI conclusions and gold for the intelligence signature rather than coloring whole paragraphs gold.

## Motion

- Fast: ~120-160 ms for press/selection/quantity changes.
- Standard: ~180-240 ms for popovers/inspectors/tabs.
- Slow: ~280-360 ms for large sheets/page transitions.

No playful bounce by default. Honor reduced-motion preference.

## Accessibility

- Target WCAG 2.2 AA contrast.
- `#B69450` is decorative and not suitable for small text on light surfaces; use accessible bronze text `#7A582B` for small accent text.
- Do not use color alone for status.
- Maintain comfortable mobile touch targets.
- All icon-only actions need accessible labels/tooltips.
- Desktop must be keyboard navigable.
- Layouts must tolerate text scaling, long translations and RTL.

## Internationalization

Never hardcode currency/date/number formatting. Support locale-aware currency, Indian and western grouping, decimal conventions, 12/24-hour time, RTL, time zones and country-specific address/tax structures.
