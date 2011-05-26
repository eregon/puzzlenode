require 'csv'
require 'nokogiri'

module InternationTrade
  extend self

  def sum(item, in_currency, transactions_csv, rates_xml)
    rates = parse_rates(rates_xml)

    currencies = rates.inject([]) { |currencies, (from, to_conversion)|
      currencies | [from, *to_conversion.keys]
    }

    transactions = parse_transactions(transactions_csv, item)

    round transactions.inject(0) { |total, (price, currency)|
      total + round(price * find_conversion(rates, currency, in_currency))
    }
  end

  private
  def parse_rates(xml)
    Nokogiri::XML(open(xml)).slop!.rates.rate.each_with_object({}) { |rate, rates|
      from, to = [:from, :to].map { |child| rate.send(child).text.to_sym }
      rates[from] ||= { from => Rational(1) }
      rates[from].merge! to => Rational(rate.conversion.text)
    }
  end

  def parse_transactions(csv, item_searched)
    transactions = []
    CSV.foreach(csv) { |_, item, price|
      next unless item == item_searched
      price, currency = price.split(' ')
      transactions << [Rational(price), currency.to_sym]
    }
    transactions
  end

  def find_rates_from_reverse(rates, currencies)
    currencies.each { |currency|
      rates[currency] ||= {}
      currencies.each { |cur|
        rates[currency][cur] = 1 / rates[cur][currency] if rates[cur][currency] and !rates[currency][cur]
      }
    }
  end

  def find_conversion rates, from, to
    until rates[from][to]
      cur = rates[from].keys.find(lambda {
        raise "Couldnt find from #{from} to #{to} with #{values} and #{rates}"
      }) { |currency|
        !(rates[currency].keys - rates[from].keys).empty?
      }
      rates[cur].each_pair { |inter, val|
        rates[from][inter] = rates[from][cur] * val
      }
    end
    rates[from][to]
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
end

p InternationTrade.sum('DM1182', :USD, 'TRANS.csv', 'RATES.xml')

