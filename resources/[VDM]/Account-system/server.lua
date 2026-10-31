-- VENDRIX RPG - Account System
-- Uses MTA's native account storage. Never trust client-supplied identity or auth state.

local AUTH_EVENT = "vendrix:account:submit"
local RESULT_EVENT = "vendrix:account:result"
local READY_EVENT = "vendrix:account:ready"

local MIN_USERNAME_LENGTH = 3
local MAX_USERNAME_LENGTH = 24
local MIN_PASSWORD_LENGTH = 8
local MAX_PASSWORD_LENGTH = 64
local MAX_FAILED_ATTEMPTS = 5
local LOCK_DURATION_MS = 10000
local REQUEST_COOLDOWN_MS = 1200

local attempts = {}
local authenticated = {}

-- Default player spawn
local SPAWN_X, SPAWN_Y, SPAWN_Z = 2029.132812, -1419.573242, 16.992188
local SPAWN_ROTATION = 133.620
local SPAWN_INTERIOR = 0
local SPAWN_DIMENSION = 0
local SPAWN_SKIN = 0

local function sendResult(player, success, message, authenticatedNow)
    if isElement(player) then
        triggerClientEvent(player, RESULT_EVENT, resourceRoot, success, message, authenticatedNow == true)
    end
end

local function isValidUsername(username)
    return type(username) == "string"
        and #username >= MIN_USERNAME_LENGTH
        and #username <= MAX_USERNAME_LENGTH
        and username:match("^[A-Za-z0-9_]+$") ~= nil
end

local function isValidPassword(password)
    return type(password) == "string"
        and #password >= MIN_PASSWORD_LENGTH
        and #password <= MAX_PASSWORD_LENGTH
        and password:find("[%c]") == nil
end

-- MTA account names may have been created with different letter casing.
-- Resolve them case-insensitively so players can log in consistently.
local function findAccountByUsername(username)
    if type(username) ~= "string" then
        return nil
    end

    local direct = getAccount(username)
    if direct then
        return direct
    end

    local wanted = username:lower()
    local accounts = getAccounts()
    for i = 1, #accounts do
        local account = accounts[i]
        if isElement(account) then
            local storedName = getAccountName(account)
            if type(storedName) == "string" and storedName:lower() == wanted then
                return account
            end
        end
    end

    return nil
end

-- One account registration per MTA serial. The serial is stored in native
-- account data, which persists with MTA's account database.
local SERIAL_DATA_KEY = "vendrix:registrationSerial"

local function findAccountBySerial(serial)
    if type(serial) ~= "string" or serial == "" then
        return nil
    end

    local accounts = getAccounts()
    for i = 1, #accounts do
        local account = accounts[i]
        if isElement(account) and getAccountData(account, SERIAL_DATA_KEY) == serial then
            return account
        end
    end

    return nil
end

local function isPlayerLoggedInto(player, account)
    if not isElement(player) or not account then
        return false
    end

    local current = getPlayerAccount(player)
    return current == account and not isGuestAccount(current)
end

local function getAttemptState(player)
    local state = attempts[player]
    if not state then
        state = {
            failures = 0,
            lockedUntil = 0,
            lastRequest = 0
        }
        attempts[player] = state
    end
    return state
end

local function finishAuthentication(player)
    authenticated[player] = true
    attempts[player] = nil

    setElementAlpha(player, 255)
    setElementFrozen(player, false)

    if not isPedInVehicle(player) then
        spawnPlayer(
            player,
            SPAWN_X, SPAWN_Y, SPAWN_Z,
            SPAWN_ROTATION,
            SPAWN_SKIN,
            SPAWN_INTERIOR,
            SPAWN_DIMENSION
        )
    end

    fadeCamera(player, true)
    setCameraTarget(player, player)
    sendResult(player, true, "ورود موفق بود. به VENDRIX خوش آمدی.", true)
    outputServerLog(("[VENDRIX] Player authenticated: %s"):format(getPlayerName(player)))
end

local function getDatabaseConnection()
    if type(vendrixGetDatabaseConnection) ~= "function" then
        return false
    end
    return vendrixGetDatabaseConnection()
end

local function recordLoginEvent(accountId, username, success, reason, serial)
    local connection = getDatabaseConnection()
    if not connection then return false end
    return dbExec(connection,
        "INSERT INTO account_login_events (account_id, username_attempt, success, reason, serial) VALUES (?, ?, ?, ?, ?)",
        accountId or nil, username, success and 1 or 0, reason, serial
    )
end

local function updateSqlLoginMetadata(accountId, serial)
    local connection = getDatabaseConnection()
    if not connection then return false end
    return dbExec(connection,
        "UPDATE accounts SET last_login_at = strftime('%s','now'), last_login_serial = ? WHERE id = ?",
        serial, accountId
    )
