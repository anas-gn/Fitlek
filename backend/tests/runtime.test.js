import test from 'node:test';
import assert from 'node:assert/strict';
import {runtimeConfig,publicOrigin} from '../config/runtime.js';
const dev={DB_HOST:'localhost',DB_USER:'fixture',DB_NAME:'fixture',JWT_SECRET:'fixture-only'};
test('production requires explicit secrets, web origins, HTTPS and bounded proxy trust',()=>{
  assert.throws(()=>runtimeConfig({}),/Missing/);
  assert.equal(runtimeConfig(dev).trustProxy,0);
  assert.throws(()=>runtimeConfig({...dev,NODE_ENV:'production'}),/JWT_SECRET/);
  const prod={...dev,NODE_ENV:'production',JWT_SECRET:'z'.repeat(64),CORS_ORIGINS:'https://app.example.invalid',PUBLIC_API_ORIGIN:'https://api.example.invalid'};
  assert.deepEqual(runtimeConfig(prod).origins,['https://app.example.invalid']);
  for(const change of [{CORS_ORIGINS:''},{CORS_ORIGINS:'*'},{CORS_ORIGINS:'https://user:pass@app.example.invalid'},{PUBLIC_API_ORIGIN:'https://api.example.invalid/api'},{PUBLIC_API_ORIGIN:'https://api.example.invalid?host=bad'},{PUBLIC_API_ORIGIN:'http://api.example.invalid'},{TRUST_PROXY_HOPS:'99'}])assert.throws(()=>runtimeConfig({...prod,...change}));
});
test('media uses the configured HTTPS origin instead of request host',()=>{
  const original=process.env.PUBLIC_API_ORIGIN;
  try{process.env.PUBLIC_API_ORIGIN='https://api.example.invalid/';assert.equal(publicOrigin({protocol:'http',get:()=> 'untrusted.example'}),'https://api.example.invalid');}
  finally{if(original===undefined)delete process.env.PUBLIC_API_ORIGIN;else process.env.PUBLIC_API_ORIGIN=original;}
});
