require "test_helper"

class LittlesLawAnalysisTest < Test::Unit::TestCase
  include Evidence
  def test_calculate
    result = stream(data_stream) | littles_law_analysis(60)
    expected = [
                [Time.parse('2013-01-01 00:00:00'),
                 Time.parse('2013-01-01 00:01:00'),
                 1 * 2],
                [Time.parse('2013-01-01 00:01:00'),
                 Time.parse('2013-01-01 00:02:00'),
                 1 * (2 + 4)/2],
                [Time.parse('2013-01-01 00:02:00'),
                 Time.parse('2013-01-01 00:03:00'),
                 0.5 * 4]]
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
    data << {request: {timestamp: (start + 61)}, response: {completed_time: 2000}}
    data
  end
end
