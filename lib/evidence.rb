require 'evidence/lazy'
require 'evidence/rails'
require 'evidence/action_parser'

Enumerator::Lazy.send(:include, Evidence::Lazy)

module Evidence
  module_function

  # Parse log file stream by given pattern
  #   pattern: ruby regex expression, has named group specified
  # example: logs.map(&parse_log(pattern)).compact
  def parse_log(pattern)
    lambda do |log|
      if m = pattern.match(log)
        Hash[m.names.map(&:to_sym).zip(m.captures)].tap do |h|
          h[:origin] = log unless h.has_key?(:origin)
        end
      end
    end
  end

  # default to rails 2
  def rails_action_parser(pid, message, version=2)
    rails2_action_parser(pid, message)
  end
  # Parse out rails actions by given:
  #   pid: a lambda returns process id used to group logs
  #   message: a lambda returns rails log string message
  # example: logs.map(&rails_action_parser(pid, message)).compact
  def rails2_action_parser(pid, message)
    ActionParser.new(pid, message, rails2_action_patterns)
  end

  # Rails action request timestamp parser
  #   log.map(&rails_action_parser(pid, message)).compact.map(&request_timestamp_parser)
  def request_timestamp_parser(format="%Y-%m-%d %H:%M:%S")
    lambda do |action|
      action[:request][:timestamp] = Time.strptime(action[:request][:timestamp], format)
      action
    end
  end

  # actions.chunk(&by_time_window(60))
  def by_time_window(time_window, start=nil)
    range = nil
    lambda do |ele|
      start ||= ele[:request][:timestamp]
      range ||= start..(start + time_window)
      while(range.max <= ele[:request][:timestamp]) do
        range = range.max..(range.max + time_window)
      end
      range
    end
  end

  # Do the little's law analysis on rails actions stream
  # usage example:
  #   rails_action_parser(pid, message).parse(parse_log(logs,
  # pattern)).each(&request_timestamp_parser).chunk({start: nil},
  # &time_window(60 seconds)).map do |range, actions|
  #     littles_law_analysis(range, actions)
  #   end
  def littles_law_analysis
    lambda do |args|
      range, actions = args
      statistics = actions.inject(sum: 0, count: 0) do |memo, action|
        memo[:count] += 1
        memo[:sum] += action[:response][:completed_time].to_i
        memo
      end
      avg_sec_arrival_rate = statistics[:count].to_f/(range.max - range.min)
      avg_sec_response_time = statistics[:sum].to_f / statistics[:count] /1000
      {range: range, value: avg_sec_arrival_rate * avg_sec_response_time}
    end
  end
end
