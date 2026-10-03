import db from '../config/db.js';
import { ensureGoogleAuthSchema } from '../config/googleAuthSchema.js';

try {
  await ensureGoogleAuthSchema(db);
  console.log('SIRVYA Google authentication schema is ready.');
} finally {
  await db.end();
}
