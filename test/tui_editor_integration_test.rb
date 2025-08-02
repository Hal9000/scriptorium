#!/usr/bin/env ruby

require 'pty'
require 'expect'
require 'fileutils'
require 'minitest/autorun'
require_relative '../lib/scriptorium'

class TUIEditorIntegrationTest < Minitest::Test
  # Test repository path
  TEST_REPO_PATH = "scriptorium-TEST"

  def setup
    cleanup_test_repo
  end

  def teardown
    cleanup_test_repo
  end

  def test_001_links_widget_editing_workflow
    # Test the complete links widget editing workflow using PTY
    # Start with no repo, let TUI create it, trigger wizard, configure links widget, edit content
    
    # Ensure clean start
    cleanup_test_repo
    
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_links_widget_workflow(read, write)
      ensure
        # Clean up the process
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_002_basic_tui_flow
    # Test basic TUI flow without complex wizard
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_basic_tui_workflow(read, write)
        
      ensure
        # Clean up the process
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_003_create_post_workflow
    # Test creating a post through the TUI
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        run_create_post_workflow(read, write)        
      ensure
        # Clean up the process
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
    # More aggressive cleanup - remove any test repositories
    FileUtils.rm_rf(TEST_REPO_PATH) if Dir.exist?(TEST_REPO_PATH)
    FileUtils.rm_rf("scriptorium-TEST") if Dir.exist?("scriptorium-TEST")
    # Also clean up any other potential test repos
    Dir.glob("scriptorium-*TEST*").each do |dir|
      FileUtils.rm_rf(dir) if Dir.exist?(dir)
    end
  end

  def send_and_expect(read, write, input, expected_pattern, description)
    write.puts input
    sleep 0.1  # Small delay to ensure input is processed
    result = get_string(read, expected_pattern, description)
    # Add explicit assertion for the expected pattern
    assert result.match?(expected_pattern), "#{description}: Expected pattern '#{expected_pattern}' not found in output"
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

  def run_links_widget_workflow(read, write)
    # Wait for initial output
    get_string(read, /No repository found\./, "Should show 'No repository found'")
    
    # Send 'y' to create new repository
    send_and_expect(read, write, "y", "Created repository successfully.",
                   "Should show repository created")
    
    # Wait for editor setup
    get_string(read, "No editor configured", "Should show editor setup")
    
    # Wait for editor list
    get_string(read, "Available editors", "Should show available editors")
    
    # Wait for editor choice prompt
    get_string(read, "Choose editor", "Should prompt for editor selection")
    send_and_expect(read, write, "4", "Selected editor: ed",
                   "Should show editor selection")
    
    # Wait for setup completion
    get_string(read, "Setup complete", "Should show setup completion")
    
    # Wait for assistance question
    get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
    
    # Send 'y' for assistance
    send_and_expect(read, write, "y", "Enter view name",
                   "Should prompt for view name")
    
    # Send view name
    send_and_expect(read, write, "testview", "Enter view title",
                   "Should prompt for view title")
    
    # Send view title
    send_and_expect(read, write, "Test View", "Enter subtitle",
                   "Should prompt for subtitle")
    
    # Send subtitle
    send_and_expect(read, write, "Test Subtitle", "Would you like to edit the layout",
                   "Should ask about editing layout")
    
    # Send 'n' to skip layout editing (avoid ed interaction issues)
    send_and_expect(read, write, "n", "Would you like to configure header",
                   "Should ask about header configuration")
    
    # Wait for container configuration questions (in wizard order: header, main, left, right, footer)
    send_and_expect(read, write, "n", "Would you like to configure main",
                   "Should ask about main configuration")
    send_and_expect(read, write, "n", "Would you like to configure left",
                   "Should ask about left configuration")
    
    # Say yes to configure left sidebar
    send_and_expect(read, write, "y", "Add widgets to left",
                   "Should ask about adding widgets to left")
    
    # Say yes to add widgets
    send_and_expect(read, write, "y", "Available widgets: links, pages, featuredposts",
                   "Should show available widgets")
    
    send_and_expect(read, write, "y", /Add links widget\?/, "Should ask about adding links widget")
    
    send_and_expect(read, write, "n", /Add pages widget\?/, "Should ask about adding pages widget")
    
    send_and_expect(read, write, "n", /Add featuredposts widget\?/, "Should ask about adding featuredposts widget")
    
    send_and_expect(read, write, "n", /Configure links widget\?/, "Should ask about configuring links widget")
    
    # Say no to configure links widget - now should proceed to next container
    send_and_expect(read, write, "n", "Would you like to configure right",
                   "Should ask about right configuration")
    

    send_and_expect(read, write, "n", "Would you like to configure footer",
                   "Should ask about footer configuration")
    send_and_expect(read, write, "n", "View setup complete",
                   "Should show setup completion")
    
    # Wait for main prompt
    get_string(read, "[testview]", "Should show main prompt")
    
    # Send 'quit' to exit
    send_and_expect(read, write, "quit", "Goodbye!",
                   "Should show goodbye message")
  end

  def run_basic_tui_workflow(read, write)
    # Wait for initial output
    get_string(read, "No repository found.", "Should show 'No repository found'")
    
    # Send 'y' to create new repository
    send_and_expect(read, write, "y", "Created repository successfully.",
                   "Should show repository created")
    
    # Wait for editor setup
    get_string(read, "No editor configured", "Should show editor setup")
    
    # Wait for editor list
    get_string(read, "Available editors", "Should show available editors")
    
    # Wait for editor choice prompt
    get_string(read, "Choose editor", "Should prompt for editor selection")
    send_and_expect(read, write, "4", "Selected editor: ed",
                   "Should show editor selection")
    
    # Wait for setup completion
    get_string(read, "Setup complete", "Should show setup completion")
    
    # Wait for assistance question
    get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
    
    # Send 'n' to skip assistance
    send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
    
    # Send 'quit' to exit
    send_and_expect(read, write, "quit", "Goodbye!",
                   "Should show goodbye message")
  end

  def run_create_post_workflow(read, write)
    # Wait for initial output
    get_string(read, "No repository found.", "Should show 'No repository found'")
    
    # Send 'y' to create new repository
    send_and_expect(read, write, "y", "Created repository successfully.",
                   "Should show repository created")
    
    # Wait for editor setup
    get_string(read, "No editor configured", "Should show editor setup")
    
    # Wait for editor list
    get_string(read, "Available editors", "Should show available editors")
    
    # Wait for editor choice prompt
    get_string(read, "Choose editor", "Should prompt for editor selection")
    send_and_expect(read, write, "4", "Selected editor: ed",
                   "Should show editor selection")
    
    # Wait for setup completion
    get_string(read, "Setup complete", "Should show setup completion")
    
    # Wait for assistance question
    get_string(read, "Do you want assistance in creating your first view", "Should ask about assistance")
    
    # Send 'n' to skip assistance
    send_and_expect(read, write, "n", "[sample]", "Should show main prompt")
    
    # Create a post
    send_and_expect(read, write, "new post Test Post", "Created draft",
                   "Should show draft created")
    
    # Wait for editor opening
    get_string(read, "Opening in ed", "Should show editor opening")
    
    # Simulate ed interaction
    sleep 1
    write.puts "a"
    write.puts "Test content"
    write.puts "."
    write.puts "w"
    write.puts "q"
    sleep 1
    
    # Wait for post creation
    get_string(read, "Post created", "Should show post created")
    
    # Wait for main prompt
    get_string(read, "[sample]", "Should show main prompt")
    
    # Send 'quit' to exit
    send_and_expect(read, write, "quit", "Goodbye!",
                   "Should show goodbye message")
  end
end 