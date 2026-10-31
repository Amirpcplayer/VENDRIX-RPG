-- VENDRIX HUD | compact top-left combat status
-- Native DX only: no CEF, timers, database calls, or per-frame element-data writes.

local sx, sy = guiGetScreenSize()
local wantedLevel = 0
local gold = tocolor(212, 175, 55, 245)
local red = tocolor(245, 35, 65, 245)
local white = tocolor(245, 245, 245, 245)
local muted = tocolor(177, 184, 197, 235)
local panel = tocolor(8, 10, 15, 218)
local edge = tocolor(212, 175, 55, 185)
local barBack = tocolor(54, 58, 68, 235)
local blue = tocolor(83, 167, 235, 245)

local weaponNames = {
    [0] = "FISTS", [1] = "BRASS", [2] = "GOLF", [3] = "NIGHTSTICK",
    [4] = "KNIFE", [5] = "BAT", [6] = "SHOVEL", [7] = "POOL",
    [8] = "KATANA", [9] = "CHAINSAW", [22] = "9MM", [23] = "SILENCED",
    [24] = "DEAGLE", [25] = "SHOTGUN", [26] = "SAWED-OFF",
    [27] = "SPAS", [28] = "UZI", [29] = "MP5", [30] = "AK-47",
    [31] = "M4", [32] = "TEC-9", [33] = "RIFLE", [34] = "SNIPER",
    [35] = "ROCKET", [36] = "HS ROCKET", [37] = "FLAME", [38] = "MINIGUN",
    [16] = "GRENADE", [17] = "TEAR GAS", [18] = "MOLOTOV",
    [39] = "SATCHEL", [41] = "SPRAY", [42] = "EXTINGUISHER", [43] = "CAMERA"
}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function drawText(text, x, y, w, h, color, scale, align, font)
    dxDrawText(tostring(text), x, y, x + w, y + h, color, scale or 1,
        font or "default-bold", align or "left", "center", false, false, false, true)
end

local function formatMoney(value)
    local formatted = tostring(math.floor(tonumber(value) or 0))
    while true do
        local updated, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        formatted = updated
        if count == 0 then break end
    end
    return formatted
end

local function drawBar(x, y, w, h, value, maximum, color)
    dxDrawRectangle(x, y, w, h, barBack)
    local ratio = maximum > 0 and clamp(value / maximum, 0, 1) or 0
    if ratio > 0 then dxDrawRectangle(x, y, w * ratio, h, color) end
end

local function getWeaponLabel(weapon)
    return weaponNames[weapon] or ("W" .. tostring(weapon))
end

local function drawStatusPanel()
    local x, y, w = 20, 20, 286
    local health = clamp(getElementHealth(localPlayer), 0, 100)
    local armor = clamp(getPedArmor(localPlayer), 0, 100)
    local money = getPlayerMoney(localPlayer)
    wantedLevel = clamp(getPlayerWantedLevel(localPlayer), 0, 6)

    -- Header
    dxDrawRectangle(x, y, w, 31, panel)
    dxDrawRectangle(x, y, 3, 31, red)
    dxDrawRectangle(x + 3, y, w - 3, 1, edge)
    drawText("VENDRIX", x + 12, y + 1, 118, 29, gold, 1.0, "left")
    drawText("PLAYER STATUS", x + 145, y + 1, w - 157, 29, muted, 0.72, "right")

    -- Health and armor rows
    local rowY = y + 39
    dxDrawRectangle(x, rowY, w, 31, panel)
    drawText("♥", x + 9, rowY, 24, 30, red, 1.12, "center")
    drawText(math.floor(health) .. " HP", x + 38, rowY, 64, 30, white, 0.9)
    drawBar(x + 108, rowY + 12, 112, 7, health, 100, red)
    drawText(math.floor(health) .. "%", x + 224, rowY, 51, 30, white, 0.78, "right")

    rowY = rowY + 35
    dxDrawRectangle(x, rowY, w, 31, panel)
    -- Compact shield glyph made from DX rectangles; avoids font-dependent icon assets.
    dxDrawRectangle(x + 15, rowY + 8, 12, 13, blue)
    dxDrawRectangle(x + 18, rowY + 5, 6, 3, blue)
    dxDrawRectangle(x + 18, rowY + 21, 6, 3, blue)
    drawText(math.floor(armor) .. " ARMOR", x + 38, rowY, 64, 30, white, 0.82)
    drawBar(x + 108, rowY + 12, 112, 7, armor, 100, blue)
    drawText(math.floor(armor) .. "%", x + 224, rowY, 51, 30, white, 0.78, "right")

    -- Cash and wanted level
    rowY = rowY + 35
    dxDrawRectangle(x, rowY, w, 31, panel)
    drawText("$", x + 10, rowY, 21, 30, gold, 1.15, "center")
    drawText(formatMoney(money), x + 36, rowY, 122, 30, gold, 0.95)
    drawText("WANTED", x + 164, rowY, 59, 30, muted, 0.68, "right")
    for star = 1, 6 do
        local color = star <= wantedLevel and red or tocolor(80, 83, 94, 220)
        drawText("★", x + 225 + ((star - 1) * 9), rowY, 10, 30, color, 0.72, "center")
    end

    -- Weapons carried in GTA weapon slots, with clip / total ammo.
    rowY = rowY + 37
    dxDrawRectangle(x, rowY, w, 24, panel)
    dxDrawRectangle(x, rowY, 2, 24, edge)
    drawText("WEAPONS", x + 8, rowY, 58, 24, gold, 0.68)
    local slotX = x + 69
    local shown = 0
    for slot = 2, 7 do
        local weapon = getPedWeapon(localPlayer, slot)
        local totalAmmo = getPedTotalAmmo(localPlayer, slot)
        if weapon and weapon > 0 and totalAmmo and totalAmmo > 0 then
            local clip = getPedAmmoInClip(localPlayer, slot) or 0
            local label = getWeaponLabel(weapon)
            local compact = label .. " " .. tostring(clip) .. "/" .. tostring(totalAmmo)
            local chipW = math.min(86, math.max(56, dxGetTextWidth(compact, 0.62, "default-bold") + 10))
            if slotX + chipW > x + w - 5 then
                break
            end
            dxDrawRectangle(slotX, rowY + 3, chipW, 18, tocolor(36, 39, 48, 235))
            drawText(compact, slotX + 4, rowY + 2, chipW - 8, 19, white, 0.62)
            slotX = slotX + chipW + 4
            shown = shown + 1
        end
    end
    if shown == 0 then
        drawText("NO AMMO WEAPONS", x + 72, rowY, w - 80, 24, muted, 0.66)
    end
end

local function renderHUD()
    if not isElement(localPlayer) then return end
    if type(isPlayerMapVisible) == "function" and isPlayerMapVisible() then return end
    sx, sy = guiGetScreenSize()
    drawStatusPanel()
end

local hudErrorReported = false
local function renderHUDGuarded()
    local ok, err = pcall(renderHUD)
    if not ok and not hudErrorReported then
        hudErrorReported = true
        outputDebugString("[vendrix-hud] Render error: " .. tostring(err), 1)
        outputChatBox("[VENDRIX HUD] خطای رندر؛ F8 را برای جزئیات بررسی کن.", 255, 60, 60)
    end
end

addEventHandler("onClientRender", root, renderHUDGuarded)
