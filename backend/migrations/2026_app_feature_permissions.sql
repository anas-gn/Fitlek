-- Allow existing platform super-admins to manage app visibility only.
-- No role-management permission or new user/role assignment is granted.
START TRANSACTION;
INSERT IGNORE INTO permissions (code, description)
VALUES ('app.features.manage', 'Manage visibility of mobile app feature sections');
INSERT IGNORE INTO role_permissions (roleID, permissionID)
SELECT r.id, p.id FROM roles r JOIN permissions p ON p.code = 'app.features.manage'
WHERE r.code = 'super_admin' AND r.scopeType = 'platform';
COMMIT;
