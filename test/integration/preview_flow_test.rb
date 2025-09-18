require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require 'fileutils'
require_relative '../support/preview_utils'

class PreviewFlowTest < Minitest::Test
  include TestHelpers

  def setup
    @repo_name = "test/scriptorium-TEST"
    @view_name = "preview_test_view"

    @api = Scriptorium::API.new
    # Ensure a clean slate before creating the repo
    begin
      FileUtils.rm_rf(@repo_name)
      backup_dir = File.join(File.dirname(@repo_name), 'backup-scriptorium-TEST')
      FileUtils.rm_rf(backup_dir)
    rescue => e
      puts "[Integration] Warning: cleanup failed: #{e.message}"
    end
    @api.create_repo(@repo_name)
    @api.open_repo(@repo_name)
    @api.create_view(@view_name, "Preview Test View")

    # Add a couple of posts
    @api.create_post("Final Test Post", "ADD BLURB HERE")
    @api.create_post("Another New Post", "ADD BLURB HERE")

    # Configure date format with break and small pagination (via shared helper)
    PreviewUtils.write_post_index_config(@repo_name, @view_name, {
      "posts.per.page" => "5",
      "entry.date.format" => "month dd break yyyy"
    })

    # Upload a global image and reference it from the first post via .image
    test_asset = Tempfile.new(['previewflow', '.jpg'])
    begin
      test_asset.write("x")
      test_asset.close
      @api.upload_asset(test_asset.path, filename: "previewflow.jpg")
    ensure
      test_asset.unlink rescue nil
    end

    # Insert image reference into post 0001
    src1 = "#{@repo_name}/posts/0001/source.lt3"
    File.write(src1, ".image previewflow.jpg\n\nHello")

    # Generate view
    @api.generate_view(@view_name)
  end

  def teardown
    FileUtils.rm_rf(@repo_name)
  end

  def test_post_index_has_table_and_formatted_dates
    post_index = "#{@repo_name}/views/#{@view_name}/output/post_index.html"
    assert File.exist?(post_index), "Expected post_index.html to exist"
    content = File.read(post_index)
    assert_includes content, "<table", "post_index should be wrapped in a table"
    assert_includes content, "<br>", "post_index should include a line break in the date"
  end

  def test_paginated_page_table_wrapper
    page1 = "#{@repo_name}/views/#{@view_name}/output/page1.html"
    assert File.exist?(page1), "Expected page1.html to exist"
    content = File.read(page1)
    assert_includes content, "<table", "page1 should be wrapped in a table"
  end

  def test_index_inlines_table_content
    index = "#{@repo_name}/views/#{@view_name}/output/index.html"
    assert File.exist?(index), "Expected index.html to exist"
    content = File.read(index)
    # The main section should include a table from post_index inclusion
    assert_includes content, "<table", "index should inline post_index table"
  end

  def test_post_page_references_assets_relatively
    # Verify that the first post page references ../assets/ for the image
    # Find slug for post 0001 from its meta
    meta = File.read("#{@repo_name}/posts/0001/meta.txt")
    slug = meta.lines.grep(/^post.slug\s+/).first.split.last
    post_html = "#{@repo_name}/views/#{@view_name}/output/posts/#{slug}"
    assert File.exist?(post_html), "Expected post HTML to exist"
    html = File.read(post_html)
    assert_includes html, "<img src=../assets/previewflow.jpg", "Post image should use ../assets/ path"
  end
end


