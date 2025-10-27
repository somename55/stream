/*
 * Arduino Dual LED Control via Serial
 *
 * Controls two LEDs via serial commands from computer
 * - Pin 13: LED 1 (e.g., Red LED)
 * - Pin 12: LED 2 (e.g., Blue LED)
 *
 * Commands:
 * - 'R1' : Turn Red LED (pin 13) ON
 * - 'R0' : Turn Red LED (pin 13) OFF
 * - 'B1' : Turn Blue LED (pin 12) ON
 * - 'B0' : Turn Blue LED (pin 12) OFF
 * - 'ALL_ON'  : Turn both LEDs ON
 * - 'ALL_OFF' : Turn both LEDs OFF
 * - 'ALTERNATE' : Alternate between red and blue (like your original code)
 * - 'STOP' : Stop alternating mode
 */

const int RED_LED_PIN = 13;   // Pin for red LED
const int BLUE_LED_PIN = 12;  // Pin for blue LED

bool redState = false;
bool blueState = false;
bool alternateMode = false;

void setup() {
  // Initialize serial communication
  Serial.begin(9600);

  // Set LED pins as output
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(BLUE_LED_PIN, OUTPUT);

  // Turn off both LEDs initially
  digitalWrite(RED_LED_PIN, LOW);
  digitalWrite(BLUE_LED_PIN, LOW);

  // Wait for serial connection
  while (!Serial) {
    ; // Wait for serial port to connect
  }

  Serial.println("Dual LED Control Ready!");
  Serial.println("Commands: R1/R0 (red), B1/B0 (blue), ALL_ON, ALL_OFF, ALTERNATE, STOP");
}

void loop() {
  // Handle alternate mode
  if (alternateMode) {
    digitalWrite(RED_LED_PIN, HIGH);
    digitalWrite(BLUE_LED_PIN, LOW);
    delay(1000);

    // Check for stop command during delay
    if (Serial.available() > 0) {
      String command = Serial.readStringUntil('\n');
      command.trim();
      if (command == "STOP") {
        alternateMode = false;
        Serial.println("Alternate mode stopped");
        return;
      }
    }

    digitalWrite(RED_LED_PIN, LOW);
    digitalWrite(BLUE_LED_PIN, HIGH);
    delay(1000);

    // Check again after second delay
    if (Serial.available() > 0) {
      String command = Serial.readStringUntil('\n');
      command.trim();
      if (command == "STOP") {
        alternateMode = false;
        Serial.println("Alternate mode stopped");
        return;
      }
    }
    return; // Skip normal command processing while alternating
  }

  // Check for serial commands
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    // Red LED commands
    if (command == "R1") {
      digitalWrite(RED_LED_PIN, HIGH);
      redState = true;
      Serial.println("Red LED: ON");

    } else if (command == "R0") {
      digitalWrite(RED_LED_PIN, LOW);
      redState = false;
      Serial.println("Red LED: OFF");

    // Blue LED commands
    } else if (command == "B1") {
      digitalWrite(BLUE_LED_PIN, HIGH);
      blueState = true;
      Serial.println("Blue LED: ON");

    } else if (command == "B0") {
      digitalWrite(BLUE_LED_PIN, LOW);
      blueState = false;
      Serial.println("Blue LED: OFF");

    // Both LEDs
    } else if (command == "ALL_ON") {
      digitalWrite(RED_LED_PIN, HIGH);
      digitalWrite(BLUE_LED_PIN, HIGH);
      redState = true;
      blueState = true;
      Serial.println("Both LEDs: ON");

    } else if (command == "ALL_OFF") {
      digitalWrite(RED_LED_PIN, LOW);
      digitalWrite(BLUE_LED_PIN, LOW);
      redState = false;
      blueState = false;
      Serial.println("Both LEDs: OFF");

    // Alternate mode
    } else if (command == "ALTERNATE") {
      alternateMode = true;
      Serial.println("Alternate mode started");

    } else if (command == "STOP") {
      alternateMode = false;
      Serial.println("Already stopped");

    } else {
      Serial.print("Unknown command: ");
      Serial.println(command);
    }
  }
}
