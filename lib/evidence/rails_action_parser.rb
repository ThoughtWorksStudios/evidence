module Evidence
  class RailsActionParser

    def initialize(pid, message, unmatched)
      @pid, @message = pid, message
      @unmatched = unmatched
    end

    def [](block)
      processes = Hash.new
      lambda do |log|
        pid = @pid[log]
        if processes.has_key?(pid)
          processes[pid] << log
          if end_action?(@message[log])
            block.call(parse_action_logs(processes.delete(pid)))
          end
        else
          if start_action?(@message[log])
            processes[pid] = [log]
          else
            @unmatched.call(log)
          end
        end
      end
    end

    def parse_action_logs(logs)
      {
        request: request(@message[logs[0]]),
        response: response(@message[logs[-1]]),
        logs: logs
      }
    end

    def end_action?(msg)
      msg =~ end_action_pattern
    end

    def start_action?(msg)
      msg =~ start_action_pattern
    end

    def request(msg)
      to_hash(start_action_pattern.match(msg))
    end

    def response(msg)
      to_hash(end_action_pattern.match(msg))
    end

    def start_action_pattern
      /^
        (\#012\#012)?             # ignore encoded newlines
        Processing\s+
        (?<controller>\w+)\#(?<action>\w+)\s+
        \(for\s+
        (?<remote_addr>[^\s]+)\s+
        at\s+
        (?<timestamp>[^\)]+)\)\s+
        \[(?<method>[\w]+)\]
      $/x
    end

    # Completed in 755ms (View: 330, DB: 215) | 200 OK [url]
    def end_action_pattern
      /^
        Completed\sin\s
        (?<completed_time>\d+)ms\s+
        \(View\:\s(?<view_time>\d+)
        (,\s*DB\:\s(?<db_time>\d+))?
        \)\s+\|\s+
        (?<code>\d+)\s+
        (?<status>\w+)\s+
        \[(?<url>.+)\]
      $/x
    end

    def to_hash(m)
      Hash[m.names.map(&:to_sym).zip(m.captures)]
    end
  end
end
