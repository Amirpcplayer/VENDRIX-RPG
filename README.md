# VENDRIX RPG

Custom MTA:SA RPG + Gang War gamemode built from the ground up with Lua.

## Resource layout

```text
resources/
└── [VDM]/
    ├── Core/
    │   ├── meta.xml
    │   └── server.lua
    ├── Account-system/
    │   ├── meta.xml
    │   ├── server.lua
    │   ├── client.lua
    │   └── README.md
    └── Inventory/
        └── README.md
```

## Current status

- **Core:** minimal server-side bootstrap resource.
- **Account-system:** initial registration/login flow using native MTA account storage.
- **Inventory:** planned; not yet an MTA resource.

## Install

Copy the repository's `resources/[VDM]` directory into:

`D:\\VENDRIX RPG\\MTA\\server\\mods\\deathmatch\\resources\\`

Then run these commands in the MTA server console:

```text
refresh
start Account-system
```

The Core resource may remain running. After the account resource starts, reconnect to the server to test the login/register panel.

## Important limitations

The current account system uses MTA's native account storage and a temporary default spawn position. Character creation, persistent RPG data, database integration, and final spawn selection are not implemented yet.

Never store passwords, database credentials, or private tokens in this repository.
