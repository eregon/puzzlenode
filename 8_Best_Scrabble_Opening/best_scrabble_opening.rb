require 'json'

module Scrabble
  extend self

  class Board
    attr_reader :width, :height, :values
    def initialize(values)
      @values = values
      @height, @width = values.size, values[0].size
    end

    def at(place)
      @values[place.y][place.x]
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

  Place = Struct.new(:x, :y, :direction) do
    def next!
      if direction == :horizontal
        self.x += 1
      else
        self.y += 1
      end
    end
  end

  def best_opening(input)
    board, dictionary, letters, values = parse_input(input)

    words = possible_words(dictionary, letters)

    best_word, best_place = max_by_keys(words) { |word|
      score, place = max_by_keys(places_for(word, board)) { |position|

        place, score = position.dup, 0
        word.each_char { |letter|
          score += board.at(place) * values[letter]
          place.next!
        }

        [score, score, position]
      }
      [score, word, place]
    }

    board.play(best_word, best_place)

    board
  end

  def possible_words(dictionary, letters)
    dictionary.select { |word|
      count_letters(word).all? { |letter, count|
        letters[letter] and letters[letter] >= count
      }
    }
  end

  def places_for(word, board)
    (0...board.height).each_with_object([]) { |y, places|
      (0...board.width).each { |x|
        places << Place.new(x, y, :horizontal) if x + word.size <= board.width
        places << Place.new(x, y, :vertical)   if y + word.size <= board.height
      }
    }
  end

  private
  def parse_input(file)
    data = JSON.parse File.read file

    board = Board.new data['board'].map { |line| line.split.map(&:to_i) }

    dictionary = data['dictionary']

    letters, values = Hash.new(0), {}
    data['tiles'].each { |tile|
      letter, value = tile[0], tile[1..-1].to_i
      letters[letter] += 1
      values[letter] = value
    }

    [board, dictionary, letters, values]
  end

  def count_letters(word)
    word.each_char.with_object(Hash.new(0)) { |c, h| h[c] += 1 }
  end

  # Save all keys passed in the Array returned in the block
  #   while maximizing the first element.
  #
  # Equivalent to enum.map { |e| [value(e), *keys] }.max_by(&:first)[1..-1]
  #
  #   places.max_by_keys { |place|
  #     [score, score, place]
  #   } # => [best score, place corresponding]
  def max_by_keys(enum)
    best_value = nil
    best_to_keep = nil
    enum.each { |e|
      value, *to_keep = yield(e)
      if best_value == nil or value > best_value
        best_value = value
        best_to_keep = to_keep
      end
    }
    best_to_keep
  end
end

if __FILE__ == $0
  abort "ruby #{$0} input.json" if ARGV.size != 1
  print Scrabble.best_opening(ARGV.first)
end
