# Test Images for BannerSVG

This directory contains test images for verifying image background functionality in BannerSVG.

## Expected Images

| Filename | Size | Aspect | Purpose |
|----------|------|--------|---------|
| `perfect.png` | 800x100 | 8:1 | Ideal case - matches default banner aspect |
| `wide.png` | 800x50 | 16:1 | Tests left/right cropping |
| `tall.png` | 100x100 | 1:1 | Tests top/bottom cropping |
| `very_tall.png` | 100x400 | 1:4 | Tests extreme vertical cropping |
| `very_wide.png` | 1600x100 | 16:1 | Tests extreme horizontal cropping |
| `small.png` | 200x25 | 8:1 | Tests scaling up of small images |
| `odd_aspect.png` | 500x123 | ~4:1 | Tests non-integer aspect ratios |

## Expected Behavior

- **Perfect match**: Image should display without cropping
- **Wide images**: Should crop left/right, center the image
- **Tall images**: Should crop top/bottom, center the image  
- **Small images**: Should scale up to fill the banner
- **All images**: Should use `preserveAspectRatio="xMidYMid slice"` for cropping

## Manual Testing

Run `ruby test/manual/test_banner_features.rb` to see these images in action with different banner configurations. 