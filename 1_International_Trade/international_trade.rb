# require 'csv' # 0.284 => 0.245
require 'nokogiri'

class CSV
  class << self
    def rows(file) # 0.476 => 0.461
      to_enum(:foreach, file)
    end

    def fast(file) # 0.461 => 0.340
      return to_enum(__method__, file) unless block_given?
      File.foreach(file) { |line|
        yield(*line.chomp.split(','))
      }
    end
  end
end

Sample = !true
trans_file, rates_file = 'TRANS.csv', 'RATES.xml'
[trans_file, rates_file].each { |file| file.prepend('SAMPLE_') if Sample }

Item = 'DM1182'
Currency = :USD

Rates = Nokogiri::XML(open(rates_file)).slop!.rates.rate.each_with_object({}) { |rate, rates|
  from, to = [:from, :to].map { |child| rate.send(child).text.to_sym }
  rates[from] ||= { from => Rational(1) }
  rates[from].merge! to => Rational(rate.conversion.text)
}

Currencies = Rates.inject([]) { |currencies, (from, to_conversion)| currencies | [from, *to_conversion.keys] }

Currencies.each { |currency|
  Rates[currency] ||= {}
  Currencies.each { |cur|
    Rates[currency][cur] = 1 / Rates[cur][currency] if Rates[cur][currency] and !Rates[currency][cur]
  }
}

def find_conversion(from, to)
  Rates[from][to] or find_it!(from, to)
end

def find_it! from, to
  until Rates[from][to]
    cur = Rates[from].keys.find(lambda { raise "Couldnt find from #{from} to #{to} with #{values} and #{Rates}" }) { |currency|
      !(Rates[currency].keys - Rates[from].keys).empty?
    }
    Rates[cur].each_pair { |inter, val|
      Rates[from][inter] = Rates[from][cur] * val
    }
  end
  Rates[from][to]
end

def round(r)
  fix, frac = (100*r).divmod(1)
  if frac == 0.5
    [fix, fix + 1].find(&:even?)
  elsif frac > 0.5
    fix + 1
  else
    fix
  end / 100.0
end

# Utica,DM1210,13.12 CAD

# p round CSV.fast(trans_file).inject(0) { |total, (_, item, price)|
#   next(total) unless item == Item
#   price, currency = price.split(' ')
#   total + round(Rational(price) * find_conversion(currency.to_sym, Currency))
# }

# 0.340 => 0.284
Cache = 'cache.rates.marshal'
if File.exist? Cache
  data = Marshal.load(File.binread(Cache))
else
  data = []
  open(Cache, 'wb') { |f|
    CSV.fast(trans_file).each { |_, item, price|
      next unless item == Item
      price, currency = price.split(' ')
      data << [Rational(price), currency.to_sym]
    }
    f.write Marshal.dump data
  }
end
p round data.inject(0) { |total, (price, currency)| total + round(price * find_conversion(currency, Currency)) }

