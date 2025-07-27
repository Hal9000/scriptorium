require_relative './environment'

manual_setup

# Create a simple view for debugging
view = @repo.create_view("svg-debug", "SVG Debug Test", "Testing SVG insertion")

# Set up layout with header only
File.open(view.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
end

# Generate the empty containers
view.generate_empty_containers

# Configure the header to only have the SVG banner
File.open(view.dir/:config/"header.txt", "w") do |f|
  f.puts "banner_svg"
end

# Create a simple SVG config
File.open(view.dir/:config/"config.txt", "w") do |f|
  f.puts "# Simple debug config"
  f.puts "back.radial #FF0000 #0000FF"
  f.puts "title.color #FFFFFF"
  f.puts "subtitle.color #FFFF00"
  f.puts "title.style bold"
  f.puts "subtitle.style italic"
end

# Generate the front page
view.generate_front_page

instruct <<~EOS
  SVG Debug Test
  
  This test has:
  - Only the SVG banner (no title/subtitle HTML elements)
  - Red to blue radial gradient
  - White bold title
  - Yellow italic subtitle
  - No header background color
  
  Check if the SVG displays correctly now.
EOS

examine view 