require "test_helper"

class RailsActionParserTest < Test::Unit::TestCase
  include Evidence

  def test_start_action_pattern
    log = 'Processing MyController#list (for 67.214.225.82 at 2013-08-06 15:00:42) [GET]'
    assert log =~ rails2_action_patterns[:start]

    log = '#012#012Processing MyController#list (for 67.214.225.82 at 2013-08-06 15:00:42) [GET]'
    assert log =~ rails2_action_patterns[:start]
  end

  def test_end_action_pattern
    log = 'Completed in 755ms (View: 330, DB: 215) | 200 OK [https://abc.god.company.com/projects/abc/cards/list]'
    assert log =~ rails2_action_patterns[:end]
  end

  def test_merge_logs_into_actions
    data = [
            {pid: '1', message: 'Processing MyController#list (for 67.214.225.82 at 2013-08-06 15:00:42) [GET]'},
            {pid: '1', message: 'Completed in 755ms (View: 330, DB: 215) | 200 OK [https://abc.god.company.com/projects/abc/cards/list]'}
           ]
    actions = data.map(&rails2_parser).compact.to_a

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
    data = [
              {pid: '1', message: 'Processing MyController#list (for 67.214.225.01 at 2013-08-06 15:00:42) [GET]'},
              {pid: '2', message: 'Processing MyController#list (for 67.214.225.02 at 2013-08-06 15:00:42) [GET]'},
              {pid: '1', message: 'Completed in 701ms (View: 31, DB: 21) | 200 OK [https://abc.god.company.com/projects/abc/cards/list]'},
              {pid: '2', message: 'Completed in 702ms (View: 32, DB: 22) | 200 OK [https://abc.god.company.com/projects/abc/cards/list]'}
           ]
    actions = data.map(&rails2_parser).compact.to_a
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

  def test_process_action_that_has_no_view_time
    logs = ["#012#012Processing LandingController#index (for 14.140.219.2 at 2013-07-13 00:11:15) [GET]",
            "Redirected to https://x.company.com/abc",
            "Completed in 2115ms (DB: 230) | 302 Found [https://x.company.com/]"]

    assert_parse_action_logs(logs)
  end

  def test_weird_rails_log
    logs = ["#012#012Processing LandingController#index (for 14.140.219.2 at 2013-07-13 00:11:15) [GET]",
            "Completed in 21ms (View: 7 | 200 OK [https://x.company.com/gadgets/js/rpc.js?v=1.1-beta5]"]
    assert_parse_action_logs(logs)
  end

  def test_process_multiple_words_status_response
    logs = ["#012#012Processing LandingController#index (for 14.140.219.2 at 2013-07-13 00:11:15) [GET]",
            "Completed in 21ms (View: 7 | 304 Not Modified [https://x.company.com/gadgets/js/rpc.js?v=1.1-beta5]"]
    assert_parse_action_logs(logs)
  end

  def test_ignore_previous_start_action_when_found_another_start_action_after_a_start_action
    logs = ["#012#012Processing LandingController#index (for 14.140.219.2 at 2013-07-13 00:11:15) [GET]",
            "#012#012Processing HelloController#index (for 14.140.219.2 at 2013-07-13 00:11:15) [GET]",
            "Completed in 21ms (View: 7 | 304 Not Modified [https://x.company.com/gadgets/js/rpc.js?v=1.1-beta5]"]

    actions = logs.map(&rails2_parser(lambda {|l| 'pid'}, lambda {|l| l})).compact.to_a
    assert_equal 1, actions.size
    assert_equal 'HelloController', actions[0][:request][:controller]
  end

  def assert_parse_action_logs(logs)
    actions = logs.map(&rails2_parser(lambda {|l| 'pid'}, lambda {|l| l})).compact.to_a
    assert_equal 1, actions.size
  end

  def rails2_parser(pid=lambda {|log| log[:pid]}, message=lambda {|log| log[:message]})
    rails2_action_parser(pid, message)
  end
end
