require "test_helper"

class LogParserTest < Test::Unit::TestCase
  include Evidence

  def pattern
    /^
      (?<timestamp>\w{3}\s+\d+\s+\d{2}\:\d{2}\:\d{2})\s+
      (?<host_name>[^\s]+)\s+
      (?<app_name>[-_\w\d]+)\:\s+
      (?<message>.*)
    $/x
  end

  def raw_logs
    ['Aug  6 15:01:14 cluster-ip-10-197-18-30 helloworld: INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout] #012#012Processing ProgramsController#index (for 83.244.132.215 at 2013-08-06 15:01:14) [GET]',
     'Aug  6 15:01:14 cluster-ip-10-197-18-30 helloworld: INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout]   Parameters: {"controller"=>"programs", "action"=>"index"}']
  end

  def test_parse_logs_by_a_regex_pattern
    logs = raw_logs.map(&parse_log(pattern)).compact.to_a
    log = logs.shift
    assert log
    assert_equal 'Aug  6 15:01:14', log[:timestamp]
    assert_equal 'cluster-ip-10-197-18-30', log[:host_name]
    assert_equal 'helloworld', log[:app_name]
    assert_equal 'INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout] #012#012Processing ProgramsController#index (for 83.244.132.215 at 2013-08-06 15:01:14) [GET]', log[:message]

    log = logs.shift
    assert log
    assert_equal 'INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout]   Parameters: {"controller"=>"programs", "action"=>"index"}', log[:message]
  end
end
