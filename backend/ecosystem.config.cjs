module.exports = {
  apps: [
    {
      name: 'sirvya-backend-live',
      script: './index.js',
      instances: 1,
      exec_mode: 'fork',
      env_production: {
        NODE_ENV: 'production',
      },
    },
  ],
};