# ThreadStock Visual Identity Contract

Version: 1.1  
Status: **canonical for implementation**  
Reference date: 17 September 2026

This document translates the approved ThreadStock visual references into implementation rules for Flutter, Figma handoff, Cursor, Antigravity and VS Code/Copilot. The attached approved screenshots and brand assets are the visual source of truth. When a token and a screenshot appear to disagree, preserve the screenshot's hierarchy and update the centralized token - do not hardcode a one-off color inside a feature.

## 1. Brand character

ThreadStock is a luxury fashion operations product, not a generic SaaS dashboard. Its visual language is **editorial fashion + calm enterprise software**:

- warm silk/ivory environment;
- near-black ink typography;
- antique champagne-gold accents;
- editorial serif display typography paired with a neutral sans-serif UI family;
- generous negative space;
- fine warm borders rather than heavy shadows;
- fashion photography and fabric texture used selectively;
- restrained status colors;
- high-density data only where the task requires it.

The primary product name is **ThreadStock**. `Atelier` may appear only where an approved product design explicitly uses it as an experience/theme label. Do not rename the product to Atelier OS in code, routes, analytics, database entities or new copy unless product requirements explicitly change.

## 2. Canonical brand assets

The blueprint pack includes:

- `assets/brand/threadstock-monogram.png` - compact TS monogram; use for app mark, splash mark and small brand placements.
- `assets/brand/threadstock-logo-lockup.png` - approved ThreadStock brand lockup reference.
- `assets/brand/threadstock-silk-background.png` - approved warm silk/fabric background.
- `assets/reference/desktop-overview-reference.png` - approved desktop application visual reference.
- `assets/reference/onboarding-team-reference.png` - approved onboarding visual reference.

Production preference: export the logo from the final Figma source as SVG for scalable UI use. Until a vector asset is available, use the supplied raster asset rather than recreating the monogram with a font.

### Approved visual references

![Approved ThreadStock desktop Overview reference](assets/reference/desktop-overview-reference.png)

![Approved ThreadStock Team onboarding reference](assets/reference/onboarding-team-reference.png)

### Asset rules

- Never recolor the monogram with arbitrary theme colors.
- Do not crop through the TS mark.
- Keep a minimum clear space around the mark equal to roughly one quarter of the mark width.
- Use the monogram alone at compact sizes; use the full lockup only where the wordmark is readable.
- Do not place the logo over high-contrast image detail without a quiet surface/scrim.
- Do not recreate the wordmark with `Text()` in Flutter when the approved lockup asset is intended.

## 3. Color system

The palette below is calibrated to the approved screenshots and supplied logo assets. All feature code must consume semantic design tokens; raw hex values must not be scattered through widgets.

### 3.1 Light theme - approved ThreadStock Atelier palette

| Semantic token | Hex | Usage |
|---|---:|---|
| `brand.ink` | `#12120E` | Logo ink, strongest brand dark |
| `brand.gold` | `#B69450` | Primary antique-gold accent, icon accents, rules, selected emphasis |
| `brand.goldSoft` | `#D6BE89` | Soft champagne details, subtle decoration |
| `brand.bronzeText` | `#7A582B` | Accessible small gold/bronze text on light surfaces |
| `surface.canvas` | `#F3EBE4` | Ambient warm canvas / main shell background |
| `surface.shell` | `#FAF6F1` | Sidebar, header, quiet navigation surfaces |
| `surface.primary` | `#FFFDFB` | Cards, tables, forms, main content surfaces |
| `surface.secondary` | `#FBF6EF` | AI briefing, secondary panels, inset surfaces |
| `surface.selected` | `#F3ECE4` | Selected nav/row/tile background |
| `surface.input` | `#FFFCF8` | Inputs and form fields |
| `text.primary` | `#171513` | Main UI text |
| `text.secondary` | `#6B655E` | Body/supporting copy |
| `text.muted` | `#918981` | Metadata, quiet labels |
| `text.inverse` | `#FFFDFB` | Text on dark actions |
| `border.subtle` | `#E7DCD1` | Hairlines and section separators |
| `border.default` | `#D9C8B7` | Inputs and interactive outlines |
| `border.brand` | `#C9A56A` | Selected/AI/brand outline when needed |
| `action.primary` | `#272624` | Primary action button |
| `action.primaryPressed` | `#151412` | Pressed/strong action state |
| `ai.surface` | `#FBF2E5` | Intelligence surface |
| `ai.border` | `#D8B980` | AI/recommendation outline |
| `focus.ring` | `#8A642B` | Accessible keyboard focus ring |

