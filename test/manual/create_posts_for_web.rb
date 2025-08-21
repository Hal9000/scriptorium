require_relative './environment'

manual_setup

# Create a view for testing posts in the correct location for the web app
# First, clean up the old repo and create a new one in the right location
system("rm -rf ui/web/scriptorium-TEST")
@repo = Scriptorium::Repo.create("ui/web/scriptorium-TEST", testmode: true)
view = @repo.create_view("web-test", "Web App Test View", "Testing posts in the web interface")

puts "Creating posts for web app testing..."

# Create 45 posts with varied content
45.times do |i|
  # Create posts with different titles and content
  title = case i % 5
  when 0
    "Technical Post #{i + 1}: Ruby Programming"
  when 1
    "Creative Post #{i + 1}: Writing and Art"
  when 2
    "Science Post #{i + 1}: Physics and Math"
  when 3
    "Philosophy Post #{i + 1}: Deep Thoughts"
  else
    "Misc Post #{i + 1}: Random Topics"
  end
  
  # Create varied body content
  body = case i % 4
  when 0
    "This is a technical post about programming and software development. " +
    "It covers various aspects of Ruby programming, including best practices, " +
    "design patterns, and performance optimization techniques."
  when 1
    "A creative exploration of writing, art, and expression. " +
    "This post delves into the creative process, inspiration, and " +
    "the intersection of technology and creativity."
  when 2
    "An exploration of scientific concepts, from physics to mathematics. " +
    "This post discusses fundamental principles, recent discoveries, " +
    "and the beauty of scientific understanding."
  else
    "Philosophical musings on life, technology, and human nature. " +
    "This post explores deep questions about consciousness, existence, " +
    "and the meaning of it all."
  end
  
  # Add some code examples for syntax highlighting
  if i % 3 == 0
    body += "\n\n```ruby\n# Example Ruby code\ndef hello_world\n  puts 'Hello, World!'\nend\n\nhello_world\n```"
  end
  
  # Create the post
  post = @repo.create_post(title: title, body: body)
  
  # Set publication dates spread across different days
  # Use modulo to get valid dates (1-31 for January)
  day = (i % 31) + 1
  post.set_pubdate_with_seconds("2025-01-#{day.to_s.rjust(2, '0')}", i % 60)
  
  # Generate the post
  @repo.generate_post(post.id)
  
  puts "Created post #{i + 1}: #{title}"
end

# Generate the front page for the view
view.generate_front_page

puts "\n" + "="*60
puts "POSTS CREATED SUCCESSFULLY!"
puts "="*60
puts "Created 45 posts in view 'web-test'"
puts "Posts have varied titles, content, and publication dates"
puts "Some posts include code examples for syntax highlighting"
puts "\nTo view in web app:"
puts "1. Start the web app: ./ui/web/bin/scriptorium-web start"
puts "2. Open browser to: http://localhost:4567"
puts "3. Select the 'web-test' view"
puts "4. Browse posts and test pagination"
puts "\nFiles generated in: test/scriptorium-TEST/views/web-test/output/"

instruct <<~EOS
  Posts created successfully!
  
  Next steps:
  1. Start the web app with: ./ui/web/bin/scriptorium-web start
  2. Open browser to http://localhost:4567
  3. Select 'web-test' view from the dropdown
  4. Browse the posts and test the interface
  
  The posts include:
  - 45 posts with varied content types
  - Different publication dates (spread across 45 days)
  - Code examples for syntax highlighting
  - Varied titles and content themes
  
  Press Enter to continue...
EOS

STDIN.gets

# Clean up webrick if it was started
begin
  line = `ps | grep "ruby -run -e httpd" | grep -v grep`
  if line.strip != ""
    pid = line.split.first
    pid2 = pid.to_i + 1
    system("kill #{pid} #{pid2}")
    puts "Cleaned up webrick server"
  end
rescue => e
  puts "No webrick server to clean up"
end

puts "\nManual test complete! You can now test the web app with these posts."
