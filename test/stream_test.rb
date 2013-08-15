require "test_helper"

class StreamTest < Test::Unit::TestCase
  include Evidence

  def test_stream
    s = stream([1, 2, 3, 4]) | even_number_filter
    assert_equal [2, 4], s.to_a
  end

  def test_stream_an_enumerator
    e = Enumerator.new do |y|
      c = 0
      loop do
        y << (c += 1)
      end
    end
    s = stream(e) | even_number_filter
    assert_equal [2, 4], s.first(2)
  end

  def test_counter_is_an_infinite_stream
    c = counter
    assert_equal [1, 2, 3, 4], c.first(4)
    assert_equal 5, c.first
    assert_equal 10000, c.first(10000).size
    assert !c.eos?
  end

  def test_pipe_infinite_stream
    s = counter | even_number_filter
    assert_equal [2, 4, 6, 8], s.first(4)
  end

  def test_take
    s = counter | even_number_filter
    assert_equal [2], s.take(1)
    assert_equal [4], s.take(1)
    assert_equal [6, 8], s.take(2)
  end

  def test_first
    s = counter | even_number_filter
    assert_equal 2, s.first
    assert_equal 4, s.first
    assert_equal [6, 8], s.first(2)
  end

  def test_stream_an_array
    s = stream([1, 2, 3])
    assert_equal 1, s.first
    assert_equal [2], s.take(1)
    assert !s.eos?
    assert_equal [3], s.to_a
    assert s.eos?

    s = stream([1, 2, 3, 4]) | even_number_filter
    assert_equal 2, s.first
    assert_equal [4], s.to_a
  end

  def test_pipe_a_stream
    s1 = stream([1, 2, 3])
    s2 = s1 | lambda{|b| b}
    assert_equal 1, s2.first
    assert !s2.eos?
    assert_equal [2], s2.take(1)
    assert !s2.eos?
    assert_equal [3], s2.to_a
    assert s2.eos?
  end

  def test_merge_streams_with_a_comparator
    s1 = stream([2, 3, 5])
    s2 = stream([1, 4, 6])
    s3 = merge_streams([s1, s2], lambda{|i1, i2| i1 <=> i2})
    assert_equal [1, 2, 3, 4], s3.first(4)
    assert !s3.eos?
    assert_equal [5, 6], s3.first(2)
    assert s3.eos?
  end

  def test_merged_stream_ignores_nil_value
    s1 = stream([2, nil, nil, nil, 3, 5])
    s2 = stream([1, 4, nil, nil, 6])
    s3 = merge_streams([s1, s2], lambda{|i1, i2| i1 <=> i2})

    assert_equal [1, 2, 3, 4], s3.first(4)
    assert_equal [5, 6], s3.first(2)
  end

  def test_file_stream
    s = stream(File.new(file('app2.log')))
    assert_equal 2, s.first(2).size
    assert !s.eos?
    assert_equal 1, s.to_a.size
    assert s.eos?
  end

  def test_file_stream_pipe
    s = stream(File.new(file('app2.log'))) | lambda {|output| lambda {|log| output[log] if log =~ /Completed/}}
    assert_equal 1, s.to_a.size
  end

  def test_merged_stream_pipe
    s1 = stream([2, 3, 5])
    s2 = stream([1, 4, 6])
    s3 = merge_streams([s1, s2], lambda{|i1, i2| i1 <=> i2})
    s4 = s3 | even_number_filter
    assert_equal [2, 4, 6], s4.to_a
  end

  def test_counter_pipe
    stream = counter | even_number_filter
    assert_equal [2, 4], stream.first(2)
  end

  def test_pipe_multiple_streams
    stream = stream([1, 2, 3, 4, 5, 6]) | even_number_filter | pick_numbers([4])
    assert_equal [4], stream.to_a
  end

  def test_stream_each_should_process_and_output_same_element
    stream = stream([{k: 1}, {k: 2}]) | stream_each {|e| e[:k] += 1}
    assert_equal [{k: 2}, {k: 3}], stream.to_a
  end

  def test_stream_map_should_process_and_output_the_process_result
    stream = stream([{k: 1}, {k: 2}]) | stream_map {|e| e[:k] += 1}
    assert_equal [2, 3], stream.to_a
  end

  def test_stream_filter_and_select_should_output_filtered_element
    stream = stream([{k: 1}, {k: 2}]) | stream_filter {|e| e[:k] == 1}
    assert_equal [{k: 1}], stream.to_a

    stream = stream([{k: 1}, {k: 2}]) | stream_select {|e| e[:k] == 2}
    assert_equal [{k: 2}], stream.to_a
  end

  def test_chain_slice_stream_with_stream_map
    stream = stream([1, 2, 3, 4]) | slice_stream(2) {|s| s[:stream].to_a} | stream_map {|ns| ns.reduce(:+)}
    assert_equal [3, 7], stream.to_a
  end

  def pick_numbers(numbers)
    lambda{|output| lambda {|d| output.call(d) if numbers.include?(d)}}
  end

  def even_number_filter
    lambda{|output| lambda {|d| output.call(d) if d % 2 == 0}}
  end

end
