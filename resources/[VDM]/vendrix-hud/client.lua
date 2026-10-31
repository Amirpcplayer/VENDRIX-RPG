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

    -- Compact custom VENDRIX HUD: narrow right-side status rail.
    -- Scales with resolution while keeping the same visual proportions.
    local u = clamp(sy / 900, 0.86, 1.2)
    local w = 190 * u
    local x = sx - w - 22 * u
    local y = 20 * u

    local health = clamp(getElementHealth(localPlayer), 0, 100)
    local armor = clamp(getPedArmor(localPlayer), 0, 100)
    local cash = getPlayerMoney(localPlayer)
    local wanted = clamp(getPlayerWantedLevel(localPlayer), 0, 6)
    local weapon = getPedWeapon(localPlayer) or 0
    local clip = getPedAmmoInClip(localPlayer) or 0
    local totalAmmo = getPedTotalAmmo(localPlayer) or 0

    -- Logo only; no generated text branding.
    image("logo", x + 2*u, y, 156*u, 30*u)
    rect(x, y + 33*u, w, 2*u, C.red)
    rect(x + 82*u, y + 33*u, 48*u, 2*u, C.gold)

    -- Two compact status bars with numeric values aligned to the right.
    local rowY = y + 42*u
    if not image("hp", x, rowY, 20*u, 20*u) then
        txt("+", x, rowY - 1*u, 20*u, 21*u, C.red, 0.95*u, "center")
    end
    txt("HP", x + 25*u, rowY - 1*u, 28*u, 18*u, C.white, 0.66*u)
    txt(math.floor(health) .. "%", x + w - 43*u, rowY - 1*u, 43*u, 18*u, C.red, 0.72*u, "right")
    drawBar(x + 25*u, rowY + 19*u, w - 28*u, 4*u, health, 100, C.red)

    rowY = rowY + 31*u
    if not image("armor", x, rowY, 20*u, 20*u) then
        txt("A", x, rowY - 1*u, 20*u, 21*u, C.blue, 0.72*u, "center")
    end
    txt("AP", x + 25*u, rowY - 1*u, 28*u, 18*u, C.white, 0.66*u)
    txt(math.floor(armor) .. "%", x + w - 43*u, rowY - 1*u, 43*u, 18*u, C.blue, 0.72*u, "right")
    drawBar(x + 25*u, rowY + 19*u, w - 28*u, 4*u, armor, 100, C.blue)

    -- Money strip: no panel background, only a fine gold accent.
    rowY = rowY + 32*u
    rect(x, rowY, 2*u, 25*u, C.gold)
    if not image("money", x + 7*u, rowY + 2*u, 20*u, 20*u) then
        txt("$", x + 7*u, rowY, 20*u, 23*u, C.gold, 0.82*u, "center")
    end
    txt(moneyString(cash), x + 32*u, rowY, w - 34*u, 24*u, C.gold, 0.78*u, "right")

    -- Wanted level: a tight single line, shown only when wanted.
    if wanted > 0 then
        rowY = rowY + 30*u
        txt("WANTED", x, rowY, 56*u, 16*u, C.muted, 0.56*u)
        for i = 1, 6 do
            local px = x + 61*u + (i - 1) * 18*u
            local tint = i <= wanted and tocolor(255,255,255,255) or tocolor(100,105,115,95)
            if not image("wanted_star", px, rowY, 14*u, 14*u, tint) then
                txt("★", px, rowY - 1*u, 15*u, 16*u, i <= wanted and C.red or C.empty, 0.63*u, "center")
            end
        end
    end

    -- Weapon row: compact weapon icon on the right, ammo count, then ammo icon.
    rowY = rowY + 29*u
    rect(x, rowY, w, 1*u, C.goldDim)
    txt(weaponNames[weapon] or ("WEAPON " .. tostring(weapon)),
        x, rowY + 5*u, w - 2*u, 17*u, C.white, 0.66*u, "right")

    local iconSize = 23*u
    local iconY = rowY + 25*u
    local weaponIconX = x + w - iconSize
    local ammoTextW = 88*u
    local ammoTextX = weaponIconX - 9*u - ammoTextW

    txt(tostring(clip) .. " / " .. tostring(totalAmmo),
        ammoTextX, iconY - 1*u, ammoTextW, iconSize + 2*u, C.gold, 0.74*u, "right")

    local weaponFile = "weapon_" .. tostring(weapon)
    if not image(weaponFile, weaponIconX, iconY, iconSize, iconSize) then
        txt("W", weaponIconX, iconY, iconSize, iconSize, C.white, 0.65*u, "center")
    end
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
