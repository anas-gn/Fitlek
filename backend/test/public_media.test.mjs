import test from 'node:test';
import assert from 'node:assert/strict';
import {publicMediaUrl,normalizePublicMedia,publicMediaResponses} from '../services/publicMedia.js';

test('legacy local and IP upload URLs use the public HTTPS origin',()=>{
  for(const origin of ['http://127.0.0.1:3000','http://51.170.143.251','http://api.sirvya.com'])
    assert.equal(publicMediaUrl(origin+'/uploads/photo.jpg?v=2','https://api.sirvya.com/api'),'https://api.sirvya.com/uploads/photo.jpg?v=2');
  for(const value of ['https://res.cloudinary.com/photo.jpg','http://127.0.0.1:3000/api/invite/abc','/uploads/a.jpg',null])
    assert.equal(publicMediaUrl(value),value);
  assert.equal(publicMediaUrl('http://51.170.143.251/uploads/a.jpg','http://localhost'), 'http://51.170.143.251/uploads/a.jpg');
});
test('JSON responses normalize nested media without changing the source object, dates or nulls',()=>{
  const date=new Date();const input={users:[{avatarUrl:'http://51.170.143.251/uploads/a.jpg'}],date,empty:null,body:'http://51.170.143.251/uploads/a.jpg'};
  const output=normalizePublicMedia(input);
  assert.equal(output.users[0].avatarUrl,'https://api.sirvya.com/uploads/a.jpg');
  assert.equal(input.users[0].avatarUrl,'http://51.170.143.251/uploads/a.jpg');
  assert.equal(output.date,date);assert.equal(output.empty,null);
  assert.equal(output.body,input.body);
  let sent;const response={json(value){sent=value;return this;}};
  publicMediaResponses({},response,()=>{});
  assert.equal(response.json(input),response);assert.deepEqual(sent,output);
});
