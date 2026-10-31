-- VENDRIX // PNG-DRIVEN HUD
-- DX only. PNG assets are optional; missing images use clean text fallbacks.
-- Put all PNGs directly in assets/ (flat folder) using the names in assets/README.txt.

local sx, sy = guiGetScreenSize()
local textureCache = {}
local failedTextures = {}
local errorReported = false

local C = {
    gold = tocolor(232, 190, 72, 255),
    goldDim = tocolor(130, 99, 39, 220),
    red = tocolor(255, 48, 76, 255),
    blue = tocolor(93, 174, 255, 255),
    white = tocolor(245, 247, 251, 255),
    muted = tocolor(143, 151, 166, 245),
    empty = tocolor(48, 55, 68, 230),
    green = tocolor(99, 221, 163, 255)
}

local weaponNames = {
    [0]="UNARMED",[1]="BRASS KNUCKLES",[2]="GOLF CLUB",[3]="NIGHTSTICK",
    [4]="KNIFE",[5]="BASEBALL BAT",[6]="SHOVEL",[7]="POOL CUE",[8]="KATANA",
    [9]="CHAINSAW",[10]="DILDO 1",[11]="DILDO 2",[12]="VIBRATOR 1",
    [13]="VIBRATOR 2",[14]="FLOWERS",[15]="CANE",[16]="GRENADE",
    [17]="TEAR GAS",[18]="MOLOTOV",[22]="9MM",[23]="SILENCED 9MM",
    [24]="DESERT EAGLE",[25]="SHOTGUN",[26]="SAWED-OFF",[27]="SPAS-12",
    [28]="MICRO SMG",[29]="MP5",[30]="AK-47",[31]="M4",[32]="TEC-9",
    [33]="RIFLE",[34]="SNIPER RIFLE",[35]="ROCKET LAUNCHER",
    [36]="HEAT SEEKER",[37]="FLAMETHROWER",[38]="MINIGUN",
    [39]="SATCHEL CHARGE",[40]="DETONATOR",[41]="SPRAY CAN",
    [42]="FIRE EXTINGUISHER",[43]="CAMERA",[44]="NIGHT VISION",
    [45]="THERMAL GOGGLES",[46]="PARACHUTE"
}

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function rect(x, y, w, h, color)
    dxDrawRectangle(math.floor(x), math.floor(y), math.max(1, math.floor(w)), math.max(1, math.floor(h)), color)
end

local function txt(value, x, y, w, h, color, scale, align, font)
    dxDrawText(tostring(value), x, y, x + w, y + h, color, scale or 1,
        font or "default-bold", align or "left", "center", false, false, false, true)
end

local function moneyString(value)
    local s = tostring(math.floor(tonumber(value) or 0))
    while true do
        local changed, count = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        s = changed
        if count == 0 then return s end
    end
end

local function image(name, x, y, w, h, color)
    local path = "assets/" .. name .. ".png"
    local texture = textureCache[path]
    if not texture and not failedTextures[path] then
        if fileExists(path) then
            texture = dxCreateTexture(path, "argb", true, "clamp")
            if texture then
                textureCache[path] = texture
            else
                failedTextures[path] = true
            end
        else
            failedTextures[path] = true
        end
    end
    if texture then
        dxDrawImage(x, y, w, h, texture, 0, 0, 0, color or tocolor(255, 255, 255, 255), false)
        return true
    end
    return false
end

local function drawBar(x, y, w, h, value, maxValue, color)
    rect(x, y, w, h, C.empty)
    local ratio = maxValue > 0 and clamp(value / maxValue, 0, 1) or 0
    if ratio > 0 then
        rect(x, y, w * ratio, h, color)
        rect(x, y, w * ratio, 1, tocolor(255, 255, 255, 90))
    end
end

local function drawWanted(x, y, level)
    for i = 1, 6 do
        local px = x + (i - 1) * 19
        if not image("wanted_star", px, y, 16, 16, i <= level and tocolor(255,255,255,255) or tocolor(100,105,115,125)) then
            txt("★", px, y - 1, 17, 18, i <= level and C.red or C.empty, 0.8, "center")
        end
    end
end

local function drawWeaponFallback(weapon, x, y)
    txt("WEAPON", x, y, 65, 28, C.gold, 0.57, "center")
end

