Input = ARGV.delete('-s') ? 'SAMPLE_INPUT.txt' : 'INPUT.txt'

=begin
problem's example:
numm and nom => nm (2)

  n  u  m  m
n 1  1  1  1
o 1  1  1  1
m 1  1  2  2

levenshtein:
min(top+1, left+1, top-left + (same letters ? 0 : 1))
     n  u  m  m
  0  1  2  3  4
n 1  0  1  2  3
o 2  1  1  2  3
m 3  2  2  1  2

inverted levenshtein:
min(top, left, top-left - (same letters ? 1 : 0))
     n  u  m  m
  0  1  2  3  4
n 1 -1 -1 -1 -1
o 2 -1 -1 -1 -1
m 3 -1 -1 -2 -2

common subsequences:
max(top, left, top-left - (same letters ? 1 : 0))

=end

class << String
  def levenshtein_recur(a, b)
    case
    when a.empty?
      b.length
    when b.empty?
      a.length
    else
      [
        (a[0] == b[0] ? 0 : 1) + levenshtein_recur(a[1..-1], b[1..-1]),
        1 + levenshtein_recur(a[1..-1], b),
        1 + levenshtein_recur(a, b[1..-1])
      ].min
    end
  end

  def levenshtein(a, b)
    row = (0..a.length).to_a
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
  def invert_levenshtein1(a, b)
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

  def invert_levenshtein(a, b)
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

class String
  def include_sequence? seq
    seq.inject(-1) { |i, char|
      index(char, i+1) or return false
    }
    true
  end

  def choose(a, b)
    c = chars.to_a
    (1..length).each { |l|
      ar, br = false, false
      c.combination(l).each { |seq| # combination => O(2**n)
        break if ar & br
        ar ||= a.include_sequence? seq
        br ||= b.include_sequence? seq
      } # 3 years later
      if ar ^ br
        return ar ? a : b
      elsif !(ar & br)
        raise "both fail at #{l}"
      end
    }
  end
end

lines = File.read(Input).lines
lines.next.to_i.times.map {
  lines.next
  3.times.map { lines.next.chomp }
}.each { |group|
  misspelled, *words = group
  #puts misspelled.choose(*words)
  puts words.min_by { |word| String.invert_levenshtein(misspelled, word) }
}

p String.invert_levenshtein1('numm', 'nom')
