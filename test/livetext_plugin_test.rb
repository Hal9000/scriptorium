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
      .id 123
      .created
      .views sample
      .tags ruby, testing
      .blurb This is a test post
      This is the body content
    EOS
    
    result = process_livetext(content)
    
    # Check that variables were set correctly
    assert_equal("My Test Post", result[:vars][:"post.title"])
    assert_equal("123", result[:vars][:"post.id"])
    assert_equal("sample", result[:vars][:"post.views"])
    assert_equal("ruby, testing", result[:vars][:"post.tags"])
    assert_equal("This is a test post", result[:vars][:"post.blurb"])
    
    # Check that body text is returned
    assert_match(/This is the body content/, result[:text])
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
    
    result = process_livetext(content)
    
    # Check HTML output
    assert_match(/<h1>Main Heading<\/h1>/, result[:text])
    assert_match(/<h2>Sub Heading<\/h2>/, result[:text])
    assert_match(/<ul>/, result[:text])
    assert_match(/<li>Item 1<\/li>/, result[:text])
    assert_match(/<ol>/, result[:text])
    assert_match(/<li>Numbered 1<\/li>/, result[:text])
    assert_match(/<blockquote>/, result[:text])
    assert_match(/<hr>/, result[:text])
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
    
    result = process_livetext(content)
    
    # Check for dropcap formatting
    assert_match(/mydrop/, result[:text])
    assert_match(/his is a dropcap test/, result[:text])  # The remainder after the dropcap
    
    # Check for inset formatting
    assert_match(/float:left/, result[:text])
    assert_match(/width: 25%/, result[:text])
  end

  def test_004_functions
    # Test Livetext functions
    content = <<~EOS
      $$br:2
      $$h1[Function Heading]
      $$h2[Sub Heading]
      $$image:test.jpg
    EOS
    
    result = process_livetext(content)
    
    # Check function output
    assert_match(/<br><br>/, result[:text])
    assert_match(/<h1>Function Heading<\/h1>/, result[:text])
    assert_match(/<h2>Sub Heading<\/h2>/, result[:text])
    assert_match(/<img src='test\.jpg'><\/img>/, result[:text])
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
    
    result = process_livetext(content)
    
    # Check FAQ formatting
    assert_match(/data-toggle="collapse"/, result[:text])
    assert_match(/What is this\?/, result[:text])
    assert_match(/This is a test question and answer/, result[:text])
    assert_match(/Another question\?/, result[:text])
  end

  def test_006_last_updated_command
    # Test the last_updated command
    content = <<~EOS
      .created
      .title Test Post
      .last_updated
    EOS
    
    result = process_livetext(content)
    
    # Check that last_updated outputs the publication date
    assert_match(/Published:/, result[:text])
    today = Time.now.strftime("%Y-%m-%d")
    assert_match(/#{today}/, result[:text])  # Should match today's date
  end

          def test_007_wordcount_function
          # Test the wordcount function
          content = <<~EOS
            .title Test Post
            This is a test post with some words.
            It has multiple sentences and paragraphs.
            
            .wordcount
            The file $File has $wordcount words.
            
            More content here to increase the word count.
            This should be counted as well.
          EOS
    
    result = process_livetext(content)
    
              # Check that wordcount function worked
          assert_match(/The file .* has \d+ words\./, result[:text])
                  # Should not contain the literal ".wordcount" if working
        refute_match(/\.wordcount/, result[:text])
        # Should not contain the literal "$wordcount" if working
        refute_match(/\$wordcount/, result[:text])
  end
  
  def test_008_stats_command
    # Test the stats command that sets multiple variables
    content = <<~EOS
      .title Test Post
      This is a test post with some words.
      It has multiple sentences and paragraphs.
      
      .stats
      This file has $file.wordcount words, $file.charcount characters, and takes about $file.readingtime minutes to read.
      
      More content here to increase the word count.
      This should be counted as well.
    EOS
    
    result = process_livetext(content)
    
    # Check that stats command worked
    assert_match(/This file has \d+ words, \d+ characters, and takes about \d+ minutes to read\./, result[:text])
    # Should not contain the literal ".stats" if working
    refute_match(/\.stats/, result[:text])
    # Should not contain the literal variable names if working
    refute_match(/\$file\.wordcount/, result[:text])
    refute_match(/\$file\.charcount/, result[:text])
    refute_match(/\$file\.readingtime/, result[:text])
  end

  private

  def process_livetext(content)
    # Create a temporary file with the content
    temp_file = "test/temp_livetext.lt3"
    write_file(temp_file, content)
    
    # Process with Livetext using the plugin
    begin
      # Use the real Livetext integration like in repo.rb
      live = Livetext.customize(mix: "lt3scriptor", call: ".nopara")
      text = live.xform_file(temp_file)
      vars, body = live.vars.vars, live.body
      
      # Return the actual data structures
      return { vars: vars, text: text, body: body }
    rescue => e
      return { error: e.message, backtrace: e.backtrace.first }
    ensure
      # Clean up
      File.delete(temp_file) if File.exist?(temp_file)
    end
  end



  def cleanup_test_repo
    if Dir.exist?(@test_repo_path)
      FileUtils.rm_rf(@test_repo_path)
    end
  end
end 