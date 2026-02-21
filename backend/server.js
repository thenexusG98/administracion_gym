import app from './src/app.js';
import config from './src/config/index.js';
import prisma from './src/config/database.js';

const startServer = async () => {
  try {
    // Test database connection
    await prisma.$connect();
    console.log('✅ Conexión a base de datos establecida');

    app.listen(config.port, () => {
      console.log(`🚀 Servidor corriendo en http://localhost:${config.port}`);
      console.log(`📋 Entorno: ${config.nodeEnv}`);
    });
  } catch (error) {
    console.error('❌ Error al iniciar el servidor:', error);
    await prisma.$disconnect();
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Cerrando servidor...');
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

startServer();
