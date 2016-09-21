require 'sqlite3'
require 'sequel'
require 'csv'

GREEN_DB = "green.db"

DATA_DIR = "data"
SEGMENTS_FILE = "segments.csv"
NO_HEADSIGN_FILE = "none.csv"
HEADSIGN_FILES = { "Westbound" => "west.csv",
                   "Lechmere" => "lech.csv",
                   "North Station" => "north.csv",
                   "Government Center" => "govt.csv",
                   "Park Street" => "park.csv" }

STATION_IDS = ["place-boyls", "place-pktrm", "place-gover", "place-haecl", "place-north", "place-spmnl"]

def createTables(db)
  # segments
  db.create_table :segments do
    String :segment_id # Park_Loop
    String :segment_lat # 42.356205
    String :segment_lon # -71.062571
    index [:segment_lat, :segment_lon]
  end

  # stops_away
  db.create_table :stops_away do
    String :segment_id # Park_Loop
    String :station_id # place-boyls
    String :headsign # Government Center
    String :stops_away # 2
    index [:segment_id, :station_id, :headsign]
  end
end

def createSegments
  segments = @green_db[:segments]

  CSV.foreach(File.join(DATA_DIR, SEGMENTS_FILE)) do |row|
    segments.insert(:segment_id => row[2],
                    :segment_lat => row[0],
                    :segment_lon => row[1])
  end
end

def createHeadsigns
  stopsAway = @green_db[:stops_away]

  HEADSIGN_FILES.each do |headsign, file|
    CSV.foreach(File.join(DATA_DIR, file)) do |row|
      (1..6).each do |i|
        if row[i] != "REMOVE"
          stopsAway.insert(:segment_id => row[0],
                           :station_id => STATION_IDS[i - 1],
                           :headsign => headsign,
                           :stops_away => row[i])
        end
      end
    end
  end
end

File.delete(GREEN_DB) if File.exist?(GREEN_DB)
SQLite3::Database.new(GREEN_DB).close
@green_db = Sequel.connect('sqlite://' + GREEN_DB)

createTables(@green_db)
createSegments
createHeadsigns
