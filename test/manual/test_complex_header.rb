require_relative './environment'

manual_setup

# Create a view with a complex header
view = @repo.create_view("complex-header", "My Awesome Blog", "Exploring the Power of SVG Banners")

# Set up layout with header
File.open(view.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
  f.puts "main"
end

# Generate the empty containers
view.generate_empty_containers

# Create a complex SVG banner configuration
File.open(view.dir/:config/"header.txt", "w") do |f|
  f.puts "banner_svg"
  f.puts "title"
  f.puts "subtitle"
end

# Create a complex SVG banner config file
File.open(view.dir/:config/"config.txt", "w") do |f|
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

# Generate the front page
view.generate_front_page

instruct <<~EOS
  Complex Header Test - Multiple SVG Banner Features
  
  This header demonstrates:
  - Radial gradient background (purple to blue)
  - Custom aspect ratio (6:1 - wider banner)
  - Georgia serif font
  - Title: Bold, larger scale (1.2x), white color, centered
  - Subtitle: Italic, smaller scale (0.6x), light gray color, centered
  - Custom positioning for both title and subtitle
  - Responsive SVG that scales with window width
  
  The banner should look sophisticated with the gradient background
  and well-positioned, styled text elements.
EOS

examine view 