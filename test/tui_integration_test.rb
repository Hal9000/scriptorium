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
      run_basic_tui_interaction_test(read, write, pid)
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_view_management
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      run_view_management_test(read, write, pid)
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_command_abbreviations
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      run_command_abbreviations_test(read, write, pid)
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_interactive_create_view
    # Create an existing view for testing
    @api.create_view("existing", "Existing View", "An existing view")
    
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      run_interactive_create_view_test(read, write, pid)
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_unknown_commands
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      run_unknown_commands_test(read, write, pid)
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_empty_input_handling
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      run_empty_input_handling_test(read, write, pid)
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_exit_variations
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      run_exit_variations_test(read, write, pid)
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_error_conditions
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      run_error_conditions_test(read, write, pid)
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  private

  def send_and_expect(read, write, input, expected_pattern, description)
    write.puts input
    sleep 0.1  # Small delay to ensure input is processed
    get_string(read, expected_pattern, description)
  rescue Errno::EIO => e
    # Handle case where TUI terminates immediately after output
    if expected_pattern.to_s.include?("Goodbye!")
      # If we're expecting Goodbye! and get an I/O error, that's probably OK
      # The TUI terminated after outputting Goodbye!
      return
    else
      raise e
    end
  end

  def run_basic_tui_interaction_test(read, write, pid)
    begin
      # Wait for repository discovery
      get_string(read, /Found existing test repository/, "Should find existing repository")
      
      # Send help command
      send_and_expect(read, write, "h", /Available commands:/, "Should show help")
      
      # Send list views command
      send_and_expect(read, write, "lsv", /sample/, "Should show sample view")
      
      # Send view command to see current view
      send_and_expect(read, write, "view", /Current view:/, "Should show view info")
      
      # Send view command
      send_and_expect(read, write, "view", /Current view:/, "Should show view info")
      
      # Send quit
      send_and_expect(read, write, "q", /Goodbye!/, "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_view_management_test(read, write, pid)
    begin
      # Wait for repository discovery
      get_string(read, /Found existing test repository/, "Should find existing repository")
      
      # List views
      send_and_expect(read, write, "lsv", /sample/, "Should show sample view")
      
      # Create a new view first
      write.puts "create view testview123 This is just a test..."
      get_string(read, /Enter subtitle \(optional\):/, "Should prompt for subtitle")
      write.puts ""  # Empty subtitle
      get_string(read, /Created view 'testview123' with title/, "Should create new view")
      
      # Now change to the new view
      send_and_expect(read, write, "cv testview123", /Switched to view 'testview123'/, "Should show view switch")
      
      # Show current view
      send_and_expect(read, write, "view", /Current view:/, "Should show view info")
      
      # Create new view (this should fail because view already exists)
      write.puts "create view testview123 This is just a test..."
      get_string(read, /Enter subtitle \(optional\):/, "Should prompt for subtitle")
      write.puts ""  # Empty subtitle
      get_string(read, /View 'testview123' already exists/, "Should show view already exists error")
      
      # Change to new view (already on this view, so no switch message)
      write.puts "cv testview123"
      # No message expected since we're already on this view
      
      # Try to change to non-existent view
      send_and_expect(read, write, "cv nonexistent", /View 'nonexistent' not found/, "Should show error for non-existent view")
      
      # Quit
      send_and_expect(read, write, "q", /Goodbye!/, "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_command_abbreviations_test(read, write, pid)
    begin
      # Wait for repository discovery
      get_string(read, /Found existing test repository/, "Should find existing repository")
      
      # Send help command
      send_and_expect(read, write, "h", /Available commands:/, "Should show help")
      
      # Send version command
      send_and_expect(read, write, "v", /Scriptorium/, "Should show version")
      
      # Send list views command
      send_and_expect(read, write, "lsv", /sample/, "Should show sample view")
      
      # Quit
      send_and_expect(read, write, "q", /Goodbye!/, "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_interactive_create_view_test(read, write, pid)
    begin
      # Wait for repository discovery
      get_string(read, /Found existing test repository/, "Should find existing repository")
      
      # Start interactive create view
      send_and_expect(read, write, "create view", /Enter view name:/, "Should prompt for view name")
      
      # Enter view name
      send_and_expect(read, write, "interactiveview", /Enter view title:/, "Should prompt for view title")
      
      # Enter view title
      send_and_expect(read, write, "Interactive View", /Enter subtitle \(optional\):/, "Should prompt for subtitle")
      
      # Enter subtitle
      send_and_expect(read, write, "Interactive Subtitle", /Created view 'interactiveview'/, "Should create view")
      
      # List views to verify
      send_and_expect(read, write, "lsv", /interactiveview/, "Should show new view in list")
      
      # Quit
      send_and_expect(read, write, "q", /Goodbye!/, "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_unknown_commands_test(read, write, pid)
    begin
      # Wait for repository discovery
      get_string(read, /Found existing test repository/, "Should find existing repository")
      
      # Send unknown command
      send_and_expect(read, write, "unknowncommand", /Unknown command: unknowncommand/, "Should show unknown command error")
      
      # Send another unknown command
      send_and_expect(read, write, "xyz123", /Unknown command: xyz123/, "Should show unknown command error")
      
      # Quit
      send_and_expect(read, write, "q", /Goodbye!/, "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_empty_input_handling_test(read, write, pid)
    begin
      # Wait for repository discovery
      get_string(read, /Found existing test repository/, "Should find existing repository")
      
      # Send empty line
      write.puts ""
      
      # Send whitespace-only line
      write.puts "   "
      
      # Send help command to verify we're still working
      send_and_expect(read, write, "h", /Available commands:/, "Should show help after empty input")
      
      # Quit
      send_and_expect(read, write, "q", /Goodbye!/, "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_exit_variations_test(read, write, pid)
    begin
      # Wait for repository discovery
      get_string(read, /Found existing test repository/, "Should find existing repository")
      
      # Send quit command
      send_and_expect(read, write, "quit", /Goodbye!/, "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_error_conditions_test(read, write, pid)
    begin
      # Wait for repository discovery
      get_string(read, /Found existing test repository/, "Should find existing repository")
      
      # Start interactive create view
      send_and_expect(read, write, "create view", /Enter view name:/, "Should prompt for view name")
      
      # Enter invalid view name
      send_and_expect(read, write, "invalid/name", /Enter view title:/, "Should prompt for view title")
      
      # Enter title
      send_and_expect(read, write, "Invalid Title", /Enter subtitle \(optional\):/, "Should prompt for subtitle")
      
      # Enter subtitle
      send_and_expect(read, write, "Invalid Subtitle", /Cannot create view: invalid name/, "Should show error for invalid name")
      
      # Quit
      send_and_expect(read, write, "q", /Goodbye!/, "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

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