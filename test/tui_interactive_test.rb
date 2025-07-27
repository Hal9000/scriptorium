#!/usr/bin/env ruby

require 'open3'
require 'timeout'
require 'test/unit'
require_relative '../lib/scriptorium'

class TUIInteractiveTest < Test::Unit::TestCase
  def setup
    @test_repo_path = "test/tui-interactive-test-repo"
    cleanup_test_repo
  end

  def teardown
    cleanup_test_repo
  end

  def test_interactive_tui_session
    # Use the same test repo that the TUI uses
    script_path = File.expand_path("../../bin/scriptorium", __FILE__)
    ruby_path = "/Users/Hal/.rbenv/versions/3.2.3/bin/ruby"
    
    commands = [
      "h\n",  # Help
      "lsv\n",  # List views
      "cv sample\n",  # Change to sample view (which exists)
      "view\n",  # Show current view
      "q\n"  # Quit
    ]
    
    input = commands.join("")
    
    Timeout.timeout(30) do
      stdout, stderr, status = Open3.capture3(
        "#{ruby_path} #{script_path}",
        stdin_data: input
      )
      output = stdout + stderr
      
      # Check that help command worked
      assert_match(/Available commands:/, output)
      # Check that views are listed (sample should exist)
      assert_match(/sample/, output)
      # Check that view switching worked
      assert_match(/Current view: sample/, output)
    end
  end

  def test_tui_basic_functionality
    # Test basic TUI functionality - no Readline features in automated tests
    script_path = File.expand_path("../../bin/scriptorium", __FILE__)
    ruby_path = "/Users/Hal/.rbenv/versions/3.2.3/bin/ruby"
    
    commands = [
      "h\n",  # Help
      "q\n"  # Quit
    ]
    
    input = commands.join("")
    
    Timeout.timeout(30) do
      stdout, stderr, status = Open3.capture3(
        "#{ruby_path} #{script_path}",
        stdin_data: input
      )
      output = stdout + stderr
      
      # Check that help command worked
      assert_match(/Available commands:/, output)
    end
  end

  private

  def cleanup_test_repo
    if Dir.exist?(@test_repo_path)
      FileUtils.rm_rf(@test_repo_path)
    end
  end
end 