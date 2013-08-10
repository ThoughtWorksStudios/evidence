require 'evidence'

include Evidence

mingle_log_pattern = /^
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

pid = lambda {|log| "#{log[:host_name]}-#{log[:thread_label]}"}
message = lambda {|log| log[:message]}

def parse_timestamp
  lambda do |block|
    lambda do |log|
      #puts "[DEBUG]log[:timestamp] => #{log[:timestamp].inspect}"
      block.call(log.merge(timestamp: Time.parse(log[:timestamp])))
    end
  end
end

logs = Dir['/Users/tworker/studios/saas/log/dumpling/**/mingle-cluster*'].map do |f|
  stream(stream(File.new(f), log_parser(mingle_log_pattern)), parse_timestamp)
end

require 'time'
merged = merge_streams(logs, lambda {|log1, log2| log1[:timestamp] <=> log2[:timestamp]})

counter = 0

# stream(merged, lambda {|block| lambda {|log| block.call(counter += 1)}}).each do |count|
#   puts "#{Time.now}: #{count}"
# end

actions_stream = stream(merged, rails_action_parser(pid, message))

time_window = (ARGV[0] || 60).to_i

stream(actions_stream, littles_law_analysis(time_window)).each do |avg_stay_in_system|
  puts avg_stay_in_system
end
