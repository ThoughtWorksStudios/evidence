module Evidence
  class LogParser
    def self.default_unmatched
      lambda {|log| warn "Cannot match log: #{log}"}
    end

    def initialize(pattern, options)
      @pattern, @options = pattern, options
      @unmatched = @options[:unmatched] || LogParser.default_unmatched
    end

    def [](block)
      single_pattern_parser(block)
    end

    def single_pattern_parser(block)
      lambda do |line|
        if m = @pattern.match(line)
          block.call(m)
        else
          @unmatched.call(line)
        end
      end
    end

    def to_hash(m)
      Hash[m.names.map(&:to_sym).zip(m.captures)]
    end
  end
end
