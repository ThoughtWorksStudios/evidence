module Evidence
  class Stream
    include Enumerable

    def initialize(upstream, processor)
      @upstream, @processor = upstream, processor
    end

    def merge(stream, comparator)
      MergedStream.new(comparator, self, stream)
    end

    def each(&block)
      @upstream.each(&@processor[block])
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

    def initialize(comparator, *streams)
      @comparator, @streams = comparator, streams
    end

    def each(&block)
      items = @streams.map{|s| {stream: s, next: s.first}}
      loop do
        items.sort! do |a, b|
          if a[:next]
            b[:next] ? @comparator.call(a[:next], b[:next]) : -1
          else
            b[:next] ? -1 : 0
          end
        end
        block.call(items[0][:next])
        items[0][:next] = items[0][:stream].first
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
