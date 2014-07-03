require 'date'

class Location
  attr_reader :name
  attr_reader :north
  attr_reader :east

  def initialize(name, north, east)
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

class Float
  def round_to(i)
    f = (10 ** i).to_f
    nr = self * f
    return nr.round / f
  end
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

bul = Location.new("Burglengenfeld", 49.197298, 12.045822)

s = SunDeclination.new(bul)
print "Sunrise: "
puts s.sunrise_to_s
print "Sunset:  "
puts s.sunset_to_s



#date = Date.new(2011,1,1);

#for i in 1..date.days_in_year
  #s = SunDeclination.new(bul,date)
  #print date
  #print " "
  #print s.sunrise_to_s
  #print " "
  #print s.sunset_to_s
  #puts ""
  #date = date+1
#end
