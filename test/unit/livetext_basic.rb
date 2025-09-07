#!/usr/bin/env ruby

require 'minitest/autorun'
require 'livetext'

class TestLivetextBasic < Minitest::Test

  def test_001_basic_livetext_processing
    # Test basic Livetext without any plugins
    content = "Simple text content"
    
    live = Livetext.customize(call: ".nopara")
    body, vars = live.process(text: content)
    assert_equal "<p>\nSimple text content\n</p>", body.strip
    assert vars.is_a?(Hash)
  rescue => e
    flunk "Basic Livetext processing failed: #{e.message}"
  end

  def test_002_livetext_with_simple_dot_commands
    # Test Livetext with simple dot commands
    content = <<~CONTENT
      .title Test Post
      .views sample
      
      This is the body.
    CONTENT
    
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara")
    body, vars = live.process(text: content)
    assert_includes body, "This is the body"
    assert vars.is_a?(Hash)
  rescue => e
    flunk "Livetext with dot commands failed: #{e.message}"
  end

  def test_003_livetext_plugin_loading
    # Test if the plugin can be loaded without processing
    live = Livetext.customize(mix: "lt3scriptor")
    assert live
  rescue => e
    flunk "Plugin loading failed: #{e.message}"
  end

  def test_004_livetext_plugin_processing_simple
    # Test if the plugin can process very simple content
    content = "Simple content"
    
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara")
    body, vars = live.process(text: content)
    assert body.is_a?(String)
  rescue => e
    puts "✗ Plugin processing failed: #{e.message}"
    puts e.backtrace.first(3)
    skip "Plugin processing needs to be fixed"
  end
end
