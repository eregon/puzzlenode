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

  def best_opening(input)
    data = JSON.parse File.read input

    board = Board.new data['board'].map { |line| line.split.map(&:to_i) }

    dictionary = data['dictionary']

    letters, letter_values = Hash.new(0), {}
    data['tiles'].each { |tile|
      letter, value = tile[0], tile[1..-1].to_i
      letters[letter] += 1
      letter_values[letter] = value
    }

    # select doable
    words = dictionary.select { |word|
      count_letters(word).all? { |letter, count|
        letters[letter] and letters[letter] >= count
      }
    }

    # find best place
    _, best_word, best_place = words.max_by_keys { |word|
      score, place = places_for(word, board).max_by_keys { |starting_position|
        place = starting_position.dup
        score = word.chars.inject(0) { |s, letter|
          value = board.values[place.y][place.x] * letter_values[letter]
          place.next!
          s + value
        }
        [score, starting_position]
      }
      [score, word, place]
    }

    board.play(best_word, best_place)
    print board
  end

  def places_for(word, board)
    places = []
    (0...board.height).each { |y|
      (0...board.width-word.size).each { |x|
        places << StartPosition.new(x, y, :horizontal)
      }
    }
    (0...board.height-word.size).each { |y|
      (0...board.width).each { |x|
        places << StartPosition.new(x, y, :vertical)
      }
    }
    places
  end

  private
  def count_letters(word)
    word.chars.each_with_object(Hash.new(0)) { |c, h| h[c] += 1 }
  end
end

Scrabble.best_opening('EXAMPLE_INPUT.json')
#Scrabble.best_opening('INPUT.json')
