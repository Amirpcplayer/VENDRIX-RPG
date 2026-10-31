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
