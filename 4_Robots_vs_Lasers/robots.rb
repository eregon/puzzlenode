Input = ARGV.delete('-s') ? 'sample-input.txt' : 'input.txt'

Directions = [:west, :east]

def best_way(lasers, start)
  conveyor_size = lasers.first.size
  positions = { west: start, east: start }
  damages = Hash.new(0)
  conveyor_exits = { west: 0, east: conveyor_size-1 }
  
  other = -> d { Directions.find { |dir| dir != d } }
  go = -> d { "GO #{d.upcase}" }

  [start, conveyor_size-start-1].max.times { |click|
    { west: -1, east: 1 }.each_pair { |direction, step|
      position = positions[direction]
      if position == conveyor_exits[direction]
        if damages[other[direction]] > damages[direction]
          return go[direction]
        end
      else
        damages[direction] += 1 if lasers[click % 2][position]

        positions[direction] += step
      end
    }
  }
  go[Directions.min_by { |d| damages[d] }]
end

File.readlines(Input).map(&:chomp).reject(&:empty?).each_slice(3) { |north, robot, south|
  lasers = [north, south].map { |side| side.chars.map { |c| c == '|' } }
  #p [north, robot, south]
  #p lasers
  puts best_way(lasers, robot.index('X'))
}
