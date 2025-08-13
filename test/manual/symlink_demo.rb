#!/usr/bin/env ruby

# Manual test script to demonstrate symlink functionality
# Run with: ruby test/manual/symlink_demo.rb

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class SymlinkDemo
  include Scriptorium::Helpers
  include TestHelpers

  def run
    puts "=== Symlink Functionality Demo ==="
    puts
    
    # Create test repository
    puts "1. Creating test repository..."
    @repo = Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)
    @view = @repo.create_view("demo_view", "Demo View", "A demo view for symlinks")
    puts "   ✓ Created repository and view"
    puts
    
    # Create a test post
    puts "2. Creating test post..."
    post_title = "My First Test Post with Special Characters: & < > \" ' !"
    post_body = "This is the body of my test post. It contains some content."
    
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    puts "   ✓ Created post ##{post_num}: #{post_title}"
    puts
    
    # Generate the post
    puts "3. Generating post..."
    @repo.generate_post(post_num)
    puts "   ✓ Generated post"
    puts
    
    # Check the files
    puts "4. Checking generated files..."
    
    numbered_slug = slugify(post_num, post_title) + ".html"
    clean_slug = clean_slugify(post_title) + ".html"
    
    numbered_path = @view.dir/:output/:permalink/numbered_slug
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    puts "   Numbered file: #{numbered_path}"
    puts "   Clean symlink: #{clean_symlink_path}"
    puts
    
    # Verify files exist
    if File.exist?(numbered_path)
      puts "   ✓ Numbered file exists"
    else
      puts "   ✗ Numbered file missing"
    end
    
    if File.exist?(clean_symlink_path)
      puts "   ✓ Clean symlink exists"
    else
      puts "   ✗ Clean symlink missing"
    end
    
    if File.symlink?(clean_symlink_path)
      puts "   ✓ Clean symlink is actually a symlink"
      symlink_target = File.readlink(clean_symlink_path)
      puts "   ✓ Symlink points to: #{symlink_target}"
    else
      puts "   ✗ Clean symlink is not a symlink"
    end
    puts
    
    # Show the URLs
    puts "5. Generated URLs:"
    puts "   Numbered URL: /permalink/#{numbered_slug}"
    puts "   Clean URL:    /permalink/#{clean_slug}"
    puts
    
    # Test the symlink
    puts "6. Testing symlink..."
    if File.symlink?(clean_symlink_path)
      symlink_target = File.readlink(clean_symlink_path)
      if symlink_target == numbered_slug
        puts "   ✓ Symlink correctly points to numbered file"
      else
        puts "   ✗ Symlink points to wrong target: #{symlink_target}"
      end
    else
      puts "   ✗ Clean symlink is not a symlink"
    end
    puts
    
    # Show file contents
    puts "7. File contents:"
    if File.exist?(numbered_path)
      content = File.read(numbered_path)
      puts "   Numbered file size: #{content.length} bytes"
      puts "   Contains 'Back to Blog' link: #{content.include?('Back to Blog') ? 'Yes' : 'No'}"
    end
    
    if File.exist?(clean_symlink_path) && File.symlink?(clean_symlink_path)
      puts "   Clean symlink: points to #{File.readlink(clean_symlink_path)}"
    end
    puts
    
    puts "=== Demo Complete ==="
    puts
    puts "To clean up, run: rm -rf test/scriptorium-TEST"
  end
end

if __FILE__ == $0
  demo = SymlinkDemo.new
  demo.run
end
