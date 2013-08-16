require 'evidence'
require 'time'
require 'fileutils'

include Evidence

mingle_log_pattern = /^
  \w{3}\s+\d+\s+\d{2}\:\d{2}\:\d{2}\s+
  (?<host_name>[^\s]+)\s+
  [-_\w]+\:\s+
  INFO\s+
  \[(?<timestamp>[^\]]+)\]\s+
  \[(?<thread_label>[^\]]+)\]\s+
  \[(?<log4j_label>[^\]]+)\]\s+
  \[tenant\:(?<tenant>[^\]]*)\]\s+
  (?<message>.*)
$/x

pid = lambda {|log| "#{log[:host_name]}-#{log[:thread_label]}"}
message = lambda {|log| log[:message]}

logs = Dir['./log/*'].sort.lazy.map { |f| File.new(f).lazy.map(&parse_log(mingle_log_pattern)).compact }.flat_map {|a| a}
time_window = (ARGV[0] || 60).to_i
puts "[DEBUG]logs.size => #{logs.size.inspect}"
puts "[DEBUG] time_window => #{time_window.inspect}"

FileUtils.mkdir_p('out')
File.open('out/mingle_logs_littles_law_analysis', 'w') do |f|
  logs.map(&rails_action_parser(pid, message)).compact.map(&request_timestamp_parser).chunk(&by_time_window(time_window)).map(&littles_law_analysis).map do |stat|
    t1 = stat[:range].min.strftime("%m-%d %H:%M")
    t2 = stat[:range].max.strftime("%H:%M")
    f.write("#{t1}-#{t2} #{stat[:value]}\n".tap{|r| puts r})
  end.force
end
