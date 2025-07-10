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

  def test_integration_index_contains_titles_and_dates
    create_3_views
    create_13_posts
    alter_pubdates
    @repo.generate_post_index("blog1")
    @repo.generate_front_page("blog1")
    posts_content = File.read(@repo.root/:views/"blog1"/:output/"post_index.html")
    posts = @repo.all_posts("blog1")
    posts.each do |post|
      assert_includes posts_content, post.title
      assert_includes posts_content, post.pubdate
    end
  end

  def try_blog1_index_with_post_checks   # Helper
    @repo.generate_front_page("blog1")
  
    # 1. Verify index.html exists and has expected heading
    index = @repo.root/:views/"blog1"/:output/"index.html"
    assert File.exist?(index), "Expected index.html to exist"
    html = File.read(index)
    assert_includes html, "<title>Blog 1</title>", "Expected <title>Blog 1</title> in index"
  
    # 2. Verify container files exist and are non-empty
    %w[header main right footer].each do |section|
      path = @repo.root/:views/"blog1"/:output/:panes/"#{section}.html"
      assert File.exist?(path), "Expected #{section}.html to exist"
      refute_empty File.read(path).strip, "Expected #{section}.html not to be blank"
    end
  
    # 3. Check that post_index.html includes correct post metadata
    @repo.generate_post_index("blog1")
    post_index = @repo.root/:views/"blog1"/:output/"post_index.html"
    assert File.exist?(post_index), "Expected post_index.html to be generated"
    content = File.read(post_index)
  
    @repo.all_posts("blog1").each do |post|
      next unless post.pubdate && post.title
      assert_includes content, post.pubdate, "Expected pubdate #{post.pubdate} to appear"
      assert_includes content, post.title,   "Expected title #{post.title} to appear"
    end
  end
  
  def test_posts_generated_and_indexed_across_multiple_views
    srand(42)
    create_3_views
    create_13_posts
    alter_pubdates
  
    num_posts_per_view(@repo, "blog1", 7)
    num_posts_per_view(@repo, "blog2", 6)
    num_posts_per_view(@repo, "blog3", 5)
  
    try_blog1_index_with_post_checks
  end
  
  def test_generate_front_page_outputs_index_html
    # Setup test view and layout
    view = @repo.create_view("landing", "Landing Page", "Unit test front page")
  
    layout_txt = <<~LAYOUT
      header
      footer
      main
    LAYOUT
  
    layout_path = view.dir/:config/"layout.txt"
    File.write(layout_path, layout_txt)
    
    # Call the method under test
    @repo.generate_front_page("landing")
  
    # Assertions
    index_file = view.dir/:output/"index.html"
    assert File.exist?(index_file), "Expected index.html to be generated"
  
    content = File.read(index_file)
    targets = ["<!-- Section: header (output) -->", 
               "<!-- Section: main (output) -->", 
               "<!-- Section: footer (output) -->"]
    assert_present(content, *targets)
    assert_ordered(content, *targets)
  end
  
  def test_all_containers_are_present
    # layout_file = @sample_view.dir/:config/"layout.txt"
    layout = @sample_view.read_layout  
    layout.each do |container|
      output_file = @sample_view.dir/:output/:panes/"#{container}.html"
      assert File.exist?(output_file), "Expected output file #{output_file} for container #{container}"
    end
  end
  
  def test_missing_container_in_layout
    layout_file = @sample_view.dir/:config/"layout.txt"
    layout = read_commented_file(layout_file)
  
    layout.each do |container|
      output_file = @sample_view.dir/:output/:panes/"#{container}.html"
      if File.exist?(output_file)
        content = File.read(output_file)
        refute content.include?("<!-- Missing #{container}.html -->"), "Missing #{container}.html should not appear"
      end
    end
  end
  
  def test_front_page_handles_missing_containers
    @repo.generate_front_page("sample")
    index_file = @repo.root/:views/"sample"/:output/"index.html"
    assert File.exist?(index_file), "Expected index.html to be generated"
  
    layout = @sample_view.read_layout
    layout.each do |container|
      content = File.read(index_file)
      if !File.exist?(@repo.root/:views/"sample"/:output/:panes/"#{container}.html")
        assert_includes content, "<!-- Missing #{container}.html -->", "Expected placeholder for missing #{container}.html"
      else
        refute_includes content, "<!-- Missing #{container}.html -->", "Expected no placeholder for #{container}.html"
      end
    end
  end
    
  def test_create_view_and_generate_front_page_with_placeholders
    # Step 1: Create a new view
    view = @repo.create_view("test_view", "Test View", "A test view")
  
    # Step 2: Create the layout file with all sections
    layout_txt = <<~LAYOUT
      header
      main
      right
      footer
    LAYOUT
    File.write(view.dir/:config/"layout.txt", layout_txt)
  
    # Step 3: Create the text placeholders in the corresponding sections
    # Skip main as a special case
    header_txt = <<~HEADER
      text "HEADER CONTENT PLACEHOLDER"
    HEADER
    File.write(view.dir/:config/"header.txt", header_txt)
  
    right_txt = <<~RIGHT
      text "RIGHT CONTENT PLACEHOLDER"
    RIGHT
    File.write(view.dir/:config/"right.txt", right_txt)
  
    footer_txt = <<~FOOTER
      text "FOOTER CONTENT PLACEHOLDER"
    FOOTER
    File.write(view.dir/:config/"footer.txt", footer_txt)
  
    # Step 4: Generate the front page
    @repo.generate_front_page("test_view")
  
    # Step 5: Now check that each section contains its placeholder replacement
  
    # Verify header section
    header_html = File.read(view.dir/:output/:panes/"header.html")
    assert_includes header_html, "HEADER CONTENT PLACEHOLDER", "Expected header content to include placeholder replacement"
  
    # Verify right section
    right_html = File.read(view.dir/:output/:panes/"right.html")
    assert_includes right_html, "RIGHT CONTENT PLACEHOLDER", "Expected right content to include placeholder replacement"
  
    # Verify footer section
    footer_html = File.read(view.dir/:output/:panes/"footer.html")
    assert_includes footer_html, "FOOTER CONTENT PLACEHOLDER", "Expected footer content to include placeholder replacement"
  
    # Step 6: Verify that the generated front page (index.html) contains all the expected content
    targets = ["HEADER CONTENT PLACEHOLDER", 
               "RIGHT CONTENT PLACEHOLDER", 
               "FOOTER CONTENT PLACEHOLDER"]
    index_html = File.read(view.dir/:output/"index.html")
    assert_present(index_html, *targets)
    assert_ordered(index_html, *targets)
  end
    
  def test_content_of_nonempty_main_section
    create_3_views
    create_13_posts
    alter_pubdates
    @repo.generate_front_page("blog1")
    index_file = @repo.root/:views/"blog1"/:output/"index.html"
    index_html = File.read(index_file)
    targets = ["<!-- Section: header (output) -->",
               "<!-- Section: left (output) -->",
               "<!-- Section: main (output) -->",
               "<!-- Section: right (output) -->",
               "<!-- Section: footer (output) -->"]
    assert_present(index_html, *targets)
    assert_ordered(index_html, *targets)
    FileUtils.cp(index_file, "/tmp/testcms1.html")
    post_div = %[class="index-entry"]
    num_posts = index_html.scan(/#{Regexp.escape(post_div)}/).length
    assert_equal 7, num_posts, "Expected 7 posts, found #{num_posts}"
  end

  def test_content_of_empty_main_section
    create_3_views
    @repo.generate_front_page("blog1")
    index_file = @repo.root/:views/"blog1"/:output/"index.html"
    index_html = File.read(index_file)
    targets = ["<!-- Section: header (output) -->",
               "<!-- Section: left (output) -->",
               "<!-- Section: main (output) -->",
               "<!-- Section: right (output) -->",
               "<!-- Section: footer (output) -->"]
    assert_present(index_html, *targets)
    assert_ordered(index_html, *targets)
    FileUtils.cp(index_file, "/tmp/testcms2.html")
    post_div = %[<div class="index-entry">]
    num_posts = index_html.scan(/#{Regexp.escape(post_div)}/).length
    assert_equal 0, num_posts, "Expected 0 posts, found #{num_posts}"
    assert_includes index_html, "No posts yet!", "Expected 'no posts yet' message"
  end
end
