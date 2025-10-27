# Quick Start Guide - Webcam Stream + Arduino Control

## How It Works

### Person 1 (Broadcaster) 👁️
- Opens the website (Netlify)
- Clicks "Start Broadcasting"
- Shares their Peer ID
- Shows webcam to viewer

### Person 2 (Viewer with Arduino) 🎮
- Opens the website (Netlify)
- Clicks "View Stream"
- Enters broadcaster's Peer ID
- Watches their webcam
- **Controls the Arduino LEDs** (red and blue)

## Setup for Viewer with Arduino

### Step 1: Upload Arduino Code
```bash
# Open Arduino IDE
# Upload: arduino_dual_led_control.ino
# Note your Arduino port (e.g., COM3, /dev/cu.usbmodem14101)
```

### Step 2: Configure and Start Backend
```bash
# Edit server.js line 18 with your Arduino port
# Then run:
npm install
npm start
```

### Step 3: Expose Backend to Internet (for remote control)

**If testing locally (same WiFi):**
- Use your local IP: `http://192.168.1.X:3000`

**If remote (different WiFi):**
```bash
# Download and install ngrok from ngrok.com
# Run:
ngrok http 3000

# Copy the HTTPS URL it gives you
# Example: https://abc123.ngrok-free.app
```

### Step 4: Use the Website
1. Open your Netlify site
2. Enter the backend URL in "Arduino Server URL" field
3. Click "Connect" (should show green "Connected")
4. Click "View Stream" to watch broadcaster
5. Control the LEDs while watching!

## LED Controls Available

- **Red LED ON/OFF** - Control red LED (pin 13)
- **Blue LED ON/OFF** - Control blue LED (pin 12)
- **Both ON/OFF** - Control both at once
- **Start Alternating** - Make them blink alternately (like your original code!)
- **Stop Alternating** - Stop the blinking

## Common Scenarios

### Scenario A: Testing Locally
Both people on same WiFi:
1. Broadcaster starts stream on Netlify
2. Viewer with Arduino:
   - Finds local IP: `ipconfig` or `ifconfig`
   - Enters `http://192.168.1.X:3000` in Arduino Server URL
   - Connects and controls

### Scenario B: Remote Access
Different locations:
1. Viewer with Arduino runs ngrok
2. Shares ngrok URL with themselves (or saves it)
3. Opens Netlify site
4. Enters ngrok URL: `https://abc123.ngrok-free.app`
5. Watches stream and controls Arduino

### Scenario C: Same Person Does Both
One person broadcasts AND has Arduino:
1. Start backend locally: `npm start`
2. Open Netlify site
3. Use `http://localhost:3000` for Arduino
4. Click "Start Broadcasting"
5. Share Peer ID with others
6. They can watch, you can control Arduino

## Wiring Reference

```
Arduino Pin 13 → Red LED (+) → 220Ω Resistor → GND
Arduino Pin 12 → Blue LED (+) → 220Ω Resistor → GND
```

Or use the built-in LED on pin 13 and add one external LED on pin 12.

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| "Arduino not connected" | Make sure backend is running (`npm start`) |
| Can't connect from Netlify | Use ngrok URL, not localhost |
| CORS error | Make sure server.js has CORS enabled (it does by default) |
| LEDs don't respond | Check wiring, test with Arduino IDE Serial Monitor |
| ngrok URL doesn't work | Make sure you copied the HTTPS URL and backend is running |
| Webcam not working | Click "Allow" when browser asks for camera permission |
| Can't see stream | Check if Peer ID is correct and both users are online |

## URLs You Need

**Frontend (Website):**
- Deployed on Netlify: `https://your-app.netlify.app`
- This is what EVERYONE opens

**Backend (Arduino Server):**
- Local: `http://localhost:3000`
- Same WiFi: `http://192.168.1.X:3000`
- Remote (ngrok): `https://abc123.ngrok-free.app`
- This is where Arduino is connected

## Testing Without Arduino

Want to test the webcam streaming first?
1. Just deploy to Netlify
2. Two people open the site
3. One broadcasts, one views
4. Arduino controls will be disabled (that's OK)

## Files Reference

- `index.html` - Website (deploy this to Netlify)
- `server.js` - Arduino backend (run locally)
- `arduino_dual_led_control.ino` - Upload to Arduino
- `package.json` - Dependencies for backend
- `netlify.toml` - Netlify configuration (auto-detected)

## Need Help?

1. Check `NETLIFY_DEPLOYMENT.md` for detailed deployment steps
2. Check `SETUP_DUAL_LED.md` for Arduino wiring and setup
3. Check `CLAUDE.md` for technical architecture details
