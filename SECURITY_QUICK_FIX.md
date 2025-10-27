# Security Quick Fix Guide
## Immediate Actions to Secure Your Arduino Control App

This guide provides copy-paste solutions for the most critical vulnerabilities.

---

## 1. Add API Key Authentication (CRITICAL)

### Step 1: Install required dependencies
```bash
npm install dotenv
```

### Step 2: Create `.env` file
```bash
# .env (add this to .gitignore!)
ARDUINO_API_KEY=your-secret-key-here-min-32-characters-long
ARDUINO_PORT=/dev/cu.usbmodem14101
NODE_ENV=production
```

### Step 3: Update server.js (Add at the top)
```javascript
// At the very top of server.js
require('dotenv').config();
const express = require('express');
const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Generate API key if not set
const API_KEY = process.env.ARDUINO_API_KEY ||
    (() => {
        console.error('⚠️  WARNING: No API_KEY set in environment!');
        console.error('⚠️  Using temporary key. Set ARDUINO_API_KEY in .env file!');
        return require('crypto').randomBytes(32).toString('hex');
    })();

// Authentication middleware
const authenticateAPIKey = (req, res, next) => {
    const providedKey = req.headers['x-api-key'];

    if (!providedKey || providedKey !== API_KEY) {
        console.warn('⚠️  Unauthorized access attempt from:', req.ip);
        return res.status(401).json({
            success: false,
            error: 'Unauthorized: Invalid or missing API key'
        });
    }
    next();
};

// Restricted CORS configuration
const ALLOWED_ORIGINS = [
    'https://your-netlify-site.netlify.app',  // CHANGE THIS!
    process.env.NODE_ENV === 'development' ? 'http://localhost:8080' : null,
    process.env.NODE_ENV === 'development' ? 'http://127.0.0.1:8080' : null,
].filter(Boolean);

const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (Postman, curl, etc.)
        if (!origin) return callback(null, true);

        if (ALLOWED_ORIGINS.includes(origin)) {
            callback(null, true);
        } else {
            console.warn('⚠️  Blocked CORS request from:', origin);
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'X-API-Key']
};

app.use(cors(corsOptions));
app.use(express.json());

// Apply authentication to all Arduino endpoints
app.use('/arduino', authenticateAPIKey);

// ... rest of your server.js code ...
```

### Step 4: Update frontend (index.html)
```javascript
// Add this near the top of the <script> section in index.html
let API_KEY = localStorage.getItem('arduinoApiKey') || '';

// Add API key input to the arduino-control section
// Insert after line 110 in index.html:
/*
<div style="margin: 15px 0; padding: 10px; background: #fff3cd; border-radius: 4px;">
    <label for="apiKeyInput" style="display: block; margin-bottom: 5px; font-weight: bold;">API Key (Required):</label>
    <input type="password" id="apiKeyInput" placeholder="Enter your API key"
           style="width: 70%; padding: 8px; margin-right: 5px;">
    <button id="saveApiKeyBtn" style="padding: 8px 15px;">Save Key</button>
</div>
*/

// Add event listener (after line 195)
document.getElementById('saveApiKeyBtn').addEventListener('click', saveApiKey);

function saveApiKey() {
    const key = document.getElementById('apiKeyInput').value.trim();
    if (!key) {
        alert('Please enter an API key');
        return;
    }
    API_KEY = key;
    localStorage.setItem('arduinoApiKey', key);
    alert('API key saved! Try connecting now.');
}

// Load saved API key
document.getElementById('apiKeyInput').value = API_KEY;

// Update all fetch calls to include API key
// Modify the controlLED function (line 269):
async function controlLED(endpoint) {
    if (!isArduinoConnected) {
        alert('Arduino is not connected!');
        return;
    }

    if (!API_KEY) {
        alert('Please enter your API key first!');
        return;
    }

    try {
        const response = await fetch(`${BACKEND_URL}/arduino/${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-API-Key': API_KEY  // ADD THIS LINE
            }
        });

        const data = await response.json();

        if (response.status === 401) {
            alert('Invalid API key! Please check your credentials.');
            return;
        }

        if (data.success) {
            console.log(`LED control success: ${endpoint}`);
        } else {
            alert('Failed to control LED: ' + data.error);
        }
    } catch (error) {
        console.error('Error communicating with Arduino:', error);
        alert('Failed to communicate with Arduino server.');
    }
}

