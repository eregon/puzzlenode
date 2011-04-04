def longest_common_subsequence(chars1, chars2)
  if chars1.empty? or chars2.empty?
    []
  elsif chars1.last == chars2.last
    longest_common_subsequence(chars1[0..-2], chars2[0..-2]) << chars1.last
  else
    variant1 = longest_common_subsequence(chars1, chars2[0..-2])
    variant2 = longest_common_subsequence(chars1[0..-2], chars2)
    variant1.size >= variant2.size ? variant1 : variant2
  end
end

results = []

File.open('INPUT.txt') do |input|
  words_number = input.gets.to_i

  words_number.times do
    word, variant1, variant2 = input.gets('').split("\n")

    longest1 = longest_common_subsequence word.chars.to_a, variant1.chars.to_a
    longest2 = longest_common_subsequence word.chars.to_a, variant2.chars.to_a

    results.push((longest1.size > longest2.size) ? variant1 : variant2)
  end
end

puts results
