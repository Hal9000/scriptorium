require_relative './environment'

manual_setup

# Create multiple views to test different radial gradient scenarios
views = []

# Test 1: Custom radial gradient with custom center and radius
view1 = @repo.create_view("radial-custom", "Custom Radial Test", "Testing custom radial gradient parameters")
File.open(view1.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
end
view1.generate_empty_containers
File.open(view1.dir/:config/"header.txt", "w") do |f|
  f.puts "banner_svg"
end
File.open(view1.dir/:config/"config.txt", "w") do |f|
  f.puts "# Custom Radial Gradient Test"
  f.puts "# Default: circular vignette (ar omitted, will use 1/aspect)"
  f.puts "aspect 5.0"
  f.puts "back.radial #FF6B6B #4ECDC4 75% 25% 60%"
  f.puts ""
  f.puts "# Custom: elliptical vignette (ar = 0.5, i.e. squished horizontally)"
  f.puts "# Uncomment to test:"
  f.puts "# back.radial #FF6B6B #4ECDC4 75% 25% 60% 0.5"
  f.puts ""
  f.puts "# Title styling"
  f.puts "title.color #FFFFFF"
  f.puts "title.style bold"
  f.puts "title.align center"
  f.puts ""
  f.puts "# Subtitle styling"
  f.puts "subtitle.color #FFFFFF"
  f.puts "subtitle.style italic"
  f.puts "subtitle.align center"
end
view1.generate_front_page
views << view1

# Test 2: Large radius radial gradient (soft vignette)
view2 = @repo.create_view("radial-large-radius", "Large Radius Radial Test", "Testing r > 100% for soft vignette")
File.open(view2.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
end
view2.generate_empty_containers
File.open(view2.dir/:config/"header.txt", "w") do |f|
  f.puts "banner_svg"
end
File.open(view2.dir/:config/"config.txt", "w") do |f|
  f.puts "# Large Radius Radial Gradient Test"
  f.puts "aspect 5.0"
  f.puts "# r = 150% (soft vignette, gradient extends beyond banner)"
  f.puts "back.radial #FF6B6B #4ECDC4 50% 50% 150%"
  f.puts ""
  f.puts "# Title styling"
  f.puts "title.color #FFFFFF"
  f.puts "title.style bold"
  f.puts "title.align center"
  f.puts ""
  f.puts "# Subtitle styling"
  f.puts "subtitle.color #FFFFFF"
  f.puts "subtitle.style italic"
  f.puts "subtitle.align center"
end
view2.generate_front_page
views << view2

instruct <<~EOS
  Radial Gradient Banner Tests
  
  This test demonstrates different radial gradient scenarios:
  
  1. radial-custom: Custom center position (75%, 25%) and radius (60%)
     - Tests aspect-ratio compensation for circular vignettes
     - Includes commented example for elliptical vignettes (ar=0.5)
  
  2. radial-large-radius: Large radius (150%) for soft vignette effect
     - Tests gradients that extend beyond the banner boundaries
     - Creates a very soft, subtle color transition
  
  Both tests use:
  - Wide aspect ratio (5.0) to test gradient behavior in non-square banners
  - White text with bold title and italic subtitle
  - Centered text alignment
EOS

examine views