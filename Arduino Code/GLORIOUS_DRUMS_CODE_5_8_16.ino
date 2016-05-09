////////////////////////////////////////////////////////////
// BeeBop                                                 //
// MMDA, Spring 2016, Group 2                             //
// Contains code for the arduino side of BeeBop           //
////////////////////////////////////////////////////////////

#include <String.h>
#include <FreeSixIMU.h>
//#include <FIMU_ADXL345.h>
//#include <FIMU_ITG3200.h>

//includes and defines for the adafruit bluetooth
#include <SPI.h>
#include "Adafruit_BLE_UART.h"
#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 2     // This should be an interrupt pin, on Uno thats #2 or #3
#define ADAFRUITBLE_RST 9
 
#define enable 4                  //enable color controller demux
#define selectColorA 5            //color controller demux select line
#define selectColorB 6            //color controller demux select line
#define selectColorC 7            //color controller demux select line
#define cycleA 0                  //LED cycle select line
#define cycleB 1                  //LED cycle select line
#define cycleC 8                  //LED cycle select line
#define switch_R A3               //red drum switch
#define switch_O A2               //orange drum switch
#define switch_B A1               //blue drum switch
#define switch_Y A0               //yellow drum switch
#define interruptPin 3            //pin for the interrupts (comes from OR gate)
#define d 1000                    //microsecond delay between 8 LEDs during demux cycle
#define DEBOUNCE_TIME   5000      //debounce time if not the last drum hit
#define DEBOUNCE_TIME_2 200000    //debounce time if last drum hit
#define accelDataSize 10          //number of acceleration data points to store

//globals for bluetooth
aci_evt_opcode_t laststatus = ACI_EVT_DISCONNECTED;
aci_evt_opcode_t status;

enum drum {                       //enum for the drum colors
  red = 0,
  orange,
  blue,
  yellow
};
bool drumsHit[4];                 //array to keep track of which drum is being cued
byte lastHit = 5;                 //int to keep track of last drum hit
String messageForBT = "";         //message to send over bluetooth
unsigned long cueTime;            //stores time between cue and response
int accelData[accelDataSize];     //circular array to store acceleration data
byte accelIterator = 0;           //iterator for circular accelData array
//float values[4];                  //acceleration readings
bool endOfSong = false;

// Connect CLK/MISO/MOSI to hardware SPI
Adafruit_BLE_UART BTLEserial = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);

// Set the FreeSixIMU object
FreeSixIMU sixDOF = FreeSixIMU();

void setup() {                
  // initialize the pins
  pinMode(switch_O, INPUT);
  pinMode(switch_B, INPUT);
  pinMode(switch_Y, INPUT);
  pinMode(switch_R, INPUT);
  pinMode(selectColorC, OUTPUT);
  pinMode(selectColorB, OUTPUT);
  pinMode(selectColorA, OUTPUT);
  pinMode(cycleC, OUTPUT);
  pinMode(cycleB, OUTPUT);
  pinMode(cycleA, OUTPUT);
  pinMode(enable, OUTPUT);
  digitalWrite(cycleC, LOW);
  digitalWrite(cycleB, LOW);
  digitalWrite(cycleA, LOW);

  //initialize drumsHit array to all false
  drumsHit[red] = false;
  drumsHit[orange] = false;
  drumsHit[blue] = false;
  drumsHit[yellow] = false;

//  Serial.begin(9600);
//  while (!Serial) {
//    ; // wait for serial port to connect. Needed for native USB port only
//  }
 
  //setup drum interrupt
  attachInterrupt(digitalPinToInterrupt(interruptPin), hitDetected, RISING);

  //Begin bluetooth comms and name device
  BTLEserial.setDeviceName("BeeBop"); /* 7 characters max! */
  BTLEserial.begin();
  delay(5);
  
//  sixDOF.init(); //begin the IMU
  sixDOF.init(true);
  delay(5);  
}

//ISR for drum hit
void hitDetected(void) {
  //poll to see which hit and call colorDetected to debounce
  if(analogRead(switch_R) >= 200){
    colorDetected(red);
  }else if (analogRead(switch_O) >= 200){
    colorDetected(orange);
  }else if (analogRead(switch_Y) >= 200){
    colorDetected(yellow);
  }else if (analogRead(switch_B) >= 200){
    colorDetected(blue);
  }
}

