-- VENDRIX Signature HUD
-- Native DX rendering: no CEF, per-frame database access, or repeating timers.

local sx, sy = guiGetScreenSize()
local onlineCount = 0
local lastHealth, lastArmor, lastMoney = -1, -1, -1
local gold = tocolor(212, 175, 55, 255)
local red = tocolor(245, 35, 65, 255)
local white = tocolor(245, 245, 245, 245)
local muted = tocolor(180, 184, 194, 235)
local panel = tocolor(8, 10, 15, 220)
local panelEdge = tocolor(212, 175, 55, 190)
local barBack = tocolor(55, 58, 66, 235)

local weaponNames = {
    [0] = "بدون اسلحه", [1] = "پنجه", [2] = "چوب بیسبال", [3] = "چماق",
    [4] = "چاقوی بازی", [5] = "چوب بیسبال", [6] = "بیل", [7] = "چوب بیلیارد",
    [8] = "کاتانا", [9] = "اره", [22] = "کلت", [23] = "کلت صداخفه‌کن",
    [24] = "دیزرت ایگل", [25] = "شاتگان", [26] = "شاتگان کوتاه",
    [27] = "شاتگان جنگی", [28] = "اوزی", [29] = "MP5", [30] = "AK-47",
    [31] = "M4", [32] = "تک‌دستی", [33] = "رایفل", [34] = "اسنایپر"
}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function drawText(text, x, y, w, h, color, scale, align)
    dxDrawText(tostring(text), x, y, x + w, y + h, color, scale or 1,
        "default-bold", align or "left", "center", false, false, false, true)
end

local function drawBar(x, y, w, h, value, maximum, color)
    dxDrawRectangle(x, y, w, h, barBack)
    local ratio = maximum > 0 and clamp(value / maximum, 0, 1) or 0
    if ratio > 0 then
        dxDrawRectangle(x, y, w * ratio, h, color)
    end
end

local function getGangName(player)
    local keys = {"gangName", "gang", "factionName", "groupName"}
    for i = 1, #keys do
        local value = getElementData(player, keys[i])
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    return "بدون گنگ"
end

local function getPlayerId(player)
    local id = getElementData(player, "id")
        or getElementData(player, "player:id")
        or getElementData(player, "vendrix:sessionID")
    return id and tostring(id) or "--"
end

local function getWeaponLabel(player)
    local weapon = getPedWeapon(player)
    local name = weaponNames[weapon] or ("اسلحه " .. tostring(weapon))
    local ammo = getPedTotalAmmo(player)
    if weapon == 0 or ammo <= 0 then
        return name
    end
    return name .. "  |  " .. tostring(ammo)
end

local function drawRadarFrame()
    -- Frame sits just outside the default GTA radar; the native radar remains enabled.
    local x, y, w, h = 17, sy - 166, 166, 126
    dxDrawRectangle(x, y, w, 2, panelEdge)
    dxDrawRectangle(x, y + h - 2, w, 2, panelEdge)
    dxDrawRectangle(x, y, 2, h, red)
    dxDrawRectangle(x + w - 2, y, 2, h, panelEdge)
    dxDrawRectangle(x + 7, y + 7, 48, 3, red)
    dxDrawText("VENDRIX  /  GPS", x + 8, y - 18, x + w, y + 2,
        gold, 0.8, "default-bold", "left", "center", false, false, false, true)
end

local function renderHUD()
    if not isElement(localPlayer) or isPlayerMapVisible() then
        return
    end
    if getElementAlpha(localPlayer) < 250 or isElementFrozen(localPlayer) then
        return
    end
    if not getPlayerHudComponentVisible("radar") then
        return
    end

    sx, sy = guiGetScreenSize()
    local health = clamp(getElementHealth(localPlayer), 0, 100)
    local armor = clamp(getPedArmor(localPlayer), 0, 100)
    local money = getPlayerMoney(localPlayer)
    local id = getPlayerId(localPlayer)
    local gang = getGangName(localPlayer)
    local weapon = getWeaponLabel(localPlayer)

    drawRadarFrame()

    -- Left identity strip, positioned above the native radar to avoid covering gameplay.
    local leftX, leftY, leftW, leftH = 18, sy - 211, 292, 37
    dxDrawRectangle(leftX, leftY, leftW, leftH, panel)
    dxDrawRectangle(leftX, leftY, 3, leftH, red)
    dxDrawRectangle(leftX + 3, leftY, leftW - 3, 1, panelEdge)
    drawText("V", leftX + 10, leftY + 2, 23, 31, red, 1.25, "center")
    drawText("ID  " .. id, leftX + 40, leftY + 2, 62, 31, gold, 0.95, "left")
    dxDrawRectangle(leftX + 107, leftY + 8, 1, 21, tocolor(255,255,255,50))
    drawText(gang, leftX + 117, leftY + 2, leftW - 125, 31, white, 0.88, "left")

    -- Bottom-right status card.
    local w, h = 318, 112
    local x, y = sx - w - 20, sy - h - 22
    dxDrawRectangle(x, y, w, h, panel)
    dxDrawRectangle(x, y, w, 2, panelEdge)
    dxDrawRectangle(x, y, 3, h, red)

    drawText("سلامتی", x + 13, y + 10, 54, 18, white, 0.85, "left")
    drawText(math.floor(health) .. "%", x + w - 49, y + 10, 35, 18, white, 0.85, "right")
    drawBar(x + 73, y + 15, w - 132, 8, health, 100, red)

    drawText("زره", x + 13, y + 34, 54, 18, white, 0.85, "left")
    drawText(math.floor(armor) .. "%", x + w - 49, y + 34, 35, 18, white, 0.85, "right")
    drawBar(x + 73, y + 39, w - 132, 8, armor, 100, tocolor(75, 160, 225, 255))

    dxDrawRectangle(x + 12, y + 63, w - 24, 1, tocolor(255,255,255,35))
    drawText("$" .. string.format("%,d", money), x + 13, y + 66, 154, 29, gold, 1.08, "left")
    drawText(weapon, x + 165, y + 66, w - 180, 29, muted, 0.78, "right")

    dxDrawRectangle(x + 12, y + h - 12, w - 24, 2, tocolor(255,255,255,25))
    dxDrawRectangle(x + 12, y + h - 12, clamp(health, 0, 100) / 100 * (w - 24), 2, red)

    -- Online indicator, separate from the money line for quick readability.
    dxDrawRectangle(sx - 151, 18, 131, 28, panel)
    dxDrawRectangle(sx - 151, 18, 2, 28, red)
    dxDrawCircle(sx - 136, 32, 3, 0, 360, tocolor(90, 230, 145, 255), tocolor(90, 230, 145, 255), 12)
    drawText("آنلاین  " .. tostring(onlineCount), sx - 126, 19, 99, 26, white, 0.82, "left")
end

addEvent("vendrix:hud:sync", true)
addEventHandler("vendrix:hud:sync", resourceRoot, function(count)
    if type(count) == "number" then
        onlineCount = clamp(math.floor(count), 0, 10000)
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent("vendrix:hud:sync", resourceRoot)
end)

addEventHandler("onClientRender", root, renderHUD)
