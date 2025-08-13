# Scriptorium Gem Assets

This directory contains assets that are bundled with the Scriptorium gem.

## Directory Structure

```
assets/
├── icons/           # UI icons and interface elements
│   ├── back-arrow.png
│   ├── social/      # Social media icons
│   │   ├── twitter.png
│   │   ├── facebook.png
│   │   └── reddit.png
│   └── ui/          # UI interface icons
│       ├── menu.png
│       └── close.png
├── samples/         # Sample images for demos
│   ├── placeholder.jpg
│   ├── banner.jpg
│   └── avatar.png
├── themes/          # Theme-specific assets
│   └── standard/
│       ├── logo.png
│       └── favicon.ico
└── README.md        # This file
```

## Usage

These assets are automatically copied to the standard theme when a new repository is created. Users can:

1. **Override** any gem asset by placing a file with the same name in their theme's `assets/` directory
2. **Reference** gem assets using `$$asset[icons/back-arrow.png]` in templates
3. **Copy** gem assets to their local assets using the `copy_gem_asset_to_user` helper

## Asset Search Priority

1. Post assets (`posts/0001/assets/`)
2. View assets (`views/myview/assets/`)
3. **Theme assets** (`themes/standard/assets/`) ⭐ *NEW*
4. Global assets (`assets/`)
5. Library assets (`assets/library/`)
6. Gem assets (`assets/`) - *lowest priority*
