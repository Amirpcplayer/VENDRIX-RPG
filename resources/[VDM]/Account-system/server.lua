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

local SPAWN_X, SPAWN_Y, SPAWN_Z, SPAWN_ROTATION = 1481.0, -1771.0, 18.8, 0

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
        spawnPlayer(player, SPAWN_X, SPAWN_Y, SPAWN_Z, SPAWN_ROTATION, 0, 0, 0)
    end

    fadeCamera(player, true)
    setCameraTarget(player, player)
    sendResult(player, true, "ورود موفق بود. به VENDRIX خوش آمدی.", true)
    outputServerLog(("[VENDRIX] Player authenticated: %s"):format(getPlayerName(player)))
end

addEvent(READY_EVENT, true)
addEventHandler(READY_EVENT, resourceRoot, function()
    local player = client
    if not isElement(player) then
        return
    end

    if authenticated[player] then
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
    if not isElement(player) or source ~= resourceRoot then
        return
    end

    if authenticated[player] then
        sendResult(player, true, "شما قبلاً وارد حساب شده‌اید.", true)
        return
    end

    local state = getAttemptState(player)
    local now = getTickCount()

    if now < state.lockedUntil then
        local remaining = math.ceil((state.lockedUntil - now) / 1000)
        sendResult(player, false, ("به دلیل تلاش‌های ناموفق، %d ثانیه صبر کن."):format(remaining), false)
        return
    end

    if now - state.lastRequest < REQUEST_COOLDOWN_MS then
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

    local account = getAccount(username)

    if mode == "register" then
        if account then
            sendResult(player, false, "این نام کاربری قبلاً ثبت شده است.", false)
            return
        end

        account = addAccount(username, password)
        if not account then
            sendResult(player, false, "ساخت حساب انجام نشد؛ دوباره تلاش کن.", false)
            return
        end

        if not logIn(player, account, password) then
            sendResult(player, false, "حساب ساخته شد، اما ورود خودکار ناموفق بود. از بخش ورود استفاده کن.", false)
            return
        end

        finishAuthentication(player)
        return
    end

    if not account or not logIn(player, account, password) then
        state.failures = state.failures + 1
        if state.failures >= MAX_FAILED_ATTEMPTS then
            state.failures = 0
            state.lockedUntil = now + LOCK_DURATION_MS
            sendResult(player, false, "تلاش‌های ناموفق زیاد بود؛ ۱۰ ثانیه صبر کن.", false)
        else
            sendResult(player, false, ("نام کاربری یا رمز عبور اشتباه است. (%d/%d)"):format(state.failures, MAX_FAILED_ATTEMPTS), false)
        end
        return
    end

    finishAuthentication(player)
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
