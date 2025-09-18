#!/usr/bin/env ruby

require 'minitest/autorun'
require 'fileutils'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestSyntaxHighlighting < Minitest::Test
  include TestHelpers

  def setup
    FileUtils.rm_rf('test/scriptorium-TEST') if Dir.exist?('test/scriptorium-TEST')
    @repo = create_test_repo
    @view = 'syntax_view'
    @repo.create_view(@view, 'Syntax View', 'Highlight.js test view')
    # Ensure highlight is enabled in head
    head = @repo.root/:views/@view/:config/"global-head.txt"
    content = File.exist?(head) ? read_file(head) : ''
    additions = []
    additions << "highlight" unless content.include?("\nhighlight")
    additions << "highlight_custom" unless content.include?("\nhighlight_custom")
    File.open(head, 'a') { |f| additions.each { |ln| f.puts ln } } unless additions.empty?
    # Ensure an index is generated for head assertions
    @repo.generate_front_page(@view)
  end

  def teardown
    FileUtils.rm_rf('test/scriptorium-TEST') if Dir.exist?('test/scriptorium-TEST')
  end

  def test_001_post_contains_raw_code_blocks_for_hljs
    body = <<~LT
      .title HLJS Test
      .views #{@view}
      .blurb
      Testing Highlight.js only
      .end

      ## Ruby
      .code ruby
      def hello
        puts 'hi'
      end
      .end

      ## JS
      .code javascript
      console.log('x');
      .end
    LT
    name = @repo.create_draft(title: 'HLJS Test', views: [@view], body: body)
    num = @repo.finish_draft(name)
    @repo.generate_post(num)
    @repo.generate_front_page(@view)

    post = @repo.root/:views/@view/:output/:posts/"#{d4(num)}-hljs-test.html"
    html = read_file(post)

    assert_includes html, '<pre><code class="language-ruby">'
    assert_includes html, '<pre><code class="language-javascript">'
    refute_match(/class=\"token\s+/, html)
  end

  def test_002_head_includes_hljs_assets
    index = @repo.root/:views/@view/:output/"index.html"
    html = read_file(index)

    assert_includes html, 'cdnjs.cloudflare.com/ajax/libs/highlight.js'
  end
end