local function drawHUD()
    if not isElement(localPlayer) or isPlayerMapVisible() then return end
    sx, sy = guiGetScreenSize()

    -- Tall, transparent stack. Larger at 1080p; scales down only on small screens.
    local scale = clamp(sy / 900, 0.78, 1.18)
    local w = 224 * scale
    local x = sx - w - 24 * scale
    local y = 26 * scale

    local health = clamp(getElementHealth(localPlayer), 0, 100)
    local armor = clamp(getPedArmor(localPlayer), 0, 100)
    local cash = getPlayerMoney(localPlayer)
    local wanted = clamp(getPlayerWantedLevel(localPlayer), 0, 6)
    local weapon = getPedWeapon(localPlayer) or 0
    local clip = getPedAmmoInClip(localPlayer) or 0
    local totalAmmo = getPedTotalAmmo(localPlayer) or 0
    local u = scale

    -- Header: no background or enclosing frame.
    txt("V", x, y, 32*u, 34*u, C.red, 1.45*u, "center")
    txt("VENDRIX", x + 35*u, y, 145*u, 34*u, C.gold, 1.08*u)
    rect(x + 1*u, y + 36*u, w - 2*u, 2*u, C.goldDim)

    -- HEALTH: full row
    local rowY = y + 49*u
    if not image("hp", x + 2*u, rowY, 40*u, 40*u) then
        txt("+", x + 2*u, rowY, 40*u, 40*u, C.red, 1.7*u, "center")
    end
    txt("HEALTH", x + 50*u, rowY - 2*u, 100*u, 22*u, C.white, 0.83*u)
    txt(math.floor(health) .. "%", x + 144*u, rowY - 2*u, 72*u, 22*u, C.red, 0.92*u, "right")
    drawBar(x + 50*u, rowY + 25*u, w - 54*u, 8*u, health, 100, C.red)

    -- ARMOR: own row underneath health
    rowY = y + 105*u
    if not image("armor", x + 2*u, rowY, 40*u, 40*u) then
        txt("A", x + 2*u, rowY, 40*u, 40*u, C.blue, 1.15*u, "center")
    end
    txt("ARMOR", x + 50*u, rowY - 2*u, 100*u, 22*u, C.white, 0.83*u)
    txt(math.floor(armor) .. "%", x + 144*u, rowY - 2*u, 72*u, 22*u, C.blue, 0.92*u, "right")
    drawBar(x + 50*u, rowY + 25*u, w - 54*u, 8*u, armor, 100, C.blue)

    -- MONEY: separate line
    rowY = y + 164*u
    if not image("money", x + 3*u, rowY, 34*u, 34*u) then
        txt("$", x + 3*u, rowY - 1*u, 34*u, 34*u, C.gold, 1.35*u, "center")
    end
    txt("CASH", x + 48*u, rowY - 2*u, w - 50*u, 18*u, C.muted, 0.67*u)
    txt(moneyString(cash), x + 48*u, rowY + 15*u, w - 50*u, 24*u, C.gold, 0.92*u)

    -- WANTED: its own row with larger stars.
    rowY = y + 216*u
    txt("WANTED LEVEL", x + 1*u, rowY, w - 2*u, 21*u, C.white, 0.77*u)
    for i = 1, 6 do
        local px = x + 2*u + (i - 1) * 36*u
        local tint = i <= wanted and tocolor(255,255,255,255) or tocolor(100,105,115,115)
        if not image("wanted_star", px, rowY + 24*u, 29*u, 29*u, tint) then
            txt("★", px, rowY + 22*u, 31*u, 32*u, i <= wanted and C.red or C.empty, 1.12*u, "center")
        end
    end

    -- WEAPON: image centered on its own row; name and ammo below.
    rowY = y + 278*u
    local weaponFile = "weapon_" .. tostring(weapon)
    if not image(weaponFile, x + 8*u, rowY, w - 16*u, 67*u) then
        txt("WEAPON", x + 8*u, rowY + 12*u, w - 16*u, 36*u, C.gold, 0.88*u, "center")
    end
    rect(x + 1*u, rowY + 71*u, w - 2*u, 1*u, C.goldDim)
    txt(weaponNames[weapon] or ("WEAPON " .. tostring(weapon)), x + 1*u, rowY + 77*u, w - 2*u, 25*u, C.white, 0.83*u, "center")
    if not image("ammo", x + 36*u, rowY + 108*u, 24*u, 24*u) then
        txt("AMMO", x + 30*u, rowY + 107*u, 44*u, 24*u, C.gold, 0.61*u, "center")
    end
    txt(tostring(clip) .. " / " .. tostring(totalAmmo), x + 64*u, rowY + 105*u, w - 68*u, 29*u, C.gold, 0.94*u, "left")
end

local function hideNativeHUD()
    local components = {"health", "armour", "money", "weapon", "ammo", "wanted", "clock", "breath", "vehicle_name", "area_name", "radio"}
    for i = 1, #components do
        showPlayerHudComponent(components[i], false)
    end
end

local function releaseTextures()
    for path, texture in pairs(textureCache) do
        if isElement(texture) then destroyElement(texture) end
        textureCache[path] = nil
    end
    failedTextures = {}
end

local function guardedRender()
    local ok, err = pcall(drawHUD)
    if not ok and not errorReported then
        errorReported = true
        outputDebugString("[vendrix-hud] Render error: " .. tostring(err), 1)
    end
end

addEventHandler("onClientResourceStart", resourceRoot, hideNativeHUD)
addEventHandler("onClientPlayerSpawn", localPlayer, hideNativeHUD)
addEventHandler("onClientResourceStop", resourceRoot, releaseTextures)
addEventHandler("onClientRender", root, guardedRender)
