# Automated equivalents to manual banner feature tests
# 
# These tests verify the same scenarios as the manual inspection tests,
# but in an automated way that's meaningful for me to run in Cursor.
# 
# Instead of visual browser inspection, these tests:
# - Generate config files with the same syntax as manual tests
# - Create BannerSVG instances with the same parameters
# - Parse the generated HTML/JavaScript output
# - Verify that the correct SVG attributes and values are present
# - Check that gradients, colors, text positioning, etc. are correct
#
# NOTE: These tests may not use the exact same config values as manual tests.
# Manual tests focus on realistic, complex combinations for visual inspection,
# while these automated tests focus on simple, isolated feature verification
# for reliable automated testing. Both test the same underlying features
# but with different complexity levels appropriate to their purpose.
#
# This allows me to verify the banner functionality programmatically
# while you use the manual tests for visual inspection in the browser.

require_relative 'lib/scriptorium/banner_svg'
require 'fileutils'

class CursorBannerFeatureTests
  def initialize
    @test_dir = "cursor-test-temp"
    setup_test_directory
  end

  def setup_test_directory
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    Dir.mkdir(@test_dir)
  end

  def cleanup
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
  end

  def run_all_tests
    puts "Running automated banner feature tests..."
    puts "=" * 50
    
    test_count = 0
    pass_count = 0
    
    # Background color tests
    test_count += 1
    pass_count += 1 if test_red_background
    test_count += 1
    pass_count += 1 if test_blue_background
    test_count += 1
    pass_count += 1 if test_green_background
    
    # Linear gradient tests
    test_count += 1
    pass_count += 1 if test_red_to_blue_gradient
    test_count += 1
    pass_count += 1 if test_green_to_yellow_gradient
    test_count += 1
    pass_count += 1 if test_top_to_bottom_gradient
    
    # Radial gradient tests
    test_count += 1
    pass_count += 1 if test_radial_red_to_blue
    test_count += 1
    pass_count += 1 if test_radial_green_to_yellow
    
    # Text size tests
    test_count += 1
    pass_count += 1 if test_small_text
    test_count += 1
    pass_count += 1 if test_large_text
    
    # Text style tests
    test_count += 1
    pass_count += 1 if test_bold_text
    test_count += 1
    pass_count += 1 if test_italic_text
    test_count += 1
    pass_count += 1 if test_bold_italic_text
    
    # Text color tests
    test_count += 1
    pass_count += 1 if test_blue_text
    test_count += 1
    pass_count += 1 if test_green_text
    
    # Text positioning tests
    test_count += 1
    pass_count += 1 if test_left_position
    test_count += 1
    pass_count += 1 if test_center_position
    test_count += 1
    pass_count += 1 if test_right_position
    
    puts "=" * 50
    puts "Results: #{pass_count}/#{test_count} tests passed"
    
    cleanup
    pass_count == test_count
  end

  def test_banner(config_content, title, subtitle, expectations)
    # Write config file
    File.write("#{@test_dir}/config.txt", config_content)
    
    # Create banner and parse config
    Dir.chdir(@test_dir) do
      banner = BannerSVG.new(title, subtitle)
      banner.parse_header_svg
      js_output = banner.get_svg
      
      # Check each expectation
      expectations.each do |expectation|
        case expectation[:type]
        when :contains
          unless js_output.include?(expectation[:value])
            puts "❌ FAIL: Expected to contain '#{expectation[:value]}'"
            return false
          end
        when :not_contains
          if js_output.include?(expectation[:value])
            puts "❌ FAIL: Expected NOT to contain '#{expectation[:value]}'"
            return false
          end
        when :instance_variable
          actual_value = banner.instance_variable_get(expectation[:variable])
          expected_value = expectation[:value]
          unless actual_value == expected_value
            puts "❌ FAIL: #{expectation[:variable]} expected '#{expected_value}', got '#{actual_value}'"
            return false
          end
        end
      end
      
      puts "✅ PASS: #{title}"
      true
    end
  end

  # Background color tests
  def test_red_background
    test_banner(
      "back.color #ff0000",
      "Red Background",
      "Test",
      [
        { type: :contains, value: "fill='#ff0000'" },
        { type: :not_contains, value: "fill='#fff'" }
      ]
    )
  end

  def test_blue_background
    test_banner(
      "back.color #0000ff",
      "Blue Background",
      "Test",
      [
        { type: :contains, value: "fill='#0000ff'" },
        { type: :not_contains, value: "fill='#fff'" }
      ]
    )
  end

  def test_green_background
    test_banner(
      "back.color #00ff00",
      "Green Background",
      "Test",
      [
        { type: :contains, value: "fill='#00ff00'" },
        { type: :not_contains, value: "fill='#fff'" }
      ]
    )
  end

  # Linear gradient tests
  def test_red_to_blue_gradient
    test_banner(
      "back.linear red blue lr",
      "Red to Blue Gradient",
      "Test",
      [
        { type: :contains, value: "linearGradient" },
        { type: :contains, value: "stop-color:red" },
        { type: :contains, value: "stop-color:blue" },
        { type: :not_contains, value: "fill='#fff'" }
      ]
    )
  end

  def test_green_to_yellow_gradient
    test_banner(
      "back.linear green yellow lr",
      "Green to Yellow Gradient",
      "Test",
      [
        { type: :contains, value: "linearGradient" },
        { type: :contains, value: "stop-color:green" },
        { type: :contains, value: "stop-color:yellow" },
        { type: :not_contains, value: "fill='#fff'" }
      ]
    )
  end

  def test_top_to_bottom_gradient
    test_banner(
      "back.linear blue red tb",
      "Top to Bottom Gradient",
      "Test",
      [
        { type: :contains, value: "linearGradient" },
        { type: :contains, value: "stop-color:blue" },
        { type: :contains, value: "stop-color:red" },
        { type: :contains, value: "x1=\"0%\" y1=\"0%\" x2=\"0%\" y2=\"100%\"" }
      ]
    )
  end

  # Radial gradient tests
  def test_radial_red_to_blue
    test_banner(
      "back.radial red blue",
      "Radial Red to Blue",
      "Test",
      [
        { type: :contains, value: "radialGradient" },
        { type: :contains, value: "stop-color:red" },
        { type: :contains, value: "stop-color:blue" },
        { type: :not_contains, value: "fill='#fff'" }
      ]
    )
  end

  def test_radial_green_to_yellow
    test_banner(
      "back.radial green yellow",
      "Radial Green to Yellow",
      "Test",
      [
        { type: :contains, value: "radialGradient" },
        { type: :contains, value: "stop-color:green" },
        { type: :contains, value: "stop-color:yellow" },
        { type: :not_contains, value: "fill='#fff'" }
      ]
    )
  end

  # Text size tests
  def test_small_text
    test_banner(
      "title.scale 0.5\nsubtitle.scale 0.3",
      "Small Text",
      "Test",
      [
        { type: :instance_variable, variable: :@title_scale, value: 0.5 },
        { type: :instance_variable, variable: :@subtitle_scale, value: 0.3 }
      ]
    )
  end

  def test_large_text
    test_banner(
      "title.scale 1.2\nsubtitle.scale 0.8",
      "Large Text",
      "Test",
      [
        { type: :instance_variable, variable: :@title_scale, value: 1.2 },
        { type: :instance_variable, variable: :@subtitle_scale, value: 0.8 }
      ]
    )
  end

  # Text style tests
  def test_bold_text
    test_banner(
      "title.style bold",
      "Bold Text",
      "Test",
      [
        { type: :instance_variable, variable: :@title_weight, value: "bold" }
      ]
    )
  end

  def test_italic_text
    test_banner(
      "title.style italic",
      "Italic Text",
      "Test",
      [
        { type: :instance_variable, variable: :@title_style, value: "italic" }
      ]
    )
  end

  def test_bold_italic_text
    test_banner(
      "title.style bold italic",
      "Bold Italic Text",
      "Test",
      [
        { type: :instance_variable, variable: :@title_weight, value: "bold" },
        { type: :instance_variable, variable: :@title_style, value: "italic" }
      ]
    )
  end

  # Text color tests
  def test_blue_text
    test_banner(
      "text.color #0000ff",
      "Blue Text",
      "Test",
      [
        { type: :instance_variable, variable: :@text_color, value: "#0000ff" }
      ]
    )
  end

  def test_green_text
    test_banner(
      "text.color #00ff00",
      "Green Text",
      "Test",
      [
        { type: :instance_variable, variable: :@text_color, value: "#00ff00" }
      ]
    )
  end

  # Text positioning tests
  def test_left_position
    test_banner(
      "text.position left",
      "Left Position",
      "Test",
      [
        { type: :instance_variable, variable: :@text_anchor, value: "start" }
      ]
    )
  end

  def test_center_position
    test_banner(
      "text.position center",
      "Center Position",
      "Test",
      [
        { type: :instance_variable, variable: :@text_anchor, value: "middle" }
      ]
    )
  end

  def test_right_position
    test_banner(
      "text.position right",
      "Right Position",
      "Test",
      [
        { type: :instance_variable, variable: :@text_anchor, value: "end" }
      ]
    )
  end
end

# Run the tests
if __FILE__ == $0
  tests = CursorBannerFeatureTests.new
  success = tests.run_all_tests
  exit(success ? 0 : 1)
end 