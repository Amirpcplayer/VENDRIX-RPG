-- VENDRIX // PNG-DRIVEN HUD
-- DX only. PNG assets are optional; missing images use clean text fallbacks.
-- Put all PNGs directly in assets/ (flat folder) using the names in assets/README.txt.

local sx, sy = guiGetScreenSize()
local textureCache = {}
local failedTextures = {}
local errorReported = false

local C = {
    bg = tocolor(8, 10, 15, 238),
    panel = tocolor(16, 19, 27, 245),
    panel2 = tocolor(23, 27, 37, 245),
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

    local scale = math.min(1, sx / 1100)
    local w, h = 366 * scale, 190 * scale
    local x, y = sx - w - 20 * scale, 20 * scale
    local health = clamp(getElementHealth(localPlayer), 0, 100)
    local armor = clamp(getPedArmor(localPlayer), 0, 100)
    local cash = getPlayerMoney(localPlayer)
    local wanted = clamp(getPlayerWantedLevel(localPlayer), 0, 6)
    local weapon = getPedWeapon(localPlayer) or 0
    local clip = getPedAmmoInClip(localPlayer) or 0
    local totalAmmo = getPedTotalAmmo(localPlayer) or 0
    local unit = scale

    -- Outer frame
    rect(x, y, w, h, C.bg)
    rect(x, y, w, 2 * unit, C.gold)
    rect(x + w - 3 * unit, y, 3 * unit, h, C.red)
    rect(x, y, 3 * unit, h, C.goldDim)
    txt("V", x + 12*unit, y + 5*unit, 25*unit, 27*unit, C.red, 1.12*unit, "center")
    txt("VENDRIX", x + 39*unit, y + 5*unit, 116*unit, 27*unit, C.gold, 0.9*unit)
    txt("PLAYER STATUS", x + 166*unit, y + 5*unit, w - 180*unit, 27*unit, C.muted, 0.58*unit, "right")
    rect(x + 12*unit, y + 34*unit, w - 24*unit, 1, C.goldDim)

    -- Health
    if not image("hp", x + 14*unit, y + 44*unit, 25*unit, 25*unit) then
        txt("+", x + 14*unit, y + 43*unit, 25*unit, 25*unit, C.red, 1.2*unit, "center")
    end
    txt("HP", x + 45*unit, y + 41*unit, 35*unit, 17*unit, C.muted, 0.58*unit)
    txt(math.floor(health) .. "%", x + 78*unit, y + 40*unit, 55*unit, 18*unit, C.white, 0.72*unit, "right")
    drawBar(x + 45*unit, y + 60*unit, 88*unit, 5*unit, health, 100, C.red)

    -- Armor
    if not image("armor", x + 150*unit, y + 44*unit, 25*unit, 25*unit) then
        txt("A", x + 150*unit, y + 43*unit, 25*unit, 25*unit, C.blue, 0.8*unit, "center")
    end
    txt("ARMOR", x + 181*unit, y + 41*unit, 49*unit, 17*unit, C.muted, 0.55*unit)
    txt(math.floor(armor) .. "%", x + 230*unit, y + 40*unit, 47*unit, 18*unit, C.white, 0.72*unit, "right")
    drawBar(x + 181*unit, y + 60*unit, 96*unit, 5*unit, armor, 100, C.blue)

    -- Money and wanted
    rect(x + 12*unit, y + 76*unit, w - 24*unit, 33*unit, C.panel)
    if not image("money", x + 18*unit, y + 81*unit, 23*unit, 23*unit) then
        txt("$", x + 18*unit, y + 79*unit, 23*unit, 26*unit, C.gold, 0.9*unit, "center")
    end
    txt(moneyString(cash), x + 47*unit, y + 78*unit, 137*unit, 28*unit, C.gold, 0.78*unit)
    txt("WANTED", x + 188*unit, y + 78*unit, 57*unit, 28*unit, C.muted, 0.52*unit)
    drawWanted(x + 244*unit, y + 85*unit, wanted)

    -- Weapon card
    rect(x + 12*unit, y + 117*unit, w - 24*unit, 61*unit, C.panel)
    rect(x + 12*unit, y + 117*unit, 2*unit, 61*unit, C.gold)
    local weaponFile = "weapon_" .. tostring(weapon)
    if not image(weaponFile, x + 20*unit, y + 124*unit, 105*unit, 43*unit) then
        drawWeaponFallback(weapon, x + 20*unit, y + 125*unit)
    end
    txt(weaponNames[weapon] or ("WEAPON " .. tostring(weapon)), x + 132*unit, y + 120*unit, 131*unit, 22*unit, C.white, 0.66*unit)
    txt("AMMO", x + 132*unit, y + 143*unit, 46*unit, 19*unit, C.muted, 0.52*unit)
    if not image("ammo", x + 180*unit, y + 146*unit, 13*unit, 13*unit) then
        txt("•", x + 180*unit, y + 143*unit, 13*unit, 18*unit, C.gold, 0.8*unit, "center")
    end
    txt(tostring(clip) .. " / " .. tostring(totalAmmo), x + 197*unit, y + 140*unit, 126*unit, 24*unit, C.gold, 0.73*unit, "right")
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
