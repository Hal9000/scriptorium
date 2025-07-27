# test/post/unit.rb

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class PostTest < Minitest::Test
  include Scriptorium::Helpers
  include Scriptorium::Exceptions
  include TestHelpers

  def setup
    system("rm -rf test/scriptorium-TEST")
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
    system("rm -rf test/scriptorium-TEST")
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
    assert pub =~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, "pubdate should be YYYY-MM-DD HH:MM:SS"
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

  def test_post_handles_missing_meta_file
    File.delete(@post.meta_file) if File.exist?(@post.meta_file)
    assert_nil @post.title
    assert_nil @post.pubdate
    assert_nil @post.slug
  end
  
  def test_post_returns_nil_for_missing_fields
    File.write(@post.meta_file, "post.id 1\n")  # no title, pubdate, slug
    assert_nil @post.title
    assert_nil @post.pubdate
    assert_nil @post.slug
  end
  
  def test_post_handles_extra_fields
    File.open(@post.meta_file, "a") do |f|
      f.puts "extra.stuff something"
    end
    assert @post.title.is_a?(String)
  end
  
  def test_repo_post_reads_metadata
    post = @repo.post(1)
    assert_equal "Test Post", post.title
    today = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    # NOTE: In theory, this can fail if the post is made in one second
    # and the Time.now in the next second. So far, I haven't seen this.
    assert_equal today, post.pubdate
  end
  
  def test_repo_post_invalid_id_returns_nil
    assert_nil @repo.post(9999), "Expected nil for nonexistent post ID"
  end
    
  
end
