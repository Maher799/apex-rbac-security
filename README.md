# Oracle APEX – Role & Button Based Security (RBAC) Starter

A complete, ready-to-run database layer + build guide for adding
**custom login**, **role-based authorization**, and **button/component-level
security** to an Oracle APEX application — with a role-driven **tree
navigation menu** (the collapsible side-menu look APEX gives you natively).

## Features

- Custom authentication (salted SHA-512 password hashing) — no plain-text
  passwords stored
- Role → User assignment (many-to-many)
- Self-referencing menu table that powers a collapsible **tree navigation
  menu**, filtered per logged-in user's role(s)
- Generic **button/region/item level security** table — one row per
  component, per role, driven by each component's APEX Static ID
- Login attempt auditing + account lockout after repeated failures
- Sample data: 4 roles (ADMIN / MANAGER / USER / VIEWER), 4 users, a sample
  tree, and sample button rules

## Repo structure

```
apex-rbac-security/
├── README.md
├── database/
│   ├── 01_tables.sql        -- all tables + indexes
│   ├── 02_packages.sql      -- pkg_auth (login), pkg_security (role/button checks)
│   └── 03_sample_data.sql   -- seed roles, users, menu tree, button rules
└── docs/
    ├── ARCHITECTURE.md      -- ER diagram + request-flow diagram (Mermaid)
    └── APEX_BUILD_GUIDE.md  -- click-by-click steps inside APEX App Builder
```

## Quick start

1. Run the three scripts in `database/` against your schema, in order.
2. Follow `docs/APEX_BUILD_GUIDE.md` to wire the Authentication Scheme,
   Authorization Schemes, the tree Navigation Menu, and button security
   into your APEX application.
3. Default sample users (all created with password `ChangeMe#123` — change
   before using anywhere real):

   | Username       | Role    |
   |----------------|---------|
   | admin.farooq   | ADMIN   |
   | m.khan         | MANAGER |
   | u.ali          | USER    |
   | v.sana         | VIEWER  |

## How this looks in APEX

APEX doesn't have a special "tree security" object — what you get is the
regular **Navigation Menu (List) component**, rendered as a tree because
its position is set to **Side** under Universal Theme. Feed it a dynamic
query against `APP_MENU_ITEMS` filtered by the current user's roles (query
given in `docs/APEX_BUILD_GUIDE.md`) and APEX collapses/expands it
automatically as a tree widget. See Oracle's own Universal Theme docs for
what that side-tree widget looks like in practice, and the sample APEX
context-menu app below for a live, click-through example of role-driven
menus and buttons.

## References used while building this

- Doyensys — Role-based Authorization in Oracle APEX (ROLE_ACCESS_CONTROL
  table pattern this project builds on)
- Oracle APEX Universal Theme docs — Navigation Menus (Side Position =
  Tree Based Navigation)
- Pretius APEX Context Menu — live demo of role/authorization-driven menus
- gisprogrammer/Oracle-APEX-Authentication-and-Authorization-plugins (GitHub)
  — example of a pluggable custom Authentication/Authorization scheme

## License

MIT — see `LICENSE`.
