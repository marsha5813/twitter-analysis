
##################################################
##################################################
# clean.location.data
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






##################################################
##################################################
# clean.tweets
##################################################
##################################################

clean.tweets = function(data, column) {
  
  
  # saves raw text for later comparison
  data[["rawtext"]] = data[[column]]
  # remove retweet entities
  data[[column]] = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", data[[column]])
  # remove retweet entities
  data[[column]] = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", data[[column]])
  # remove at people
  data[[column]] = gsub("@\\w+", "", data[[column]])
  # remove punctuation
  data[[column]] = gsub("[[:punct:]]", "", data[[column]])
  # remove numbers
  data[[column]] = gsub("[[:digit:]]", "", data[[column]])
  # remove html links
  data[[column]] = gsub("http\\w+", "", data[[column]])
  # remove unnecessary spaces
  data[[column]] = gsub("[ \t]{2,}", "", data[[column]])
  data[[column]] = gsub("^\\s+|\\s+$", "", data[[column]])
  # remove all non-ASCII characters (removes emojis)
  data[[column]] = iconv(data[[column]], "latin1", "ASCII", sub="")
  
  # define "tolower error handling" function
  try.error = function(x)
  {
    # create missing value
    y = NA
    # tryCatch error
    try_error = tryCatch(tolower(x), error=function(e) e)
    # if not an error
    if (!inherits(try_error, "error"))
      y = tolower(x)
    # result
    return(y)
  }
  # lower case using try.error with sapply
  data[[column]] = sapply(data[[column]], try.error)
  
  # remove NAs in data[[column]]
  data[[column]] = data[[column]][!is.na(data[[column]])]
  names(data[[column]]) = NULL
  
  return(data)
  
  
}
    
    

##################################################
##################################################
# map.tweets
##################################################
##################################################

map.tweets = function(data, lat, lon) {
  
  map.data <- map_data("state")
  points <- data.frame(x = as.numeric(data[[lon]]), y = as.numeric(data[[lat]]))
  points <- points[points$y > 25, ]
  ggplot(map.data) + geom_map(aes(map_id = region), map = map.data, fill = "white", 
                              color = "grey20", size = 0.25) + expand_limits(x = map.data$place_lon, y = map.data$place_lat) + 
    theme(axis.line = element_blank(), axis.text = element_blank(), axis.ticks = element_blank(), 
          axis.title = element_blank(), panel.background = element_blank(), panel.border = element_blank(), 
          panel.grid.major = element_blank(), plot.background = element_blank(), 
          plot.margin = unit(0 * c(-1.5, -1.5, -1.5, -1.5), "lines")) + geom_point(data = points, 
                                                                                   aes(x = x, y = y), size = 1, alpha = 1/5, color = "darkblue")
  
  
}





