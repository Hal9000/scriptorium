require_relative './environment'

manual_setup

# Create multiple views to test different banner integration scenarios
views = []

# Test 1: Simple banner in header
view1 = @repo.create_view("banner-simple", "Simple Banner Site", "A site with basic SVG banner in header")
File.open(view1.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
  f.puts "main"
end
view1.generate_empty_containers
File.open(view1.dir/:config/"header.txt", "w") do |f|
  f.puts "banner svg"
end
view1.generate_front_page
views << view1

# Test 2: SVG debug test (header only)
view2 = @repo.create_view("svg-debug", "SVG Debug Test", "Testing SVG insertion")
File.open(view2.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
end
view2.generate_empty_containers
File.open(view2.dir/:config/"header.txt", "w") do |f|
  f.puts "banner_svg"
end
File.open(view2.dir/:config/"config.txt", "w") do |f|
  f.puts "# Simple debug config"
  f.puts "back.radial #FF0000 #0000FF"
  f.puts "title.color #FFFFFF"
  f.puts "subtitle.color #FFFF00"
  f.puts "title.style bold"
  f.puts "subtitle.style italic"
end
view2.generate_front_page
views << view2

# Test 3: Complex header with multiple elements
view3 = @repo.create_view("complex-header", "My Awesome Blog", "Exploring the Power of SVG Banners")
File.open(view3.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
  f.puts "main"
end
view3.generate_empty_containers
File.open(view3.dir/:config/"header.txt", "w") do |f|
  f.puts "banner_svg"
  f.puts "title"
  f.puts "subtitle"
end
File.open(view3.dir/:config/"config.txt", "w") do |f|
  f.puts "# Complex SVG Banner Configuration"
  f.puts "# This exercises multiple features at once"
  f.puts ""
  f.puts "# Background: Radial gradient from purple to blue"
  f.puts "back.radial #8B5CF6 #3B82F6"
  f.puts ""
  f.puts "# Custom aspect ratio (wider banner)"
  f.puts "aspect 6.0"
  f.puts ""
  f.puts "# Custom font"
  f.puts "text.font Georgia serif"
  f.puts ""
  f.puts "# Title styling: Bold, larger scale, custom color"
  f.puts "title.scale 1.2"
  f.puts "title.style bold"
  f.puts "title.color #FFFFFF"
  f.puts "title.align center"
  f.puts ""
  f.puts "# Subtitle styling: Italic, smaller scale, different color"
  f.puts "subtitle.scale 0.6"
  f.puts "subtitle.style italic"
  f.puts "subtitle.color #E5E7EB"
  f.puts "subtitle.align center"
  f.puts ""
  f.puts "# Custom positioning for both title and subtitle"
  f.puts "title.xy 50% 45%"
  f.puts "subtitle.xy 50% 75%"
end
view3.generate_front_page
views << view3

# Test 4: Empty header (placeholder test)
view4 = @repo.create_view("empty-header-test", "Empty Header Test", "Testing placeholder text")
File.open(view4.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
  f.puts "main"
end
view4.generate_empty_containers
File.open(view4.dir/:config/"header.txt", "w") do |f|
  # Empty file - should trigger placeholder
end
view4.generate_front_page
views << view4

instruct <<~EOS
  Banner Integration Tests
  
  This test demonstrates different banner integration scenarios:
  
  1. banner-simple: Basic SVG banner in header with main content
  2. svg-debug: Header-only layout with red-to-blue radial gradient banner
  3. complex-header: Multiple header elements with sophisticated banner styling
  4. empty-header-test: Empty header to verify placeholder text behavior
  
  Each view tests different aspects of banner integration:
  - Simple banner insertion
  - Header-only layouts
  - Complex styling combinations
  - Placeholder text handling
EOS

examine views