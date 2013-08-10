module Evidence
  class Stream
    include Enumerable

    def initialize(upstream, processor)
      @upstream, @processor = upstream, processor
    end

    def eos?
      @upstream.eos?
    end

    def each(&block)
      @upstream.each(&@processor[block])
    end
  end

  class FileStream
    include Enumerable

    def initialize(file)
      @file = file
    end

    def eos?
      @file.eof?
    end

    def each(&block)
      @file.each(&block)
    end

  end

  class ArrayStream
    include Enumerable
    def initialize(array)
      @array = array
    end

    def eos?
      @array.empty?
    end

    def each(&block)
      while(item = @array.shift) do
        block.call(item)
      end
    end
  end

  class MergedStream
    include Enumerable

    def initialize(streams, comparator)
      @streams, @comparator = streams, comparator
    end

    def eos?
      @heads && @heads.empty?
    end

    def each(&block)
      @heads ||= @streams.map{|s| {stream: s, element: s.first}}.reject{|head| head[:stream].eos? && head[:element].nil?}

      loop do
        min = @heads.min do |a, b|
          @comparator.call(a[:element], b[:element])
        end
        break if min.nil?
        block.call(pull_next(min))
      end
    end

    def pull_next(head)
      head[:element].tap do |value|
        head[:element] = head[:stream].first
        if head[:stream].eos? && head[:element].nil?
          @heads.delete(head)
        end
      end
    end
  end

  class Counter
    include Enumerable
    def initialize
      @count = 0
    end

    def eos?
      false
    end

    def each(&block)
      loop do
        block.call(@count += 1)
      end
    end
  end
end
