require_relative './environment'

manual_setup

# Create a view with an empty header
view = @repo.create_view("empty-header-test", "Empty Header Test", "Testing placeholder text")

# Set up layout with header
File.open(view.dir/:config/"layout.txt", "w") do |f|
  f.puts "header"
  f.puts "main"
end

# Generate the empty containers
view.generate_empty_containers

# Leave header.txt empty (no content)
File.open(view.dir/:config/"header.txt", "w") do |f|
  # Empty file - should trigger placeholder
end

# Generate the front page
view.generate_front_page

instruct <<~EOS
  This test verifies that placeholder text appears when header has no content.
  
  The header.txt is empty, so it should show "This is header..." as placeholder text.
  This confirms that our fix only removes placeholders when there's real content.
EOS

examine view 