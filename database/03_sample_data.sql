--------------------------------------------------------------------------------
-- 03_sample_data.sql
-- Sample roles, users, tree menu and button-level security rules
--------------------------------------------------------------------------------

-- Roles
INSERT INTO app_roles (role_name, role_desc) VALUES ('ADMIN',   'Full system access');
INSERT INTO app_roles (role_name, role_desc) VALUES ('MANAGER', 'Approve and edit records');
INSERT INTO app_roles (role_name, role_desc) VALUES ('USER',    'Standard data entry user');
INSERT INTO app_roles (role_name, role_desc) VALUES ('VIEWER',  'Read-only access');
COMMIT;

-- Users (passwords are set via pkg_auth.register_user so they are hashed, not plain text)
BEGIN
    pkg_auth.register_user('admin.farooq', 'ChangeMe#123', 'Abdullah Farooq', 'admin@example.com');
    pkg_auth.register_user('m.khan',       'ChangeMe#123', 'Manager Khan',    'manager@example.com');
    pkg_auth.register_user('u.ali',        'ChangeMe#123', 'Regular Ali',     'user@example.com');
    pkg_auth.register_user('v.sana',       'ChangeMe#123', 'Viewer Sana',     'viewer@example.com');
END;
/

-- Assign roles to users
INSERT INTO app_user_roles (user_id, role_id)
SELECT u.user_id, r.role_id FROM app_users u, app_roles r
WHERE u.username = 'admin.farooq' AND r.role_name = 'ADMIN';

INSERT INTO app_user_roles (user_id, role_id)
SELECT u.user_id, r.role_id FROM app_users u, app_roles r
WHERE u.username = 'm.khan' AND r.role_name = 'MANAGER';

INSERT INTO app_user_roles (user_id, role_id)
SELECT u.user_id, r.role_id FROM app_users u, app_roles r
WHERE u.username = 'u.ali' AND r.role_name = 'USER';

INSERT INTO app_user_roles (user_id, role_id)
SELECT u.user_id, r.role_id FROM app_users u, app_roles r
WHERE u.username = 'v.sana' AND r.role_name = 'VIEWER';
COMMIT;

-- Navigation tree (this is what renders as the collapsible "tree" side menu
-- in Universal Theme when Navigation Menu position = Side)
INSERT INTO app_menu_items (menu_id, parent_menu_id, menu_label, menu_icon, target_page_id, display_seq)
VALUES (1, NULL, 'Dashboard', 'fa-home', 1, 10);

INSERT INTO app_menu_items (menu_id, parent_menu_id, menu_label, menu_icon, target_page_id, display_seq)
VALUES (2, NULL, 'Administration', 'fa-cogs', NULL, 20);

INSERT INTO app_menu_items (menu_id, parent_menu_id, menu_label, menu_icon, target_page_id, display_seq)
VALUES (3, 2, 'Manage Users', 'fa-users', 10, 10);

INSERT INTO app_menu_items (menu_id, parent_menu_id, menu_label, menu_icon, target_page_id, display_seq)
VALUES (4, 2, 'Manage Roles', 'fa-id-badge', 11, 20);

INSERT INTO app_menu_items (menu_id, parent_menu_id, menu_label, menu_icon, target_page_id, display_seq)
VALUES (5, 2, 'Button/Page Security', 'fa-lock', 12, 30);

INSERT INTO app_menu_items (menu_id, parent_menu_id, menu_label, menu_icon, target_page_id, display_seq)
VALUES (6, NULL, 'Reports', 'fa-bar-chart', NULL, 30);

INSERT INTO app_menu_items (menu_id, parent_menu_id, menu_label, menu_icon, target_page_id, display_seq)
VALUES (7, 6, 'Login Audit', 'fa-history', 20, 10);
COMMIT;

-- Which roles can see which tree node
INSERT INTO app_menu_role_access (menu_id, role_id)
SELECT m.menu_id, r.role_id FROM app_menu_items m, app_roles r WHERE r.role_name = 'ADMIN';  -- Admin sees everything

INSERT INTO app_menu_role_access (menu_id, role_id)
SELECT m.menu_id, r.role_id FROM app_menu_items m, app_roles r
WHERE m.menu_id IN (1, 6, 7) AND r.role_name IN ('MANAGER','USER','VIEWER');
COMMIT;

-- Button-level security example: only ADMIN and MANAGER can see the Delete
-- button on the Manage Users page (page 10); VIEWER never sees Save/Edit.
INSERT INTO app_component_security (role_id, app_id, page_id, component_type, component_name, display_ind)
SELECT r.role_id, 100, 10, 'BUTTON', 'BTN_DELETE', 'Y' FROM app_roles r WHERE r.role_name IN ('ADMIN');

INSERT INTO app_component_security (role_id, app_id, page_id, component_type, component_name, display_ind)
SELECT r.role_id, 100, 10, 'BUTTON', 'BTN_SAVE', 'Y' FROM app_roles r WHERE r.role_name IN ('ADMIN','MANAGER','USER');

INSERT INTO app_component_security (role_id, app_id, page_id, component_type, component_name, display_ind)
SELECT r.role_id, 100, 10, 'BUTTON', 'BTN_SAVE', 'N' FROM app_roles r WHERE r.role_name = 'VIEWER';
COMMIT;
