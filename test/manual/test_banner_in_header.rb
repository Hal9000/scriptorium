require_relative './environment'

manual_setup

# Create a simple view
view = @repo.create_view("banner-test", "My Banner Site", "A site with SVG banner in header")

# Set up layout with header
File.open(view.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
  f.puts "main"
end

# Generate the empty containers
view.generate_empty_containers

# Configure the header to include the SVG banner
File.open(view.dir/:config/"header.txt", "w") do |f|
  f.puts "banner_svg"
  f.puts "title"
  f.puts "subtitle"
end

# Generate the front page
view.generate_front_page

instruct <<~EOS
  This test shows how to insert an SVG banner into the header.
  
  The header.txt contains:
  - banner_svg (inserts the SVG banner)
  - title (inserts the view title)
  - subtitle (inserts the view subtitle)
  
  The SVG banner will appear at the top of the header, followed by the title and subtitle.
  The banner uses the view's title and subtitle as its content.
EOS

examine view 