-- VENDRIX RPG - Account System UI
-- Authentication decisions are always made by the server.

local AUTH_EVENT = "vendrix:account:submit"
local RESULT_EVENT = "vendrix:account:result"
local READY_EVENT = "vendrix:account:ready"
local SHOW_EVENT = "vendrix:account:show"

local window, usernameEdit, passwordEdit, statusLabel
local loginButton, registerButton
local busy = false

local function destroyPanel()
    if isElement(window) then
        destroyElement(window)
    end

    window = nil
    usernameEdit = nil
    passwordEdit = nil
    statusLabel = nil
    loginButton = nil
    registerButton = nil
    busy = false
    showCursor(false)
end

local function setBusy(value)
    busy = value
    if isElement(loginButton) then
        guiSetEnabled(loginButton, not value)
    end
    if isElement(registerButton) then
        guiSetEnabled(registerButton, not value)
    end
end

local function showPanel()
    if isElement(window) then
        guiBringToFront(window)
        showCursor(true)
        return
    end

    local screenW, screenH = guiGetScreenSize()
    local width, height = 390, 285
    local x, y = (screenW - width) / 2, (screenH - height) / 2

    window = guiCreateWindow(x, y, width, height, "VENDRIX | حساب کاربری", false)
    guiWindowSetSizable(window, false)

    guiCreateLabel(20, 30, 350, 28, "برای ورود به دنیای VENDRIX وارد شو یا حساب بساز.", false, window)

    guiCreateLabel(20, 68, 100, 24, "نام کاربری", false, window)
    usernameEdit = guiCreateEdit(120, 64, 245, 28, "", false, window)
    guiEditSetMaxLength(usernameEdit, 24)

    guiCreateLabel(20, 108, 100, 24, "رمز عبور", false, window)
    passwordEdit = guiCreateEdit(120, 104, 245, 28, "", false, window)
    guiEditSetMasked(passwordEdit, true)
    guiEditSetMaxLength(passwordEdit, 64)

    loginButton = guiCreateButton(20, 148, 165, 36, "ورود", false, window)
    registerButton = guiCreateButton(200, 148, 165, 36, "ساخت حساب", false, window)

    statusLabel = guiCreateLabel(20, 194, 350, 65, "نام کاربری: ۳ تا ۲۴ حرف انگلیسی، عدد یا زیرخط\nرمز عبور: حداقل ۸ نویسه", false, window)
    guiLabelSetHorizontalAlign(statusLabel, "left", true)
    guiLabelSetVerticalAlign(statusLabel, "center")

    addEventHandler("onClientGUIClick", loginButton, function()
        if busy then return end
        local username = guiGetText(usernameEdit)
        local password = guiGetText(passwordEdit)
        setBusy(true)
        guiSetText(statusLabel, "در حال بررسی اطلاعات...")
        triggerServerEvent(AUTH_EVENT, resourceRoot, "login", username, password)
    end, false)

    addEventHandler("onClientGUIClick", registerButton, function()
        if busy then return end
        local username = guiGetText(usernameEdit)
        local password = guiGetText(passwordEdit)
        setBusy(true)
        guiSetText(statusLabel, "در حال ساخت حساب...")
        triggerServerEvent(AUTH_EVENT, resourceRoot, "register", username, password)
    end, false)

    showCursor(true)
    guiBringToFront(window)
end

addEvent(SHOW_EVENT, true)
addEventHandler(SHOW_EVENT, resourceRoot, showPanel)

addEvent(RESULT_EVENT, true)
addEventHandler(RESULT_EVENT, resourceRoot, function(success, message, authenticatedNow)
    if not isElement(window) and not authenticatedNow then
        showPanel()
    end

    if authenticatedNow then
        destroyPanel()
        return
    end

    if isElement(statusLabel) then
        guiSetText(statusLabel, tostring(message or "خطای نامشخص"))
    end
    setBusy(false)
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent(READY_EVENT, resourceRoot)
end)

addEventHandler("onClientResourceStop", resourceRoot, destroyPanel)
