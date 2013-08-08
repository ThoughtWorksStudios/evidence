require "test/unit"

require "evidence"

def file(fname)
  File.join(File.dirname(__FILE__), 'data', fname)
end

def file_stream(file)
  File.new(file)
end

def data_logs_parser
  pattern = /^
    \w{3}\s+\d+\s+\d{2}\:\d{2}\:\d{2}\s+
    (?<host_name>[^\s]+)\s+
    [\w-_]+\:\s+
    INFO\s+
    \[(?<timestamp>[^\]]+)\]\s+
    \[(?<thread_label>[^\]]+)\]\s+
    \[(?<log4j_label>[^\]]+)\]\s+
    \[tenant\:(?<tenant>[^\]]*)\]\s+
    (?<message>.*)
  $/x
  log_parser(pattern)
end

