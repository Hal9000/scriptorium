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

  def test_wizard_first_view_flow
    # Create a test repo with only sample view
    api = Scriptorium::API.new(@test_repo_path)
    
    # Simulate wizard interaction
    script_path = File.expand_path("../../bin/scriptorium", __FILE__)
    ruby_path = "/Users/Hal/.rbenv/versions/3.2.3/bin/ruby"
    
    # Commands to simulate wizard interaction
    commands = [
      "n\n",  # No to creating new repo (we'll create it manually)
      "q\n"   # Quit after wizard
    ]
    
    input = commands.join("")
    
    Timeout.timeout(30) do
      stdout, stderr, status = Open3.capture3(
        "#{ruby_path} #{script_path}",
        stdin_data: input
      )
      output = stdout + stderr
      
      # Check that the script ran without crashing
      assert_equal 0, status.exitstatus, "Script should exit successfully"
      
      # Check that it found the test repo
      assert_match(/Found existing test repository: scriptorium-TEST/, output)
    end
  end

  def test_wizard_method_exists
    # Test that the wizard method exists and can be called
    script_path = File.expand_path("../../bin/scriptorium", __FILE__)
    
    # Load the script to access the TUI class
    load script_path
    
    # Clean up any existing test repo
    FileUtils.rm_rf("test/scriptorium-TEST") if Dir.exist?("test/scriptorium-TEST")
    
    # Create a test repo (this will have only the sample view)
    repo = Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)
    
    # Create a TUI instance to test the wizard
    tui = ScriptoriumTUI.new
    tui.instance_variable_set(:@repo, repo)
    
    # Test that the wizard method exists
    assert tui.respond_to?(:wizard_first_view), "wizard_first_view method should exist"
    
    # Clean up
    FileUtils.rm_rf("test/scriptorium-TEST")
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

  def test_wizard_with_new_repo
    # Test the full wizard flow with a new repository
    script_path = File.expand_path("../../bin/scriptorium", __FILE__)
    ruby_path = "/Users/Hal/.rbenv/versions/3.2.3/bin/ruby"
    
    Timeout.timeout(60) do
      Open3.popen3("#{ruby_path} #{script_path}") do |stdin, stdout, stderr, wait_thr|
        # Send commands one by one and read responses
        puts "Starting interactive test..."
        
        # Wait for editor selection and choose nano
        await_output(stdout, "Choose editor (1-4):")
        stdin.puts "1"
        stdin.flush
        
        # Wait for wizard prompt and start wizard
        await_output(stdout, "Would you like to run the first view setup wizard? (y/n):")
        stdin.puts "y"
        
        # Wait for view name prompt
        await_output(stdout, "Enter view name:")
        stdin.puts "test-view"
        
        # Wait for view title prompt
        await_output(stdout, "Enter view title:")
        stdin.puts "Test View"
        
        # Wait for subtitle prompt
        await_output(stdout, "Enter subtitle (optional):")
        stdin.puts ""
        
        # Wait for each widget prompt and respond
        await_output(stdout, "Add header widget? (y/n):")
        stdin.puts "y"
        
        await_output(stdout, "Add main widget? (y/n):")
        stdin.puts "y"
        
        await_output(stdout, "Add left widget? (y/n):")
        stdin.puts "y"
        
        await_output(stdout, "Add right widget? (y/n):")
        stdin.puts "y"
        
        await_output(stdout, "Add footer widget? (y/n):")
        stdin.puts "y"
        
        # Wait for completion message
        await_output(stdout, "View 'test-view' created successfully")
        
        # Send "q" to quit
        stdin.puts "q"
        
        # Close stdin to signal end of input
        stdin.close
        
        # Wait for process to finish
        status = wait_thr.value
        
        # Read any remaining output
        final_output = stdout.read
        error_output = stderr.read
        
        puts "Final output: #{final_output}"
        puts "Error output: #{error_output}"
        puts "Exit status: #{status.exitstatus}"
        
        # Check that the script ran without crashing
        assert_equal 0, status.exitstatus, "Script should exit successfully"
        
        # Check that it went through the wizard flow
        full_output = final_output + error_output
        assert_match(/First View Setup Wizard/, full_output)
        assert_match(/Let's set up your first view!/, full_output)
        assert_match(/Created view 'testview'/, full_output)
        assert_match(/View setup complete!/, full_output)
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