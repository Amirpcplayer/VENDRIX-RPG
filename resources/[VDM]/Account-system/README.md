# VENDRIX Account System

## Current implementation

- Native MTA account registration and login.
- Server-side validation of usernames and passwords.
- A basic MTA GUI login/register panel; no CEF dependency.
- Per-player request cooldown and temporary lock after repeated failed logins.
- Unauthenticated players are hidden/frozen and cannot complete a spawn.

## Account rules

- Username: 3–24 ASCII letters, digits, or underscores.
- Password: 8–64 characters.
- Passwords and authentication decisions are never trusted from client state.

## Storage limitation

This initial version uses MTA's native account storage. It does not yet store RPG characters, inventory, or progression in a dedicated database. Do not treat this as the final persistence architecture for a large public server.

## Start

From the MTA server console:

```text
refresh
start Account-system
```

The Core resource can remain running independently.
