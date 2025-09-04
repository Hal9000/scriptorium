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
      .dropcap This is a dropcap test
      .inset left 25
      |This goes in the inset
      This goes in the body
      /This only goes in inset
      .end
    EOS
    
    body, vars = process_livetext(content)
    
    # Check for dropcap formatting
    assert_match(/mydrop/, body)
    assert_match(/his is a dropcap test/, body)  # The remainder after the dropcap
    
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

  def test_005_faq_command
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

  def test_006_last_updated_command
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



  def test_009_image_command
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
