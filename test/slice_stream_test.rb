require "test_helper"
require 'time'

class SliceStreamTest < Test::Unit::TestCase
  include Evidence
  def test_slice_stream_by_index_proc_and_one_step
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 1)

    range, slice = stream.first
    assert_equal start..(start + 1), range
    assert_equal start, slice.first[:request][:timestamp]
    assert_equal 0, slice.count

    range, slice = stream.first
    assert_equal (start + 1)..(start + 2), range
    assert_equal start + 1, slice.first[:request][:timestamp]
    assert_equal 0, slice.count
  end

  def test_slice_stream_by_index_proc_and_steps
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 3)
    range, slice = stream.first
    assert_equal start..(start + 3), range
    assert_equal 3, slice.count

    range, slice = stream.first
    assert_equal (start + 3)..(start + 6), range
    assert_equal 3, slice.count
  end

  def test_slice_stream_by_index_proc_and_steps_proc
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, lambda{|start_index| start_index + 3})
    range, slice = stream.first
    assert_equal start..(start + 3), range
    assert_equal 3, slice.count

    range, slice = stream.first
    assert_equal (start + 3)..(start + 6), range
    assert_equal 3, slice.count
  end

  def test_slice_stream_by_index_proc_and_steps_and_start_index
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 3, start + 2)

    range, slice = stream.first
    slice = slice.to_a
    assert_equal (start + 2)..(start + 2 + 3), range
    assert_equal 3, slice.count
    assert_equal start + 2, slice[0][:request][:timestamp]
    assert_equal start + 3, slice[1][:request][:timestamp]
    assert_equal start + 4, slice[2][:request][:timestamp]

    range, slice = stream.first
    slice = slice.to_a
    assert_equal (start + 2 + 3)..(start + 2 + 3 + 3), range
    assert_equal 3, slice.count
    assert_equal start + 5, slice[0][:request][:timestamp]
    assert_equal start + 6, slice[1][:request][:timestamp]
    assert_equal start + 7, slice[2][:request][:timestamp]
  end

  def test_slice_stream_that_is_sliced
    start = Time.parse('2013-01-01 00:00:00')
    data = requests(start, 50)
    stream = stream(data) | slice_stream(lambda {|action| action[:request][:timestamp]}, 6)
    range, slice = stream.first
    stream2 = slice | slice_stream(lambda {|action| action[:request][:timestamp]}, 2)
    range, slice2 = stream2.first
    assert_equal 2, slice2.to_a.size
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

  def requests(start, seconds)
    data = []
    seconds.times do |i|
      data << {request: {timestamp: (start + i)}}
    end
    data
  end
end