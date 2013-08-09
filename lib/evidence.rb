require 'evidence/stream'
require 'evidence/log_parser'
require 'evidence/rails_action_parser'
require 'evidence/littles_law_analysis'

module Evidence
  module_function

  # A stream is an Enumerable with a processor processing the data comming
  # from upstream and yield to downstream
  def stream(up_stream, processor)
    Stream.new(up_stream, processor)
  end

  def counter
    Counter.new
  end

  def log_parser(pattern, unmatched=default_unmatched_processor)
    LogParser.new(pattern, unmatched)
  end

  def rails_action_parser(pid, message, unmatched=default_unmatched_processor)
    RailsActionParser.new(pid, message, unmatched)
  end

  def littles_law_analysis(time_window)
    LittlesLawAnalysis.new(time_window)
  end

  def default_unmatched_processor
    lambda {|log| }
  end
end
