
##################################################
##################################################
# clean.locationdata
##################################################
##################################################

# Defines a function that takes as input a dataframe of tweets 
# in the format provided by filterstream (from the streamR package)
# and manipulates the lattitude and longitude data so that:
# 1) 
# When Twitter provides only a state as a place (and not a more 
# specific location), the lat/lon data are set to missing. (For my
# purposes, I'm interested in specific counties rather than whole states, 
# so the lat/lon of the state centroid is not meaningful to me).
# 2)
# If I have a valid lat/lon that comes from the exact location 
# of the tweet rather than the Twitter "place," the function will
# replace the "place" lat/lon with the more specific lat/lon.
# See https://dev.twitter.com/overview/api/places for what is a 
# Twitter "place." Basically, the function will favor the exact lat/lon
# over the "place" when the exact lat/lon is available.

clean.location.data = function(x) {
  is.na(x[["place_lat"]]) = grep(", USA", x[["full_name"]])
  is.na(x[["place_lon"]]) = grep(", USA", x[["full_name"]])
  x[["lat"]][is.na(x[["lat"]])] = x[["place_lat"]][is.na(x[["lat"]])]
  x[["lon"]][is.na(x[["lon"]])] = x[["place_lon"]][is.na(x[["lon"]])]
  return(x)
}





##################################################
##################################################
# get.coordinates
##################################################
##################################################

# prepares a dataframe of coordinates for 
# the function "latlong2county"

get.coordinates = function(x) {
  # create dataframe of coordinates from twitter data
  coords = subset(x, select=c("lon", "lat"))
  
  # Code missing values of coords to extreme value rather than na
  # otherwise latlong2county doesn't work -- it needs a numeric input
  coords[is.na(coords)] = 99999
  return(coords)
}






##################################################
##################################################
# latlong2county
##################################################
##################################################


# latlong2county
# dependencies: sp; maps; maptools
# Runs quickly but sometimes leaves locations unidentified
# Modified from http://stackoverflow.com/questions/8751497/latitude-longitude-coordinates-to-state-code-in-r/8751965#8751965
# The single argument to this function, pointsDF, is a data.frame in which:
#   - column 1 contains the longitude in degrees (negative in the US)
#   - column 2 contains the latitude in degrees

latlong2county <- function(pointsDF) {
  
  # Prepare SpatialPolygons object with one SpatialPolygon
  # per state (plus DC, minus HI & AK)
  counties <- map('county', fill=TRUE, col="transparent", plot=FALSE)
  IDs <- sapply(strsplit(counties$names, ":"), function(x) x[1])
  counties_sp <- map2SpatialPolygons(counties, IDs=IDs,
                                     proj4string=CRS("+proj=longlat +datum=WGS84"))
  # Convert pointsDF to a SpatialPoints object 
  pointsSP <- SpatialPoints(pointsDF, 
                            proj4string=CRS("+proj=longlat +datum=WGS84"))
  # Use 'over' to get _indices_ of the Polygons object containing each point 
  indices <- over(pointsSP, counties_sp)
  
  # Return the state names of the Polygons object containing each point
  countyNames <- sapply(counties_sp@polygons, function(x) x@ID)
  countyNames[indices]
}







##################################################
##################################################
# latlong2fips
##################################################
##################################################

# Dependencies: RJSONIO
# This defines a simple function to access the FCC's conversion API. 
# Can submit coordinates and the API will return a fips code.
# Simple and relibale but runs slowly
# From Github; https://gist.github.com/ramhiser/f09a71d96a4dec80994c
latlong2fips <- function(latitude, longitude) {
  url <- "http://data.fcc.gov/api/block/find?format=json&latitude=%f&longitude=%f"
  url <- sprintf(url, latitude, longitude)
  json <- RCurl::getURL(url)
  json <- RJSONIO::fromJSON(json)
  as.character(json$County['FIPS'])
}














