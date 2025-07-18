require 'minitest/autorun'

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestScriptoriumRepo < Minitest::Test

  include Scriptorium::Exceptions
  include Scriptorium::Helpers
  include TestHelpers

  Repo = Scriptorium::Repo

  def setup
  end

  def teardown
    system("rm -rf scriptorium-TEST")
  end

  def test_001_version
    ver = Scriptorium::VERSION
    pieces = ver.split(".")
    pieces.each do |num|
      assert num =~ /^\d+$/, "Invalid version '#{ver}'"
    end
  end

  def test_002_repo_create_destroy
    t0 = Repo.exist?
    refute t0, "Repo should not exist yet"

    create_test_repo

    t1 = Repo.exist?
    assert t1, "Repo should exist"

    Repo.destroy

    t2 = Repo.exist?
    refute t2, "Repo should have been destroyed"
  end

  def test_003_illegal_destroy
    Repo.testing = false
    assert_raises(TestModeOnly) { Repo.destroy }
  end

  def test_004_repo_structure
    create_test_repo
    root = Repo.root
    assert_dir_exist?(root/"config")
    assert_dir_exist?(root/"views")
    assert_dir_exist?(root/"views/sample")
    assert_dir_exist?(root/"posts")
    assert_dir_exist?(root/"drafts")
    assert_dir_exist?(root/"themes")
    assert_dir_exist?(root/"themes/standard")
    assert_dir_exist?(root/"assets")
  end

  def test_005_check_sample_view
    repo = create_test_repo
    assert repo.views.is_a?(Array), "Expected array of Views"
    assert repo.views.size == 1, "Expected one initial view"
    assert repo.views[0].name == "sample", "Expected to find view 'sample'"
    assert repo.current_view.name == "sample", "Expected current view to be 'sample'"
  end

  def test_006_create_view
    repo = create_test_repo
    vname = "testview"
    t0 = repo.view_exist?(vname)
    refute t0, "View should not exist yet"

    repo.create_view(vname, "My Title", "Just a subtitle here")  # testing

    t1 = repo.view_exist?(vname)
    assert t1, "View should exist"

    assert_raises(ViewDirAlreadyExists) do
      repo.create_view(vname, "My Other Title", "Just dumbness here")  # testing
    end
  end

  def test_007_new_view_becomes_current
    repo = create_test_repo
    tv2 = "testview2"
    view = repo.create_view(tv2, "My 2nd Title", "Just another subtitle here")
    assert repo.views.size == 2, "Expected 2 views, not #{repo.views.size}"
    vnames = repo.views.map {|v| v.name }
    assert vnames.include?(tv2), "Expected to find '#{tv2}' in views"
    assert repo.current_view.name == view.name, "Expected '#{tv2}' as current view"
  end

  def test_008_open_view
    repo = create_test_repo
    vname = "testview"
    title, sub = "My Awesome Title", "Just another subtitle"
    repo.create_view(vname, title, sub)
    t0 = repo.view_exist?(vname)
    assert t0, "View should exist"

    view = repo.open_view(vname)
    assert view.title    == title, "View title missing"
    assert view.subtitle == sub,   "View subtitle missing"
    assert view.theme    == "standard", "Expected standard theme, found '#{view.theme}'"
    assert repo.current_view.name == vname, "Expected '#{vname}' in views"
  end

  def test_009_create_draft
    repo = create_test_repo("testview")  # View should exist to create draft?
    fname = repo.create_draft
    assert_file_exist?(fname)
    assert_file_contains?(fname, ".title ADD TITLE HERE")
    assert_file_contains?(fname, ".views BLOG1 BLOG2 BLOG3")
    assert_file_contains?(fname, ".tags  sample, tags")
    
    f2 = repo.create_draft(title: "Draft post", tags: %w[things stuff])
    assert_file_exist?(f2)
    assert_file_contains?(f2, ".title Draft post")
    assert_file_contains?(f2, ".views BLOG1 BLOG2 BLOG3")
    assert_file_contains?(f2, ".tags  things, stuff")
  end

  def test_010_finish_draft
    $debug = true
    repo = create_test_repo("testview")  # View should exist to create draft?
    fname = repo.create_draft

    repo.finish_draft(fname)
    postnum = "0001"  # Assumes testing started with 0
    postdir = repo.root/:posts/postnum 
    assert_dir_exist?(postdir/:assets)
    assert_file_exist?(postdir/"draft.lt3") 
    $debug = false
  end

  def test_011_check_initial_post
    repo = create_test_repo
    root = repo.root
    file = "#{root}/themes/standard/initial/post.lt3" # FIXME hardcoded
    assert_file_exist?(file)
    assert_file_lines(file, 12)
  end

  def test_012_check_interpolated_initial_post
    repo = create_test_repo
    predef = repo.instance_eval { @predef }
    str = predef.initial_post
    lines = str.split("\n")
    assert lines[2] == ".id 0000", "Expected '.id 0000' with unspecified num"
    str2 = predef.initial_post(num: 237)
    lines = str2.split("\n")
    assert lines[2] == ".id 0237", "Expected 'num' to be filled in (found '#{lines[2]}')"
  end

  def test_013_find_theme_file
    repo = create_test_repo
    t = Scriptorium::Theme.new(repo.root, "standard")

    path1 = t.file("initial/post.lt3")
    want1 = "./scriptorium-TEST/themes/standard/initial/post.lt3"
    assert path1 == want1, "Expected: #{want1}"
    path2 = t.file("right.txt")
    want2 = "./scriptorium-TEST/themes/standard/layout/config/right.txt"
    assert path2 == want2, "Expected: #{want2}"

    assert_raises(MoreThanOneResult) { t.file("post.lt3") }
  end

  def test_014_check_post_template
    repo = create_test_repo
    root = repo.root
    file = "#{root}/themes/standard/templates/post.lt3" # FIXME hardcoded
    assert_file_exist?(file)
    assert_file_lines(file, 13)
  end

  def test_015_change_view
    repo = create_test_repo
    root = repo.root

    v1 = repo.view   # initially 'sample'
    assert v1.name == 'sample', "Expected view to be 'sample'"

    vname = "testing"
    t0 = repo.view_exist?(vname)
    refute t0, "View should not exist yet"

    repo.create_view(vname, "My Title", "Nothing here")  # testing
    v2 = repo.view
    assert v2.name == 'testing', "Expected view to be 'sample'"

    v3 = repo.view('sample')
    assert v3.name == 'sample', "Expected view to be 'sample'"

    v4 = repo.view('testing')
    assert v4.name == 'testing', "Expected view to be 'sample'"
  end

  def test_016_lookup_view
    repo = create_test_repo
    root = repo.root
    v0 = repo.lookup_view('sample')
    assert v0.name == 'sample', "Expected view to be 'sample'"
    assert_raises(CannotLookupView) { repo.lookup_view('view99')}
    repo.create_view("newview", "My Title", "Nothing here")  # testing
    v2 = repo.view
    v3 = repo.lookup_view(v2.name)
    assert v3.name == v2.name, "Expected new view '#{v2.name}' found as '#{v3.name}"
  end

  def test_017_tree_method
    repo = create_test_repo
    repo.tree("/tmp/test-tree.txt")
    assert_file_exist?("/tmp/tree.txt")
    num = File.readlines("/tmp/tree.txt").size
    assert num > 0, "Tree file appears too short"  
  end

  def test_018_change_config
    cfg_file = "/tmp/myconfig.txt"
    File.open(cfg_file, "w") do |f|
      f.puts <<~EOS
        alpha foo  # nothing much
        beta  bar  # meh again
        gamma baz  # whatever
      EOS
    end
    change_config(cfg_file, "beta", "new-value")
    lines = File.readlines(cfg_file).map(&:chomp)
    assert lines[0] == "alpha foo  # nothing much",     "Expected alpha text"
    assert lines[1] == "beta  new-value  # meh again",  "Expected beta text"
    assert lines[2] == "gamma baz  # whatever",         "Expected gamma text"
  end

  def test_019_mock_vars_into_template
    title   = "This is my title"
    pubdate = "August 2, 2024"
    tags    = "history, journal, birthday"
    body    = 
      <<~EOS
      This is just a fake blog post.
    
      <p>
      If it had been an <i>actual</i> post, it
      might have said something.
  
      <p>
      That's all.
      EOS
    vars = {:"post.title" => title, :"post.pubdate" => pubdate, 
            :"post.tags" => tags,   :"post.body" => body}
    predef = Scriptorium::StandardFiles.new
    template = predef.post_template("standard")
    result = template % vars
    assert result =~ /August 2, 2024/
    File.open("/tmp/mock.html", "w") do |f|
      f.puts result
    end
    assert_file_lines("/tmp/mock.html", 21)
  end

  def test_020_check_html_stubs
    repo = create_test_repo
    panes = repo.root/:views/:sample/:output/:panes
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

  def test_021_check_layout_parsing
    repo = create_test_repo
    file = repo.root/:views/:sample/:config/"layout.txt"
    File.open(file, "w") do |f|
      f.puts <<~EOS
        main     # Center pane
        header
        left   15%
        right  20%  # Right sidebar
        footer
      EOS
    end
    results = repo.view.read_layout.keys
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
    assert_raises(LayoutHasUnknownTag) { repo.view.read_layout }

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
    assert_raises(LayoutHasDuplicateTags) { repo.view.read_layout }
  end

  def test_022_simple_generate_post
    repo = create_test_repo
    dname = repo.create_draft(title: "My first post", tags: %w[things stuff])
    body    = 
    <<~EOS
    This is just another fake blog post.

    <p>
    If it had been an _actual post, it might have 
    said something meaninful.

    <p>
    But here we are.
    EOS
    text = File.read(dname)
    text.sub!(/BEGIN HERE.../, body)
    write_file(dname, text)
    num = repo.finish_draft(dname)
    repo.generate_post(num)
    repo.tree("/tmp/tree.txt")
    assert_file_exist?(repo.root/:posts/d4(num)/"body.html")
    assert_file_exist?(repo.root/:posts/d4(num)/"meta.txt")
    assert_file_exist?(repo.root/:views/:sample/:output/:posts/"#{d4(num)}-my-first-post.html")
  end

  def test_read_commented_file
    # Setup: Create a temporary test config file
    test_file = "test_config.txt"
    File.open(test_file, "w") do |f|
      f.puts "# This is a comment"
      f.puts ""
      f.puts "header  20% # This is a header line with a comment"
      f.puts "footer  # This is a footer line with another comment"
      f.puts "# Another full-line comment"
      f.puts "main    # Main content area"
    end
  
    # Expected result: an array of non-comment lines, with comments stripped
    expected_result = ["header  20%", "footer", "main"]
  
    # Run the method
    result = read_commented_file(test_file)
  
    # Assert the result matches the expected array
    assert_equal expected_result, result
  
    # Cleanup: Delete the test config file
    File.delete(test_file)
  end
  
end
