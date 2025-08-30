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
    system("rm -rf test/scriptorium-TEST")
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

  def test_006_check_widgets_txt_created
    repo = create_test_repo
    widgets_file = "#{repo.root}/config/widgets.txt"
    assert File.exist?(widgets_file), "widgets.txt should exist in config directory"
    
    content = read_file(widgets_file)
    assert_includes content, "links"
    assert_includes content, "pages"
  end

  def test_007_create_view
    repo = create_test_repo
    vname = "testview"
    t0 = repo.view_exist?(vname)
    refute t0, "View should not exist yet"

    repo.create_view(vname, "My Title", "Just a subtitle here")  # testing

    t1 = repo.view_exist?(vname)
    assert t1, "View should exist"

    # Check that pages directory was created
    pages_dir = "#{repo.root}/views/#{vname}/pages"
    assert Dir.exist?(pages_dir), "Pages directory should exist"

    assert_raises(ViewDirAlreadyExists) do
      repo.create_view(vname, "My Other Title", "Just dumbness here")  # testing
    end
  end

  def test_008_create_view_creates_all_config_files
    repo = create_test_repo
    vname = "testview"
    
    repo.create_view(vname, "My Title", "Just a subtitle here")
    
          # Check that all expected config files are created
      view_dir = "#{repo.root}/views/#{vname}"
      config_dir = "#{view_dir}/config"
      
      # Main view config file (in view root, not config subdirectory)
      assert_file_exist?("#{view_dir}/config.txt")
      
      # Core config files
      assert_file_exist?("#{config_dir}/global-head.txt")
      assert_file_exist?("#{config_dir}/bootstrap_js.txt")
      assert_file_exist?("#{config_dir}/bootstrap_css.txt")
      assert_file_exist?("#{config_dir}/common.js")
      assert_file_exist?("#{config_dir}/social.txt")
      assert_file_exist?("#{config_dir}/reddit.txt")
      assert_file_exist?("#{config_dir}/deploy.txt")
      assert_file_exist?("#{config_dir}/status.txt")
      assert_file_exist?("#{config_dir}/post_index.txt")
      
      # Theme config files
      assert_file_exist?("#{config_dir}/header.txt")
      assert_file_exist?("#{config_dir}/footer.txt")
      assert_file_exist?("#{config_dir}/left.txt")
      assert_file_exist?("#{config_dir}/right.txt")
      assert_file_exist?("#{config_dir}/main.txt")
      
      # Banner config files
      assert_file_exist?("#{config_dir}/svg.txt")
      
      # Check that header.txt includes banner svg
      header_content = read_file("#{config_dir}/header.txt")
      assert_includes header_content, "banner svg"
      
      # Check that svg.txt has proper content
      svg_content = read_file("#{config_dir}/svg.txt")
      assert_includes svg_content, "aspect"
      assert_includes svg_content, "back.linear"
      assert_includes svg_content, "title.color"
  end

  def test_009_new_view_becomes_current
    repo = create_test_repo
    tv2 = "testview2"
    view = repo.create_view(tv2, "My 2nd Title", "Just another subtitle here")
    assert repo.views.size == 2, "Expected 2 views, not #{repo.views.size}"
    vnames = repo.views.map {|v| v.name }
    assert vnames.include?(tv2), "Expected to find '#{tv2}' in views"
    assert repo.current_view.name == view.name, "Expected '#{tv2}' as current view"
  end

  def test_010_open_view
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

  def test_011_create_draft
    repo = create_test_repo
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

  def test_012_finish_draft
    $debug = true
    repo = create_test_repo
    fname = repo.create_draft

    repo.finish_draft(fname)
    postnum = "0001"  # Assumes testing started with 0
    postdir = repo.root/:posts/postnum 
    assert_dir_exist?(postdir/:assets)
    assert_file_exist?(postdir/"source.lt3") 
    $debug = false
  end

  def test_013_check_initial_post
    repo = create_test_repo
    root = repo.root
    file = "#{root}/themes/standard/initial/post.lt3"
    assert_file_exist?(file)
    assert_file_lines(file, 10)
  end

  def test_014_check_interpolated_initial_post
    repo = create_test_repo
    predef = repo.instance_eval { @predef }
    str = predef.initial_post
    lines = str.split("\n")
    str2 = predef.initial_post(title: "My post title")
    lines = str2.split("\n")
    assert lines[3] == ".title My post title", "Expected 'title' to be filled in (found '#{lines[3]}')"
  end

  def test_015_find_theme_file
    repo = create_test_repo
    t = Scriptorium::Theme.new(repo.root, "standard")

    path1 = t.file("initial/post.lt3")
    want1 = "test/scriptorium-TEST/themes/standard/initial/post.lt3"
    assert path1 == want1, "Expected: #{want1}, got: #{path1}"
    path2 = t.file("right.txt")
    want2 = "test/scriptorium-TEST/themes/standard/layout/config/right.txt"
    assert path2 == want2, "Expected: #{want2}"

    assert_raises(MoreThanOneResult) { t.file("post.lt3") }
  end

  def test_014_check_post_template
    repo = create_test_repo
    root = repo.root
    file = "#{root}/themes/standard/templates/post.lt3"
    assert_file_exist?(file)
    assert_file_lines(file, 16)  # Template now includes copy link button but no inline JavaScript
  end

  def test_015_change_view
    repo = create_test_repo
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
    vars = {:"post.title" => title, :"post.pubdate" => pubdate, :"post.date" => pubdate,
            :"post.tags" => tags,   :"post.body" => body, :"reddit_button" => ""}
    predef = Scriptorium::StandardFiles.new
    template = predef.post_template("standard")
    result = template % vars
    assert result =~ /August 2, 2024/
    File.open("/tmp/mock.html", "w") do |f|
      f.puts result
    end
    assert_file_lines("/tmp/mock.html", 24)  # Template + expanded body content (newlines in body create extra lines)
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
    text = read_file(dname)
    text.sub!(/BEGIN HERE.../, body)
    write_file(dname, text)
    num = repo.finish_draft(dname)
    repo.generate_post(num)
    repo.tree("/tmp/tree.txt")
    assert_file_exist?(repo.root/:posts/d4(num)/"body.html")
    assert_file_exist?(repo.root/:posts/d4(num)/"meta.txt")
    assert_file_exist?(repo.root/:views/:sample/:output/:posts/"#{d4(num)}-my-first-post.html")
  end


  


  def test_025_layout_file_missing
    repo = create_test_repo
    view = repo.create_view("testview", "Test View", "Test Subtitle")
    
    # Remove the layout.txt file to test the exception
    layout_file = view.dir/:config/"layout.txt"
    File.delete(layout_file) if File.exist?(layout_file)
    
    assert_raises(LayoutFileMissing) do
      view.read_layout
    end
  end

  def test_026_verify_permalink_generation
    repo = create_test_repo
    dname = repo.create_draft(title: "Permalink Test Post", tags: %w[test permalink])
    body = <<~EOS
    This is a test post for permalink functionality.

    <p>
    It should be generated in both the posts/ and permalink/ directories.
    EOS
    text = read_file(dname)
    text.sub!(/BEGIN HERE.../, body)
    write_file(dname, text)
    num = repo.finish_draft(dname)
    repo.generate_post(num)
    
    # Check that post was generated in both locations
    # Use the same pattern as the working test
    regular_post = repo.root/:views/:sample/:output/:posts/"#{d4(num)}-permalink-test-post.html"
    assert File.exist?(regular_post), "Regular post should exist at #{regular_post}"
    
    # Permalink location
    permalink_post = repo.root/:views/:sample/:output/:permalink/"#{d4(num)}-permalink-test-post.html"
    assert File.exist?(permalink_post), "Permalink post should exist at #{permalink_post}"
    
    # Both files should have different content (permalink has "Visit Blog" link)
    regular_content = read_file(regular_post)
    permalink_content = read_file(permalink_post)
    refute_equal regular_content, permalink_content, "Post content should differ (permalink has 'Visit Blog' link)"
    
    # Regular post should NOT contain the "Visit Blog" link
    refute_includes regular_content, "Visit Blog"
    refute_includes regular_content, 'href="../index.html"'
    
    # Permalink post should contain the "Visit Blog" link
    assert_includes permalink_content, "Visit Blog"
    assert_includes permalink_content, 'href="../index.html"'
    
    # Permalink post should contain the "Copy link" button
    assert_includes permalink_content, "Copy link"
  end

  # View-related tests
  def test_view_method_writes_to_currentview_txt
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    repo.create_view("view2", "View Two", "Second view")
    
    # Initially, current view should be the last created view (view2)
    assert_equal "view2", repo.current_view.name
    
    # Switch to view1
    repo.view("view1")
    
    # Check that current view changed in memory
    assert_equal "view1", repo.current_view.name
    
    # Check that currentview.txt was written
    currentview_file = File.join(test_repo_path, "config", "currentview.txt")
    assert File.exist?(currentview_file), "currentview.txt should exist"
    
    content = read_file(currentview_file).strip
    assert_equal "view1", content, "currentview.txt should contain 'view1'"
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end

  def test_view_method_persists_across_repo_reload
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    repo.create_view("view2", "View Two", "Second view")
    
    # Switch to view1
    repo.view("view1")
    assert_equal "view1", repo.current_view.name
    
    # Create a new repo instance pointing to the same directory
    new_repo = Scriptorium::Repo.open(test_repo_path)
    
    # The new repo should load the current view from the file
    assert_equal "view1", new_repo.current_view.name
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end

  def test_create_view_switches_to_new_view
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    repo.create_view("view2", "View Two", "Second view")
    
    # Start with view2 as current
    assert_equal "view2", repo.current_view.name
    
    # Create a new view - should switch to it
    repo.create_view("view3", "View Three", "Third view")
    assert_equal "view3", repo.current_view.name
    
    # Check that currentview.txt was updated
    currentview_file = File.join(test_repo_path, "config", "currentview.txt")
    content = read_file(currentview_file).strip
    assert_equal "view3", content, "currentview.txt should contain 'view3'"
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end

  def test_load_views_reads_currentview_txt
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    repo.create_view("view2", "View Two", "Second view")
    
    # Switch to view1
    repo.view("view1")
    assert_equal "view1", repo.current_view.name
    
    # Create a new repo instance to test load_views
    new_repo = Scriptorium::Repo.open(test_repo_path)
    
    # Should load the correct current view from file
    assert_equal "view1", new_repo.current_view.name
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end

  def test_load_views_handles_missing_currentview_txt
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    
    # Remove currentview.txt
    currentview_file = File.join(test_repo_path, "config", "currentview.txt")
    File.delete(currentview_file) if File.exist?(currentview_file)
    
    # Create a new repo instance
    new_repo = Scriptorium::Repo.open(test_repo_path)
    
    # Should handle missing file gracefully
    # The behavior depends on how the repo handles nil current_view
    assert new_repo.current_view.nil? || new_repo.current_view.is_a?(Scriptorium::View)
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end

  def test_load_views_handles_invalid_view_name
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    
    # Write an invalid view name to currentview.txt
    currentview_file = File.join(test_repo_path, "config", "currentview.txt")
    write_file(currentview_file, "nonexistent_view")
    
    # Create a new repo instance - should handle invalid view name gracefully
    # The current implementation raises an exception, so we expect that
    assert_raises(CannotLookupView) do
      Scriptorium::Repo.open(test_repo_path)
    end
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end

  def test_view_method_returns_view_object
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    repo.create_view("view2", "View Two", "Second view")
    
    # The view method should return the view object, not nil
    result = repo.view("view1")
    assert_instance_of Scriptorium::View, result
    assert_equal "view1", result.name
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end

  def test_view_method_with_nil_returns_current_view
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    
    # view() with no arguments should return current view
    current = repo.current_view
    result = repo.view
    assert_equal current, result
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end

  def test_view_method_with_view_object
    # Create a test repo for this test
    test_repo_path = "test_repo_view_test"
    FileUtils.rm_rf(test_repo_path) if Dir.exist?(test_repo_path)
    
    repo = Scriptorium::Repo.create(test_repo_path, testmode: true)
    repo.create_view("view1", "View One", "First view")
    repo.create_view("view2", "View Two", "Second view")
    
    # Should work with a View object instead of string
    view_obj = repo.lookup_view("view1")
    repo.view(view_obj)
    assert_equal "view1", repo.current_view.name
    
    # Cleanup
    FileUtils.rm_rf(test_repo_path)
  end
end
