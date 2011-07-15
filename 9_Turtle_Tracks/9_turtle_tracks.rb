module Logo
  class Position
    attr_reader :x, :y
    def initialize(x, y)
      @x, @y = x, y
    end

    def + p
      Position.new x + p.x, y + p.y
    end

    def - p
      Position.new x - p.x, y - p.y
    end

    def inspect
      "(#{x},#{y})"
    end
  end

  DIRECTIONS = [:N, :NE, :E, :SE, :S, :SW, :W, :NW].map.with_index { |dir, i|
    x = i % 4 == 0 ? 0 : (i < 4 ? 1 : -1)
    y = i % 4 == 2 ? 0 : ((4-i).abs < 2 ? 1 : -1)
    Logo.const_set dir, Position.new(x, y)
  }

  class Interpreter
    def initialize(width, commands)
      @grid = Array.new(width) { [false]*width }
      @commands = commands
      @orientation = 0
      @position = Position.new width/2, width/2
    end

    def direction
      DIRECTIONS[@orientation]
    end

    def mark
      @grid[@position.y][@position.x] = true
    end

    def step
      if command = @commands.shift
        case command
        when /^REPEAT (\d+) \[ (.+) \]$/
          n, c = $1.to_i, $2
          n.times { @commands.unshift c }
        when /^(R|L)T (\d+)$/ # turn right / left
          @orientation += ($1 == 'R' ? $2.to_i : -$2.to_i) / 45
          @orientation %= DIRECTIONS.size
        when /^(FD|BK) (\d+)$/ # walk forward / backwards
          $2.to_i.times { |i|
            mark
            $1 == 'FD' ? @position += direction : @position -= direction
          }
          mark
        when /^([A-Z]+ (?:\d+)) (.+)$/ # two commands
          @commands.unshift $1, $2
        else
          raise "Unknown command: #{command}"
        end
        true
      end
    end

    def run
      nil while step
    end

    def to_s
      @grid.map { |row|
        row.map { |cell| cell ? 'X' : '.' }.join(' ')
      }.join("\n")
    end

    def to_gplot
      x, y = [], []
      @grid.each_with_index { |row, i|
        row.each_with_index { |cell, j|
          if cell
            x << j
            y << i
          end
        }
      }
      [x, y]
    end

    def gnuplot
      require 'gnuplot'
      Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
          plot.title  "Turtle tracks"
          plot.data << Gnuplot::DataSet.new(to_gplot) # use self instead of to_gplot for fun
        end
      end
    end
  end

  def Logo.parse_input(file)
    lines = File.readlines file
    lines.each(&:chomp!)
    [lines.shift(2)[0].to_i, lines]
  end
end
interpreter = Logo::Interpreter.new(*Logo.parse_input('complex.logo'))
interpreter.run
#puts interpreter
interpreter.gnuplot
