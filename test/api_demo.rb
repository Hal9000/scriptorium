#!/usr/bin/env ruby

require_relative "../lib/scriptorium"

# Demo of the new Scriptorium::API convenience interface

puts "=== Scriptorium::API Demo ==="

# Create API instance (testing mode)
api = Scriptorium::API.new("test/scriptorium-TEST")

puts "\n1. Creating a view..."
api.create_view_and_use("demo", "Demo Blog", "A demonstration blog")

puts "\n2. Creating a post..."
post = api.create_post("Hello World", "This is my first post!", tags: ["demo", "first"])

puts "\n3. Generating front page..."
api.generate_front_page

puts "\n4. Creating another post with quick_post..."
api.quick_post("Second Post", "This is my second post!", tags: ["demo", "second"])

puts "\n5. Listing posts..."
posts = api.posts
puts "Found #{posts.length} posts:"
posts.each do |p|
  puts "  - #{p.title} (ID: #{p.id})"
end

puts "\n6. Tree structure:"
api.tree

puts "\n=== Demo Complete ==="
puts "Check the output in scriptorium-TEST/views/demo/output/"

# Clean up
api.destroy 