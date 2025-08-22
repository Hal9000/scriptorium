# Test file for permalink copy functionality
# Tests the clean URL copy generation for posts

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require 'fileutils'

class TestPermalinkCopy < Minitest::Test
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @test_dir = "test/symlink_test_files"
    FileUtils.mkdir_p(@test_dir)
    Scriptorium::Repo.testing = true
    
    # Create test repository
    @repo = Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)
    @view = @repo.create_view("test_view", "Test View", "Test Subtitle")
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
    FileUtils.rm_rf("test/scriptorium-TEST") if File.exist?("test/scriptorium-TEST")
  end

  # ========================================
  # clean_slugify function tests
  # ========================================

  def test_001_clean_slugify_basic
    result = clean_slugify("My Test Post")
    assert_equal "my-test-post", result
  end

  def test_002_clean_slugify_with_special_characters
    result = clean_slugify("Post with & < > \" ' characters!")
    assert_equal "post-with-characters", result
  end

  def test_003_clean_slugify_with_underscores_and_hyphens
    result = clean_slugify("Post with_underscores-and-hyphens")
    assert_equal "post-with-underscores-and-hyphens", result
  end

  def test_004_clean_slugify_with_multiple_spaces
    result = clean_slugify("Post   with   multiple   spaces")
    assert_equal "post-with-multiple-spaces", result
  end

  def test_005_clean_slugify_with_leading_trailing_hyphens
    result = clean_slugify("-Post with leading/trailing hyphens-")
    assert_equal "post-with-leadingtrailing-hyphens", result
  end

  # ========================================
  # Permalink copy generation tests
  # ========================================

  def test_006_permalink_copy_creation_for_post
    # Create a test post
    post_title = "My First Test Post"
    post_body = "This is the body of my test post."
    
    # Create draft and finish it
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    
    # Generate the post
    @repo.generate_post(post_num)
    
    # Check that both files exist
    numbered_slug = slugify(post_num, post_title) + ".html"
    clean_slug = clean_slugify(post_title) + ".html"
    
    numbered_path = @view.dir/:output/:permalink/numbered_slug
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    # Both files should exist
    assert File.exist?(numbered_path), "Numbered post file should exist: #{numbered_path}"
    assert File.exist?(clean_symlink_path), "Clean symlink should exist: #{clean_symlink_path}"
    
    # Clean copy should exist
    assert File.exist?(clean_symlink_path), "Clean copy should exist"
    
    # Copy should have same content as numbered file
    copy_content = File.read(clean_symlink_path)
    numbered_content = File.read(numbered_path)
    assert_equal numbered_content, copy_content, "Copy should have same content as numbered file"
  end

  def test_007_permalink_copy_has_correct_content
    # Create a test post with a specific title
    post_title = "Another Test Post"
    post_body = "This is another test post."
    
    # Create draft and finish it
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    
    # Generate the post
    @repo.generate_post(post_num)
    
    # Check symlink target
    clean_slug = clean_slugify(post_title) + ".html"
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    assert File.exist?(clean_symlink_path), "Should be a copy"
    
    # Get the actual content to verify it's a copy
    copy_content = File.read(clean_symlink_path)
    target_content = File.read(@view.dir/:output/:permalink/slugify(post_num, post_title) + ".html")
    
    # Expected content should match the numbered file
    assert_equal target_content, copy_content, "Copy should have same content as numbered file"
  end

  def test_008_permalink_copy_overwrites_existing
    # Create a test post
    post_title = "Duplicate Test Post"
    post_body = "This is a test post."
    
    # Create draft and finish it
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    
    # Generate the post (should create copy)
    @repo.generate_post(post_num)
    
    # Check that copy exists
    clean_slug = clean_slugify(post_title) + ".html"
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    assert File.exist?(clean_symlink_path), "Copy should exist"
    
    # Get the original content
    original_content = File.read(clean_symlink_path)
    
    # Now create another post with the same clean slug (different numbered slug)
    post_title2 = "Duplicate Test Post"  # Same title, different post
    post_body2 = "This is another test post with same title."
    
    draft_name2 = @repo.create_draft(title: post_title2, body: post_body2)
    post_num2 = @repo.finish_draft(draft_name2)
    
    # Generate the second post (should overwrite copy)
    @repo.generate_post(post_num2)
    
    # Check that copy still exists and has new content
    assert File.exist?(clean_symlink_path), "Copy should still exist"
    
    new_content = File.read(clean_symlink_path)
    expected_content = File.read(@view.dir/:output/:permalink/slugify(post_num2, post_title2) + ".html")
    
    assert_equal expected_content, new_content, "Copy should have new content"
    refute_equal original_content, new_content, "Copy should have been updated"
  end

  def test_009_permalink_copy_with_special_characters_in_title
    # Test with a title that has special characters
    post_title = "Post with Special Characters: & < > \" ' !"
    post_body = "This post has special characters in the title."
    
    # Create draft and finish it
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    
    # Generate the post
    @repo.generate_post(post_num)
    
    # Check that copy exists with cleaned slug
    clean_slug = clean_slugify(post_title) + ".html"
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    assert File.exist?(clean_symlink_path), "Copy should exist for cleaned title"
    
    # Check that the copy has the same content as the numbered file
    copy_content = File.read(clean_symlink_path)
    expected_content = File.read(@view.dir/:output/:permalink/slugify(post_num, post_title) + ".html")
    assert_equal expected_content, copy_content, "Copy should have same content as numbered file"
  end

  def test_010_permalink_copy_deployment_ready
    # Test that permalink copies are created in the correct location for deployment
    post_title = "Deployment Test Post"
    post_body = "This post tests deployment readiness."
    
    # Create draft and finish it
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    
    # Generate the post
    @repo.generate_post(post_num)
    
    # Check that copy is in the correct deployment location
    clean_slug = clean_slugify(post_title) + ".html"
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    # Verify the path structure
    assert_equal @view.dir/:output/:permalink/clean_slug, clean_symlink_path
    assert File.exist?(clean_symlink_path), "Copy should exist in deployment location"
    
    # Verify it's a copy (not a symlink)
    assert !File.symlink?(clean_symlink_path), "Should not be a symlink"
    
    # Verify the copy has content
    copy_content = File.read(clean_symlink_path)
    assert copy_content.length > 0, "Copy should have content"
  end
end
