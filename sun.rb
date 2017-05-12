
require 'date'
require 'getoptlong'

# storage = ARGV.clone

opts = GetoptLong.new(
  ['--help', '-h', GetoptLong::NO_ARGUMENT],
  ['--year', '-y', GetoptLong::OPTIONAL_ARGUMENT]
)

year = 0

opts.each do |opt, arg|
  case opt
  when '--help'
    puts 'ruby sun.rb [--year [year]]'
    exit
  when '--year'
    year = if arg == ''
             Time.now.year
           else
             arg
           end
  end
end

#
class Location
  attr_reader :shortname
  attr_reader :name
  attr_reader :north
  attr_reader :east

  def initialize(shortname, name, north, east)
    @shortname = shortname
    @name = name
    @north = north
    @east = east
  end
end

def arcsin(x)
  Math.atan2(x, Math.sqrt(1.0 - x * x))
end

def arccos(x)
  Math.atan2(Math.sqrt(1.0 - x * x), x)
end

#
class Date
  def to_time
    Time.local(year, mon, mday)
  end

  def days_in_year
    leap? ? 366 : 365
  end
end

#
# Implementation follows the guidelines from
# http://lexikon.astronomie.info/zeitgleichung
#
class SunDeclination
  attr_accessor :loc, :date, :daynumber

  def initialize(loc, date = Date.today)
    @loc = loc
    @date = date
    @daynumber = date.yday
  end

  def gmt_offset
    (@date.to_time.gmt_offset / 60.0) / 60.0
  end

  def timeeq
    -0.171 * Math.sin(
      0.0337 * @daynumber + 0.465) - 0.1299 * Math.sin(
        0.01787 * @daynumber - 0.168)
  end

  def declination
    0.4095 * Math.sin(0.016906 * (@daynumber - 80.086))
  end

  def timediff
    12 * arccos((Math.sin(-0.0145) - Math.sin(@b) * Math.sin(@declination)) /
      (Math.cos(@b) * Math.cos(@declination))) / Math::PI
  end

  def sunrise
    @woz_up = 12 - @timeeq - @timediff
    @sunrise = @woz_up + (-1 * @loc.east) / 15 + @gmt_offset
  end

  def sunset
    @woz_down = 12 - @timeeq + @timediff
    @sunset = @woz_down + (-1 * @loc.east) / 15 + @gmt_offset
  end

  def calculate
    @gmt_offset = gmt_offset
    @timeeq = timeeq
    @b = Math::PI / 180 * @loc.north
    @declination = declination
    @timediff = timediff
    sunrise
    sunset
  end

  def sunrise_to_s
    calculate
    hour = @sunrise.to_i
    min = (((@sunrise - hour) * 1000).to_i * 60 / 100) / 10
    print format('%02i:%02i', hour, min)
  end

  def sunset_to_s
    hour = @sunset.to_i
    min = (((@sunset - hour) * 1000).to_i * 60 / 100) / 10
    print format('%02i:%02i', hour, min)
  end
end

# loc = Location.new('bul', 'Burglengenfeld', 49.207505, 12.042675)
loc = Location.new('stav', 'Stavanger', 58.972313, 5.732746)
# loc = Location.new('wak', 'Wackersdorf', 49.314604, 12.179174)

if year == 0
  syesterday = SunDeclination.new(loc, Date.today - 1)
  stoday     = SunDeclination.new(loc)
  stomorrow  = SunDeclination.new(loc, Date.today + 1)
  puts
  puts  '          Yesterday'
  print 'Sunrise:  '
  print syesterday.sunrise_to_s
  print '        '
  print 'Sunset:   '
  print syesterday.sunset_to_s
  print "\n\n"
  puts  '          Today'
  print 'Sunrise:  '
  print stoday.sunrise_to_s
  print '        '
  print 'Sunset:   '
  print stoday.sunset_to_s
  print "\n\n"
  puts  '          Tomorrow'
  print 'Sunrise:  '
  print  stomorrow.sunrise_to_s
  print '        '
  print 'Sunset:   '
  print stomorrow.sunset_to_s
  print "\n\n"
else
  date = Date.new(year.to_i, 1, 1)

  (1..date.days_in_year).each do
    s = SunDeclination.new(loc, date)
    print date
    print ' '
    print s.sunrise_to_s
    print ' '
    print s.sunset_to_s
    puts ''
    date += 1
  end
end

p stoday.loc
p stoday.date
p stoday.daynumber
p stoday.gmt_offset
p stoday.timeeq * 60
p stoday.declination * 180 / Math::PI
p stoday.timediff
