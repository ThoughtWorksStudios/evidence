require "test_helper"

class EnumeratorLazyExtTest < Test::Unit::TestCase
  def test_compact
    assert_equal [1, 2], [1, nil, 2].lazy.compact.force
  end
end
