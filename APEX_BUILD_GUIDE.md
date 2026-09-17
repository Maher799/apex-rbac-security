# Building the App in Oracle APEX (step by step)

This guide walks through wiring the tables/packages in `database/` into an
actual APEX application: custom login, a role-driven **tree navigation
menu**, and **button-level security**.

> Oracle APEX runs in your own workspace (apex.oracle.com or an on-prem
> instance) — it can't be generated headlessly from outside APEX, so these
> are the exact clicks to do it yourself. Screenshots for each numbered step
> below are in the official docs linked at the end of each section — Oracle's
> UI changes often enough between versions that pointing at the current,
> version-matched screenshot beats a stale embedded one.

## 1. Run the SQL scripts

In SQL Workshop → SQL Scripts (or SQL*Plus/SQLcl against your schema), run
in order:

```
database/01_tables.sql
database/02_packages.sql
database/03_sample_data.sql
```

## 2. Create the Authentication Scheme (login credentials)

1. App Builder → your application → **Shared Components → Authentication
   Schemes → Create**.
2. Scheme Type: **Custom**.
3. **Authentication Function Name**: `pkg_auth.authenticate`
4. Leave "Invalid Session / Session Not Valid" on defaults to start.
5. Make this scheme **Current** for the application.
6. Build (or use the built-in) Login page — Page 101 in the standard
   APEX login page template — pointing its Username/Password items at
   `P101_USERNAME` / `P101_PASSWORD`.

Reference: Oracle APEX docs — *Creating a Custom Authentication Scheme*
(`docs.oracle.com/en/database/oracle/apex`, "Managing Application Security"
chapter).

## 3. Create Authorization Schemes (role checks)

Shared Components → **Authorization Schemes → Create**, Type: **PL/SQL
Function Body returning Boolean**, e.g.:

```sql
RETURN pkg_security.has_role('ADMIN');
```

Create one per role you need to gate on (`AUTH_IS_ADMIN`,
`AUTH_IS_MANAGER`, ...). You'll attach these to Pages, Regions, Buttons, or
individual Items under each component's **Security** section.

## 4. Build the tree-based navigation menu

Oracle APEX renders the **side-position Navigation Menu** as a collapsible
tree automatically — this is the "tree security" look you're describing.

1. Shared Components → **Navigation Menu → Create** (or edit the default
   list, usually named after your app).
2. Set **List Entry Source Type = Dynamic** query pointing at
   `app_menu_items`, filtered to the rows the current user's roles can see:

```sql
SELECT m.menu_label,
       NVL('f?p=&APP_ID.:' || m.target_page_id || ':&SESSION.', 'javascript:void(0);') AS target,
       m.menu_icon,
       m.parent_menu_id
FROM   app_menu_items m
WHERE  m.is_active = 'Y'
AND    EXISTS (
         SELECT 1
         FROM   app_menu_role_access mra
         JOIN   app_user_roles ur ON ur.role_id = mra.role_id
         JOIN   app_users u       ON u.user_id  = ur.user_id
         WHERE  mra.menu_id = m.menu_id
         AND    UPPER(u.username) = UPPER(:APP_USER)
       )
ORDER BY m.display_seq
```

3. Under **Shared Components → User Interface → Desktop → Navigation Menu
   region**, confirm the **Position** is set to **Side** (this is what gives
   the collapsible tree widget rather than a flat top tab bar).

Reference: Oracle APEX docs — *Navigation Menus and Universal Theme* (search
"Side Position - Tree Based Navigation" in the Universal Theme UI docs).

## 5. Button-level (component) security

For any button, region, or item you want gated:

1. Select the component → **Advanced → Static ID** (e.g. `BTN_DELETE`) —
   this must match `app_component_security.component_name`.
2. Under **Security → Server-Side Condition → Type = PL/SQL Expression**:

```sql
pkg_security.can_display('BTN_DELETE', :APP_PAGE_ID)
```

3. Repeat per button. For a **read-only** instead of hidden behavior, bind
   the item's "Read Only" condition to a similar check against
   `readonly_ind` instead of `display_ind`.

## 6. Admin screens

Build simple interactive-grid/report pages against `app_users`,
`app_roles`, `app_user_roles`, `app_menu_items`, and
`app_component_security` so an ADMIN role can manage everything from inside
the app instead of SQL Workshop. The `App Builder → Create Application →
From table(s)` quick-start wizard is the fastest way to scaffold these.

## 7. Push to GitHub

From App Builder → your app → **Utilities → Export → Application** (or
**Export/Import → Export Application to Git-friendly SQL files**, available
in newer APEX versions), export the app definition as SQL. Commit that
alongside this repo's `database/` scripts:

```
git init
git add .
git commit -m "Initial APEX RBAC security project"
git remote add origin <your-repo-url>
git push -u origin main
```
