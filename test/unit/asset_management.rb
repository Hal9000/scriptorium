# Test file for asset management functionality
# Tests the $$asset and $$image_asset Livetext functions

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require_relative '../../lt3scriptor'
require 'fileutils'

class TestAssetManagement < Minitest::Test
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @test_dir = "test/asset_management_test"
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
    FileUtils.mkdir_p(@test_dir)
    Scriptorium::Repo.testing = true
    
    # Create test repository with unique view name
    @repo = create_test_repo
    @repo.create_view("asset_test_view", "Testing assets")
    
    # Set up LiveText variables for testing
    setup_livetext_vars
    
    # Create test assets
    create_test_assets
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
    # Also clean up the test repository
    FileUtils.rm_rf("test/scriptorium-TEST") if File.exist?("test/scriptorium-TEST")
  end

  def setup_livetext_vars
    # Set up LiveText variables for testing
    @vars = { View: "asset_test_view", "post.id": "0001" }
  end

  def create_test_assets
    # Create global asset
    File.write(@repo.root/"assets"/"image1.jpg", "Global Asset 1")
    
    # Create view asset
    File.write(@repo.root/"views"/"asset_test_view"/"assets"/"image2.jpg", "View Asset 2")
    
    # Create post asset
    FileUtils.mkdir_p(@repo.root/"posts"/"0001"/"assets")
    File.write(@repo.root/"posts"/"0001"/"assets"/"image3.jpg", "Post Asset 3")
    
    # Create library asset
    FileUtils.mkdir_p(@repo.root/"assets"/"library")
    File.write(@repo.root/"assets"/"library"/"image4.jpg", "Library Asset 4")
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

  def test_001_asset_function_finds_global_asset
    content = "$$asset[image1.jpg]"
    result = process_livetext(content)
    assert_equal "assets/image1.jpg", result[:body].strip
  end

  def test_002_asset_function_finds_view_asset
    content = "$$asset[image2.jpg]"
    result = process_livetext(content)
    
    assert_equal "assets/image2.jpg", result[:body].strip
  end

  def test_003_asset_function_finds_post_asset
    content = "$$asset[image3.jpg]"
    result = process_livetext(content)
    
    assert_equal "assets/0001/image3.jpg", result[:body].strip
  end

  def test_003b_asset_function_finds_library_asset
    content = "$$asset[image4.jpg]"
    result = process_livetext(content)
    
    assert_equal "assets/image4.jpg", result[:body].strip
  end

  def test_004_asset_function_search_hierarchy
    # Create same filename in multiple locations to test hierarchy
    File.write(@repo.root/"assets"/"duplicate.jpg", "Global")
    File.write(@repo.root/"views"/"asset_test_view"/"assets"/"duplicate.jpg", "View")
    File.write(@repo.root/"posts"/"0001"/"assets"/"duplicate.jpg", "Post")
    
    content = "$$asset[duplicate.jpg]"
    result = process_livetext(content)
    
    # Should find post asset first (highest priority)
    assert_equal "assets/0001/duplicate.jpg", result[:body].strip
  end

  def test_005_asset_function_missing_asset_generates_placeholder
    content = "$$asset[nonexistent.jpg]"
    result = process_livetext(content)
    
    assert_equal "assets/missing/nonexistent.jpg.svg", result[:body].strip
  end

  def test_006_image_asset_function_wraps_in_img_tag
    content = "$$image_asset[image1.jpg]"
    result = process_livetext(content)
    
    expected = '<img src="assets/image1.jpg" alt="image1.jpg">'
    assert_equal expected, result[:body].strip
  end

  def test_007_image_asset_function_with_missing_asset
    content = "$$image_asset[missing.jpg]"
    result = process_livetext(content)
    
    expected = '<img src="assets/missing/missing.jpg.svg" alt="missing.jpg">'
    assert_equal expected, result[:body].strip
  end

  def test_008_asset_function_without_post_id
    # Test without post.id variable
    @vars["post.id"] = nil
    
    content = "$$asset[image1.jpg]"
    result = process_livetext(content)
    assert_equal "assets/image1.jpg", result[:body].strip
    
    # Post assets should not be found
    content = "$$asset[image3.jpg]"
    result = process_livetext(content)
    assert_equal "assets/missing/image3.jpg.svg", result[:body].strip
    
    # Restore post.id for other tests
    @vars["post.id"] = "0001"
  end

  def test_009_asset_function_output_directory_structure
    # Call asset function to test path returns
    result1 = process_livetext("$$asset[image1.jpg]")
    result2 = process_livetext("$$asset[image2.jpg]")
    result3 = process_livetext("$$asset[image3.jpg]")
    result4 = process_livetext("$$asset[nonexistent.jpg]")
    
    # Verify correct paths are returned
    assert_equal "assets/image1.jpg", result1[:body].strip
    assert_equal "assets/image2.jpg", result2[:body].strip
    assert_equal "assets/0001/image3.jpg", result3[:body].strip
    assert_equal "assets/missing/nonexistent.jpg.svg", result4[:body].strip
  end

  def test_010_asset_function_idempotent_calling
    # Call asset function multiple times
    result1 = process_livetext("$$asset[image1.jpg]")
    result2 = process_livetext("$$asset[image1.jpg]")
    result3 = process_livetext("$$asset[image1.jpg]")
    
    # Should return same result each time
    assert_equal result1[:body].strip, result2[:body].strip
    assert_equal result2[:body].strip, result3[:body].strip
  end

  def test_011_theme_assets_in_hierarchy
    # Create theme assets directory and add a test asset
    theme_assets_dir = @repo.root/"themes"/"standard"/"assets"
    FileUtils.mkdir_p(theme_assets_dir)
    File.write(theme_assets_dir/"theme-test.jpg", "Theme Asset")
    
    # Create same filename in multiple locations to test hierarchy
    File.write(@repo.root/"assets"/"theme-test.jpg", "Global")
    File.write(@repo.root/"views"/"asset_test_view"/"assets"/"theme-test.jpg", "View")
    File.write(@repo.root/"posts"/"0001"/"assets"/"theme-test.jpg", "Post")
    
    # Test with post context - should find post asset first (highest priority)
    content = "$$asset[theme-test.jpg]"
    result = process_livetext(content)
    assert_equal "assets/0001/theme-test.jpg", result[:body].strip
    
    # Test without post context - should find view asset first
    # Temporarily remove post.id from vars
    original_post_id = @vars["post.id"]
    @vars["post.id"] = nil
    
    content = "$$asset[theme-test.jpg]"
    result = process_livetext(content)
    assert_equal "assets/theme-test.jpg", result[:body].strip
    
    # Restore post.id for other tests
    @vars["post.id"] = original_post_id
  end

  def test_012_gem_assets_in_hierarchy
    # Test gem assets (lowest priority)
    content = "$$asset[icons/ui/back-arrow.svg]"
    result = process_livetext(content)
    
    # Should find gem asset and return correct path
    assert_equal "assets/icons/ui/back-arrow.svg", result[:body].strip
  end

  private

  def process_livetext_no_post(content)
    # Process content without post context
    temp_file = "#{@test_dir}/temp_livetext_no_post.lt3"
    write_file(temp_file, content)
    
    # Use only View variable, no post.id
    vars = { View: "asset_test_view" }
    
    begin
      live = Livetext.customize(mix: "lt3scriptor", call: ".nopara", vars: vars)
      body, _vars = live.process(file: temp_file)
      return { vars: _vars, body: body }
    rescue => e
      puts "Livetext error: #{e.message}"
      puts "Backtrace: #{e.backtrace.first}"
      return { error: e.message, backtrace: e.backtrace.first }
    ensure
      # Clean up
      File.delete(temp_file) if File.exist?(temp_file)
    end
  end
end
