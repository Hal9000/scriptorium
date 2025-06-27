require 'minitest/autorun'

require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestScriptoriumRepo < Minitest::Test

  include Scriptorium::Exceptions
  include TestHelpers

  Repo = Scriptorium::Repo

  def setup
  end

  def teardown
    system("rm -rf scriptorium-TEST")
  end

  def test_001_version
    puts __method__
    ver = Scriptorium::VERSION
    pieces = ver.split(".")
    pieces.each do |num|
      assert num =~ /^\d+$/, "Invalid version '#{ver}'"
    end
  end

  def test_002_repo_create_destroy
    puts __method__
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
    puts __method__
    Repo.testing = false
    assert_raises(TestModeOnly) { Repo.destroy }
  end

  def test_004_repo_structure
    puts __method__
    create_test_repo
    root = Repo.root
    assert_dir_exist?(root/"config")
    assert_dir_exist?(root/"views")
    assert_dir_exist?(root/"views/sample")
    assert_dir_exist?(root/"posts")
    assert_dir_exist?(root/"posts/meta")
    assert_dir_exist?(root/"drafts")
    assert_dir_exist?(root/"themes")
    assert_dir_exist?(root/"themes/standard")
    assert_dir_exist?(root/"assets")
  end

  def test_005_check_sample_view
    puts __method__
    repo = create_test_repo
    assert repo.views.is_a?(Array), "Expected array of Views"
    assert repo.views.size == 1, "Expected one initial view"
    assert repo.views[0].name == "sample", "Expected to find view 'sample'"
    assert repo.current_view.name == "sample", "Expected current view to be 'sample'"
  end

  def test_006_create_view
    puts __method__
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
    puts __method__
    repo = create_test_repo
    tv2 = "testview2"
    view = repo.create_view(tv2, "My 2nd Title", "Just another subtitle here")
    assert repo.views.size == 2, "Expected 2 views, not #{repo.views.size}"
    vnames = repo.views.map {|v| v.name }
    assert vnames.include?(tv2), "Expected to find '#{tv2}' in views"
    assert repo.current_view.name == view.name, "Expected '#{tv2}' as current view"
  end

  def test_008_open_view
    puts __method__
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
    puts __method__
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
    puts __method__
    $debug = true
    repo = create_test_repo("testview")  # View should exist to create draft?
    fname = repo.create_draft

    repo.finish_draft(fname)
    postnum = "0001"  # Assumes testing started with 0
    postdir = repo.root/:posts/postnum 
    assert_dir_exist?(postdir/:assets)
    assert_file_exist?(postdir/"meta.lt3") 
    assert_file_exist?(postdir/"draft.lt3") 
    $debug = false
  end

  def test_011_check_initial_post
    puts __method__
    repo = create_test_repo
    root = repo.root
    file = "#{root}/themes/standard/initial/post.lt3" # FIXME hardcoded
    assert_file_exist?(file)

    lines = File.readlines(file)
    assert lines.size == 13, "Expected 13 lines in initial post"
  end

  def test_012_check_interpolated_initial_post
    puts __method__
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
    puts __method__
    repo = create_test_repo
    t = Scriptorium::Theme.new(repo.root, "standard")

    path1 = t.file("initial/post.lt3")
    want1 = "scriptorium-TEST/themes/standard/initial/post.lt3"
    assert path1 == want1, "Expected: #{want1}"

    path2 = t.file("config.lt3")
    want2 = "scriptorium-TEST/themes/standard/config.lt3"
    assert path2 == want2, "Expected: #{want2}"

    path3 = t.file("sidebar.lt3")
    want3 = "scriptorium-TEST/themes/standard/partials/sidebar.lt3"
    assert path3 == want3, "Expected: #{want3}"

    assert_raises(MoreThanOneResult) { t.file("post.lt3") }
  end

  def test_014_check_post_template
    puts __method__
    repo = create_test_repo
    root = repo.root
    file = "#{root}/themes/standard/templates/post.lt3" # FIXME hardcoded
    assert_file_exist?(file)

    lines = File.readlines(file)
    assert lines.size == 8, "Expected 8 lines in initial post"
  end

  def test_015_change_view
    puts __method__
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
    puts __method__
    repo = create_test_repo
    root = repo.root
    v0 = repo.lookup_view('sample')
    assert v0.name == 'sample', "Expected view to be 'sample'"
    assert_raises(CannotLookupView) { repo.lookup_view('view99')}

  end

end
