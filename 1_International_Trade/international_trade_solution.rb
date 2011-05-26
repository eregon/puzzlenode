require 'csv'
require 'nokogiri'

trans_file, rates_file = 'TRANS.csv', 'RATES.xml'

Item = 'DM1182'
Currency = :USD

Rates = Nokogiri::XML(open(rates_file)).slop!.rates.rate.each_with_object({}) { |rate, rates|
  from, to = [:from, :to].map { |child| rate.send(child).text.to_sym }
  rates[from] ||= { from => Rational(1) }
  rates[from].merge! to => Rational(rate.conversion.text)
}

Currencies = Rates.inject([]) { |currencies, (from, to_conversion)|
  currencies | [from, *to_conversion.keys]
}

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
    cur = Rates[from].keys.find(lambda {
      raise "Couldnt find from #{from} to #{to} with #{values} and #{Rates}"
    }) { |currency|
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

data = []
CSV.foreach(trans_file) { |_, item, price|
  next unless item == Item
  price, currency = price.split(' ')
  data << [Rational(price), currency.to_sym]
}

p round data.inject(0) { |total, (price, currency)| total + round(price * find_conversion(currency, Currency)) }

