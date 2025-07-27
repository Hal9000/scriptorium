# test/unit/post.rb

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require_relative '../../lib/scriptorium/post'

class TestScriptoriumPost < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers

  def setup
    @test_dir = "test/post_test_files"
    make_dir(@test_dir)
    @repo = Scriptorium::Repo.create(true)
    @post = Scriptorium::Post.new(@repo, 1)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    Scriptorium::Repo.destroy if Scriptorium::Repo.testing
  end

  # Constructor validation tests
  def test_initialize_with_valid_params
    post = Scriptorium::Post.new(@repo, 123)
    assert_equal @repo, post.repo
    assert_equal "0123", post.num
  end

  def test_initialize_with_nil_repo
    assert_raises(RuntimeError) do
      Scriptorium::Post.new(nil, 1)
    end
  end

  def test_initialize_with_nil_num
    assert_raises(RuntimeError) do
      Scriptorium::Post.new(@repo, nil)
    end
  end

  def test_initialize_with_empty_num
    assert_raises(RuntimeError) do
      Scriptorium::Post.new(@repo, "")
    end
  end

  def test_initialize_with_whitespace_num
    assert_raises(RuntimeError) do
      Scriptorium::Post.new(@repo, "   ")
    end
  end

  def test_initialize_with_invalid_num_format
    assert_raises(RuntimeError) do
      Scriptorium::Post.new(@repo, "abc")
    end
  end

  def test_initialize_with_negative_num
    assert_raises(RuntimeError) do
      Scriptorium::Post.new(@repo, -1)
    end
  end

  # Basic property tests
  def test_dir
    expected_dir = @repo.root/:posts/"0001"
    assert_equal expected_dir, @post.dir
  end

  def test_meta_file
    expected_file = @repo.root/:posts/"0001"/"meta.txt"
    assert_equal expected_file, @post.meta_file
  end

  def test_id
    assert_equal "0001", @post.id
  end

  def test_num_with_leading_zeros
    post = Scriptorium::Post.new(@repo, 1)
    assert_equal "0001", post.num
  end

  def test_num_without_leading_zeros
    post = Scriptorium::Post.new(@repo, 123)
    assert_equal "0123", post.num
  end

  def test_num_with_existing_zeros
    post = Scriptorium::Post.new(@repo, 0001)
    assert_equal "0001", post.num
  end

  def test_num_exclamation
    post = Scriptorium::Post.new(@repo, 1)
    assert_equal 1, post.num!
  end

  def test_num_exclamation_with_leading_zeros
    post = Scriptorium::Post.new(@repo, "00123")
    assert_equal 123, post.num!
  end

  # Metadata tests
  def test_meta_without_file
    # When meta file doesn't exist, should return empty hash
    assert_equal({}, @post.meta)
  end

  def test_meta_with_file
    # Create a meta file
    meta_content = "post.title       Test Post\npost.blurb       Test blurb\npost.slug        test-post\npost.pubdate     2023-01-01 12:00:00"
    write_file(@post.meta_file, meta_content)
    
    meta = @post.meta
    assert_equal "Test Post", meta["post.title"]
    assert_equal "Test blurb", meta["post.blurb"]
    assert_equal "test-post", meta["post.slug"]
    assert_equal "2023-01-01 12:00:00", meta["post.pubdate"]
  end

  # Individual metadata field tests
  def test_title
    write_file(@post.meta_file, "post.title       Test Post")
    assert_equal "Test Post", @post.title
  end

  def test_blurb
    write_file(@post.meta_file, "post.blurb       Test blurb")
    assert_equal "Test blurb", @post.blurb
  end

  def test_slug
    write_file(@post.meta_file, "post.slug        test-post")
    assert_equal "test-post", @post.slug
  end

  def test_pubdate
    write_file(@post.meta_file, "post.pubdate      2023-01-01 12:00:00")
    assert_equal "2023-01-01 12:00:00", @post.pubdate
  end

  def test_views
    write_file(@post.meta_file, "post.views       view1 view2")
    assert_equal "view1 view2", @post.views
  end

  def test_tags
    write_file(@post.meta_file, "post.tags        tag1,tag2")
    assert_equal "tag1,tag2", @post.tags
  end

  # set_pubdate tests
  def test_set_pubdate_with_valid_date
    Scriptorium::Repo.testing = true
    @post.set_pubdate("2023-01-15")
    
    meta = @post.meta
    assert_equal "2023-01-15 00:00:00", meta["post.pubdate"]
    assert_equal "January", meta["post.pubdate.month"]
    assert_equal "15", meta["post.pubdate.day"]
    assert_equal "2023", meta["post.pubdate.year"]
  end

  def test_set_pubdate_with_nil_date
    Scriptorium::Repo.testing = true
    assert_raises(RuntimeError) do
      @post.set_pubdate(nil)
    end
  end

  def test_set_pubdate_with_empty_date
    Scriptorium::Repo.testing = true
    assert_raises(RuntimeError) do
      @post.set_pubdate("")
    end
  end

  def test_set_pubdate_with_invalid_format
    Scriptorium::Repo.testing = true
    assert_raises(RuntimeError) do
      @post.set_pubdate("2023/01/15")
    end
  end

  def test_set_pubdate_with_invalid_date
    Scriptorium::Repo.testing = true
    assert_raises(ArgumentError) do
      @post.set_pubdate("2023-13-45")
    end
  end

  def test_set_pubdate_without_testing_mode
    Scriptorium::Repo.testing = false
    assert_raises(TestModeOnly) do
      @post.set_pubdate("2023-01-15")
    end
    Scriptorium::Repo.testing = true
  end

  # set_pubdate_with_seconds tests
  def test_set_pubdate_with_seconds
    Scriptorium::Repo.testing = true
    @post.set_pubdate_with_seconds("2023-01-15", 30)
    
    meta = @post.meta
    assert_equal "2023-01-15 12:00:30", meta["post.pubdate"]
  end

  def test_pubdate_month_day_year
    write_file(@post.meta_file, "post.pubdate.month January\npost.pubdate.day 15\npost.pubdate.year 2023")
    assert_equal ["January", "15", "2023"], @post.pubdate_month_day_year
  end

  # attrs tests
  def test_attrs_single
    write_file(@post.meta_file, "post.title       Test Post")
    assert_equal ["Test Post"], @post.attrs(:title)
  end

  def test_attrs_multiple
    write_file(@post.meta_file, "post.title       Test Post\npost.blurb       Test blurb")
    assert_equal ["Test Post", "Test blurb"], @post.attrs(:title, :blurb)
  end

  # vars tests
  def test_vars
    write_file(@post.meta_file, "post.title       Test Post\npost.blurb       Test blurb")
    vars = @post.vars
    assert_equal "Test Post", vars[:"post.title"]
    assert_equal "Test blurb", vars[:"post.blurb"]
  end

  def test_vars_default_behavior
    vars = @post.vars
    assert_equal "", vars[:nonexistent_key]
  end

  # Class method tests
  def test_read
    # Create a meta file
    meta_content = "post.title       Test Post\npost.blurb       Test blurb"
    write_file(@post.meta_file, meta_content)
    
    post = Scriptorium::Post.read(@repo, 1)
    assert_equal "Test Post", post.title
    assert_equal "Test blurb", post.blurb
  end
end
