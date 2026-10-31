-- VENDRIX RPG - Native MTA account administration
-- Passwords are managed by MTA; never store plaintext passwords in SQL/files.

local MIN_USERNAME_LENGTH = 3
local MAX_USERNAME_LENGTH = 24
local MIN_PASSWORD_LENGTH = 8
local MAX_PASSWORD_LENGTH = 64

local function isValidUsername(name)
    return type(name) == "string"
        and #name >= MIN_USERNAME_LENGTH
        and #name <= MAX_USERNAME_LENGTH
        and name:match("^[A-Za-z0-9_]+$") ~= nil
end

local function isValidPassword(password)
    return type(password) == "string"
        and #password >= MIN_PASSWORD_LENGTH
        and #password <= MAX_PASSWORD_LENGTH
        and password:find("[%c]") == nil
end

local function canManageAccounts(executor)
    -- Server console is trusted. In-game access requires the executor's
    -- logged-in account to belong to the ACL Admin group.
    if not isElement(executor) then
        return true
    end

    if getElementType(executor) ~= "player" then
        return false
    end

    local account = getPlayerAccount(executor)
    if not account or isGuestAccount(account) then
        return false
    end

    local adminGroup = aclGetGroup("Admin")
    return adminGroup ~= false
        and isObjectInACLGroup("user." .. getAccountName(account), adminGroup)
end

local function reply(executor, message, red)
    if isElement(executor) and getElementType(executor) == "player" then
        outputChatBox("[VENDRIX Account Admin] " .. message, executor, red and 255 or 230, red and 80 or 190, red and 80 or 60, true)
    else
        outputServerLog("[VENDRIX Account Admin] " .. message)
    end
end

addCommandHandler("setplayerpass", function(executor, _, username, ...)
    if not canManageAccounts(executor) then
        reply(executor, "دسترسی ندارید.", true)
        return
    end

    local password = table.concat({...}, " ")
    if not username or password == "" then
        reply(executor, "استفاده: setplayerpass <username> <new-password>", true)
        return
    end

    if not isValidPassword(password) then
        reply(executor, "رمز باید ۸ تا ۶۴ نویسه و بدون نویسه کنترلی باشد.", true)
        return
    end

    local account = getAccount(username)
    if not account then
        reply(executor, "این حساب پیدا نشد.", true)
        return
    end

    if not setAccountPassword(account, password) then
        reply(executor, "تغییر رمز انجام نشد؛ مجوزهای ACL منبع را بررسی کنید.", true)
        return
    end

    reply(executor, "رمز حساب " .. username .. " تغییر کرد. رمز جدید در لاگ ثبت نشده است.", false)
end)

