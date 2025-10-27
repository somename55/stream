# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a webcam streaming application with Arduino LED control capabilities. The application combines two main features:
1. **WebRTC-based peer-to-peer video streaming** using PeerJS for browser-to-browser webcam sharing
2. **Arduino hardware control** via a Node.js backend server that communicates with Arduino over serial USB connection

## Architecture

### Frontend (index.html)
- Single-page application handling both webcam streaming and Arduino control
- Uses PeerJS library (v1.5.1 via CDN) for WebRTC peer connections
- Implements two modes: Broadcaster (shares webcam) and Viewer (receives stream)
- Arduino control UI polls backend every 5 seconds to check connection status
- Backend URL is hardcoded to `http://localhost:3000` (line 132)

### Backend (server.js)
- Express.js server running on port 3000
- SerialPort library for Arduino USB communication at 9600 baud
- CORS enabled for cross-origin requests from frontend
- Arduino port path must be manually configured (line 18)
- Maintains persistent serial connection state in `isConnected` flag

### Arduino Firmware (arduino_led_control.ino)
- Controls LED on pin 13 (built-in LED on most boards)
- Accepts serial commands: '1'/'ON' (on), '0'/'OFF' (off), 'T' (toggle)
- Sends confirmation responses back via serial
- Runs at 9600 baud serial communication rate

## Common Commands

### Development
```bash
# Install dependencies
npm install

# Start the backend server
npm start

# Server runs on http://localhost:3000
```

### Arduino Setup
```bash
# The Arduino port MUST be configured in server.js:18
# Common ports:
# - Mac: /dev/cu.usbmodem14101 or similar
# - Windows: COM3, COM4, etc.
# - Linux: /dev/ttyUSB0, /dev/ttyACM0

# Upload arduino_led_control.ino using Arduino IDE
# Set board type and port in Tools menu
# Click Upload button
```

### Frontend
```bash
# Open index.html directly in browser
# Or serve via any static server

# For local development, open file:// URL works
# For production, deploy index.html to static hosting
```

## Critical Configuration Points

### Arduino Port Configuration
The Arduino port path in `server.js:18` must match the actual USB port where Arduino is connected. This is the most common source of connection failures. Check Arduino IDE's Tools > Port menu to identify the correct port.

### Backend URL in Frontend
The frontend hardcodes `BACKEND_URL = 'http://localhost:3000'` (index.html:132). For production deployment, this needs to be updated to the actual backend server URL.

### WebRTC STUN Servers
Both broadcaster and viewer use Google's public STUN servers for NAT traversal (index.html:224-225, 285-286). For production with firewall/NAT restrictions, additional TURN servers may be required.

## API Endpoints

All endpoints are defined in server.js:

- `POST /arduino/toggle` - Toggle LED state (sends 'T' command)
- `POST /arduino/on` - Turn LED on (sends '1' command)
- `POST /arduino/off` - Turn LED off (sends '0' command)
- `GET /arduino/status` - Returns `{connected: boolean}` for Arduino connection state

## WebRTC Streaming Flow

1. Broadcaster starts stream → creates PeerJS instance → gets unique peer ID
2. Broadcaster shares peer ID with viewer out-of-band
3. Viewer enters peer ID → creates call with dummy audio/video stream
4. Broadcaster receives call → answers with actual webcam stream
5. Viewer receives remote stream → displays in video element

The dummy stream on viewer side (index.html:307-327) is necessary to properly negotiate both audio and video tracks in the WebRTC connection.

## Serial Communication Protocol

Arduino communication uses newline-terminated ASCII commands over serial:
- Commands sent from Node.js: `'T\n'`, `'1\n'`, `'0\n'`
- Arduino responses parsed using ReadlineParser with `\r\n` delimiter
- Arduino sends human-readable confirmations like "LED: ON"

## Development Considerations

### Modifying Arduino Control
To add new Arduino commands:
1. Update arduino_led_control.ino to handle new command character
2. Add new API endpoint in server.js that sends the command via `port.write()`
3. Add UI button/control in index.html that calls the new endpoint
4. The serial protocol is extensible - use single character commands for simplicity

### WebRTC Debugging
- Check browser console for detailed WebRTC logs (enabled on lines 213-236, 333-369)
- Video track state is extensively logged including enabled/muted/readyState
- Common issue: video tracks not negotiated - ensure broadcaster has both audio and video

### Serial Port Issues
- Port must be closed in other applications (Arduino IDE Serial Monitor will block connection)
- Permission errors on Linux require user to be in `dialout` group
- Connection state tracked via SerialPort events: 'open', 'error', 'close'
