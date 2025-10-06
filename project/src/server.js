const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');
const { google } = require('googleapis');
require('dotenv').config({ path: __dirname + '/../.env' });
const Stripe = require('stripe');
const connectDB = require('./config/db');
const errorHandler = require('./middleware/errorHandler');
const notFoundHandler = require('./middleware/notFoundHandler');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;
app.use(express.json());
app.use(helmet());
app.use(cors());
app.use('/api', routes);

// Serve static files
app.use(express.static(path.join(__dirname, '../public')));

// Admin portal is now served by Flutter Web at http://localhost:8080
// All HTML admin portals have been removed and replaced with Flutter Web

// Serve basic admin portal (no login, direct access)
app.get('/admin-basic', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/admin-basic.html'));
});

const zoomRoutes = require('./routes/zoom');
const locationRoutes = require('./routes/location');
// Initialize Stripe with secret key
const stripe = process.env.STRIPE_SECRET_KEY ? new Stripe(process.env.STRIPE_SECRET_KEY) : null;

const CREDENTIALS = require('./config/secret.json');
const SCOPES = ['https://www.googleapis.com/auth/calendar.events'];
const TOKEN_PATH = path.join(__dirname, 'config', 'token.json');

const oAuth2Client = new google.auth.OAuth2(
  CREDENTIALS.web.client_id,
  CREDENTIALS.web.client_secret,
  'https://mindease-backend-production.up.railway.app/api/google-meet/oauth2callback'
);

let tokens = null;

try {
  if (fs.existsSync(TOKEN_PATH)) {
    const tokenData = fs.readFileSync(TOKEN_PATH, 'utf-8');
    tokens = JSON.parse(tokenData);
    oAuth2Client.setCredentials(tokens);
    console.log('Loaded saved Google OAuth tokens');
  } else {
    console.log('No saved token found, please authenticate via /api/google-meet/auth');
  }
} catch (err) {
  console.error('Error loading tokens:', err);
}


app.use((req, res, next) => {
  if (tokens) {
    oAuth2Client.setCredentials(tokens);
  }
  next();
});

app.use((req, res, next) => {
  const xForwardedFor = req.headers['x-forwarded-for'];
  if (xForwardedFor) {
    req.clientIp = xForwardedFor.split(',')[0].trim();
  } else {
    req.clientIp = req.connection.remoteAddress || req.socket.remoteAddress || null;
  }
  next();
});

app.get('/api/location/ip-geo', async (req, res) => {
  try {
    let ip = req.query.ip || req.clientIp;

    if (!ip) {
      return res.status(400).json({ error: 'Cannot determine client IP address' });
    }

    if ((ip === '::1' || ip === '127.0.0.1') && !req.query.ip) {
      // Return a default location for  192.168.2.102 testing
      return res.json({
        ip: ' 192.168.2.102',
        country: 'United States',
        region: 'California',
        city: 'San Francisco',
        latitude: 37.7749,
        longitude: -122.4194,
        isp: 'Local Development',
      });
    }

    const response = await fetch(`http://ip-api.com/json/${ip}`);

    if (!response.ok) {
      return res.status(500).json({ error: 'Failed to fetch location from IP' });
    }

    const data = await response.json();

    if (data.status !== 'success') {
      return res.status(500).json({ error: 'IP geolocation failed' });
    }

    return res.json({
      ip,
      country: data.country,
      region: data.regionName,
      city: data.city,
      latitude: data.lat,
      longitude: data.lon,
      isp: data.isp,
    });
  } catch (error) {
    console.error('IP geolocation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update user location
app.post('/api/location/update', async (req, res) => {
  try {
    const { userId, latitude, longitude } = req.body;

    if (!userId || !latitude || !longitude) {
      return res.status(400).json({
        error: 'userId, latitude, and longitude are required'
      });
    }

    const { User } = require('./models');

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        location: {
          type: 'Point',
          coordinates: [longitude, latitude]
        }
      },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      message: 'Location updated successfully',
      location: {
        latitude,
        longitude
      }
    });
  } catch (error) {
    console.error('Location update error:', error);
    res.status(500).json({ error: 'Failed to update location' });
  }
});


app.use('/api/zoom', zoomRoutes);
app.use('/api/location', locationRoutes);

const googleMeetRouter = express.Router();

googleMeetRouter.get('/auth', (req, res) => {
  const authUrl = oAuth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
    prompt: 'consent',
  });
  res.redirect(authUrl);
});

