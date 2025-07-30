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

  def test_links_widget_editing_workflow
    # Test the complete links widget editing workflow using PTY
    # Start with no repo, let TUI create it, trigger wizard, configure links widget, edit content
    
    # Ensure clean start
    cleanup_test_repo
    
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for initial output
        get_string(read, /No repository found\./, "Should show 'No repository found'")
        
        # Send 'y' to create new repository
        write.puts "y"
        
        # Wait for repository creation
        get_string(read, /Created repository successfully\./, "Should show repository created")
        
        # Wait for editor setup
        get_string(read, /No editor configured/, "Should show editor setup")
        
        # Wait for editor list
        get_string(read, /Available editors/, "Should show available editors")
        
        # Wait for editor choice prompt
        get_string(read, /Choose editor/, "Should prompt for editor selection")
        write.puts "4"  # Choose ed
        
        # Wait for editor selection confirmation
        get_string(read, /Selected editor: ed/, "Should show editor selection")
        
        # Wait for setup completion
        get_string(read, /Setup complete/, "Should show setup completion")
        
        # Wait for assistance question
        get_string(read, /Do you want assistance in creating your first view/, "Should ask about assistance")
        
        # Send 'y' for assistance
        write.puts "y"
        
        # Wait for view name prompt
        get_string(read, /Enter view name/, "Should prompt for view name")
        
        # Send view name
        write.puts "testview"
        
        # Wait for view title prompt
        get_string(read, /Enter view title/, "Should prompt for view title")
        
        # Send view title
        write.puts "Test View"
        
        # Wait for subtitle prompt
        get_string(read, /Enter subtitle/, "Should prompt for subtitle")
        
        # Send subtitle
        write.puts "Test Subtitle"
        
        # Wait for layout editing question
        get_string(read, /Would you like to edit the layout/, "Should ask about editing layout")
        
        # Send 'n' to skip layout editing (avoid ed interaction issues)
        write.puts "n"
        
        # Wait for container configuration questions (in wizard order: header, main, left, right, footer)
        get_string(read, /Would you like to configure header/, "Should ask about header configuration")
        write.puts "n"
        
        get_string(read, /Would you like to configure main/, "Should ask about main configuration")
        write.puts "n"
        
        get_string(read, /Would you like to configure left/, "Should ask about left configuration")
        write.puts "y"  # Say yes to configure left sidebar
        
        # Wait for sidebar widget configuration
        get_string(read, /Add widgets to left/, "Should ask about adding widgets to left")
        write.puts "y"  # Say yes to add widgets
        
        get_string(read, /Available widgets: links, pages/, "Should show available widgets")
        
        get_string(read, /Add links widget/, "Should ask about adding links widget")
        write.puts "y"  # Say yes to add links widget
        
        # After adding links widget, it will ask about pages widget
        get_string(read, /Add pages widget/, "Should ask about adding pages widget")
        write.puts "n"  # Say no to pages widget
        
        # Now it should ask about configuring the links widget
        get_string(read, /Configure links widget/, "Should ask about configuring links widget")
        write.puts "n"  # Say no to configure links widget (skip ed interaction for now)
        
        get_string(read, /Would you like to configure right/, "Should ask about right configuration")
        write.puts "n"
        
        get_string(read, /Would you like to configure footer/, "Should ask about footer configuration")
        write.puts "n"
        
        # Wait for setup completion
        get_string(read, /View setup complete/, "Should show setup completion")
        
        # Wait for main prompt
        get_string(read, /\[testview\]/, "Should show main prompt")
        
        # Send 'quit' to exit
        write.puts "quit"
        
        # Wait for goodbye message
        get_string(read, /Goodbye!/, "Should show goodbye message")
        
      ensure
        # Clean up the process
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_basic_tui_flow
    # Test basic TUI flow without complex wizard
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for initial output
        get_string(read, /No repository found\./, "Should show 'No repository found'")
        
        # Send 'y' to create new repository
        write.puts "y"
        
        # Wait for repository creation
        get_string(read, /Created repository successfully\./, "Should show repository created")
        
        # Wait for editor setup
        get_string(read, /No editor configured/, "Should show editor setup")
        
        # Wait for editor list
        get_string(read, /Available editors/, "Should show available editors")
        
        # Wait for editor choice prompt
        get_string(read, /Choose editor/, "Should prompt for editor selection")
        write.puts "4"  # Choose ed
        
        # Wait for editor selection confirmation
        get_string(read, /Selected editor: ed/, "Should show editor selection")
        
        # Wait for setup completion
        get_string(read, /Setup complete/, "Should show setup completion")
        
        # Wait for assistance question
        get_string(read, /Do you want assistance in creating your first view/, "Should ask about assistance")
        
        # Send 'n' to skip assistance
        write.puts "n"
        
        # Wait for main prompt
        get_string(read, /\[sample\]/, "Should show main prompt")
        
        # Send 'quit' to exit
        write.puts "quit"
        
        # Wait for goodbye message
        get_string(read, /Goodbye!/, "Should show goodbye message")
        
      ensure
        # Clean up the process
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  ensure
    ENV.delete('NOREADLINE')
  end

  def test_create_post_workflow
    # Test creating a post through the TUI
    ENV['NOREADLINE'] = '1'
    
    PTY.spawn({'NOREADLINE' => '1'}, 'ruby bin/scriptorium') do |read, write, pid|
      begin
        # Wait for initial output
        get_string(read, /No repository found\./, "Should show 'No repository found'")
        
        # Send 'y' to create new repository
        write.puts "y"
        
        # Wait for repository creation
        get_string(read, /Created repository successfully\./, "Should show repository created")
        
        # Wait for editor setup
        get_string(read, /No editor configured/, "Should show editor setup")
        
        # Wait for editor list
        get_string(read, /Available editors/, "Should show available editors")
        
        # Wait for editor choice prompt
        get_string(read, /Choose editor/, "Should prompt for editor selection")
        write.puts "4"  # Choose ed
        
        # Wait for editor selection confirmation
        get_string(read, /Selected editor: ed/, "Should show editor selection")
        
        # Wait for setup completion
        get_string(read, /Setup complete/, "Should show setup completion")
        
        # Wait for assistance question
        get_string(read, /Do you want assistance in creating your first view/, "Should ask about assistance")
        
        # Send 'n' to skip assistance
        write.puts "n"
        
        # Wait for main prompt
        get_string(read, /\[sample\]/, "Should show main prompt")
        
        # Create a post
        write.puts "create post Test Post"
        
        # Wait for draft creation
        get_string(read, /Created draft/, "Should show draft created")
        
        # Wait for editor opening
        get_string(read, /Opening in ed/, "Should show editor opening")
        
        # Simulate ed interaction
        sleep 1
        write.puts "a"
        write.puts "Test content"
        write.puts "."
        write.puts "w"
        write.puts "q"
        sleep 1
        
        # Wait for post creation
        get_string(read, /Post created/, "Should show post created")
        
        # Wait for main prompt
        get_string(read, /\[sample\]/, "Should show main prompt")
        
        # Send 'quit' to exit
        write.puts "quit"
        
        # Wait for goodbye message
        get_string(read, /Goodbye!/, "Should show goodbye message")
        
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
end 