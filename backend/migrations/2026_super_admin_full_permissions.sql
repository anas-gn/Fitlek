-- Owner authorized full app control for the existing platform super_admin role.
-- Register every permission required by the current Web_admin API, then grant
-- every catalogued permission to super_admin. Other roles are untouched.
START TRANSACTION;
INSERT IGNORE INTO permissions (code, description) VALUES
('admin.context.read', 'Admin context read'),
('app.features.manage', 'Manage visibility of mobile app feature sections'),
('audit.read', 'Audit read'),
('booking.read', 'Booking read'),
('booking.write', 'Manage reservations'),
('permission.read', 'Permission read'),
('role.assign', 'Role assign'),
('role.manage', 'Manage platform roles and permissions'),
('role.read', 'Role read'),
('user.deletion.request', 'User deletion request'),
('user.manage', 'Manage platform users and organizations'),
('user.read', 'User read'),
('user.suspend', 'User suspend'),
('user.verify', 'User verify');
INSERT IGNORE INTO role_permissions (roleID, permissionID)
SELECT r.id, p.id FROM roles r CROSS JOIN permissions p
WHERE r.code = 'super_admin' AND r.scopeType = 'platform';
COMMIT;
