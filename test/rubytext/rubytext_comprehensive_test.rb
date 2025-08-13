#!/usr/bin/env ruby

require 'minitest/autorun'
require 'pty'
require 'expect'
require 'timeout'
require 'tempfile'

class RubyTextComprehensiveTest < Minitest::Test
  # Test categories for RubyText
  
  def test_001_basic_initialization
    # Test that RubyText can start without errors
    PTY.spawn('ruby -e "require \"rubytext\"; RubyText.start { puts \"Hello\"; gets }"') do |read, write, pid|
      begin
        # Wait for RubyText to start
        result = read.expect(/Hello/, 5)
        assert result, "RubyText should start and display 'Hello'"
        
        # Send quit command
        write.puts "q"
        Process.wait(pid)
        assert_equal 0, $?.exitstatus
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_002_menu_functionality
    # Test menu creation and interaction
    menu_script = <<~RUBY
      require 'rubytext'
      RubyText.start do
        menu = RubyText::Menu.new(["Option 1", "Option 2", "Option 3"])
        result = menu.show
        puts "Selected: #{result}"
        gets
      end
    RUBY
    
    PTY.spawn("ruby -e \"#{menu_script}\"") do |read, write, pid|
      begin
        # Wait for menu to appear
        read.expect(/Option 1/, 5)
        
        # Navigate and select
        write.puts "\e[B"  # Down arrow
        sleep 0.1
        write.puts "\r"    # Enter
        
        # Check result
        result = read.expect(/Selected: Option 2/, 5)
        assert result, "Menu should return selected option"
        
        write.puts "q"
        Process.wait(pid)
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_003_screen_rendering
    # Test screen rendering and layout
    screen_script = <<~RUBY
      require 'rubytext'
      RubyText.start do
        screen = RubyText::Screen.new(80, 24)
        screen.puts("Test content")
        screen.refresh
        gets
      end
    RUBY
    
    PTY.spawn("ruby -e \"#{screen_script}\"") do |read, write, pid|
      begin
        # Wait for content to appear
        result = read.expect(/Test content/, 5)
        assert result, "Screen should display content"
        
        write.puts "q"
        Process.wait(pid)
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_004_input_handling
    # Test various input methods
    input_script = <<~RUBY
      require 'rubytext'
      RubyText.start do
        puts "Press any key..."
        key = RubyText.getch
        puts "Key pressed: #{key.inspect}"
        gets
      end
    RUBY
    
    PTY.spawn("ruby -e \"#{input_script}\"") do |read, write, pid|
      begin
        read.expect(/Press any key/, 5)
        
        # Send a key
        write.puts "a"
        
        result = read.expect(/Key pressed/, 5)
        assert result, "Should detect key press"
        
        write.puts "q"
        Process.wait(pid)
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_005_color_and_style
    # Test color and style functionality
    color_script = <<~RUBY
      require 'rubytext'
      RubyText.start do
        RubyText.color(:red) { puts "Red text" }
        RubyText.color(:blue) { puts "Blue text" }
        RubyText.bold { puts "Bold text" }
        gets
      end
    RUBY
    
    PTY.spawn("ruby -e \"#{color_script}\"") do |read, write, pid|
      begin
        # Check for colored output (this might be hard to test in PTY)
        result = read.expect(/Red text|Blue text|Bold text/, 5)
        assert result, "Should display styled text"
        
        write.puts "q"
        Process.wait(pid)
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_006_window_management
    # Test window creation and management
    window_script = <<~RUBY
      require 'rubytext'
      RubyText.start do
        window = RubyText::Window.new(10, 5, 5, 5)
        window.puts("Window content")
        window.refresh
        gets
      end
    RUBY
    
    PTY.spawn("ruby -e \"#{window_script}\"") do |read, write, pid|
      begin
        result = read.expect(/Window content/, 5)
        assert result, "Window should display content"
        
        write.puts "q"
        Process.wait(pid)
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_007_error_handling
    # Test error handling and recovery
    error_script = <<~RUBY
      require 'rubytext'
      begin
        RubyText.start do
          # Try to do something that might cause an error
          RubyText::Screen.new(-1, -1)  # Invalid dimensions
        end
      rescue => e
        puts "Error caught: #{e.class}"
        exit 0
      end
    RUBY
    
    PTY.spawn("ruby -e \"#{error_script}\"") do |read, write, pid|
      begin
        result = read.expect(/Error caught/, 5)
        assert result, "Should handle errors gracefully"
        
        Process.wait(pid)
        assert_equal 0, $?.exitstatus
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_008_performance
    # Test performance with large content
    performance_script = <<~RUBY
      require 'rubytext'
      require 'benchmark'
      
      RubyText.start do
        time = Benchmark.measure do
          100.times do |i|
            puts "Line #{i}: " + "x" * 50
          end
        end
        puts "Rendering time: #{time.real}s"
        gets
      end
    RUBY
    
    PTY.spawn("ruby -e \"#{performance_script}\"") do |read, write, pid|
      begin
        result = read.expect(/Rendering time/, 10)
        assert result, "Should complete performance test"
        
        write.puts "q"
        Process.wait(pid)
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
  
  def test_009_integration_scenarios
    # Test real-world usage scenarios
    scenarios = [
      {
        name: "Simple menu navigation",
        script: <<~RUBY,
          require 'rubytext'
          RubyText.start do
            menu = RubyText::Menu.new(["Edit", "View", "Quit"])
            result = menu.show
            puts "Selected: #{result}"
            gets
          end
        RUBY
        expected: /Selected: (Edit|View|Quit)/
      },
      {
        name: "Form input",
        script: <<~RUBY,
          require 'rubytext'
          RubyText.start do
            puts "Enter your name:"
            name = gets.chomp
            puts "Hello, #{name}!"
            gets
          end
        RUBY
        expected: /Hello, TestUser!/
      }
    ]
    
    scenarios.each do |scenario|
      PTY.spawn("ruby -e \"#{scenario[:script]}\"") do |read, write, pid|
        begin
          # Wait for prompt
          read.expect(/Enter your name:|Menu/, 5)
          
          # Send input
          if scenario[:name].include?("menu")
            write.puts "\r"  # Select first option
          else
            write.puts "TestUser"
            write.puts "\r"
          end
          
          # Check result
          result = read.expect(scenario[:expected], 5)
          assert result, "Scenario '#{scenario[:name]}' should work"
          
          write.puts "q"
          Process.wait(pid)
        ensure
          Process.kill('TERM', pid) rescue nil
        end
      end
    end
  end
  
  private
  
  def load_expected_screens
    # Load expected screen states from fixtures
    screens = []
    fixture_dir = "test/fixtures/rubytext_screens"
    if Dir.exist?(fixture_dir)
      Dir.glob("#{fixture_dir}/*.txt").sort.each do |file|
        screens << File.read(file)
      end
    end
    screens
  end
  
  def capture_current_screens
    # Capture current screen states for comparison
    screens = []
    # Implementation would depend on RubyText's screen capture capabilities
    screens
  end
end
