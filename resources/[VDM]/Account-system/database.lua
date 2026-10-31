-- VENDRIX RPG - SQLite database bootstrap
-- MTA creates vendrix_accounts.db automatically beside this resource.
-- Authentication integration is intentionally kept separate from this schema step.

local connection

local function initializeDatabase()
    connection = dbConnect("sqlite", "vendrix_accounts.db")
    if not connection then
        outputServerLog("[VENDRIX SQL] ERROR: Could not open vendrix_accounts.db")
        return false
    end

    local statements = {
        [[CREATE TABLE IF NOT EXISTS accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            username_normalized TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            last_login_at INTEGER,
            last_login_serial TEXT,
            status TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'locked', 'disabled'))
        )]],
        [[CREATE INDEX IF NOT EXISTS idx_accounts_status
            ON accounts(status)]],
        [[CREATE TABLE IF NOT EXISTS account_login_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            username_attempt TEXT NOT NULL,
            success INTEGER NOT NULL CHECK (success IN (0, 1)),
            reason TEXT NOT NULL,
            serial TEXT,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL
        )]],
        [[CREATE INDEX IF NOT EXISTS idx_login_events_created_at
            ON account_login_events(created_at)]],
        [[CREATE INDEX IF NOT EXISTS idx_login_events_username
            ON account_login_events(username_attempt)]],
        [[CREATE TABLE IF NOT EXISTS player_profiles (
            account_id INTEGER PRIMARY KEY,
            display_name TEXT,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        )]]
    }

    for _, statement in ipairs(statements) do
        if not dbExec(connection, statement) then
            outputServerLog("[VENDRIX SQL] ERROR: Failed to create or verify a database table.")
            return false
        end
    end

    outputServerLog("[VENDRIX SQL] SQLite database opened; account schema is ready.")
    return true
end

addEventHandler("onResourceStart", resourceRoot, function()
    initializeDatabase()
end)

addEventHandler("onResourceStop", resourceRoot, function()
    if connection then
        destroyElement(connection)
        connection = nil
    end
end)

function vendrixGetDatabaseConnection()
    if connection and isElement(connection) then
        return connection
    end
    return false
end
