--------------------------------------------------------------------------------
-- 02_packages.sql
-- PKG_AUTH        -> custom authentication (login) used by the APEX
--                    Authentication Scheme's "Verify Function"
-- PKG_SECURITY     -> reusable functions used by Authorization Schemes and by
--                    button/region "Server-Side Condition" expressions
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_auth AS

    -- Called from APEX: Shared Components > Authentication Schemes >
    -- Custom > "Authentication Function Name" -> pkg_auth.authenticate
    FUNCTION authenticate (
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN BOOLEAN;

    PROCEDURE register_user (
        p_username  IN VARCHAR2,
        p_password  IN VARCHAR2,
        p_full_name IN VARCHAR2,
        p_email     IN VARCHAR2
    );

END pkg_auth;
/

CREATE OR REPLACE PACKAGE BODY pkg_auth AS

    FUNCTION hash_password (p_password IN VARCHAR2, p_salt IN VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        -- SHA-512 hash, salted. Swap for APEX_UTIL / DBMS_CRYPTO of your choice.
        RETURN RAWTOHEX(
            DBMS_CRYPTO.HASH(
                UTL_RAW.CAST_TO_RAW(p_password || p_salt),
                DBMS_CRYPTO.HASH_SH512
            )
        );
    END hash_password;

    FUNCTION authenticate (
        p_username IN VARCHAR2,
        p_password IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_rec           app_users%ROWTYPE;
        l_hashed        VARCHAR2(200);
    BEGIN
        SELECT * INTO l_rec
        FROM   app_users
        WHERE  UPPER(username) = UPPER(p_username);

        IF l_rec.is_locked = 'Y' THEN
            INSERT INTO app_login_audit(username, result) VALUES (p_username, 'LOCKED');
            RETURN FALSE;
        END IF;

        IF l_rec.is_active = 'N' THEN
            INSERT INTO app_login_audit(username, result) VALUES (p_username, 'FAILURE');
            RETURN FALSE;
        END IF;

        l_hashed := hash_password(p_password, l_rec.salt);

        IF l_hashed = l_rec.password_hash THEN
            UPDATE app_users
            SET    failed_logins = 0,
                   last_login_dt = SYSDATE
            WHERE  user_id = l_rec.user_id;

            INSERT INTO app_login_audit(username, result) VALUES (p_username, 'SUCCESS');
            COMMIT;
            RETURN TRUE;
        ELSE
            UPDATE app_users
            SET    failed_logins = failed_logins + 1,
                   is_locked = CASE WHEN failed_logins + 1 >= 5 THEN 'Y' ELSE is_locked END
            WHERE  user_id = l_rec.user_id;

            INSERT INTO app_login_audit(username, result) VALUES (p_username, 'FAILURE');
            COMMIT;
            RETURN FALSE;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO app_login_audit(username, result) VALUES (p_username, 'FAILURE');
            COMMIT;
            RETURN FALSE;
    END authenticate;

    PROCEDURE register_user (
        p_username  IN VARCHAR2,
        p_password  IN VARCHAR2,
        p_full_name IN VARCHAR2,
        p_email     IN VARCHAR2
    )
    IS
        l_salt VARCHAR2(100) := RAWTOHEX(DBMS_CRYPTO.RANDOMBYTES(16));
    BEGIN
        INSERT INTO app_users (username, password_hash, salt, full_name, email)
        VALUES (
            p_username,
            hash_password(p_password, l_salt),
            l_salt,
            p_full_name,
            p_email
        );
        COMMIT;
    END register_user;

END pkg_auth;
/


CREATE OR REPLACE PACKAGE pkg_security AS

    -- Returns TRUE if the currently authenticated APEX user (V('APP_USER'))
    -- holds the given role. Use this as the PL/SQL expression in an
    -- Authorization Scheme, e.g.:  pkg_security.has_role('ADMIN')
    FUNCTION has_role (p_role_name IN VARCHAR2) RETURN BOOLEAN;

    -- Returns TRUE if the user's role(s) grant DISPLAY on a given
    -- page/button/item. Use in a Button/Region "Server-Side Condition ->
    -- PL/SQL Expression": pkg_security.can_display('BTN_DELETE', 12)
    FUNCTION can_display (
        p_component_name IN VARCHAR2,
        p_page_id        IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN;

    -- Returns a colon-delimited list of role names for the current user,
    -- handy for APEX_UTIL.STRING_TO_TABLE-based checks or debugging.
    FUNCTION user_roles RETURN VARCHAR2;

END pkg_security;
/

CREATE OR REPLACE PACKAGE BODY pkg_security AS

    FUNCTION has_role (p_role_name IN VARCHAR2) RETURN BOOLEAN
    IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   app_user_roles ur
        JOIN   app_users u  ON u.user_id = ur.user_id
        JOIN   app_roles r  ON r.role_id = ur.role_id
        WHERE  UPPER(u.username) = UPPER(NVL(V('APP_USER'), '-'))
        AND    UPPER(r.role_name) = UPPER(p_role_name)
        AND    r.is_active = 'Y';

        RETURN l_count > 0;
    END has_role;

    FUNCTION can_display (
        p_component_name IN VARCHAR2,
        p_page_id        IN NUMBER DEFAULT NULL
    ) RETURN BOOLEAN
    IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   app_component_security cs
        JOIN   app_user_roles ur ON ur.role_id = cs.role_id
        JOIN   app_users u       ON u.user_id = ur.user_id
        WHERE  UPPER(u.username)       = UPPER(NVL(V('APP_USER'), '-'))
        AND    UPPER(cs.component_name) = UPPER(p_component_name)
        AND    (p_page_id IS NULL OR cs.page_id = p_page_id)
        AND    cs.display_ind = 'Y';

        RETURN l_count > 0;
    END can_display;

    FUNCTION user_roles RETURN VARCHAR2
    IS
        l_roles VARCHAR2(4000);
    BEGIN
        SELECT LISTAGG(r.role_name, ':') WITHIN GROUP (ORDER BY r.role_name)
        INTO   l_roles
        FROM   app_user_roles ur
        JOIN   app_users u ON u.user_id = ur.user_id
        JOIN   app_roles r ON r.role_id = ur.role_id
        WHERE  UPPER(u.username) = UPPER(NVL(V('APP_USER'), '-'));

        RETURN l_roles;
    END user_roles;

END pkg_security;
/
