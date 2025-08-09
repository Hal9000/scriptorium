# Test file for gem asset management functionality
# Tests asset management when Scriptorium is installed as a gem

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require_relative '../../lt3scriptor'
require 'fileutils'

class TestGemAssetManagement < Minitest::Test
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @test_dir = "test/gem_asset_management_test"
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
    FileUtils.mkdir_p(@test_dir)
    Scriptorium::Repo.testing = true
    
    # Create test repository with unique view name
    @repo = create_test_repo
    @repo.create_view("gem_asset_test_view", "Testing gem assets")
    
    # Set up LiveText variables for testing
    setup_livetext_vars
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
    # Also clean up the test repository
    FileUtils.rm_rf("test/scriptorium-TEST") if File.exist?("test/scriptorium-TEST")
  end

  def setup_livetext_vars
    # Set up LiveText variables for testing
    @vars = { View: "gem_asset_test_view", "post.id": "0001" }
  end

  def process_livetext(content)
    # Create a temporary file with the content
    temp_file = "#{@test_dir}/temp_livetext.lt3"
    write_file(temp_file, content)
    
    # Process with Livetext using the plugin
    begin
      live = Livetext.customize(mix: "lt3scriptor", call: ".nopara", vars: @vars)
      body, vars = live.process(file: temp_file)
      vars = vars.to_h
      return { vars: vars, body: body }
    rescue => e
      puts "Livetext error: #{e.message}"
      puts "Backtrace: #{e.backtrace.first}"
      return { error: e.message, backtrace: e.backtrace.first }
    ensure
      # Clean up
      File.delete(temp_file) if File.exist?(temp_file)
    end
  end

  def test_001_gem_asset_discovery_in_development
    # Test that gem assets are found in development environment
    content = "$$asset[icons/ui/back-arrow.svg]"
    result = process_livetext(content)
    
    # Should find gem asset and return correct path
    assert_equal "assets/icons/ui/back-arrow.svg", result[:body].strip
  end

  def test_002_gem_asset_discovery_in_production
    # Test that gem assets are found in production environment
    # This would require simulating a gem installation
    skip "Requires gem installation simulation"
  end

  def test_003_gem_assets_copied_to_theme_during_repo_creation
    # Test that theme-specific gem assets are copied during repo creation
    theme_assets_dir = @repo.root/"themes"/"standard"/"assets"
    
    # Check that theme assets were copied
    assert Dir.exist?(theme_assets_dir), "Theme assets directory should exist"
    
    # Check for specific theme assets
    expected_theme_assets = [
      "standard/favicon.svg",
      "icons/ui/back-arrow.svg",
      "icons/social/twitter.svg"
    ]
    
    expected_theme_assets.each do |asset|
      asset_path = theme_assets_dir/asset
      assert File.exist?(asset_path), "Theme asset #{asset} should be copied"
    end
  end

  def test_004_gem_assets_copied_to_library_during_repo_creation
    # Test that application-wide gem assets are copied to library
    library_dir = @repo.root/"assets"/"library"
    
    # Check that library directory exists
    assert Dir.exist?(library_dir), "Library directory should exist"
    
    # Check for specific library assets
    expected_library_assets = [
      "placeholder.svg"
    ]
    
    expected_library_assets.each do |asset|
      asset_path = library_dir/asset
      assert File.exist?(asset_path), "Library asset #{asset} should be copied"
    end
  end

  def test_005_gem_assets_in_search_hierarchy
    # Test that gem assets are found in the correct priority order
    content = "$$asset[icons/ui/back-arrow.svg]"
    result = process_livetext(content)
    
    # Should find gem asset and return correct path
    assert_equal "assets/icons/ui/back-arrow.svg", result[:body].strip
  end

  def test_006_gem_assets_override_by_user_assets
    # Test that user assets override gem assets
    # Create a user asset with the same name as a gem asset
    user_asset_path = @repo.root/"assets"/"icons"/"ui"/"back-arrow.svg"
    FileUtils.mkdir_p(File.dirname(user_asset_path))
    File.write(user_asset_path, "User asset content")
    
    content = "$$asset[icons/ui/back-arrow.svg]"
    result = process_livetext(content)
    
    # Should find user asset first (higher priority)
    assert_equal "assets/icons/ui/back-arrow.svg", result[:body].strip
  end

  def test_007_gem_asset_path_resolution
    # Test that gem asset paths are resolved correctly
    begin
      gem_spec = Gem.loaded_specs['scriptorium']
      if gem_spec
        # Production environment - gem is installed
        gem_assets_dir = "#{gem_spec.full_gem_path}/assets"
        assert Dir.exist?(gem_assets_dir), "Gem assets directory should exist"
        
        # Check for specific gem assets
        expected_gem_assets = [
          "icons/ui/back-arrow.svg",
          "icons/social/twitter.svg",
          "samples/placeholder.svg",
          "themes/standard/favicon.svg"
        ]
        
        expected_gem_assets.each do |asset|
          asset_path = "#{gem_assets_dir}/#{asset}"
          assert File.exist?(asset_path), "Gem asset #{asset} should exist"
        end
      else
        # Development environment - use working path
        dev_assets_dir = File.expand_path("assets")
        assert Dir.exist?(dev_assets_dir), "Development assets directory should exist"
      end
    rescue => e
      # If gem lookup fails, that's expected in development
              dev_assets_dir = File.expand_path("assets")
      assert Dir.exist?(dev_assets_dir), "Development assets directory should exist"
    end
  end

  def test_008_gem_assets_not_copied_to_output
    # Test that gem assets are not copied to output directory during generation
    # (they should only be referenced)
    output_assets_dir = @repo.root/"views"/"gem_asset_test_view"/"output"/"assets"
    
    # Generate a post that references gem assets
    draft_body = "$$asset[icons/ui/back-arrow.svg]"
    name = @repo.create_draft(title: "Gem Asset Test", views: ["gem_asset_test_view"], body: draft_body)
    num = @repo.finish_draft(name)
    @repo.generate_post(num)
    
    # Check that gem assets are not copied to output
    gem_asset_in_output = output_assets_dir/"icons"/"ui"/"back-arrow.svg"
    refute File.exist?(gem_asset_in_output), "Gem assets should not be copied to output"
  end

  private

  def write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path)) unless Dir.exist?(File.dirname(path))
    File.write(path, content)
  end
end
