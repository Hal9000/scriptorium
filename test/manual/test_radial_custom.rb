require_relative './environment'

manual_setup

# Create a view with custom radial gradient
view = @repo.create_view("radial-custom", "Custom Radial Test", "Testing custom radial gradient parameters")

# Set up layout with header
File.open(view.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
end

# Generate the empty containers
view.generate_empty_containers

# Configure the header to only have the SVG banner
File.open(view.dir/:config/"header.txt", "w") do |f|
  f.puts "banner_svg"
end

# Create a custom radial gradient config
File.open(view.dir/:config/"config.txt", "w") do |f|
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

# Generate the front page
view.generate_front_page

instruct <<~EOS
  Custom Radial Gradient Test
  
  This test demonstrates the new aspect-ratio compensation for radial gradients:
  - aspect 5.0 (wide banner)
  - back.radial #FF6B6B #4ECDC4 75% 25% 60%   # default: circular vignette
  - Uncomment the line with ar=0.5 for an elliptical vignette
  
  By default, the vignette should be circular even in a wide banner.
  If you set ar < 1/aspect, the vignette will be squished horizontally.
EOS

examine view 