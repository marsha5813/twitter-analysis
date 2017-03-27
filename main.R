
# install packages
install.packages("streamR")
devtools::install_github("bnosac/taskscheduleR")
install.packages("sp")
install.packages("maps")
install.packages("maptools")
install.packages("RJSONIO")
install.packages("jsonlite", repos="http://cran.r-project.org")


# load libraries
library(taskscheduleR)
library(streamR)
library(sp)
library(maps)
library(maptools)
library(RJSONIO)
library(jsonlite)

# load my functions
source("functions.R")

# load oauth file
load("my_oauth.Rdata") 

# run data collection for all of the United States
source("data-collect-usa.R")

 # parse tweets into a data.frame
tweets.df = parseTweets("tweets.json", verbose=TRUE)

# subset the data to generate some test data
test.data = tweets.df[1:100, ]
View(test.data)

# Clean location data for tweets
test.data = clean.location.data(test.data)

# Drop observations with no valid location data
test.data <- test.data[complete.cases(test.data$lat), ]

# Get fips codes from tweets 
# Fast but sometimes leaves locations unidentified
coords = get.coordinates(test.data)
coords$name=latlong2county(coords)
coords[coords==99999] = NA
coords$fips = with(county.fips, fips[match(coords$name, polyname)])
test.data$assigned_name = coords$name
test.data$fips = coords$fips
rm(coords)

# Alternate method of getting fips codes by making a call to the
# FCC's block conversion API. Reliable but slow.
test.data$fips2 = by(test.data, 1:nrow(test.data), function(x) latlong2fips(x$lat,x$lon))

# Do sentiment analysis

# Average the scores by fips code

# Make a dataset with counties as cases

# Save county dataset as .csv








