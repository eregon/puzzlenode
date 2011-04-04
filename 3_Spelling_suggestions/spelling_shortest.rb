File.read('INPUT.txt').scan(/^(\w+)\n(\w+)\n(\w+)$/) { |m, *words|
  puts words.max_by { |w|
    Hash.new { |h, r| i, j = r.begin, r.end
      i*j == 0 ? 0 : h[i..j] = [h[i-1..j], h[i..j-1], h[i-1..j-1] + (m[i-1] == w[j-1] ? 1 : 0)].max
    }[m.size..w.size]
  }
}
