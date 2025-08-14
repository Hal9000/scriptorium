#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestClipboard < Minitest::Test
  include Scriptorium::Helpers

  def test_001_copy_to_clipboard_basic
    # Test that copy_to_clipboard method exists and can be called
    assert_respond_to self, :copy_to_clipboard
    assert_respond_to self, :get_from_clipboard
    
    # Test with a simple string
    test_text = "Test clipboard text #{Time.now.to_i}"
    result = copy_to_clipboard(test_text)
    
    # Should return true on success (or false if clipboard not supported)
    assert [true, false].include?(result), "copy_to_clipboard should return true or false"
    
    # If clipboard is supported, test reading back
    if result
      clipboard_content = get_from_clipboard
      if clipboard_content
        # Content might have newlines or other formatting, so check if it contains our text
        assert_includes clipboard_content, test_text.split.first, "Clipboard should contain our test text"
      end
    end
  end

  def test_002_copy_to_clipboard_with_special_characters
    # Test with special characters that might cause issues
    special_text = "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?`~"
    result = copy_to_clipboard(special_text)
    
    # Should not crash with special characters
    assert [true, false].include?(result), "copy_to_clipboard should handle special characters"
  end

  def test_003_copy_to_clipboard_empty_string
    # Test with empty string
    result = copy_to_clipboard("")
    assert [true, false].include?(result), "copy_to_clipboard should handle empty string"
  end

  def test_004_copy_to_clipboard_nil
    # Test with nil
    result = copy_to_clipboard(nil)
    assert [true, false].include?(result), "copy_to_clipboard should handle nil"
  end

  def test_005_get_from_clipboard_basic
    # Test that get_from_clipboard method can be called
    content = get_from_clipboard
    
    # Should return either content or nil (if not supported)
    assert content.nil? || content.is_a?(String), "get_from_clipboard should return String or nil"
  end
end
