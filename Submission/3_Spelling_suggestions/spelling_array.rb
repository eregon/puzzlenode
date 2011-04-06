Input = 'input.txt'
Input.prepend 'sample-' if ARGV.delete '-s'

[true,false].each { |bool|
  bool.define_singleton_method(:coerce) { |other|
    [other, self ? 1 : 0]
  }
}

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

def String.common_subsequence_array(a, b)
  rows = Array.new(a.size+1) { [0]*(b.size+1) }

  rows.each_with_index { |row, i|
    row.each_with_index { |e, j|
      next if i*j == 0
      rows[i][j] = [rows[i-1][j], rows[i][j-1], rows[i-1][j-1] + (a[i-1] == b[j-1])].max
    }
  }

  rows.last.last
end

def String.common_subsequence_hash(a, b)
  Hash.new { |h, (i,j)|
    i*j == 0 ? 0 : h[[i,j]] = [h[[i-1,j]], h[[i,j-1]], h[[i-1,j-1]] + (a[i-1] == b[j-1])].max
  }[[a.size,b.size]]
end

def String.longest_common_subsequence a,b
  Hash.new { |h, r| i, j = r.begin, r.end
    i*j == 0 ? 0 : h[i..j] = [h[i-1..j], h[i..j-1], h[i-1..j-1] + (a[i-1] == b[j-1])].max
  }[a.size..b.size]
end

lines = File.read(Input).scan(/^(\w+)\n(\w+)\n(\w+)$/) { |misspelled, *words|
  puts words.max_by { |word| String.longest_common_subsequence(misspelled, word) }
}
