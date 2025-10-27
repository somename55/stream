# Netlify Deployment Guide

This guide explains how to deploy your webcam streaming + Arduino control app on Netlify.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  NETLIFY (Public Internet)                              │
│  https://your-app.netlify.app                           │
│                                                          │
│  - index.html (Frontend)                                │
│  - Webcam streaming (PeerJS/WebRTC)                     │
│  - Arduino control UI                                   │
└─────────────────────────────────────────────────────────┘
                          │
                          │ HTTP Requests for Arduino control
                          ▼
┌─────────────────────────────────────────────────────────┐
│  LOCAL MACHINE (where Arduino is connected)             │
│                                                          │
│  - server.js (Backend on port 3000)                     │
│  - Arduino connected via USB                            │
│  - Must be exposed to internet (ngrok/port forward)     │
└─────────────────────────────────────────────────────────┘
```

## Important: Backend Must Run Locally

⚠️ **The Arduino backend CANNOT be deployed to Netlify** because:
- Netlify only hosts static files (HTML, CSS, JS)
- The Arduino is physically connected via USB to a computer
- The Node.js server must run on that computer

## Deployment Steps

### 1. Deploy Frontend to Netlify

#### Option A: Deploy via GitHub

1. **Push your code to GitHub**:
   ```bash
   git add .
   git commit -m "Add dual LED control"
   git push
   ```

2. **Connect to Netlify**:
   - Go to https://app.netlify.com
   - Click "Add new site" > "Import an existing project"
   - Choose "GitHub" and select your repository
   - Configure build settings:
     - **Build command**: Leave empty (it's just static HTML)
     - **Publish directory**: `/` (root directory)
   - Click "Deploy site"

3. **Your site will be live** at `https://random-name.netlify.app`

#### Option B: Manual Deploy

1. **Drag and drop to Netlify**:
   - Go to https://app.netlify.com
   - Drag `index.html` directly onto the deploy area
   - Your site will be live immediately

### 2. Set Up Arduino Backend Locally

The Arduino backend **must run on the computer** where the Arduino is connected.

#### Install and Start:

```bash
# On the machine with Arduino connected
npm install
npm start
```

You should see:
```
🚀 Server running on http://localhost:3000
✅ Connected to Arduino
```

### 3. Expose Backend to Internet

Since your frontend is on Netlify (public internet) and backend is on your local machine, you need to make the backend accessible from the internet.

#### Option A: ngrok (Easiest for Testing)

1. **Install ngrok**:
   - Download from https://ngrok.com/download
   - Create free account
   - Follow setup instructions

2. **Expose your local server**:
   ```bash
   ngrok http 3000
   ```

3. **Copy the HTTPS URL**:
   ```
   Forwarding  https://abc123.ngrok-free.app -> http://localhost:3000
   ```

4. **Use this URL in your Netlify site**:
   - Open your Netlify site
   - Enter the ngrok URL: `https://abc123.ngrok-free.app`
   - Click "Connect"

⚠️ **ngrok free URLs change every time you restart ngrok**

#### Option B: Port Forwarding (Permanent Solution)

If you have a static IP or domain:

1. **Configure your router**:
   - Forward external port (e.g., 3000) to your local machine
   - Set up Dynamic DNS if you don't have static IP

2. **Use your public IP/domain**:
   - Example: `http://your-ip-address:3000`
   - Or: `http://your-domain.com:3000`

3. **Security considerations**:
   - Use HTTPS (set up SSL certificate)
   - Add authentication if needed
   - Restrict access by IP if possible

#### Option C: Cloud Server with Arduino (Advanced)

Deploy backend to a cloud server (AWS, DigitalOcean, etc.) and connect Arduino to it:
- Set up a VPS
- Install Node.js
- Connect Arduino via USB
- Run server.js
- Use server's public IP

### 4. Configure CORS (If needed)

If you get CORS errors, update `server.js`:

```javascript
// Replace the existing cors() line with:
app.use(cors({
    origin: [
        'https://your-app.netlify.app',
        'http://localhost:5500',  // For local testing
        'http://127.0.0.1:5500'
    ],
    credentials: true
}));
```

