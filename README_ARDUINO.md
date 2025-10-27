# Arduino LED Control Setup Guide

This guide will help you set up Arduino control from your website.

## What You Need

1. Arduino board (Uno, Nano, Mega, etc.)
2. LED and 220Ω resistor (or use the built-in LED)
3. USB cable to connect Arduino to your computer
4. Arduino IDE installed on your computer

## Setup Steps

### 1. Install Arduino IDE

Download and install from: https://www.arduino.cc/en/software

### 2. Upload the Arduino Code

1. Open the Arduino IDE
2. Open the file `arduino_led_control.ino`
3. Connect your Arduino to your computer via USB
4. In Arduino IDE:
   - Go to **Tools > Board** and select your Arduino model
   - Go to **Tools > Port** and select the port your Arduino is connected to
     - Windows: Usually `COM3`, `COM4`, etc.
     - Mac: Usually `/dev/cu.usbmodem14101` or similar
     - Linux: Usually `/dev/ttyUSB0` or `/dev/ttyACM0`
5. Click the **Upload** button (arrow icon)
6. Wait for "Done uploading" message

### 3. Find Your Arduino Port

After uploading, note the port name from step 2.4 above. You'll need this for the next step.

### 4. Configure the Backend Server

1. Open `server.js` in a text editor
2. Find this line (around line 17):
   ```javascript
   const ARDUINO_PORT = '/dev/cu.usbmodem14101'; // CHANGE THIS!
   ```
3. Replace the port with YOUR Arduino's port from step 3
4. Save the file

### 5. Install Node.js Dependencies

Open a terminal in the project folder and run:

```bash
npm install
```

This will install Express, SerialPort, and CORS packages.

### 6. Start the Backend Server

In the terminal, run:

```bash
npm start
```

You should see:
```
🚀 Server running on http://localhost:3000
📡 Attempting to connect to Arduino...
✅ Connected to Arduino on [your port]
Arduino says: Arduino LED Control Ready!
```

### 7. Open Your Website

Open `index.html` in your web browser. You should see:
- A green dot with "Connected" status in the Arduino Control section
- The "Toggle LED" button should be enabled (green)

### 8. Test It!

Click the "Toggle LED" button on your website. The LED on your Arduino should turn on/off!

## Wiring (if using external LED)

If you want to use an external LED instead of the built-in one:

```
Arduino Pin 13 → LED Long Leg (Anode/+)
LED Short Leg (Cathode/-) → 220Ω Resistor → GND
```

Or simply use the built-in LED on most Arduino boards (already on pin 13).

## Troubleshooting

### "Arduino not connected" error

1. Check that Arduino is plugged into USB
2. Check that the Arduino IDE can see the port
3. Make sure the port in `server.js` matches your Arduino's port
4. Restart the Node.js server after changing the port

### Server won't start

1. Make sure Node.js is installed: `node --version`
2. Make sure dependencies are installed: `npm install`
3. Check if port 3000 is already in use

### Button is disabled (grayed out)

1. Check that the backend server is running
2. Check browser console (F12) for connection errors
3. Make sure the server URL in `index.html` is correct (http://localhost:3000)

### LED doesn't respond

1. Check Arduino is receiving commands (open Serial Monitor in Arduino IDE)
2. Check wiring if using external LED
3. Try uploading the Arduino sketch again

## How It Works

1. Website button click → JavaScript sends HTTP request to Node.js server
2. Node.js server → Sends serial command ('T') to Arduino via USB
3. Arduino receives command → Toggles LED on/off
4. Arduino sends response back through serial

## API Endpoints

The backend server provides these endpoints:

- `POST /arduino/toggle` - Toggle LED on/off
- `POST /arduino/on` - Turn LED on
- `POST /arduino/off` - Turn LED off
- `GET /arduino/status` - Check if Arduino is connected

## Next Steps

You can extend this to control:
- Multiple LEDs
- Servo motors
- Sensors (and send data back to the website)
- Relays to control high-power devices

Just modify the Arduino code and add more API endpoints to the server!
