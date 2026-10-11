const express = require('express');
const app = express();
const PORT = 4500;

app.get('/', (req, res) => {
  res.json({
    message: "Hello from Live Hot-Reloading Docker Container!",
    editCount: 1,
    time: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Hot-reload server running on port ${PORT}`);
});
