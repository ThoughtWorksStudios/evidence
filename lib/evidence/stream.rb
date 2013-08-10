module Evidence
  class Stream
    include Enumerable

    def initialize(upstream, processor)
      @upstream, @processor = upstream, processor
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

    def each(&block)
      @file.each(&block)
    end

  end

  class ArrayStream
    include Enumerable
    def initialize(array)
      @array = array
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
      @comparator = comparator
      @heads = streams.map{|s| {stream: s}}
    end

    def each(&block)
      loop do
        @heads.each do |head|
          head[:element] ||= head[:stream].first
        end

        min = @heads.reject{|h|h[:element].nil?}.min do |a, b|
          @comparator.call(a[:element], b[:element])
        end
        if min
          block.call(min.delete(:element))
        end
      end
    end
  end

  class Counter
    include Enumerable
    def initialize
      @count = 0
    end

    def each(&block)
      loop do
        block.call(@count += 1)
      end
    end
  end
end
