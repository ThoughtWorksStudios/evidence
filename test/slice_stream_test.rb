require "test_helper"
require 'time'

class SliceStreamTest < Test::Unit::TestCase
  include Evidence
  def test_slice_stream_by_one_step_and_index_proc
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(1, lambda {|action| action[:request][:timestamp]}) do |slice|
      [slice[:range], slice[:stream].map{|action| action[:request][:timestamp]}]
    end

    range, slice = stream.first
    assert_equal start..(start + 1), range
    assert_equal start, slice.first
    assert_equal 1, slice.count

    range, slice = stream.first
    assert_equal (start + 1)..(start + 2), range
    assert_equal start + 1, slice.first
    assert_equal 1, slice.count
  end

  def test_slice_stream_by_steps
    stream = stream([1, 2, 3, 4, 5, 6, 7]) | slice_stream(3) {|slice| [slice[:range], slice[:stream].to_a]}
    range, slice = stream.first
    assert_equal 1..4, range
    assert_equal 3, slice.count

    range, slice = stream.first
    assert_equal 4..7, range
    assert_equal 3, slice.count
  end

  def test_slice_stream_by_steps_proc
    stream = stream([1, 2, 3, 4, 5, 6, 7]) | slice_stream(lambda{|start_index| start_index + 3 }) {|slice| [slice[:range], slice[:stream].to_a]}
    range, slice = stream.first
    assert_equal 1..4, range
    assert_equal 3, slice.count

    range, slice = stream.first
    assert_equal 4..7, range
    assert_equal 3, slice.count
  end

  def test_slice_stream_by_index_proc_and_steps_and_start_index
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(3, lambda {|action| action[:request][:timestamp]}, start + 2) {|slice| [slice[:range], slice[:stream].to_a]}

    range, slice = stream.first
    assert_equal (start + 2)..(start + 2 + 3), range
    assert_equal 3, slice.count
    assert_equal start + 2, slice[0][:request][:timestamp]
    assert_equal start + 3, slice[1][:request][:timestamp]
    assert_equal start + 4, slice[2][:request][:timestamp]

    range, slice = stream.first
    assert_equal (start + 2 + 3)..(start + 2 + 3 + 3), range
    assert_equal 3, slice.count
    assert_equal start + 5, slice[0][:request][:timestamp]
    assert_equal start + 6, slice[1][:request][:timestamp]
    assert_equal start + 7, slice[2][:request][:timestamp]
  end

  def test_slice_stream_that_is_sliced
    stream = stream([1, 2, 3, 4, 5, 6, 7]) | slice_stream(4) do |slice|
                      subslice = slice[:stream] | slice_stream(2) {|slice| [slice[:range], slice[:stream].to_a]}
                      subslice.to_a
                    end
    slice1_result = stream.first
    assert_equal [[1..3, [1, 2]], [3..5, [3, 4]]], slice1_result
    slice2_result = stream.first
    assert_equal [[5..7, [5, 6]], [7..9, [7]]], slice2_result
  end

  def test_should_not_over_slice_the_stream
    stream = stream([1, 2, 3, 4]) | slice_stream(2) {|s| s}
    assert stream.first
    assert !stream.eos?
    assert stream.first
    assert_nil stream.first
    assert stream.eos?
  end

  def test_slice_correct_when_only_process_some_slices
    count = 0
    stream = stream([1, 2, 3, 4]) | slice_stream(2) do |s|
      count += 1
      if count == 2
        s[:stream].to_a
      else
        count
      end
    end
    assert_equal 1, stream.first
    assert_equal [3, 4], stream.first
    assert stream.eos?
    assert_nil stream.first
  end

  def requests(start, seconds)
    data = []
    seconds.times do |i|
      data << {request: {timestamp: (start + i)}}
    end
    data
  end
end
