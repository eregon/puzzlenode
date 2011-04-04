Input = 'INPUT.txt'
Input.prepend 'SAMPLE_' if ARGV.delete '-s'

def String.common_subsequence(a, b)
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

lines = File.read(Input).scan(/^(\w+)\n(\w+)\n(\w+)$/) { |misspelled, *words|
  puts words.max_by { |word| String.common_subsequence(misspelled, word) }
}
