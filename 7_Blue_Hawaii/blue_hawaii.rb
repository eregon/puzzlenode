require 'json'
require 'time'

module BlueHawai
  extend self

  ACCOMMODATION_SALES_TAX = 1.0411416

  class Season
    class << self
      attr_accessor :year
    end

    attr_reader :start, :end, :rate
    def initialize start_date, end_date, rate
      @start, @end = parse_date(start_date), parse_date(end_date)
      @rate = BlueHawai.parse_rate(rate)
    end

    def to_s
      "#{@start} - #{@end} (#{@rate})"
    end

    private
    def parse_date str
      Date.new(Season.year, *str.split('-').map(&:to_i))
    end
  end

  class RentalUnit
    attr_reader :name, :cleaning_fee
    def initialize json
      @name = json['name']
      @seasons = if json['rate']
        [Season.new('01-01', '12-31', json['rate'])]
      else
        json['seasons'].map { |season|
          Season.new(*season.values.first.values_at('start', 'end', 'rate'))
        }
      end
      @cleaning_fee = BlueHawai.parse_rate(json['cleaning fee'] || '0')
    end

    def cost_at date
      @seasons.find(->{
        raise "Could not find a season including #{date} in #{@seasons}"
      }) { |season|
        (season.start <= date and date <= season.end) or
        (season.end < season.start and (date >= season.start or date <= season.end))
      }.rate
    end
  end

  def go_to_holidays(vacation_rantals, period)
    json = JSON.load(File.read(vacation_rantals))
    period = parse_period period
    Season.year = period.begin.year

    rental_units = json.map { |data| BlueHawai::RentalUnit.new data }

    costs = period.each_with_object(Hash.new(0)) { |day, costs|
      rental_units.each { |rental_unit|
        costs[rental_unit] += rental_unit.cost_at(day)
      }
    }

    costs.each_pair { |rental_unit, cost|
      costs[rental_unit] = (cost + rental_unit.cleaning_fee) * ACCOMMODATION_SALES_TAX
    }

    costs.each_pair { |rental_unit, cost|
      puts "#{rental_unit.name}: $#{'%.2f' % cost}"
    }
  end

  def parse_rate rate
    rate.delete('$').to_i
  end

  private  
  def parse_period file
    start, _end = File.read(file).split(' - ').map { |date|
      Date.new(*date.split('/').map(&:to_i))
    }
    (start..._end)
  end
end

#BlueHawai.go_to_holidays('sample_vacation_rentals.json', 'sample_input.txt')
BlueHawai.go_to_holidays('vacation_rentals.json', 'input.txt')


