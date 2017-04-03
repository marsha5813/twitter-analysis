
# install packages
install.packages("streamR")
install.packages("sp")
install.packages("maps")
install.packages("maptools")
install.packages("RJSONIO")
install.packages("jsonlite", repos="http://cran.r-project.org")
install.packages("sp")
install.packages("maptools")
install.packages("maps")
install.packages("ggplot2")
devtools::install_github("bnosac/taskscheduleR")
devtools::install_github("timjurka/sentiment")


# load libraries
library(streamR)
library(sp)
library(maps)
library(maptools)
library(RJSONIO)
library(jsonlite)
library(sp)
library(maptools)
library(maps)
library(ggplot2)
library(taskscheduleR)
library(sentiment)



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

# Pre-process the tweets
test.data = clean.tweets(test.data, "text")

# Do sentiment analysis using Tim Jurka's "sentiment" package
emotions = as.data.frame(classify_emotion(test.data$text, algorithm = "bayes"))
polarity = as.data.frame(classify_polarity(test.data$text, algorithm = "bayes"))

# Do sentiment analysis by training a text classifier 

# Do some data viz
map.tweets(tweets.df, "place_lat", "place_lon") ## maps tweets across the U.S. (still throws some errors)

# Average the scores by fips code

# Make a dataset with counties as cases

# Save county dataset as .csv








