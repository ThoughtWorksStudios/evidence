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

pid = lambda {|log| "#{log[:host_name]}-#{log[:thread_label]}"}
message = lambda {|log| log[:message]}

logs = Dir['./log/**/*'].map do |f|
  stream(File.new(f)) | log_parser(mingle_log_pattern)
end
puts "[DEBUG]logs.size => #{logs.size.inspect}"

merged_logs = merge_streams(logs, lambda {|log1, log2| log1[:timestamp] <=> log2[:timestamp]})
result = merged_logs | rails_action_parser(pid, message) | littles_law_analysis(time_window)

time_window = (ARGV[0] || 60).to_i
File.open('datafile', 'w') do |f|
  result.map do |start_time, end_time, avg_stay_in_system|
    t1 = start_time.strftime("%m-%d %H:%M")
    t2 = end_time.strftime("%H:%M")
    f.write("#{t1}-#{t2} #{avg_stay_in_system}\n".tap{|r| puts r})
  end
end
