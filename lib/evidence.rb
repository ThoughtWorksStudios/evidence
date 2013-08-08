require 'evidence/stream'

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
end
