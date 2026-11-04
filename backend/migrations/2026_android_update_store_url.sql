-- Correct the legacy Android update link for the confirmed Sirvya package.
-- Latest/minimum versions remain unchanged. Apply when deploying this fix.
START TRANSACTION;
UPDATE app_versions
SET store_url = 'https://play.google.com/store/apps/details?id=com.sirvya.app'
WHERE platform = 'android'
  AND store_url = 'https://play.google.com/store/apps/details?id=com.fitlek.app';
COMMIT;