end

local function completeSqlLogin(player, username, password, serial, sqlAccount)
    if not isElement(player) then return end

    local current = getPlayerAccount(player)
    if current and not isGuestAccount(current) then
        if getAccountName(current):lower() ~= username:lower() then
            sendResult(player, false, "ابتدا از حساب فعلی خارج شو و سپس وارد حساب دیگری شو.", false)
            return
        end
        updateSqlLoginMetadata(sqlAccount.id, serial)
        recordLoginEvent(sqlAccount.id, username, true, "sql_login_existing_session", serial)
        finishAuthentication(player)
        return
    end

    local nativeAccount = findAccountByUsername(username)
    if not nativeAccount then
        nativeAccount = addAccount(username, password)
        if not nativeAccount then
            recordLoginEvent(sqlAccount.id, username, false, "native_account_sync_failed", serial)
            sendResult(player, false, "حساب SQL معتبر است اما ساخت حساب سازگار با MTA انجام نشد. دوباره تلاش کن.", false)
            return
        end
    end

    local loggedIn = logIn(player, nativeAccount, password) == true
        or isPlayerLoggedInto(player, nativeAccount)

    if not loggedIn then
        -- SQL password verification already succeeded, so synchronize the
        -- native compatibility account before retrying MTA login.
        if not setAccountPassword(nativeAccount, password) then
            recordLoginEvent(sqlAccount.id, username, false, "native_password_sync_failed", serial)
            sendResult(player, false, "ورود SQL تأیید شد اما همگام‌سازی حساب MTA ناموفق بود.", false)
            return
        end
        loggedIn = logIn(player, nativeAccount, password) == true
            or isPlayerLoggedInto(player, nativeAccount)
    end

    if not loggedIn or not isPlayerLoggedInto(player, nativeAccount) then
        recordLoginEvent(sqlAccount.id, username, false, "native_login_failed", serial)
        sendResult(player, false, "ورود حساب تأیید شد اما ورود داخلی MTA انجام نشد؛ دوباره تلاش کن.", false)
        return
    end

    if getAccountData(nativeAccount, SERIAL_DATA_KEY) == false then
        setAccountData(nativeAccount, SERIAL_DATA_KEY, serial, false)
    end

    updateSqlLoginMetadata(sqlAccount.id, serial)
    recordLoginEvent(sqlAccount.id, username, true, "sql_login", serial)
    finishAuthentication(player)
end

addEvent(READY_EVENT, true)
addEventHandler(READY_EVENT, resourceRoot, function()
    local player = client
    if not isElement(player) then return end

    if authenticated[player] then
        sendResult(player, true, "حساب شما فعال است.", true)
        return
    end

    -- A resource restart clears the Lua session table but does not log the
    -- player out of MTA's native account system. Restore that session safely.
    local current = getPlayerAccount(player)
    if current and not isGuestAccount(current) then
        authenticated[player] = true
        attempts[player] = nil
        setElementAlpha(player, 255)
        setElementFrozen(player, false)
        fadeCamera(player, true)
        setCameraTarget(player, player)
        sendResult(player, true, "حساب شما فعال است.", true)
        return
    end

    setElementAlpha(player, 0)
    setElementFrozen(player, true)
    triggerClientEvent(player, "vendrix:account:show", resourceRoot)
end)

