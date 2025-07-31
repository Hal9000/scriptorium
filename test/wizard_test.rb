#!/usr/bin/env ruby

require 'open3'
require 'timeout'
require 'minitest/autorun'
require_relative '../lib/scriptorium'

class WizardTest < Minitest::Test
  def setup
    @test_repo_path = "scriptorium-TEST"
    cleanup_test_repo
  end

  def teardown
    cleanup_test_repo
  end

  def test_001_wizard_first_view_flow
    # Test the wizard flow for creating the first view
    # This should create a new repository and set up the first view
    
    # Ensure clean start
    cleanup_test_repo
    
    # Run the wizard
    result = system("echo -e 'y\n4\nn' | ruby bin/scriptorium")
    assert result, "Wizard should complete successfully"
    
    # Verify repository was created
    assert Dir.exist?(TEST_REPO_PATH), "Repository should be created"
    
    # Verify sample view was created
    sample_view_path = File.join(TEST_REPO_PATH, "views", "sample")
    assert Dir.exist?(sample_view_path), "Sample view should be created"
    
    # Verify config files were created
    config_path = File.join(TEST_REPO_PATH, "config")
    assert Dir.exist?(config_path), "Config directory should be created"
    
    # Verify current view is set
    current_view_file = File.join(config_path, "currentview.txt")
    assert File.exist?(current_view_file), "Current view file should be created"
    assert_equal "sample", File.read(current_view_file).strip, "Current view should be 'sample'"
  end

  def test_002_wizard_method_exists
    # Test that the wizard method exists and can be called
    # This is a basic smoke test to ensure the wizard is available
    
    # Load the scriptorium binary to access the wizard method
    load 'bin/scriptorium'
    
    # The wizard method should be available in the TUI class
    assert defined?(TUI), "TUI class should be defined"
    assert TUI.instance_methods.include?(:wizard), "TUI should have wizard method"
  end

  def test_003_wizard_with_new_repo
    # Test wizard behavior when creating a completely new repository
    # This tests the full wizard flow including repository creation
    
    # Ensure clean start
    cleanup_test_repo
    
    # Create a new API instance to simulate fresh start
    api = Scriptorium::API.new(testmode: true)
    
    # Verify no repository exists initially
    refute Dir.exist?(TEST_REPO_PATH), "Repository should not exist initially"
    
    # Run wizard with new repo creation
    result = system("echo -e 'y\n4\ny\ntestview\nTest View\nTest Subtitle\nn\nn\nn\nn\nn' | ruby bin/scriptorium")
    assert result, "Wizard should complete successfully with new repo"
    
    # Verify repository was created
    assert Dir.exist?(TEST_REPO_PATH), "Repository should be created"
    
    # Verify test view was created
    test_view_path = File.join(TEST_REPO_PATH, "views", "testview")
    assert Dir.exist?(test_view_path), "Test view should be created"
    
    # Verify view config
    view_config = File.join(test_view_path, "config.txt")
    assert File.exist?(view_config), "View config should be created"
    config_content = File.read(view_config)
    assert_includes config_content, "title    Test View", "View title should be set"
    assert_includes config_content, "subtitle Test Subtitle", "View subtitle should be set"
  end

  def await_output(stdout, expected_str, timeout_secs = 10)
    buffer = ""
    start_time = Time.now
    
    loop do
      if Time.now - start_time > timeout_secs
        raise "Timeout waiting for '#{expected_str}'. Buffer: #{buffer.inspect}"
      end
      
      begin
        chunk = stdout.read_nonblock(1000)
        buffer += chunk
        puts "Buffer: #{buffer.inspect}"
        
        if buffer.include?(expected_str)
          puts "Found expected string: #{expected_str.inspect}"
          return buffer
        end
      rescue IO::EAGAINWaitReadable, IO::EWOULDBLOCKWaitReadable
        sleep 0.1
      rescue EOFError
        raise "EOF reached while waiting for '#{expected_str}'. Buffer: #{buffer.inspect}"
      end
    end
  end

  private

  def cleanup_test_repo
    if Dir.exist?(@test_repo_path)
      FileUtils.rm_rf(@test_repo_path)
    end
  end
end 