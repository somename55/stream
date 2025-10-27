# Webcam Streaming App

Simple peer-to-peer webcam streaming using WebRTC and PeerJS.

## Two Versions Available

### 1. **index.html** - Clean Webcam Streaming ✅
- Simple and reliable
- No external dependencies (except PeerJS)
- Perfect for basic streaming
- **Use this for most cases**

**Live URL:** https://streamzadkine.netlify.app/

### 2. **index-arduino.html** - With Arduino LED Control
- Everything from version 1
- Plus Arduino dual LED control (pins 12 & 13)
- Requires Arduino backend server running
- Optional - webcam works without Arduino

**Live URL:** https://streamzadkine.netlify.app/index-arduino.html

---

## Quick Start

### For Webcam Streaming Only:

**Broadcaster (iPhone/Computer 1):**
1. Open https://streamzadkine.netlify.app/
2. Click "Start Broadcasting"
3. Allow camera access
4. Share your Peer ID

**Viewer (Computer 2):**
1. Open https://streamzadkine.netlify.app/
2. Click "View Stream"
3. Enter broadcaster's Peer ID
4. Click "Connect"

---

## Arduino Version Setup

Only if using `index-arduino.html`:

### 1. Upload Arduino Code
```bash
# Open Arduino IDE
# Upload: arduino_dual_led_control.ino
# Note your port (e.g., COM3 or /dev/cu.usbmodem14101)
```

### 2. Start Backend Server
```bash
# Edit server.js line 18 with your Arduino port
npm install
npm start
# Server runs on http://localhost:3000
```

### 3. Expose for Remote Access (Optional)
```bash
# For remote control via ngrok:
ngrok http 3000
# Copy the HTTPS URL
```

### 4. Use the Arduino Version
1. Open https://streamzadkine.netlify.app/index-arduino.html
2. Enter your backend URL in "Arduino Server URL"
3. Click "Connect"
4. Control LEDs while streaming!

---

## Files

- **index.html** - Clean streaming version (recommended)
- **index-arduino.html** - Streaming + Arduino control
- **server.js** - Arduino backend (Node.js + SerialPort)
- **arduino_dual_led_control.ino** - Arduino firmware
- **package.json** - Backend dependencies

---

## Documentation

- **QUICK_START.md** - Quick setup guide
- **NETLIFY_DEPLOYMENT.md** - Deployment instructions
- **SETUP_DUAL_LED.md** - Arduino wiring and setup
- **CLAUDE.md** - Technical architecture

---

## Tech Stack

- **Frontend:** HTML5, JavaScript, WebRTC
- **Streaming:** PeerJS (peer-to-peer)
- **Backend (Arduino only):** Node.js, Express, SerialPort
- **Hardware (Arduino only):** Arduino Uno/Nano, 2 LEDs

---

## Browser Support

- Chrome/Edge 80+
- Firefox 75+
- Safari 14+ (iOS 14.3+)
- Opera 67+

**Note:** Requires HTTPS for getUserMedia API (Netlify provides this automatically)
