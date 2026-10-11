const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    status: 'online',
    service: 'node-express-api',
    hostname: os.hostname(),
    platform: process.platform,
    version: '1.0.0'
  });
});

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'healthy', uptime: process.uptime() });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Node Express API running on port ${PORT}`);
});
