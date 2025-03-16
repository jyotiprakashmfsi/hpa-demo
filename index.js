const express = require('express');
const app = express();

app.get('/', (req, res) => {
    res.send('Hello World!');
});

app.get('/cpu-intensive', (req, res) => {
    const iterations = req.query.iterations || 40;
    const result = fibonacci(parseInt(iterations));
    res.json({ 
        result: result,
        message: `Calculated Fibonacci(${iterations})`,
        pod: process.env.HOSTNAME || 'unknown'
    });
});

app.get('/heavy-load', (req, res) => {
    const limit = req.query.limit || 100000;
    const primes = findPrimes(parseInt(limit));
    res.json({ 
        count: primes.length,
        message: `Found ${primes.length} prime numbers up to ${limit}`,
        pod: process.env.HOSTNAME || 'unknown'
    });
});

app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok',
        pod: process.env.HOSTNAME || 'unknown',
        timestamp: new Date().toISOString()
    });
});

app.get('/metrics', (req, res) => {
    const memoryUsage = process.memoryUsage();
    res.json({
        pod: process.env.HOSTNAME || 'unknown',
        memoryUsage: {
            rss: `${Math.round(memoryUsage.rss / 1024 / 1024)} MB`,
            heapTotal: `${Math.round(memoryUsage.heapTotal / 1024 / 1024)} MB`,
            heapUsed: `${Math.round(memoryUsage.heapUsed / 1024 / 1024)} MB`
        },
        uptime: process.uptime()
    });
});

function fibonacci(n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

function findPrimes(limit) {
    const primes = [];
    for (let num = 2; num <= limit; num++) {
        let isPrime = true;
        for (let i = 2; i <= Math.sqrt(num); i++) {
            if (num % i === 0) {
                isPrime = false;
                break;
            }
        }
        if (isPrime) {
            primes.push(num);
        }
    }
    return primes;
}

app.listen(3000, () => {
    console.log('Server is running on port 3000');
});