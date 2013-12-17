Near-Space-Arduino-Sensors
==========================

##About
Arduino code for logging environmental data on a "near space" high altitude balloon.  
  
I wrote this code for the [Anacapa Near Space Exploration Club (ANSEC)](http://www.anacapaschool.org/2011/05/23/anacapas-near-space-balloon-launch-is-a-success/) that I helped found in high school. The goal of the project was to send a high altitude balloon to 100,000+ feet with a payload of cameras, enviromental sensors, and GPS for recovery. This is the code for reading from the envirormental sensors (pressure, tempature, hummidity) and then for logging the data to an SD card for analysis post flight.

The sensors used were a BMP085 pressure sensor and a SHT15 temp/humidity sensor both bought from [sparkfun](http://www.sparkfun.com). An [Adafruit](http://www.adafruit.com) datalogger shield shield was used for interfacing with the SD card.
