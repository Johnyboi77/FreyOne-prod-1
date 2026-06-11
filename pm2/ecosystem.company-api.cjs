module.exports = {
  apps: [{
    name: 'company-api',
    script: './dist/index.js',
    node_args: '--env-file=/home/deploy/company/api/.env',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '300M',
    env_production: {
      NODE_ENV: 'production',
      PORT: 3002
    },
    error_file: '/var/log/company/error.log',
    out_file: '/var/log/company/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss'
  }]
};
