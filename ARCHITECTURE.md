# Architecture

## Entity relationship overview

```mermaid
erDiagram
    APP_USERS ||--o{ APP_USER_ROLES : has
    APP_ROLES ||--o{ APP_USER_ROLES : grants
    APP_ROLES ||--o{ APP_MENU_ROLE_ACCESS : sees
    APP_MENU_ITEMS ||--o{ APP_MENU_ROLE_ACCESS : "restricted by"
    APP_MENU_ITEMS ||--o{ APP_MENU_ITEMS : "parent of"
    APP_ROLES ||--o{ APP_COMPONENT_SECURITY : controls
    APP_USERS ||--o{ APP_LOGIN_AUDIT : attempts

    APP_USERS {
        number user_id PK
        varchar2 username
        varchar2 password_hash
        char is_active
        char is_locked
    }
    APP_ROLES {
        number role_id PK
        varchar2 role_name
    }
    APP_USER_ROLES {
        number user_role_id PK
        number user_id FK
        number role_id FK
    }
    APP_MENU_ITEMS {
        number menu_id PK
        number parent_menu_id FK
        varchar2 menu_label
        number target_page_id
    }
    APP_MENU_ROLE_ACCESS {
        number menu_access_id PK
        number menu_id FK
        number role_id FK
    }
    APP_COMPONENT_SECURITY {
        number security_id PK
        number role_id FK
        varchar2 component_type
        varchar2 component_name
        char display_ind
        char readonly_ind
    }
    APP_LOGIN_AUDIT {
        number audit_id PK
        varchar2 username
        varchar2 result
    }
```

## Request flow

```mermaid
sequenceDiagram
    participant U as User
    participant L as APEX Login Page
    participant A as pkg_auth
    participant S as pkg_security
    participant P as APEX Page (Nav Tree + Buttons)

    U->>L: Enter username/password
    L->>A: pkg_auth.authenticate(user, pass)
    A->>A: hash + compare, log to APP_LOGIN_AUDIT
    A-->>L: TRUE/FALSE
    L-->>U: Session established (or error)
    U->>P: Loads page
    P->>S: has_role() for Authorization Schemes (page/region access)
    P->>S: can_display() per button/item Static ID
    S-->>P: Y/N per component
    P-->>U: Renders tree menu + buttons filtered to the user's role(s)
```

## Design notes

- **Roles, not per-user grants.** Every permission check goes through
  `APP_ROLES`, so adding a new user is one `APP_USER_ROLES` insert, not a
  re-check of every screen.
- **Menu tree mirrors the security table.** `APP_MENU_ITEMS` is
  self-referencing (`parent_menu_id`), so any depth of tree is possible;
  `APP_MENU_ROLE_ACCESS` decides which nodes render for the logged-in
  user's role(s) — hidden parents with no visible children simply
  disappear from the rendered tree.
- **Button security is generic**, not hard-coded per page: one table
  (`APP_COMPONENT_SECURITY`) covers pages, regions, buttons, items, and
  columns, keyed by each component's APEX Static ID.
- **Passwords are always hashed+salted** (`DBMS_CRYPTO.HASH`, SHA-512) —
  the plain password never touches the table.
