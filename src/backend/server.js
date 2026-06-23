const http = require('http');

const server = http.createServer((req, res) => {
    // Set JSON response headers
    res.writeHead(200, { 'Content-Type': 'application/json' });

    // Handle our /api endpoint route mapping
    if (req.url === '/api' || req.url === '/api/') {
        res.end(JSON.stringify({
            status: "success",
            message: "v3 via GitHub Actions!",
            environment: "production-eks",
            platform: "ArgoCD GitOps Engine"
        }));
    } else {
        res.end(JSON.stringify({
            status: "success",
            message: "Internal Developer Platform Runtime Mesh Active"
        }));
    }
});

const PORT = 8080;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Application successfully listening on port ${PORT}`);
});