#!/usr/bin/env ruby

require 'minitest/autorun'
require 'pty'
require 'expect'
require 'timeout'

class RubyTextDemoTest < Minitest::Test
  # Test the demo/slideshow functionality
  def test_001_demo_automation
    # Run the demo in automated mode
    PTY.spawn('ruby -e "require \"rubytext\"; RubyText.start { demo_mode }"') do |read, write, pid|
      begin
        # Wait for demo to start
        read.expect(/Demo/, 10)
        
        # Send navigation commands
        write.puts "n"  # next slide
        sleep 0.5
        write.puts "n"  # next slide
        sleep 0.5
        write.puts "q"  # quit
        
        # Should exit cleanly
        Process.wait(pid)
        assert_equal 0, $?.exitstatus
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_002_slideshow_regression
    # Capture expected screen states and compare
    expected_screens = load_expected_screens
    current_screens = capture_current_screens
    
    expected_screens.each_with_index do |expected, index|
      assert_equal expected, current_screens[index], "Screen #{index} doesn't match expected"
    end
  end
end