## Usage Scenarios

### Scenario 1: Same Network (Local Testing)

Both users on same WiFi:

1. **Person with Arduino**:
   - Run `npm start`
   - Find local IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
   - Example: `192.168.1.100`

2. **Other person**:
   - Open Netlify site
   - Enter: `http://192.168.1.100:3000`
   - Control Arduino

### Scenario 2: Remote Access (Different Networks)

Users on different WiFi/locations:

1. **Person with Arduino**:
   - Run `npm start`
   - Run `ngrok http 3000`
   - Share ngrok URL: `https://abc123.ngrok-free.app`

2. **Remote person**:
   - Open Netlify site
   - Enter the ngrok URL
   - Control Arduino

### Scenario 3: Broadcaster Has Arduino

If the same person broadcasts webcam AND has Arduino:

1. Open Netlify site
2. Click "Start Broadcasting"
3. Share Peer ID with viewer
4. Arduino controls work automatically (localhost)

### Scenario 4: Viewer Controls Arduino

If the viewer wants to control Arduino:

1. Viewer has Arduino connected locally
2. Viewer runs backend: `npm start`
3. Viewer exposes with ngrok (if remote)
4. Viewer enters backend URL in the UI
5. Viewer can watch stream AND control their own Arduino

## Testing Your Setup

### Test Locally First:

1. **Start backend**: `npm start`
2. **Open index.html** in browser (or via Netlify)
3. **Enter backend URL**: `http://localhost:3000`
4. **Click "Connect"**
5. **Status should show**: "Connected" (green dot)
6. **Test LED controls**

### Test Remote Access:

1. **Start ngrok**: `ngrok http 3000`
2. **Copy ngrok URL**: `https://abc123.ngrok-free.app`
3. **Open Netlify site** on different device/network
4. **Enter ngrok URL** and connect
5. **Test LED controls**

## Troubleshooting

### "Failed to fetch" or CORS Error

**Solution**: Update CORS settings in server.js to allow your Netlify domain

### ngrok URL doesn't work

**Solution**:
- Make sure ngrok is running
- Try the HTTPS URL (not HTTP)
- Check that server.js is running

### "Arduino not connected" on Netlify

**Solution**:
- Verify backend is running locally
- Verify ngrok is exposing the backend
- Enter the correct URL in the UI
- Click "Connect" button

### Connection works locally but not on Netlify

**Solution**:
- You must use ngrok or port forwarding
- Cannot use `localhost` or `127.0.0.1` from Netlify
- Must use public IP or ngrok URL

## Security Considerations

⚠️ **Important**: When exposing your Arduino backend to the internet:

1. **Add authentication** (optional but recommended):
   ```javascript
   // In server.js
   const API_KEY = 'your-secret-key';

   app.use((req, res, next) => {
       if (req.headers['x-api-key'] !== API_KEY) {
           return res.status(401).json({ error: 'Unauthorized' });
       }
       next();
   });
   ```

2. **Use HTTPS** (ngrok provides this automatically)

3. **Restrict IP access** if possible

4. **Don't expose sensitive data** through Arduino

## Next Steps

1. ✅ Deploy index.html to Netlify
2. ✅ Run backend locally where Arduino is connected
3. ✅ Expose backend with ngrok (for testing)
4. ✅ Configure backend URL in the web interface
5. ✅ Test webcam streaming between two users
6. ✅ Test Arduino control from remote viewer

## Quick Start Checklist

- [ ] Push code to GitHub
- [ ] Deploy to Netlify
- [ ] Upload `arduino_dual_led_control.ino` to Arduino
- [ ] Configure Arduino port in `server.js`
- [ ] Run `npm install` and `npm start`
- [ ] Install and run ngrok
- [ ] Copy ngrok URL
- [ ] Open Netlify site
- [ ] Enter ngrok URL and connect
- [ ] Test LED controls
- [ ] Test webcam streaming with another device
