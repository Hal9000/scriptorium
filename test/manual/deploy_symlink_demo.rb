#!/usr/bin/env ruby

# Manual test script to demonstrate deployment with symlinks
# Run with: ruby test/manual/deploy_symlink_demo.rb

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class DeploySymlinkDemo
  include Scriptorium::Helpers
  include TestHelpers

  def run
    puts "=== Deployment with Symlinks Demo ==="
    puts
    
    # Create test repository
    puts "1. Creating test repository..."
    @repo = Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)
    @view = @repo.create_view("demo_view", "Demo View", "A demo view for deployment")
    puts "   ✓ Created repository and view"
    puts
    
    # Create a test post
    puts "2. Creating test post..."
    post_title = "Deployment Test Post with Symlinks"
    post_body = "This post tests deployment with symlinks."
    
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
    
    # Test deployment simulation
    puts "5. Testing deployment simulation..."
    
    # Create a test deployment directory
    test_deploy_dir = "test/deploy-test"
    FileUtils.rm_rf(test_deploy_dir) if Dir.exist?(test_deploy_dir)
    FileUtils.mkdir_p(test_deploy_dir)
    
    # Simulate rsync command with symlink preservation
    output_dir = @view.dir/:output
    rsync_cmd = "rsync -r -z -l #{output_dir}/ #{test_deploy_dir}/"
    puts "   Simulating: #{rsync_cmd}"
    
    # Actually copy files (simulating rsync)
    FileUtils.cp_r("#{output_dir}/.", test_deploy_dir)
    
    # Check if symlinks were preserved
    deployed_symlink = "#{test_deploy_dir}/permalink/#{clean_slug}"
    deployed_target = "#{test_deploy_dir}/permalink/#{numbered_slug}"
    
    if File.exist?(deployed_symlink)
      puts "   ✓ Symlink exists in deployment directory"
      
      if File.symlink?(deployed_symlink)
        puts "   ✓ Symlink is preserved in deployment"
        deployed_target_readlink = File.readlink(deployed_symlink)
        puts "   ✓ Deployed symlink points to: #{deployed_target_readlink}"
        
        if File.exist?(deployed_target)
          puts "   ✓ Symlink target exists in deployment"
        else
          puts "   ✗ Symlink target missing in deployment"
        end
      else
        puts "   ✗ Symlink was not preserved (copied as file)"
      end
    else
      puts "   ✗ Symlink missing in deployment directory"
    end
    puts
    
    # Show deployment structure
    puts "6. Deployment directory structure:"
    if Dir.exist?(test_deploy_dir)
      Dir.glob("#{test_deploy_dir}/**/*").sort.each do |file|
        relative_path = file.sub("#{test_deploy_dir}/", "")
        if File.symlink?(file)
          target = File.readlink(file)
          puts "   #{relative_path} -> #{target} (symlink)"
        elsif File.directory?(file)
          puts "   #{relative_path}/ (directory)"
        else
          puts "   #{relative_path} (file)"
        end
      end
    end
    puts
    
    puts "=== Demo Complete ==="
    puts
    puts "To clean up, run: rm -rf test/scriptorium-TEST test/deploy-test"
  end
end

if __FILE__ == $0
  demo = DeploySymlinkDemo.new
  demo.run
end
