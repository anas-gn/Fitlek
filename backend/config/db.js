import mysql from "mysql2/promise";
import dotenv from "dotenv";

dotenv.config();

const pool = mysql.createPool({
   host: "blok55lz6chdyrkje20u-mysql.services.clever-cloud.com",
  user: "us2pff5iyntvd12p",
  password: "9HzSYURU36QjPKSDEyLv",
  database: "blok55lz6chdyrkje20u",
  port: "3306",
 waitForConnections: true,
  connectionLimit: 3,       // reste sous la limite de 5 imposée par l'hébergeur
  maxIdle: 3,               // ferme les connexions inactives
  idleTimeout: 60000,       // 60s avant de fermer une connexion inactive
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
});

// Test connection (optional)
try {
  const connection = await pool.getConnection();
  console.log("✅ Database connected");
  console.log("______________________");
  connection.release();
} catch (error) {
  console.error("❌ Database connection failed:", error.message);
}

export default pool;   // <-- this is the key change