# Manual inspection tests for BannerSVG features
# 
# This file creates individual HTML pages for each banner feature test,
# with simple navigation between them. Each page is completely isolated
# to prevent state sharing issues.
# 
# Usage:
#   ruby test_banner_features_simple.rb          # Interactive mode with browser
#   ruby test_banner_features_simple.rb --automated  # Automated mode for CI/AI testing
# 
require_relative "../../lib/scriptorium"
require_relative "./banner_environment"

# Test definitions
tests = [
  {
    title: "Red Background",
    subtitle: "Solid color test",
    config: "back.color #ff0000",
    description: "Red Background"
  },
  {
    title: "Blue Background", 
    subtitle: "Solid color test",
    config: "back.color #0000ff",
    description: "Blue Background"
  },
  {
    title: "Green Background",
    subtitle: "Solid color test", 
    config: "back.color #00ff00",
    description: "Green Background"
  },
  {
    title: "Red to Blue Gradient",
    subtitle: "Linear gradient test",
    config: "back.linear red blue lr",
    description: "Linear Gradient (Left to Right)"
  },
  {
    title: "Green to Yellow Gradient",
    subtitle: "Linear gradient test",
    config: "back.linear green yellow tb", 
    description: "Linear Gradient (Top to Bottom)"
  },
  {
    title: "Red to Blue Radial",
    subtitle: "Radial gradient test",
    config: "back.radial red blue",
    description: "Radial Gradient"
  },
  {
    title: "Green to Yellow Radial",
    subtitle: "Radial gradient test",
    config: "back.radial green yellow",
    description: "Radial Gradient"
  },
  {
    title: "Small Text",
    subtitle: "Size test",
    config: "title.scale 0.5\nsubtitle.scale 0.3",
    description: "Small Text (0.5x, 0.3x)"
  },
  {
    title: "Large Text",
    subtitle: "Size test", 
    config: "title.scale 1.5\nsubtitle.scale 1.0",
    description: "Large Text (1.5x, 1.0x)"
  },
  {
    title: "Bold Text",
    subtitle: "Style test",
    config: "title.style bold\nsubtitle.style bold",
    description: "Bold Text"
  },
  {
    title: "Italic Text",
    subtitle: "Style test",
    config: "title.style italic\nsubtitle.style italic", 
    description: "Italic Text"
  },
  {
    title: "Bold & Italic",
    subtitle: "Style test",
    config: "title.style bold italic\nsubtitle.style bold italic",
    description: "Bold & Italic Text"
  },
  {
    title: "Blue Text",
    subtitle: "Color test",
    config: "title.color #0000ff\nsubtitle.color #0000ff",
    description: "Blue Text"
  },
  {
    title: "Green Text",
    subtitle: "Color test",
    config: "title.color #00ff00\nsubtitle.color #00ff00",
    description: "Green Text"
  },
  {
    title: "Left Position",
    subtitle: "Position test",
    config: "text.align left",
    description: "Left Positioned Text"
  },
  {
    title: "Center Position",
    subtitle: "Position test",
    config: "text.align center",
    description: "Center Positioned Text"
  },
  {
    title: "Right Position",
    subtitle: "Position test",
    config: "text.align right",
    description: "Right Positioned Text"
  },
  {
    title: "Perfect Image Background",
    subtitle: "Image test (8:1 aspect)",
    config: "back.image ../../assets/images/perfect.png",
    description: "Perfect match: 8:1 aspect ratio image fits banner exactly - no cropping or scaling needed"
  },
  {
    title: "Wide Image Background", 
    subtitle: "Image test (16:1 aspect)",
            config: "back.image ../../assets/images/wide.png",
    description: "Wide image (16:1) cropped to fit 8:1 banner - left/right edges removed, center preserved"
  },
  {
    title: "Tall Image Background",
    subtitle: "Image test (1:1 aspect)", 
    config: "back.image ../../assets/images/tall.png",
    description: "Square image (1:1) cropped to fit 8:1 banner - top/bottom removed, center strip visible"
  },
  {
    title: "Very Tall Image Background",
    subtitle: "Image test (1:4 aspect)",
    config: "back.image ../../assets/images/very_tall.png", 
    description: "Very tall image (1:4) heavily cropped - only narrow center strip visible, most content lost"
  },
  {
    title: "Very Wide Image Background",
    subtitle: "Image test (16:1 aspect)",
    config: "back.image ../../assets/images/very_wide.png",
    description: "Very wide image (16:1) heavily cropped - only narrow center strip visible, sides removed"
  },
  {
    title: "Small Image Background",
    subtitle: "Image test (low res, 8:1 aspect)",
    config: "back.image ../../assets/images/small.png",
    description: "Small low-res image scaled up to fill banner - may appear pixelated but maintains aspect"
  },
  {
    title: "Odd Aspect Image Background",
    subtitle: "Image test (~4:1 aspect)",
    config: "back.image ../../assets/images/odd_aspect.png",
    description: "Non-standard aspect ratio (~4:1) cropped to fit 8:1 banner - moderate cropping applied"
  },
  {
    title: "Another gradient test",
    subtitle: "Just one more, I swear",
    config: "back.linear #0000ff #000033 lr\ntitle.color #fff\nsubtitle.color #fff",
    description: "Linear Gradient (Left to Right)"
  }
]

