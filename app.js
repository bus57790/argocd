const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/health', (req, res) => res.json({ status: 'UP', timestamp: new Date() }));
app.get('/', (req, res) => res.send('Microservice v1.0.0 is running!'));

app.listen(PORT, () => console.log(`Server on port ${PORT}`));
