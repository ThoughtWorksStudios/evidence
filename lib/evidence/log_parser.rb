module Evidence
  class LogParser
    def initialize(pattern, unmatched)
      @pattern, @unmatched = pattern, unmatched
    end

    def [](output)
      lambda do |line|
        if m = @pattern.match(line)
          output.call(to_hash(m))
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
