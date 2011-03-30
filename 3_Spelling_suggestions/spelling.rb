Input = ARGV.delete('-s') ? 'SAMPLE_INPUT.txt' : 'INPUT.txt'

class String
  def self.levenshtein_slow(a, b)
  	case
  	when a.empty?
  		b.length
  	when b.empty?
  		a.length
  	else
  		[
  			(a[0] == b[0] ? 0 : 1) + levenshtein(a[1..-1], b[1..-1]),
  			1 + levenshtein(a[1..-1], b),
  			1 + levenshtein(a, b[1..-1])
  		].min
  	end
  end
  
  def levenshtein(a, b)
  	1.upto(b.length) do |y|
  		prow = row
  		row = [y]

  		1.upto(a.length) do |x|
  			row[x] = [
  				prow[x] + 1,
  				row[x-1] + 1,
  				prow[x-1] + (a[x-1] == b[y-1] ? 0 : 1)
  			].min
  		end
  	end

  	row[-1]
  end
  
  # inspired from levenshtein distance
  # sort of inverted algorithm
  def self.invert_levenshtein1(a, b)
    row	= (0..a.length).to_a
  	1.upto(b.length) do |y|
  		prow = row
  		row = [y]

  		1.upto(a.length) do |x|
  			row[x] = [
  				prow[x],
  				row[x-1],
  				prow[x-1] - (a[x-1] == b[y-1] ? 1 : 0)
  			].min
  		end
  	end

  	row[-1]
  end
  
  def self.invert_levenshtein(a, b)
    row	= (0..a.length).to_a
  	b.length.times do |y|
  		prow = row
  		row = [y+1]

  		a.length.times do |x|
  			row[x+1] = [
  				prow[x+1],
  				row[x],
  				prow[x] - (a[x] == b[y] ? 1 : 0)
  			].min
  		end
  	end

  	row[-1]
  end
end

lines = File.read(Input).lines
lines.next.to_i.times.map {
  lines.next
  3.times.map { lines.next.chomp }
}.each { |group|
  misspelled, *words = group
  puts words.min_by { |word| String.invert_levenshtein(misspelled, word) }
}
