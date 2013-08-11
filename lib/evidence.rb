require 'evidence/stream'
require 'evidence/log_parser'
require 'evidence/rails_action_parser'
require 'evidence/littles_law_analysis'

module Evidence
  module_function

  # convert Array or File object to a stream
  def stream(obj)
    case obj
    when Array
      ArrayStream.new(obj)
    when File
      FileStream.new(obj)
    else
      raise "Unknown how to convert #{obj.class} to a stream"
    end
  end

  def merge_streams(streams, comparator)
    loop do
      s1 = streams.shift
      return s1 if streams.empty?
      s2 = streams.shift
      streams << MergedStream.new([s1, s2], comparator)
    end
  end

  def counter
    Counter.new
  end

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
  #   log stream | rails_action_parser(pid, message) | response_time_parser
  def response_time_parser
    lambda do |output|
      lambda do |action|
        action[:request][:timestamp] = Time.strptime(action[:request][:timestamp], "%Y-%m-%d %H:%M:%S")
        output[action]
      end
    end
  end

  # Do the little's law analysis on rails actions stream with response_time_parser
  # example:
  #   log stream | rails_action_parser(pid, message) | response_time_parser | littles_law_analysis(60)
  def littles_law_analysis(time_window)
    LittlesLawAnalysis.new(time_window)
  end

  def default_unmatched_process
    lambda {|log| }
  end
end
