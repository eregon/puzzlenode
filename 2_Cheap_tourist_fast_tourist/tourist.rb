require 'forwardable'

Input = ARGV.include?('-s') ? 'sample-input.txt' : 'input.txt'
Start, Arrival = 'A', 'Z'

class Array
  def all_min_by
    values = map { |e| yield(e) }
    min = values.min
    select.with_index { |e, i| values[i] == min }
  end
end

class Path
  extend Forwardable
  def initialize(path)
    @ary = path
  end

  #def_delegators :@ary, :join, :map, :last, :first
  delegate [:join, :each, :map, :last, :first] => :@ary

  def cost
    map(&:price).reduce(:+)
  end

  def duration
    @duration ||= last.arrival - first.departure
  end

  def to_s
    "#{first.departure} #{last.arrival} #{'%.2f' % cost}"
  end

  def inspect
    "#{join(', ')} => #{Hour.new(duration)} #{cost}$"
  end
end

class Hour
  include Comparable
  def initialize(hour)
    @h, @m = case hour
    when String
      hour.split(':').map(&:to_i)
    when Integer
      hour.divmod(60)
    end
  end

  def to_i
    @h * 60 + @m
  end

  def to_s
    [@h, @m].map { |e| '%02d' % e }.join(':')
  end

  def - hour
    to_i - hour.to_i
  end

  def <=>(hour)
    to_i <=> hour.to_i
  end
end

class Flight
  attr_reader :from, :to, :departure, :arrival, :price
  def initialize from, to, departure, arrival, price
    @from, @to = from, to
    @departure, @arrival = [departure, arrival].map { |hour| Hour.new(hour) }
    @price = price.to_i
  end

  def to_s
    "#{from}(#{departure}) -> #{to}(#{arrival}) #{price}$"
  end

  def > flight # self can be taken after flight
    flight.to == from and departure >= flight.arrival
  end
end

# simpler: create all possible paths, then choose best

def all_paths(flights, from = Start)
  flights.select { |f| f.from == Start }.each_with_object([]) { |flight, paths|
    sub(paths, flight, flights)
  }
end

def sub(paths, flight, flights, visited = [flight.from, flight.to], path = [flight])
  if flight.to == Arrival
    paths << Path.new(path)
  else
    flights.select { |f| f > flight and !visited.include? f.to }.each { |f|
      sub(paths, f, flights, visited + [f.to], path + [f])
    }
  end
end

lines = File.read(Input).lines
flight_groups = lines.next.to_i.times.map {
  lines.next
  lines.next.to_i.times.map {
    Flight.new(*lines.next.split)
  }
}

flight_groups.each_with_index { |flights, i|
  # remove flights going to Start or going from Arrival
  flights.reject! { |flight| flight.to == Start or flight.from == Arrival }

  # remove impossible flights
  flights.select! { |flight|
    flight.from == Start or flight.to == Arrival or flights.any? { |f| flight > f }
  }

  # remove bad flights
  flights.reject! { |flight|
    flights.any? { |better|
      better.from == flight.from and better.to == flight.to and
      better.price <= flight.price and better.departure >= flight.departure and better.arrival <= flight.arrival and
      (better.price < flight.price or better.departure > flight.departure or better.arrival < flight.arrival)
    }
  }

  flights.sort_by! { |flight| [flight.from, flight.to, flight.departure, flight.arrival] }

  if ARGV.include? '-g' # graph
    require 'graphviz'
    GraphViz.digraph(:G) { |g|
      nodes = Hash.new { |h, airport| h[airport] = g.add_node(airport) }
      flights.each { |flight|
        g.add_edge( nodes[flight.from], nodes[flight.to] )
      }
    }.output(svg: "graph/graph-#{Input}-#{i+1}-simplified2.svg")
  end

  all_paths = all_paths(flights)
#  all_paths.each { |path| p path } && puts if $DEBUG

  all_paths.all_min_by(&:cost).each { |path| p path } if $VERBOSE
  cheapest_path = all_paths.min_by(&:cost) # need a criteria to find shortest flights
  p cheapest_path if $DEBUG
  puts cheapest_path

  all_paths.all_min_by(&:duration).each { |path| p path } if $VERBOSE
  fast_path = all_paths.all_min_by(&:duration).min_by(&:cost)
  p fast_path if $DEBUG
  puts fast_path

  puts

  if ARGV.include? '-p' # draw paths
    require 'graphviz'
    GraphViz.digraph(:G) { |g|
      nodes = Hash.new { |h, airport| h[airport] = g.add_node(airport) }
      n = all_paths.size
      all_paths.each_with_index { |path, i|
        color = "##{(i * 256**3 / n).to_s(16)}"
        width = (path == cheapest_path or path == fast_path) ? 4 : 1
        path.each { |flight|
          g.add_edge( nodes[flight.from], nodes[flight.to], color: color, penwidth: width )
        }
      }
    }.output(svg: "graph/graph-#{Input}-#{i+1}-paths.svg")
  end
}