addEvent(AUTH_EVENT, true)
addEventHandler(AUTH_EVENT, resourceRoot, function(mode, username, password)
    local player = client
    if not isElement(player) or source ~= resourceRoot then return end

    if authenticated[player] then
        sendResult(player, true, "شما قبلاً وارد حساب شده‌اید.", true)
        return
    end

    local state = getAttemptState(player)
    local now = getTickCount()

    if now < state.lockedUntil then
        sendResult(player, false, ("به دلیل تلاش‌های ناموفق، %d ثانیه صبر کن."):format(math.ceil((state.lockedUntil - now) / 1000)), false)
        return
    end
    if state.lastRequest > 0 and now - state.lastRequest < REQUEST_COOLDOWN_MS then
        sendResult(player, false, "کمی صبر کن و دوباره تلاش کن.", false)
        return
    end
    state.lastRequest = now

    if mode ~= "register" and mode ~= "login" then
        sendResult(player, false, "درخواست نامعتبر است.", false)
        return
    end
    if not isValidUsername(username) then
        sendResult(player, false, "نام کاربری باید ۳ تا ۲۴ حرف انگلیسی، عدد یا زیرخط باشد.", false)
        return
    end
    if not isValidPassword(password) then
        sendResult(player, false, "رمز عبور باید ۸ تا ۶۴ نویسه و بدون نویسه کنترلی باشد.", false)
        return
    end

    local currentAccount = getPlayerAccount(player)
    if currentAccount and not isGuestAccount(currentAccount) then
        sendResult(player, false, "ابتدا از حساب فعلی خارج شو و سپس ورود را انجام بده.", false)
        return
    end

    local serial = getPlayerSerial(player)
    if type(serial) ~= "string" or serial == "" then
        sendResult(player, false, "شناسه سیستم قابل دریافت نیست؛ اتصال را دوباره برقرار کن.", false)
        return
    end

    local connection = getDatabaseConnection()
    if not connection then
        sendResult(player, false, "اتصال دیتابیس آماده نیست؛ چند لحظه دیگر تلاش کن.", false)
        outputServerLog("[VENDRIX SQL] Authentication rejected because database connection is unavailable.")
        return
    end

    local normalized = username:lower()
    dbQuery(function(queryHandle)
        if not isElement(player) then return end
        local rows, errorCode, errorMessage = dbPoll(queryHandle, 0)
        if type(rows) ~= "table" then
            outputServerLog(("[VENDRIX SQL] Account lookup failed (%s): %s"):format(tostring(errorCode), tostring(errorMessage)))
            sendResult(player, false, "خواندن دیتابیس ناموفق بود؛ دوباره تلاش کن.", false)
            return
        end

        local sqlAccount = rows[1]

        if mode == "register" then
            if sqlAccount or findAccountByUsername(username) then
                sendResult(player, false, "این نام کاربری قبلاً ثبت شده است.", false)
                return
            end

            local serialAccount = findAccountBySerial(serial)
            if serialAccount then
                sendResult(player, false, "این سیستم قبلاً یک حساب ساخته است. با همان حساب وارد شو.", false)
                return
            end

            passwordHash(password, "bcrypt", { cost = 10 }, function(hash)
                if not isElement(player) then return end
                if type(hash) ~= "string" or hash == "" then
                    sendResult(player, false, "ساخت هش امن رمز عبور ناموفق بود.", false)
                    return
                end

                local inserted = dbExec(connection,
                    "INSERT INTO accounts (username, username_normalized, password_hash, status, last_login_serial) VALUES (?, ?, ?, 'active', ?)",
                    username, normalized, hash, serial
                )
                if not inserted then
                    sendResult(player, false, "ذخیره حساب در SQL انجام نشد؛ دوباره تلاش کن.", false)
                    return
                end

                local createdAccount = addAccount(username, password)
                if not createdAccount then
                    dbExec(connection, "DELETE FROM accounts WHERE username_normalized = ?", normalized)
                    sendResult(player, false, "ساخت حساب سازگار با MTA انجام نشد؛ ثبت‌نام لغو شد.", false)
                    return
                end

                if not setAccountData(createdAccount, SERIAL_DATA_KEY, serial, false) then
                    removeAccount(createdAccount)
                    dbExec(connection, "DELETE FROM accounts WHERE username_normalized = ?", normalized)
                    sendResult(player, false, "اتصال امن حساب به سیستم انجام نشد؛ ثبت‌نام لغو شد.", false)
                    return
                end

                local loggedIn = logIn(player, createdAccount, password) == true
                    or isPlayerLoggedInto(player, createdAccount)
                if not loggedIn or not isPlayerLoggedInto(player, createdAccount) then
                    recordLoginEvent(nil, username, false, "registration_native_login_failed", serial)
                    sendResult(player, false, "حساب SQL ساخته شد، اما ورود خودکار انجام نشد. دوباره با همین مشخصات وارد شو.", false)
                    return
                end

                local idRows = dbPoll(dbQuery(connection, "SELECT id FROM accounts WHERE username_normalized = ? LIMIT 1", normalized), -1)
                local accountId = type(idRows) == "table" and idRows[1] and tonumber(idRows[1].id) or nil
                recordLoginEvent(accountId, username, true, "registration", serial)
                finishAuthentication(player)
            end)
            return
        end

        if sqlAccount then
            if sqlAccount.status ~= "active" then
                recordLoginEvent(tonumber(sqlAccount.id), username, false, "account_not_active", serial)
                sendResult(player, false, "این حساب در حال حاضر فعال نیست.", false)
                return
            end

            passwordVerify(password, sqlAccount.password_hash, {}, function(matches)
                if not isElement(player) then return end
                if matches ~= true then
                    state.failures = state.failures + 1
                    recordLoginEvent(tonumber(sqlAccount.id), username, false, "invalid_password", serial)
                    if state.failures >= MAX_FAILED_ATTEMPTS then
                        state.failures = 0
                        state.lockedUntil = getTickCount() + LOCK_DURATION_MS
                        sendResult(player, false, "تلاش‌های ناموفق زیاد بود؛ ۱۰ ثانیه صبر کن.", false)
                    else
                        sendResult(player, false, ("نام کاربری یا رمز عبور اشتباه است. (%d/%d)"):format(state.failures, MAX_FAILED_ATTEMPTS), false)
                    end
                    return
                end
                state.failures = 0
                completeSqlLogin(player, username, password, serial, sqlAccount)
            end)
            return
        end

        -- Legacy migration: validate the password against the existing MTA
        -- account once, then hash it and insert it into SQL before auth succeeds.
        local nativeAccount = findAccountByUsername(username)
        if not nativeAccount then
            state.failures = state.failures + 1
            recordLoginEvent(nil, username, false, "account_not_found", serial)
            sendResult(player, false, ("نام کاربری یا رمز عبور اشتباه است. (%d/%d)"):format(state.failures, MAX_FAILED_ATTEMPTS), false)
            return
        end

        local boundAccount = findAccountBySerial(serial)
        if boundAccount and boundAccount ~= nativeAccount then
            sendResult(player, false, "این سیستم قبلاً به حساب دیگری متصل شده است.", false)
            return
        end

        local loggedIn = logIn(player, nativeAccount, password) == true
            or isPlayerLoggedInto(player, nativeAccount)
        if not loggedIn or not isPlayerLoggedInto(player, nativeAccount) then
            state.failures = state.failures + 1
            recordLoginEvent(nil, username, false, "legacy_password_rejected", serial)
            sendResult(player, false, ("نام کاربری یا رمز عبور اشتباه است. (%d/%d)"):format(state.failures, MAX_FAILED_ATTEMPTS), false)
            return
        end

        passwordHash(password, "bcrypt", { cost = 10 }, function(hash)
            if not isElement(player) then return end
            if type(hash) ~= "string" or hash == "" then
                logOut(player)
                sendResult(player, false, "ساخت هش امن رمز عبور ناموفق بود؛ دوباره تلاش کن.", false)
                return
            end

            local inserted = dbExec(connection,
                "INSERT INTO accounts (username, username_normalized, password_hash, status, last_login_at, last_login_serial) VALUES (?, ?, ?, 'active', strftime('%s','now'), ?)",
                getAccountName(nativeAccount), getAccountName(nativeAccount):lower(), hash, serial
            )
            if not inserted then
                logOut(player)
                sendResult(player, false, "انتقال حساب قدیمی به SQL ناموفق بود؛ دوباره تلاش کن.", false)
                return
            end

            setAccountData(nativeAccount, SERIAL_DATA_KEY, serial, false)
            local rows2 = dbPoll(dbQuery(connection, "SELECT id FROM accounts WHERE username_normalized = ? LIMIT 1", getAccountName(nativeAccount):lower()), -1)
            local accountId = type(rows2) == "table" and rows2[1] and tonumber(rows2[1].id) or nil
            recordLoginEvent(accountId, getAccountName(nativeAccount), true, "legacy_account_migrated", serial)
            finishAuthentication(player)
            outputServerLog(("[VENDRIX SQL] Legacy account migrated to SQL: %s"):format(getAccountName(nativeAccount)))
        end)
    end, connection,
        "SELECT id, username, password_hash, status FROM accounts WHERE username_normalized = ? LIMIT 1",
        normalized
    )
end)