//debounce function
void colorDetected(int c) {
   static unsigned long lastHitTime;
   unsigned long currentTime = micros();
   unsigned long debounceTime = DEBOUNCE_TIME;

   //if the same drum is "hit" twice, give it a longer debounce time
   if (lastHit == c){
     debounceTime = DEBOUNCE_TIME_2;
   }
   //if valid hit, add the color to the bluetooth message and reset variables
   if (currentTime - lastHitTime > debounceTime){
     messageForBT += String(c) + " ";
     lastHitTime = currentTime;
     drumsHit[c] = true;
     lastHit = c;
   }
}

//loop takes in a drum number via bluetooth from the phone
//and then cues the appropriate drum
void loop() {
  digitalWrite(enable, LOW);              //shut off the drums
  char message = -1;
  checkBluetooth();
  if (status == ACI_EVT_CONNECTED) {
    while (BTLEserial.available()) {
      message = BTLEserial.read();
      ///Serial.print(message);
      switch (message) {
        case '0': 
          digitalWrite(enable, HIGH);     //turn on the drum set
          cue(red);                       //cue the red drum
          break;
        case '1':
          digitalWrite(enable, HIGH);
          cue(orange);
          break;
        case '2':
          digitalWrite(enable, HIGH);
          cue(blue);
          break;
        case '3':
          digitalWrite(enable, HIGH);
          cue(yellow);
          break;
        case '4':                         //the number of drums if the lights are to shut off
          digitalWrite(enable, LOW);
          break;
        default:
          break;
      }
      checkBluetooth();
      
    }
  
  }
    
}

//Cues a drum as specified by the integer input
void cue(int color) 
{
  endOfSong = false;
  
  messageForBT = "";            //reset bluetooth message

  cueTime = millis();           //reset cue time
    
  //turn on color lights, wait for correct hit, send bluetooth, select green lights
  switch (color){
    case yellow:
      digitalWrite(selectColorC, LOW);
      digitalWrite(selectColorB, LOW);
      digitalWrite(selectColorA, LOW);
      waitAndSend(yellow);
      digitalWrite(selectColorC, HIGH);
      digitalWrite(selectColorB, HIGH);
      digitalWrite(selectColorA, HIGH);
      break;
    case blue:
      digitalWrite(selectColorC, LOW);
      digitalWrite(selectColorB, HIGH);
      digitalWrite(selectColorA, LOW);
      waitAndSend(blue);
      digitalWrite(selectColorC, LOW);
      digitalWrite(selectColorB, LOW);
      digitalWrite(selectColorA, HIGH);
      break; 
    case orange:
      digitalWrite(selectColorC, HIGH);
      digitalWrite(selectColorB, LOW);
      digitalWrite(selectColorA, LOW);
      waitAndSend(orange);
      digitalWrite(selectColorC, LOW);
      digitalWrite(selectColorB, HIGH);
      digitalWrite(selectColorA, HIGH);
      break; 
    case red:
      digitalWrite(selectColorC, HIGH);
      digitalWrite(selectColorB, HIGH);
      digitalWrite(selectColorA, LOW);
      waitAndSend(red);
      digitalWrite(selectColorC, HIGH);
      digitalWrite(selectColorB, LOW);
      digitalWrite(selectColorA, HIGH);
      break; 
    default:
      break;
  }
  
  //turn on the green lights for 50 iterations through the loop
  if (!endOfSong){
    for (int i = 0; i < 50; i++){
     lightCycle();
    }
  }
  
  digitalWrite(enable, LOW);        //shut off the drums
  //this function had to be int and return something or else it gave an error
}

