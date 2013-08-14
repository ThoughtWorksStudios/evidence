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
      loop do
        output[@enum.next]
      end
    rescue StopIteration
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
      @eos_in_slice ||= false
      loop do
        if @slice_start_index > @index[@head]
          return if eos?
          @head = @stream.first
        else
          break
        end
      end

      loop do
        break if @eos_in_slice
        range = @slice_start_index..@slice_end_index
        slice_enum = Enumerator.new do |y|
          loop do
            break if range.max <= @index[@head]
            if @eos_in_slice = eos?
              y << @head
              break
            end
            head, @head = @head, @stream.first
            y << head
          end
        end
        @slice_start_index, @slice_end_index = range.max, @end_index[range.max]
        output[range: range, stream: EnumStream.new(slice_enum)]
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

  module_function
  def stream(obj)
    EnumStream.new(obj.to_enum)
  end

  def merge_streams(streams, comparator)
    loop do
      s1 = streams.shift
      return s1 if streams.empty?
      s2 = streams.shift
      streams << MergedStream.new([s1, s2], comparator)
    end
  end

  def slice_stream(index, step, start_index=nil)
    end_index = step.is_a?(Proc) ? step : lambda { |index| index + step }
    SliceStream.new(index, start_index, end_index)
  end

  def stream_each(&block)
    lambda do |output|
      lambda do |i|
        block[i]
        output[i]
      end
    end
  end

  def stream_map(&block)
    lambda { |output| lambda { |i| output[block[i]] } }
  end

  def stream_filter(&block)
    lambda { |output| lambda { |i| output[i] if block[i] } }
  end
  alias :stream_select :stream_filter

  def counter
    count = 0
    counter = Enumerator.new { |y| loop { y << (count += 1) } }
    stream(counter)
  end

end
