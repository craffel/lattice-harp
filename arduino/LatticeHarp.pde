/* Lattice Harp Firmware 
   communicates via monome serial protocol
   by Colin Raffel, 2009 */


// Number of strings on the lattice harp
const char numStrings = 8;

// Current button values
char currentVals[numStrings][numStrings];
// Debounce values for each switch
// Note = debouncing algorithm is "counting", see 
// http://www.ganssle.com/debouncing.pdf
// "A counting algorithm", page 18
char debounceVals[numStrings][numStrings];
// Number to count up to before sending values
char debounceMax = 10;
// Our serial received message
char serialMessage = 0;
// Shift amount array for speedup
char shifts[8] = {0b00000001, 0b00000010, 0b00000100, 0b00001000, 0b00010000, 0b00100000, 0b01000000, 0b10000000};
// Press location message
char spotMessage;
// Read in all pin values
char readAll;
// Reading per pin
char reading;

void sendPress( char state, char x, char y )
{
    // send a serial message of the state,
    // Correct format is 0000 (address) 000x (state)
    // Fortunately this is just 1 or 0.
    Serial.print(state, BYTE);
    // Send a message of the location
    // Format is yyyyxxxx
    spotMessage = (y << 4) | x;
    Serial.print(spotMessage, BYTE);
    
}
void setup() {
  
  // start serial port at 9600 bps:
  Serial.begin(9600);
  
  // Setup pins
  for (int i = 0; i < numStrings; i++){
    // Set pins 10 - 17 as input
    // (We are using pins D10-17, hence +10 offset)
    pinMode(i+2+numStrings, INPUT);
    // Pullups on 10-17
    // So that these pins sit at 5V
   digitalWrite(i+2+numStrings, HIGH);
  }
  
}

void loop() {
  
  
  // Check buttons
  for (int i = 0; i < numStrings; i++){
    // Make the i'th row output 0V
    // The opposite of the 5V or col's sit at
    pinMode(i+2, OUTPUT);
    digitalWrite(i+2, LOW);
    readAll = ((PINB & 0b00111100) >> 2) | ((PINC & 0b00001111) << 4);
    for (int j = 0; j < numStrings; j++ ){
      // Read in value from j'th column
      reading = readAll & 1;
      //char reading = digitalRead(j+2+numStrings);
      // If the button is up, decrement its debounce value
      if ( reading && (debounceVals[i][j] > 0) )
      {
        debounceVals[i][j]--;
        // If the debounce value is at it's bounds, eg debounceMax or 0
        // and the reading is not the last reading sent out...
        if ( (debounceVals[i][j] == 0) && ( reading != currentVals[i][j] ))
        {
            // Send out a message with the reading's 1 bit inverted
            // Because we want a press to be 1, and an un-press to be 0
            // Which is the opposite of what the pin sits at
            // Because they are pull UPs.
            sendPress( reading ^ 1, i, j );
            // Remember the current value
            currentVals[i][j] = reading;
        }
      }
      // If the button is down (a press!) increment debounce value
      if ( !reading && (debounceVals[i][j] < debounceMax) )
      {
        debounceVals[i][j]++;
        // If the debounce value is at it's bounds, eg debounceMax or 0
        // and the reading is not the last reading sent out...
        if ( (debounceVals[i][j] == debounceMax) && ( reading != currentVals[i][j] ))
        {
          // Send out a message with the reading's 1 bit inverted
          // Because we want a press to be 1, and an un-press to be 0
          // Which is the opposite of what the pin sits at
          // Because they are pull UPs.
          sendPress( reading ^ 1, i, j );
          // Remember the current value
          currentVals[i][j] = reading;
        } 
      }
      readAll = readAll >> 1;
    }
    // OK, now we are done with this row, do it again.
    // Make this row an input so that it doesn't affect
    // future readings
    pinMode(i+2, INPUT);
  } 
  
}
