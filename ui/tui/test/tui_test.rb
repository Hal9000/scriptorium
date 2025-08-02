require 'minitest/autorun'
require_relative '../../../lib/scriptorium'

class TUITest < Minitest::Test
  def test_tui_structure
    # Test that the TUI file exists in the new location
    tui_file = File.join(__dir__, '..', 'bin', 'scriptorium')
    assert File.exist?(tui_file), "TUI executable should exist at #{tui_file}"
    
    # Test that the file is executable
    assert File.executable?(tui_file), "TUI executable should be executable"
  end
  
  def test_require_path
    # Test that the require path in the TUI file is correct
    tui_file = File.join(__dir__, '..', 'bin', 'scriptorium')
    content = File.read(tui_file)
    
    # Should require the core library
    assert content.include?('require_relative "../../../lib/scriptorium"'), 
           "TUI should require the core library with correct relative path"
  end
end 