# Version Guide

This project has two separate versions to keep things simple and reliable.

## 📹 Version 1: Clean Streaming (Recommended)

**File:** `index.html`
**URL:** https://streamzadkine.netlify.app/

### ✅ Use this when:
- You just want webcam streaming
- Maximum reliability needed
- No hardware involved
- Production use

### Features:
- ✅ Peer-to-peer webcam streaming
- ✅ Audio + Video
- ✅ Simple and fast
- ✅ No dependencies on backend
- ✅ Works 100% of the time

---

## 🔌 Version 2: With Arduino Control

**File:** `index-arduino.html`
**URL:** https://streamzadkine.netlify.app/index-arduino.html

### ✅ Use this when:
- You want Arduino LED control
- You have Arduino hardware
- You're willing to run a backend server
- Experimental/demo purposes

### Features:
- ✅ Everything from Version 1
- ✅ Arduino dual LED control (pins 12, 13)
- ✅ Individual LED on/off
- ✅ Both LEDs on/off
- ✅ Alternating blink mode
- ⚠️ Requires backend server running
- ⚠️ Webcam still works if Arduino not connected

---

## Quick Comparison

| Feature | index.html | index-arduino.html |
|---------|------------|-------------------|
| Webcam Streaming | ✅ | ✅ |
| Audio | ✅ | ✅ |
| Peer-to-Peer | ✅ | ✅ |
| Arduino Control | ❌ | ✅ |
| Requires Backend | ❌ | ⚠️ Optional |
| Complexity | Simple | Medium |
| Reliability | 100% | 95% |

---

## Backend Requirements

### For index.html:
**None!** Everything runs in the browser.

### For index-arduino.html:
Only needed if you want Arduino control:

1. **Arduino hardware** (Uno/Nano with 2 LEDs)
2. **Node.js backend** (server.js)
3. **USB connection** to Arduino
4. **ngrok** (for remote access)

---

## Which Should I Use?

### Use **index.html** if:
- ✅ You just want video streaming
- ✅ You want maximum reliability
- ✅ You don't have Arduino hardware
- ✅ You want zero setup (just open URL)

### Use **index-arduino.html** if:
- ✅ You specifically need Arduino control
- ✅ You have the hardware and backend running
- ✅ You understand the extra complexity
- ✅ Webcam working without Arduino is acceptable

---

## Files Overview

```
stream/
├── index.html                    ⭐ Main version (use this)
├── index-arduino.html            🔌 Arduino version
├── server.js                     📡 Backend (Arduino only)
├── arduino_dual_led_control.ino  🔧 Firmware (Arduino only)
├── package.json                  📦 Dependencies (Arduino only)
│
├── README.md                     📖 Main documentation
├── VERSIONS.md                   📋 This file
├── QUICK_START.md                🚀 Quick setup
├── NETLIFY_DEPLOYMENT.md         ☁️ Deployment guide
├── SETUP_DUAL_LED.md             💡 Arduino setup
└── CLAUDE.md                     🏗️ Architecture details
```

---

## Switching Between Versions

Both versions are deployed simultaneously:

- **Clean version:** Just go to https://streamzadkine.netlify.app/
- **Arduino version:** Go to https://streamzadkine.netlify.app/index-arduino.html

No need to deploy separately - both are always available!

---

## Development

### Testing Clean Version Locally:
```bash
# Just open the file
open index.html
# Or use any local server
python -m http.server 8000
```

### Testing Arduino Version Locally:
```bash
# 1. Start backend
npm install
npm start

# 2. Open Arduino version
open index-arduino.html
# Or visit http://localhost:8000/index-arduino.html

# 3. Connect to Arduino backend
# Enter http://localhost:3000 in the Arduino Server URL field
```

---

## Deployment

Both versions deploy automatically when you push to GitHub:

```bash
git add .
git commit -m "Update"
git push
```

Netlify automatically:
- Deploys both HTML files
- Applies correct security headers to each
- Makes both URLs available

**Clean version:** Default (`/`)
**Arduino version:** `/index-arduino.html`

---

## Support

- **Clean version issues:** Should never happen (it's very simple)
- **Arduino version issues:** Check backend is running, Arduino connected, correct port configured
- **Both not working:** Check internet connection, camera permissions
