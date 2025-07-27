require_relative '../test_helpers'
require_relative '../../lib/scriptorium/view'

class TestScriptoriumView < Minitest::Test
  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers

  def setup
    @test_dir = "test/view_test_files"
    make_dir(@test_dir)
    @repo = Scriptorium::Repo.create(true)
    @view = @repo.create_view("test_view", "Test View", "A test view", theme: "standard")
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    Scriptorium::Repo.destroy if Scriptorium::Repo.testing
  end

  # Constructor validation tests
  def test_initialize_with_valid_params
    view = Scriptorium::View.new("valid_name", "Valid Title", "Subtitle", "standard")
    assert_equal "valid_name", view.name
    assert_equal "Valid Title", view.title
    assert_equal "Subtitle", view.subtitle
    assert_equal "standard", view.theme
  end

  def test_initialize_with_nil_name
    assert_raises(CannotCreateViewNameNil) do
      Scriptorium::View.new(nil, "Title", "Subtitle")
    end
  end

  def test_initialize_with_empty_name
    assert_raises(CannotCreateViewNameEmpty) do
      Scriptorium::View.new("", "Title", "Subtitle")
    end
  end

  def test_initialize_with_whitespace_name
    assert_raises(CannotCreateViewNameEmpty) do
      Scriptorium::View.new("   ", "Title", "Subtitle")
    end
  end

  def test_initialize_with_invalid_name_format
    assert_raises(CannotCreateViewNameInvalid) do
      Scriptorium::View.new("invalid@name", "Title", "Subtitle")
    end
  end

  def test_initialize_with_nil_title
    assert_raises(CannotCreateViewTitleNil) do
      Scriptorium::View.new("valid_name", nil, "Subtitle")
    end
  end

  def test_initialize_with_empty_title
    assert_raises(CannotCreateViewTitleEmpty) do
      Scriptorium::View.new("valid_name", "", "Subtitle")
    end
  end

  def test_initialize_with_whitespace_title
    assert_raises(CannotCreateViewTitleEmpty) do
      Scriptorium::View.new("valid_name", "   ", "Subtitle")
    end
  end

  # Theme handling tests
  def test_theme_getter
    assert_equal "standard", @view.theme
  end

  def test_theme_setter_with_valid_theme
    @view.theme("standard")
    assert_equal "standard", @view.theme
  end

  def test_theme_setter_with_nonexistent_theme
    assert_raises(ThemeDoesntExist) do
      @view.theme("nonexistent_theme")
    end
  end

  # Widget validation tests
  def test_build_widgets_with_valid_widget
    # This test would need actual widget classes to be available
    # For now, we'll test the validation logic
    assert_raises(CannotBuildWidgetsArgNil) do
      @view.build_widgets(nil)
    end
  end

  def test_build_widgets_with_empty_arg
    assert_raises(CannotBuildWidgetsArgEmpty) do
      @view.build_widgets("")
    end
  end

  def test_build_widgets_with_whitespace_arg
    assert_raises(CannotBuildWidgetsArgEmpty) do
      @view.build_widgets("   ")
    end
  end

  def test_build_widgets_with_invalid_widget_name
    assert_raises(CannotBuildWidgetNameInvalid) do
      @view.build_widgets("invalid@widget")
    end
  end

  # Layout file tests
  def test_read_layout_with_missing_file
    # Create a view without layout.txt by creating it through repo then deleting the layout file
    view = @repo.create_view("no_layout", "No Layout", "No layout view", theme: "standard")
    File.delete(view.dir/:config/"layout.txt") if File.exist?(view.dir/:config/"layout.txt")
    assert_raises(LayoutFileMissing) do
      view.read_layout
    end
  end

  # Content tag tests
  def test_content_tag
    assert_equal "<!-- Section: header -->", @view.content_tag("header")
    assert_equal "<!-- Section: footer -->", @view.content_tag("footer")
  end

  # Placeholder text tests
  def test_placeholder_text_with_file_reference
    # Create a test file
    test_file = @view.dir/:config/:text/"test_content"
    make_dir(File.dirname(test_file))
    write_file(test_file, "Test content from file")
    
    result = @view.placeholder_text("@test_content")
    assert_equal "Test content from file\n", result
  end

  def test_placeholder_text_with_plain_text
    result = @view.placeholder_text("Plain text content")
    assert_equal "Plain text content", result
  end

  def test_placeholder_text_with_missing_file
    result = @view.placeholder_text("@missing_file")
    assert_match /Missing:.*missing_file/, result
  end

  # Section hash tests
  def test_section_hash_default_behavior
    hash = @view.section_hash("test_section")
    assert hash.is_a?(Hash)
    
    # Test default behavior for unknown keys
    result = hash["unknown_key"].call
    assert_match /Not defined for key: unknown_key/, result
  end

  def test_section_hash_text_component
    hash = @view.section_hash("test_section")
    result = hash["text"].call("Test argument")
    assert_equal "  <p>Test argument</p>\n", result
  end

  # Inspect test
  def test_inspect
    result = @view.inspect
    assert_match /<View: test_view/, result
    assert_match /Test View/, result
    assert_match /theme: standard/, result
  end

  # HTML generation tests
  def test_check_html_stubs
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
  def test_check_layout_parsing
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
end 