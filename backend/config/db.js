import mysql from "mysql2/promise";
import dotenv from 'dotenv';
dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  port: Number(process.env.DB_PORT),
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

(async () => {
  try {
    const connection = await pool.getConnection();
    console.log("✅ Database connected");
    console.log("______________________");
    connection.release();
  } catch (error) {
    console.error("❌ Database connection failed:", error.message);
  }
})();

export default pool;