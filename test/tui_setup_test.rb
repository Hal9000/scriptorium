#!/usr/bin/env ruby

require 'open3'
require 'timeout'
require 'minitest/autorun'
require_relative '../lib/scriptorium'

class TUISetupTest < Minitest::Test
  def setup
    @test_repo_path = "scriptorium-TEST"
    cleanup_test_repo
  end

  def teardown
    cleanup_test_repo
  end

  def test_basic_setup_creates_editor_config
    # Test that the setup process creates the editor config file
    script_path = File.expand_path("../../bin/scriptorium", __FILE__)
    ruby_path = "/Users/Hal/.rbenv/versions/3.2.3/bin/ruby"
    
    Timeout.timeout(30) do
      Open3.popen3("#{ruby_path} #{script_path}") do |stdin, stdout, stderr, wait_thr|
        # Send input to complete the setup process
        stdin.puts "1"  # Choose nano
        stdin.puts "n"  # Skip wizard
        stdin.puts "q"  # Quit
        stdin.close
        
        # Wait for process to finish
        status = wait_thr.value
        
        # Check that the script ran without crashing
        assert_equal 0, status.exitstatus, "Script should exit successfully"
        
        # Check that editor was configured
        assert File.exist?("test/scriptorium-TEST/config/editor.txt"), "Editor config should be created"
        editor_choice = File.read("test/scriptorium-TEST/config/editor.txt").strip
        assert_equal "nano", editor_choice, "Should have selected nano editor"
      end
    end
  end

  def test_setup_with_wizard_creates_view
    # Test that the setup process with wizard creates a view
    script_path = File.expand_path("../../bin/scriptorium", __FILE__)
    ruby_path = "/Users/Hal/.rbenv/versions/3.2.3/bin/ruby"
    
    Timeout.timeout(60) do
      Open3.popen3("#{ruby_path} #{script_path}") do |stdin, stdout, stderr, wait_thr|
        # Send input to complete the setup process with wizard
        stdin.puts "1"  # Choose nano
        stdin.puts "y"  # Run wizard
        stdin.puts "test-view"  # View name
        stdin.puts "Test View"  # View title
        stdin.puts ""   # No subtitle
        stdin.puts "n"  # Don't edit layout
        stdin.puts "n"  # Don't configure header
        stdin.puts "n"  # Don't configure main
        stdin.puts "n"  # Don't configure left
        stdin.puts "n"  # Don't configure right
        stdin.puts "n"  # Don't configure footer
        stdin.puts "q"  # Quit
        stdin.close
        
        # Wait for process to finish
        status = wait_thr.value
        
        # Check that the script ran without crashing
        assert_equal 0, status.exitstatus, "Script should exit successfully"
        
        # Check that editor was configured
        assert File.exist?("test/scriptorium-TEST/config/editor.txt"), "Editor config should be created"
        
        # Check that view was created
        assert Dir.exist?("test/scriptorium-TEST/views/test-view"), "Test view should be created"
      end
    end
  end

  private

  def cleanup_test_repo
    if Dir.exist?(@test_repo_path)
      FileUtils.rm_rf(@test_repo_path)
    end
    if Dir.exist?("test/#{@test_repo_path}")
      FileUtils.rm_rf("test/#{@test_repo_path}")
    end
  end
end 