// Update checkArduinoConnection (line 229)
async function checkArduinoConnection() {
    try {
        const response = await fetch(`${BACKEND_URL}/arduino/status`, {
            headers: {
                'X-API-Key': API_KEY  // ADD THIS LINE
            }
        });
        const data = await response.json();
        isArduinoConnected = data.connected;
        updateArduinoStatus(data.connected);
    } catch (error) {
        console.error('Failed to check Arduino status:', error);
        isArduinoConnected = false;
        updateArduinoStatus(false);
    }
}
```

---

## 2. Add Rate Limiting (CRITICAL)

### Step 1: Install dependency
```bash
npm install express-rate-limit
```

### Step 2: Add to server.js (after CORS setup)
```javascript
const rateLimit = require('express-rate-limit');

// Rate limiter for Arduino commands
const arduinoLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 30, // Maximum 30 commands per minute
    message: {
        success: false,
        error: 'Too many requests. Please wait before sending more commands.'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// Apply rate limiting to Arduino endpoints
app.use('/arduino', arduinoLimiter);
```

---

## 3. Add Command Validation (HIGH PRIORITY)

### Add to server.js (before endpoint definitions)
```javascript
// Command validation
const VALID_COMMANDS = {
    'T': 'T\n',
    '1': '1\n',
    '0': '0\n',
    'R1': 'R1\n',
    'R0': 'R0\n',
    'B1': 'B1\n',
    'B0': 'B0\n',
    'ALL_ON': 'ALL_ON\n',
    'ALL_OFF': 'ALL_OFF\n',
    'ALTERNATE': 'ALTERNATE\n',
    'STOP': 'STOP\n'
};

function sendSafeCommand(command, callback) {
    if (!VALID_COMMANDS[command]) {
        return callback(new Error('Invalid command'));
    }

    if (!isConnected || !port) {
        return callback(new Error('Arduino not connected'));
    }

    port.write(VALID_COMMANDS[command], callback);
}

// Replace all port.write() calls with sendSafeCommand()
// Example for /arduino/red/on endpoint:
app.post('/arduino/red/on', (req, res) => {
    sendSafeCommand('R1', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('🔴 Red LED turned ON');
        res.json({ success: true, message: 'Red LED turned ON' });
    });
});

// Repeat for all other endpoints...
```

---

## 4. Secure Arduino Port Configuration

### Update server.js
```javascript
// Use environment variable for port
const ARDUINO_PORT = process.env.ARDUINO_PORT || '/dev/ttyUSB0';
const BAUD_RATE = parseInt(process.env.BAUD_RATE || '9600', 10);

console.log(`📡 Connecting to Arduino on ${ARDUINO_PORT} at ${BAUD_RATE} baud`);
```

---

## 5. Add Security Logging

### Step 1: Install dependencies
```bash
npm install winston morgan
```

### Step 2: Add to server.js
```javascript
const winston = require('winston');
const morgan = require('morgan');

// Setup logger
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'security.log', level: 'warn' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ],
});

// HTTP request logging
app.use(morgan('combined', {
    stream: {
        write: (message) => logger.info(message.trim())
    }
}));

// Log security events
function logSecurityEvent(event, details) {
    logger.warn({
        event,
        timestamp: new Date().toISOString(),
        ...details
    });
}

// Update authentication middleware to log failures
const authenticateAPIKey = (req, res, next) => {
    const providedKey = req.headers['x-api-key'];

    if (!providedKey || providedKey !== API_KEY) {
        logSecurityEvent('auth_failed', {
            ip: req.ip,
            path: req.path,
            userAgent: req.get('user-agent')
        });
        return res.status(401).json({
            success: false,
            error: 'Unauthorized: Invalid or missing API key'
        });
    }
    next();
};
```

---

## 6. Update CSP Headers in netlify.toml

Replace the Content-Security-Policy line:
```toml
Content-Security-Policy = """
  default-src 'self';
  script-src 'self' 'unsafe-inline' https://unpkg.com;
  connect-src 'self'
    https://0.peerjs.com
    wss://0.peerjs.com
    https://*.peerjs.com
    wss://*.peerjs.com
    http://localhost:3000
    https://*.ngrok.io
    https://*.ngrok-free.app;
  style-src 'self' 'unsafe-inline';
  media-src 'self' blob: mediastream:;
  img-src 'self' data: blob:;
  worker-src 'self' blob:;
  frame-ancestors 'self';
  form-action 'self';
  base-uri 'self';
"""
```

---

## 7. Add .gitignore

Create `.gitignore` file:
```
# Environment variables
.env
.env.local
.env.production

# Logs
*.log
npm-debug.log*

# Dependencies
node_modules/

# Security
*.pem
*.key
certs/

