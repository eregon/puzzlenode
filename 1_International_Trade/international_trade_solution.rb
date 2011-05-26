require 'csv'
require 'nokogiri'

trans_file, rates_file = 'TRANS.csv', 'RATES.xml'

ITEM = 'DM1182'
CURRENCY = :USD

RATES = Nokogiri::XML(open(rates_file)).slop!.rates.rate.each_with_object({}) { |rate, rates|
  from, to = [:from, :to].map { |child| rate.send(child).text.to_sym }
  rates[from] ||= { from => Rational(1) }
  rates[from].merge! to => Rational(rate.conversion.text)
}

CURRENCIES = RATES.inject([]) { |currencies, (from, to_conversion)|
  currencies | [from, *to_conversion.keys]
}

CURRENCIES.each { |currency|
  RATES[currency] ||= {}
  CURRENCIES.each { |cur|
    RATES[currency][cur] = 1 / RATES[cur][currency] if RATES[cur][currency] and !RATES[currency][cur]
  }
}

def find_conversion(from, to)
  RATES[from][to] or find_it!(from, to)
end

def find_it! from, to
  until RATES[from][to]
    cur = RATES[from].keys.find(lambda {
      raise "Couldnt find from #{from} to #{to} with #{values} and #{RATES}"
    }) { |currency|
      !(RATES[currency].keys - RATES[from].keys).empty?
    }
    RATES[cur].each_pair { |inter, val|
      RATES[from][inter] = RATES[from][cur] * val
    }
  end
  RATES[from][to]
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
  next unless item == ITEM
  price, currency = price.split(' ')
  data << [Rational(price), currency.to_sym]
}

p round data.inject(0) { |total, (price, currency)| total + round(price * find_conversion(currency, CURRENCY)) }

