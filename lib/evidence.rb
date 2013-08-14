require 'evidence/stream'
require 'evidence/log_parser'
require 'evidence/rails_action_parser'

module Evidence
  module_function

  # Parse log file stream by given pattern
  #   pattern: ruby regex expression, has named group specified
  #   unmatched processor: process all unmatched log
  def log_parser(pattern, unmatched=default_unmatched_process)
    LogParser.new(pattern, unmatched)
  end

  # Parse out rails actions by given:
  #   pid: a lambda returns process id used to group logs
  #   message: a lambda returns rails log string message
  def rails_action_parser(pid, message, unmatched=default_unmatched_process)
    RailsActionParser.new(pid, message, unmatched)
  end

  # Rails action request timestamp parser
  #   log stream | rails_action_parser(pid, message) | request_timestamp_parser
  def request_timestamp_parser(format="%Y-%m-%d %H:%M:%S")
    stream_each do |action|
      action[:request][:timestamp] = Time.strptime(action[:request][:timestamp], format)
    end
  end

  # Do the little's law analysis on rails actions stream with request_timestamp_parser
  # usage example:
  #   log stream | rails_action_parser(pid, message) | request_timestamp_parser | slice_stream(lambda {|action| action[:request][:timestamp]}, 60) | littles_law_analysis
  def littles_law_analysis
    lambda do |output|
      lambda do |range, actions|
        statistics = actions.inject(sum: 0, count: 0) do |memo, action|
          memo[:count] += 1
          memo[:sum] += action[:response][:completed_time].to_i
          memo
        end
        avg_sec_arrival_rate = statistics[:count].to_f/(range.max - range.min)
        avg_sec_response_time = statistics[:sum].to_f / statistics[:count] /1000
        output[range, avg_sec_arrival_rate * avg_sec_response_time]
      end
    end
  end

  def default_unmatched_process
    lambda {|log| }
  end
end
