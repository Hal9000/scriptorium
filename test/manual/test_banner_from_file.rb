#!/usr/bin/env ruby

require_relative '../../lib/scriptorium'

include Scriptorium::Helpers

# Simple banner test from configuration file
def test_banner_from_file(config_file, output_file = nil)
  # Default output file if not specified
  output_file ||= "banner_output.html"
  
  # Read the configuration file
  unless File.exist?(config_file)
    puts "Error: Configuration file '#{config_file}' not found"
    exit 1
  end
  
  # Use the read_commented_file helper to read the config
  config_lines = read_commented_file(config_file)
  config_content = File.read(config_file)  # Keep original for display
  
  puts "Read configuration from: #{config_file}"
  puts "Found #{config_lines.length} configuration lines (comments removed)"
  
  # Create banner with default title/subtitle
  banner = Scriptorium::BannerSVG.new("Test Banner", "Generated from config file")
  
  # Write config to temporary file for banner to read
  temp_config = "temp_banner_config.txt"
  File.write(temp_config, config_content)
  
  # Parse and generate the banner
  banner.parse_header_svg
  svg_output = banner.generate_svg
  
  # Clean up temp config file
  File.delete(temp_config) if File.exist?(temp_config)
  
  # Create HTML output
  html_content = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>Banner Test - #{File.basename(config_file)}</title>
        <style>
            body { 
                font-family: Arial, sans-serif; 
                margin: 0; 
                padding: 20px; 
                background: #f5f5f5; 
            }
            .banner { 
                width: 100%; 
                max-width: 800px; 
                margin: 0 auto 20px auto; 
                border: 2px solid #007cba; 
                border-radius: 8px; 
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }
            .config { 
                background: white; 
                padding: 20px; 
                margin: 20px auto; 
                max-width: 800px;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }
            .config h3 { 
                margin-top: 0; 
                color: #333; 
            }
            .config pre { 
                background: #f8f9fa; 
                padding: 15px; 
                border-radius: 4px; 
                overflow-x: auto;
                font-family: monospace;
                font-size: 12px;
            }
            .info {
                background: white;
                padding: 20px;
                margin: 20px auto;
                max-width: 800px;
                border-radius: 8px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            }
            .processed-config {
                background: #e8f4fd;
                padding: 15px;
                margin: 10px 0;
                border-radius: 4px;
                font-family: monospace;
                font-size: 12px;
            }
        </style>
    </head>
    <body>
        <div class="banner">
            #{svg_output}
        </div>
        
        <div class="info">
            <h3>Banner Information</h3>
            <p><strong>Configuration file:</strong> #{config_file}</p>
            <p><strong>Output file:</strong> #{output_file}</p>
            <p><strong>Generated:</strong> #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}</p>
            <p><strong>Configuration lines processed:</strong> #{config_lines.length}</p>
        </div>
        
        <div class="config">
            <h3>Configuration Used (with comments)</h3>
            <pre>#{config_content}</pre>
            
            <h3>Processed Configuration (comments removed)</h3>
            <div class="processed-config">
                #{config_lines.map { |line| line.empty? ? "# (empty line)" : line }.join("\n")}
            </div>
        </div>
    </body>
    </html>
  HTML
  
  # Write the HTML file
  File.write(output_file, html_content)
  puts "Generated banner HTML: #{output_file}"
  
  # Open in browser if on macOS
  if RUBY_PLATFORM.include?('darwin')
    puts "Opening in browser..."
    system("open #{output_file}")
  else
    puts "Open #{output_file} in your browser to view the banner"
  end
end

# Main execution
if ARGV.empty?
  puts "Usage: ruby test_banner_from_file.rb <config_file> [output_file]"
  puts ""
  puts "Example:"
  puts "  ruby test_banner_from_file.rb my_banner_config.txt"
  puts "  ruby test_banner_from_file.rb my_banner_config.txt custom_output.html"
  exit 1
end

config_file = ARGV[0]
output_file = ARGV[1]  # Optional

test_banner_from_file(config_file, output_file) 