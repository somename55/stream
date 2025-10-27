const express = require('express');
const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Enable CORS to allow your website to communicate with this server
app.use(cors());
app.use(express.json());

// Configure Arduino serial connection
// IMPORTANT: Change '/dev/ttyUSB0' to your Arduino's port
// On Windows: 'COM3', 'COM4', etc.
// On Mac: '/dev/cu.usbmodem14101' or similar
// On Linux: '/dev/ttyUSB0', '/dev/ttyACM0', etc.
const ARDUINO_PORT = '/dev/cu.usbmodem14101'; // CHANGE THIS!
const BAUD_RATE = 9600;

let port;
let parser;
let isConnected = false;

// Connect to Arduino
function connectArduino() {
    try {
        port = new SerialPort({
            path: ARDUINO_PORT,
            baudRate: BAUD_RATE,
        });

        parser = port.pipe(new ReadlineParser({ delimiter: '\r\n' }));

        port.on('open', () => {
            console.log('✅ Connected to Arduino on', ARDUINO_PORT);
            isConnected = true;
        });

        port.on('error', (err) => {
            console.error('❌ Serial port error:', err.message);
            isConnected = false;
        });

        port.on('close', () => {
            console.log('⚠️ Arduino connection closed');
            isConnected = false;
        });

        // Read data from Arduino (optional - for debugging)
        parser.on('data', (data) => {
            console.log('Arduino says:', data);
        });

    } catch (err) {
        console.error('❌ Failed to connect to Arduino:', err.message);
    }
}

// API endpoint to toggle LED
app.post('/arduino/toggle', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({
            success: false,
            error: 'Arduino not connected'
        });
    }

    // Send 'T' command to Arduino to toggle the LED
    port.write('T\n', (err) => {
        if (err) {
            console.error('Error writing to Arduino:', err.message);
            return res.status(500).json({
                success: false,
                error: err.message
            });
        }

        console.log('💡 Sent toggle command to Arduino');
        res.json({ success: true, message: 'LED toggled' });
    });
});

// API endpoint to turn LED ON
app.post('/arduino/on', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({
            success: false,
            error: 'Arduino not connected'
        });
    }

    port.write('1\n', (err) => {
        if (err) {
            return res.status(500).json({
                success: false,
                error: err.message
            });
        }

        console.log('💡 LED turned ON');
        res.json({ success: true, message: 'LED turned ON' });
    });
});

// API endpoint to turn LED OFF
app.post('/arduino/off', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({
            success: false,
            error: 'Arduino not connected'
        });
    }

    port.write('0\n', (err) => {
        if (err) {
            return res.status(500).json({
                success: false,
                error: err.message
            });
        }

        console.log('💡 LED turned OFF');
        res.json({ success: true, message: 'LED turned OFF' });
    });
});

// Check connection status
app.get('/arduino/status', (req, res) => {
    res.json({ connected: isConnected });
});

// ===== DUAL LED CONTROL ENDPOINTS =====

// Control Red LED (pin 13)
app.post('/arduino/red/on', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }
    port.write('R1\n', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('🔴 Red LED turned ON');
        res.json({ success: true, message: 'Red LED turned ON' });
    });
});

app.post('/arduino/red/off', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }
    port.write('R0\n', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('🔴 Red LED turned OFF');
        res.json({ success: true, message: 'Red LED turned OFF' });
    });
});

// Control Blue LED (pin 12)
app.post('/arduino/blue/on', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }
    port.write('B1\n', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('🔵 Blue LED turned ON');
        res.json({ success: true, message: 'Blue LED turned ON' });
    });
});

app.post('/arduino/blue/off', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }
    port.write('B0\n', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('🔵 Blue LED turned OFF');
        res.json({ success: true, message: 'Blue LED turned OFF' });
    });
});

// Control both LEDs
app.post('/arduino/all/on', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }
    port.write('ALL_ON\n', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('💡 Both LEDs turned ON');
        res.json({ success: true, message: 'Both LEDs turned ON' });
    });
});

app.post('/arduino/all/off', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }
    port.write('ALL_OFF\n', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('💡 Both LEDs turned OFF');
        res.json({ success: true, message: 'Both LEDs turned OFF' });
    });
});

// Alternate mode (like your original blinking code)
app.post('/arduino/alternate/start', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }
    port.write('ALTERNATE\n', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('🔄 Alternate mode started');
        res.json({ success: true, message: 'Alternate mode started' });
    });
});

app.post('/arduino/alternate/stop', (req, res) => {
    if (!isConnected || !port) {
        return res.status(503).json({ success: false, error: 'Arduino not connected' });
    }
    port.write('STOP\n', (err) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        console.log('🔄 Alternate mode stopped');
        res.json({ success: true, message: 'Alternate mode stopped' });
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log('📡 Attempting to connect to Arduino...');
    connectArduino();
});
