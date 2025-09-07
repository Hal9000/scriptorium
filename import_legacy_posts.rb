#!/usr/bin/env ruby

# Complete legacy post import workflow
# 1. Create new test repository
# 2. Convert legacy posts from doc/old-posts/ to proper format
# 3. Create default views
# 4. Import all converted posts
# 5. Create some new test posts

require_relative 'lib/scriptorium'
require 'fileutils'
require 'pathname'

puts "=== Complete Legacy Post Import Workflow ==="
puts

# Step 1: Create new test repository
puts "1. Creating new test repository..."
repo_path = "ui/web/scriptorium-TEST"

# Remove existing repo if it exists
if Dir.exist?(repo_path)
  puts "   Removing existing repository at #{repo_path}..."
  system("rm -rf #{repo_path}")
end

# Create new repo
api = Scriptorium::API.new(testmode: true)
api.create_repo(repo_path)
api.open_repo(repo_path)
puts "   ✓ Repository created at #{repo_path}"

# Step 2: Convert legacy posts
puts
puts "2. Converting legacy posts..."

source_dir = Pathname.new('doc/old-posts')
target_dir = Pathname.new(repo_path) / 'legacy'

# Check if source directory exists
unless Dir.exist?(source_dir)
  puts "   ❌ Source directory not found: #{source_dir}"
  puts "   Please ensure doc/old-posts/ exists with legacy .lt3 files"
  exit 1
end

# Create target directory
FileUtils.mkdir_p(target_dir)
puts "   ✓ Target directory ready: #{target_dir}"

# Get all legacy post files
legacy_files = source_dir.glob('*.lt3').sort
puts "   Found #{legacy_files.length} legacy posts to convert"

if legacy_files.empty?
  puts "   ❌ No .lt3 files found in #{source_dir}"
  exit 1
end

converted_count = 0
error_count = 0

legacy_files.each do |file|
  filename = file.basename
  puts "   Converting #{filename}..."
  
  begin
    content = File.read(file)
    lines = content.lines
    
    # Process the lines
    processed_lines = []
    in_blurb = false
    
    lines.each do |line|
      stripped = line.strip
      
      # Skip unwanted legacy commands
      if line.start_with?('.mixin') || line.start_with?('.post')
        next
      end
      
      # Comment out .pin directives to prevent interference with .blurb processing
      if line.start_with?('.pin')
        processed_lines << line.gsub('.pin', '. pin')
        next
      end
      
      # Transform metadata lines
      if line.start_with?('.pubdate')
        processed_lines << line.gsub('.pubdate', '.created')
      elsif line.start_with?('.teaser')
        # Convert .teaser to .blurb
        processed_lines << line.gsub('.teaser', '.blurb')
        in_blurb = true
      elsif line.strip == '.end' && in_blurb
        # End of blurb - keep the .end and add $blurb
        in_blurb = false
        processed_lines << line # Keep the .end
        processed_lines << "\n"
        processed_lines << "$post.blurb\n"
        processed_lines << "\n"
      elsif in_blurb
        # Keep blurb content as-is
        processed_lines << line
      else
        # Preserve ALL other lines as-is, including blank lines
        # But fix lines starting with ... to prevent LiveText dot command interpretation
        if line.start_with?('...')
          processed_lines << ' ' + line
        else
          processed_lines << line
        end
      end
    end
    
    # Write to target directory
    target_file = target_dir / filename
    File.write(target_file, processed_lines.join)
    
    puts "     ✓ Converted to #{target_file}"
    converted_count += 1
    
  rescue => e
    puts "     ❌ Failed to convert #{filename}: #{e.message}"
    error_count += 1
  end
end

if error_count > 0
  puts "   ❌ #{error_count} conversions failed. Aborting."
  exit 1
end

puts "   ✓ Successfully converted #{converted_count} posts"

# Step 3: Create default views
puts
puts "3. Creating default views..."

default_views = [
  { name: 'computing', title: 'Computing' },
  { name: 'austin', title: 'Austin' },
  { name: 'chiller', title: 'Chiller' },
  { name: 'writing', title: 'Writing' }
]

