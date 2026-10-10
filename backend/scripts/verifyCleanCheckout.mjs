import dotenv from 'dotenv';
import mysql from 'mysql2/promise';
import {spawn} from 'node:child_process';
import {readdir} from 'node:fs/promises';
dotenv.config({path:new URL('../.env',import.meta.url),quiet:true});
if(!['localhost','127.0.0.1','::1'].includes(process.env.DB_HOST))throw new Error('Clean-checkout verification requires local MySQL');
const database=`sirvya_ci_${Date.now()}`;
const conn=await mysql.createConnection({host:process.env.DB_HOST,user:process.env.DB_USER,password:process.env.DB_PASSWORD,port:Number(process.env.DB_PORT??3306)});
try{
  const [[existing]]=await conn.query('SELECT COUNT(*) AS n FROM information_schema.SCHEMATA WHERE SCHEMA_NAME=?',[database]);
  if(existing.n)throw new Error('Refusing to reuse an existing schema');
  await conn.query(`CREATE DATABASE \`${database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
}finally{await conn.end();}
const env={...process.env,CI:'true',DB_NAME:database,WORKOUT_TEST_MYSQL:'1',APP_TEST_MYSQL:'1',AUTH_TEST_MYSQL:'1'};
const run=args=>new Promise((resolve,reject)=>{
  const child=spawn(process.execPath,args,{cwd:new URL('../',import.meta.url),env,stdio:'inherit',windowsHide:true});
  child.on('error',reject);child.on('exit',code=>code===0?resolve():reject(new Error(`Clean-checkout command failed (${code})`)));
});
console.log(`Verifying an isolated new schema: ${database}`);
await run(['scripts/bootstrapCI.mjs']);
const tests=(await readdir(new URL('../tests/',import.meta.url))).filter(name=>name.endsWith('.test.js')).map(name=>'tests/'+name);
await run(['--import','./tests/providerFixtures.js','--test','--test-concurrency=1',...tests]);
console.log('Clean-checkout integration checks passed. Disposable schema retained for inspection.');
