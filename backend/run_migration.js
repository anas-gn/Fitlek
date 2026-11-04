import fs from 'node:fs';
import mysql from 'mysql2/promise';
import 'dotenv/config';
async function run() {
 let conn;
 try {
  const sql=fs.readFileSync('migrations/2026_categories_favorites.sql','utf8');
  conn=await mysql.createConnection({host:process.env.DB_HOST,user:process.env.DB_USER,password:process.env.DB_PASSWORD,database:process.env.DB_NAME,port:Number(process.env.DB_PORT||3306),multipleStatements:true});
  await conn.query(sql);console.log('Migration executed successfully');
 } catch(error){console.error('Migration failed:',error.code||'Database unavailable');process.exitCode=1;}
 finally{if(conn)await conn.end();}
}
run();
