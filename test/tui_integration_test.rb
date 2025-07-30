#!/usr/bin/env ruby

require 'pty'
require 'expect'
require 'fileutils'
require 'minitest/autorun'
require_relative '../lib/scriptorium'

class TUIIntegrationTest < Minitest::Test
  # Test repository path
  TEST_REPO_PATH = "scriptorium-TEST"
  
  def setup
    cleanup_test_repo
    # Create test repo for TUI tests
    @api = Scriptorium::API.new(testmode: true)
    @api.create_repo(TEST_REPO_PATH)
  end

  def teardown
    cleanup_test_repo
  end

  def test_basic_tui_interaction
    # Test TUI interaction with existing scriptorium-TEST repo
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for repository discovery
        get_string(read, /Found existing test repository/, "Should find existing repository")
        
        # Send help command
        write.puts "h"
        
        # Wait for help output
        get_string(read, /Available commands:/, "Should show help")
        
        # Send list views command
        write.puts "lsv"
        
        # Wait for views list
        get_string(read, /sample/, "Should show sample view")
        
        # Send view command to see current view
        write.puts "view"
        
        # Wait for view info
        get_string(read, /Current view:/, "Should show view info")
        
        # Send view command
        write.puts "view"
        
        # Wait for view info
        get_string(read, /Current view:/, "Should show view info")
        
        # Send quit
        write.puts "q"
        
        # Wait for goodbye
        get_string(read, /Goodbye!/, "Should show goodbye")
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_view_management
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for repository discovery
        get_string(read, /Found existing test repository/, "Should find existing repository")
        
        # List views
        write.puts "lsv"
        get_string(read, /sample/, "Should show sample view")
        
        # Create a new view first
        write.puts "create view testview123 This is just a test..."
        get_string(read, /Created view 'testview123'/, "Should create new view")
        
        # Now change to the new view
        write.puts "cv testview123"
        get_string(read, /Switched to view 'testview123'/, "Should show view switch")
        
        # Show current view
        write.puts "view"
        get_string(read, /Current view:/, "Should show view info")
        
        # Create new view
        write.puts "create view testview123 This is just a test..."
        get_string(read, /Created view 'testview123' with title/, "Should create new view")
        
        # Change to new view
        write.puts "cv testview123"
        get_string(read, /Switched to view 'testview123'/, "Should change to new view")
        
        # Try to change to non-existent view
        write.puts "cv nonexistent"
        get_string(read, /Cannot lookup view: nonexistent/, "Should show error for non-existent view")
        
        # Quit
        write.puts "q"
        get_string(read, /Goodbye!/, "Should show goodbye")
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_command_abbreviations
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for repository discovery
        get_string(read, /Found existing test repository/, "Should find existing repository")
        
        # Send help command
        write.puts "h"
        get_string(read, /Available commands:/, "Should show help")
        
        # Send version command
        write.puts "v"
        get_string(read, /Scriptorium/, "Should show version")
        
        # Send list views command
        write.puts "lsv"
        get_string(read, /sample/, "Should show sample view")
        
        # Quit
        write.puts "q"
        get_string(read, /Goodbye!/, "Should show goodbye")
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_interactive_create_view
    # Create an existing view for testing
    @api.create_view("existing", "Existing View", "An existing view")
    
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for repository discovery
        get_string(read, /Found existing test repository/, "Should find existing repository")
        
        # Start interactive create view
        write.puts "create view"
        get_string(read, /Enter view name:/, "Should prompt for view name")
        
        # Enter view name
        write.puts "interactiveview"
        get_string(read, /Enter view title:/, "Should prompt for view title")
        
        # Enter view title
        write.puts "Interactive View"
        get_string(read, /Enter subtitle \(optional\):/, "Should prompt for subtitle")
        
        # Enter subtitle
        write.puts "Interactive Subtitle"
        get_string(read, /Created view 'interactiveview'/, "Should create view")
        
        # List views to verify
        write.puts "lsv"
        get_string(read, /interactiveview/, "Should show new view in list")
        
        # Quit
        write.puts "q"
        get_string(read, /Goodbye!/, "Should show goodbye")
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_unknown_commands
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for repository discovery
        get_string(read, /Found existing test repository/, "Should find existing repository")
        
        # Send unknown command
        write.puts "unknowncommand"
        get_string(read, /Unknown command: unknowncommand/, "Should show unknown command error")
        
        # Send another unknown command
        write.puts "xyz123"
        get_string(read, /Unknown command: xyz123/, "Should show unknown command error")
        
        # Quit
        write.puts "q"
        get_string(read, /Goodbye!/, "Should show goodbye")
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_empty_input_handling
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for repository discovery
        get_string(read, /Found existing test repository/, "Should find existing repository")
        
        # Send empty line
        write.puts ""
        
        # Send whitespace-only line
        write.puts "   "
        
        # Send help command to verify we're still working
        write.puts "h"
        get_string(read, /Available commands:/, "Should show help after empty input")
        
        # Quit
        write.puts "q"
        get_string(read, /Goodbye!/, "Should show goodbye")
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_exit_variations
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for repository discovery
        get_string(read, /Found existing test repository/, "Should find existing repository")
        
        # Send quit command
        write.puts "quit"
        get_string(read, /Goodbye!/, "Should show goodbye")
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_error_conditions
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for repository discovery
        get_string(read, /Found existing test repository/, "Should find existing repository")
        
        # Start interactive create view
        write.puts "create view"
        get_string(read, /Enter view name:/, "Should prompt for view name")
        
        # Enter invalid view name
        write.puts "invalid/name"
        get_string(read, /Enter view title:/, "Should prompt for view title")
        
        # Enter title
        write.puts "Invalid Title"
        get_string(read, /Enter subtitle \(optional\):/, "Should prompt for subtitle")
        
        # Enter subtitle
        write.puts "Invalid Subtitle"
        get_string(read, /Cannot create view: invalid name/, "Should show error for invalid name")
        
        # Quit
        write.puts "q"
        get_string(read, /Goodbye!/, "Should show goodbye")
        
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  private

  def get_string(read, pattern, message, timeout = 5)
    # Convenience method to get a string matching a pattern with timeout
    # Set VERBOSE=1 to see detailed output, defaults to silent
    output = read.expect(pattern, timeout)
    if output
      puts "Found: #{output[0].strip}" if ENV['VERBOSE']
    else
      puts "Failed to find pattern: #{pattern}"
      # Read what we actually got
      available = read.read_nonblock(1000) rescue ""
      puts "Available output: #{available.inspect}"
    end
    assert output, message
    output[0]  # Return the matched string
  end

  def cleanup_test_repo
    FileUtils.rm_rf(TEST_REPO_PATH) if Dir.exist?(TEST_REPO_PATH)
  end
end 