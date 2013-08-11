require "test_helper"

class StreamTest < Test::Unit::TestCase
  def test_stream
    s = Evidence.stream([1, 2, 3, 4]) | even_number_filter
    assert_equal [2, 4], s.to_a
  end

  def test_counter_is_an_infinite_stream
    counter = Evidence.counter
    assert_equal [1, 2, 3, 4], counter.first(4)
    assert_equal 5, counter.first
    assert_equal 10000, Evidence.counter.first(10000).size
    assert !counter.eos?
  end

  def test_pipe_infinite_stream
    s = Evidence.counter | even_number_filter
    assert_equal [2, 4, 6, 8], s.first(4)
  end

  def test_take
    s = Evidence.counter | even_number_filter
    assert_equal [2], s.take(1)
    assert_equal [4], s.take(1)
    assert_equal [6, 8], s.take(2)
  end

  def test_first
    s = Evidence.counter | even_number_filter
    assert_equal 2, s.first
    assert_equal 4, s.first
    assert_equal [6, 8], s.first(2)
  end

  def test_stream_an_array
    s = Evidence.stream([1, 2, 3])
    assert_equal 1, s.first
    assert_equal [2], s.take(1)
    assert !s.eos?
    assert_equal [3], s.to_a
    assert s.eos?

    s = Evidence.stream([1, 2, 3, 4]) | even_number_filter
    assert_equal 2, s.first
    assert_equal [4], s.to_a
  end

  def test_pipe_a_stream
    s1 = Evidence.stream([1, 2, 3])
    s2 = s1 | lambda{|b| b}
    assert_equal 1, s2.first
    assert !s2.eos?
    assert_equal [2], s2.take(1)
    assert !s2.eos?
    assert_equal [3], s2.to_a
    assert s2.eos?
  end

  def test_merge_streams_with_a_comparator
    s1 = Evidence.stream([2, 3, 5])
    s2 = Evidence.stream([1, 4, 6])
    s3 = Evidence.merge_streams([s1, s2], lambda{|i1, i2| i1 <=> i2})
    assert_equal [1, 2, 3, 4], s3.first(4)
    assert !s3.eos?
    assert_equal [5, 6], s3.first(2)
    assert s3.eos?
  end

  def test_merged_stream_ignores_nil_value
    s1 = Evidence.stream([2, nil, nil, nil, 3, 5])
    s2 = Evidence.stream([1, 4, nil, nil, 6])
    s3 = Evidence.merge_streams([s1, s2], lambda{|i1, i2| i1 <=> i2})

    assert_equal [1, 2, 3, 4], s3.first(4)
    assert_equal [5, 6], s3.first(2)
  end

  def test_file_stream
    s = Evidence.stream(File.new(file('app2.log')))
    assert_equal 2, s.first(2).size
    assert !s.eos?
    assert_equal 1, s.to_a.size
    assert s.eos?
  end

  def test_file_stream_pipe
    s = Evidence.stream(File.new(file('app2.log'))) | lambda {|output| lambda {|log| output[log] if log =~ /Completed/}}
    assert_equal 1, s.to_a.size
  end

  def test_merged_stream_pipe
    s1 = Evidence.stream([2, 3, 5])
    s2 = Evidence.stream([1, 4, 6])
    s3 = Evidence.merge_streams([s1, s2], lambda{|i1, i2| i1 <=> i2})
    s4 = s3 | even_number_filter
    assert_equal [2, 4, 6], s4.to_a
  end

  def test_counter_pipe
    counter = Evidence.counter
    stream = counter | even_number_filter
    assert_equal [2, 4], stream.first(2)
  end

  def test_pipe_multiple_streams
    stream = Evidence.stream([1, 2, 3, 4, 5, 6]) | even_number_filter | pick_numbers([4])
    assert_equal [4], stream.to_a
  end

  def pick_numbers(numbers)
    lambda{|block| lambda {|d| block.call(d) if numbers.include?(d)}}
  end

  def even_number_filter
    lambda{|block| lambda {|d| block.call(d) if d % 2 == 0}}
  end

end
