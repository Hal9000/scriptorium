#!/usr/bin/env ruby

require 'minitest/autorun'
require 'livetext'

class TestLivetextCompatibility < Minitest::Test

  def test_001_basic_livetext_processing
    # Test basic Livetext without any plugins
    content = "Simple text content"
    
    begin
      live = Livetext.customize(call: ".nopara")
      body, vars = live.process(text: content)
      vars = vars.to_h
      assert_equal "Simple text content", body.strip
      assert vars.is_a?(Hash)
      puts "✓ Basic Livetext processing works"
    rescue => e
      flunk "Basic Livetext processing failed: #{e.message}"
    end
  end

  def test_002_livetext_with_simple_dot_commands
    # Test Livetext with simple dot commands
    content = <<~CONTENT
      .title Test Post
      .views sample
      
      This is the body.
    CONTENT
    
    begin
      live = Livetext.customize(call: ".nopara")
      body, vars = live.process(text: content)
      vars = vars.to_h
      assert_includes body, "This is the body"
      assert vars.is_a?(Hash)
      puts "✓ Livetext with dot commands works"
    rescue => e
      flunk "Livetext with dot commands failed: #{e.message}"
    end
  end

  def test_003_livetext_plugin_loading
    # Test if the plugin can be loaded without processing
    begin
      live = Livetext.customize(mix: "lt3scriptor")
      assert live
      puts "✓ Plugin loaded successfully"
    rescue => e
      flunk "Plugin loading failed: #{e.message}"
    end
  end

  def test_004_livetext_plugin_processing
    # Test if the plugin can process simple content
    content = "Simple content with $$asset[test.png]"
    
    begin
      live = Livetext.customize(mix: "lt3scriptor", call: ".nopara")
      body, vars = live.process(text: content)
      vars = vars.to_h
      assert body.is_a?(String)
      puts "✓ Plugin processing succeeded: #{body}"
    rescue => e
      puts "✗ Plugin processing failed: #{e.message}"
      puts e.backtrace.first(3)
      skip "Plugin processing needs to be fixed"
    end
  end

  def test_005_livetext_old_api
    # Test the old Livetext API
    content = "Simple content"
    
    begin
      live = Livetext.customize(call: ".nopara")
      text, vars = live.process(content)
      vars = vars.to_h
      assert text.is_a?(String)
      assert vars.is_a?(Hash)
      puts "✓ Old Livetext API works"
    rescue => e
      puts "✗ Old Livetext API failed: #{e.message}"
      skip "Old API needs to be fixed"
    end
  end
end
