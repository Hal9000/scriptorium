require_relative './environment'

manual_setup

# Create a view with a large-radius radial gradient
view = @repo.create_view("radial-large-radius", "Large Radius Radial Test", "Testing r > 100% for soft vignette")

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

# Create a config with a large radius
File.open(view.dir/:config/"config.txt", "w") do |f|
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

# Generate the front page
view.generate_front_page

instruct <<~EOS
  Large Radius Radial Gradient Test
  
  This test demonstrates a radial gradient with r > 100% (here, 150%).
  - aspect 5.0 (wide banner)
  - back.radial #FF6B6B #4ECDC4 50% 50% 150%
  
  The gradient should be very soft, with the color fading in from outside the banner.
EOS

examine view 