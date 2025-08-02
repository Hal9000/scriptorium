require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'
require_relative '../../lib/scriptorium/view'

class TestScriptoriumView < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @test_dir = "test/view_test_files"
    make_dir(@test_dir)
    # Use a unique test repo path to avoid conflicts
    @repo_path = "scriptorium-TEST"
    FileUtils.rm_rf(@repo_path) if Dir.exist?(@repo_path)
    @repo = Scriptorium::Repo.create(@repo_path, testmode: true)
    @view = @repo.create_view("test_view", "Test View", "A test view", theme: "standard")
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    FileUtils.rm_rf(@repo_path) if Dir.exist?(@repo_path)
    Scriptorium::Repo.destroy if Scriptorium::Repo.testing
  end

  # Constructor validation tests
  def test_001_initialize_with_valid_params
    view = Scriptorium::View.new("valid_name", "Valid Title", "Subtitle", "standard")
    assert_equal "valid_name", view.name
    assert_equal "Valid Title", view.title
    assert_equal "Subtitle", view.subtitle
    assert_equal "standard", view.theme
  end

  def test_002_initialize_with_nil_name
    assert_raises(CannotCreateViewNameNil) do
      Scriptorium::View.new(nil, "Title", "Subtitle")
    end
  end

  def test_003_initialize_with_empty_name
    assert_raises(CannotCreateViewNameEmpty) do
      Scriptorium::View.new("", "Title", "Subtitle")
    end
  end

  def test_004_initialize_with_whitespace_name
    assert_raises(CannotCreateViewNameEmpty) do
      Scriptorium::View.new("   ", "Title", "Subtitle")
    end
  end

  def test_005_initialize_with_invalid_name_format
    assert_raises(CannotCreateViewNameInvalid) do
      Scriptorium::View.new("invalid@name", "Title", "Subtitle")
    end
  end

  def test_006_initialize_with_nil_title
    assert_raises(CannotCreateViewTitleNil) do
      Scriptorium::View.new("valid_name", nil, "Subtitle")
    end
  end

  def test_007_initialize_with_empty_title
    assert_raises(CannotCreateViewTitleEmpty) do
      Scriptorium::View.new("valid_name", "", "Subtitle")
    end
  end

  def test_008_initialize_with_whitespace_title
    assert_raises(CannotCreateViewTitleEmpty) do
      Scriptorium::View.new("valid_name", "   ", "Subtitle")
    end
  end

  # Theme handling tests
  def test_009_theme_getter
    assert_equal "standard", @view.theme
  end

  def test_010_theme_setter_with_valid_theme
    @view.theme("standard")
    assert_equal "standard", @view.theme
  end

  def test_011_theme_setter_with_nonexistent_theme
    assert_raises(ThemeDoesntExist) do
      @view.theme("nonexistent_theme")
    end
  end

  # Widget validation tests
  def test_012_build_widgets_with_valid_widget
    # This test would need actual widget classes to be available
    # For now, we'll test the validation logic
    assert_raises(CannotBuildWidgetsArgNil) do
      @view.build_widgets(nil)
    end
  end

  def test_013_build_widgets_with_empty_arg
    assert_raises(CannotBuildWidgetsArgEmpty) do
      @view.build_widgets("")
    end
  end

  def test_014_build_widgets_with_whitespace_arg
    assert_raises(CannotBuildWidgetsArgEmpty) do
      @view.build_widgets("   ")
    end
  end

  def test_015_build_widgets_with_invalid_widget_name
    assert_raises(CannotBuildWidgetNameInvalid) do
      @view.build_widgets("invalid@widget")
    end
  end

  # Layout file tests
  def test_016_read_layout_with_missing_file
    # Create a view without layout.txt by creating it through repo then deleting the layout file
    view = @repo.create_view("no_layout", "No Layout", "No layout view", theme: "standard")
    File.delete(view.dir/:config/"layout.txt") if File.exist?(view.dir/:config/"layout.txt")
    assert_raises(LayoutFileMissing) do
      view.read_layout
    end
  end

  # Content tag tests
  def test_017_content_tag
    assert_equal "<!-- Section: header -->", @view.content_tag("header")
    assert_equal "<!-- Section: footer -->", @view.content_tag("footer")
  end

  # Placeholder text tests
  def test_018_placeholder_text_with_file_reference
    # Create a test file
    test_file = @view.dir/:config/:text/"test_content"
    make_dir(File.dirname(test_file))
    write_file(test_file, "Test content from file")
    
    result = @view.placeholder_text("@test_content")
    assert_equal "Test content from file\n", result
  end

  def test_019_placeholder_text_with_plain_text
    result = @view.placeholder_text("Plain text content")
    assert_equal "Plain text content", result
  end

  def test_020_placeholder_text_with_missing_file
    result = @view.placeholder_text("@missing_file")
    assert_match /Missing:.*missing_file/, result
  end

  # Section hash tests
  def test_021_section_hash_default_behavior
    hash = @view.section_hash("test_section")
    assert hash.is_a?(Hash)
    
    # Test default behavior for unknown keys
    result = hash["unknown_key"].call
    assert_match /Not defined for key: unknown_key/, result
  end

  def test_022_section_hash_text_component
    hash = @view.section_hash("test_section")
    result = hash["text"].call("Test argument")
    assert_equal "  <p>Test argument</p>\n", result
  end

  # Inspect test
  def test_023_inspect
    result = @view.inspect
    assert_match /<View: test_view/, result
    assert_match /Test View/, result
    assert_match /theme: standard/, result
  end

  # HTML generation tests
  def test_024_check_html_stubs
    panes = @view.dir/:output/:panes
    assert_file_exist?(panes/"header.html")
    assert_file_exist?(panes/"footer.html")
    assert_file_exist?(panes/"left.html")
    assert_file_exist?(panes/"right.html")
    assert_file_exist?(panes/"main.html")

    assert_file_contains?(panes/"header.html", "<!-- HEADER CONTENT -->")
    assert_file_contains?(panes/"footer.html", "<!-- FOOTER CONTENT -->")
    assert_file_contains?(panes/"left.html",   "<!-- LEFT CONTENT -->")
    assert_file_contains?(panes/"right.html",  "<!-- RIGHT CONTENT -->")
    assert_file_contains?(panes/"main.html",   "<!-- MAIN CONTENT -->")
  end

  # Layout parsing tests
  def test_025_check_layout_parsing
    file = @view.dir/:config/"layout.txt"
    File.open(file, "w") do |f|
      f.puts <<~EOS
        main     # Center pane
        header
        left   15%
        right  20%  # Right sidebar
        footer
      EOS
    end
    results = @view.read_layout.keys
    expected = ["main", "header", "left", "right", "footer"].sort
    assert results.sort == expected, "Error reading layout file (got #{results.inspect})"

    File.open(file, "w") do |f|
      f.puts <<~EOS
        main     # Center pane
        header
        banana
        left   15%
        right  20%  # Right sidebar
        footer
      EOS
    end
    assert_raises(LayoutHasUnknownTag) { @view.read_layout }

    File.open(file, "w") do |f|
      f.puts <<~EOS
        main     # Center pane
        header
        main
        left   15%
        right  20%  # Right sidebar
        footer
      EOS
    end
    assert_raises(LayoutHasDuplicateTags) { @view.read_layout }
  end

  def test_025_build_banner_svg_format
    # Create svg.txt config file
    svg_config = @view.dir/:config/"svg.txt"
    make_dir(File.dirname(svg_config))
    write_file!(svg_config, "back.color #f0f0f0", 
                "text.color #333333", "aspect 4.0")
    result = @view.build_banner("svg")
    
    # Should generate JavaScript with SVG content
    assert_includes result, "<script>"
    assert_includes result, "insert_svg_header"
    assert_includes result, "svg_text"
  end

  def test_026_build_banner_image_format
    # Create test image in view assets
    image_path = @view.dir/:assets/"testbanner.jpg"
    make_dir(File.dirname(image_path))
    write_file(image_path, "fake image content")
    
    result = @view.build_banner("testbanner.jpg")
    
    # Should generate img tag with relative path
    assert_includes result, "<img src='assets/testbanner.jpg'"
    assert_includes result, "alt='Banner Image'"
    assert_includes result, "style='width: 100%; height: auto;'"
  end

  def test_027_build_banner_image_missing_with_warning
    result = @view.build_banner("missing.jpg")
    
    # Should show warning message
    assert_includes result, "<p>Banner image missing: missing.jpg</p>"
  end

  def test_028_build_navbar_with_default_file
    # Create navbar.txt file
    navbar_file = @view.dir/:config/"navbar.txt"
    make_dir(File.dirname(navbar_file))
    write_file!(navbar_file, 
                "=About",
                " Vision & Mission  mission",
                " Board of Directors    board",
                "-Contact               contact")
    result = @view.build_nav(nil)
    
    # Should generate Bootstrap navbar
    assert_includes result, "navbar navbar-expand-lg"
    assert_includes result, "dropdown-toggle"
    assert_includes result, "About"
    assert_includes result, "Vision &amp; Mission"
    assert_includes result, "Contact"
    assert_includes result, "load_main('pages/mission.html')"
    assert_includes result, "load_main('pages/contact.html')"
  end

  def test_029_build_navbar_with_specified_file
    # Create custom navbar file
    navbar_file = @view.dir/:config/"custom-nav.txt"
    make_dir(File.dirname(navbar_file))
    write_file!(navbar_file, 
                "=Resources",
                " Documentation  docs",
                " API Reference    api",
                "-Support               support")
    result = @view.build_nav("custom-nav.txt")
    
    # Should generate Bootstrap navbar
    assert_includes result, "Resources"
    assert_includes result, "Documentation"
    assert_includes result, "Support"
    assert_includes result, "load_main('pages/docs.html')"
  end

  def test_030_build_navbar_with_missing_pages
    # Create navbar.txt with references to non-existent pages
    navbar_file = @view.dir/:config/"navbar.txt"
    make_dir(File.dirname(navbar_file))
    write_file!(navbar_file, 
                "-Home                   home",
                "-Missing Page          missing")
    result = @view.build_nav(nil)
    
    # Should still generate links but include warnings
    assert_includes result, "load_main('pages/home.html')"
    assert_includes result, "load_main('pages/missing.html')"
    assert_includes result, "Warning: Page file 'missing.html' not found"
  end

  def test_031_build_navbar_parsing
    # Test parsing of different line types
    navbar_content = <<~EOS
      =About
       Vision & Mission  mission
       Board of Directors    board
      -Contact               contact
      =Resources
       Documentation  docs
      -Support               support
    EOS
    
    menu_items = @view.send(:parse_navbar_content, navbar_content)
    
    # Should parse correctly
    assert_equal 4, menu_items.length
    
    # Check dropdown items
    about_dropdown = menu_items.find { |item| item[:label] == "About" }
    assert_equal :dropdown, about_dropdown[:type]
    assert_equal 2, about_dropdown[:children].length
    
    # Check regular items
    contact_item = menu_items.find { |item| item[:title] == "Contact" }
    assert_equal :item, contact_item[:type]
    assert_equal "contact", contact_item[:filename]
  end
end 
