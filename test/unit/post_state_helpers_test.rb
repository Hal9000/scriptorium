#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestPostStateHelpers < Minitest::Test
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @test_dir = "test/post_state_helpers_test"
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    make_dir(@test_dir)
    
    @unpublished_file = @test_dir/"unpublished.txt"
    @undeployed_file = @test_dir/"undeployed.txt"
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
  end

  def test_001_read_post_state_file_empty
    # Test reading empty file
    result = read_post_state_file(@unpublished_file)
    assert_equal [], result
  end

  def test_002_read_post_state_file_with_content
    # Test reading file with post IDs
    write_file(@unpublished_file, "1\n3\n7\n")
    result = read_post_state_file(@unpublished_file)
    assert_equal [1, 3, 7], result
  end

  def test_003_read_post_state_file_with_whitespace
    # Test reading file with whitespace
    write_file(@unpublished_file, "  1  \n  3  \n  7  \n")
    result = read_post_state_file(@unpublished_file)
    assert_equal [1, 3, 7], result
  end

  def test_004_read_post_state_file_with_empty_lines
    # Test reading file with empty lines
    write_file(@unpublished_file, "1\n\n3\n\n7\n")
    result = read_post_state_file(@unpublished_file)
    assert_equal [1, 3, 7], result
  end

  def test_005_write_post_state_file_empty
    # Test writing empty array
    write_post_state_file(@unpublished_file, [])
    content = read_file(@unpublished_file)
    assert_equal "\n", content  # Empty file with newline is correct
  end

  def test_006_write_post_state_file_with_content
    # Test writing array with post IDs
    write_post_state_file(@unpublished_file, [7, 1, 3])
    content = read_file(@unpublished_file)
    assert_equal "1\n3\n7\n", content  # Should be sorted
  end

  def test_007_add_post_to_state_file_new
    # Test adding new post ID
    write_file(@unpublished_file, "1\n3\n")
    add_post_to_state_file(@unpublished_file, 5)
    result = read_post_state_file(@unpublished_file)
    assert_equal [1, 3, 5], result
  end

  def test_008_add_post_to_state_file_existing
    # Test adding existing post ID (should not duplicate)
    write_file(@unpublished_file, "1\n3\n")
    add_post_to_state_file(@unpublished_file, 3)
    result = read_post_state_file(@unpublished_file)
    assert_equal [1, 3], result
  end

  def test_009_remove_post_from_state_file
    # Test removing post ID
    write_file(@unpublished_file, "1\n3\n5\n")
    remove_post_from_state_file(@unpublished_file, 3)
    result = read_post_state_file(@unpublished_file)
    assert_equal [1, 5], result
  end

  def test_010_remove_post_from_state_file_nonexistent
    # Test removing non-existent post ID
    write_file(@unpublished_file, "1\n3\n")
    remove_post_from_state_file(@unpublished_file, 5)
    result = read_post_state_file(@unpublished_file)
    assert_equal [1, 3], result
  end

  def test_011_post_in_state_file_true
    # Test checking if post exists in file
    write_file(@unpublished_file, "1\n3\n5\n")
    assert post_in_state_file?(@unpublished_file, 3)
  end

  def test_012_post_in_state_file_false
    # Test checking if post doesn't exist in file
    write_file(@unpublished_file, "1\n3\n5\n")
    refute post_in_state_file?(@unpublished_file, 7)
  end

  def test_013_post_in_state_file_empty
    # Test checking empty file
    refute post_in_state_file?(@unpublished_file, 1)
  end

  def test_014_integration_workflow
    # Test complete workflow: add, check, remove
    # Start with empty file
    assert_equal [], read_post_state_file(@unpublished_file)
    
    # Add posts
    add_post_to_state_file(@unpublished_file, 1)
    add_post_to_state_file(@unpublished_file, 3)
    add_post_to_state_file(@unpublished_file, 5)
    
    # Verify they're there
    assert_equal [1, 3, 5], read_post_state_file(@unpublished_file)
    assert post_in_state_file?(@unpublished_file, 1)
    assert post_in_state_file?(@unpublished_file, 3)
    assert post_in_state_file?(@unpublished_file, 5)
    
    # Remove one
    remove_post_from_state_file(@unpublished_file, 3)
    assert_equal [1, 5], read_post_state_file(@unpublished_file)
    assert post_in_state_file?(@unpublished_file, 1)
    refute post_in_state_file?(@unpublished_file, 3)
    assert post_in_state_file?(@unpublished_file, 5)
  end
end
