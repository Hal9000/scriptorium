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

  def test_005_create_view
    puts __method__
    repo = create_test_repo
    vname = "testview"
    t0 = repo.view_exist?(vname)
    refute t0, "View should not exist yet"

    repo.create_view(vname, "My Title", "Just a subtitle here")  # testing

    t1 = repo.view_exist?(vname)
    assert t1, "View should exist"

    # Add check: already exists
  end

  def test_006_open_view
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
    # FIXME finish
  end

  def test_007_create_draft
    puts __method__
    repo = create_test_repo("testview")  # View should exist to create draft?
    fname = repo.create_draft
    assert_file_exist?(fname)
  end

  def test_008_publish_draft
    puts __method__
    $debug = true
    repo = create_test_repo("testview")  # View should exist to create draft?
    fname = repo.create_draft

    repo.publish_draft(fname)
    postnum = "0001"  # Assumes testing started with 0
    postdir = repo.root/:posts/postnum 
    assert_dir_exist?(postdir/:assets)
    assert_file_exist?(postdir/"meta.lt3") 
    assert_file_exist?(postdir/"draft.lt3") 
    $debug = false
  end

  def test_009_check_initial_post_template
    puts __method__
    create_test_repo
    root = Repo.root
    file = "#{root}/themes/standard/post_template.lt3"
    assert_file_exist?(file)

    lines = File.readlines(file)
    assert lines.size == 13, "Expected 13 lines in post template"
  end

  def test_010_check_interpolated_post_template
    puts __method__
    repo = create_test_repo
    predef = repo.instance_eval { @predef }
    str = predef.post_template
    lines = str.split("\n")
    assert lines[2] == ".id 0000", "Expected '.id 0000' with unspecified num"
    str2 = predef.post_template(num: 237)
    lines = str2.split("\n")
    assert lines[2] == ".id 0237", "Expected 'num' to be filled in (found '#{lines[2]}')"
  end

end
