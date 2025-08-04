#!/usr/bin/env ruby

require_relative '../../lib/scriptorium'
include Scriptorium::Helpers

# Simple banner test from configuration file
def test_banner_from_file(config_file, title = nil, subtitle = nil, output_file = nil)
  # Default output file if not specified
  output_file ||= "banner_output.html"
  
  # Default titles if not specified
  title ||= "Test Banner"
  subtitle ||= "Generated from config file"
  
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
  puts "Title: #{title}"
  puts "Subtitle: #{subtitle}"
  
  # Create banner with the actual titles from View
  banner = Scriptorium::BannerSVG.new(title, subtitle)
  
  # Write config to temporary file for banner to read
  temp_config = "config.txt"
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
            <h3>Configuration Used </h3>
            <pre>#{config_content}</pre>
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
  puts "Usage: ruby make_banner.rb <config_file> [title] [subtitle] [output_file]"
  puts ""
  puts "Example:"
  puts "  ruby make_banner.rb my_banner_config.txt"
  puts "  ruby make_banner.rb my_banner_config.txt 'My Blog' 'A subtitle'"
  puts "  ruby make_banner.rb my_banner_config.txt 'My Blog' 'A subtitle' custom_output.html"
  exit 1
end

config_file = ARGV[0]
title = ARGV[1]      # Optional
subtitle = ARGV[2]   # Optional
output_file = ARGV[3] # Optional

test_banner_from_file(config_file, title, subtitle, output_file) 
