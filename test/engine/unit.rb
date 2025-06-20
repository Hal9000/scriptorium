require 'minitest/autorun'

require_relative '../../lib/scriptorium'

class TestScriptoriumEngine < Minitest::Test

  # TestModeOnly = Scriptorium::TestModeOnly
  include Scriptorium::Exceptions

  def setup
  end

  def teardown
    root = Scriptorium.root
    puts "root = #{root}"
  end

  def test_version
    ver = Scriptorium::VERSION
    pieces = ver.split(".")
    pieces.each do |num|
      assert num =~ /^\d+$/, "Invalid version '#{ver}'"
    end
  end

  def test_repo_create_destroy
    puts __method__
    t0 = Scriptorium.exist?
    refute t0, "Repo should not exist yet"

    Scriptorium.create(true)  # testing

    t1 = Scriptorium.exist?
    assert t1, "Repo should exist"

    Scriptorium.destroy

    t2 = Scriptorium.exist?
    refute t2, "Repo should have been destroyed"
  end

  def test_illegal_destroy
    puts __method__
    Scriptorium.testing = false
    assert_raises(TestModeOnly) { Scriptorium.destroy }
  end

end
