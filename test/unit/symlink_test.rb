# Test file for symlink functionality
# Tests the clean URL symlink generation for posts

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require 'fileutils'

class TestSymlinkFunctionality < Minitest::Test
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
  # Symlink generation tests
  # ========================================

  def test_006_symlink_creation_for_post
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
    
    # Clean symlink should be a symlink
    assert File.symlink?(clean_symlink_path), "Clean symlink should be a symlink"
    
    # Symlink should point to the numbered file
    symlink_target = File.readlink(clean_symlink_path)
    expected_target = numbered_slug
    assert_equal expected_target, symlink_target, "Symlink should point to numbered file"
  end

  def test_007_symlink_points_to_correct_file
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
    
    assert File.symlink?(clean_symlink_path), "Should be a symlink"
    
    # Get the actual target
    symlink_target = File.readlink(clean_symlink_path)
    
    # Expected target should be the numbered slug
    expected_slug = slugify(post_num, post_title) + ".html"
    assert_equal expected_slug, symlink_target, "Symlink should point to correct numbered file"
  end

  def test_008_symlink_overwrites_existing
    # Create a test post
    post_title = "Duplicate Test Post"
    post_body = "This is a test post."
    
    # Create draft and finish it
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    
    # Generate the post (should create symlink)
    @repo.generate_post(post_num)
    
    # Check that symlink exists
    clean_slug = clean_slugify(post_title) + ".html"
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    assert File.symlink?(clean_symlink_path), "Symlink should exist"
    
    # Get the target
    original_target = File.readlink(clean_symlink_path)
    
    # Now create another post with the same clean slug (different numbered slug)
    post_title2 = "Duplicate Test Post"  # Same title, different post
    post_body2 = "This is another test post with same title."
    
    draft_name2 = @repo.create_draft(title: post_title2, body: post_body2)
    post_num2 = @repo.finish_draft(draft_name2)
    
    # Generate the second post (should overwrite symlink)
    @repo.generate_post(post_num2)
    
    # Check that symlink still exists and points to the new target
    assert File.symlink?(clean_symlink_path), "Symlink should still exist"
    
    new_target = File.readlink(clean_symlink_path)
    expected_target = slugify(post_num2, post_title2) + ".html"
    
    assert_equal expected_target, new_target, "Symlink should point to new target"
    refute_equal original_target, new_target, "Symlink should have been updated"
  end

  def test_009_symlink_with_special_characters_in_title
    # Test with a title that has special characters
    post_title = "Post with Special Characters: & < > \" ' !"
    post_body = "This post has special characters in the title."
    
    # Create draft and finish it
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    
    # Generate the post
    @repo.generate_post(post_num)
    
    # Check that symlink exists with cleaned slug
    clean_slug = clean_slugify(post_title) + ".html"
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    assert File.exist?(clean_symlink_path), "Symlink should exist for cleaned title"
    assert File.symlink?(clean_symlink_path), "Should be a symlink"
    
    # Check that the symlink points to the correct numbered file
    symlink_target = File.readlink(clean_symlink_path)
    expected_target = slugify(post_num, post_title) + ".html"
    assert_equal expected_target, symlink_target, "Symlink should point to correct numbered file"
  end

  def test_010_symlink_deployment_ready
    # Test that symlinks are created in the correct location for deployment
    post_title = "Deployment Test Post"
    post_body = "This post tests deployment readiness."
    
    # Create draft and finish it
    draft_name = @repo.create_draft(title: post_title, body: post_body)
    post_num = @repo.finish_draft(draft_name)
    
    # Generate the post
    @repo.generate_post(post_num)
    
    # Check that symlink is in the correct deployment location
    clean_slug = clean_slugify(post_title) + ".html"
    clean_symlink_path = @view.dir/:output/:permalink/clean_slug
    
    # Verify the path structure
    assert_equal @view.dir/:output/:permalink/clean_slug, clean_symlink_path
    assert File.exist?(clean_symlink_path), "Symlink should exist in deployment location"
    
    # Verify it's a symlink
    assert File.symlink?(clean_symlink_path), "Should be a symlink"
    
    # Verify the target exists and is accessible
    symlink_target = File.readlink(clean_symlink_path)
    target_path = @view.dir/:output/:permalink/symlink_target
    assert File.exist?(target_path), "Symlink target should exist"
  end
end
