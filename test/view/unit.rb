require 'minitest/autorun'

require_relative '../../lib/scriptorium'
require_relative '../../lib/view'

class TestView< Minitest::Test

  include Scriptorium::Exceptions

  def setup
    @repo = Scriptorium.create(true)
    @name = "myview"
  end

  def teardown
  end

  def test_view_create
    puts __method__
    t0 = View.exist?(@name)
    refute t0, "View should not exist yet"

    View.create(@name, "My Title", "Just a subtitle here")  # testing

    t1 = View.exist?(@name)
    assert t1, "View should exist"

    # Add check: already exists
  end

end