-- Use the username registered in the native VENDRIX account system for normal T chat.
-- Only replace public chat (type 0); team/action chat keeps its existing MTA behavior.
addEventHandler("onPlayerChat", root, function(message, messageType)
    if messageType ~= 0 then
        return
    end

    cancelEvent()

    if not authenticated[source] then
        return
    end

    local account = getPlayerAccount(source)
    if not account or isGuestAccount(account) then
        return
    end

    local accountName = getAccountName(account)
    if type(accountName) ~= "string" or accountName == "" then
        accountName = "Player"
    end

    if type(message) ~= "string" then
        return
    end

    -- Disable color-code parsing so player input cannot inject chat colors.
    outputChatBox(accountName .. ": " .. message, root, 245, 247, 251, false)
end)

addEventHandler("onPlayerSpawn", root, function()
    if not authenticated[source] then
        cancelEvent()
        setElementAlpha(source, 0)
        setElementFrozen(source, true)
    end
end)

addEventHandler("onPlayerQuit", root, function()
    attempts[source] = nil
    authenticated[source] = nil
end)

addEventHandler("onResourceStart", resourceRoot, function()
    outputServerLog("[VENDRIX] Account-system started. Native MTA account storage is enabled.")
end)

addEventHandler("onResourceStop", resourceRoot, function()
    for player in pairs(authenticated) do
        if isElement(player) then
            setElementAlpha(player, 255)
            setElementFrozen(player, false)
        end
    end
end)
