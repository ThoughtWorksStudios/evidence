require 'evidence/stream'
require 'evidence/log_parser'
require 'evidence/rails_action_parser'

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

  def log_parser(pattern, options={})
    LogParser.new(pattern, options)
  end

  def rails_action_parser(pid, message)
    RailsActionParser.new(pid, message)
  end

end
