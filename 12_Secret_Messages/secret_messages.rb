# encoding: utf-8

Dict = File.readlines '/usr/share/dict/words'
Dict.each(&:chomp!)
Dict.each { |word| word.upcase! }
A = 'A'.ord

def find_Ceasar_shift(encrypted_key)
  words = Dict.select { |word| word.size == encrypted_key.size }
  found = []
  (0...26).each { |shift|
    decrypted = decrypt_Ceasar(encrypted_key, shift)
    found << decrypted if words.include? decrypted
  }
  found
end

def decrypt_Ceasar(encrypted, shift)
  encrypted.chars.map { |c|
    if ('A'..'Z') === c
      ((c.ord - A - shift) % 26 + A).chr
    else
      c
    end
  }.join
end

def decrypt_Vigenère(encrypted, key)
  key = key.bytes.map { |b| b - A }
  encrypted.chars.map { |c|
    if ('A'..'Z') === c
      ((c.ord - A - key[0]) % 26 + A).chr.tap { key.rotate! }
    else
      c
    end
  }.join
end

input = File.readlines 'complex_cipher.txt'#'simple_cipher.txt'
input.each(&:chomp!)

encrypted_key = input.shift(2)[0]

encrypted_text = input.join("\n")

key = find_Ceasar_shift(encrypted_key)
if key.size == 1
  key = key[0]
  print decrypt_Vigenère(encrypted_text, key)
else
  p key
end


