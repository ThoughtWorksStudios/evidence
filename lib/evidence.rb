require 'evidence/stream'
require 'evidence/log_parser'
require 'evidence/rails_action_parser'

module Evidence
  module_function

  # Parse log file stream by given pattern
  #   pattern: ruby regex expression, has named group specified
  #   output stream: hash object with name and captured string in log
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
    lambda do |output|
      lambda do |action|
        action[:request][:timestamp] = Time.strptime(action[:request][:timestamp], format)
        output[action]
      end
    end
  end

  # Do the little's law analysis on rails actions stream with request_timestamp_parser
  # usage example:
  #   log stream | rails_action_parser(pid, message) | request_timestamp_parser | slice_stream(lambda {|action| action[:request][:timestamp]}, 60) | littles_law_analysis
  def littles_law_analysis
    lambda do |output|
      lambda do |range, logs|
        logs = logs.to_a
        count = logs.size
        avg_response_time = logs.reduce(0) {|memo, log| memo + log[:response][:completed_time].to_i} / count

        avg_sec_arrival_rate = count.to_f/(range.max - range.min)
        avg_sec_response_time = avg_response_time.to_f/1000
        output[range, avg_sec_arrival_rate * avg_sec_response_time]
      end
    end
  end

  def default_unmatched_process
    lambda {|log| }
  end
end