addCommandHandler("renameaccount", function(executor, _, oldName, newName, ...)
    if not canManageAccounts(executor) then
        reply(executor, "دسترسی ندارید.", true)
        return
    end

    local newPassword = table.concat({...}, " ")
    if not oldName or not newName or newPassword == "" then
        reply(executor, "استفاده: renameaccount <old-username> <new-username> <new-password>", true)
        return
    end

    if not isValidUsername(oldName) or not isValidUsername(newName) then
        reply(executor, "نام کاربری باید ۳ تا ۲۴ حرف انگلیسی، عدد یا زیرخط باشد.", true)
        return
    end

    if oldName == newName then
        reply(executor, "نام جدید با نام فعلی یکسان است.", true)
        return
    end

    if not isValidPassword(newPassword) then
        reply(executor, "رمز جدید باید ۸ تا ۶۴ نویسه و بدون نویسه کنترلی باشد.", true)
        return
    end

    local oldAccount = getAccount(oldName)
    if not oldAccount then
        reply(executor, "حساب قبلی پیدا نشد.", true)
        return
    end

    if getAccount(newName) then
        reply(executor, "این نام کاربری از قبل وجود دارد.", true)
        return
    end

    local accountData = getAllAccountData(oldAccount)
    if type(accountData) ~= "table" then
        reply(executor, "خواندن اطلاعات حساب انجام نشد؛ حساب قبلی دست‌نخورده باقی ماند.", true)
        return
    end

    -- Create the replacement first. The old account is only removed after
    -- the new account and its account-data copy have been created.
    local newAccount = addAccount(newName, newPassword)
    if not newAccount then
        reply(executor, "ساخت حساب جدید ناموفق بود؛ حساب قبلی حفظ شد.", true)
        return
    end

    local copied = true
    for key, value in pairs(accountData) do
        if type(key) ~= "string" or type(value) ~= "string"
            or not setAccountData(newAccount, key, value) then
            copied = false
            break
        end
    end

    if not copied then
        removeAccount(newAccount)
        reply(executor, "کپی اطلاعات کامل نشد؛ حساب جدید لغو و حساب قبلی حفظ شد.", true)
        return
    end

    if not removeAccount(oldAccount) then
        removeAccount(newAccount)
        reply(executor, "حذف حساب قبلی انجام نشد؛ حساب قبلی حفظ شد و حساب جدید لغو شد.", true)
        return
    end

    reply(executor, "حساب " .. oldName .. " به " .. newName .. " تغییر کرد و داده‌های Account Data کپی شدند.", false)
    outputServerLog("[VENDRIX Account Admin] Account renamed; password omitted from logs.")
    reply(executor, "توجه: مجوزهای ACL که به نام حساب قبلی متصل بوده‌اند، خودکار منتقل نمی‌شوند.", true)
end)

addEventHandler("onResourceStart", resourceRoot, function()
    outputServerLog("[VENDRIX] Account-admin commands loaded.")
end)


-- SQL account administration. SQL is authoritative for VENDRIX authentication.
local function getSqlConnection()
    local accountResource = getResourceFromName("Account-system")
    if not accountResource or getResourceState(accountResource) ~= "running" then
        return false
    end
    local ok, connection = pcall(function()
        return exports["Account-system"]:vendrixGetDatabaseConnection()
    end)
    if not ok or not connection or not isElement(connection) then
        return false
    end
    return connection
end

local function findNativeAccountCaseInsensitive(username)
    local direct = getAccount(username)
    if direct then return direct end
    local wanted = string.lower(username)
    for _, account in ipairs(getAccounts()) do
        if isElement(account) and string.lower(getAccountName(account)) == wanted then
            return account
        end
    end
    return false
end

