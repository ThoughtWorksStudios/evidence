require "test_helper"
require 'time'

class SliceStreamTest < Test::Unit::TestCase
  include Evidence
  def test_slice_stream_by_index_proc_and_one_step
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 1)

    slice = stream.first
    assert_equal start..(start + 1), slice[:range]
    assert_equal start, slice[:stream].first[:request][:timestamp]
    assert_equal 0, slice[:stream].count

    slice = stream.first
    assert_equal (start + 1)..(start + 2), slice[:range]
    assert_equal start + 1, slice[:stream].first[:request][:timestamp]
    assert_equal 0, slice[:stream].count
  end

  def test_slice_stream_by_index_proc_and_steps
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 3)
    slice = stream.first
    assert_equal start..(start + 3), slice[:range]
    assert_equal 3, slice[:stream].count

    slice = stream.first
    assert_equal (start + 3)..(start + 6), slice[:range]
    assert_equal 3, slice[:stream].count
  end

  def test_slice_stream_by_index_proc_and_steps_proc
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, lambda{|start_index| start_index + 3})
    slice = stream.first
    assert_equal start..(start + 3), slice[:range]
    assert_equal 3, slice[:stream].count

    slice = stream.first
    assert_equal (start + 3)..(start + 6), slice[:range]
    assert_equal 3, slice[:stream].count
  end

  def test_slice_stream_by_index_proc_and_steps_and_start_index
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 3, start + 2)

    slice = stream.first
    assert_equal (start + 2)..(start + 2 + 3), slice[:range]
    slice = slice[:stream].to_a
    assert_equal 3, slice.count
    assert_equal start + 2, slice[0][:request][:timestamp]
    assert_equal start + 3, slice[1][:request][:timestamp]
    assert_equal start + 4, slice[2][:request][:timestamp]

    slice = stream.first
    assert_equal (start + 2 + 3)..(start + 2 + 3 + 3), slice[:range]
    slice = slice[:stream].to_a
    assert_equal 3, slice.count
    assert_equal start + 5, slice[0][:request][:timestamp]
    assert_equal start + 6, slice[1][:request][:timestamp]
    assert_equal start + 7, slice[2][:request][:timestamp]
  end

  def test_slice_stream_that_is_sliced
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 6)
    slice = stream.first
    stream2 = slice[:stream] | slice_stream(lambda {|action| action[:request][:timestamp]}, 2)
    slice2 = stream2.first
    assert_equal 2, slice2[:stream].to_a.size
  end

  def test_should_not_over_slice_the_stream
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 4)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 2)
    assert stream.first
    assert stream.first
    assert_nil stream.first
    assert stream.eos?
  end

  def test_prev_slice_stream_should_be_empty_if_we_jump_to_process_next_slice_stream
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 4)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 2)
    slice1 = stream.first
    slice2 = stream.first
    assert_equal 0, slice1[:stream].count
    assert_equal 2, slice2[:stream].count
  end

  def requests(start, seconds)
    data = []
    seconds.times do |i|
      data << {request: {timestamp: (start + i)}}
    end
    data
  end
end