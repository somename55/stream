/*
 * Arduino LED Control via Serial
 *
 * This sketch allows you to control an LED connected to pin 13
 * by sending commands from your computer via serial communication.
 *
 * Commands:
 * - '1' or 'ON'  : Turn LED ON
 * - '0' or 'OFF' : Turn LED OFF
 * - 'T'          : Toggle LED (switch between ON and OFF)
 *
 * Wiring:
 * - Connect LED positive (long leg) to Pin 13
 * - Connect LED negative (short leg) to GND through a 220Ω resistor
 * - Or use the built-in LED (already on pin 13 on most Arduino boards)
 */

const int LED_PIN = 13;  // Pin connected to LED (use built-in LED on pin 13)
bool ledState = false;   // Track current LED state

void setup() {
  // Initialize serial communication at 9600 baud
  Serial.begin(9600);

  // Set LED pin as output
  pinMode(LED_PIN, OUTPUT);

  // Turn off LED initially
  digitalWrite(LED_PIN, LOW);

  // Wait for serial connection
  while (!Serial) {
    ; // Wait for serial port to connect
  }

  Serial.println("Arduino LED Control Ready!");
  Serial.println("Commands: 1=ON, 0=OFF, T=Toggle");
}

void loop() {
  // Check if data is available to read
  if (Serial.available() > 0) {
    // Read the incoming command
    String command = Serial.readStringUntil('\n');
    command.trim(); // Remove whitespace

    // Process the command
    if (command == "1" || command == "ON") {
      // Turn LED ON
      digitalWrite(LED_PIN, HIGH);
      ledState = true;
      Serial.println("LED: ON");

    } else if (command == "0" || command == "OFF") {
      // Turn LED OFF
      digitalWrite(LED_PIN, LOW);
      ledState = false;
      Serial.println("LED: OFF");

    } else if (command == "T") {
      // Toggle LED
      ledState = !ledState;
      digitalWrite(LED_PIN, ledState ? HIGH : LOW);
      Serial.print("LED: ");
      Serial.println(ledState ? "ON" : "OFF");

    } else {
      // Unknown command
      Serial.print("Unknown command: ");
      Serial.println(command);
    }
  }
}
