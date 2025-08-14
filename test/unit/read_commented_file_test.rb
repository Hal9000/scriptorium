require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

# Simple class to access the Helpers method
class TestHelper
  include Scriptorium::Helpers
end

class TestReadCommentedFile < Minitest::Test
  include Scriptorium::Helpers
  
  def setup
    ENV['DBC_DISABLED'] = 'true'
    @test_file = "test_comments.txt"
    @helper = TestHelper.new
    @banner = Scriptorium::BannerSVG.new("Test", "Subtitle")
  end

  def teardown
    File.delete(@test_file) if File.exist?(@test_file)
  end

  def test_comprehensive_comparison
    # Test file with comprehensive comment scenarios
    test_content = <<~CONTENT
      # Full line comment
      simple_line
      line_with_inline_comment # this is a comment
      line_with_spaces    # comment with spaces
      line_with_tab	# comment with tab
      
      # Lines with # in values (should be preserved)
      color #ff0000
      color #ff0000 # this is red
      url http://example.com#fragment
      url http://example.com#fragment # URL with fragment
      hex #123456
      hex #123456 # hex value
      
      # Edge cases
      line#nospace
      line#nospace # comment
      line # comment with # in it
      line # comment with # and spaces
      
      # Multiple # characters
      multiple #ff0000 #ff0001 #ff0002
      multiple #ff0000 #ff0001 #ff0002 # three colors
      
      # Empty lines and whitespace
      
      line_after_empty
        # indented comment
      indented_line
      
      # Final line
      last_line
    CONTENT
    
    write_file(@test_file, test_content)
    
    helpers_result = @helper.read_commented_file(@test_file)
    banner_result = @banner.read_commented_file(@test_file)
    
    # Both methods should now produce identical results
    assert_equal helpers_result, banner_result, "Both methods should produce identical results"
  end

  def test_whitespace_edge_cases
    test_cases = [
      {
        name: "leading spaces",
        content: "  line with leading spaces",
        expected: ["line with leading spaces"]
      },
      {
        name: "leading tabs",
        content: "\tline with leading tab",
        expected: ["line with leading tab"]
      },
      {
        name: "mixed leading whitespace",
        content: " \t line with mixed whitespace",
        expected: ["line with mixed whitespace"]
      },
      {
        name: "trailing spaces",
        content: "line with trailing spaces  ",
        expected: ["line with trailing spaces"]
      },
      {
        name: "trailing tabs",
        content: "line with trailing tab\t",
        expected: ["line with trailing tab"]
      },
      {
        name: "line with only spaces",
        content: "   ",
        expected: []
      },
      {
        name: "line with only tabs",
        content: "\t\t",
        expected: []
      },
      {
        name: "line with only mixed whitespace",
        content: " \t \t ",
        expected: []
      },
      {
        name: "line with spaces and comment",
        content: "   line # comment",
        expected: ["line"]
      },
      {
        name: "line with tabs and comment",
        content: "\t\tline # comment",
        expected: ["line"]
      },
      {
        name: "line with mixed whitespace and comment",
        content: " \t line # comment",
        expected: ["line"]
      },
      {
        name: "line with spaces and # in value",
        content: "   color #ff0000",
        expected: ["color #ff0000"]
      },
      {
        name: "line with tabs and # in value",
        content: "\t\tcolor #ff0000",
        expected: ["color #ff0000"]
      },
      {
        name: "line with mixed whitespace and # in value",
        content: " \t color #ff0000",
        expected: ["color #ff0000"]
      },
      {
        name: "line with spaces and # in value and comment",
        content: "   color #ff0000 # this is red",
        expected: ["color #ff0000"]
      },
      {
        name: "line with tabs and # in value and comment",
        content: "\t\tcolor #ff0000 # this is red",
        expected: ["color #ff0000"]
      },
      {
        name: "line with mixed whitespace and # in value and comment",
        content: " \t color #ff0000 # this is red",
        expected: ["color #ff0000"]
      },
      {
        name: "indented comment",
        content: "  # indented comment",
        expected: []
      },
      {
        name: "tabbed comment",
        content: "\t# tabbed comment",
        expected: []
      },
      {
        name: "mixed whitespace comment",
        content: " \t # mixed whitespace comment",
        expected: []
      },
      {
        name: "line with internal spaces",
        content: "line with  multiple   spaces",
        expected: ["line with  multiple   spaces"]
      },
      {
        name: "line with internal tabs",
        content: "line\twith\ttabs",
        expected: ["line\twith\ttabs"]
      }
    ]

    test_cases.each do |test_case|
      write_file(@test_file, test_case[:content])
      
      helpers_result = @helper.read_commented_file(@test_file)
      banner_result = @banner.read_commented_file(@test_file)
      
      assert_equal test_case[:expected], helpers_result, "Helpers failed for: #{test_case[:name]}"
      assert_equal test_case[:expected], banner_result, "BannerSVG failed for: #{test_case[:name]}"
    end
  end

  def test_individual_cases
    test_cases = [
      {
        name: "simple line",
        content: "simple_line",
        expected: ["simple_line"]
      },
      {
        name: "line with inline comment",
        content: "line # comment",
        expected: ["line"]
      },
      {
        name: "line with # in value",
        content: "color #ff0000",
        expected: ["color #ff0000"]
      },
      {
        name: "line with # in value and comment",
        content: "color #ff0000 # this is red",
        expected: ["color #ff0000"]
      },
      {
        name: "line with # in URL",
        content: "url http://example.com#fragment",
        expected: ["url http://example.com#fragment"]
      },
      {
        name: "line with # in URL and comment",
        content: "url http://example.com#fragment # URL with fragment",
        expected: ["url http://example.com#fragment"]
      },
      {
        name: "line with # no space",
        content: "line#nospace",
        expected: ["line#nospace"]
      },
      {
        name: "line with # no space and comment",
        content: "line#nospace # comment",
        expected: ["line#nospace"]
      },
      {
        name: "comment with # in it",
        content: "line # comment with # in it",
        expected: ["line"]
      },
      {
        name: "multiple # characters",
        content: "multiple #ff0000 #ff0001 #ff0002",
        expected: ["multiple #ff0000 #ff0001 #ff0002"]
      }
    ]

    test_cases.each do |test_case|
      write_file(@test_file, test_case[:content])
      
      helpers_result = @helper.read_commented_file(@test_file)
      banner_result = @banner.read_commented_file(@test_file)
      
      assert_equal test_case[:expected], helpers_result, "Helpers failed for: #{test_case[:name]}"
      assert_equal test_case[:expected], banner_result, "BannerSVG failed for: #{test_case[:name]}"
    end
  end

  def test_edge_cases
    # Test with empty file
    write_file(@test_file, "")
    helpers_result = @helper.read_commented_file(@test_file)
    banner_result = @banner.read_commented_file(@test_file)
    assert_equal helpers_result, banner_result, "Empty file should produce same result"
    
    # Test with file that doesn't exist
    helpers_result = @helper.read_commented_file("nonexistent.txt")
    banner_result = @banner.read_commented_file("nonexistent.txt")
    assert_equal helpers_result, banner_result, "Nonexistent file should produce same result"
    
    # Test with only comments
    write_file(@test_file, "# Only comments\n# Another comment\n  # Indented comment")
    helpers_result = @helper.read_commented_file(@test_file)
    banner_result = @banner.read_commented_file(@test_file)
    assert_equal helpers_result, banner_result, "File with only comments should produce same result"
  end
end 