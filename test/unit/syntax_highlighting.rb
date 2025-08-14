#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require 'rouge'

class TestSyntaxHighlighting < Minitest::Test
  include TestHelpers

  def setup
    @test_dir = "test/syntax_highlighting_test_files"
    FileUtils.mkdir_p(@test_dir)
    Scriptorium::Repo.testing = true
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if File.exist?(@test_dir)
  end

  # ========================================
  # LiveText Rouge Lexer Tests
  # ========================================

  def test_001_livetext_lexer_creation
    # Load our custom lexer
    load 'lib/rouge/lexers/livetext.rb'
    
    # Test lexer creation
    lexer = Rouge::Lexers::LiveText.new
    assert lexer.is_a?(Rouge::Lexers::LiveText)
    
    # Test class-level attributes
    assert_equal "LiveText", Rouge::Lexers::LiveText.title
    assert_equal "LiveText markup language (.lt3 files)", Rouge::Lexers::LiveText.desc
    assert_equal "livetext", Rouge::Lexers::LiveText.tag
  end

  def test_002_livetext_lexer_basic_tokenization
    load 'lib/rouge/lexers/livetext.rb'
    lexer = Rouge::Lexers::LiveText.new
    
    # Test with simple content
    content = ".title Test\n## Comment\n$VAR"
    tokens = lexer.lex(content).to_a
    
    assert tokens.length > 0, "Should generate tokens"
    assert tokens.first.is_a?(Array), "Tokens should be arrays"
  end

  def test_003_livetext_lexer_complex_content
    load 'lib/rouge/lexers/livetext.rb'
    lexer = Rouge::Lexers::LiveText.new
    
    # Test with complex LiveText content
    sample_lt3 = <<~LIVETEXT
      .title My LiveText Post
      .blurb This is a test post
      .views sample
      .tags livetext,test
      
      ## This is a comment
      
      .h1 Main Heading
      .h2 Subheading
      
      .list
        First item
        Second item with $VARIABLE
        Third item with @blog.view
      .end
      
      .code ruby
      def hello
        puts "Hello World"
      end
      .end
      
      Using function: $$func[param]
      Using Livetext::Vars[:myvar]
      
      Path example: views/standard/posts
      Special syntax: :views, :posts
    LIVETEXT
    
    tokens = lexer.lex(sample_lt3).to_a
    assert tokens.length > 0, "Should tokenize complex content"
  end

  # ========================================
  # Rouge Integration Tests
  # ========================================

  def test_004_rouge_html_formatter_integration
    load 'lib/rouge/lexers/livetext.rb'
    lexer = Rouge::Lexers::LiveText.new
    
    content = ".title Test\n## Comment\n$VAR"
    formatter = Rouge::Formatters::HTML.new
    highlighted = formatter.format(lexer.lex(content))
    
    assert highlighted.is_a?(String), "Should return HTML string"
    assert highlighted.length > 0, "Should generate HTML output"
    assert highlighted.include?('<span'), "Should contain HTML spans"
  end

  def test_005_rouge_syntax_highlighting_working
    load 'lib/rouge/lexers/livetext.rb'
    lexer = Rouge::Lexers::LiveText.new
    
    # Test with LiveText content that includes code blocks
    content = <<~LIVETEXT
      .title Test Post
      
      .code ruby
      def hello
        puts "Hello World"
      end
      .end
      
      Regular text content
    LIVETEXT
    
    formatter = Rouge::Formatters::HTML.new
    highlighted = formatter.format(lexer.lex(content))
    
    # Should contain syntax highlighting classes
    assert highlighted.include?('class="'), "Should contain CSS classes"
    assert highlighted.include?('def'), "Should contain Ruby keyword"
  end

  # ========================================
  # Scriptorium Syntax Highlighter Tests
  # ========================================

  def test_006_scriptorium_syntax_highlighter
    # Test the Scriptorium syntax highlighter class
    highlighter = Scriptorium::SyntaxHighlighter.new
    assert highlighter.is_a?(Scriptorium::SyntaxHighlighter)
  end

  def test_007_syntax_highlighter_ruby_code
    highlighter = Scriptorium::SyntaxHighlighter.new
    
    ruby_code = <<~RUBY
      def hello_world
        puts "Hello, World!"
        @greeting = "Welcome to Scriptorium"
        return @greeting
      end
    RUBY
    
    highlighted = highlighter.highlight(ruby_code, 'ruby')
    assert highlighted.is_a?(String), "Should return highlighted string"
    assert highlighted.include?('class="'), "Should contain CSS classes"
  end

  def test_008_syntax_highlighter_javascript_code
    highlighter = Scriptorium::SyntaxHighlighter.new
    
    js_code = <<~JS
      function greet(name) {
        console.log("Hello, " + name);
        return "Greeting sent";
      }
    JS
    
    highlighted = highlighter.highlight(js_code, 'javascript')
    assert highlighted.is_a?(String), "Should return highlighted string"
    assert highlighted.include?('function'), "Should contain JavaScript keyword"
  end

  def test_009_syntax_highlighter_no_language
    highlighter = Scriptorium::SyntaxHighlighter.new
    
    plain_text = "This is plain text with no language specified"
    highlighted = highlighter.highlight(plain_text, '')
    
    # Should return plain text when no language specified
    assert_equal plain_text, highlighted
  end

  def test_010_syntax_highlighter_invalid_language
    highlighter = Scriptorium::SyntaxHighlighter.new
    
    code = "some code here"
    # Should handle invalid language gracefully
    highlighted = highlighter.highlight(code, 'invalid_language')
    
    assert highlighted.is_a?(String), "Should return string even with invalid language"
  end
end
