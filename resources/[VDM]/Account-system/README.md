# VENDRIX Account System

## Features
- Custom HTML/CSS/JavaScript CEF login and registration interface.
- Black, gold, and neon-red VENDRIX styling.
- CEF browser is created when authentication UI is needed and destroyed after successful authentication.
- No external fonts, remote assets, or third-party JS dependencies.
- Server-side username/password validation and native MTA account storage.
- Temporary lock after repeated failed login attempts.

## Account rules
- Username: 3–24 ASCII letters, digits, or underscores.
- Password: 8–64 characters, without control characters.

## Install / start
Run in the MTA server console:
```text
refresh
restart Account-system
```
If it is not running yet:
```text
start Account-system
```

## Current limitations
This version uses native MTA account storage. RPG character data, inventory, and progression persistence are not implemented yet. The CEF interface has not been verified in a live MTA client in this development session.
