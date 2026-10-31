-- VENDRIX RPG master database schema (SQLite 3)
-- Open vendrix_accounts.db with DB Browser for SQLite to browse these tables.
-- Passwords must be stored as strong salted hashes, never plaintext.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    username_normalized TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','locked','disabled')),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    last_login_at INTEGER,
    last_login_serial TEXT
);
CREATE INDEX IF NOT EXISTS idx_accounts_status ON accounts(status);

CREATE TABLE IF NOT EXISTS account_login_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER,
    username_attempt TEXT NOT NULL,
    success INTEGER NOT NULL CHECK (success IN (0,1)),
    reason TEXT NOT NULL,
    serial TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_login_events_created_at ON account_login_events(created_at);
CREATE INDEX IF NOT EXISTS idx_login_events_username ON account_login_events(username_attempt);

CREATE TABLE IF NOT EXISTS characters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    name_normalized TEXT NOT NULL UNIQUE,
    skin_id INTEGER NOT NULL DEFAULT 0,
    money INTEGER NOT NULL DEFAULT 0 CHECK (money >= 0),
    bank_money INTEGER NOT NULL DEFAULT 0 CHECK (bank_money >= 0),
    playtime_seconds INTEGER NOT NULL DEFAULT 0 CHECK (playtime_seconds >= 0),
    health REAL NOT NULL DEFAULT 100 CHECK (health >= 0 AND health <= 100),
    armor REAL NOT NULL DEFAULT 0 CHECK (armor >= 0 AND armor <= 100),
    x REAL, y REAL, z REAL, rotation REAL,
    interior INTEGER NOT NULL DEFAULT 0,
    dimension INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_characters_account ON characters(account_id);

CREATE TABLE IF NOT EXISTS vehicles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id INTEGER NOT NULL,
    model_id INTEGER NOT NULL,
    display_name TEXT,
    plate TEXT UNIQUE,
    color1 INTEGER, color2 INTEGER, color3 INTEGER, color4 INTEGER,
    health REAL NOT NULL DEFAULT 1000,
    fuel REAL NOT NULL DEFAULT 100 CHECK (fuel >= 0),
    mileage REAL NOT NULL DEFAULT 0 CHECK (mileage >= 0),
    x REAL, y REAL, z REAL, rotation REAL,
    interior INTEGER NOT NULL DEFAULT 0,
    dimension INTEGER NOT NULL DEFAULT 0,
    locked INTEGER NOT NULL DEFAULT 0 CHECK (locked IN (0,1)),
    impounded INTEGER NOT NULL DEFAULT 0 CHECK (impounded IN (0,1)),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_vehicles_character ON vehicles(character_id);

CREATE TABLE IF NOT EXISTS vehicle_modifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    vehicle_id INTEGER NOT NULL,
    upgrade_id INTEGER NOT NULL,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
    UNIQUE (vehicle_id, upgrade_id)
);

CREATE TABLE IF NOT EXISTS weapons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id INTEGER NOT NULL,
    weapon_id INTEGER NOT NULL,
    ammo INTEGER NOT NULL DEFAULT 0 CHECK (ammo >= 0),
    slot INTEGER,
    serial_number TEXT UNIQUE,
    condition REAL NOT NULL DEFAULT 100 CHECK (condition >= 0 AND condition <= 100),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_weapons_character ON weapons(character_id);

CREATE TABLE IF NOT EXISTS inventory_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id INTEGER NOT NULL,
    item_key TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    metadata_json TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    UNIQUE (character_id, item_key)
);
CREATE INDEX IF NOT EXISTS idx_inventory_character ON inventory_items(character_id);

CREATE TABLE IF NOT EXISTS properties (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_character_id INTEGER,
    property_type TEXT NOT NULL,
    name TEXT NOT NULL,
    price INTEGER NOT NULL DEFAULT 0 CHECK (price >= 0),
    x REAL, y REAL, z REAL,
    interior INTEGER NOT NULL DEFAULT 0,
    dimension INTEGER NOT NULL DEFAULT 0,
    locked INTEGER NOT NULL DEFAULT 1 CHECK (locked IN (0,1)),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (owner_character_id) REFERENCES characters(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_properties_owner ON properties(owner_character_id);

CREATE TABLE IF NOT EXISTS factions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    faction_type TEXT NOT NULL DEFAULT 'gang',
    leader_character_id INTEGER,
    treasury INTEGER NOT NULL DEFAULT 0 CHECK (treasury >= 0),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (leader_character_id) REFERENCES characters(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS faction_members (
    faction_id INTEGER NOT NULL,
    character_id INTEGER NOT NULL,
    rank INTEGER NOT NULL DEFAULT 1,
    joined_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    PRIMARY KEY (faction_id, character_id),
    FOREIGN KEY (faction_id) REFERENCES factions(id) ON DELETE CASCADE,
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS jobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    job_key TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    enabled INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0,1))
);

CREATE TABLE IF NOT EXISTS character_jobs (
    character_id INTEGER NOT NULL,
    job_id INTEGER NOT NULL,
    level INTEGER NOT NULL DEFAULT 1,
    experience INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    PRIMARY KEY (character_id, job_id),
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS economy_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    character_id INTEGER,
    transaction_type TEXT NOT NULL,
    amount INTEGER NOT NULL,
    balance_after INTEGER,
    reference TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_economy_character_time ON economy_transactions(character_id, created_at);

CREATE TABLE IF NOT EXISTS bans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER,
    serial TEXT,
    reason TEXT NOT NULL,
    admin_account_id INTEGER,
    expires_at INTEGER,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL,
    FOREIGN KEY (admin_account_id) REFERENCES accounts(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_bans_serial ON bans(serial);

CREATE TABLE IF NOT EXISTS player_profiles (
    account_id INTEGER PRIMARY KEY,
    display_name TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);
