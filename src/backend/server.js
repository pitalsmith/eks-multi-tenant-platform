res.end(JSON.stringify({
    status: "success",
    message: "Internal Developer Platform API is fully operational! v3 via GitHub Actions!",
    timestamp: new Date().toISOString(),
    environment: "production-eks"
  }));