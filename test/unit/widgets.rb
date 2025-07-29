#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

# Test widget classes defined at module level
class TestWidget < Scriptorium::Widget
  def generate
    "generated content"
  end
  
  def load_config
    { test: "config" }
  end
end

class TestWidget2 < Scriptorium::Widget
  def generate
    "generated content"
  end
  
  def load_config
    { test: "config" }
  end
end

class TestWidget3 < Scriptorium::Widget
  def generate; "generated"; end
  def load_config; {}; end
end

class TestWidget4 < Scriptorium::Widget
  def generate; "generated"; end
  def load_config; {}; end
end

class TestWidget5 < Scriptorium::Widget
  def generate; "generated"; end
  def load_config; {}; end
end

class TestWidget6 < Scriptorium::Widget
  def generate; "generated"; end
  def load_config; {}; end
end

class TestListWidget < Scriptorium::Widget::ListWidget
  def generate
    "generated"
  end
  
  def load_config
    {}
  end
end

class TestListWidget2 < Scriptorium::Widget::ListWidget
  def generate
    "generated"
  end
  
  def load_config
    {}
  end
end

class TestListWidget3 < Scriptorium::Widget::ListWidget
  def generate
    "generated"
  end
  
  def load_config
    {}
  end
end

class TestScriptoriumWidgets < Minitest::Test
  include TestHelpers

  def setup
    @test_dir = "test/widget_test_files"
    make_dir(@test_dir)
    @repo = Scriptorium::Repo.create("test/scriptorium-TEST", testmode: true)
    @view = @repo.create_view("test_view", "Test View", "Test subtitle")
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    Scriptorium::Repo.destroy if Scriptorium::Repo.testing
  end

  # ========================================
  # Base Widget Class Tests
  # ========================================

  def test_base_widget_initialization
    widget = TestWidget.new(@repo, @view)
    
    assert_equal @repo, widget.repo
    assert_equal @view, widget.view
    assert_equal({ test: "config" }, widget.config)
    assert_equal "testwidget", widget.name
    assert_equal "#{@view.dir}/widgets/testwidget", widget.path
  end

  def test_base_widget_abstract_methods
    widget = TestWidget2.new(@repo, @view)
    
    # Test that we can call the abstract methods on concrete implementation
    assert_equal "generated content", widget.generate
    assert_equal({ test: "config" }, widget.load_config)
  end

  def test_html_body_without_css
    widget = TestWidget3.new(@repo, @view)
    result = widget.html_body { "test content" }
    
    assert_match(/<html>/, result)
    assert_match(/<body>test content<\/body>/, result)
    refute_match(/<head>/, result)
  end

  def test_html_body_with_css
    widget = TestWidget4.new(@repo, @view)
    result = widget.html_body("body { color: red; }") { "test content" }
    
    assert_match(/<html>/, result)
    assert_match(/<head><style>body \{ color: red; \}<\/style><\/head>/, result)
    assert_match(/<body>test content<\/body>/, result)
  end

  def test_html_card
    widget = TestWidget5.new(@repo, @view)
    result = widget.html_card("Test Title", "test-tag", "test content")
    
    assert_match(/<div class="card mb-3">/, result)
    assert_match(/<h5 class="card-title">/, result)
    assert_match(/<button.*data-bs-toggle="collapse".*data-bs-target="#test-tag">/, result)
    assert_match(/<a href="javascript:void\(0\)".*onclick="javascript:load_main\('test-tag-main\.html'\)"/, result)
    assert_match(/Test Title/, result)
    assert_match(/<div class="collapse" id="test-tag">/, result)
    assert_match(/test content/, result)
  end

  def test_html_container
    widget = TestWidget6.new(@repo, @view)
    result = widget.html_container("test content")
    
    assert_match(/<div class="widget-container">/, result)
    assert_match(/test content/, result)
  end

  # ========================================
  # ListWidget Tests
  # ========================================

  def test_list_widget_initialization
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/testlistwidget/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [
      "https://example.com, Example Site",
      "https://test.com, Test Site"
    ])
    
    widget = TestListWidget.new(@repo, @view)
    
    assert_equal @repo, widget.repo
    assert_equal @view, widget.view
    assert_equal "testlistwidget", widget.name
    assert_equal "#{@view.dir}/widgets/testlistwidget", widget.path
    assert_equal list_file, widget.instance_variable_get(:@list)
    assert_equal [
      "https://example.com, Example Site",
      "https://test.com, Test Site"
    ], widget.instance_variable_get(:@data)
  end

  def test_list_widget_load_data_missing_file
    # Should raise error when list.txt doesn't exist
    assert_raises(CannotReadFileNotFound) do
      TestListWidget2.new(@repo, @view)
    end
  end

  def test_list_widget_load_data_empty_file
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/testlistwidget3/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [])
    
    widget = TestListWidget3.new(@repo, @view)
    assert_equal [], widget.instance_variable_get(:@data)
  end

  # ========================================
  # Links Widget Tests
  # ========================================

  def test_links_widget_initialization
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/links/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [
      "https://example.com, Example Site",
      "https://test.com, Test Site"
    ])
    
    widget = Scriptorium::Widget::Links.new(@repo, @view)
    
    assert_equal @repo, widget.repo
    assert_equal @view, widget.view
    assert_equal "links", widget.name
    assert_equal "#{@view.dir}/widgets/links", widget.path
    assert_equal [
      "https://example.com, Example Site",
      "https://test.com, Test Site"
    ], widget.instance_variable_get(:@lines)
  end

  def test_links_widget_get_list
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/links/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [
      "https://example.com, Example Site",
      "https://test.com, Test Site",
      "https://spaced.com , Spaced Site"
    ])
    
    widget = Scriptorium::Widget::Links.new(@repo, @view)
    result = widget.get_list
    
    assert_equal [
      ["https://example.com", "Example Site"],
      ["https://test.com", "Test Site"],
      ["https://spaced.com ", "Spaced Site"]
    ], result
  end

  def test_links_widget_link_item
    # Create test list.txt file for initialization
    list_file = "#{@view.dir}/widgets/links/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, ["https://example.com, Example Site"])
    
    widget = Scriptorium::Widget::Links.new(@repo, @view)
    result = widget.link_item("https://example.com", "Example Site")
    
    assert_match(/<li class="list-group-item">/, result)
    assert_match(/<a href="https:\/\/example\.com" target="_blank" style="text-decoration: none;">Example Site<\/a>/, result)
  end

  def test_links_widget_write_card
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/links/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [
      "https://example.com, Example Site",
      "https://test.com, Test Site"
    ])
    
    widget = Scriptorium::Widget::Links.new(@repo, @view)
    widget.write_card
    
    # Check that card file was created
    card_file = "#{@view.dir}/widgets/links/links-card.html"
    assert_file_exist?(card_file)
    
    # Check card content
    content = read_file(card_file)
    assert_match(/<div class="card mb-3">/, content)
    assert_match(/<h5 class="card-title">/, content)
    assert_match(/External links/, content)
    assert_match(/<a href="https:\/\/example\.com" target="_blank"/, content)
    assert_match(/Example Site/, content)
    assert_match(/<a href="https:\/\/test\.com" target="_blank"/, content)
    assert_match(/Test Site/, content)
  end

  def test_links_widget_generate
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/links/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [
      "https://example.com, Example Site"
    ])
    
    widget = Scriptorium::Widget::Links.new(@repo, @view)
    widget.generate
    
    # Check that card file was created
    card_file = "#{@view.dir}/widgets/links/links-card.html"
    assert_file_exist?(card_file)
    
    # Check card content
    content = read_file(card_file)
    assert_match(/External links/, content)
    assert_match(/Example Site/, content)
  end

  def test_links_widget_card_method
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/links/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [
      "https://example.com, Example Site"
    ])
    
    widget = Scriptorium::Widget::Links.new(@repo, @view)
    widget.generate
    
    # Test card method returns file content
    card_content = widget.card
    assert_match(/External links/, card_content)
    assert_match(/Example Site/, card_content)
  end

  def test_links_widget_missing_list_file
    # Should raise error when list.txt doesn't exist
    assert_raises(CannotReadFileNotFound) do
      Scriptorium::Widget::Links.new(@repo, @view)
    end
  end

  # ========================================
  # Widget Integration Tests
  # ========================================

  def test_build_widgets_with_links
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/links/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [
      "https://example.com, Example Site"
    ])
    
    # Build widgets through view
    result = @view.build_widgets("links")
    
    # Check that HTML was generated
    assert_match(/<div class="card mb-3">/, result)
    assert_match(/External links/, result)
    assert_match(/Example Site/, result)
    
    # Check that card file was created
    card_file = "#{@view.dir}/widgets/links/links-card.html"
    assert_file_exist?(card_file)
  end

  def test_build_widgets_multiple_widgets
    # Create test list.txt file for links widget
    list_file = "#{@view.dir}/widgets/links/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, [
      "https://example.com, Example Site"
    ])
    
    # Build multiple widgets (just links for now, but tests the multiple widget handling)
    result = @view.build_widgets("links links")
    
    # Should contain widget HTML twice
    assert_match(/External links/, result)
    assert_match(/Example Site/, result)
    
    # Count occurrences to verify it appears twice
    assert_equal 2, result.scan(/External links/).length
  end

  def test_build_widgets_invalid_widget_name
    assert_raises(NameError) do
      @view.build_widgets("nonexistent")
    end
  end

  def test_build_widgets_with_special_characters
    assert_raises(CannotBuildWidgetNameInvalid) do
      @view.build_widgets("invalid@widget")
    end
  end

  # Pages widget tests
  def test_pages_widget_initialization
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/pages/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, "about", "contact", "faq")
    
    # Create test HTML files
    pages_dir = "#{@view.dir}/pages"
    make_dir(pages_dir)
    write_file("#{pages_dir}/about.html", "<html><title>About Us</title><body><h1>About Us</h1></body></html>")
    write_file("#{pages_dir}/contact.html", "<html><title>Contact Information</title><body><h1>Contact</h1></body></html>")
    write_file("#{pages_dir}/faq.html", "<html><title>FAQ</title><body><h1>FAQ</h1></body></html>")
    
    widget = Scriptorium::Widget::Pages.new(@repo, @view)
    
    assert_equal @repo, widget.repo
    assert_equal @view, widget.view
    assert_equal "pages", widget.name
    assert_equal ["about", "contact", "faq"], widget.data
  end

  def test_pages_widget_extract_title_from_title_tag
    # Create minimal list.txt to avoid initialization error
    list_file = "#{@view.dir}/widgets/pages/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, "test")
    
    widget = Scriptorium::Widget::Pages.new(@repo, @view)
    
    html = "<html><head><title>My Page Title</title></head><body>Content</body></html>"
    title = widget.send(:extract_title_from_html, html)
    
    assert_equal "My Page Title", title
  end

  def test_pages_widget_extract_title_from_h1_tag
    # Create minimal list.txt to avoid initialization error
    list_file = "#{@view.dir}/widgets/pages/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, "test")
    
    widget = Scriptorium::Widget::Pages.new(@repo, @view)
    
    html = "<html><body><h1>My H1 Title</h1><p>Content</p></body></html>"
    title = widget.send(:extract_title_from_html, html)
    
    assert_equal "My H1 Title", title
  end

  def test_pages_widget_extract_title_fallback
    # Create minimal list.txt to avoid initialization error
    list_file = "#{@view.dir}/widgets/pages/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, "test")
    
    widget = Scriptorium::Widget::Pages.new(@repo, @view)
    
    html = "<html><body><p>No title here</p></body></html>"
    title = widget.send(:extract_title_from_html, html)
    
    assert_equal "Untitled", title
  end

  def test_pages_widget_generate
    # Create test list.txt file
    list_file = "#{@view.dir}/widgets/pages/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, "about", "contact")
    
    # Create test HTML files
    pages_dir = "#{@view.dir}/pages"
    make_dir(pages_dir)
    write_file("#{pages_dir}/about.html", "<html><title>About Us</title><body></body></html>")
    write_file("#{pages_dir}/contact.html", "<html><title>Contact</title><body></body></html>")
    
    widget = Scriptorium::Widget::Pages.new(@repo, @view)
    result = widget.generate
    
    assert result
    
    # Check that card file was created
    card_file = "#{@view.dir}/widgets/pages/pages-card.html"
    assert File.exist?(card_file)
    
    # Check that card contains links to pages
    card_content = read_file(card_file)
    assert_includes card_content, 'onclick="load_main(\'pages/about.html\')"'
    assert_includes card_content, 'onclick="load_main(\'pages/contact.html\')"'
    assert_includes card_content, 'About Us'
    assert_includes card_content, 'Contact'
  end

  def test_pages_widget_skip_missing_pages
    # Create test list.txt file with a missing page
    list_file = "#{@view.dir}/widgets/pages/list.txt"
    make_dir(File.dirname(list_file))
    write_file(list_file, "about", "missing", "contact")
    
    # Create only one HTML file
    pages_dir = "#{@view.dir}/pages"
    make_dir(pages_dir)
    write_file("#{pages_dir}/about.html", "<html><title>About Us</title><body></body></html>")
    write_file("#{pages_dir}/contact.html", "<html><title>Contact</title><body></body></html>")
    
    widget = Scriptorium::Widget::Pages.new(@repo, @view)
    result = widget.generate
    
    assert result
    
    # Check that card file was created and contains only existing pages
    card_file = "#{@view.dir}/widgets/pages/pages-card.html"
    card_content = read_file(card_file)
    assert_includes card_content, 'onclick="load_main(\'pages/about.html\')"'
    assert_includes card_content, 'onclick="load_main(\'pages/contact.html\')"'
    refute_includes card_content, 'onclick="load_main(\'pages/missing.html\')"'
  end
end 