require "test_helper"

class LogParserTest < Test::Unit::TestCase
  def setup
    @logs = []
  end

  def pattern
    /^
      (?<timestamp>\w{3}\s+\d+\s+\d{2}\:\d{2}\:\d{2})\s+
      (?<host_name>[^\s]+)\s+
      (?<app_name>[-_\w\d]+)\:\s+
      (?<message>.*)
    $/x
  end

  def test_parse_logs_by_a_regex_pattern
    stream = ['Aug  6 15:01:14 cluster-ip-10-197-18-30 helloworld: INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout] #012#012Processing ProgramsController#index (for 83.244.132.215 at 2013-08-06 15:01:14) [GET]', 'Aug  6 15:01:14 cluster-ip-10-197-18-30 helloworld: INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout]   Parameters: {"controller"=>"programs", "action"=>"index"}']

    processor = Evidence.log_parser(pattern)[lambda {|log| @logs << log}]
    processor.call(stream[0])
    assert_equal 1, @logs.size
    assert_equal 'Aug  6 15:01:14', @logs[0][:timestamp]
    assert_equal 'cluster-ip-10-197-18-30', @logs[0][:host_name]
    assert_equal 'helloworld', @logs[0][:app_name]
    assert_equal 'INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout] #012#012Processing ProgramsController#index (for 83.244.132.215 at 2013-08-06 15:01:14) [GET]', @logs[0][:message]

    processor.call(stream[1])
    assert_equal 2, @logs.size
    assert_equal 'INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout]   Parameters: {"controller"=>"programs", "action"=>"index"}', @logs[1][:message]
  end

  def test_handles_unmatched_logs
    stream = ['abc', 'Aug  6 15:01:14 cluster-ip-10-197-18-30 helloworld: INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout] #012#012Processing ProgramsController#index (for 83.244.132.215 at 2013-08-06 15:01:14) [GET]', 'eft', 'Aug  6 15:01:14 cluster-ip-10-197-18-30 helloworld: INFO [2013-08-06 15:01:14,304] [btpool0-17] [com.company.helloworld] [tenant:timeout]   Parameters: {"controller"=>"programs", "action"=>"index"}']
    unmatched = []
    processor = Evidence.log_parser(pattern, lambda{|log| unmatched << log})[lambda {|log| @logs << log}]
    stream.each do |l|
      processor.call(l)
    end
    assert_equal ['abc', 'eft'], unmatched
    assert_equal 2, @logs.size
  end
end
