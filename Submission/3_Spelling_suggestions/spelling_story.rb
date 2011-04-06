Input = ARGV.delete('-s') ? 'sample-input.txt' : 'input.txt'

=begin
problem's example:
numm and nom => nm (2)

levenshtein:
min(top+1, left+1, top-left + (same letters))
     n  u  m  m
  0  1  2  3  4
n 1  0  1  2  3
o 2  1  1  2  3
m 3  2  2  1  2

inverted levenshtein:
min(top, left, top-left - (same letters))
     n  u  m  m
  0  1  2  3  4
n 1 -1 -1 -1 -1
o 2 -1 -1 -1 -1
m 3 -1 -1 -2 -2

common subsequences:
max(top, left, top-left + (same letters))
     n  u  m  m
  0  0  0  0  0
n 0  1  1  1  1
o 0  1  1  1  1
m 0  1  1  2  2

=end

class String
  class << self
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

    def common_subsequence(a, b)
      row	= [0]*(a.size+1)
      b.size.times do |y|
        prow = row
        row = [0]

        a.size.times do |x|
          row[x+1] = [
            prow[x+1],
            row[x],
            prow[x] + (a[x] == b[y] ? 1 : 0)
          ].max
        end
      end

      row[-1]
    end
  end

  def include_sequence? seq
    seq.inject(-1) { |i, char|
      index(char, i+1) or return false
    }
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

lines = File.read(Input).scan(/^(\w+)\n(\w+)\n(\w+)$/) { |misspelled, *words|
  puts words.max_by { |word| String.common_subsequence(misspelled, word) }
}
