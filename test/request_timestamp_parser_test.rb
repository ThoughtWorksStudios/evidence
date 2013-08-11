require "test_helper"

class RequestTimestampParserTest < Test::Unit::TestCase
  include Evidence
  def test_parse_default_rails_timestamp_format
    stream = stream([{request: {timestamp: '2013-08-06 15:00:42'}}]) | request_timestamp_parser
    assert_equal Time.parse('2013-08-06 15:00:42'), stream.first[:request][:timestamp]
  end

  def test_parse_by_given_format
    stream = stream([{request: {timestamp: '08-06-2013 15:00:42'}}]) | request_timestamp_parser("%m-%d-%Y %H:%M:%S")
    assert_equal Time.parse('2013-08-06 15:00:42'), stream.first[:request][:timestamp]
  end
end