require 'sqlite3'
require 'sequel'
require 'net/http'
require 'json'

GREEN_DB = "green.db"
EB_HEADSIGNS = ["Lechmere", "North Station", "Government Center", "Park Street"]
ROUTE_HEADSIGNS = { "Green-B" => "Boston College",
                    "Green-C" => "Cleveland Circle",
                    "Green-D" => "Riverside",
                    "Green-E" => "Heath Street" }
STATION_NAMES = { "place-spmnl" => "Science Park",
                  "place-north" => "North Station",
                  "place-haecl" => "Haymarket",
                  "place-gover" => "Government Center",
                  "place-pktrm" => "Park Street",
                  "place-boyls" => "Boylston" }

class Vehicle
   def initialize(route, id, headsign, lat, lon)
      @route=route
      @id=id
      @headsign=headsign
      @lat=lat
      @lon=lon
   end

   def route
     @route
   end

   def id
     @id
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
   def initialize(vehicle, stops)
     @vehicle=vehicle
     @stops=stops
   end

   def vehicle
     @vehicle
   end

   def stops
     @stops
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
          vehicleId = trip["vehicle"]["vehicle_id"]
          headsign = trip["trip_headsign"]
          lat = trip["vehicle"]["vehicle_lat"]
          lon = trip["vehicle"]["vehicle_lon"]
          vehicles << Vehicle.new(routeId, vehicleId, headsign, lat, lon)
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
        stopsAway << StopsAway.new(vehicle, row[:stops_away])
      end
    end
  end

  stopsAway
end

def comparator(x, y)
  if x.vehicle.route == y.vehicle.route
    return x.stops.to_i <=> y.stops.to_i
  else
    return x.vehicle.route <=> y.vehicle.route
  end
end

@green_db = Sequel.connect('sqlite://' + GREEN_DB)
@vehicles = getVehicles

STATION_NAMES.each do |stationId, stationName|
  print stationName
  print "\n==============\n"
  stops = stopsAwayForStation(stationId)
  stops.sort! { |x, y| comparator(x, y) }
  stops.each do |stop|
    print ROUTE_HEADSIGNS[stop.vehicle.route] + ", " + stop.stops + " (" + stop.vehicle.id + ")\n"
  end
  print "\n"
end
