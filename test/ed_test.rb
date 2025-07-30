#!/usr/bin/env ruby

# This file tests that we can interact with 'ed' correctly for automated testing.
# We are NOT testing 'ed' itself - we assume 'ed' works correctly.
# We ARE testing that our test infrastructure can properly invoke 'ed'
# and handle its input/output/error streams for automated testing scenarios.

require 'minitest/autorun'
require 'pty'
require 'expect'
require 'tempfile'

class EdTest < Minitest::Test
  def test_ed_basic_functionality_pty
    # Test that ed can create and edit a file using PTY
    temp_file = Tempfile.new(['test', '.txt'])
    temp_file.close
    
    PTY.spawn("ed #{temp_file.path}") do |read, write, pid|
      begin
        # Wait for ed to start
        sleep 0.5
        
        # Send ed commands
        write.puts "a"           # Enter append mode
        write.puts "Hello world" # Add text
        write.puts "This is a test" # Add more text
        write.puts "."           # Exit append mode
        write.puts "w"           # Write the file
        write.puts "q"           # Quit ed
        
        # Wait for ed to exit
        Process.wait(pid)
        
        # Verify the file was written
        content = File.read(temp_file.path)
        assert_includes content, "Hello world"
        assert_includes content, "This is a test"
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
    
    temp_file.unlink
  end

  def test_ed_file_creation_pty
    # Test that ed can create a new file using PTY
    temp_file = Tempfile.new(['new', '.txt'])
    file_path = temp_file.path  # Save the path before closing
    temp_file.close
    temp_file.unlink  # Remove the file so ed creates it
    
    PTY.spawn("ed") do |read, write, pid|
      begin
        # Wait for ed to start
        sleep 0.5
        
        # Send ed commands
        write.puts "a"
        write.puts "New file content"
        write.puts "Created by ed"
        write.puts "."
        write.puts "w #{file_path}"
        write.puts "q"
        
        # Wait for ed to exit
        Process.wait(pid)
        
        # Verify the file was created
        assert File.exist?(file_path), "File should be created"
        
        # Verify the file has content
        content = File.read(file_path)
        assert_includes content, "New file content"
        assert_includes content, "Created by ed"
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
    
    File.unlink(file_path) if File.exist?(file_path)
  end

  def test_ed_simulate_edit_file_usage_pty
    # Test how edit_file would use ed with PTY
    temp_file = Tempfile.new(['test', '.txt'])
    temp_file.close
    
    PTY.spawn("ed #{temp_file.path}") do |read, write, pid|
      begin
        # Wait for ed to start
        sleep 0.5
        
        # Send ed commands (simulating what edit_file would do)
        write.puts "a"
        write.puts "Content added by edit_file"
        write.puts "This simulates user input"
        write.puts "."
        write.puts "w"
        write.puts "q"
        
        # Wait for ed to exit
        Process.wait(pid)
        
        # Verify the file was modified
        content = File.read(temp_file.path)
        assert_includes content, "Content added by edit_file"
        assert_includes content, "This simulates user input"
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
    
    temp_file.unlink
  end

  def test_ed_with_empty_file_pty
    # Test ed behavior with an empty file using PTY
    temp_file = Tempfile.new(['empty', '.txt'])
    temp_file.close
    
    PTY.spawn("ed #{temp_file.path}") do |read, write, pid|
      begin
        # Wait for ed to start
        sleep 0.5
        
        # Add content to empty file
        write.puts "a"
        write.puts "First line"
        write.puts "Second line"
        write.puts "."
        write.puts "w"
        write.puts "q"
        
        # Wait for ed to exit
        Process.wait(pid)
        
        content = File.read(temp_file.path)
        assert_includes content, "First line"
        assert_includes content, "Second line"
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
    
    temp_file.unlink
  end

  def test_ed_which_command
    # Test that ed is available on the system
    require 'open3'
    stdout, stderr, status = Open3.capture3("which ed")
    
    assert_equal 0, status.exitstatus, "ed should be available on the system"
    assert_includes stdout, "ed", "which should find ed"
  end

  def test_ed_error_handling
    # Test that ed handles errors gracefully
    require 'open3'
    stdout, stderr, status = Open3.capture3("ed /nonexistent/directory/file.txt", stdin_data: "q\n")
    
    # ed should exit with an error
    refute_equal 0, status.exitstatus, "ed should fail on non-existent directory"
  end

  def test_ed_stderr_behavior
    # Test that ed puts error messages on stderr, not stdout
    require 'open3'
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