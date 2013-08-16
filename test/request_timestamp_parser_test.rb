require "test_helper"

class RequestTimestampParserTest < Test::Unit::TestCase
  include Evidence
  def test_parse_default_rails_timestamp_format
    data = [{request: {timestamp: '2013-08-06 15:00:42'}}].each(&request_timestamp_parser)
    assert_equal Time.parse('2013-08-06 15:00:42'), data.first[:request][:timestamp]
  end

  def test_parse_by_given_format
    data = [{request: {timestamp: '08-06-2013 15:00:42'}}].each(&request_timestamp_parser("%m-%d-%Y %H:%M:%S"))
    assert_equal Time.parse('2013-08-06 15:00:42'), data.first[:request][:timestamp]
  end
end
