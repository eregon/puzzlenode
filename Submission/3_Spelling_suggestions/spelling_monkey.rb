Input = 'INPUT.txt'
Input.prepend 'SAMPLE_' if ARGV.delete '-s'

[true, false].each { |bool|
  bool.define_singleton_method(:coerce) { |other|
    [other, self ? 1 : 0]
  }
}

class MyHash < Hash
  def [](i,j)
    super([i,j])
  end
  def []=(i,j,v)
    super([i,j],v)
  end
end

def String.common_subsequence_hash(a, b)
  MyHash.new { |h, (i,j)|
    i*j == 0 ? 0 : h[i,j] = [h[i-1,j], h[i,j-1], h[i-1,j-1] + (a[i-1] == b[j-1])].max
  }[a.size,b.size]
end

def String.common_subsequence_hash2(a, b)
  class << h = Hash.new { |h, (i,j)|
      i*j == 0 ? 0 : h[i,j] = [h[i-1,j], h[i,j-1], h[i-1,j-1] + (a[i-1] == b[j-1])].max
    }
    def [](i,j) super([i,j]) end
    def []=(i,j,v) super([i,j],v) end
  end
  h[a.size,b.size]
end

lines = File.read(Input).scan(/^(\w+)\n(\w+)\n(\w+)$/) { |misspelled, *words|
  puts words.max_by { |word| String.common_subsequence_hash2(misspelled, word) }
}

