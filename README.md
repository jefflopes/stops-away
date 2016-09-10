# stops-away

run "ruby stops_away.rb <station_id>" to show upcoming vehicles and how many stops away they are

station_id should be one of: place-boyls, place-pktrm, place-gover, place-haecl, place-north, place-spmnl

create_db.rb takes the data from the spreadsheet below (in CSV form) and turns it into a SQLite DB. Westbound stations that were in common between all the sheets are separated into their own CSV, so there's one more CSV than there are sheets in the spreadsheet. 

Original spreadsheet from MBTA: https://www.dropbox.com/s/a5xtacqw44ijyaw/Stops_Away_for_developers.xlsx?dl=0
