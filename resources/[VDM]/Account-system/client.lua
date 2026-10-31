-- VENDRIX RPG - CEF account interface
-- The browser is created only when needed and destroyed after authentication.
-- Server remains authoritative for all account operations.

local AUTH_EVENT = "vendrix:account:submit"
local RESULT_EVENT = "vendrix:account:result"
local READY_EVENT = "vendrix:account:ready"
local SHOW_EVENT = "vendrix:account:show"
local UI_SUBMIT_EVENT = "vendrix:account:uiSubmit"

local browserGUI, browser
local panelOpen = false
local browserReady = false
local pendingShow = false
local busy = false

local function destroyBrowser()
    panelOpen = false
    browserReady = false
    pendingShow = false
    busy = false
    showCursor(false)

    if isElement(browserGUI) then
        destroyElement(browserGUI)
    end

    browserGUI, browser = nil, nil
end

local function showBrowser()
    if panelOpen and isElement(browserGUI) then
        showCursor(true)
        return
    end

    panelOpen = true
    pendingShow = true
    showCursor(true)

    local sx, sy = guiGetScreenSize()
    browserGUI = guiCreateBrowser(0, 0, sx, sy, true, true, false)
    if not isElement(browserGUI) then
        outputDebugString("[VENDRIX] Failed to create account browser.", 1)
        panelOpen = false
        showCursor(false)
        return
    end

    browser = guiGetBrowser(browserGUI)
    addEventHandler("onClientBrowserCreated", browser, function()
        if not isElement(browser) then return end
        loadBrowserURL(browser, "http://mta/local/ui/index.html")
    end)

    addEventHandler("onClientBrowserDocumentReady", browser, function()
        if not panelOpen or not isElement(browser) then return end
        browserReady = true
        executeBrowserJavascript(browser, "window.VENDRIX && window.VENDRIX.setBusy(false);")
        executeBrowserJavascript(browser, "window.VENDRIX && window.VENDRIX.setStatus('نام کاربری: ۳ تا ۲۴ حرف انگلیسی، عدد یا زیرخط؛ رمز عبور حداقل ۸ نویسه.', 'info');")
        pendingShow = false
    end)
end

addEvent(UI_SUBMIT_EVENT, true)
addEvent(SHOW_EVENT, true)
addEventHandler(SHOW_EVENT, resourceRoot, showBrowser)

addEvent(UI_SUBMIT_EVENT, true)
addEventHandler(UI_SUBMIT_EVENT, root, function(mode, username, password)
    if not panelOpen or busy or (mode ~= "login" and mode ~= "register") then
        return
    end

    if type(username) ~= "string" or type(password) ~= "string" then
        return
    end

    busy = true
    if isElement(browser) and browserReady then
        executeBrowserJavascript(browser, "window.VENDRIX && window.VENDRIX.setBusy(true);")
        executeBrowserJavascript(browser, "window.VENDRIX && window.VENDRIX.setStatus(" ..
            toJSON(mode == "login" and "در حال بررسی اطلاعات ورود..." or "در حال ساخت حساب...") ..
            ", 'info');")
    end

    triggerServerEvent(AUTH_EVENT, resourceRoot, mode, username, password)
end)

addEvent(RESULT_EVENT, true)
addEventHandler(RESULT_EVENT, resourceRoot, function(success, message, authenticatedNow)
    if authenticatedNow then
        destroyBrowser()
        return
    end

    if not panelOpen then
        showBrowser()
    end

    busy = false
    if isElement(browser) and browserReady then
        executeBrowserJavascript(browser, "window.VENDRIX && window.VENDRIX.setBusy(false);")
        executeBrowserJavascript(browser, "window.VENDRIX && window.VENDRIX.setStatus(" ..
            toJSON(tostring(message or "خطای نامشخص")) ..
            ", " .. toJSON(success == true and "success" or "error") .. ");")
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent(READY_EVENT, resourceRoot)
end)

addEventHandler("onClientResourceStop", resourceRoot, destroyBrowser)
