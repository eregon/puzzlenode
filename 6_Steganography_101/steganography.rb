class Bitmap
  FILE_HEADER_SIZE = 14
  DIB_HEADER_SIZE = 40
  PIXEL_ARRAY_ADDRESS = 10

  def initialize(path)
    @path = path
    parse_header
    parse_pixel_array
  end

  def encode_message(message)
    hidden_binary_message = message.unpack('C*').map { |i|
      i.to_s(2).rjust(8, '0')
    }.join.chars.map(&:to_i)

    if hidden_binary_message.size > @width * @height
      $stderr.puts "Too long message, truncating it."
      hidden_binary_message = hidden_binary_message[0, @width * @height]
    end

    @height.times { |y|
      @width.times { |x|
        if hidden_binary_message[y*@width+x] == 1
          @pixels[y][x] += 1 if @pixels[y][x].even?
        else # fill the rest with zeros
          @pixels[y][x] -= 1 if @pixels[y][x].odd?
        end
      }
    }
  end

  def pixel_array
    @height.times.with_object("") { |i, str|
      str << @pixels[i].pack('C*').tap { |row|
        row << 0 while row.size < @row_size # pad row with zeros
      }
    }
  end

  def save(path)
    header = File.binread(@path, @pixel_array_offset)
    footer = File.binread(@path, nil, @pixel_array_offset + @pixel_array_size)

    File.open(path, 'wb') { |file|
      file << header << pixel_array << footer
    }
  end

  private
  def parse_header
    header = File.binread(@path, FILE_HEADER_SIZE + DIB_HEADER_SIZE)
    @pixel_array_offset = header[PIXEL_ARRAY_ADDRESS, 4].unpack('L')[0]

    size, @width, @height, _, @color_depth, compression, @pixel_array_size =
      header[FILE_HEADER_SIZE, 4*3+2*2+4*2].unpack('Ll2S2L2')

    raise "Incorrect DIB header size" unless size == DIB_HEADER_SIZE
    raise "Only handles 8-bit color depth" unless @color_depth == 8
    raise "Compressed image" unless compression == 0
    raise "Invalid height: (#{@height})" unless @height > 0
  end

  def parse_pixel_array
    pixel_array = File.binread(@path, @pixel_array_size, @pixel_array_offset)
    @row_size = row_bytes = @color_depth * @width / 8
    @row_size += 1 until @row_size % 4 == 0 # pad to a multiple of 4 bytes
    raise "Invalid image size" unless @pixel_array_size == @row_size * @height

    @pixels = @height.times.map { |i|
        pixel_array[i*@row_size, row_bytes].unpack('C*')
    }
  end
end

input, output = if ARGV.delete '-s'
  ['sample_input.txt', 'out.bmp']
else
  ['input.txt', 'solution.bmp']
end

bitmap = Bitmap.new('input.bmp')
message = File.read(input)
bitmap.encode_message(message)
bitmap.save(output)