default_views.each do |view|
  begin
    api.create_view(view[:name], view[:title])
    puts "   ✓ Created view: #{view[:name]}"
  rescue => e
    puts "   ❌ Failed to create view #{view[:name]}: #{e.message}"
    exit 1
  end
end

# Step 4: Import converted posts
puts
puts "4. Importing converted posts..."

# Get all converted legacy post files
converted_files = Dir.glob(File.join(target_dir, "*.lt3")).sort
puts "   Found #{converted_files.length} converted posts to import"

success_count = 0
import_error_count = 0
skipped_count = 0

converted_files.each do |file|
  filename = File.basename(file)
  puts "   Importing #{filename}..."
  
  begin
    # Read the converted content
    content = File.read(file)
    
    # Extract post number from filename
    post_num = filename.match(/^(\d+)/)
    if post_num
      target_post_id = post_num[1].to_i
    else
      puts "     ❌ Could not extract post number from filename"
      import_error_count += 1
      next
    end
    
    # Check if post already exists - quit with error if it does
    begin
      existing_post = api.post(target_post_id)
      puts "     ❌ Post #{target_post_id} already exists! Aborting import."
      puts "     This should not happen with a fresh repository."
      exit 1
    rescue CannotGetPost
      # Post doesn't exist, which is what we want
    end
    
    # Extract title from content
    title = "Imported from #{filename}"
    
    # Try to extract actual title from content
    content.lines.each do |line|
      if line.start_with?('.title ')
        title = line.sub('.title ', '').strip
      end
    end
    
    # Create the post manually to preserve the post number
    post_num_str = "%04d" % target_post_id
    post_dir = File.join(repo_path, 'posts', post_num_str)
    FileUtils.mkdir_p(post_dir)
    
    # Write source content
    source_file = File.join(post_dir, 'source.lt3')
    File.write(source_file, content)
    
    # Create metadata
    metadata_file = File.join(post_dir, 'meta.txt')
    metadata_content = <<~EOS
      post.id            #{target_post_id}
      post.created       #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
      post.published     no
      post.deployed      no
      post.title         #{title}
      post.views         computing
      post.tags          imported legacy
    EOS
    File.write(metadata_file, metadata_content)
    
    # Generate the post
    api.generate_post(target_post_id)
    
    puts "     ✓ Successfully imported as post ##{target_post_id}"
    success_count += 1
    
  rescue => e
    puts "     ❌ Failed to import #{filename}: #{e.message}"
    import_error_count += 1
  end
end

if import_error_count > 0
  puts "   ❌ #{import_error_count} imports failed. Aborting."
  exit 1
end

puts "   ✓ Successfully imported #{success_count} posts"

# Step 5: Create new test posts
puts
puts "5. Creating new test posts..."

# Find the highest post number to continue from
max_post_num = 0
if success_count > 0
  max_post_num = converted_files.map { |f| File.basename(f).match(/^(\d+)/)[1].to_i }.max
end

new_posts = [
  { title: "New Post After Import", blurb: "This is a new post created after importing legacy posts." },
  { title: "Another New Post", blurb: "Testing date display with new posts." },
  { title: "Final Test Post", blurb: "This should be post ##{max_post_num + 3} if everything works correctly." }
]

new_posts.each_with_index do |post_data, index|
  post_num = max_post_num + index + 1
  puts "   Creating new post #{post_num}: #{post_data[:title]}"
  
  begin
    post = api.create_post(
      post_data[:title],
      post_data[:blurb],  # body
      views: "computing",
      tags: "test"
    )
    
    puts "     ✓ Created post #{post.num}: #{post.title}"
  rescue => e
    puts "     ❌ Error creating post #{post_num}: #{e.message}"
    exit 1
  end
end

puts
puts "=== Import Complete ==="
puts "✓ Repository created: #{repo_path}"
puts "✓ Converted #{converted_count} legacy posts"
puts "✓ Created #{default_views.length} views"
puts "✓ Imported #{success_count} legacy posts"
puts "✓ Created #{new_posts.length} new test posts"
puts
puts "🎉 All done! You can now test the repository at #{repo_path}"
