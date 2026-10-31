-- VENDRIX RPG account database schema (SQLite 3)
-- Passwords must be stored as password hashes, never as plaintext.
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL,
    username_normalized TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    last_login_at INTEGER,
    last_login_serial TEXT,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'locked', 'disabled'))
);

CREATE INDEX IF NOT EXISTS idx_accounts_status
    ON accounts(status);

CREATE TABLE IF NOT EXISTS account_login_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id INTEGER,
    username_attempt TEXT NOT NULL,
    success INTEGER NOT NULL CHECK (success IN (0, 1)),
    reason TEXT NOT NULL,
    serial TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_login_events_created_at
    ON account_login_events(created_at);

CREATE INDEX IF NOT EXISTS idx_login_events_username
    ON account_login_events(username_attempt);

-- Reserved for future character/profile persistence. Do not put gameplay state
-- here until the corresponding server systems are migrated deliberately.
CREATE TABLE IF NOT EXISTS player_profiles (
    account_id INTEGER PRIMARY KEY,
    display_name TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);
