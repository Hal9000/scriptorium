#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../lib/scriptorium'
require_relative 'test_helpers'

class LivetextPluginTest < Minitest::Test
  include TestHelpers

  def setup
    @test_repo_path = "scriptorium-TEST"
    cleanup_test_repo
  end

  def teardown
    cleanup_test_repo
  end

  def create_test_environment_with_content
    # Create test repo using API
    @api = Scriptorium::API.new(testmode: true)
    @api.create_repo(@test_repo_path)
    
    # Create a view
    @api.create_view("testview", "Test View")
    
    # Create a page using the API
    @api.create_page("testview", "testpage", "Test Page", "This is a test page for link testing.")
    
    # Create a post using the API
    @api.create_post("Test Post", "This is a test post for link testing.", views: "testview", tags: "test")
  end

  def test_001_basic_dot_commands
    # Test basic dot commands that should work
    content = <<~EOS
      .title My Test Post
      .created
      .views sample
      .tags ruby, testing
      .blurb 
      This is a test post
      .end
      This is the body content
    EOS
    
    body, vars = process_livetext(content)
    
    # Check that variables were set correctly
    assert_equal("My Test Post", vars[:"post.title"])
    assert_equal("sample", vars[:"post.views"])
    assert_equal("ruby, testing", vars[:"post.tags"])
    assert_equal("This is a test post", vars[:"post.blurb"])
    
    # Check that body text is returned
    assert_match(/This is the body content/, body)
  end

  def test_002_html_formatting_commands
    # Test HTML formatting commands
    content = <<~EOS
      .h1 Main Heading
      .h2 Sub Heading
      .list
      Item 1
      Item 2
      Item 3
      .end
      .nlist
      Numbered 1
      Numbered 2
      .end
      .quote
      This is a quote
      .end
      .hr
    EOS
    
    body, vars = process_livetext(content)
    
    # Check HTML output
    assert_match(/<h1>Main Heading<\/h1>/, body)
    assert_match(/<h2>Sub Heading<\/h2>/, body)
    assert_match(/<ul>/, body)
    assert_match(/<li>Item 1<\/li>/, body)
    assert_match(/<ol>/, body)
    assert_match(/<li>Numbered 1<\/li>/, body)
    assert_match(/<blockquote>/, body)
    assert_match(/<hr>/, body)
  end

  def test_003_special_formatting
    # Test special formatting like dropcap and inset
    content = <<~EOS
      .dropcap
      This is a dropcap test with multiple lines.
      The dropcap should apply to the first letter of this content.
      .end
      .inset left 25
      |This goes in the inset
      This goes in the body
      /This only goes in inset
      .end
    EOS
    
    body, vars = process_livetext(content)
    
    # Check for dropcap formatting - should be a single paragraph with class
    assert_match(/<p class="dropcap">/, body)
    assert_match(/This is a dropcap test with multiple lines\./, body)
    assert_match(/The dropcap should apply to the first letter/, body)
    
    # Check for inset formatting
    assert_match(/float:left/, body)
    assert_match(/width: 25%/, body)
  end

  def test_004_functions
    # Test Livetext functions
    content = <<~EOS
      $$br:2
      $$h1[Function Heading]
      $$h2[Sub Heading]
      $$image:test.jpg
    EOS
    
    body, vars = process_livetext(content)
    
    # Check function output
    assert_match(/<br><br>/, body)
    assert_match(/<h1>Function Heading<\/h1>/, body)
    assert_match(/<h2>Sub Heading<\/h2>/, body)
    assert_match(/<img src='test\.jpg'><\/img>/, body)
  end

  def test_005_dropcap_command
    # Test the dropcap command
    content = <<~EOS
      .dropcap
      Once upon a time there was a story that began with a dropcap.
      This is the rest of the paragraph that flows naturally.
      .end
    EOS
    
    body, vars = process_livetext(content)
    
    # Check dropcap formatting
    assert_match(/<p class="dropcap">/, body)
    assert_match(/Once upon a time there was a story/, body)
    assert_match(/This is the rest of the paragraph/, body)
    
    # Should be a single paragraph, not split into multiple divs
    refute_match(/mydrop/, body)
    refute_match(/padding-top: 1px/, body)
  end

  def test_006_faq_command
    # Test the FAQ command
    content = <<~EOS
      .faq What is this?
      This is a test question and answer.
      .end
      .faq Another question?
      Another answer.
      .end
    EOS
    
    body, vars = process_livetext(content)
    
    # Check FAQ formatting
    assert_match(/data-toggle="collapse"/, body)
    assert_match(/What is this\?/, body)
    assert_match(/This is a test question and answer/, body)
    assert_match(/Another question\?/, body)
  end

  def test_007_last_updated_command
    skip "Possible LiveText bug with last_updated command"
    content = <<~EOS
      .created
      .title Test Post
      .last_updated
    EOS
    body, vars = process_livetext(content)
    assert_match(/Published:/, body)
    today = Time.now.strftime("%Y-%m-%d")
    assert_match(/#{today}/, body)
  end

  def test_008_image_command
    # Test the .image command
    content = <<~EOS
      .title Test Post
      .image test.jpg
      This is the body content.
    EOS
    
    body, vars = process_livetext(content)
    
    # Check that image command worked
    assert_match(/<img/, body)
    assert_match(/src=assets\/test\.jpg/, body)
    assert_match(/This is the body content/, body)
    # Should not contain the literal ".image" if working
    refute_match(/\.image/, body)
  end

  def test_010_image_exclamation_command
    # Test the .image! command (featured image)
    content = <<~EOS
      .title Test Post
      .image! featured.jpg 800 600 1 Featured image with alt text
      This is the body content.
    EOS
    
    body, vars = process_livetext(content)
    
    # Check that image! command worked
    assert_match(/<img/, body)
    assert_match(/src=assets\/featured\.jpg/, body)
    assert_match(/width=800/, body)
    assert_match(/height=600/, body)
    assert_match(/alt='Featured image with alt text'/, body)
    assert_match(/This is the body content/, body)
    # Should not contain the literal ".image!" if working
    refute_match(/\.image!/, body)
  end

  def test_011_image_with_alt_text
    # Test image command with alt text
    content = <<~EOS
      .title Test Post
      .image test.jpg Alt text for image
      This is the body content.
    EOS
    
    body, vars = process_livetext(content)
    
    # Check that image with alt text worked
    assert_match(/<img/, body)
    assert_match(/src=assets\/test\.jpg/, body)
    assert_match(/alt='Alt text for image'/, body)
    assert_match(/This is the body content/, body)
  end

  def test_012_pullquote_command
    # Test the pullquote command
    content = <<~EOS
      .title Test Post
      This is some content before the pullquote.
      
      .pullquote right 200px
      This is an impactful sentence that will be highlighted in a box.
      .end
      
      This is content after the pullquote that should flow around it.
      
      .pullquote left 180px
      This is another important point on the left side.
      .end
      
      More content that flows around the left-aligned pullquote.
    EOS
    
    body, vars = process_livetext(content)
    
    # Check that pullquote HTML was generated
    assert_match(/<div class="pullquote pullquote-right"/, body)
    assert_match(/<div class="pullquote pullquote-left"/, body)
    assert_match(/style="width: 200px;"/, body)
    assert_match(/style="width: 180px;"/, body)
    
    # Check that the content is included
    assert_match(/This is an impactful sentence/, body)
    assert_match(/This is another important point/, body)
    
    # Check that surrounding content is present
    assert_match(/This is some content before/, body)
    assert_match(/This is content after the pullquote/, body)
    assert_match(/More content that flows around/, body)
    
    # Should not contain the literal ".pullquote" if working
    refute_match(/\.pullquote/, body)
  end

  def test_013_page_function_with_content
    create_test_environment_with_content
    
    content = <<~EOS
      Check out this page: $$page[testpage]
    EOS
    
    # Set the view context for the LiveText functions
    temp_file = "test/temp_livetext.lt3"
    write_file(temp_file, content)
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara", vars: { View: "testview" })
    body, vars = live.process(file: temp_file)
    
    assert_includes body, '<a href="testpage.html">Test Page</a>'
    refute_includes body, '[link is broken]'
  ensure
    File.delete(temp_file) if temp_file && File.exist?(temp_file)
  end

  def test_014_page_function_missing
    create_test_environment_with_content
    
    content = <<~EOS
      Check out this missing page: $$page[nonexistent]
    EOS
    
    temp_file = "test/temp_livetext.lt3"
    write_file(temp_file, content)
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara", vars: { View: "testview" })
    body, vars = live.process(file: temp_file)
    
    assert_includes body, '<a href="nonexistent.html">Nonexistent</a>'
    assert_includes body, '[link is broken]'
  ensure
    File.delete(temp_file) if temp_file && File.exist?(temp_file)
  end

  def test_015_post_function_with_content
    create_test_environment_with_content
    
    content = <<~EOS
      Check out this post: $$post[1]
    EOS
    
    temp_file = "test/temp_livetext.lt3"
    write_file(temp_file, content)
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara", vars: { View: "testview" })
    body, vars = live.process(file: temp_file)
    
    assert_includes body, '<a href="0001-test-post">Test Post</a>'
    refute_includes body, '[link is broken]'
  ensure
    File.delete(temp_file) if temp_file && File.exist?(temp_file)
  end

  def test_016_post_function_missing
    create_test_environment_with_content
    
    content = <<~EOS
      Check out this missing post: $$post[999]
    EOS
    
    temp_file = "test/temp_livetext.lt3"
    write_file(temp_file, content)
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara", vars: { View: "testview" })
    body, vars = live.process(file: temp_file)
    
    assert_includes body, '<a href="0999-untitled.html">Post 999</a>'
    assert_includes body, '[link is broken]'
  ensure
    File.delete(temp_file) if temp_file && File.exist?(temp_file)
  end

  def test_017_imglink_function
    content = <<~EOS
      Check out this image: $$imglink[test.jpg|https://example.com|Click me]
    EOS
    
    body, vars = process_livetext(content)
    
    assert_includes body, '<a href="https://example.com">'
    assert_includes body, '<img src='
    assert_includes body, 'alt="Click me"'
  end

  def test_018_imglink_function_minimal
    content = <<~EOS
      Simple image: $$imglink[icon.png]
    EOS
    
    body, vars = process_livetext(content)
    
    assert_includes body, '<a href="#">'
    assert_includes body, '<img src='
    assert_includes body, 'alt="Image"'
  end

  private

  def process_livetext(content)
    # Create a temporary file with the content
    temp_file = "test/temp_livetext.lt3"
    write_file(temp_file, content)
    live = Livetext.customize(mix: "lt3scriptor", call: ".nopara")
    body, vars = live.process(file: temp_file)
    return [body, vars]
  rescue => e
    return [nil, { error: e.message, backtrace: e.backtrace.first }]
  ensure
    # Clean up
    File.delete(temp_file) if File.exist?(temp_file)
  end

  def cleanup_test_repo
    if Dir.exist?(@test_repo_path)
      FileUtils.rm_rf(@test_repo_path)
    end
  end
end 
