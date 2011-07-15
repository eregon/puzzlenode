require 'forwardable'

class Card
  VALUES = [*(2..10), :J, :Q, :K, :A]
  SUITS = [:C, :D, :S, :H]
end

class Player
  extend Forwardable

  def Player.[](name)
    @players ||= []
    @players.find(-> { Player.new(name).tap { |p| @players << p } }) { |player| player.name == name }
  end
  def Player.all
    @players
  end

  attr_reader :name, :hand
  def initialize name
    @name = name
    @hand = []
  end

  delegate :<< => :@hand
  def_instance_delegator :@hand, :delete, :>>
end

class Move
  def initialize str
    raise "Invalid move: #{str}" unless str =~ /((?:\+|-))(#{CARD})(?:\:(#{PLAYER}))?/
    @get = $1 == ?+ # vs give
    @card = $2
    @player = $3
  end

  def known?
    @card != UNKNOWN_CARD
  end

  def apply player
    if @get
      unless DISCARD_PILE.include? @card
        player << @card
        Player[@player] >> @card if @player
      end
    else
      player >> @card
      if @player == 'discard'
        DISCARD_PILE << @card
      else
        Player[player] << @card
      end
    end
  end
end

DISCARD_PILE = []
UNKNOWN_CARD = '??'
CARD = /(?:(?:#{Card::VALUES.join('|')})(?:#{Card::SUITS.join('|')}))|#{Regexp.escape UNKNOWN_CARD}/
PLAYER = /[A-Z][a-z]+|discard/
MOVE = /(?:\+|-)#{CARD}(?:\:#{PLAYER})?/

Lil = Player['Lil']

all_moves = File.readlines 'SAMPLE_INPUT.txt'
all_moves.each(&:chomp!)
until all_moves.empty?
  all_moves.shift(4).each { |move|
    if move =~ /^(#{PLAYER}) *((?: #{MOVE})+)$/
      player, moves = $1, $2.split(' ')
      moves.map! { |move| Move.new move }
      if player == '*'
        # assume truth # TODO
        moves.each { |move|
          move.apply(Lil)
        }
      else
        player = Player[player]
        moves.select(&:known?).each { |move|
          move.apply(player)
        }
      end
    else
      raise "Invalid move: #{move}"
    end
  }

  signals = []
  while !all_moves.empty? and all_moves.first[0] == ?*
    signals << all_moves.shift
  end

  signals.each { |move|
    if move =~ /^\* *((?: #{MOVE})+)$/
      moves = $1.split(' ')
      moves.map! { |move| Move.new move }

      # assume truth # TODO
      moves.each { |move|
        move.apply(Lil)
      }
    else
      raise "Invalid move: #{move}"
    end
  }

  puts Lil.hand.join(' ')
end
