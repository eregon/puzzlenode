
Input = 'sample-input.txt'
Start = 'A'
Arrival = 'Z'

=begin
example 2:
A B 08:00 09:00 50.00
A B 12:00 13:00 300.00
A C 14:00 15:30 175.00
B C 10:00 11:00 75.00
B Z 15:00 16:30 250.00
C B 15:45 16:45 50.00
C Z 16:00 19:00 100.00
sol:
12:00 16:30 550.00
flights:
A B 12:00 13:00 300.00
B Z 15:00 16:30 250.00
=end

class Hour
  include Comparable
  def initialize(hour)
    @h, @m = hour.split(':').map(&:to_i)
  end
  
  def to_i
    @h * 60 + @m
  end

  def to_s
    [@h,@m].map { |e| '%02d' % e }.join(':')
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
  
  def > flight
    departure >= flight.arrival
  end
end

# vertices: Array of vertice
# edges: lambda { |from_vertice, prev| } # => Array of Array[to_vertice, edge, added_dist]
# start: vertice
# arrival: vertice
def dijkstra(vertices, edges, start, arrival)
	dist = Hash.new(Float::INFINITY)
	prev = {}
	dist[start] = 0
	q = vertices.dup
	
	until q.empty?
		u = q.min_by { |v| dist[v] }
		return prev, dist if u == arrival
		q.delete(u)
		edges[u, prev].each do |v, edge, added_dist|
			alt = dist[u] + added_dist
      if alt < dist[v]
        dist[v] = alt
        prev[v] = edge
      end
		end
	end
end

def time_with(flight, flights, path = [flight.from, flight.to])
  p flight
  if flight.to == Arrival
    flight.arrival - flight.departure
  else
    flights.select { |f| f.from == flight.to and f > flight and !path.include? f.to }.map { |f|
      f.departure - flight.departure + time_with(f, flights, path + [f.to])
    }.min || 100_000
  end
end

def my_solver(airports, flights)
  best = flights.select { |f| f.from == Start }.min_by { |f|  
    p time_with(f, flights)
  }
end

# simpler: create all possible paths, then choose best
def solver(flights)
  (p all_paths(flights)).min_by { |path| cost_of_path(path) }
end

def solver_spent(flights)
  all_paths(flights).min_by { |path| path.map(&:price).reduce(:+) }
end


def cost_of_path(path)
  path.last.arrival - path.first.departure
end

def all_paths(flights, from = Start)
  paths = []
  flights.select { |f| f.from == Start }.each { |flight|
    sub(paths, flight, flights)
  }
  paths
end

def sub(paths, flight, flights, visited = [flight.from, flight.to], path = [flight])
  if flight.to == Arrival
    paths << path
  else
    flights.select { |f| f.from == flight.to and f > flight and !path.include? f.to }.each { |f|
      sub(paths, f, flights, visited + [f.to], path + [f])
    }
  end
end

lines = File.readlines(Input)
flight_groups = lines.shift.to_i.times.map { 
  lines.shift
  lines.shift.to_i.times.map {
    Flight.new(*lines.shift.split)
  }
}

flight_groups.each { |flights|
  # vertices = flights.inject([]) { |v, flight| v | [flight.from, flight.to] }
  # 
  # find_first_flight = lambda { |from, flight, prev|
  #   until flight.from == Start
  #     flight = prev[flight.from]
  #   end
  #   flight
  # }
  # 
  # edges_min_duration = lambda { |from, prev|  
  #   flights.select { |flight| flight.from == from }.map { |flight|
  #     # cost = flight.arrival - find_first_flight[from, flight, prev].departure
  #     cost = flight.arrival - (flight.from == Start ? flight.departure : prev[flight.from].departure)
  #     [flight.to, flight, cost]
  #   }
  # }
  # 
  # prev, dist = dijkstra(vertices, edges_min_duration, Start, Arrival)
  # 
  # path = [prev[Arrival]]
  # until path.last.from == Start
  #   path << flights.find { |f| f.to == path.last.from }
  # end
  # path = path.reverse
  # p dist if $VERBOSE
  # p prev if $VERBOSE
  # p path if $VERBOSE
  # 
  # cost = path.map(&:price).reduce(:+)
  # puts [path.first.departure, path.last.arrival, '%.2f' % cost].join(' ')
  # 
  # puts
  #p my_solver(vertices, flights)
  path = solver_spent(flights)
  p path if $VERBOSE
  spent = path.map(&:price).reduce(:+) # /!\ cost of money here, not time
  puts [path.first.departure, path.last.arrival, '%.2f' % spent].join(' ')
  
  path = solver(flights)
  p path if $VERBOSE
  spent = path.map(&:price).reduce(:+) # /!\ cost of money here, not time
  puts [path.first.departure, path.last.arrival, '%.2f' % spent].join(' ')
  
  puts
}










