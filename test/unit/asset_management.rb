# Test file for asset management functionality
# Tests the $$asset and $$image Livetext functions

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require 'fileutils'

class TestAssetManagement < Minitest::Test
  include TestHelpers

  def setup
    @repo_name = "test/scriptorium-TEST"
    @view_name = "asset_test_view"
    
    # Create test repo and API
    @api = Scriptorium::API.new
    @api.create_repo(@repo_name)
    @api.open_repo(@repo_name)
    
    # Create a view for testing
    @api.create_view(@view_name, "Asset Test View")
    
    # Create test posts
    @api.create_post("Test Post 1", "This is the first test post for asset testing.")
    @api.create_post("Test Post 2", "This is the second test post for asset testing.")
    
    # Generate the view to create output directory structure
    @api.generate_view(@view_name)
  end

  def teardown
    FileUtils.rm_rf("test/scriptorium-TEST")  # Commented out for debugging
  end
  
  def test_001_asset_function_basic_functionality
    # Test that asset() function returns correct paths for existing assets
    # Create a global asset
    global_file = Tempfile.new(['global-image', '.jpg'])
    global_file.write("global image content")
    global_file.close
    @api.upload_asset(global_file.path, filename: "global-image.jpg")
    
    # Update existing post 0001 with asset reference
    source_file = "test/scriptorium-TEST/posts/0001/source.lt3"
    File.write(source_file, "Global asset: $$asset[global-image.jpg]")
    
    # Generate the view
    @api.generate_view(@view_name)
    
    # Check that the asset path is correct in generated HTML
    html_file = "test/scriptorium-TEST/views/#{@view_name}/output/posts/0001-test-post-1.html"
    html_content = File.read(html_file)
    
    assert_includes_concise_string html_content, "Global asset: ../assets/global-image.jpg", "Asset function should return correct path"
  end
  
  def test_002_asset_function_missing_asset
    # Test that asset() function returns fallback for missing assets
    # Update existing post 0002 with missing asset reference
    source_file = "test/scriptorium-TEST/posts/0002/source.lt3"
    File.write(source_file, "Missing asset: $$asset[missing-image.jpg]")
    
    # Generate the view
    @api.generate_view(@view_name)
    
    # Check that the fallback path is used
    html_file = "test/scriptorium-TEST/views/#{@view_name}/output/posts/0002-test-post-2.html"
    html_content = File.read(html_file)
    
    assert_includes_concise_string html_content, "Missing asset: ../assets/imagenotfound.jpg", "Asset function should return fallback for missing assets"
  end
  
  def test_003_image_function_basic_functionality
    # Test that image() function generates correct HTML
    # Create a global asset
    global_file = Tempfile.new(['global-image', '.jpg'])
    global_file.write("global image content")
    global_file.close
    @api.upload_asset(global_file.path, filename: "global-image.jpg")
    
    # Update existing post 0001 with image reference
    source_file = "test/scriptorium-TEST/posts/0001/source.lt3"
    File.write(source_file, "Image:\n.image global-image.jpg")
    
    # Generate the view
    @api.generate_view(@view_name)
    
    # Check that the image tag is correct
    html_file = "test/scriptorium-TEST/views/#{@view_name}/output/posts/0001-test-post-1.html"
    html_content = File.read(html_file)
    
    assert_includes_concise_string html_content, "<img src=../assets/global-image.jpg alt='No alt text'></img>", "Image function should generate correct HTML"
  end
  
  def test_004_image_function_with_real_asset
    # Test that image() function works with actual test assets
    # Upload a real test asset
    @api.upload_asset("test/assets/testbanner.jpg", filename: "testbanner.jpg")
    
    # Update existing post 0002 with image reference
    source_file = "test/scriptorium-TEST/posts/0002/source.lt3"
    File.write(source_file, "Real asset:\n.image testbanner.jpg")
    
    # Generate the view
    @api.generate_view(@view_name)
    
    # Check that the image tag is correct
    html_file = "test/scriptorium-TEST/views/#{@view_name}/output/posts/0002-test-post-2.html"
    html_content = File.read(html_file)
    
    assert_includes_concise_string html_content, "<img src=../assets/testbanner.jpg alt='No alt text'></img>", "Image function should work with real assets"
  end
  
  def test_005_global_asset_copied_to_view
    # Test that global assets are automatically copied to view assets during generation
    # First, create a global asset file directly in the repo
    global_asset_path = "test/scriptorium-TEST/assets/global-copy-test.jpg"
    FileUtils.cp("test/assets/testbanner.jpg", global_asset_path)
    
    # Update existing post 0001 to reference the global asset
    source_file = "test/scriptorium-TEST/posts/0001/source.lt3"
    File.write(source_file, "Global asset copy test:\n.image global-copy-test.jpg")
    
    # Assert initial state before generation
    view_assets_dir = "test/scriptorium-TEST/views/#{@view_name}/assets"
    
    # The global asset we just created should NOT be in view assets yet
    view_asset_path = "#{view_assets_dir}/global-copy-test.jpg"
    refute File.exist?(view_asset_path), "Global asset should not be in view assets before generation"
    
    # Generate the view (this should copy the global asset to the view)
    @api.generate_view(@view_name)
    
    # Check that the global asset was copied to the view assets directory
    view_asset_path = "test/scriptorium-TEST/views/#{@view_name}/assets/global-copy-test.jpg"
    assert File.exist?(view_asset_path), "Global asset should be copied to view assets directory"
    
    # Check that the image tag references the correct path
    html_file = "test/scriptorium-TEST/views/#{@view_name}/output/posts/0001-test-post-1.html"
    html_content = File.read(html_file)
    assert_includes_concise_string html_content, "<img src=../assets/global-copy-test.jpg alt='No alt text'></img>", "Image should reference the copied asset"
  end
  
  def test_006_asset_priority_hierarchy
    # Test that post assets take precedence over view assets with same filename
    # 1. Create a file with specific contents and upload to view assets
    view_file = Tempfile.new(['priority-test', '.txt'])
    view_file.write("File 1, view asset")
    view_file.close
    @api.upload_asset(view_file.path, 'view', @view_name, filename: "priority-test.txt")
    
    # 2. Create another file with SAME NAME but different contents and upload to post 2 assets
    post_file = Tempfile.new(['priority-test', '.txt'])
    post_file.write("File 2, post asset")
    post_file.close
    @api.upload_asset(post_file.path, 'post', 2, filename: "priority-test.txt")
    
    # 3. Update both posts to reference the asset
    source_file_1 = "test/scriptorium-TEST/posts/0001/source.lt3"
    File.write(source_file_1, "Asset priority test:\n$$asset[priority-test.txt]")
    
    source_file_2 = "test/scriptorium-TEST/posts/0002/source.lt3"
    File.write(source_file_2, "Asset priority test:\n$$asset[priority-test.txt]")
    
    # 4. Generate the view
    @api.generate_view(@view_name)
    
    # 5. Check that post 1 refers to the view asset (since it has no post asset)
    html_file_1 = "test/scriptorium-TEST/views/#{@view_name}/output/posts/0001-test-post-1.html"
    html_content_1 = File.read(html_file_1)
    assert_includes_concise_string html_content_1, "../assets/priority-test.txt", "Post 1 should reference the view asset"
    
    # 6. Check that post 2 refers to its own post asset (post assets take precedence)
    html_file_2 = "test/scriptorium-TEST/views/#{@view_name}/output/posts/0002-test-post-2.html"
    html_content_2 = File.read(html_file_2)
    assert_includes_concise_string html_content_2, "../assets/posts/0002/priority-test.txt", "Post 2 should reference its post asset"
    
    # 7. Verify the actual files exist in the correct locations
    view_asset_path = "test/scriptorium-TEST/views/#{@view_name}/assets/priority-test.txt"
    post_asset_path = "test/scriptorium-TEST/posts/0002/assets/priority-test.txt"
    
    assert File.exist?(view_asset_path), "View asset should exist"
    assert File.exist?(post_asset_path), "Post asset should exist"
    
    # 8. Check that the files have the correct contents
    view_content = File.read(view_asset_path)
    post_content = File.read(post_asset_path)
    
    assert_includes view_content, "File 1, view asset", "View asset should have correct content"
    assert_includes post_content, "File 2, post asset", "Post asset should have correct content"
  end

  def test_007_asset_paths_in_post_context
    # Test that asset paths work correctly in post page context (subdirectory)
    
    # 1. Create a test asset
    test_file = Tempfile.new(['path-test', '.txt'])
    test_file.write("Path test asset")
    test_file.close
    @api.upload_asset(test_file.path, 'post', 1, filename: "path-test.txt")
    
    # 2. Update post 1 to reference the asset
    source_file_1 = "test/scriptorium-TEST/posts/0001/source.lt3"
    File.write(source_file_1, "Asset path test:\n$$asset[path-test.txt]")
    
    # 3. Generate the view
    @api.generate_view(@view_name)
    
    # 4. Check post page - should have ../assets/posts/0001/path-test.txt
    post_file = "test/scriptorium-TEST/views/#{@view_name}/output/posts/0001-test-post-1.html"
    post_content = File.read(post_file)
    assert_includes_concise_string post_content, "../assets/posts/0001/path-test.txt", "Post page should reference assets with ../ prefix"
    
    # 5. Verify the asset file exists in the output directory
    asset_file = "test/scriptorium-TEST/views/#{@view_name}/output/assets/posts/0001/path-test.txt"
    assert File.exist?(asset_file), "Asset should be copied to output directory"
  end
end
