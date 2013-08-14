module Evidence
  module Stream
    include Enumerable

    def |(process)
      case process
      when SliceStream
        process.slice(self)
      else
        PipeStream.new(self, process)
      end
    end
  end

  class PipeStream
    include Stream

    def initialize(upstream, process)
      @upstream, @process = upstream, process
    end

    def eos?
      @upstream.eos?
    end

    def each(&output)
      @upstream.each(&@process[output])
    end
  end

  class FileStream
    include Stream

    def initialize(file)
      @file = file
    end

    def eos?
      @file.eof?
    end

    def each(&output)
      @file.each(&output)
    end
  end

  class ArrayStream
    include Stream

    def initialize(array)
      @array = array
    end

    def eos?
      @array.empty?
    end

    def each(&output)
      while(item = @array.shift) do
        output.call(item)
      end
    end

    def to_s
      "$[#{@array.inspect}]"
    end
  end

  class EnumStream
    include Stream

    def initialize(enum)
      @enum = enum
    end

    def eos?
      @enum.peek
      false
    rescue StopIteration
      true
    end

    def each(&output)
      @enum.each(&output)
    end

    def to_s
      "$[#{@enum.inspect}]"
    end
  end

  class MergedStream
    include Stream

    def initialize(streams, comparator)
      @comparator = comparator
      @heads = streams.map{|s| {stream: s}}
    end

    def eos?
      @heads.empty?
    end

    def each(&output)
      pull_heads
      loop do
        if min = @heads.min{|a, b| @comparator.call(a[:element], b[:element])}
          output.call(min.delete(:element).tap{ pull_heads })
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

  class SlicedStreams
    include Stream

    def initialize(stream, index, start_index, end_index)
      @stream, @index, @start_index, @end_index = stream, index, start_index, end_index
      @slice_start_index, @slice_end_index = nil
    end

    def eos?
      @stream.eos?
    end

    def each(&output)
      return if eos?
      @head ||= @stream.first
      @slice_start_index ||= @start_index || @index[@head]
      @slice_end_index ||= @end_index[@slice_start_index]
      eos_in_slice = false
      loop do
        break if eos_in_slice

        range = @slice_start_index..@slice_end_index
        e = Enumerator.new do |y|
          loop do
            head_index = @index[@head]
            if range.min > head_index
              break if eos_in_slice = eos?
              @head = @stream.first
              next
            end
            break if range.max <= head_index

            n = @head
            if eos_in_slice = eos?
              y << n
              break
            else
              @head = @stream.first
              y << n
            end
          end
        end
        @slice_start_index = range.max
        @slice_end_index = @end_index[@slice_start_index]
        output[range, EnumStream.new(e)]
      end
    end
  end

  class SliceStream
    def initialize(index, start_index, end_index)
      @index, @start_index, @end_index = index, start_index, end_index
    end

    def slice(stream)
      SlicedStreams.new(stream, @index, @start_index, @end_index)
    end
  end

  class Counter
    include Stream

    def initialize
      @count = 0
    end

    def eos?
      false
    end

    def each(&output)
      loop do
        output.call(@count += 1)
      end
    end
  end
end
