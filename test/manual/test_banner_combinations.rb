# Manual inspection tests for BannerSVG feature combinations
# 
# This file creates posts with sensible combinations of banner features,
# demonstrating how multiple features work together in realistic scenarios.
# The posts are displayed in a browser for visual inspection.
# 
# Usage:
#   ruby test_banner_combinations.rb          # Interactive mode with browser
#   ruby test_banner_combinations.rb --automated  # Automated mode for CI/AI testing
# 
# Combinations tested:
# - Professional Blue: Dark blue background with white bold centered text
# - Gradient Elegance: Purple gradient with white bold italic centered text
# - Warm Welcome: Yellow radial gradient with dark text, left-aligned
# - High Contrast: Black background with large white bold text
# - Reverse Contrast: White background with black text, right-aligned
# - Creative Gradient: Diagonal gradient with white bold centered text
# - Subtle Elegance: Light gray with dark italic text
# - Bold Statement: Red gradient with large white bold text
# - Modern Minimal: Light background with smaller dark text
# 
require_relative "./banner_environment"

# Create test banners for sensible combinations
create_banner_post(
  "Professional Blue", 
  "Clean and modern design",
  "back.color #1e3a8a\ntext.color #ffffff\ntitle.style bold\ntext.position center\ntitle.xy 50% 30%\nsubtitle.xy 50% 70%",
  "Professional Blue (White text, bold, centered)",
  "banner-combo-test"
)

create_banner_post(
  "Gradient Elegance", 
  "Smooth color transition",
  "back.linear #667eea #764ba2 lr\ntext.color #ffffff\ntitle.style bold italic\ntext.position center\ntitle.xy 50% 30%\nsubtitle.xy 50% 70%",
  "Gradient Elegance (Purple gradient, white text, bold italic, centered)",
  "banner-combo-test"
)

create_banner_post(
  "Warm Welcome", 
  "Friendly and inviting",
  "back.radial #fbbf24 #f59e0b\ntext.color #1f2937\ntitle.style bold\ntext.position left\ntitle.xy 10% 30%\nsubtitle.xy 10% 70%",
  "Warm Welcome (Yellow radial, dark text, bold, left-aligned)",
  "banner-combo-test"
)

create_banner_post(
  "High Contrast", 
  "Maximum readability",
  "back.color #000000\ntext.color #ffffff\ntitle.style bold\ntitle.scale 1.2\nsubtitle.scale 0.8\ntext.position center\ntitle.xy 50% 30%\nsubtitle.xy 50% 70%",
  "High Contrast (Black background, white text, bold, large, centered)",
  "banner-combo-test"
)

create_banner_post(
  "Reverse Contrast", 
  "Inverted color scheme",
  "back.color #ffffff\ntext.color #000000\ntitle.style bold\ntext.position right\ntitle.xy 90% 30%\nsubtitle.xy 90% 70%",
  "Reverse Contrast (White background, black text, bold, right-aligned)",
  "banner-combo-test"
)

create_banner_post(
  "Creative Gradient", 
  "Diagonal color flow",
  "back.linear #ff6b6b #4ecdc4 ul-lr\ntext.color #ffffff\ntitle.style bold\ntitle.scale 1.1\nsubtitle.scale 0.7\ntext.position center\ntitle.xy 50% 30%\nsubtitle.xy 50% 70%",
  "Creative Gradient (Diagonal gradient, white text, bold, centered)",
  "banner-combo-test"
)

create_banner_post(
  "Subtle Elegance", 
  "Understated beauty",
  "back.color #f8fafc\ntext.color #475569\ntitle.style italic\ntext.position center\ntitle.xy 50% 35%\nsubtitle.xy 50% 75%",
  "Subtle Elegance (Light gray background, dark text, italic, centered)",
  "banner-combo-test"
)

create_banner_post(
  "Bold Statement", 
  "Make an impact",
  "back.linear #dc2626 #7c2d12 tb\ntext.color #ffffff\ntitle.style bold\ntitle.scale 1.3\nsubtitle.scale 0.9\ntext.position center\ntitle.xy 50% 25%\nsubtitle.xy 50% 75%",
  "Bold Statement (Red gradient, white text, bold, large, centered)",
  "banner-combo-test"
)

create_banner_post(
  "Modern Minimal", 
  "Clean and simple",
  "back.color #f1f5f9\ntext.color #0f172a\ntitle.style bold\ntitle.scale 0.9\nsubtitle.scale 0.6\ntext.position left\ntitle.xy 5% 40%\nsubtitle.xy 5% 80%",
  "Modern Minimal (Light background, dark text, bold, left-aligned, smaller)",
  "banner-combo-test"
)

generate_front_page("banner-combo-test")

instruct <<~EOS
  BannerSVG Combination Tests
  
  This page displays posts with sensible feature combinations:
  - Professional Blue: Dark blue background with white bold centered text
  - Gradient Elegance: Purple gradient with white bold italic centered text
  - Warm Welcome: Yellow radial gradient with dark text, left-aligned
  - High Contrast: Black background with large white bold text
  - Reverse Contrast: White background with black text, right-aligned
  - Creative Gradient: Diagonal gradient with white bold centered text
  - Subtle Elegance: Light gray with dark italic text
  - Bold Statement: Red gradient with large white bold text
  - Modern Minimal: Light background with smaller dark text
  
  Each combination shows how multiple features work together.
  Check that gradients render properly, text positioning is correct,
  and the overall design looks cohesive and professional.
  
  The JavaScript should handle dynamic resizing when you resize the browser window.
EOS

examine("banner-combo-test") 