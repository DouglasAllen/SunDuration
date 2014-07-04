require 'date'
require 'getoptlong'

storage = ARGV.clone

opts = GetoptLong.new(
  ['--help', '-h', GetoptLong::NO_ARGUMENT],
  ['--year', '-y', GetoptLong::OPTIONAL_ARGUMENT]
)

year = 0

opts.each do |opt, arg|
  case opt
    when '--help'
      puts "ruby sun.rb [--year [year]]"
      exit
    when '--year'
      if arg == ''
        year = Time.now.year
      else
        year = arg
      end
  end
end

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
  Math.atan2(x, Math.sqrt(1.0-x*x))
end

def arccos(x)
  Math.atan2(Math.sqrt(1.0-x*x),x)
end

class Date
  def to_time()
    Time.local(year, mon, mday)
  end

  def days_in_year()
    if leap?
      return 366
    end
    return 365
  end
end

#
# Implementation follows the guidelines from
# http://lexikon.astronomie.info/zeitgleichung
#
class SunDeclination
  attr_reader :sunrise
  attr_reader :sunset

  def initialize(loc, date = Date.today)
    @loc = loc
    @daynumber= date.yday
    @gmt_offset = (date.to_time.gmt_offset/60)/60
    @declination = 0.4095*Math.sin(0.016906*(@daynumber-80.086))
    @b = Math::PI * @loc.north / 180
    @timediff = 12*arccos((Math.sin(-0.0145)-Math.sin(@b)*Math.sin(@declination))/(Math.cos(@b)*Math.cos(@declination)))/Math::PI
    @timeeq = -0.171*Math.sin(0.0337*@daynumber+0.465)-0.1299*Math.sin(0.01787*@daynumber-0.168)
    @woz_up = 12 - @timediff - @timeeq
    @woz_down = 12 + @timediff - @timeeq
    @sunrise = @woz_up + (-1*@loc.east)/15 + @gmt_offset
    @sunset =  @woz_down + (-1*@loc.east)/15 + @gmt_offset
  end

  def sunrise_to_s()
    hour = @sunrise.to_i
    min = (((@sunrise-hour)*1000).to_i*60/100)/10
    return sprintf("%02i:%02i",hour,min)
  end

  def sunset_to_s()
    hour = @sunset.to_i
    min = (((@sunset-hour)*1000).to_i*60/100)/10
    return sprintf("%02i:%02i",hour,min)
  end

end

#loc = Location.new("bul","Burglengenfeld", 49.207505, 12.042675)
#loc = Location.new("stav","Stavanger", 58.972313, 5.732746)
loc = Location.new("wak","Wackersdorf", 49.314604, 12.179174)



if year == 0 then
  syesterday = SunDeclination.new(loc, Date.today-1)
  stoday     = SunDeclination.new(loc)
  stomorrow  = SunDeclination.new(loc, Date.today+1)

  puts  "          Yesterday    Today    Tomorrow"
  print "Sunrise:  "
  print syesterday.sunrise_to_s
  print "        "
  print stoday.sunrise_to_s
  print "    "
  puts  stomorrow.sunrise_to_s

  print "Sunset:   "
  print syesterday.sunset_to_s
  print "        "
  print stoday.sunset_to_s
  print "    "
  puts stomorrow.sunset_to_s
else
  date = Date.new(year.to_i,1,1);

  for i in 1..date.days_in_year
    s = SunDeclination.new(loc,date)
    print date
    print " "
    print s.sunrise_to_s
    print " "
    print s.sunset_to_s
    puts ""
    date = date+1
  end
end
