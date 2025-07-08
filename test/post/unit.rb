# test/unit/test_post.rb

require "minitest/autorun"
require "fileutils"
require_relative "../../lib/scriptorium"
require_relative "../test_helpers"

class PostTest < Minitest::Test
  include TestHelpers
  include Scriptorium::Helpers

  def setup
    @repo = create_test_repo
    @postnum = 42
    @post = Scriptorium::Post.new(@repo, @postnum)

    # Create fake meta.txt
    post_dir = @repo.root/:posts/"0042"
    FileUtils.mkdir_p(post_dir)
    File.write(post_dir/"meta.txt", <<~META)
      title    The Meaning of Life
      slug     the-meaning-of-life
      pubdate  2025-07-08
    META
  end

  def teardown
    FileUtils.remove_entry(@repo.root)
  end

  def test_post_number_is_padded
    assert_equal "0042", @post.num
  end

  def test_post_title
    assert_equal "The Meaning of Life", @post.title
  end

  def test_post_slug
    assert_equal "the-meaning-of-life", @post.slug
  end

  def test_post_pubdate
    assert_equal "2025-07-08", @post.pubdate
  end

  def test_post_meta_file_exists
    assert File.exist?(@post.meta_file)
  end
end