### 3.2 Semantic status colors

These are secondary to labels/icons. Never communicate status through color alone.

| State | Text/Icon | Surface |
|---|---:|---:|
| Success / Healthy | `#1F6F46` | `#EDF5EF` |
| Warning / Attention | `#9A5D14` | `#F9EEE1` |
| Critical / Stockout | `#9D3F3B` | `#F7E7E4` |
| Information | `#3E5F8C` | `#EEF3F8` |
| Neutral | `#625D57` | `#F1EEEA` |

### 3.3 Gold accessibility rule

`brand.gold #B69450` is a decorative/brand accent and does **not** have sufficient contrast for small body text on ivory/white. For small text, links, form labels or focus treatment use `brand.bronzeText #7A582B` or another tested accessible token. Never force the gold accent into text roles that reduce readability.

### 3.4 Dark companion theme

The approved references are light-first. Dark mode must preserve the same quiet luxury hierarchy rather than becoming black-and-gold gaming UI.

| Semantic token | Hex |
|---|---:|
| `surface.canvas` | `#0F0E0C` |
| `surface.shell` | `#14120F` |
| `surface.primary` | `#1B1814` |
| `surface.secondary` | `#211D18` |
| `surface.elevated` | `#29241E` |
| `text.primary` | `#F7F0E8` |
| `text.secondary` | `#B2A99F` |
| `text.muted` | `#817970` |
| `border.subtle` | `#302A23` |
| `border.default` | `#463A2E` |
| `brand.gold` | `#D6BE89` |
| `brand.bronzeText` | `#E0C998` |
| `action.primary` | `#F2E8DE` |
| `action.onPrimary` | `#171513` |

## 4. Typography

ThreadStock deliberately uses **two typography voices**.

### 4.1 Editorial/display family

Preferred implementation family: **Cormorant Garamond**.

Use for:

- onboarding hero titles;
- desktop page titles such as `Overview`;
- major greetings (`Good morning, Alex`);
- large financial/stock metrics when editorial emphasis is desired;
- premium section titles in low-density surfaces.

Do not use the serif family for tables, form labels, SKU data, filters, dense lists or long operational paragraphs.

Recommended styles:

| Style | Size / line | Weight | Usage |
|---|---|---:|---|
| Display XL | 48 / 52 | 600 | Welcome/onboarding hero |
| Display L | 40 / 44 | 600 | Desktop greeting/hero |
| H1 Editorial | 32 / 36 | 600 | Major page title |
| H2 Editorial | 26 / 31 | 600 | Major section title |
| H3 Editorial | 22 / 27 | 600 | Premium panel title |
| Metric Editorial | 34 / 38 | 600 | Revenue, inventory value, major totals |
| Mobile Display | 32 / 38 | 600 | Mobile hero/title when appropriate |

### 4.2 UI family

Preferred implementation family: **Inter**.

Use for:

- navigation;
- buttons;
- body copy;
- inputs and labels;
- tables;
- filters;
- chips/statuses;
- SKU/variant data;
- dialogs and system feedback.

Recommended styles:

| Style | Size / line | Weight |
|---|---|---:|
| UI Title | 20 / 26 | 600 |
| Section | 16 / 22 | 600 |
| Body Large | 16 / 24 | 400 |
| Body | 14 / 20 | 400 |
| Body Medium | 14 / 20 | 500 |
| Table | 13 / 18 | 400 |
| Label | 12 / 16 | 600 |
| Caption | 12 / 16 | 400 |
| Micro | 11 / 14 | 500 |
| Button | 14 / 18 | 600 |

