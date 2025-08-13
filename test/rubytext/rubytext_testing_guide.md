# RubyText Testing Guide

## Overview

Testing curses-based applications like RubyText is challenging because they're inherently interactive and terminal-dependent. This guide outlines a comprehensive testing strategy that balances automation with practical reality.

## Testing Challenges

### **1. Terminal Dependencies**
- Different terminals behave differently
- Terminal capabilities vary (colors, Unicode, etc.)
- Screen sizes and resolutions differ

### **2. Interactive Nature**
- User input is time-sensitive
- Screen state changes dynamically
- Hard to capture and verify visual output

### **3. Platform Differences**
- Unix/Linux vs macOS vs Windows
- Different curses implementations
- Terminal emulator variations

## Testing Strategy

### **1. Component Testing (Recommended)**

Test individual components in isolation:

```ruby
# Test menu logic without curses
def test_menu_logic
  menu = RubyText::Menu.new(["Option 1", "Option 2"])
  assert_equal 2, menu.options.length
  assert_equal "Option 1", menu.options[0]
end

# Test screen buffer logic
def test_screen_buffer
  screen = RubyText::Screen.new(80, 24)
  screen.puts("Hello")
  assert_includes screen.buffer, "Hello"
end
```

### **2. PTY-Based Integration Testing**

Use PTY for realistic terminal interaction:

```ruby
def test_basic_interaction
  PTY.spawn('ruby -e "require \"rubytext\"; RubyText.start { puts \"Hello\"; gets }"') do |read, write, pid|
    begin
      read.expect(/Hello/, 5)
      write.puts "q"
      Process.wait(pid)
      assert_equal 0, $?.exitstatus
    ensure
      Process.kill('TERM', pid) rescue nil
    end
  end
end
```

### **3. Regression Testing with Screenshots**

Capture expected screen states:

```ruby
def test_screen_regression
  # Capture current screen
  current_screen = capture_screen do
    run_rubytext_app_with_input(["help", "quit"])
  end
  
  # Compare with expected
  expected_screen = File.read("test/fixtures/expected_help_screen.txt")
  assert_equal expected_screen, current_screen
end
```

### **4. Automated Demo Testing**

Automate your existing demo/slideshow:

```ruby
def test_demo_automation
  PTY.spawn('ruby demo.rb --automated') do |read, write, pid|
    begin
      # Navigate through slides
      read.expect(/Slide 1/, 5)
      write.puts "n"  # next
      read.expect(/Slide 2/, 5)
      write.puts "q"  # quit
      
      Process.wait(pid)
      assert_equal 0, $?.exitstatus
    ensure
      Process.kill('TERM', pid) rescue nil
    end
  end
end
```

## Test Categories

### **Core Functionality**
- [ ] Menu creation and navigation
- [ ] Screen rendering and layout
- [ ] Input handling (keyboard, mouse)
- [ ] Color and style support
- [ ] Window management

### **User Interface**
- [ ] Menu interactions
- [ ] Form input
- [ ] Dialog boxes
- [ ] Progress indicators
- [ ] Error messages

### **Performance**
- [ ] Large content rendering
- [ ] Screen refresh speed
- [ ] Memory usage
- [ ] Input responsiveness

### **Error Handling**
- [ ] Invalid input
- [ ] Terminal errors
- [ ] Resource limits
- [ ] Graceful degradation

### **Platform Compatibility**
- [ ] Different terminals
- [ ] Screen sizes
- [ ] Color support
- [ ] Unicode support

## Implementation Examples

### **1. Menu Testing**

```ruby
class MenuTest < Minitest::Test
  def test_menu_creation
    menu = RubyText::Menu.new(["Option 1", "Option 2"])
    assert_equal 2, menu.options.length
  end
  
  def test_menu_interaction
    PTY.spawn('ruby -e "require \"rubytext\"; RubyText.start { menu = RubyText::Menu.new([\"A\", \"B\"]); puts menu.show; gets }"') do |read, write, pid|
      begin
        read.expect(/A/, 5)
        write.puts "\r"  # Select first option
        result = read.expect(/A/, 5)
        assert result
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
end
```

### **2. Screen Testing**

```ruby
class ScreenTest < Minitest::Test
  def test_screen_rendering
    PTY.spawn('ruby -e "require \"rubytext\"; RubyText.start { puts \"Test\"; gets }"') do |read, write, pid|
      begin
        result = read.expect(/Test/, 5)
        assert result, "Screen should display content"
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
end
```

### **3. Input Testing**

```ruby
class InputTest < Minitest::Test
  def test_keyboard_input
    PTY.spawn('ruby -e "require \"rubytext\"; RubyText.start { key = RubyText.getch; puts \"Key: #{key}\"; gets }"') do |read, write, pid|
      begin
        write.puts "a"
        result = read.expect(/Key: a/, 5)
        assert result, "Should detect key press"
      ensure
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
end
```

## Testing Tools

### **1. PTY (Pseudo-Terminal)**
- Realistic terminal interaction
- Captures input/output
- Good for integration testing

### **2. Screen Capture**
- Capture screen states
- Compare with expected output
- Good for regression testing

### **3. Mock Terminals**
- Test logic without curses
- Faster execution
- Good for unit testing

### **4. Automated Demos**
- Test real user workflows
- Verify end-to-end functionality
- Good for acceptance testing

## Best Practices

### **1. Test Structure**
- Separate unit tests from integration tests
- Use descriptive test names
- Group related tests together

### **2. Error Handling**
- Test error conditions
- Verify graceful degradation
- Check error messages

### **3. Performance**
- Test with realistic data sizes
- Monitor memory usage
- Check response times

### **4. Platform Coverage**
- Test on multiple platforms
- Use CI/CD for automated testing
- Document platform-specific issues

## Manual Testing Checklist

Since automated testing can't cover everything, maintain a manual testing checklist:

### **Visual Verification**
- [ ] Colors display correctly
- [ ] Text alignment is proper
- [ ] Screen layout is clean
- [ ] Unicode characters render

### **Interaction Testing**
- [ ] Menu navigation works
- [ ] Keyboard shortcuts function
- [ ] Mouse input responds
- [ ] Error messages are clear

### **Performance Testing**
- [ ] Large content renders quickly
- [ ] Screen updates are smooth
- [ ] Input is responsive
- [ ] Memory usage is reasonable

## Conclusion

Testing RubyText requires a multi-faceted approach:

1. **Unit test the core logic** (menus, screens, input handling)
2. **Integration test with PTY** (real terminal interaction)
3. **Regression test with screenshots** (visual verification)
4. **Manual test the complex interactions** (user experience)

The key is to **automate what you can** and **accept that some testing will always be manual**. Focus on testing the critical paths and user workflows, and use your existing demo/slideshow as a foundation for automated testing.

Remember: **Perfect automated testing of curses applications is impossible, but good testing is definitely achievable!**
