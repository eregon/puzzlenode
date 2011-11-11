module AllWiredUp
  GATES = {
    'A' => -> a, b { a & b },
    'O' => -> a, b { a | b },
    'X' => -> a, b { a ^ b },
    'N' => -> a { !a }
  }

  INPUTS = '0'..'1'
  WIRE = %w[- |]
  GATE = GATES.keys
  LIGHT_BULB = ['@']
  GATE_BULB = GATE + LIGHT_BULB
  WIRE_GATE_BULB = WIRE + GATE + LIGHT_BULB

  Place = Struct.new(:x, :y, :map) do
    def inspect
      "(#{x},#{y})"
    end

    def at
      (map[y] || [])[x]
    end

    def right!
      self.x += 1 if WIRE_GATE_BULB.include? map[y][x+1]
    end

    def down!
      self.y += 1 if !@up and map[y+1] and WIRE_GATE_BULB.include? map[y+1][x]
    end

    def up!
      if y > 0 and WIRE_GATE_BULB.include? map[y-1][x]
        self.y -= 1
        @up = true
      end
    end
  end

  class Circuit
    attr_reader :map
    def initialize(str)
      @map = str.lines.map { |line| line.chomp.chars.to_a }
    end

    def solve
      find_inputs
      unleash_power
    end

    def find_inputs
      @inputs = @map.each_with_index.with_object([]) { |(row, y), inputs|
        row.each_with_index { |c, x|
          inputs << Input.new(c == '1', Place.new(x, y, @map)) if INPUTS.include? c
        }
      }
    end

    def unleash_power
      loop do
        @inputs.each(&:go_until_gate)

        break if @inputs.first.pos.at == LIGHT_BULB[0]

        @inputs.each { |input|
          next unless @inputs.include? input
          other = @inputs.find { |other|
            !other.equal?(input) and input == other
          }
          if other
            input.value = GATES[input.pos.at][input.value, other.value]
            input.pos.right!
            @inputs.delete other
          elsif input.pos.at == 'N'
            input.value = !input.value
            input.pos.right!
          else
            # wait other to arrive
          end
        }
      end
      puts @inputs.first.value ? 'on' : 'off'
    end
  end

  class Input
    attr_accessor :value
    attr_reader :pos
    def initialize(value, pos)
      @value, @pos = value, pos
    end

    def go_until_gate
      until GATE_BULB.include? @pos.at
        @pos.right! or @pos.down! or @pos.up!
      end
    end

    def == other
      @pos == other.pos
    end
  end
end

File.read('complex_circuits.txt').split("\n\n").each { |circuit|
  AllWiredUp::Circuit.new(circuit).solve
}

