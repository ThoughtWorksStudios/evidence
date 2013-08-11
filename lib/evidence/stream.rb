module Evidence
  module Pipeline
    def |(process)
      Stream.new(self, process)
    end
  end

  # A stream is an Enumerable with a process processing the data comming
  # from input stream and output as another stream
  class Stream
    include Enumerable
    include Pipeline

    def initialize(upstream, process)
      @upstream, @process = upstream, process
    end

    def eos?
      @upstream.eos?
    end

    def each(&block)
      @upstream.each(&@process[block])
    end
  end

  class FileStream
    include Enumerable
    include Pipeline

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
    include Pipeline

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

    def to_s
      "$[#{@array.inspect}]"
    end
  end

  class MergedStream
    include Enumerable
    include Pipeline

    def initialize(streams, comparator)
      @comparator = comparator
      @heads = streams.map{|s| {stream: s}}
    end

    def eos?
      @heads.empty?
    end

    def each(&block)
      pull_heads
      loop do
        if min = @heads.min{|a, b| @comparator.call(a[:element], b[:element])}
          block.call(min.delete(:element).tap{ pull_heads })
        else
          break if @heads.empty?
          pull_heads
        end
      end
    end

    def pull_heads
      @heads.select!{|h| h[:element] ||= pull(h[:stream])}
    end

    def pull(stream)
      loop do
        return nil if stream.eos?
        if n = stream.first
          return n
        end
      end
    end
  end

  class Counter
    include Enumerable
    include Pipeline

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