//in cue: turn on color lights until correct drum is hit, then send bluetooth
//        and reset drumsHit array
void waitAndSend(int color){
  drumsHit[color] = false;
  float absMaxAccelData = -1;       //initailize acceleration value
  while (!drumsHit[color] && status == ACI_EVT_CONNECTED) {
    checkBluetooth();
    if (BTLEserial.available()) {
      char message = BTLEserial.peek();
      if (message == '4'){          //phone sends number of drums if end song is pressed
        endOfSong = true;
        break;
      }
    }
    lightCycle();                   //cycle cued color
  }
  drumsHit[color] = false;
  unsigned long reactionTime = millis() - cueTime;      //calculate reaction time

  messageForBT += String(reactionTime);
  messageForBT += String(" ");

  if (color == red){                  //currently we only have an accelerometer on the red drum
    for (int i = accelIterator; i < accelDataSize - 1 + accelIterator; i++){
      absMaxAccelData = max(abs(accelData[i%accelDataSize]), absMaxAccelData);          //find the largest acceleration
    }
  }
  messageForBT += String(absMaxAccelData);
  if (!endOfSong){
    String message = "";
    int chars =0;
    for(int sends = 0; chars < messageForBT.length(); sends++){
      message = "";
      /* Sending in groups of 19 characters or just the remaining portion of the message */
      for (chars; chars < (sends+1)*19 && chars < messageForBT.length(); chars++) {
        message += messageForBT.charAt(chars);
      }
      message += " "; /* Adding a space, needed to recieve properly */
      uint8_t sendbuffer[message.length()];
      message.getBytes(sendbuffer, message.length());
      char sendbuffersize = min(20, message.length());
      BTLEserial.write(sendbuffer, sendbuffersize);
    }
    
    message = "END ";
    uint8_t sendbufferEND[message.length()];
    message.getBytes(sendbufferEND, message.length());
    char sendbuffersize = min(20, message.length());
    BTLEserial.write(sendbufferEND, sendbuffersize);
  }

}

//cycle through the LED select lines quickly
void lightCycle(){
    //000
    digitalWrite(cycleC, LOW);
    digitalWrite(cycleB, LOW);
    digitalWrite(cycleA, LOW);
    getAccelData();                   //collect acceleration data once every light cycle
    delayMicroseconds(d); 
    //001
    digitalWrite(cycleA, HIGH);
    getAccelData();                   //collect acceleration data once every light cycle
    delayMicroseconds(d);
    //010
    digitalWrite(cycleB, HIGH);
    digitalWrite(cycleA, LOW);
    getAccelData();                   //collect acceleration data once every light cycle
    delayMicroseconds(d);  
    //011
    digitalWrite(cycleA, HIGH);
    getAccelData();                   //collect acceleration data once every light cycle
    delayMicroseconds(d);
    //100
    digitalWrite(cycleC, HIGH);
    digitalWrite(cycleB, LOW);
    digitalWrite(cycleA, LOW);
    getAccelData();                   //collect acceleration data once every light cycle
    delayMicroseconds(d);
    //101
    digitalWrite(cycleA, HIGH);
    getAccelData();                   //collect acceleration data once every light cycle
    delayMicroseconds(d);
    //110
    digitalWrite(cycleB, HIGH);
    digitalWrite(cycleA, LOW);
    getAccelData();                   //collect acceleration data once every light cycle
    delayMicroseconds(d); 
    //111
    digitalWrite(cycleA, HIGH);
    delayMicroseconds(d);
    
}

//this function reads the accelerometer (currently only connected to the red drum)
//it stores the accelerometer reading in a circular array
//it is called by light cycle inbetween every LED in the cycle
void getAccelData(){
  float values[4];
  sixDOF.getValues(values);
  accelData[accelIterator] = values[2];         //reads the z-axis of the accelerometer
  
  if (accelIterator < accelDataSize - 1){       //this code iterates through the circular array
    accelIterator = accelIterator + 1;
  } else {
    accelIterator = 0;
  }
}

//check the bluetooth status
void checkBluetooth(){
  // Tell the nRF8001 to do whatever it should be working on.
  BTLEserial.pollACI();

  // Ask what is our current status
  status = BTLEserial.getState();
  // If the status changed....
  if (status != laststatus) {
    // print it out!
    if (status == ACI_EVT_DEVICE_STARTED) {
        //Serial.println(F("* Advertising started"));
        digitalWrite(enable, LOW);
    }
    if (status == ACI_EVT_CONNECTED) {
        //Serial.println(F("* Connected!"));
    }
    if (status == ACI_EVT_DISCONNECTED) {
        //Serial.println(F("* Disconnected or advertising timed out"));
    }
    // OK set the last status change to this one
    laststatus = status;
  }
}

