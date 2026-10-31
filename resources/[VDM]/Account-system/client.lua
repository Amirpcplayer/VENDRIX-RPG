-- VENDRIX RPG - Lightweight custom account UI
-- Rendering is active only while the authentication panel is open.
-- Authentication and all validation remain server-side.

local AUTH_EVENT = "vendrix:account:submit"
local RESULT_EVENT = "vendrix:account:result"
local READY_EVENT = "vendrix:account:ready"
local SHOW_EVENT = "vendrix:account:show"

local sx, sy = guiGetScreenSize()
local scale = math.min(sx / 1600, sy / 900)
scale = math.max(0.72, math.min(scale, 1.15))

local panelW, panelH = math.floor(560 * scale), math.floor(430 * scale)
local panelX, panelY = math.floor((sx - panelW) / 2), math.floor((sy - panelH) / 2)

local usernameEdit, passwordEdit
local panelOpen = false
local busy = false
local statusText = "نام کاربری: ۳ تا ۲۴ حرف انگلیسی، عدد یا زیرخط  |  رمز: حداقل ۸ نویسه"
local statusGood = false

local GOLD = tocolor(220, 177, 75, 255)
local RED = tocolor(235, 54, 67, 255)
local WHITE = tocolor(242, 244, 248, 255)
local MUTED = tocolor(158, 164, 176, 255)
local DARK = tocolor(9, 11, 16, 238)
local FIELD = tocolor(18, 21, 29, 245)
local LINE = tocolor(220, 177, 75, 90)

local function px(value)
    return math.floor(value * scale)
end

local function destroyEdits()
    if isElement(usernameEdit) then destroyElement(usernameEdit) end
    if isElement(passwordEdit) then destroyElement(passwordEdit) end
    usernameEdit, passwordEdit = nil, nil
end

local function closePanel()
    panelOpen = false
    busy = false
    destroyEdits()
    showCursor(false)
    removeEventHandler("onClientRender", root, renderPanel)
end

local function setEditTheme(edit)
    if not isElement(edit) then return end
    guiSetFont(edit, "default")
    guiSetProperty(edit, "NormalTextColour", "FFECEFF4")
    guiSetProperty(edit, "CaretColour", "FFDDB34B")
    guiSetProperty(edit, "SelectionColour", "FF8E2630")
end

local function showPanel()
    if panelOpen then
        if isElement(usernameEdit) then guiBringToFront(usernameEdit) end
        showCursor(true)
        return
    end

    sx, sy = guiGetScreenSize()
    scale = math.min(sx / 1600, sy / 900)
    scale = math.max(0.72, math.min(scale, 1.15))
    panelW, panelH = math.floor(560 * scale), math.floor(430 * scale)
    panelX, panelY = math.floor((sx - panelW) / 2), math.floor((sy - panelH) / 2)

    local fieldX = panelX + px(46)
    local fieldW = panelW - px(92)
    usernameEdit = guiCreateEdit(fieldX, panelY + px(177), fieldW, px(37), "", false)
    passwordEdit = guiCreateEdit(fieldX, panelY + px(247), fieldW, px(37), "", false)
    guiEditSetMaxLength(usernameEdit, 24)
    guiEditSetMaxLength(passwordEdit, 64)
    guiEditSetMasked(passwordEdit, true)
    setEditTheme(usernameEdit)
    setEditTheme(passwordEdit)

    panelOpen = true
    busy = false
    statusText = "نام کاربری: ۳ تا ۲۴ حرف انگلیسی، عدد یا زیرخط  |  رمز: حداقل ۸ نویسه"
    statusGood = false
    showCursor(true)
    addEventHandler("onClientRender", root, renderPanel)
end

