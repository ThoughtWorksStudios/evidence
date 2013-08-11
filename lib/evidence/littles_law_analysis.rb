require 'time'

module Evidence
  # Little's Law analysis, input stream log should include the following data
  # {:request => {:timestamp}, :response => {:completed_time}}
  class LittlesLawAnalysis
    class Result
      def initialize(start, time_window)
        @start, @time_window = start, time_window
        @end = @start + @time_window
        @arrival_count = 0
        @response_time = 0
      end

      def ended?(timestamp)
        @end <= timestamp
      end

      def add(millisecond)
        @arrival_count += 1
        @response_time += millisecond
      end

      def next
        Result.new(@start + @time_window, @time_window)
      end

      def value
        avg_sec_arrival_rate = @arrival_count.to_f/@time_window
        avg_sec_response_time = @response_time.to_f/1000/@arrival_count
        [@start, @end, avg_sec_arrival_rate * avg_sec_response_time]
      end
    end

    # time_window: second
    def initialize(time_window)
      @time_window = time_window
    end

    def [](output)
      result = nil
      lambda do |log|
        timestamp = log[:request][:timestamp]
        if result.nil?
          result = Result.new(timestamp, @time_window)
        else
          if result.ended?(timestamp)
            output.call(result.value)
            result = result.next
          end
        end
        result.add(log[:response][:completed_time].to_i)
      end
    end
  end
end
