require 'json'

module Enumerable
  # save all keys passed at the end of Array passed for max
  # [value maximised, what_to_keep]
  # => [max, what_to_keep from max]
  def max_by_keys
    best_value = nil
    best_to_keep = nil
    each { |e|
      value, *to_keep = yield(e)
      if best_value == nil or value > best_value
        best_value = value
        best_to_keep = to_keep
      end
    }
    [best_value, *best_to_keep]
  end
end

module Scrabble
  extend self

  class Board
    attr_reader :width, :height, :values
    def initialize(values)
      @values = values
      @height, @width = values.size, values[0].size
    end

    def play(word, place)
      word.each_char { |letter|
        @values[place.y][place.x] = letter
        place.next!
      }
    end

    def to_s
      @values.map { |row| row.join(' ') }.join("\n")
    end
  end

  StartPosition = Struct.new(:x, :y, :direction) do
    def next!
      if direction == :horizontal
        self.x += 1
      else
        self.y += 1
      end
    end
  end
  Tile = Struct.new(:letter, :value)

  def best_opening(input)
    data = JSON.parse(File.read(input))

    board = Board.new data['board'].map { |line| line.split.map(&:to_i) }

    dictionary = data['dictionary']

    tiles = data['tiles'].map { |tile| Tile.new tile[0], tile[1..-1].to_i }
    letters = tiles.map(&:letter).each_with_object(Hash.new(0)) { |c, h| h[c] += 1 }
    letter_values = tiles.each_with_object({}) { |t, h| h[t.letter] = t.value }

    # select doable
    words = dictionary.select { |word|
      word.chars.each_with_object(Hash.new(0)) { |c, h| h[c] += 1 }.all? { |letter, count|
        letters[letter] and letters[letter] >= count
      }
    }

    # find best place
    score, word, place = words.max_by_keys { |word|
      score, best_place = places_for(word, board).max_by_keys { |starting_position|
        place = starting_position.dup
        score = word.chars.inject(0) { |score, letter|
          value = board.values[place.y][place.x] * letter_values[letter]
          place.next!
          score + value
        }
        [score, starting_position]
      }
      [score, word, best_place]
    }
#p [word, place]

    board.play(word, place)
    print board
  end

  def places_for(word, board)
    [].tap { |places|
      (0...board.height).each { |y|
        (0...board.width-word.size).each { |x| places << StartPosition.new(x, y, :horizontal) }
      }
      (0...board.height-word.size).each { |y|
        (0...board.width).each { |x| places << StartPosition.new(x, y, :vertical) }
      }
    }
  end
end

Scrabble.best_opening('EXAMPLE_INPUT.json')
#Scrabble.best_opening('INPUT.json')
