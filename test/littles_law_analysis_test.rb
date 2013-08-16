require "test_helper"
require 'time'

class LittlesLawAnalysisTest < Test::Unit::TestCase
  include Evidence
  def test_calculate
    start = Time.parse('2013-01-01 00:00:00')
    result = actions.chunk(&by_time_window(60)).map(&littles_law_analysis)

    expected = [{range: start..(start + 60), value: 1.0 * 2},
                {range: (start + 60)..(start + 120), value: 1.0 * (2 + 4)/2},
                {range: (start + 120)..(start + 180), value: 0.5 * 4}]
    assert_equal expected, result.to_a
  end

  def actions
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
