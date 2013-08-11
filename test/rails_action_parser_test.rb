require "test_helper"

class RailsActionParserTest < Test::Unit::TestCase
  include Evidence

  def test_start_action_pattern
    log = 'Processing MyController#list (for 67.214.225.82 at 2013-08-06 15:00:42) [GET]'
    assert log =~ parser.start_action_pattern

    log = '#012#012Processing MyController#list (for 67.214.225.82 at 2013-08-06 15:00:42) [GET]'
    assert log =~ parser.start_action_pattern
  end

  def test_end_action_pattern
    log = 'Completed in 755ms (View: 330, DB: 215) | 200 OK [https://abc.god.company.com/projects/abc/cards/list]'
    assert log =~ parser.end_action_pattern
  end

  def test_unmatched_process
    pid = lambda {|log| log[:pid]}
    message = lambda {|log| log[:message]}
    unmatched = []
    parser = rails_action_parser(pid, message, lambda{|log| unmatched << log})
    actions = []
    process = parser[lambda {|action| actions << action}]
    process.call({message: "haha", pid: '1'})
    assert_equal 1, unmatched.size
    assert_equal [], actions
  end

  def test_merge_logs_into_actions
    stream = [
      {pid: '1', message: 'Processing MyController#list (for 67.214.225.82 at 2013-08-06 15:00:42) [GET]'},
      {pid: '1', message: 'Completed in 755ms (View: 330, DB: 215) | 200 OK [https://abc.god.company.com/projects/abc/cards/list]'}
    ]
    actions = []
    block = lambda {|action| actions << action}
    process = parser[block]
    process.call(stream[0])
    process.call(stream[1])

    assert_equal 1, actions.size
    assert_equal({
      remote_addr: '67.214.225.82',
      timestamp: '2013-08-06 15:00:42',
      controller: 'MyController',
      action: 'list',
      method: 'GET'
    }, actions[0][:request])
    assert_equal({
      completed_time: '755',
      view_time: '330',
      db_time: '215',
      code: '200',
      status: 'OK',
      url: "https://abc.god.company.com/projects/abc/cards/list"
    }, actions[0][:response])
  end

  def test_group_logs_by_pid_before_parsing_out_actions
    stream = [
      {pid: '1', message: 'Processing MyController#list (for 67.214.225.01 at 2013-08-06 15:00:42) [GET]'},
      {pid: '2', message: 'Processing MyController#list (for 67.214.225.02 at 2013-08-06 15:00:42) [GET]'},
      {pid: '1', message: 'Completed in 701ms (View: 31, DB: 21) | 200 OK [https://abc.god.company.com/projects/abc/cards/list]'},
      {pid: '2', message: 'Completed in 702ms (View: 32, DB: 22) | 200 OK [https://abc.god.company.com/projects/abc/cards/list]'}
    ]
    actions = []
    block = lambda {|action| actions << action}
    process = parser[block]
    process.call(stream[0])
    process.call(stream[1])
    process.call(stream[2])
    process.call(stream[3])

    assert_equal 2, actions.size
    assert_equal({
      remote_addr: '67.214.225.01',
      timestamp: '2013-08-06 15:00:42',
      controller: 'MyController',
      action: 'list',
      method: 'GET'
    }, actions[0][:request])
    assert_equal({
      completed_time: '701',
      view_time: '31',
      db_time: '21',
      code: '200',
      status: 'OK',
      url: "https://abc.god.company.com/projects/abc/cards/list"
    }, actions[0][:response])

    assert_equal({
      remote_addr: '67.214.225.02',
      timestamp: '2013-08-06 15:00:42',
      controller: 'MyController',
      action: 'list',
      method: 'GET'
    }, actions[1][:request])
    assert_equal({
      completed_time: '702',
      view_time: '32',
      db_time: '22',
      code: '200',
      status: 'OK',
      url: "https://abc.god.company.com/projects/abc/cards/list"
    }, actions[1][:response])
  end

  def parser(pid=lambda {|log| log[:pid]}, message=lambda {|log| log[:message]})
    rails_action_parser(pid, message)
  end
end
