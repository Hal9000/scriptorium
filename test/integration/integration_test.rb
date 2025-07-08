# test/integration/integration_test.rb

require "minitest/autorun"
require "fileutils"
require_relative '../../lib/scriptorium'
require_relative "../test_helpers"

class IntegrationTest < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers
  
  def setup
    @tmpdir = Dir.mktmpdir
    @old_dir = Dir.pwd
    Dir.chdir(@tmpdir)
    @repo = create_test_repo
    @sample_view = @repo.lookup_view("sample")
  end

  def teardown
    Dir.chdir(@old_dir)
    FileUtils.remove_entry(@tmpdir)
  end

  def test_sample_view_generates_header_html
    header_txt = @sample_view.dir/:config/"header.txt"
    File.write(header_txt, "title")

    @sample_view.build_header

    output = @sample_view.dir/:output/:panes/"header.html"
    assert File.exist?(output), "Expected header.html to exist"
    content = File.read(output)
    assert_includes content, "<h1>", "Expected header content to include <h1>"
  end

  def create_3_views  # For test_posts_generated_and_indexed_across_multiple_views
    @repo.create_view("blog1", "Blog 1", "nothing (1)")
    @repo.create_view("blog2", "Blog 2", "nothing (2)")
    @repo.create_view("blog3", "Blog 3", "nothing (3)")
  end

  def create_13_posts  # For test_posts_generated_and_indexed_across_multiple_views
    try_post_with_views(@repo, "blog1")
    try_post_with_views(@repo, "blog2")
    try_post_with_views(@repo, "blog3")
    try_post_with_views(@repo, %w[blog1 blog2])
    try_post_with_views(@repo, %w[blog2 blog3])
    try_post_with_views(@repo, %w[blog1 blog3])
    try_post_with_views(@repo, %w[blog1 blog2 blog3])
    try_post_with_views(@repo, "blog1")
    try_post_with_views(@repo, "blog1")
    try_post_with_views(@repo, "blog1")
    try_post_with_views(@repo, "blog2")
    try_post_with_views(@repo, "blog2")
    try_post_with_views(@repo, "blog3")
    # blog1   1 4 6 7 8 9 10
    # blog2   2 4 5 11 12
    # blog3   3 5 6 7 13
  end

  def alter_pubdates  # For test_posts_generated_and_indexed_across_multiple_views
    @repo.alter_pubdate(1,  "2025-07-01")
    @repo.alter_pubdate(2,  "2025-07-02")
    @repo.alter_pubdate(3,  "2025-07-03")
    @repo.alter_pubdate(4,  "2025-07-04")
    @repo.alter_pubdate(5,  "2025-07-05")
    @repo.alter_pubdate(6,  "2025-07-06")
    @repo.alter_pubdate(7,  "2025-07-07")
    @repo.alter_pubdate(8,  "2025-07-08")
    @repo.alter_pubdate(9,  "2025-07-09")
    @repo.alter_pubdate(10, "2025-07-10")
    @repo.alter_pubdate(11, "2025-07-11")
    @repo.alter_pubdate(12, "2025-07-12")
    @repo.alter_pubdate(13, "2025-07-13")
  end

  def try_blog1_index  # For test_posts_generated_and_indexed_across_multiple_views
    @repo.generate_post_index("blog1")
    %w[header main right footer].each do |section|
      file = @repo.root/:views/"blog1"/:output/:panes/"#{section}.html"
      assert File.exist?(file), "Expected section file #{file} to exist"
    end
    @repo.tree("/tmp/blog1.txt")
    post_index = @repo.root/:views/"blog1"/:output/"post_index.html"
    assert File.exist?(post_index), "Expected blog1 post_index.html to be generated"
    content = File.read(post_index)
    assert_includes content, "2025-07-01"
    assert_includes content, "2025-07-04"
    assert_includes content, "2025-07-06"
    assert_includes content, "2025-07-07"
    assert_includes content, "2025-07-08"
    assert_includes content, "2025-07-09"
    assert_includes content, "2025-07-10"
    refute_includes content, "2025-07-02"
    refute_includes content, "2025-07-03"
    refute_includes content, "2025-07-05"
    refute_includes content, "2025-07-11"
    refute_includes content, "2025-07-12"
    refute_includes content, "2025-07-13"
  end

=begin
  blog1   1 4 6 7 8 9 10
  blog2   2 4 5 11 12
  blog3   3 5 6 7 13
  
  1,  "2025-07-01"
  2,  "2025-07-02"
  3,  "2025-07-03"
  4,  "2025-07-04"
  5,  "2025-07-05"
  6,  "2025-07-06"
  7,  "2025-07-07"
  8,  "2025-07-08"
  9,  "2025-07-09"
  10, "2025-07-10"
  11, "2025-07-11"
  12, "2025-07-12"
  13, "2025-07-13"

=end

  def test_posts_generated_and_indexed_across_multiple_views
    srand(42)  # for random posts

    create_3_views
    n0 = @repo.all_posts.size

    create_13_posts
    n1 = @repo.all_posts.size
    assert n1 == n0 + 13, "Expected 13 posts, found #{n1 - n0}"

    alter_pubdates

    num_posts_per_view(@repo, "blog1", 7)
    num_posts_per_view(@repo, "blog2", 6)
    num_posts_per_view(@repo, "blog3", 5)

    try_blog1_index
  end
end
