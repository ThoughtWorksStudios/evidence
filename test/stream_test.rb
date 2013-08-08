require "test_helper"

class StreamTest < Test::Unit::TestCase
  def test_stream
    s = Evidence.stream([1, 2, 3, 4], simple_number_processor)
    assert_equal [3, 5], s.to_a
  end

  def test_counter_is_an_infinite_stream
    assert_equal [1, 2, 3, 4], Evidence.counter.first(4)
    assert_equal 10000, Evidence.counter.first(10000).size
  end

  def test_stream_infinite_upstream
    s = Evidence.stream(Evidence.counter, simple_number_processor)
    assert_equal [3, 5, 7, 9], s.first(4)
  end

  def simple_number_processor
    lambda{|block| lambda {|data| block.call(data + 1) if data % 2 == 0}}
  end
end