# Create temp directory for tests
test_dir = File.dirname(__FILE__)/"banner-tests"
Dir.mkdir(test_dir) unless Dir.exist?(test_dir)

# Create individual pages for each test
pages = []
tests.each_with_index do |test, index|
  page_num = index + 1
  filename = "test#{page_num.to_s.rjust(2, '0')}.html"
  
  # Write config file for this test
  File.write(test_dir/"svg.txt", test[:config])
  
  # Create banner
  require_relative '../../lib/scriptorium'
  Dir.chdir(test_dir) do
    banner = Scriptorium::BannerSVG.new(test[:title], test[:subtitle])
    banner.parse_header_svg
    svg_output = banner.get_svg
    
    # Check if this is an image background test
    image_path = nil
    if test[:config].include?("back.image")
      image_path = test[:config].match(/back\.image\s+(.+)/)&.[](1)
      # For the original image display, we need the path relative to the HTML file
      # The HTML is in test/manual/banner-tests/, and images are in test/assets/images/
      # Convert ../../assets/images/... to /assets/images/... (absolute from web server root)
      display_path = image_path.gsub('../../assets/images/', '/assets/images/') if image_path
      
      # Fix the SVG pattern path to use the correct absolute path
      svg_output = svg_output.gsub('../../assets/images/', '/assets/images/')
    end
    
    # Create standalone HTML page
    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
          <title>#{test[:title]}</title>
          <style>
              body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f5f5f5; }
              .banner { width: 100%; margin: 0; padding: 0; border: 3px solid #007cba; border-radius: 8px; }
              .content { padding: 20px; padding-bottom: 80px; }
              .description { margin: 10px 0; font-weight: bold; }
              .config { background: #f0f0f0; padding: 10px; margin: 10px 0; font-family: monospace; font-size: 12px; }
              .navigation { 
                  position: fixed; 
                  bottom: 0; 
                  left: 0; 
                  right: 0; 
                  background: #e0e0e0; 
                  padding: 15px; 
                  text-align: center; 
                  border-top: 2px solid #007cba;
                  z-index: 1000;
              }
              .navigation a { margin: 0 10px; padding: 8px 15px; background: #007cba; color: white; text-decoration: none; border-radius: 3px; }
              .navigation a:hover { background: #005a87; }
              .original-image { margin: 20px 0; padding: 20px; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
              .original-image h3 { margin: 0 0 10px 0; color: #333; }
              .original-image img { max-width: 100%; height: auto; border: 1px solid #ddd; }
          </style>
      </head>
      <body>
          <div class="banner" id="header">
            #{svg_output}
          </div>
          <div class="content">
              <div class="description">#{test[:description]}</div>
              <div class="config">#{test[:config]}</div>
              #{image_path ? "<div class='original-image'>\n                <h3>Original Image (for comparison):</h3>\n                <img src='#{display_path}' alt='Original image'>\n              </div>" : ""}
              <div class="navigation">
                  <a href="index.html">Back to Index</a>
              </div>
          </div>
      </body>
      </html>
    HTML
    
    File.write(filename, html_content)
  end
  
  pages << { number: page_num, title: test[:title], filename: filename }
end

# Add navigation links to each page
pages.each_with_index do |page, index|
  prev_page = index > 0 ? pages[index - 1][:filename] : nil
  next_page = index < pages.length - 1 ? pages[index + 1][:filename] : nil
  
  # Read the current page
  page_file = test_dir/page[:filename]
  content = File.read(page_file)
  
  # Create navigation HTML
  nav_html = '<div class="navigation">'
  nav_html += '<a href="index.html">Back to Index</a>'
  nav_html += " <a href=\"#{prev_page}\">Previous</a>" if prev_page
  nav_html += " <a href=\"#{next_page}\">Next</a>" if next_page
  nav_html += '</div>'
  
  # Replace the placeholder navigation
  content.gsub!(/<div class="navigation">.*?<\/div>/m, nav_html)
  
  # Write the updated page
  File.write(page_file, content)
end

# Create index page
index_html = <<~HTML
  <!DOCTYPE html>
  <html>
  <head>
      <title>BannerSVG Feature Tests</title>
      <style>
          body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
          .test-list { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
          .test-item { margin: 10px 0; padding: 10px; background: #f9f9f9; border-left: 4px solid #007cba; }
          .test-item a { color: #007cba; text-decoration: none; font-weight: bold; }
          .test-item a:hover { text-decoration: underline; }
          .test-description { color: #666; font-size: 14px; margin-top: 5px; }
      </style>
  </head>
  <body>
      <h1>BannerSVG Feature Tests</h1>
      <div class="test-list">
          <p>Click on any test to view the banner in isolation:</p>
          #{pages.map.with_index { |page, index| 
            "<div class='test-item'><a href='#{page[:filename]}'>#{index + 1}. #{page[:title]}</a><div class='test-description'>#{tests[index][:description]}</div></div>"
          }.join("\n")}
      </div>
  </body>
  </html>
HTML

File.write(test_dir/"index.html", index_html)

# Call the environment's examine function
examine("banner-test") 
