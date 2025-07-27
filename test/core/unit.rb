# This test file primarily tests the core helper methods from lib/scriptorium/helpers.rb
# including file I/O operations, directory creation, system commands, and existence validation

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require 'fileutils'
require 'tempfile'

class TestReadWrite < Minitest::Test
  include Scriptorium::Helpers
  include Scriptorium::Exceptions
  include TestHelpers

  def setup
    @test_dir = "test/core_test_files"
    FileUtils.mkdir_p(@test_dir)
    Scriptorium::Repo.testing = true  # Ensure testing mode is enabled
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
  end

  # ========================================
  # need() tests
  # ========================================

  def test_need_file_basic_functionality
    file_path = "#{@test_dir}/test_file.txt"
    File.write(file_path, "test content")
    
    result = need(:file, file_path)
    assert_equal file_path, result
  end

  def test_need_dir_basic_functionality
    dir_path = "#{@test_dir}/test_dir"
    Dir.mkdir(dir_path)
    
    result = need(:dir, dir_path)
    assert_equal dir_path, result
  end

  def test_need_with_custom_exception
    file_path = "#{@test_dir}/nonexistent.txt"
    
    # Create a simple custom exception for testing
    custom_error_class = Class.new(StandardError) do
      def self.call(path)
        new("Custom error for: #{path}")
      end
    end
    
    begin
      need(:file, file_path, custom_error_class)
      flunk "Expected need() to raise an error"
    rescue custom_error_class => e
      assert_match /Custom error for: #{file_path}/, e.message
    end
  end

  def test_need_nil_path_raises_error
    assert_raises(RuntimeError) do
      need(:file, nil)
    end
  end

  def test_need_empty_path_raises_error
    assert_raises(RuntimeError) do
      need(:file, "")
    end
  end

  def test_need_whitespace_path_raises_error
    assert_raises(RuntimeError) do
      need(:file, "   ")
    end
  end

  def test_need_invalid_type_raises_error
    assert_raises(RuntimeError) do
      need(:invalid, "some/path")
    end
  end

  def test_need_file_nonexistent_raises_error
    file_path = "#{@test_dir}/nonexistent.txt"
    
    assert_raises(RuntimeError) do
      need(:file, file_path)
    end
  end

  def test_need_dir_nonexistent_raises_error
    dir_path = "#{@test_dir}/nonexistent_dir"
    
    assert_raises(RuntimeError) do
      need(:dir, dir_path)
    end
  end

  # ========================================
  # system! tests
  # ========================================

  def test_system_basic_functionality
    # Test a simple command that should succeed
    result = system!("echo 'test'", "basic echo test")
    assert result
  end

  def test_system_with_description
    # Test that description is included in error message
    begin
      system!("false", "testing failure")
      flunk "Expected system! to raise an error"
    rescue RuntimeError => e
      assert_match /testing failure/, e.message
      assert_match /Command failed/, e.message
    end
  end

  def test_system_nil_command_raises_error
    assert_raises(RuntimeError) do
      system!(nil)
    end
  end

  def test_system_empty_command_raises_error
    assert_raises(RuntimeError) do
      system!("")
    end
  end

  def test_system_whitespace_command_raises_error
    assert_raises(RuntimeError) do
      system!("   ")
    end
  end

  def test_system_failing_command_raises_error
    assert_raises(RuntimeError) do
      system!("false")
    end
  end

  def test_system_nonexistent_command_raises_error
    assert_raises(RuntimeError) do
      system!("nonexistent_command_that_should_fail")
    end
  end

  # ========================================
  # make_dir tests
  # ========================================

  def test_make_dir_basic_functionality
    dir_path = "#{@test_dir}/new_dir"
    
    make_dir(dir_path)
    
    assert Dir.exist?(dir_path)
  end

  def test_make_dir_with_parents
    dir_path = "#{@test_dir}/nested/deep/path"
    
    make_dir(dir_path, create_parents: true)
    
    assert Dir.exist?(dir_path)
    assert Dir.exist?("#{@test_dir}/nested")
    assert Dir.exist?("#{@test_dir}/nested/deep")
  end

  def test_make_dir_existing_directory
    dir_path = "#{@test_dir}/existing_dir"
    Dir.mkdir(dir_path)
    
    # Should not raise an error
    make_dir(dir_path)
    
    assert Dir.exist?(dir_path)
  end

  def test_make_dir_nil_path_raises_error
    assert_raises(RuntimeError) do
      make_dir(nil)
    end
  end

  def test_make_dir_empty_path_raises_error
    assert_raises(RuntimeError) do
      make_dir("")
    end
  end

  def test_make_dir_whitespace_path_raises_error
    assert_raises(RuntimeError) do
      make_dir("   ")
    end
  end

  def test_make_dir_permission_denied_simulation
    # Create a read-only directory
    read_only_dir = "#{@test_dir}/readonly"
    Dir.mkdir(read_only_dir)
    FileUtils.chmod(0444, read_only_dir)
    
    file_path = "#{read_only_dir}/test_dir"
    
    # This should raise a permission denied error
    assert_raises(RuntimeError) do
      make_dir(file_path)
    end
    
    # Clean up
    FileUtils.chmod(0755, read_only_dir)
  end

  # ========================================
  # write_file tests
  # ========================================

  def test_write_file_basic_functionality
    file_path = "#{@test_dir}/basic.txt"
    content = ["line1", "line2", "line3"]
    
    write_file(file_path, *content)
    
    assert File.exist?(file_path)
    assert_equal content.join("\n") + "\n", File.read(file_path)
  end

  def test_write_file_creates_parent_directories
    file_path = "#{@test_dir}/nested/deep/path/file.txt"
    content = ["test content"]
    
    write_file(file_path, *content)
    
    assert File.exist?(file_path)
    assert File.exist?("#{@test_dir}/nested/deep/path")
  end

  def test_write_file_empty_content
    file_path = "#{@test_dir}/empty.txt"
    
    write_file(file_path)
    
    assert File.exist?(file_path)
    assert_equal "", File.read(file_path)
  end

  def test_write_file_single_line
    file_path = "#{@test_dir}/single.txt"
    content = "single line content"
    
    write_file(file_path, content)
    
    assert File.exist?(file_path)
    assert_equal content + "\n", File.read(file_path)
  end

  def test_write_file_multiple_lines
    file_path = "#{@test_dir}/multi.txt"
    content = ["first line", "second line", "third line"]
    
    write_file(file_path, *content)
    
    assert File.exist?(file_path)
    expected = content.join("\n") + "\n"
    assert_equal expected, File.read(file_path)
  end

  def test_write_file_nil_path_raises_error
    assert_raises(RuntimeError) do
      write_file(nil, "content")
    end
  end

  def test_write_file_empty_path_raises_error
    assert_raises(RuntimeError) do
      write_file("", "content")
    end
  end

  def test_write_file_whitespace_path_raises_error
    assert_raises(RuntimeError) do
      write_file("   ", "content")
    end
  end

  def test_write_file_permission_denied_simulation
    # Create a read-only directory
    read_only_dir = "#{@test_dir}/readonly"
    FileUtils.mkdir_p(read_only_dir)
    FileUtils.chmod(0444, read_only_dir)
    
    file_path = "#{read_only_dir}/test.txt"
    
    # This should raise a permission denied error
    assert_raises(RuntimeError) do
      write_file(file_path, "content")
    end
    
    # Clean up
    FileUtils.chmod(0755, read_only_dir)
  end

  # ========================================
  # read_file tests
  # ========================================

  def test_read_file_basic_functionality
    file_path = "#{@test_dir}/read_test.txt"
    content = "line1\nline2\nline3"
    File.write(file_path, content)
    
    result = read_file(file_path)
    
    assert_equal content, result
  end

  def test_read_file_as_lines
    file_path = "#{@test_dir}/lines_test.txt"
    content = "line1\nline2\nline3"
    File.write(file_path, content)
    
    result = read_file(file_path, lines: true)
    
    assert_equal ["line1\n", "line2\n", "line3"], result
  end

  def test_read_file_as_lines_with_chomp
    file_path = "#{@test_dir}/chomp_test.txt"
    content = "line1\nline2\nline3\n"
    File.write(file_path, content)
    
    result = read_file(file_path, lines: true, chomp: true)
    
    assert_equal ["line1", "line2", "line3"], result
  end

  def test_read_file_as_lines_without_chomp
    file_path = "#{@test_dir}/no_chomp_test.txt"
    content = "line1\nline2\nline3\n"
    File.write(file_path, content)
    
    result = read_file(file_path, lines: true, chomp: false)
    
    assert_equal ["line1\n", "line2\n", "line3\n"], result
  end

  def test_read_file_missing_file_with_fallback
    file_path = "#{@test_dir}/nonexistent.txt"
    fallback = "fallback content"
    
    result = read_file(file_path, missing_fallback: fallback)
    
    assert_equal fallback, result
  end

  def test_read_file_missing_file_without_fallback_raises_error
    file_path = "#{@test_dir}/nonexistent.txt"
    
    assert_raises(RuntimeError) do
      read_file(file_path)
    end
  end

  def test_read_file_nil_path_raises_error
    assert_raises(RuntimeError) do
      read_file(nil)
    end
  end

  def test_read_file_empty_path_raises_error
    assert_raises(RuntimeError) do
      read_file("")
    end
  end

  def test_read_file_whitespace_path_raises_error
    assert_raises(RuntimeError) do
      read_file("   ")
    end
  end

  def test_read_file_permission_denied_simulation
    # Create a file and make it unreadable
    file_path = "#{@test_dir}/unreadable.txt"
    File.write(file_path, "content")
    FileUtils.chmod(0000, file_path)
    
    assert_raises(RuntimeError) do
      read_file(file_path)
    end
    
    # Clean up
    FileUtils.chmod(0644, file_path)
  end

  def test_read_file_empty_file
    file_path = "#{@test_dir}/empty.txt"
    File.write(file_path, "")
    
    result = read_file(file_path)
    
    assert_equal "", result
  end

  def test_read_file_empty_file_as_lines
    file_path = "#{@test_dir}/empty_lines.txt"
    File.write(file_path, "")
    
    result = read_file(file_path, lines: true)
    
    assert_equal [], result
  end

  def test_read_file_single_line
    file_path = "#{@test_dir}/single_line.txt"
    content = "single line"
    File.write(file_path, content)
    
    result = read_file(file_path)
    
    assert_equal content, result
  end

  def test_read_file_single_line_as_lines
    file_path = "#{@test_dir}/single_line.txt"
    content = "single line"
    File.write(file_path, content)
    
    result = read_file(file_path, lines: true)
    
    assert_equal [content], result
  end

  def test_read_file_with_trailing_newline
    file_path = "#{@test_dir}/trailing_newline.txt"
    content = "line1\nline2\n"
    File.write(file_path, content)
    
    result = read_file(file_path)
    
    assert_equal content, result
  end

  def test_read_file_with_trailing_newline_as_lines
    file_path = "#{@test_dir}/trailing_newline.txt"
    content = "line1\nline2\n"
    File.write(file_path, content)
    
    result = read_file(file_path, lines: true)
    
    assert_equal ["line1\n", "line2\n"], result
  end

  def test_read_file_with_trailing_newline_as_lines_no_chomp
    file_path = "#{@test_dir}/trailing_newline.txt"
    content = "line1\nline2\n"
    File.write(file_path, content)
    
    result = read_file(file_path, lines: true, chomp: false)
    
    assert_equal ["line1\n", "line2\n"], result
  end

  # ========================================
  # Integration tests
  # ========================================

  def test_write_then_read_cycle
    file_path = "#{@test_dir}/cycle.txt"
    original_content = ["first line", "second line", "third line"]
    
    # Write content
    write_file(file_path, *original_content)
    
    # Read it back
    read_content = read_file(file_path)
    
    # Verify
    expected_content = original_content.join("\n") + "\n"
    assert_equal expected_content, read_content
  end

  def test_write_then_read_as_lines_cycle
    file_path = "#{@test_dir}/cycle_lines.txt"
    original_content = ["first line", "second line", "third line"]
    
    # Write content
    write_file(file_path, *original_content)
    
    # Read it back as lines
    read_content = read_file(file_path, lines: true)
    
    # Verify
    assert_equal ["first line\n", "second line\n", "third line\n"], read_content
  end

  def test_multiple_write_operations
    file_path = "#{@test_dir}/multiple.txt"
    
    # First write
    write_file(file_path, "first content")
    assert_equal "first content\n", File.read(file_path)
    
    # Second write (should overwrite)
    write_file(file_path, "second content")
    assert_equal "second content\n", File.read(file_path)
  end

  def test_write_file_with_special_characters
    file_path = "#{@test_dir}/special.txt"
    content = ["line with spaces", "line\twith\ttabs", "line with # comments"]
    
    write_file(file_path, *content)
    
    result = read_file(file_path, lines: true)
    assert_equal ["line with spaces\n", "line\twith\ttabs\n", "line with # comments\n"], result
  end

  def test_read_file_with_unicode_content
    file_path = "#{@test_dir}/unicode.txt"
    content = ["café", "naïve", "résumé", "über"]
    
    write_file(file_path, *content)
    
    result = read_file(file_path, lines: true)
    assert_equal ["café\n", "naïve\n", "résumé\n", "über\n"], result
  end

  # ========================================
  # Edge case tests
  # ========================================

  def test_write_file_with_nil_lines
    file_path = "#{@test_dir}/nil_lines.txt"
    
    write_file(file_path, nil, "content", nil)
    
    result = read_file(file_path, lines: true)
    assert_equal ["\n", "content\n", "\n"], result
  end

  def test_write_file_with_empty_strings
    file_path = "#{@test_dir}/empty_strings.txt"
    
    write_file(file_path, "", "content", "")
    
    result = read_file(file_path, lines: true)
    assert_equal ["\n", "content\n", "\n"], result
  end

  def test_read_file_missing_fallback_with_lines_option
    file_path = "#{@test_dir}/nonexistent.txt"
    fallback = ["fallback", "lines"]
    
    result = read_file(file_path, lines: true, missing_fallback: fallback)
    
    assert_equal fallback, result
  end

  def test_read_file_missing_fallback_with_chomp_option
    file_path = "#{@test_dir}/nonexistent.txt"
    fallback = ["fallback", "lines"]
    
    result = read_file(file_path, lines: true, chomp: true, missing_fallback: fallback)
    
    assert_equal fallback, result
  end

  def test_write_file_very_long_line
    file_path = "#{@test_dir}/long_line.txt"
    long_line = "x" * 10000
    
    write_file(file_path, long_line)
    
    result = read_file(file_path)
    assert_equal long_line + "\n", result
  end

  def test_write_file_many_lines
    file_path = "#{@test_dir}/many_lines.txt"
    many_lines = (1..1000).map { |i| "line #{i}" }
    
    write_file(file_path, *many_lines)
    
    result = read_file(file_path, lines: true)
    expected_lines = many_lines.map { |line| line + "\n" }
    assert_equal expected_lines, result
  end

  # ========================================
  # Moved helper method tests (3 tests)
  # ========================================

  def test_change_config
    cfg_file = "#{@test_dir}/myconfig.txt"
    File.open(cfg_file, "w") do |f|
      f.puts <<~EOS
        alpha foo  # nothing much
        beta  bar  # meh again
        gamma baz  # whatever
      EOS
    end
    change_config(cfg_file, "beta", "new-value")
    lines = File.readlines(cfg_file).map(&:chomp)
    assert lines[0] == "alpha foo  # nothing much",     "Expected alpha text"
    assert lines[1] == "beta  new-value  # meh again",  "Expected beta text"
    assert lines[2] == "gamma baz  # whatever",         "Expected gamma text"
  end

  def test_read_commented_file
    # Setup: Create a temporary test config file
    test_file = "#{@test_dir}/test_config.txt"
    File.open(test_file, "w") do |f|
      f.puts "# This is a comment"
      f.puts ""
      f.puts "header  20% # This is a header line with a comment"
      f.puts "footer  # This is a footer line with another comment"
      f.puts "# Another full-line comment"
      f.puts "main    # Main content area"
    end
  
    # Expected result: an array of non-comment lines, with comments stripped
    expected_result = ["header  20%", "footer", "main"]
  
    # Run the method
    result = read_commented_file(test_file)
  
    # Assert the result matches the expected array
    assert_equal expected_result, result
  end
  
  def test_get_asset_path
    name = "back-icon.png"
    result = get_asset_path(name)
    assert result == "lib/scriptorium/dev_assets/#{name}", "Expected #{name} to be in dev_assets (got #{result})"
    assert_raises(AssetNotFound) { get_asset_path("nonexistent.png") }
  end

  # ========================================
  # New helper method tests
  # ========================================

  def test_slugify_basic
    result = slugify(42, "My Test Post")
    assert_equal "0042-my-test-post", result
  end

  def test_slugify_with_special_characters
    result = slugify(1, "Post with & < > \" ' characters!")
    assert_equal "0001-post-with-characters", result
  end

  def test_slugify_with_underscores_and_hyphens
    result = slugify(123, "Post with_underscores-and-hyphens")
    assert_equal "0123-post-with-underscores-and-hyphens", result
  end

  def test_slugify_with_multiple_spaces
    result = slugify(5, "Post   with   multiple   spaces")
    assert_equal "0005-post-with-multiple-spaces", result
  end

  def test_slugify_with_leading_trailing_hyphens
    result = slugify(99, "-Post with leading/trailing hyphens-")
    assert_equal "0099-post-with-leadingtrailing-hyphens", result
  end

  def test_escape_html_basic
    result = escape_html("<script>alert('test')</script>")
    assert_equal "&lt;script&gt;alert(&#39;test&#39;)&lt;/script&gt;", result
  end

  def test_escape_html_with_quotes
    result = escape_html('He said "Hello" and she said \'Hi\'')
    assert_equal "He said &quot;Hello&quot; and she said &#39;Hi&#39;", result
  end

  def test_escape_html_with_ampersand
    result = escape_html("Fish & Chips")
    assert_equal "Fish &amp; Chips", result
  end

  def test_escape_html_with_mixed_content
    result = escape_html('<a href="test">Link & Text</a>')
    assert_equal "&lt;a href=&quot;test&quot;&gt;Link &amp; Text&lt;/a&gt;", result
  end

  def test_getvars_basic
    config_file = "#{@test_dir}/config.txt"
    File.write(config_file, <<~EOS)
      title My Blog
      subtitle A test blog
      theme standard
    EOS
    
    result = getvars(config_file)
    assert_equal "My Blog", result[:title]
    assert_equal "A test blog", result[:subtitle]
    assert_equal "standard", result[:theme]
  end

  def test_getvars_with_comments
    config_file = "#{@test_dir}/config_with_comments.txt"
    File.write(config_file, <<~EOS)
      # This is a comment
      title My Blog # Another comment
      subtitle A test blog
      # Empty line below
      
      theme standard
    EOS
    
    result = getvars(config_file)
    assert_equal "My Blog", result[:title]
    assert_equal "A test blog", result[:subtitle]
    assert_equal "standard", result[:theme]
    assert_equal 4, result.size  # Including the empty line
  end

  def test_getvars_with_empty_values
    config_file = "#{@test_dir}/config_empty.txt"
    File.write(config_file, <<~EOS)
      title My Blog
      subtitle
      theme standard
    EOS
    
    result = getvars(config_file)
    assert_equal "My Blog", result[:title]
    assert_nil result[:subtitle]  # When no value after key, split returns nil
    assert_equal "standard", result[:theme]
  end

  def test_d4_basic
    assert_equal "0001", d4(1)
    assert_equal "0042", d4(42)
    assert_equal "0123", d4(123)
    assert_equal "9999", d4(9999)
  end

  def test_d4_with_large_numbers
    assert_equal "10000", d4(10000)
    assert_equal "12345", d4(12345)
  end

  def test_substitute_with_hash
    vars = {title: "My Title", content: "My Content"}
    template = "Title: %{title}\nContent: %{content}"
    
    result = substitute(vars, template)
    assert_equal "Title: My Title\nContent: My Content", result
  end

  def test_substitute_with_object
    # Create a mock object with vars method
    mock_obj = Object.new
    def mock_obj.vars
      {title: "My Title", content: "My Content"}
    end
    
    template = "Title: %{title}\nContent: %{content}"
    result = substitute(mock_obj, template)
    assert_equal "Title: My Title\nContent: My Content", result
  end

  def test_substitute_with_missing_vars
    vars = {title: "My Title"}
    template = "Title: %{title}\nContent: %{content}"
    
    # The substitute method raises KeyError for missing keys
    assert_raises(KeyError) do
      substitute(vars, template)
    end
  end

  def test_make_tree_basic
    tree_text = <<~EOS
      test_tree/
      ├── file1.txt
      ├── dir1/
      │   ├── file2.txt
      │   └── subdir/
      │       └── file3.txt
      └── file4.txt
    EOS
    
    make_tree(@test_dir, tree_text)
    
    assert File.exist?("#{@test_dir}/test_tree/file1.txt")
    assert File.exist?("#{@test_dir}/test_tree/dir1/file2.txt")
    assert File.exist?("#{@test_dir}/test_tree/dir1/subdir/file3.txt")
    assert File.exist?("#{@test_dir}/test_tree/file4.txt")
  end

  def test_make_tree_with_comments
    tree_text = <<~EOS
      test_tree_with_comments/
      ├── file1.txt # This is a comment
      ├── dir1/     # Another comment
      │   └── file2.txt
      └── file3.txt
    EOS
    
    make_tree(@test_dir, tree_text)
    
    assert File.exist?("#{@test_dir}/test_tree_with_comments/file1.txt")
    assert File.exist?("#{@test_dir}/test_tree_with_comments/dir1/file2.txt")
    assert File.exist?("#{@test_dir}/test_tree_with_comments/file3.txt")
  end
end 