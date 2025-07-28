# Automated equivalents to manual banner combination tests
# 
# These tests verify sensible combinations of banner features,
# but in an automated way that's meaningful for me to run in Cursor.
# 
# Instead of visual browser inspection, these tests:
# - Generate config files with the same syntax as manual combination tests
# - Create BannerSVG instances with the same parameters
# - Parse the generated HTML/JavaScript output
# - Verify that multiple features work together correctly
# - Check that gradients, colors, text positioning, etc. are all applied
#
# NOTE: These tests may not use the exact same config values as manual tests.
# Manual tests focus on realistic, complex combinations for visual inspection,
# while these automated tests focus on simple, isolated feature verification
# for reliable automated testing. Both test the same underlying features
# but with different complexity levels appropriate to their purpose.
#
# This allows me to verify that banner features work together properly
# while you use the manual tests for visual inspection in the browser.

require_relative 'lib/scriptorium/banner_svg'
require 'fileutils'

class CursorBannerCombinationTests
  def initialize
    @test_dir = "cursor-combination-test-temp"
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
    puts "Running automated banner combination tests..."
    puts "=" * 50
    
    test_count = 0
    pass_count = 0
    
    # Combination tests
    test_count += 1
    pass_count += 1 if test_red_gradient_bold_center
    test_count += 1
    pass_count += 1 if test_blue_gradient_large_italic
    test_count += 1
    pass_count += 1 if test_green_radial_small_right
    test_count += 1
    pass_count += 1 if test_yellow_gradient_blue_text
    test_count += 1
    pass_count += 1 if test_complex_combination
    
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

  # Red gradient with bold text and center positioning
  def test_red_gradient_bold_center
    test_banner(
      "back.linear red blue lr\ntitle.style bold\ntext.position center",
      "Red Gradient Bold Center",
      "Test",
      [
        { type: :contains, value: "linearGradient" },
        { type: :contains, value: "stop-color:red" },
        { type: :contains, value: "stop-color:blue" },
        { type: :instance_variable, variable: :@title_weight, value: "bold" },
        { type: :instance_variable, variable: :@text_anchor, value: "middle" }
      ]
    )
  end

  # Blue gradient with large text and italic style
  def test_blue_gradient_large_italic
    test_banner(
      "back.linear blue green tb\ntitle.scale 1.2\ntitle.style italic",
      "Blue Gradient Large Italic",
      "Test",
      [
        { type: :contains, value: "linearGradient" },
        { type: :contains, value: "stop-color:blue" },
        { type: :contains, value: "stop-color:green" },
        { type: :instance_variable, variable: :@title_scale, value: 1.2 },
        { type: :instance_variable, variable: :@title_style, value: "italic" }
      ]
    )
  end

  # Green radial gradient with small text and right positioning
  def test_green_radial_small_right
    test_banner(
      "back.radial green yellow\ntitle.scale 0.6\ntext.position right",
      "Green Radial Small Right",
      "Test",
      [
        { type: :contains, value: "radialGradient" },
        { type: :contains, value: "stop-color:green" },
        { type: :contains, value: "stop-color:yellow" },
        { type: :instance_variable, variable: :@title_scale, value: 0.6 },
        { type: :instance_variable, variable: :@text_anchor, value: "end" }
      ]
    )
  end

  # Yellow gradient with blue text
  def test_yellow_gradient_blue_text
    test_banner(
      "back.linear yellow orange lr\ntext.color #0000ff",
      "Yellow Gradient Blue Text",
      "Test",
      [
        { type: :contains, value: "linearGradient" },
        { type: :contains, value: "stop-color:yellow" },
        { type: :contains, value: "stop-color:orange" },
        { type: :instance_variable, variable: :@text_color, value: "#0000ff" }
      ]
    )
  end

  # Complex combination with multiple features
  def test_complex_combination
    test_banner(
      "back.radial red blue\ntitle.scale 1.1\nsubtitle.scale 0.6\ntitle.style bold italic\ntext.color #00ff00\ntext.position center",
      "Complex Combination",
      "Test Subtitle",
      [
        { type: :contains, value: "radialGradient" },
        { type: :contains, value: "stop-color:red" },
        { type: :contains, value: "stop-color:blue" },
        { type: :instance_variable, variable: :@title_scale, value: 1.1 },
        { type: :instance_variable, variable: :@subtitle_scale, value: 0.6 },
        { type: :instance_variable, variable: :@title_weight, value: "bold" },
        { type: :instance_variable, variable: :@title_style, value: "italic" },
        { type: :instance_variable, variable: :@text_color, value: "#00ff00" },
        { type: :instance_variable, variable: :@text_anchor, value: "middle" }
      ]
    )
  end
end

# Run the tests
if __FILE__ == $0
  tests = CursorBannerCombinationTests.new
  success = tests.run_all_tests
  exit(success ? 0 : 1)
end 