Uppercase micro labels such as `THREADSTOCK AI BRIEFING` or onboarding step labels may use Inter 600 with approximately `0.04em` tracking.

### 4.3 Brand wordmark

Do not infer the wordmark font. The approved logo lockup is an asset. When the full logo is not used and plain product-name text is required in navigation, use Inter 600/700 with restrained tracking rather than attempting to imitate the logo artwork.

### 4.4 Font loading

- Bundle/pin approved font files or package versions; avoid runtime font downloads in production-critical surfaces.
- If Cormorant Garamond is unavailable during boot, use a metrically reasonable serif fallback without changing layout drastically.
- Keep Inter as the operational UI fallback before platform default.
- Do not ship different fonts on Windows and macOS simply because they are available on the platform; preserve ThreadStock identity.

## 5. Background and surface treatment

The silk asset is part of the ThreadStock identity but must not impair productivity.

### Onboarding, authentication and empty-business states

- Use `threadstock-silk-background.png` full-bleed with `BoxFit.cover`.
- Add a warm ivory scrim only as needed for predictable text contrast.
- Approved setup panels may use a softly translucent ivory surface (`surface.primary` at roughly 90-96% opacity) with a 1px warm border.
- A restrained backdrop blur (approximately 8-12 px) is acceptable on onboarding hero/setup panels only when performance is verified.

### Main application shell

- The silk texture may appear as a **quiet ambient layer**, not as a competing background.
- Apply an ivory scrim equivalent to roughly 82-90% opacity over the image before placing operational content.
- Tables, forms and data panels remain near-opaque (`surface.primary`) for readability.
- Do not put dense tables directly on a photographic/fabric background.

### Image intensity hierarchy

1. Onboarding/auth: strongest fabric presence.
2. Overview/empty state: subtle ambient fabric presence.
3. Inventory/Sales/Purchasing/Transfers/Settings: nearly flat warm canvas; texture is faint or absent behind data.
4. Scanner/camera: functional camera surface overrides brand background.

## 6. Surface geometry

- Standard card/panel radius: 12-14 px desktop.
- Onboarding/setup panel radius: 16-18 px.
- Mobile bottom sheet top radius: 20-24 px.
- Inputs: 8-10 px.
- Pills/chips: fully rounded only for short statuses/toggles, not every container.
- Default border: 1 px.
- Shadows: very soft or none. Prefer surface separation + warm border.

Do not make every section a card. The approved Overview uses cards for meaningful business objects while larger hierarchy comes from spacing and typography.

## 7. Primary actions

Primary buttons use near-black (`action.primary`) with warm-white text. Gold is not the default fill for primary buttons.

Gold is reserved for:

- AI/intelligence mark;
- selected accents;
- fine borders;
- arrow/icon detail inside premium actions;
- step indicators;
- small brand moments.

Secondary actions use a light surface and warm border. Tertiary actions are text/ghost controls.

## 8. Navigation

### Desktop

- Warm quiet sidebar surface.
- Selected navigation uses a subtle warm selected background; avoid a large gold fill.
- Primary application sections remain: Overview, Inventory, Sales, Purchasing, Transfers, AI Studio, Automations, Insights, Settings.
- Supplier/other subpages remain contextual according to the product blueprint; do not add new top-level destinations solely because a screenshot includes them.

### Mobile

Primary navigation remains `Home / Inventory / Scan / Sales / AI`.

Do not reproduce desktop sidebar hierarchy on phones.

## 9. AI visual language

AI must look native to ThreadStock, not like a generic chatbot brand.

- Use the antique-gold intelligence icon/accent.
- Use `ai.surface` + `ai.border` for briefings and prepared actions.
- Large AI text remains `text.primary`; do not make paragraphs gold.
- Avoid purple/blue AI gradients, neon glow, robot icons and excessive sparkles.
- The approved Overview `ThreadStock AI Briefing` pattern is the reference: editorial headline + concise evidence + action.

## 10. Charts and data visualization

- Primary series: antique gold/bronze.
- Secondary/reference series: warm graphite/gray.
- Positive financial delta: restrained green.
- Critical exceptions: restrained red only where required.
- Avoid rainbow charts.
- Keep gridlines very faint.
- Serif can be used for a major metric adjacent to a chart; axes, tooltips and labels remain Inter.

