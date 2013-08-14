require "test_helper"
require 'time'

class LittlesLawAnalysisTest < Test::Unit::TestCase
  include Evidence
  def test_calculate
    start = Time.parse('2013-01-01 00:00:00')
    result = stream(data_stream) | slice_stream(lambda {|action| action[:request][:timestamp]}, 60) | littles_law_analysis
    expected = [[start..(start + 60), 1.0 * 2],
                [(start + 60)..(start + 120), 1.0 * (2 + 4)/2],
                [(start + 120)..(start + 180), 0.5 * 4]]
    assert_equal expected, result.to_a
  end

  def data_stream
    data = []
    start = Time.parse('2013-01-01 00:00:00')
    60.times do |i|
      data << {request: {timestamp: (start + i)}, response: {completed_time: 2000}}
    end
    start = Time.parse('2013-01-01 00:01:00')
    60.times do |i|
      data << {request: {timestamp: (start + i)}, response: {completed_time: 2000 + (i / 30) * 2000}}
    end
    start = Time.parse('2013-01-01 00:02:00')
    30.times do |i|
      data << {request: {timestamp: (start + i * 2)}, response: {completed_time: 4000}}
    end
    data
  end
end
