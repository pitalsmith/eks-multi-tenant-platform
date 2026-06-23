const http = require('http');

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    status: "success",
    message: "Internal Developer Platform API is fully operational!",
    timestamp: new Date().toISOString(),
    environment: "production-eks"
  }));
});

const PORT = 8080;
server.listen(PORT, () => {
  console.log(`Backend API running smoothly on port ${PORT}`);
});
