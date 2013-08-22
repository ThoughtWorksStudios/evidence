module Evidence
  class ActionParser

    def initialize(pid, message, action_patterns)
      @pid, @message = pid, message
      @processes = Hash.new
      @start_action_pattern, @end_action_pattern = action_patterns[:start], action_patterns[:end]
    end

    def to_proc
      lambda do |log|
        pid = @pid[log]
        if @processes.has_key?(pid)
          @processes[pid] << log
          if end_action?(@message[log])
            parse_action_logs(@processes.delete(pid))
          end
        else
          if start_action?(@message[log])
            @processes[pid] = [log]
          end
          nil
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
      msg =~ @end_action_pattern
    end

    def start_action?(msg)
      msg =~ @start_action_pattern
    end

    def request(msg)
      to_hash(@start_action_pattern.match(msg))
    end

    def response(msg)
      to_hash(@end_action_pattern.match(msg))
    end

    def to_hash(m)
      Hash[m.names.map(&:to_sym).zip(m.captures)]
    end
  end
end
