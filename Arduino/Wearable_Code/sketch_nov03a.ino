#include <SoftwareSerial.h>
#include <DHT.h>

//DHT values
#define DHTPIN 7     // what pin we're connected to
#define DHTTYPE DHT22   // DHT 22  (AM2302)
DHT dht(DHTPIN, DHTTYPE); //// Initialize DHT sensor for normal 16mhz Arduino

//Bluetooth communication
SoftwareSerial mySerial(2, 3); // RX, TX
int PIN_EN_OUT = 4;
int PIN_STATE_IN = 5;


//Variables
float hum;  //Stores humidity value
float temp; //Stores temperature value
String convertedHumidity;
String convertedTemperature;
String convertedDustDensity;
String converted;

int measurePin = 5;
int ledPower = 12;

int samplingTime = 280;
int deltaTime = 40;
int sleepTime = 9680;

float voMeasured = 0;
float calcVoltage = 0;
float dustDensity = 0;


void setup() {
  mySerial.begin(9600);
  Serial.begin(9600);
  pinMode(ledPower,OUTPUT);
  dht.begin();

  sendCommand("AT");
  sendCommand("AT+ROLE0");
  sendCommand("AT+UUID0xFFE0");
  sendCommand("AT+CHAR0xFFE1");
  sendCommand("AT+NAMEbluino");
}

void sendCommand(const char * command) {
  Serial.print("Command send :");
  Serial.println(command);
  mySerial.println(command);
  //wait some time
  delay(100);

  char reply[100];
  int i = 0;
  while (mySerial.available()) {
    reply[i] = mySerial.read();
    i += 1;
  }
  //end the string
  reply[i] = '\0';
  Serial.print(reply);
  Serial.println("Reply end");
  delay(50);
}

char buf[100];
void loop() {
  hum = dht.readHumidity();
  temp = dht.readTemperature();

  //Calculating Dust density
  digitalWrite(ledPower,LOW); // power on the LED
  delayMicroseconds(samplingTime);
  voMeasured = analogRead(measurePin); // read the dust value
  
  delayMicroseconds(deltaTime);
  digitalWrite(ledPower,HIGH); // turn the LED off
  delayMicroseconds(sleepTime);

  // 0 - 5.0V mapped to 0 - 1023 integer values 
  calcVoltage = voMeasured * (5.0 / 1024); 
  
  // linear eqaution taken from http://www.howmuchsnow.com/arduino/airquality/
  dustDensity = (0.13 * calcVoltage - 0.1)*1000; 


  convertedHumidity = String(hum);
  convertedTemperature = String(temp);
  convertedDustDensity = String(dustDensity);
  converted = convertedHumidity +'_'+ convertedTemperature +'_' + convertedDustDensity;
  converted.toCharArray(buf, 100);
  Serial.print("Humidity:");
  Serial.println(convertedHumidity);
  Serial.print("Temperature:");
  Serial.println(convertedTemperature);
  Serial.print("Dust Density [ug/m3]: ");
  Serial.println(dustDensity);
  mySerial.write(buf);
  delay(10);
}
