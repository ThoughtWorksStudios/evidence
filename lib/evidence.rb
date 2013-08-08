require 'evidence/stream'
require 'evidence/log_parser'

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
end