# OS
.DS_Store
Thumbs.db
```

---

## 8. Secure ngrok Usage

### Option A: Add Basic Auth to ngrok
```bash
ngrok http 3000 --auth="your-username:your-password"
```

### Option B: Use ngrok config file
```yaml
# ~/.ngrok2/ngrok.yml
authtoken: your_auth_token_here
tunnels:
  arduino:
    proto: http
    addr: 3000
    auth: "username:password"
    bind_tls: true

# Then run:
# ngrok start arduino
```

---

## 9. Frontend URL Validation

Add this validation function to index.html:
```javascript
function validateBackendUrl(url) {
    try {
        const parsed = new URL(url);

        // Only allow specific protocols
        if (!['http:', 'https:'].includes(parsed.protocol)) {
            return false;
        }

        // Whitelist specific hosts
        const ALLOWED_PATTERNS = [
            /^localhost$/,
            /^127\.0\.0\.1$/,
            /^192\.168\.\d{1,3}\.\d{1,3}$/,  // Local network
            /^.*\.ngrok\.io$/,
            /^.*\.ngrok-free\.app$/
        ];

        const hostname = parsed.hostname;
        const isAllowed = ALLOWED_PATTERNS.some(pattern =>
            pattern.test(hostname)
        );

        if (!isAllowed) {
            console.error('Hostname not allowed:', hostname);
            return false;
        }

        return true;
    } catch (e) {
        return false;
    }
}

// Update connectToBackend function
function connectToBackend() {
    const inputUrl = document.getElementById('backendUrlInput').value.trim();
    if (!inputUrl) {
        alert('Please enter a backend URL');
        return;
    }

    if (!validateBackendUrl(inputUrl)) {
        alert('Invalid backend URL. Only localhost, local network IPs, and ngrok URLs are allowed.');
        return;
    }

    // ... rest of function
}
```

---

## 10. Testing Your Fixes

### Test Authentication
```bash
# Should fail (no API key)
curl -X POST http://localhost:3000/arduino/toggle

# Should succeed (with API key)
curl -X POST http://localhost:3000/arduino/toggle \
  -H "X-API-Key: your-secret-key-here"
```

### Test Rate Limiting
```bash
# Run this 31 times quickly - last one should be rate limited
for i in {1..31}; do
  curl -X POST http://localhost:3000/arduino/toggle \
    -H "X-API-Key: your-key"
done
```

### Test CORS
```bash
# Should be blocked (wrong origin)
curl -X POST http://localhost:3000/arduino/toggle \
  -H "X-API-Key: your-key" \
  -H "Origin: https://evil.com"
```

---

## Complete Updated package.json

```json
{
  "name": "stream-arduino-control",
  "version": "1.0.0",
  "description": "Secure webcam streaming with Arduino control",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "NODE_ENV=development node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "serialport": "^12.0.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express-rate-limit": "^7.1.5",
    "winston": "^3.11.0",
    "morgan": "^1.10.0"
  }
}
```

---

## Deployment Checklist

Before deploying to production:

- [ ] Set strong API key in .env (min 32 characters)
- [ ] Update ALLOWED_ORIGINS in server.js with your Netlify URL
- [ ] Add .env to .gitignore
- [ ] Test all endpoints with authentication
- [ ] Verify rate limiting works
- [ ] Configure ngrok with authentication
- [ ] Update CSP headers in netlify.toml
- [ ] Test CORS restrictions
- [ ] Review security logs
- [ ] Change default Arduino port in .env

---

## Emergency Procedures

### If API Key Compromised
1. Stop the server immediately
2. Generate new API key:
   ```bash
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```
3. Update .env file
4. Restart server
5. Update key in frontend

### If System Compromised
1. Shut down server
2. Disconnect Arduino physically
3. Review security.log and error.log
4. Rotate all credentials
5. Audit code changes
6. Restore from known-good backup

---

## Quick Reference

### Generate Strong API Key
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Start Server Securely
```bash
# Set environment variables
export ARDUINO_API_KEY="your-long-random-key-here"
export ARDUINO_PORT="/dev/cu.usbmodem14101"
export NODE_ENV="production"

# Start server
npm start
```

### View Security Logs
```bash
tail -f security.log
```

---

## Support Resources

- Full audit report: `SECURITY_AUDIT_REPORT.md`
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Express Security: https://expressjs.com/en/advanced/best-practice-security.html
- Node.js Security: https://nodejs.org/en/docs/guides/security/

---

**Remember:** Security is not a one-time task. Regularly review logs, update dependencies, and reassess your threat model.
