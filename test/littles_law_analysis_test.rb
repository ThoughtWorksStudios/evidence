require "test_helper"

class LittlesLawAnalysisTest < Test::Unit::TestCase
  include Evidence
  def test_calculate
    result = stream(data_stream, littles_law_analysis(60)).to_a
    assert_equal [1 * 2, 1 * (2 + 4)/2, 0.5 * 4], result
  end

  def data_stream
    data = []
    start = Time.parse('2013-01-01 00:00:00')
    60.times do |i|
      data << {request: {timestamp: (start + i).to_s}, response: {completed_time: 2000}}
    end
    start = Time.parse('2013-01-01 00:01:00')
    60.times do |i|
      data << {request: {timestamp: (start + i).to_s}, response: {completed_time: 2000 + (i / 30) * 2000}}
    end
    start = Time.parse('2013-01-01 00:02:00')
    30.times do |i|
      data << {request: {timestamp: (start + i * 2).to_s}, response: {completed_time: 4000}}
    end
    data << {request: {timestamp: (start + 61).to_s}, response: {completed_time: 2000}}
    data
  end
end
