const loadtest = require('loadtest');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

const argv = yargs(hideBin(process.argv))
  .option('endpoint', {
    alias: 'e',
    description: 'Endpoint to test',
    type: 'string',
    choices: ['cpu-intensive', 'heavy-load', 'health'],
    default: 'cpu-intensive'
  })
  .option('concurrency', {
    alias: 'c',
    description: 'Number of concurrent clients',
    type: 'number',
    default: 10
  })
  .option('requests', {
    alias: 'n',
    description: 'Number of requests to make',
    type: 'number',
    default: 100
  })
  .option('rps', {
    alias: 'r',
    description: 'Requests per second',
    type: 'number',
    default: 5
  })
  .option('param', {
    alias: 'p',
    description: 'Parameter value (iterations for cpu-intensive, limit for heavy-load)',
    type: 'number',
    default: 40
  })
  .option('host', {
    alias: 'h',
    description: 'Host to test against',
    type: 'string',
    default: 'localhost'
  })
  .option('port', {
    alias: 'P',
    description: 'Port to test against',
    type: 'number',
    default: 30008
  })
  .help()
  .alias('help', 'H')
  .argv;

const getParamName = (endpoint) => {
  switch (endpoint) {
    case 'cpu-intensive':
      return 'iterations';
    case 'heavy-load':
      return 'limit';
    default:
      return null;
  }
};

const paramName = getParamName(argv.endpoint);
const url = `http://${argv.host}:${argv.port}/${argv.endpoint}${paramName ? `?${paramName}=${argv.param}` : ''}`;
// const url = `http://localhost:30008/${argv.endpoint}`;

console.log(`Starting load test on ${url}`);
console.log(`Concurrency: ${argv.concurrency}, Requests: ${argv.requests}, RPS: ${argv.rps}`);

const options = {
  url: url,
  concurrency: argv.concurrency,
  maxRequests: argv.requests,
  requestsPerSecond: argv.rps,
  method: 'GET',
  contentType: 'application/json',
  // timeout: 120000,
  statusCallback: (error, result, latency) => {
    if (error) {
      console.log(`Request error: ${error.message || error}`);
    } else {
      console.log(`Request completed - Status: ${result.statusCode}, Latency: ${latency}ms`);
    }
  }
};

loadtest.loadTest(options, (error, result) => {
  if (error) {
    console.error('Load test error:', error);
    return;
  }
  
  console.log('\nLoad Test Results:');
  console.log('------------------');
  console.log(`Total Requests: ${result.totalRequests}`);
  console.log(`Total Errors: ${result.totalErrors}`);
  console.log(`RPS: ${result.rps.toFixed(2)}`);
  console.log(`Mean Latency: ${result.meanLatencyMs.toFixed(2)} ms`);
  console.log(`Max Latency: ${result.maxLatencyMs.toFixed(2)} ms`);
  console.log(`Percentiles:`);
  console.log(`  50%: ${result.percentiles['50'].toFixed(2)} ms`);
  console.log(`  90%: ${result.percentiles['90'].toFixed(2)} ms`);
  console.log(`  95%: ${result.percentiles['95'].toFixed(2)} ms`);
  console.log(`  99%: ${result.percentiles['99'].toFixed(2)} ms`);
});
