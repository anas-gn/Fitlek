import mysql from "mysql2/promise";
import dotenv from "dotenv";

dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || "51.170.143.251",
  user: process.env.DB_USER || "sirvya",
  password: process.env.DB_PASSWORD || "Sirvya@Backend2026",
  database: process.env.DB_NAME || "sirvya",
  port: process.env.DB_PORT ? Number(process.env.DB_PORT) : 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
});

// Test connection non-blockingly
pool.query('SELECT 1').then(() => {
  console.log("✅ Database connected (51.170.143.251)");
  console.log("______________________");
}).catch((error) => {
  console.error("❌ Database connection failed:", error.message);
});

export default pool;