require 'evidence'
require 'time'

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
mingle_bg_log_pattern = /^
  \w{3}\s+\d+\s+\d{2}\:\d{2}\:\d{2}\s+
  (?<host_name>[^\s]+)\s+
  [\w-_]+\:\s+
  INFO\s+
  \[(?<timestamp>[^\]]+)\]\s+
  \[[\w-_\d]+\[(?<thread_label>[^\]]+)\]\]\s+
  \[(?<log4j_label>[^\]]+)\]\s+
  \[tenant\:(?<tenant>[^\]]*)\]\s+
  (?<message>.*)
$/x

pid = lambda {|log| "#{log[:host_name]}-#{log[:thread_label]}"}
message = lambda {|log| log[:message]}

def parse_timestamp
  lambda do |block|
    lambda do |log|
      block.call(log.merge(timestamp: Time.parse(log[:timestamp])))
    end
  end
end

logs = Dir['./../mingle-saas/log/dumpling/**/mingle-cluster*'].reject do |f|
  File.new(f).first(100).any? do |l|
    l =~ mingle_bg_log_pattern
  end
end.map do |f|
  stream(File.new(f), log_parser(mingle_log_pattern))
end
puts "[DEBUG]logs.size => #{logs.size.inspect}"

merged = merge_streams(logs, lambda {|log1, log2| log1[:timestamp] <=> log2[:timestamp]})

#counter = 0

#stream(merged, lambda {|block| lambda {|log| block.call(counter += 1)}}).each do |count|
#   puts "#{Time.now}: #{count}"
#end

actions_stream = stream(merged, rails_action_parser(pid, message))

time_window = (ARGV[0] || 60).to_i
File.open('datafile', 'w') do |f|
  stream(actions_stream, littles_law_analysis(time_window)).map do |start_time, end_time, avg_stay_in_system|
    t1 = start_time.strftime("%m-%d %H:%M")
    t2 = end_time.strftime("%H:%M")
    f.write("#{t1}-#{t2} #{avg_stay_in_system}\n".tap{|r| puts r})
  end
end
