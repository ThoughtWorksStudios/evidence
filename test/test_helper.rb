require "test/unit"

require "evidence"

def file(fname)
  File.join(File.dirname(__FILE__), 'data', fname)
end

def file_stream(file)
  File.new(file)
end

