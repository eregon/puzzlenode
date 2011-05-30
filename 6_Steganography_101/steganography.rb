class Bitmap
  FILE_HEADER_SIZE = 14
  DIB_HEADER_SIZE = 40
  
  def initialize(path)
    @path = path
    parse_header
    parse_pixel_array
  end
  
  def parse_header
    header = File.binread(@path, FILE_HEADER_SIZE + DIB_HEADER_SIZE)
    @pixel_array_offset = header[0xA, 4].unpack('L')[0]
    
    dib_header_size, @width, @height, _, @color_depth, compression, @pixel_array_size =
      header[FILE_HEADER_SIZE, 4+4+4+2+2+4+4].unpack('Ll2SSLL')
    raise "Incorrect DIB header size" unless dib_header_size == DIB_HEADER_SIZE
    raise "Only handles 8-bit color depth" unless @color_depth == 8
    raise "Compressed image" unless compression == 0
  end
  
  def parse_pixel_array
    pixel_array = File.binread(@path, @pixel_array_size, @pixel_array_offset)
    @row_size = (@color_depth * @width / 32.0).ceil * 4
    row_bytes = @color_depth * @width / 8
    raise "Invalid image size" unless @pixel_array_size == @row_size * @height

    @pixels = @height.times.map { |i|
        pixel_array[i*@row_size, row_bytes].unpack('C*')
    }
  end
  
  def encode_message(message)
    hidden_binary_message = message.unpack('C*').map { |i|
      i.to_s(2).rjust(8, '0')
    }.join.chars.map(&:to_i)
    raise "Too long message" if hidden_binary_message.size > @width*@height

    @height.times { |y|
      @width.times { |x|
        bit = hidden_binary_message[y*@width+x] || 0 # fill with zeros the rest
        # if bit == 1
        #   @pixels[y][x] += 1 if @pixels[y][x].even?
        # else
        #   @pixels[y][x] -= 1 if @pixels[y][x].odd?
        # end
        @pixels[y][x] -= 1*(-1)**bit unless @pixels[y][x] % 2 == bit
      }
    }
  end
  
  def pixel_array
    @height.times.with_object("") { |i, str|
      str << @pixels[i].pack('C*').tap { |row|
        row << 0 while row.bytesize < @row_size
      }
    }
  end

  def save(path)
    header = File.binread(@path, @pixel_array_offset)
    footer = File.binread(@path, nil, @pixel_array_offset+@pixel_array_size)
    
    File.open(path, 'wb') { |file|
      file << header << pixel_array << footer
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
