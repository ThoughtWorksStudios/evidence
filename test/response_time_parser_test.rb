require "test_helper"

class ResponseTimeParserTest < Test::Unit::TestCase
  include Evidence
  def test_parse
    stream = stream([{request: {timestamp: '2013-08-06 15:00:42'}}]) | response_time_parser
    assert_equal Time.parse('2013-08-06 15:00:42'), stream.first[:request][:timestamp]
  end
end