addCommandHandler("sqlaccounts", function(executor)
    if not canManageAccounts(executor) then
        reply(executor, "دسترسی ندارید.", true)
        return
    end
    local connection = getSqlConnection()
    if not connection then
        reply(executor, "اتصال دیتابیس SQL آماده نیست؛ Account-system را بررسی کنید.", true)
        return
    end
    dbQuery(function(handle)
        local rows, errorCode, errorMessage = dbPoll(handle, 0)
        if type(rows) ~= "table" then
            reply(executor, "خواندن حساب‌های SQL ناموفق بود: " .. tostring(errorMessage), true)
            return
        end
        reply(executor, "تعداد حساب‌های SQL: " .. #rows, false)
        for index, row in ipairs(rows) do
            reply(executor, ("%d) %s | وضعیت: %s | ID: %s"):format(index, tostring(row.username), tostring(row.status), tostring(row.id)), false)
        end
    end, connection, "SELECT id, username, status FROM accounts ORDER BY id DESC LIMIT 100")
end)

addCommandHandler("sqlaccountstatus", function(executor, _, username, status)
    if not canManageAccounts(executor) then
        reply(executor, "دسترسی ندارید.", true)
        return
    end
    if not username or (status ~= "active" and status ~= "locked" and status ~= "disabled") then
        reply(executor, "استفاده: sqlaccountstatus <username> <active|locked|disabled>", true)
        return
    end
    local connection = getSqlConnection()
    if not connection then
        reply(executor, "اتصال دیتابیس SQL آماده نیست.", true)
        return
    end
    dbQuery(function(handle)
        local rows, errorCode, errorMessage = dbPoll(handle, 0)
        if type(rows) ~= "table" then
            reply(executor, "به‌روزرسانی وضعیت ناموفق بود: " .. tostring(errorMessage), true)
            return
        end
        if #rows == 0 then
            reply(executor, "این حساب در SQL پیدا نشد.", true)
            return
        end
        local ok = dbExec(connection, "UPDATE accounts SET status = ? WHERE id = ?", status, tonumber(rows[1].id))
        reply(executor, ok and ("وضعیت حساب " .. rows[1].username .. " به " .. status .. " تغییر کرد.") or "تغییر وضعیت SQL ناموفق بود.", not ok)
        if ok and status ~= "active" then
            for _, player in ipairs(getElementsByType("player")) do
                local account = getPlayerAccount(player)
                if account and not isGuestAccount(account) and string.lower(getAccountName(account)) == string.lower(rows[1].username) then
                    logOut(player)
                    kickPlayer(player, "VENDRIX", "وضعیت حساب شما غیرفعال شده است.")
                end
            end
        end
    end, connection, "SELECT id, username FROM accounts WHERE username_normalized = ? LIMIT 1", string.lower(username))
end)

addCommandHandler("sqldeleteaccount", function(executor, _, username, confirmation)
    if not canManageAccounts(executor) then
        reply(executor, "دسترسی ندارید.", true)
        return
    end
    if not username or confirmation ~= "CONFIRM" then
        reply(executor, "استفاده: sqldeleteaccount <username> CONFIRM | حذف دائمی اطلاعات وابسته را هم پاک می‌کند.", true)
        return
    end
    local connection = getSqlConnection()
    if not connection then
        reply(executor, "اتصال دیتابیس SQL آماده نیست.", true)
        return
    end
    dbQuery(function(handle)
        local rows, errorCode, errorMessage = dbPoll(handle, 0)
        if type(rows) ~= "table" then
            reply(executor, "بررسی حساب ناموفق بود: " .. tostring(errorMessage), true)
            return
        end
        local row = rows[1]
        if not row then
            reply(executor, "این حساب در SQL پیدا نشد.", true)
            return
        end
        local nativeAccount = findNativeAccountCaseInsensitive(row.username)
        local adminGroup = aclGetGroup("Admin")
        if nativeAccount and adminGroup and isObjectInACLGroup("user." .. getAccountName(nativeAccount), adminGroup) then
            reply(executor, "حساب دارای دسترسی ACL Admin است؛ برای جلوگیری از قفل‌شدن مدیریت، حذف خودکار مجاز نیست.", true)
            return
        end
        local deleted = dbExec(connection, "DELETE FROM accounts WHERE id = ?", tonumber(row.id))
        if not deleted then
            reply(executor, "حذف حساب SQL ناموفق بود.", true)
            return
        end
        if nativeAccount then
            for _, player in ipairs(getElementsByType("player")) do
                if getPlayerAccount(player) == nativeAccount then
                    logOut(player)
                    kickPlayer(player, "VENDRIX", "حساب شما حذف شده است.")
                end
            end
            if not removeAccount(nativeAccount) then
                outputServerLog("[VENDRIX Account Admin] SQL account deleted but native account removal failed for " .. row.username)
                reply(executor, "حساب SQL حذف شد، اما حذف حساب داخلی MTA ناموفق بود؛ لاگ سرور را بررسی کنید.", true)
                return
            end
        end
        reply(executor, "حساب " .. row.username .. " و داده‌های وابسته آن از SQL حذف شد.", false)
        outputServerLog("[VENDRIX Account Admin] SQL account deleted: " .. row.username)
    end, connection, "SELECT id, username FROM accounts WHERE username_normalized = ? LIMIT 1", string.lower(username))
end)
