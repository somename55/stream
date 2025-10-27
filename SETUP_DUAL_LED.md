# Dual LED Control Setup Guide

This guide will help you set up your Arduino with 2 LEDs (red and blue) controlled from the web interface.

## What You Have

- **Red LED** on Pin 13
- **Blue LED** on Pin 12
- Web interface with individual and combined controls

## Step-by-Step Setup

### 1. Upload the Arduino Code

1. Open Arduino IDE
2. Open the file **`arduino_dual_led_control.ino`** (NOT the old one!)
3. Connect your Arduino via USB
4. In Arduino IDE:
   - Select your board: Tools > Board > (your Arduino model)
   - Select your port: Tools > Port > (your Arduino port)
5. Click **Upload** button (→)
6. Wait for "Done uploading"

### 2. Note Your Arduino Port

After uploading, remember the port from Tools > Port menu:
- **Mac**: `/dev/cu.usbmodem14101` (or similar)
- **Windows**: `COM3`, `COM4`, etc.
- **Linux**: `/dev/ttyUSB0`, `/dev/ttyACM0`

### 3. Configure the Server

1. Open `server.js` in a text editor
2. Find line 18:
   ```javascript
   const ARDUINO_PORT = '/dev/cu.usbmodem14101'; // CHANGE THIS!
   ```
3. Change it to YOUR Arduino's port from step 2
4. Save the file

### 4. Install Dependencies

Open terminal in your project folder:
```bash
npm install
```

### 5. Start the Server

```bash
npm start
```

You should see:
```
🚀 Server running on http://localhost:3000
📡 Attempting to connect to Arduino...
✅ Connected to Arduino on [your port]
Arduino says: Dual LED Control Ready!
```

### 6. Open the Web Interface

Open `index.html` in your browser. You should see:
- Green "Connected" status
- All buttons enabled

## Available Controls

### Individual LED Control
- **Turn Red ON** - Turns on red LED (pin 13)
- **Turn Red OFF** - Turns off red LED (pin 13)
- **Turn Blue ON** - Turns on blue LED (pin 12)
- **Turn Blue OFF** - Turns off blue LED (pin 12)

### Both LEDs
- **Turn Both ON** - Both LEDs on at the same time
- **Turn Both OFF** - Both LEDs off

### Alternate Mode
- **Start Alternating** - Red and blue alternate every second (like your original code!)
- **Stop Alternating** - Stops the alternating pattern

## Wiring

Your current setup:
```
Arduino Pin 13 → Red LED (+) → Resistor → GND
Arduino Pin 12 → Blue LED (+) → Resistor → GND
```

If using external LEDs (not built-in):
- Use 220Ω resistor for each LED
- Connect long leg (anode/+) to the pin
- Connect short leg (cathode/-) through resistor to GND

## Testing

1. Click "Turn Red ON" → Red LED should turn on
2. Click "Turn Blue ON" → Blue LED should turn on
3. Click "Turn Both OFF" → Both should turn off
4. Click "Start Alternating" → LEDs should alternate like your original code
5. Click "Stop Alternating" → Alternating stops

## Troubleshooting

### Arduino not connected

1. Check USB cable is plugged in
2. Check the port in `server.js` matches your Arduino
3. Close Arduino IDE Serial Monitor (it blocks the port)
4. Restart the Node.js server: Ctrl+C, then `npm start`

### LEDs don't respond

1. Open Arduino IDE Serial Monitor (Tools > Serial Monitor)
2. Set baud rate to 9600
3. Type commands manually to test:
   - Type `R1` and press Enter → Red LED should turn on
   - Type `B1` and press Enter → Blue LED should turn on
   - Type `R0` and press Enter → Red LED should turn off

### Server won't start

1. Make sure Node.js is installed: `node --version`
2. Make sure dependencies are installed: `npm install`
3. Check if port 3000 is in use by another program

## API Endpoints

Your server now has these endpoints:

**Individual Control:**
- `POST /arduino/red/on` - Red LED on
- `POST /arduino/red/off` - Red LED off
- `POST /arduino/blue/on` - Blue LED on
- `POST /arduino/blue/off` - Blue LED off

**Combined Control:**
- `POST /arduino/all/on` - Both on
- `POST /arduino/all/off` - Both off

**Alternate Mode:**
- `POST /arduino/alternate/start` - Start alternating
- `POST /arduino/alternate/stop` - Stop alternating

**Status:**
- `GET /arduino/status` - Check connection

## Arduino Serial Commands

The Arduino accepts these commands:
- `R1` - Red LED on
- `R0` - Red LED off
- `B1` - Blue LED on
- `B0` - Blue LED off
- `ALL_ON` - Both on
- `ALL_OFF` - Both off
- `ALTERNATE` - Start alternating mode
- `STOP` - Stop alternating mode

## Next Steps

You can extend this to:
- Add more LEDs on different pins
- Add sensors and send data back to the website
- Control motors, servos, or relays
- Create custom light patterns
