require "test_helper"

class StreamTest < Test::Unit::TestCase
  def test_stream
    s = Evidence.stream([1, 2, 3, 4], even_number_filter)
    assert_equal [2, 4], s.to_a
  end

  def test_counter_is_an_infinite_stream
    counter = Evidence.counter
    assert_equal [1, 2, 3, 4], counter.first(4)
    assert_equal 5, counter.first
    assert_equal 10000, Evidence.counter.first(10000).size
  end

  def test_stream_infinite_upstream
    s = Evidence.stream(Evidence.counter, even_number_filter)
    assert_equal [2, 4, 6, 8], s.first(4)
  end

  def test_take
    s = Evidence.stream(Evidence.counter, even_number_filter)
    assert_equal [2], s.take(1)
    assert_equal [4], s.take(1)
    assert_equal [6, 8], s.take(2)
  end

  def test_first
    s = Evidence.stream(Evidence.counter, even_number_filter)
    assert_equal 2, s.first
    assert_equal 4, s.first
    assert_equal [6, 8], s.first(2)
  end

  def test_stream_an_array
    s = Evidence.stream([1, 2, 3])
    assert_equal 1, s.first
    assert_equal [2], s.take(1)
    assert_equal [3], s.to_a

    s = Evidence.stream([1, 2, 3, 4], even_number_filter)
    assert_equal 2, s.first
    assert_equal [4], s.to_a
  end

  def test_stream_a_stream
    s1 = Evidence.stream([1, 2, 3])
    s2 = Evidence.stream(s1)
    assert_equal 1, s2.first
    assert_equal [2], s2.take(1)
    assert_equal [3], s2.to_a
  end

  def test_merge_streams_with_a_comparator
    s = Evidence.stream(Evidence.counter, even_number_filter)
    s1 = Evidence.stream([2, 3, 5], yield_number_processor)
    s2 = Evidence.stream([1, 4, 6], yield_number_processor)
    s3 = s1.merge(s2, lambda{|i1, i2| i1 <=> i2})
    assert_equal [1, 2, 3, 4], s3.first(4)
  end

  def even_number_filter
    lambda{|block| lambda {|data| block.call(data) if data % 2 == 0}}
  end

  def yield_number_processor
    lambda{|b| lambda {|i| b[i]}}
  end
end
