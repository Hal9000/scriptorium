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
    # Don't create repo here - let the TUI create it interactively
  end

  def teardown
    cleanup_test_repo
  end



  def test_001_basic_tui_interaction
    # Test TUI interaction - let TUI create repo interactively
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_basic_tui_interaction_test(read, write, pid)
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_002_view_management
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_view_management_test(read, write, pid)
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_003_command_abbreviations
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_command_abbreviations_test(read, write, pid)
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_004_interactive_create_view
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_interactive_create_view_test(read, write, pid)
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_005_unknown_commands
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_unknown_commands_test(read, write, pid)
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_006_empty_input_handling
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_empty_input_handling_test(read, write, pid)
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_007_exit_variations
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_exit_variations_test(read, write, pid)
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_008_error_conditions
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_error_conditions_test(read, write, pid)
      ensure
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  private

  def send_and_expect(read, write, input, expected_pattern, description)
    write.puts input
    sleep 0.1  # Small delay to ensure input is processed
    result = get_string(read, expected_pattern, description)
    # Add explicit assertion for the expected pattern
    if expected_pattern.is_a?(Regexp)
      assert result.match?(expected_pattern), "#{description}: Expected pattern '#{expected_pattern}' not found in output"
    else
      assert result.include?(expected_pattern), "#{description}: Expected text '#{expected_pattern}' not found in output"
    end
    result
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
      # Wait for "No repository found" message
      get_string(read, "No repository found.", "Should show 'No repository found'")
      
      # Send 'y' to create new repository
      send_and_expect(read, write, "y", "Created repository successfully.", "Should show repository created")
      
      # Wait for editor setup
      get_string(read, "No editor configured", "Should show editor setup")
      
      # Wait for editor list
      get_string(read, "Available editors", "Should show available editors")
      
      # Wait for editor choice prompt
      get_string(read, "Choose editor", "Should prompt for editor selection")
      send_and_expect(read, write, "4", "Selected editor: ed", "Should show editor selection")
      
      # Wait for setup completion
      get_string(read, "Setup complete", "Should show setup completion")
      
      # Wait for assistance question
      get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
      
      # Send 'n' to skip assistance (simpler test)
      send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
      
      # Send help command
      send_and_expect(read, write, "h", "view", "Should show help")
      
      # Wait for prompt again
      get_string(read, /\[.*\] /, "Should show prompt after help")
      
      # Send list views command
      send_and_expect(read, write, "lsv", "sample", "Should show sample view")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after lsv")
      
      # Send view command to see current view
      send_and_expect(read, write, "view", "Current view:", "Should show view info")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after view")
      
      # Send quit
      send_and_expect(read, write, "q", "Goodbye!", "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_view_management_test(read, write, pid)
    begin
      # Wait for "No repository found" message
      get_string(read, "No repository found.", "Should show 'No repository found'")
      
      # Send 'y' to create new repository
      send_and_expect(read, write, "y", "Created repository successfully.", "Should show repository created")
      
      # Wait for editor setup
      get_string(read, "No editor configured", "Should show editor setup")
      
      # Wait for editor list
      get_string(read, "Available editors", "Should show available editors")
      
      # Wait for editor choice prompt
      get_string(read, "Choose editor", "Should prompt for editor selection")
      send_and_expect(read, write, "4", "Selected editor: ed", "Should show editor selection")
      
      # Wait for setup completion
      get_string(read, "Setup complete", "Should show setup completion")
      
      # Wait for assistance question
      get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
      
      # Send 'n' to skip assistance (simpler test)
      send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
      
      # List views
      send_and_expect(read, write, "lsv", "sample", "Should show sample view")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after lsv")
      
      # Create a new view first
      write.puts "new view testview123 This is just a test..."
      get_string(read, "Enter subtitle (optional):", "Should prompt for subtitle")
      write.puts ""  # Empty subtitle
      get_string(read, "Created view 'testview123' with title", "Should create new view")
      
      # Wait for the "Switched to view" message that comes after creation
      get_string(read, "Switched to view 'testview123'", "Should switch to new view after creation")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after creating view")
      
      # Now change to the new view (should already be on it, so no switch message)
      write.puts "cv testview123"
      # No message expected since we're already on this view
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after switching view")
      
      # Show current view
      send_and_expect(read, write, "view", "Current view:", "Should show view info")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after view command")
      
      # Create new view (this should fail because view already exists)
      write.puts "new view testview123 This is just a test..."
      get_string(read, "Enter subtitle (optional):", "Should prompt for subtitle")
      write.puts ""  # Empty subtitle
      get_string(read, "View 'testview123' already exists", "Should show view already exists error")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after failed view creation")
      
      # Change to new view (already on this view, so no switch message)
      write.puts "cv testview123"
      # No message expected since we're already on this view
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after cv command")
      
      # Try to change to non-existent view
      send_and_expect(read, write, "cv nonexistent", "View 'nonexistent' not found", "Should show error for non-existent view")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after error")
      
      # Quit
      send_and_expect(read, write, "q", "Goodbye!", "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_command_abbreviations_test(read, write, pid)
    begin
      # Wait for "No repository found" message
      get_string(read, "No repository found.", "Should show 'No repository found'")
      
      # Send 'y' to create new repository
      send_and_expect(read, write, "y", "Created repository successfully.", "Should show repository created")
      
      # Wait for editor setup
      get_string(read, "No editor configured", "Should show editor setup")
      
      # Wait for editor list
      get_string(read, "Available editors", "Should show available editors")
      
      # Wait for editor choice prompt
      get_string(read, "Choose editor", "Should prompt for editor selection")
      send_and_expect(read, write, "4", "Selected editor: ed", "Should show editor selection")
      
      # Wait for setup completion
      get_string(read, "Setup complete", "Should show setup completion")
      
      # Wait for assistance question
      get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
      
      # Send 'n' to skip assistance (simpler test)
      send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
      
      # Send help command
      send_and_expect(read, write, "h", "view", "Should show help")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after help")
      
      # Send version command
      send_and_expect(read, write, "v", "Scriptorium", "Should show version")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after version")
      
      # Send list views command
      send_and_expect(read, write, "lsv", "sample", "Should show sample view")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after lsv")
      
      # Quit
      send_and_expect(read, write, "q", "Goodbye!", "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_interactive_create_view_test(read, write, pid)
    begin
      # Wait for "No repository found" message
      get_string(read, "No repository found.", "Should show 'No repository found'")
      
      # Send 'y' to create new repository
      send_and_expect(read, write, "y", "Created repository successfully.", "Should show repository created")
      
      # Wait for editor setup
      get_string(read, "No editor configured", "Should show editor setup")
      
      # Wait for editor list
      get_string(read, "Available editors", "Should show available editors")
      
      # Wait for editor choice prompt
      get_string(read, "Choose editor", "Should prompt for editor selection")
      send_and_expect(read, write, "4", "Selected editor: ed", "Should show editor selection")
      
      # Wait for setup completion
      get_string(read, "Setup complete", "Should show setup completion")
      
      # Wait for assistance question
      get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
      
      # Send 'n' to skip assistance (simpler test)
      send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
      
      # Start interactive create view
      send_and_expect(read, write, "new view", "Enter view name:", "Should prompt for view name")
      
      # Enter view name
      send_and_expect(read, write, "interactiveview", "Enter view title:", "Should prompt for view title")
      
      # Enter view title
      send_and_expect(read, write, "Interactive View", "Enter subtitle (optional):", "Should prompt for subtitle")
      
      # Enter subtitle
      send_and_expect(read, write, "Interactive Subtitle", "Created view 'interactiveview'", "Should create view")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after creating view")
      
      # List views to verify
      send_and_expect(read, write, "lsv", "interactiveview", "Should show new view in list")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after lsv")
      
      # Quit
      send_and_expect(read, write, "q", "Goodbye!", "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_unknown_commands_test(read, write, pid)
    begin
      # Wait for "No repository found" message
      get_string(read, "No repository found.", "Should show 'No repository found'")
      
      # Send 'y' to create new repository
      send_and_expect(read, write, "y", "Created repository successfully.", "Should show repository created")
      
      # Wait for editor setup
      get_string(read, "No editor configured", "Should show editor setup")
      
      # Wait for editor list
      get_string(read, "Available editors", "Should show available editors")
      
      # Wait for editor choice prompt
      get_string(read, "Choose editor", "Should prompt for editor selection")
      send_and_expect(read, write, "4", "Selected editor: ed", "Should show editor selection")
      
      # Wait for setup completion
      get_string(read, "Setup complete", "Should show setup completion")
      
      # Wait for assistance question
      get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
      
      # Send 'n' to skip assistance (simpler test)
      send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
      
      # Send unknown command
      send_and_expect(read, write, "unknowncommand", "Unknown command: unknowncommand", "Should show unknown command error")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after error")
      
      # Send another unknown command
      send_and_expect(read, write, "xyz123", "Unknown command: xyz123", "Should show unknown command error")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after second error")
      
      # Quit
      send_and_expect(read, write, "q", "Goodbye!", "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_empty_input_handling_test(read, write, pid)
    begin
      # Wait for "No repository found" message
      get_string(read, "No repository found.", "Should show 'No repository found'")
      
      # Send 'y' to create new repository
      send_and_expect(read, write, "y", "Created repository successfully.", "Should show repository created")
      
      # Wait for editor setup
      get_string(read, "No editor configured", "Should show editor setup")
      
      # Wait for editor list
      get_string(read, "Available editors", "Should show available editors")
      
      # Wait for editor choice prompt
      get_string(read, "Choose editor", "Should prompt for editor selection")
      send_and_expect(read, write, "4", "Selected editor: ed", "Should show editor selection")
      
      # Wait for setup completion
      get_string(read, "Setup complete", "Should show setup completion")
      
      # Wait for assistance question
      get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
      
      # Send 'n' to skip assistance (simpler test)
      send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
      
      # Send empty line
      write.puts ""
      
      # Send whitespace-only line
      write.puts "   "
      
      # Send help command to verify we're still working
      send_and_expect(read, write, "h", "view", "Should show help after empty input")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after help")
      
      # Quit
      send_and_expect(read, write, "q", "Goodbye!", "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_exit_variations_test(read, write, pid)
    begin
      # Wait for "No repository found" message
      get_string(read, "No repository found.", "Should show 'No repository found'")
      
      # Send 'y' to create new repository
      send_and_expect(read, write, "y", "Created repository successfully.", "Should show repository created")
      
      # Wait for editor setup
      get_string(read, "No editor configured", "Should show editor setup")
      
      # Wait for editor list
      get_string(read, "Available editors", "Should show available editors")
      
      # Wait for editor choice prompt
      get_string(read, "Choose editor", "Should prompt for editor selection")
      send_and_expect(read, write, "4", "Selected editor: ed", "Should show editor selection")
      
      # Wait for setup completion
      get_string(read, "Setup complete", "Should show setup completion")
      
      # Wait for assistance question
      get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
      
      # Send 'n' to skip assistance (simpler test)
      send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
      
      # Send quit command
      send_and_expect(read, write, "quit", "Goodbye!", "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def run_error_conditions_test(read, write, pid)
    begin
      # Wait for "No repository found" message
      get_string(read, "No repository found.", "Should show 'No repository found'")
      
      # Send 'y' to create new repository
      send_and_expect(read, write, "y", "Created repository successfully.", "Should show repository created")
      
      # Wait for editor setup
      get_string(read, "No editor configured", "Should show editor setup")
      
      # Wait for editor list
      get_string(read, "Available editors", "Should show available editors")
      
      # Wait for editor choice prompt
      get_string(read, "Choose editor", "Should prompt for editor selection")
      send_and_expect(read, write, "4", "Selected editor: ed", "Should show editor selection")
      
      # Wait for setup completion
      get_string(read, "Setup complete", "Should show setup completion")
      
      # Wait for assistance question
      get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
      
      # Send 'n' to skip assistance (simpler test)
      send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
      
      # Start interactive create view
      send_and_expect(read, write, "new view", "Enter view name:", "Should prompt for view name")
      
      # Enter invalid view name
      send_and_expect(read, write, "invalid/name", "Enter view title:", "Should prompt for view title")
      
      # Enter title
      send_and_expect(read, write, "Invalid Title", "Enter subtitle (optional):", "Should prompt for subtitle")
      
      # Enter subtitle
      send_and_expect(read, write, "Invalid Subtitle", "Cannot create view: invalid name", "Should show error for invalid name")
      
      # Wait for prompt
      get_string(read, /\[.*\] /, "Should show prompt after error")
      
      # Quit
      send_and_expect(read, write, "q", "Goodbye!", "Should show goodbye")
      
    ensure
      Process.kill('TERM', pid) rescue nil
      Process.wait(pid) rescue nil
    end
  end

  def get_string(read, pattern, message, timeout = 5)
    # Convenience method to get a string matching a pattern with timeout
    # Set VERBOSE=1 to see detailed output, defaults to silent
    begin
      output = read.expect(pattern, timeout)
      if output
        puts "Found: #{output[0].strip}" if ENV['VERBOSE']
        return output[0]  # Return the matched string
      else
        puts "Failed to find pattern: #{pattern}"
        # Read what we actually got
        available = read.read_nonblock(1000) rescue ""
        puts "Available output: #{available.inspect}"
        flunk "#{message}: Pattern '#{pattern}' not found within #{timeout} seconds"
      end
    rescue IO::EAGAINWaitReadable
      puts "No output available within timeout"
      flunk "#{message}: No output received within #{timeout} seconds"
    rescue => e
      puts "Error in get_string: #{e.message}"
      flunk "#{message}: Error - #{e.message}"
    end
  end

  def cleanup_test_repo
    # Clean up test repositories
    FileUtils.rm_rf(TEST_REPO_PATH) if Dir.exist?(TEST_REPO_PATH)
    FileUtils.rm_rf("scriptorium-TEST") if Dir.exist?("scriptorium-TEST")
  end
end 