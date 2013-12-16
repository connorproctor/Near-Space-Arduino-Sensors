/*
Written by Connor Proctor

BMP085 Pressure Sensore Pin Map:
SDA -> A4
SCL -> A5
VCC -> 3v3
Gnd -> Gnd

SHT15 temp/humidity Pin Map:
Data -> 6
SCK -> 5
VCC -> 5v
Gnd -> Gnd 
*/


#include <Wire.h>
#include "SdFat.h"
#include "RTClib.h"
#include <SHT1x.h>
#include <BMP085.h>


#define LOG_INTERVAL 1000 //mills between sensor readings
#define ECHO_TO_SERIAL 1 //echo data to serial port
#define WAIT_TO_START 0 //Wait for serial input in setup()
#define SYNC_INTERVAL 1000 //mills between calls to sync()
int syncTime = 0;

//digital pins that connect to SHT1x; creates sht1x object
#define SHTDataPin 6
#define SHTClockPin 5
SHT1x sht1x(SHTDataPin, SHTClockPin);

//the digital pins that connect to the LEDs
#define redLEDpin 3
#define greenLEDpin 4

//define the RTC object
RTC_DS1307 RTC;

//define the BMP085 object
BMP085 dps = BMP085();
//define the BMP085 vars
long BMPTemp = 0, Pressure = 0, Altitude = 0;

// The objects to talk to the SD card
Sd2Card card;
SdVolume volume;
SdFile root;
SdFile file; 

//----------------------------------------------------------

void error(char *str)
{
  Serial.print("error: ");
  Serial.println(str);
  while(1);
}


//----------------------------------------------------------


void setup(void)
{
  Serial.begin(9600);
  Serial.println();
  
  #if WAIT_TO_START
    Serial.println("Type any char to begin");
    while (!Serial.available());
  #endif //WAIT TO START
  
  //initialize the SDcard
  if (!card.init()) error("card.init");
  
  //initialize a FAT volume
  if (!volume.init(card)) error("volume.init");
  
  // open root directory
  if (!root.openRoot(volume)) error("openRoot");
  
  //create a new file
  char name[] = "LOGGER00.CSV";
  for (uint8_t i = 0; i < 100; i++) {
    name [6] = i/10 + '0';
    name [7] = i%10 + '0';
    if (file.open(root, name, O_CREAT | O_EXCL | O_WRITE)) break;
  }
  if (!file.isOpen()) error("file.create");
  Serial.print("Logging to:  ");
  Serial.println(name);
  
  //write header
  file.writeError = 0;
  
  Wire.begin();
  if (!RTC.begin()) {
    file.println("RTC failed");
    #if ECHO_TO_SERIAL
    Serial.println("RTC failed");
    #endif //Echo to serial
  }
  
  file.println("millis,unix,date,time,tempC,tempF,humidity,Pressure,BMPTemp");
  #if ECHO_TO_SERIAL
    Serial.println("millis,unix,date,time,tempC,tempF,humidity,Pressure,BMPTemp");
  #endif
  //attempt to write out the header to the file
  if (file.writeError || !file.sync()) {
   error("write header");
  }
  
  //initilize the BMP085 pressure sensor
  dps.init();
  
  pinMode(redLEDpin, OUTPUT);
  pinMode(greenLEDpin, OUTPUT);
  
}


//-----------------------------------------------------------

void loop() 
{
  
  //clear print error
  file.writeError = 0;
  
  //delay for the amount of time we want between readings
  delay((LOG_INTERVAL -1) - (millis() % LOG_INTERVAL));
  
  digitalWrite(redLEDpin, HIGH); //shows we are reading data
  
  time(); //reads and prints time
  temp_humidity(); //reads and prints temp and humidity
  pressure(); //reads and prints pressure and temp
  
  if (file.writeError) error("write data");
  
  digitalWrite(redLEDpin, LOW);
  
  if ((millis() - syncTime) < SYNC_INTERVAL) return;
  syncTime = millis();
  
  digitalWrite(greenLEDpin, HIGH);
  if (!file.sync()) error("sync");
  digitalWrite(greenLEDpin, LOW);
  
  delay(4000);
  
}


//----------------------------------------------------------


// Reads RTC and prints
void time()
{
  DateTime now;
  
  //log milliseconds since starting
  uint32_t m = millis();
  file.print(m);
  file.print(", ");
  #if ECHO_TO_SERIAL
  Serial.print(m);         // milliseconds since start
  Serial.print(", ");  
  #endif
  
  //fetch the time
  now = RTC.now();
  //log time
  file.print(now.unixtime()); //seconds since 1970
  file.print(", ");
  file.print(now.year(), DEC);
  file.print("/");
  file.print(now.month(), DEC);
  file.print("/");
  file.print(now.day(), DEC);
  file.print(", ");
  file.print(now.hour(), DEC);
  file.print(":");
  file.print(now.minute(), DEC);
  file.print(":");
  file.print(now.second(), DEC);
  #if ECHO_TO_SERIAL
  Serial.print(now.unixtime()); // seconds since 1970
  Serial.print(", ");
  Serial.print(now.year(), DEC);
  Serial.print("/");
  Serial.print(now.month(), DEC);
  Serial.print("/");
  Serial.print(now.day(), DEC);
  Serial.print(", ");
  Serial.print(now.hour(), DEC);
  Serial.print(":");
  Serial.print(now.minute(), DEC);
  Serial.print(":");
  Serial.print(now.second(), DEC);
  #endif //ECHO_TO_SERIAL 
}


//-------------------------------------------------


//Reads SHT (temp/humidity) data and prints
void temp_humidity()
{
  //define the sht1 sensor data
  float temp_c = 0;
  float temp_f = 0;
  float humidity = 0;
  
  //read temp and humidity
  temp_c = sht1x.readTemperatureC();
  temp_f = sht1x.readTemperatureF();
  humidity = sht1x.readHumidity();
   
  //Send sensor data to file
  file.print(", ");
  file.print(temp_c);
  file.print(", ");
  file.print(temp_f);
  file.print(", ");
  file.print(humidity);
  #if ECHO_TO_SERIAL
  Serial.print(", ");
  Serial.print(temp_c);
  Serial.print(", ");
  Serial.print(temp_f);
  Serial.print(", ");
  Serial.print(humidity);
  #endif 
}

//---------------------------------------------

void pressure()
{
  dps.getPressure(&Pressure);
  dps.getTemperature(&BMPTemp);
  
  file.print(", ");
  file.print(Pressure);
  file.print(", ");
  file.println(BMPTemp);
  #if ECHO_TO_SERIAL
  Serial.print(", ");
  Serial.print(Pressure);
  Serial.print(", ");
  Serial.println(BMPTemp);
  #endif
  
}