googleMeetRouter.get('/oauth2callback', async (req, res) => {
  const code = req.query.code;
  try {
    const { tokens: newTokens } = await oAuth2Client.getToken(code);
    tokens = newTokens;
    oAuth2Client.setCredentials(tokens);

    fs.writeFileSync(TOKEN_PATH, JSON.stringify(tokens, null, 2));
    console.log('Tokens saved to', TOKEN_PATH);

    res.send('Google authentication successful! Tokens saved. You can now POST to /api/google-meet/create-meet');
  } catch (error) {
    console.error('OAuth callback error:', error);
    res.status(500).send('Authentication failed');
  }
});

googleMeetRouter.post('/create-meet', async (req, res) => {
  if (!tokens) {
    return res.status(500).send('Server not authenticated with Google. Please authenticate once via /api/google-meet/auth');
  }

  const calendar = google.calendar({ version: 'v3', auth: oAuth2Client });

  try {
    const event = {
      summary: 'Google Meet Meeting',
      start: {
        dateTime: new Date().toISOString(),
        timeZone: 'UTC',
      },
      end: {
        dateTime: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
        timeZone: 'UTC',
      },
      conferenceData: {
        createRequest: {
          requestId: `meet-${Date.now()}`,
          conferenceSolutionKey: { type: 'hangoutsMeet' },
        },
      },
    };

    const response = await calendar.events.insert({
      calendarId: 'primary',
      resource: event,
      conferenceDataVersion: 1,
    });

    const meetLink = response.data.conferenceData.entryPoints.find(
      (entry) => entry.entryPointType === 'video'
    ).uri;

    res.json({ meetLink });
  } catch (error) {
    console.error('Error creating meet:', error);
    res.status(500).send('Failed to create Google Meet link');
  }
});

app.use('/api/google-meet', googleMeetRouter);

// Stripe routes enabled
const stripeRouter = express.Router();

// Create a Stripe customer
stripeRouter.post('/createcustomer', async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({ error: 'Stripe not configured' });
    }

    const { email, name } = req.body;
    if (!email || !name) {
      return res.status(400).json({ error: 'Email and name are required' });
    }

    const customer = await stripe.customers.create({ email, name });

    res.json({ customer });
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ error: 'Failed to create customer' });
  }
});

// Create a setup intent for adding payment methods
stripeRouter.post('/create-setup-intent', async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({ error: 'Stripe not configured' });
    }

    const { customer_id } = req.body;

    const setupIntent = await stripe.setupIntents.create({
      customer: customer_id,
      payment_method_types: ['card'],
      usage: 'off_session',
    });

    res.json({
      clientSecret: setupIntent.client_secret,
      setupIntentId: setupIntent.id
    });
  } catch (error) {
    console.error('Create setup intent error:', error);
    res.status(500).json({ error: 'Failed to create setup intent' });
  }
});

// Create a payment intent
stripeRouter.post('/create-payment-intent', async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({ error: 'Stripe not configured' });
    }

    const { amount, currency = 'usd', customerId } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid amount is required' });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      customer: customerId,
      payment_method_types: ['card'],
    });

    res.json({ clientSecret: paymentIntent.client_secret, paymentIntentId: paymentIntent.id });
  } catch (error) {
    console.error('Create payment intent error:', error);
    res.status(500).json({ error: 'Failed to create payment intent' });
  }
});

app.use('/api/stripe', stripeRouter);
app.use(notFoundHandler);
app.use(errorHandler);

console.log('Starting server...');
console.log('Connecting to database...');

// Connect to database first
connectDB().then(() => {
  console.log('Database connection attempt completed');

  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV}`);
    console.log('Server started successfully!');
  });
}).catch(err => {
  console.error('Failed to start server:', err);
  process.exit(1);
});

module.exports = app;
