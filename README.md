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
    │   └── README.md
    └── Inventory/
        └── README.md
```

## Current status

- **Core:** minimal server-side bootstrap resource.
- **Account-system:** planned; not yet an MTA resource.
- **Inventory:** planned; not yet an MTA resource.

## Install

Copy the `resources/[VDM]` directory into:

`D:\\VENDRIX RPG\\MTA\\server\\mods\\deathmatch\\resources\\`

Then start the Core resource from the MTA server console:

```text
refresh
start [VDM]/Core
```

Expected log entry:

`[VENDRIX] Core started successfully.`

Do not store passwords, database credentials, or private tokens in this repository.
