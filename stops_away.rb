require 'sqlite3'
require 'sequel'
require 'net/http'
require 'json'

GREEN_DB = "green.db"
EB_HEADSIGNS = ["Lechmere", "North Station", "Government Center", "Park Street"]

class Vehicle
   def initialize(route, headsign, lat, lon)
      @route=route
      @headsign=headsign
      @lat=lat
      @lon=lon
   end

   def route
     @route
   end

   def headsign
     @headsign
   end

   def lat
     @lat
   end

   def lon
     @lon
   end
end

class StopsAway
   def initialize(stops, route, headsign)
     @stops=stops
     @route=route
     @headsign=headsign
   end

   def stops
     @stops
   end

   def route
     @route
   end

   def headsign
     @headsign
   end
end

def getVehicles
  vehicles = []

  url = "http://realtime.mbta.com/developer/api/v2/vehiclesbyroutes?api_key=wX9NwuHnZU2ToO7GmGR9uw&routes=Green-B,Green-C,Green-D,Green-E&format=json"
  uri = URI(url)
  response = Net::HTTP.get(uri)
  parsed = JSON.parse(response)

  parsed["mode"].each do |mode|
    mode["route"].each do |route|
      routeId = route["route_id"]
      route["direction"].each do |direction|
        direction["trip"].each do |trip|
          headsign = trip["trip_headsign"]
          lat = trip["vehicle"]["vehicle_lat"]
          lon = trip["vehicle"]["vehicle_lon"]
          vehicles << Vehicle.new(routeId, headsign, lat, lon)
        end
      end
    end
  end

  vehicles
end

def vehicleSegment(vehicle)
  segment = nil

  @green_db['SELECT segment_id from segments WHERE segment_lat = ? and segment_lon = ?', vehicle.lat, vehicle.lon].each do |row|
    segment = row[:segment_id]
  end

  segment
end

def stopsAwayForStation(stationId)
  stopsAway = []

  @vehicles.each do |vehicle|
    segmentId = vehicleSegment(vehicle)
    if segmentId
      headsign = (EB_HEADSIGNS.include?(vehicle.headsign)) ? vehicle.headsign : "Westbound"
      @green_db['SELECT stops_away, headsign from stops_away WHERE segment_id = ? and station_id = ? and headsign = ?', segmentId, stationId, headsign].each do |row|
        stopsAway << StopsAway.new(row[:stops_away], vehicle.route, headsign)
      end
    end
  end

  stopsAway
end

@green_db = Sequel.connect('sqlite://' + GREEN_DB)
@vehicles = getVehicles

stationId = (ARGV[0] == nil) ? 'place-pktrm' : ARGV[0]
print "Stops away for " + stationId + "\n\n"

stops = stopsAwayForStation(stationId)
stops.each do |stop|
  print stop.route + ", " + stop.headsign + ", " + stop.stops + "\n"
end
