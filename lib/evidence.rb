require 'evidence/stream'
require 'evidence/log_parser'
require 'evidence/rails_action_parser'
require 'evidence/littles_law_analysis'

module Evidence
  module_function

  # A stream is an Enumerable with a process processing the data comming
  # from upstream and yield to downstream
  def stream(obj, process=nil)
    up_stream = case obj
    when Array
      ArrayStream.new(obj)
    when File
      FileStream.new(obj)
    else
      obj
    end
    Stream.new(up_stream, process || lambda {|b| b})
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

  # Do the little's law analysis on rails actions stream
  def littles_law_analysis(time_window)
    LittlesLawAnalysis.new(time_window)
  end

  def default_unmatched_process
    lambda {|log| }
  end
end
