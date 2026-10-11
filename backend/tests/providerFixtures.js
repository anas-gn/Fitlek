// Explicit test-process preload. Production startup never imports this file.
import {getApps,initializeApp} from 'firebase-admin/app';
if (!getApps().length) initializeApp({projectId:'sirvya-ci-fixtures'});
