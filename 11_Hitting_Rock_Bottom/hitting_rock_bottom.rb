WATER = '~'
EMPTY = ' '

map = File.readlines 'complex_cave.txt'#'simple_cave.txt'
map.map(&:chomp!)

water_units = map.shift(2)[0].to_i - 1

map.map! { |row| row.chars.to_a }

class Water
  attr_reader :x, :y
  def initialize(x, y, map)
    @x, @y, @map = x, y, map
  end

  def down!
    @y += 1 if @map[@y+1][@x] == EMPTY
  end

  def right!
    @x += 1 if @map[@y][@x+1] == EMPTY
  end

  def fill_upper!
    @y -= 1 until @map[@y][@x] == EMPTY
    while @map[@y][@x-1] == EMPTY and @x > 0
      @x -= 1
    end
    true
  end

  def to_s
    @map.map(&:join) * "\n"
  end
end

water = nil
map.each_with_index.find { |row, y|
  row.each_with_index.find { |cell, x|
    water = Water.new(x, y, map) if cell == WATER
  }
}

while water.down! or water.right! or water.fill_upper!
  if map[water.y][water.x] != EMPTY
    p "already sth at #{water.x},#{water.y}"
    map[water.y][water.x] = 'O'
  else
    map[water.y][water.x] = WATER
  end
  water_units -= 1
  break if water_units == 0
end

p water if $VERBOSE
p water.to_s.count WATER if $VERBOSE

transposed = map.transpose
print transposed.map { |column|
  count = column.count(WATER)
  if count > 0 and column[column.rindex(WATER) + 1] == EMPTY
    WATER
  else
    count
  end
} * ' '