function renderPanel()
    if not panelOpen then return end

    -- Subtle dim overlay; the player's own background image/music can run independently.
    dxDrawRectangle(0, 0, sx, sy, tocolor(0, 0, 0, 105), false)
    dxDrawRectangle(panelX, panelY, panelW, panelH, DARK, false)
    dxDrawRectangle(panelX, panelY, panelW, px(4), RED, false)
    dxDrawRectangle(panelX + px(24), panelY + px(91), panelW - px(48), 1, LINE, false)
    dxDrawRectangle(panelX + px(46), panelY + px(174), panelW - px(92), px(43), FIELD, false)
    dxDrawRectangle(panelX + px(46), panelY + px(244), panelW - px(92), px(43), FIELD, false)

    dxDrawText("V", panelX + px(40), panelY + px(22), panelX + px(98), panelY + px(80),
        GOLD, 1.35 * scale, "default-bold", "center", "center", false, false, false)
    dxDrawText("VENDRIX", panelX + px(108), panelY + px(25), panelX + panelW - px(35), panelY + px(57),
        WHITE, 1.05 * scale, "default-bold", "left", "center")
    dxDrawText("ROLEPLAY  •  ACCOUNT ACCESS", panelX + px(110), panelY + px(53),
        panelX + panelW - px(35), panelY + px(78), GOLD, 0.78 * scale, "default", "left", "center")
    dxDrawText("ورود به دنیای VENDRIX", panelX + px(36), panelY + px(105),
        panelX + panelW - px(36), panelY + px(143), WHITE, 1.15 * scale, "default-bold", "center", "center")
    dxDrawText("حساب کاربری خود را وارد کن یا یک حساب جدید بساز",
        panelX + px(36), panelY + px(143), panelX + panelW - px(36), panelY + px(166),
        MUTED, 0.83 * scale, "default", "center", "center")

    dxDrawText("نام کاربری", panelX + px(48), panelY + px(153), panelX + panelW - px(46), panelY + px(174),
        MUTED, 0.78 * scale, "default", "left", "center")
    dxDrawText("رمز عبور", panelX + px(48), panelY + px(220), panelX + panelW - px(46), panelY + px(242),
        MUTED, 0.78 * scale, "default", "left", "center")

    local cx, cy = getCursorPosition()
    if cx then cx, cy = cx * sx, cy * sy end
    local loginX, loginY = panelX + px(46), panelY + px(306)
    local btnW, btnH = (panelW - px(104)) / 2, px(46)
    local registerX = loginX + btnW + px(12)

    local loginHover = cx and cx >= loginX and cx <= loginX + btnW and cy >= loginY and cy <= loginY + btnH
    local registerHover = cx and cx >= registerX and cx <= registerX + btnW and cy >= loginY and cy <= loginY + btnH
    dxDrawRectangle(loginX, loginY, btnW, btnH, (loginHover and not busy) and tocolor(184, 38, 50, 255) or tocolor(145, 28, 39, 255), false)
    dxDrawRectangle(registerX, loginY, btnW, btnH, (registerHover and not busy) and tocolor(244, 202, 100, 255) or GOLD, false)
    dxDrawText(busy and "در حال بررسی..." or "ورود به حساب", loginX, loginY, loginX + btnW, loginY + btnH,
        WHITE, 0.9 * scale, "default-bold", "center", "center")
    dxDrawText("ساخت حساب", registerX, loginY, registerX + btnW, loginY + btnH,
        tocolor(15, 15, 18, 255), 0.9 * scale, "default-bold", "center", "center")

    local statusColor = statusGood and tocolor(120, 220, 155, 255) or MUTED
    dxDrawText(statusText, panelX + px(28), panelY + px(360), panelX + panelW - px(28), panelY + px(401),
        statusColor, 0.76 * scale, "default", "center", "center", true, true)
    dxDrawText("SECURE AUTHENTICATION  •  VENDRIX", panelX, panelY + panelH - px(25),
        panelX + panelW, panelY + panelH - px(8), tocolor(120, 125, 137, 200),
        0.65 * scale, "default", "center", "center")
end

local function submit(mode)
    if busy or not panelOpen or not isElement(usernameEdit) or not isElement(passwordEdit) then return end
    local username, password = guiGetText(usernameEdit), guiGetText(passwordEdit)
    if username == "" or password == "" then
        statusText = "نام کاربری و رمز عبور را وارد کن."
        statusGood = false
        return
    end

    busy = true
    statusText = mode == "login" and "در حال بررسی اطلاعات ورود..." or "در حال ساخت حساب..."
    statusGood = false
    triggerServerEvent(AUTH_EVENT, resourceRoot, mode, username, password)
end

addEvent(SHOW_EVENT, true)
addEventHandler(SHOW_EVENT, resourceRoot, showPanel)

addEvent(RESULT_EVENT, true)
addEventHandler(RESULT_EVENT, resourceRoot, function(success, message, authenticatedNow)
    if authenticatedNow then
        closePanel()
        return
    end
    if not panelOpen then showPanel() end
    busy = false
    statusText = tostring(message or "خطای نامشخص")
    statusGood = success == true
end)

addEventHandler("onClientClick", root, function(button, state, x, y)
    if not panelOpen or button ~= "left" or state ~= "down" or busy then return end

    local loginX, loginY = panelX + px(46), panelY + px(306)
    local btnW, btnH = (panelW - px(104)) / 2, px(46)
    local registerX = loginX + btnW + px(12)

    if x >= loginX and x <= loginX + btnW and y >= loginY and y <= loginY + btnH then
        submit("login")
    elseif x >= registerX and x <= registerX + btnW and y >= loginY and y <= loginY + btnH then
        submit("register")
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent(READY_EVENT, resourceRoot)
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    panelOpen = false
    destroyEdits()
    showCursor(false)
end)
