module.exports = {
  apps: [{
    name: 'freyone-api',
    script: './dist/index.js',
    node_args: '--env-file=/home/deploy/freyone/apps/api/.env',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '500M',
    env_production: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: '/var/log/freyone/error.log',
    out_file: '/var/log/freyone/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss'
  }]
}
