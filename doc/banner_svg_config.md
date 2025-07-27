# BannerSVG Configuration Options

This document describes all configuration options available for customizing SVG banners using BannerSVG.

---

## Background Options

### `back.color <color>`
Solid color background.
- Example: `back.color #FF6B6B`

### `back.linear <start> <end> [direction]`
Linear gradient background.
- `start`, `end`: Colors (hex or CSS names)
- `direction` (optional):
  - `lr` (left-right, default)
  - `tb` (top-bottom)
  - `ul-lr` (upper-left to lower-right)
  - `ll-ur` (lower-left to upper-right)
- Example: `back.linear #FF6B6B #4ECDC4 lr`

### `back.radial <start> <end> [cx cy r [ar]]`
Radial gradient background.
- `start`, `end`: Colors
- `cx`, `cy`: Center (default: `50% 50%`)
- `r`: Radius (default: `50%`)
- `ar`: Aspect ratio compensation (default: `1/aspect` for circular vignette)
  - Example: `back.radial #FF6B6B #4ECDC4 50% 50% 150%`
  - Example with custom aspect: `back.radial #FF6B6B #4ECDC4 75% 25% 60% 0.5`

### `back.image <url>`
Image background. The image should match the banner's aspect ratio for best results.
- Example: `back.image /assets/banner.jpg`

---

## Banner Geometry

### `aspect <number>`
Set the banner's aspect ratio (width/height).
- Example: `aspect 5.0` (for a 5:1 banner)

---

## Font and Text Options

### `text.font <font-family>`
Set the font family for both title and subtitle.
- Example: `text.font Verdana`

### `text.color <color>`
Set the default text color for both title and subtitle.
- Example: `text.color #222222`

### `title.color <color>` / `subtitle.color <color>`
Set the color for title or subtitle individually.
- Example: `title.color #FF0000`

### `title.scale <number>` / `subtitle.scale <number>`
Scale the font size for title or subtitle (relative to base size).
- Example: `title.scale 1.2`

### `title.style <style>` / `subtitle.style <style>`
Set font style for title or subtitle. Options: `bold`, `italic`, or both.
- Example: `title.style bold italic`

### `title.align <direction> [x y]` / `subtitle.align <direction> [x y]`
Align title or subtitle. Directions: `left`, `center`, `right`. Optionally override x/y positions.
- Example: `title.align center`
- Example: `subtitle.align right 95% 80%`

### `title.xy <x> <y>` / `subtitle.xy <x> <y>`
Set explicit x/y coordinates for title or subtitle (overrides align).
- Example: `title.xy 50% 52%`

### `text.align <direction>`
Set alignment for both title and subtitle at once.
- Example: `text.align center`

---

## Advanced/Other Options

### `preserve_aspect <value>`
Override the SVG's `preserveAspectRatio` attribute. Usually not needed.
- Example: `preserve_aspect xMidYMid slice`

---

## Example Config

```
# BannerSVG Example Config
aspect 5.0
back.radial #FF6B6B #4ECDC4 50% 50% 150%
text.font Verdana
text.color #222222

title.color #FFFFFF
title.scale 1.2
title.style bold italic
title.align center

title.xy 50% 52%
subtitle.color #4ECDC4
subtitle.scale 0.6
subtitle.style italic
subtitle.align right 95% 80%
```

---

For more details or advanced usage, see the code or ask for help! 