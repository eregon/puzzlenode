# Robots vs Lasers

# This is a tight embrace of square brackets and curly braces

Input = 'input.txt'
Input.prepend 'sample-' if ARGV.delete '-s'

Directions = [:west, :east]

def destiny(lasers, start)
  positions, damages = Hash.new(start), Hash.new(0)
  exits = { west: 0, east: lasers.first.size-1 }
  other = -> d { Directions.find { |dir| dir != d } }
  go = -> d { "GO #{d.upcase}" }

  [exits[:west]+start, exits[:east]-start].max.times { |click|
    { west: -1, east: 1 }.each_pair { |direction, step|
      position = positions[direction]
      if position == exits[direction]
        return go[direction] if damages[other[direction]] > damages[direction]
      else
        damages[direction] += 1 if lasers[click % 2][position]
        positions[direction] += step
      end
    }
  }
  go.call Directions.min_by { |d| damages[d] }
end

File.readlines(Input).map(&:chomp).reject(&:empty?).each_slice(3) { |north, robot, south|
  lasers = [north, south].map { |side| side.chars.map { |c| c == '|' } }
  puts destiny(lasers, robot.index('X'))
}
