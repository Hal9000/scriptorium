#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class ThemeManagementTest < Minitest::Test
  include TestHelpers
  
  def setup
    @repo = create_test_repo
    @api = Scriptorium::API.new(testmode: true)
    @api.open_repo(@repo.root)
  end

  def teardown
    system("rm -rf test/scriptorium-TEST")
  end

  def test_001_themes_available_returns_list
    themes = @api.themes_available
    assert themes.is_a?(Array), "themes_available should return an array"
    assert_includes themes, "standard", "Should include standard theme"
  end

  def test_002_system_themes_returns_list
    system_themes = @api.system_themes
    assert system_themes.is_a?(Array), "system_themes should return an array"
    assert_includes system_themes, "standard", "Should include standard theme"
  end

  def test_003_user_themes_returns_list
    user_themes = @api.user_themes
    assert user_themes.is_a?(Array), "user_themes should return an array"
    # Initially should be empty or contain only user-created themes
  end

  def test_004_theme_exists_checks_correctly
    assert @api.theme_exists?("standard"), "Standard theme should exist"
    assert !@api.theme_exists?("nonexistent"), "Nonexistent theme should not exist"
  end

  def test_005_clone_theme_creates_new_theme
    # Clone standard theme to a new user theme
    new_theme = @api.clone_theme("standard", "my-custom-theme")
    assert_equal "my-custom-theme", new_theme
    
    # Check that it exists
    assert @api.theme_exists?("my-custom-theme"), "Cloned theme should exist"
    assert_includes @api.user_themes, "my-custom-theme", "Cloned theme should be in user themes"
    
    # Check that theme directory was created
    theme_dir = @repo.root/:themes/"my-custom-theme"
    assert Dir.exist?(theme_dir), "Theme directory should exist"
  end

  def test_006_clone_theme_validates_source
    assert_raises(ThemeNotFound) do
      @api.clone_theme("nonexistent", "new-theme")
    end
  end

  def test_007_clone_theme_validates_new_name
    assert_raises(ThemeAlreadyExists) do
      @api.clone_theme("standard", "standard")
    end
    
    assert_raises(ThemeNameInvalid) do
      @api.clone_theme("standard", "invalid name!")
    end
  end

  def test_008_clone_theme_copies_files
    # Clone standard theme
    @api.clone_theme("standard", "test-theme")
    
    # Check that key files were copied
    theme_dir = @repo.root/:themes/"test-theme"
    
    # Check for layout.txt in the correct location
    layout_file = theme_dir/:layout/"layout.txt"
    assert File.exist?(layout_file), "layout.txt should be copied to #{layout_file}"
    
    # Check for config files in layout/config/
    header_file = theme_dir/:layout/:config/"header.txt"
    footer_file = theme_dir/:layout/:config/"footer.txt"
    
    assert File.exist?(header_file), "header.txt should be copied to #{header_file}"
    assert File.exist?(footer_file), "footer.txt should be copied to #{footer_file}"
  end
end
