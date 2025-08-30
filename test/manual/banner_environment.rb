# Set up environment for banner tests
ENV['PATH'] = "#{ENV['HOME']}/.rbenv/shims:#{ENV['PATH']}"

# Minimal environment for banner tests
require 'fileutils'
require 'find'

# Create test directory if it doesn't exist
test_dir = File.dirname(__FILE__)/"banner-tests"
FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
Dir.mkdir(test_dir)

@pid = nil
# Start server from the project root directory
server_dir = File.expand_path("../..", __FILE__)
Dir.chdir("test") do
  Process.spawn ("ruby -run -e httpd . -p 8000 >/dev/null 2>&1") 
  sleep 1
end

def instruct(msg)
  lines = msg.split("\n")
  longest = lines.map {|line| line.length }.max
  puts "  +" + "-" * (longest + 4) + "+"
  lines.each do |line|
    puts "  | #{line.ljust(longest + 2)} |"
  end
  puts "  +" + "-" * (longest + 4) + "+"
  puts
end

def examine(view_name)
  index_url = "http://127.0.0.1:8000/manual/banner-tests/index.html"
  
  if ARGV.include?('--automated')
    # Basic validation for automated mode
    index_file = File.dirname(__FILE__)/"banner-tests/index.html"
    if File.exist?(index_file)
      content = File.read(index_file)
      test_count = content.scan(/<div class='test-item'>/).count
      
      # Check that at least one test file has custom content
      test_file = File.dirname(__FILE__)/"banner-tests/test04.html"  # Red to Blue gradient test
      if File.exist?(test_file)
        test_content = File.read(test_file)
        unless test_content.include?('linearGradient') || test_content.include?('radialGradient') || test_content.include?('fill=\'#ff0000\'')
          puts "⚠ Warning: No custom banner content found"
        end
      end
    else
      puts "✗ Error: Index file not generated"
      exit 1
    end
    
    return
  end
  
  puts "Press Enter to open the generated front page to inspect the result."
  STDIN.gets
  system("open #{index_url}")

  puts "Press Enter to kill webrick"
  STDIN.gets
  line = `ps | grep "ruby -run -e httpd" | grep -v grep`
  pid = line.split.first
  pid2 = pid.to_i + 1
  system("kill #{pid} #{pid2}")
end

# Simple post creation for banner tests
def create_banner_post(title, subtitle, config_content, description, view_name, post_num = nil)
  # Write config file FIRST, before creating banner
  File.write("banner-tests/config.txt", config_content)
  
  # Create banner AFTER config is written, in the correct directory
  # Load the main Scriptorium library
  require_relative '../../lib/scriptorium'
  
  # Change to the test directory so the banner can find config.txt
  Dir.chdir("banner-tests") do
    banner = Scriptorium::BannerSVG.new(title, subtitle)
    
    # Parse config first to set instance variables
    banner.parse_header_svg
    
    # Generate static SVG for manual inspection
    # First parse config to set instance variables, then generate SVG
    banner.parse_header_svg
    svg_output = banner.generate_svg
    
    # Use provided post_num or generate one
    Dir.mkdir("posts") unless Dir.exist?("posts")
    post_num ||= Dir.glob("posts/*").length + 1
    post_dir = "posts/#{post_num.to_s.rjust(4, '0')}"
    Dir.mkdir(post_dir) unless Dir.exist?(post_dir)
    
    # Create individual page with banner at the top
    post_html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
          <title>#{title}</title>
          <style>
              body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f5f5f5; }
              .banner { width: 100%; margin: 0; padding: 0; }
              .content { padding: 20px; }
              .description { margin: 10px 0; font-weight: bold; }
              .config { background: #f0f0f0; padding: 10px; margin: 10px 0; font-family: monospace; font-size: 12px; }
              .navigation { background: #e0e0e0; padding: 10px; margin: 20px 0; text-align: center; }
              .navigation a { margin: 0 10px; padding: 5px 10px; background: #007cba; color: white; text-decoration: none; border-radius: 3px; }
              .navigation a:hover { background: #005a87; }
          </style>
      </head>
      <body>
          #{svg_output}
          <div class="content">
              <h1>#{title}</h1>
              <div class="description">#{description}</div>
              <div class="config">#{config_content}</div>
              <div class="navigation">
                  <a href="../index.html">Back to Index</a>
              </div>
          </div>
      </body>
      </html>
    HTML
    
    # Write individual post file
    File.write("#{post_dir}/index.html", post_html)
    
    # Add to view for index generation
    view_dir = "views/#{view_name}/output/posts"
    FileUtils.mkdir_p(view_dir) unless Dir.exist?(view_dir)
    File.write("#{view_dir}/#{post_num.to_s.rjust(4, '0')}.html", post_html)
    
    # Return post info for navigation links
    { number: post_num, title: title, filename: "#{post_num.to_s.rjust(4, '0')}.html" }
  end
end

def generate_front_page(view_name)
  # Create simple index page
  posts = Dir.glob("scriptorium-TEST/views/#{view_name}/output/posts/*.html").sort
  
  index_html = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>Banner Tests - #{view_name}</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
            .post { background: white; margin: 20px 0; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .banner { margin: 20px 0; border: 1px solid #ddd; background: white; }
            .description { margin: 10px 0; font-weight: bold; }
            .config { background: #f0f0f0; padding: 10px; margin: 10px 0; font-family: monospace; font-size: 12px; }
        </style>
    </head>
    <body>
        <h1>Banner Tests - #{view_name}</h1>
  HTML
  
  posts.each do |post_file|
    post_content = File.read(post_file)
    # Extract title, banner, description, and config from post
    title_match = post_content.match(/<h1>(.*?)<\/h1>/)
    banner_match = post_content.match(/<div class="banner">(.*?)<\/div>/m)
    desc_match = post_content.match(/<div class="description">(.*?)<\/div>/)
    config_match = post_content.match(/<div class="config">(.*?)<\/div>/m)
    
    title = title_match ? title_match[1] : "Unknown"
    banner = banner_match ? banner_match[1] : ""
    description = desc_match ? desc_match[1] : ""
    config = config_match ? config_match[1] : ""
    
    index_html += <<~HTML
        <div class="post">
            <h2>#{title}</h2>
            <div class="banner">#{banner}</div>
            <div class="description">#{description}</div>
            <div class="config">#{config}</div>
        </div>
    HTML
  end
  
  index_html += <<~HTML
    </body>
    </html>
  HTML
  
  FileUtils.mkdir_p("scriptorium-TEST/views/#{view_name}/output")
  File.write("scriptorium-TEST/views/#{view_name}/output/index.html", index_html)
end

# Cleanup method to remove standalone directories
def cleanup_standalone_directories
  if Dir.exist?("posts")
    FileUtils.rm_rf("posts")
  end
  if Dir.exist?("banner-tests")
    FileUtils.rm_rf("banner-tests")
  end
end

# Ensure cleanup happens when script exits
at_exit { cleanup_standalone_directories } 