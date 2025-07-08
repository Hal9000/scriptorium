# test/post/unit.rb

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class PostTest < Minitest::Test
  include Scriptorium::Helpers
  include Scriptorium::Exceptions
  include TestHelpers

  def setup
    system("rm -rf scriptorium-TEST")
    @repo = create_test_repo
    draft_file = @repo.create_draft(
      title: "Test Post",
      views: ["sample"],
      tags: "tag1 tag2",
      body: "This is the test body"
    )
    post_num = @repo.finish_draft(draft_file)
    @repo.generate_post(post_num)
    @post = Scriptorium::Post.new(@repo, post_num)
  end
    
  def teardown
    system("rm -rf scriptorium-TEST")
  end

  def test_post_number_is_padded
    assert_equal 4, @post.num.length
    assert_match /^\d{4}$/, @post.num
  end

  def test_post_meta_file_exists
    assert File.exist?(@post.meta_file), "meta.txt should exist"
  end

  def test_post_title
    title = @post.title
    assert title.is_a?(String), "title should be a String"
    assert !title.empty?, "title should not be empty"
  end

  def test_post_pubdate
    pub = @post.pubdate
    assert pub =~ /^\d{4}-\d{2}-\d{2}$/, "pubdate should be YYYY-MM-DD"
  end

  def test_post_slug
    slug = @post.slug
    assert slug.is_a?(String), "slug should be a String"
    assert_match %r{^\d{4}-test-post.html}, slug
  end

  def test_repo_returns_post_object
    post = @repo.post(1)
    assert_instance_of Scriptorium::Post, post
    assert_equal "0001", post.num
  end
  
end
