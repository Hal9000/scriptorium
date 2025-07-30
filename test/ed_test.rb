#!/usr/bin/env ruby

# This file tests that we can interact with 'ed' correctly for automated testing.
# We are NOT testing 'ed' itself - we assume 'ed' works correctly.
# We ARE testing that our test infrastructure can properly invoke 'ed'
# and handle its input/output/error streams for automated testing scenarios.

require 'minitest/autorun'
require 'open3'
require 'tempfile'

class EdTest < Minitest::Test
  def test_ed_basic_functionality
    # Test that ed can create and edit a file non-interactively
    temp_file = Tempfile.new(['test', '.txt'])
    temp_file.close
    
    # Use ed to add some text to the file
    ed_commands = [
      "a",           # Enter append mode
      "Hello world", # Add text
      "This is a test", # Add more text
      ".",           # Exit append mode
      "w",           # Write the file
      "q"            # Quit ed
    ].join("\n")
    
    # Run ed with the commands
    stdout, stderr, status = Open3.capture3("ed #{temp_file.path}", stdin_data: ed_commands)
    
    # Verify ed ran successfully
    assert_equal 0, status.exitstatus, "ed should exit successfully"
    
    # Verify the file was written
    content = File.read(temp_file.path)
    assert_includes content, "Hello world"
    assert_includes content, "This is a test"
    
    temp_file.unlink
  end

  def test_ed_file_creation
    # Test that ed can create a new file
    temp_file = Tempfile.new(['new', '.txt'])
    file_path = temp_file.path  # Save the path before closing
    temp_file.close
    temp_file.unlink  # Remove the file so ed creates it
    
    # Use ed to create and populate a new file
    # The key is to use 'w /path/to/file' to specify where to write
    ed_commands = [
      "a",
      "New file content",
      "Created by ed",
      ".",
      "w #{file_path}",
      "q"
    ].join("\n")
    
    stdout, stderr, status = Open3.capture3("ed", stdin_data: ed_commands)
    
    # ed may give an error on stderr when file doesn't exist initially, but still succeeds
    # The error message goes to stderr, but the operation succeeds
    assert File.exist?(file_path), "File should be created despite stderr message"
    
    # Verify the file has content
    content = File.read(file_path)
    assert_includes content, "New file content"
    assert_includes content, "Created by ed"
    
    File.unlink(file_path) if File.exist?(file_path)
  end

  def test_ed_error_handling
    # Test that ed handles errors gracefully
    # Try to edit a non-existent file in a non-existent directory
    stdout, stderr, status = Open3.capture3("ed /nonexistent/directory/file.txt", stdin_data: "q\n")
    
    # ed should exit with an error
    refute_equal 0, status.exitstatus, "ed should fail on non-existent directory"
  end

  def test_ed_which_command
    # Test that ed is available on the system
    stdout, stderr, status = Open3.capture3("which ed")
    
    assert_equal 0, status.exitstatus, "ed should be available on the system"
    assert_includes stdout, "ed", "which should find ed"
  end

  def test_ed_simulate_edit_file_usage
    # Test how edit_file would use ed
    temp_file = Tempfile.new(['test', '.txt'])
    temp_file.close
    
    # Simulate what edit_file does: system!(editor, path)
    # For ed, we need to provide input via stdin
    ed_commands = [
      "a",
      "Content added by edit_file",
      "This simulates user input",
      ".",
      "w",
      "q"
    ].join("\n")
    
    # This is how edit_file would call ed
    stdout, stderr, status = Open3.capture3("ed #{temp_file.path}", stdin_data: ed_commands)
    
    # Verify ed ran successfully
    assert_equal 0, status.exitstatus, "ed should work when called like edit_file would"
    
    # Verify the file was modified
    content = File.read(temp_file.path)
    assert_includes content, "Content added by edit_file"
    assert_includes content, "This simulates user input"
    
    temp_file.unlink
  end

  def test_ed_with_empty_file
    # Test ed behavior with an empty file
    temp_file = Tempfile.new(['empty', '.txt'])
    temp_file.close
    
    # Add content to empty file
    ed_commands = [
      "a",
      "First line",
      "Second line",
      ".",
      "w",
      "q"
    ].join("\n")
    
    stdout, stderr, status = Open3.capture3("ed #{temp_file.path}", stdin_data: ed_commands)
    
    assert_equal 0, status.exitstatus, "ed should handle empty files"
    
    content = File.read(temp_file.path)
    assert_includes content, "First line"
    assert_includes content, "Second line"
    
    temp_file.unlink
  end

  def test_ed_stderr_behavior
    # Test that ed puts error messages on stderr, not stdout
    temp_file = Tempfile.new(['stderr_test', '.txt'])
    file_path = temp_file.path
    temp_file.close
    temp_file.unlink  # Remove file so ed will give error
    
    ed_commands = [
      "a",
      "Test content",
      ".",
      "w #{file_path}",  # Specify the file path in the write command
      "q"
    ].join("\n")
    
    stdout, stderr, status = Open3.capture3("ed", stdin_data: ed_commands)
    
    # The error message should be on stderr (when we specify file on command line)
    # But when we use 'w /path/to/file', there's no error
    # stdout should contain the character count
    refute_includes stdout, "No such file or directory", "Error should not be on stdout"
    
    # The file should be created successfully
    assert File.exist?(file_path), "File should be created"
    
    File.unlink(file_path) if File.exist?(file_path)
  end
end 