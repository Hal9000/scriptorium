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

    Repo.create(true)  # testing

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
    Repo.create(true)  # testing
    root = Repo.root
    dir_exist?("#{root}/config")
    dir_exist?("#{root}/views")
    dir_exist?("#{root}/views/sample")
    dir_exist?("#{root}/posts")
    dir_exist?("#{root}/posts/meta")
    dir_exist?("#{root}/drafts")
    dir_exist?("#{root}/themes")
    dir_exist?("#{root}/themes/standard")
    dir_exist?("#{root}/assets")
  end

  def test_005_create_view
    puts __method__
    repo = Repo.create(true)  # testing
    name = "myview"
    t0 = repo.view_exist?(name)
    refute t0, "View should not exist yet"

    repo.create_view(name, "My Title", "Just a subtitle here")  # testing

    t1 = repo.view_exist?(name)
    assert t1, "View should exist"

    # Add check: already exists
  end

  def test_006_open_view
    puts __method__
    repo = Repo.create(true)  # testing
    name = "myview2"
    repo.create_view(name, "My Awesome Title", "Just another subtitle")
    t0 = repo.view_exist?(name)
    assert t0, "View should exist"

    repo.open_view(name)
  end

end