## 11. Form and onboarding style

Approved onboarding uses:

- full-bleed silk environment;
- editorial serif title;
- uppercase bronze step label;
- warm translucent/near-opaque setup panel;
- compact right-side explanation panel on desktop when useful;
- 5-step progress treatment with green completed states and antique-gold current step;
- near-black primary CTA;
- clear, sparse form controls.

Onboarding steps must remain operationally simple: Business -> Location -> Commerce -> Inventory -> Team.

## 12. Flutter implementation contract

Centralize theme implementation under the design system. Suggested names:

```text
TsColors
TsTextStyles
TsSpacing
TsRadius
TsBorders
TsShadows
TsAssets
TsTheme
```

Example semantic mappings:

```text
TsColors.brandInk          -> #12120E
TsColors.brandGold         -> #B69450
TsColors.brandBronzeText   -> #7A582B
TsColors.canvas            -> #F3EBE4
TsColors.shell             -> #FAF6F1
TsColors.surface           -> #FFFDFB
TsColors.surfaceSecondary  -> #FBF6EF
TsColors.textPrimary       -> #171513
TsColors.textSecondary     -> #6B655E
TsColors.borderSubtle      -> #E7DCD1
TsColors.primaryAction     -> #272624
```

Recommended font constants:

```text
TsFonts.display = Cormorant Garamond
TsFonts.ui      = Inter
```

Feature widgets must not contain private color constants that reproduce these values.

## 13. Visual QA checklist

Before a UI task is complete, verify:

- The supplied ThreadStock logo asset is used correctly.
- Display/editorial text uses the serif family only in approved roles.
- Operational text uses Inter.
- No bright yellow/generic gold has replaced antique gold.
- Small gold text has accessible contrast (use bronze text token).
- Silk background intensity matches the screen type.
- Data surfaces remain readable and nearly opaque.
- Borders are warm and quiet, not cool gray.
- Primary actions remain near-black.
- AI uses native ThreadStock gold/surface treatment.
- Status colors are restrained and include text/icon labels.
- Light/dark themes use semantic tokens, not duplicated hex values.
- Mobile and desktop preserve the same identity without sharing identical layouts.

## 14. Atelier Dropdown Design Contract

All dropdown menus across ThreadStock must strictly conform to the Atelier Dropdown visual architecture implemented in `lib/app/widgets/atelier_dropdown.dart`:

1. **Trigger Pill**:
   - Container: Height 36px, horizontal padding 10px, border-radius 8px.
   - Background: Warm parchment `#F3EDE3` with fine border `#DFD4C5` (transitions to `#BA8A55` when open).
   - Prefix Icon: Rich warm bronze `#8A6034` (e.g. `Icons.location_on_outlined`).
   - Label: Inter 13px, Medium (500), dark ink `#1E1C1A`.
   - Caret: Smooth chevron down/up toggle `#1E1C1A`.

2. **Floating Menu Overlay**:
   - Background: Warm ivory canvas `#FAF7F2`, border-radius 14px, border `#E5DACD` (1px).
   - Soft Elevation Shadow: `BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: Offset(0, 6))`.
   - Padding: 6px around list items.

3. **Menu Item Rows**:
   - Selected Item: Highlight background `#EFE6D9`, border-radius 8px, checkmark icon `#785125` trailing.
   - Icon Badge: 32x32px rounded container (`#E5D5C1` when selected, `#EFE6D8` otherwise) with `#785125` icon.
   - Title: Inter 13.5px, SemiBold (600) when selected, Medium (500) otherwise, `#1E1C1A`.
   - Subtitle: Inter 11.5px, Regular (400), `#7A7268`.

4. **Footer Action (Optional)**:
   - Separated by a thin 1px `#E5DACD` divider.
   - Action Row: Leading utility icon `#5E574E`, Inter 12.5px Medium text `#3B362F`, and trailing chevron `#8E867B`.

All future dropdowns must instantiate `AtelierDropdown<T>` rather than raw Material `DropdownButton`.

