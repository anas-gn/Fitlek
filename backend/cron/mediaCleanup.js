import cron from 'node-cron';
import fs from 'fs';
import path from 'path';
import db from '../config/db.js';

// Run every day at 3:00 AM
cron.schedule('0 3 * * *', async () => {
  console.log('🧹 Running chat media cleanup job...');
  let deletedCount = 0;
  
  try {
    while (true) {
      // Find expired media that haven't been processed yet
      // Batch size of 100 to prevent locking the database
      const [rows] = await db.query(
        `SELECT id, mediaUrl FROM messages 
         WHERE mediaType IN ('image', 'audio') 
           AND mediaExpired = 0 
           AND createdAt < NOW() - INTERVAL 7 DAY 
         LIMIT 100`
      );

      if (rows.length === 0) {
        break; // No more records to process
      }

      for (const row of rows) {
        if (row.mediaUrl) {
          try {
            // Extract the filename from the URL
            const urlParts = new URL(row.mediaUrl);
            const filename = path.basename(urlParts.pathname);
            const filepath = path.join(process.cwd(), 'uploads', 'chat_media', filename);

            if (fs.existsSync(filepath)) {
              fs.unlinkSync(filepath);
            }
          } catch (fileErr) {
            console.error(`❌ Failed to delete file for message ${row.id}:`, fileErr.message);
          }
        }
      }

      // Update the database to mark them as expired. We DO NOT set mediaUrl to NULL
      // so the mobile app can still attempt to load it from its local cache.
      const ids = rows.map(r => r.id);
      await db.query(
        `UPDATE messages SET mediaExpired = 1 WHERE id IN (?)`,
        [ids]
      );

      deletedCount += rows.length;
    }
    
    if (deletedCount > 0) {
      console.log(`✅ Chat media cleanup finished. Expired ${deletedCount} media files.`);
    } else {
      console.log('✅ Chat media cleanup finished. No expired media found.');
    }
  } catch (err) {
    console.error('❌ Chat media cleanup job failed:', err.message);
  }
});

export const startMediaCleanupJob = () => {
  console.log('🕒 Media cleanup cron job scheduled.');
};
