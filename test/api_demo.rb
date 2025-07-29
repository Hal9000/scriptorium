#!/usr/bin/env ruby

require_relative '../lib/scriptorium'

# Demo of select_posts and search_posts methods
puts "=== Scriptorium API Demo: Post Selection and Search ===\n"

api = Scriptorium::API.new(true)

# Create some test data
api.create_view_and_use("blog", "My Blog")
api.create_view("tech", "Tech Posts")

# Create posts with different content
api.create_post("Ruby Programming Guide", "Learn Ruby basics and advanced features", tags: "ruby, programming, tutorial")
api.create_post("Python vs Ruby", "Comparing Python and Ruby for web development", tags: "python, ruby, comparison")
api.create_post("Scriptorium API Documentation", "Complete guide to the Scriptorium API", tags: "api, documentation, scriptorium")
api.create_post("Web Development Tips", "Best practices for modern web development", tags: "web, tips, development")

puts "Created 4 posts with various content\n"

# Demo select_posts with block filtering
puts "\n=== select_posts Examples ==="

# Filter posts by title containing "Ruby"
ruby_posts = api.select_posts { |post| post.title.include?("Ruby") }
puts "Posts with 'Ruby' in title: #{ruby_posts.map(&:title).join(', ')}"

# Filter posts by tags containing "api"
api_posts = api.select_posts { |post| post.tags.include?("api") }
puts "Posts tagged with 'api': #{api_posts.map(&:title).join(', ')}"

# Filter posts by title length
long_title_posts = api.select_posts { |post| post.title.length > 20 }
puts "Posts with long titles: #{long_title_posts.map(&:title).join(', ')}"

# Demo search_posts with keyword criteria
puts "\n=== search_posts Examples ==="

# Search by title with regex
ruby_title_posts = api.search_posts(title: /Ruby/)
puts "Posts with 'Ruby' in title (regex): #{ruby_title_posts.map(&:title).join(', ')}"

# Search by body content
body_posts = api.search_posts(body: "development")
puts "Posts with 'development' in body: #{body_posts.map(&:title).join(', ')}"

# Search by tags
tagged_posts = api.search_posts(tags: "programming")
puts "Posts tagged with 'programming': #{tagged_posts.map(&:title).join(', ')}"

# Multiple criteria (AND)
multi_posts = api.search_posts(title: /Ruby/, body: "basics")
puts "Posts with 'Ruby' in title AND 'basics' in body: #{multi_posts.map(&:title).join(', ')}"

# Demo with blurb (create a post with blurb)
puts "\n=== search_posts with Blurb ==="
api.create_post("Ruby Deep Dive", "Advanced Ruby concepts", blurb: "This is a comprehensive guide to Ruby programming.")

blurb_posts = api.search_posts(blurb: "comprehensive")
puts "Posts with 'comprehensive' in blurb: #{blurb_posts.map(&:title).join(', ')}"

# Demo draft management
puts "\n=== Draft Management ==="
draft_path = api.draft(title: "Temporary Draft", body: "This will be deleted")
puts "Created draft: #{draft_path}"

drafts = api.drafts
puts "Drafts before deletion: #{drafts.length}"

api.delete_draft(draft_path)
drafts = api.drafts
puts "Drafts after deletion: #{drafts.length}"

# Demo generate_all
puts "\n=== Generate All ==="
result = api.generate_all
puts "Generated all content: #{result}"

# Demo widget generation
puts "\n=== Widget Generation ==="

# Create widget directory and sample data in the current view
widget_dir = api.repo.root/:views/api.current_view.name/:widgets/"links"
FileUtils.mkdir_p(widget_dir)
File.write(widget_dir/"list.txt", "https://ruby-lang.org, Ruby Language\nhttps://github.com, GitHub")

result = api.generate_widget("links")
puts "Generated links widget: #{result}"

# Check if widget files were created
if File.exist?(widget_dir/"links-card.html")
  puts "Widget card file created successfully"
else
  puts "Widget card file not found"
end

puts "\n=== Demo Complete ==="
api.destroy 