require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require_relative '../web_test_helper'
require_relative '../support/preview_utils'
require 'fileutils'
require 'shellwords'

# Manual-inspection oriented preview tests
# - Does not enforce strict order
# - Prints absolute paths and preview URLs to inspect
# - Set MANUAL_KEEP=1 to skip teardown so artifacts remain

class PreviewManualTest < Minitest::Test
  include TestHelpers
  include WebTestHelper

  def interactive_open(label:, paths: [], urls: [])
    PreviewUtils.interactive_open(label: label, paths: paths, urls: urls)
  end

  def setup
    # Use the web app's test repo location so preview routes see generated files
    @repo_name = "ui/web/scriptorium-TEST"
    @view_name = "manual_preview_view"

    @api = Scriptorium::API.new
    # Ensure a clean slate before creating the repo
    begin
      FileUtils.rm_rf(@repo_name)
      backup_dir = File.join(File.dirname(@repo_name), 'backup-scriptorium-TEST')
      FileUtils.rm_rf(backup_dir)
    rescue => e
      puts "[Manual] Warning: cleanup failed: #{e.message}"
    end
    @api.create_repo(@repo_name)
    @api.open_repo(@repo_name)
    @api.create_view(@view_name, "Manual Preview View")

    # Ensure required UI/social icons are available in the view
    begin
      @api.copy_asset('icons/ui/back.png',    from: 'gem', to: 'view', view: @view_name)
    rescue => e
      puts "[Manual] Warning: could not copy icons/ui/back.png from gem: #{e.message}"
    end
    begin
      @api.copy_asset('icons/social/reddit.png', from: 'gem', to: 'view', view: @view_name)
    rescue => e
      puts "[Manual] Warning: could not copy icons/social/reddit.png from gem: #{e.message}"
    end

    # Seed some posts
    @api.create_post("Manual Post A", "Blurb A")
    @api.create_post("Manual Post B", "Blurb B")

    # Configure post index (line break in date, enable pagination)
    PreviewUtils.write_post_index_config(@repo_name, @view_name)

    # Add an image and reference it in post 0001
    # Use a real image so the browser can render it
    sample_image = File.expand_path("test/assets/testbanner.jpg")
    @api.upload_asset(sample_image, filename: 'manual.jpg')
    PreviewUtils.reference_image_in_post(@repo_name, '0001', 'manual.jpg')

    @api.generate_view(@view_name)
  end

  def teardown
    return if ENV['MANUAL_KEEP'] == '1'
    FileUtils.rm_rf(@repo_name)
  end

  # 100-series: Index preview
  def test_100_preview_index_artifacts
    base = File.expand_path(File.join(@repo_name, 'views', @view_name))
    index_file = File.join(base, 'output', 'index.html')
    post_index = File.join(base, 'output', 'post_index.html')
    page1 = File.join(base, 'output', 'page1.html')

    assert File.exist?(index_file), 'index.html missing'
    assert File.exist?(post_index), 'post_index.html missing'
    assert File.exist?(page1), 'page1.html missing'

    puts "\n[Manual] Inspect artifacts (server-first). Files shown for reference:"
    puts "  URL : http://localhost:4567/preview/#{@view_name}/index.html"
    puts "  File: #{index_file}"
    puts "  File: #{post_index}"
    puts "  File: #{page1}"
    # Restart server to ensure preview routes work
    stop_web_server
    start_web_server
    # Open server URL only to avoid file:// CORS issues
    interactive_open(label: 'index (server)', paths: [], urls: ["http://localhost:4567/preview/#{@view_name}/index.html"])
  end

  # 200-series: One post page and asset
  def test_200_post_and_asset_reference
    base = File.expand_path(File.join(@repo_name, 'views', @view_name))
    meta = File.read(File.join(@repo_name, 'posts', '0001', 'meta.txt'))
    slug = meta.lines.grep(/^post.slug\s+/).first.split.last
    post_html = File.join(base, 'output', 'posts', slug)
    asset_in_output = File.join(base, 'output', 'assets', 'manual.jpg')

    assert File.exist?(post_html), 'Post HTML missing'
    html = File.read(post_html)
    assert_includes html, "<img src=../assets/manual.jpg", 'Expected relative asset path in post'

    # Global asset copied to output for serving
    assert File.exist?(asset_in_output), 'Expected asset copied to output/assets'

    # Clarify exact image path and how the browser resolves it
    img_src = html[/<img[^>]+src=([^\s>]+)/, 1]
    resolved_img_path = File.expand_path(img_src, File.dirname(post_html)) if img_src

    puts "\n[Manual] Inspect post and asset:"
    puts "  File: #{post_html}"
    puts "  File: #{asset_in_output}"
    puts "  IMG  src (from HTML): #{img_src}"
    puts "  IMG  resolves to    : #{resolved_img_path}"
    puts "  URL : /preview/#{@view_name}/posts/#{slug}"
    puts "  URL : /preview/#{@view_name}/assets/manual.jpg"
    # Restart server to ensure preview routes work
    stop_web_server
    start_web_server
    # Open server URLs only; list local paths for reference
    interactive_open(label: 'post (server)', paths: [], urls: ["http://localhost:4567/preview/#{@view_name}/posts/#{slug}"])
    interactive_open(label: 'asset (server)', paths: [], urls: ["http://localhost:4567/preview/#{@view_name}/assets/manual.jpg"])
  end
end
