module Evidence
  class LogParser
    def initialize(pattern, unmatched)
      @pattern, @unmatched = pattern, unmatched
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
