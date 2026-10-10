// Explicit test-process preload. Production startup never imports this file.
import admin from 'firebase-admin';
if (!admin.apps.length) admin.initializeApp({projectId:'sirvya-ci-fixtures'});
