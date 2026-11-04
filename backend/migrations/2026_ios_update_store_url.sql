-- Apple ID 6809422212 comes from the user's App Store Connect app record.
-- The public listing becomes usable after the app is released.
-- Latest/minimum versions remain unchanged. Apply when deploying this fix.
START TRANSACTION;
UPDATE app_versions
SET store_url = 'https://apps.apple.com/app/id6809422212'
WHERE platform = 'ios'
  AND store_url = 'https://apps.apple.com/app/idYOUR_APP_ID';
COMMIT;
