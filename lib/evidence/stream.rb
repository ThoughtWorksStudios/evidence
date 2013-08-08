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
