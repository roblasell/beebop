/*
 * Mobile Medical Devices and Apps
 * Spring 2016
 * Project 2
 * Rob Lasell, Ferdinand Dowouo, Ari Scourtas, Jake Hellman, Katia Kravchenko, Trish O'Connor
 * 
 * Arduino YUN Script
 * 
 * BeeBop
 * 
 * This script takes in data via bluetooth from our iPhone App and cues the proper drums.
 * It collects data from the drum hits and stores it on an SD card.
 * The data is sent to the iPhone app via bluetooth when queried.
 */

#define enable 4                  //This is used to enable the color controller demux
#define selectColorA 5            //This select line goes to the color controller demux
#define selectColorB 6            //This select line goes to the color controller demux
#define selectColorC 7            //This select line goes to the color controller demux
#define cycleA 8                  //This select line goes to the LED demuxes to cycle the LEDs
#define cycleB 9                  //This select line goes to the LED demuxes to cycle the LEDs
#define cycleC 10                 //This select line goes to the LED demuxes to cycle the LEDs
#define switch_R 0                //This is the pin for the red drum switch
#define switch_O 1                //This is the pin for the orange drum switch
#define switch_B 2                //This is the pin for the blue drum switch
#define switch_Y 3                //This is the pin for the yellow drum switch
#define d 1500                    //This is the microsecond delay between 8 LEDs as they are cylced by a demux
#define greenOnTime 75            //This is the number of iterations through a loop for which the green LEDs remain on after a correct hit
long lastDebounceTime = 0;        //Used for debouncing the switches
long debounceDelay = 50;          //Used for debouncing the switches
int buttonState;                  //Used for debouncing the switches
int lastButtonState = LOW;        //Used for debouncing the switches
int reading = LOW;                //Used for debouncing the switches

void setup() {
  Serial.begin(9600);
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
}

void loop() {

  turnOn();
  
  turnOnDrum('r', switch_R);
  turnOnDrum('o', switch_O);
  turnOnDrum('b', switch_B);
  turnOnDrum('y', switch_Y);

}

//This function takes in a drum's color and switch pin for the drum and lights up the selected drum
//until it is pressed.  When pressed, the drum's green LEDs turn on briefly and then the function returns.
void turnOnDrum(char color, int switchPin) 
{
  //pick color
  switch (color)
  {
    case 'y':
      digitalWrite(selectColorC, LOW);
      digitalWrite(selectColorB, LOW);
      digitalWrite(selectColorA, LOW);
      break;
    case 'b':
      digitalWrite(selectColorC, LOW);
      digitalWrite(selectColorB, HIGH);
      digitalWrite(selectColorA, LOW);
      break; 
    case 'o':
      digitalWrite(selectColorC, HIGH);
      digitalWrite(selectColorB, LOW);
      digitalWrite(selectColorA, LOW);
      break; 
    case 'r':
      digitalWrite(selectColorC, HIGH);
      digitalWrite(selectColorB, HIGH);
      digitalWrite(selectColorA, LOW);
      break; 
    default:
      break;
  }
  Serial.println("selected color");
  
  //wait for switch for this color to be pushed
  while(check_button(switchPin) == false)
  {
    Serial.println("in while loop");
    lightCycle();
  }

  Serial.println("through while loop");

  switch (color)
  {
    case 'y':
      digitalWrite(selectColorC, HIGH);
      digitalWrite(selectColorB, HIGH);
      digitalWrite(selectColorA, HIGH);
      break;
    case 'b':
      digitalWrite(selectColorC, LOW);
      digitalWrite(selectColorB, LOW);
      digitalWrite(selectColorA, HIGH);
      break; 
    case 'o':
      digitalWrite(selectColorC, LOW);
      digitalWrite(selectColorB, HIGH);
      digitalWrite(selectColorA, HIGH);
      break; 
    case 'r':
      digitalWrite(selectColorC, HIGH);
      digitalWrite(selectColorB, LOW);
      digitalWrite(selectColorA, HIGH);
      break; 
    default:
      break;
  }

  Serial.println("selected green");

  //turn on the green lights
  
  for (int i = 0; i < greenOnTime; i++) 
  {
    lightCycle();
  }

  Serial.println("green done");
  return;
}

//Cycle through the 8 LEDs for the selected color when this is called.
void lightCycle()
{
    //000
    digitalWrite(cycleC, LOW);
    digitalWrite(cycleB, LOW);
    digitalWrite(cycleA, LOW);
    delayMicroseconds(d); 
    //001
    digitalWrite(cycleA, HIGH);
    delayMicroseconds(d);
    //010
    digitalWrite(cycleB, HIGH);
    digitalWrite(cycleA, LOW);
    delayMicroseconds(d);  
    //011
    digitalWrite(cycleA, HIGH);
    delayMicroseconds(d);
    //100
    digitalWrite(cycleC, HIGH);
    digitalWrite(cycleB, LOW);
    digitalWrite(cycleA, LOW);
    delayMicroseconds(d);
    //101
    digitalWrite(cycleA, HIGH);
    delayMicroseconds(d);
    //110
    digitalWrite(cycleB, HIGH);
    digitalWrite(cycleA, LOW);
    delayMicroseconds(d); 
    //111
    digitalWrite(cycleA, HIGH);
    delayMicroseconds(d);
}

//Turn on drums
void turnOn(){
  digitalWrite(enable, HIGH);
}

//Shut off all of the lights
void turnOff(){
  digitalWrite(enable, LOW);
}

//Debounce button to see if it has been pressed.
boolean check_button(int switchPin) {
  reading = digitalRead(switchPin);

  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (reading != buttonState) {
      buttonState = reading;

      if (buttonState == HIGH) {
        return true;
      }
    }
  }

  lastButtonState = reading;

  return false;
}

