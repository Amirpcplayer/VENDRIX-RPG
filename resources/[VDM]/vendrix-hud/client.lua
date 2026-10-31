-- VENDRIX // NEON COMBAT HUD
-- Native DX rendering only. No timers, CEF, DB calls or per-frame network traffic.

local sx, sy = guiGetScreenSize()
local pulse = 0
local errorReported = false

local C = {
    bg = tocolor(7, 9, 14, 232),
    bg2 = tocolor(15, 18, 26, 245),
    bg3 = tocolor(25, 29, 39, 245),
    gold = tocolor(231, 188, 65, 255),
    goldDim = tocolor(150, 113, 35, 235),
    red = tocolor(255, 42, 75, 255),
    redDim = tocolor(145, 25, 48, 240),
    blue = tocolor(84, 176, 255, 255),
    white = tocolor(246, 248, 252, 255),
    muted = tocolor(137, 147, 164, 245),
    dim = tocolor(63, 71, 86, 235),
    green = tocolor(96, 226, 167, 255)
}

local weaponNames = {
    [0]="UNARMED",[1]="BRASS KNUCKLES",[2]="GOLF CLUB",[3]="NIGHTSTICK",
    [4]="KNIFE",[5]="BASEBALL BAT",[6]="SHOVEL",[7]="POOL CUE",[8]="KATANA",
    [9]="CHAINSAW",[10]="PURPLE DILDO",[11]="DILDO",[12]="VIBRATOR",
    [13]="SILVER VIBRATOR",[14]="FLOWERS",[15]="CANE",[16]="GRENADE",
    [17]="TEAR GAS",[18]="MOLOTOV",[22]="9MM",[23]="SILENCED 9MM",
    [24]="DESERT EAGLE",[25]="SHOTGUN",[26]="SAWED-OFF",[27]="SPAS-12",
    [28]="MICRO SMG",[29]="MP5",[30]="AK-47",[31]="M4",[32]="TEC-9",
    [33]="RIFLE",[34]="SNIPER RIFLE",[35]="ROCKET LAUNCHER",
    [36]="HEAT SEEKER",[37]="FLAMETHROWER",[38]="MINIGUN",
    [39]="SATCHEL CHARGE",[40]="DETONATOR",[41]="SPRAY CAN",
    [42]="FIRE EXTINGUISHER",[43]="CAMERA"
}

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, tonumber(v) or lo))
end

local function text(value, x, y, w, h, color, scale, align, font)
    dxDrawText(tostring(value), x, y, x + w, y + h, color, scale or 1,
        font or "default-bold", align or "left", "center", false, false, false, true)
end

local function rect(x, y, w, h, color)
    dxDrawRectangle(math.floor(x), math.floor(y), math.max(1, math.floor(w)), math.max(1, math.floor(h)), color)
end

local function moneyString(value)
    local s = tostring(math.floor(tonumber(value) or 0))
    while true do
        local changed, count = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        s = changed
        if count == 0 then return s end
    end
end

local function bar(x, y, w, h, value, maximum, color)
    rect(x, y, w, h, C.bg3)
    local ratio = maximum > 0 and clamp(value / maximum, 0, 1) or 0
    if ratio > 0 then
        rect(x, y, w * ratio, h, color)
        rect(x, y, w * ratio, 1, tocolor(255, 255, 255, 90))
    end
end

local function drawWeaponSilhouette(weapon, x, y, w, h, color)
    -- Compact weapon pictogram drawn in DX; varies by weapon class.
    local function line(x1, y1, x2, y2, width)
        dxDrawLine(x1, y1, x2, y2, color, width or 2, false)
    end
    if weapon == 0 then
        -- fists
        rect(x + w * 0.28, y + h * 0.38, w * 0.22, h * 0.22, color)
        rect(x + w * 0.51, y + h * 0.31, w * 0.20, h * 0.22, color)
        line(x + w * 0.30, y + h * 0.62, x + w * 0.70, y + h * 0.62, 2)
    elseif weapon == 4 or weapon == 8 or weapon == 9 then
        line(x + w * 0.24, y + h * 0.70, x + w * 0.78, y + h * 0.22, 3)
        line(x + w * 0.18, y + h * 0.64, x + w * 0.33, y + h * 0.80, 4)
        line(x + w * 0.23, y + h * 0.69, x + w * 0.39, y + h * 0.85, 2)
    elseif weapon == 25 or weapon == 26 or weapon == 27 or weapon == 33 or weapon == 34 then
        line(x + w * 0.12, y + h * 0.43, x + w * 0.83, y + h * 0.43, 4)
        line(x + w * 0.47, y + h * 0.43, x + w * 0.57, y + h * 0.68, 3)
        line(x + w * 0.23, y + h * 0.43, x + w * 0.23, y + h * 0.60, 2)
        line(x + w * 0.72, y + h * 0.37, x + w * 0.72, y + h * 0.49, 2)
    else
        -- pistol / SMG / rifle silhouette
        line(x + w * 0.12, y + h * 0.40, x + w * 0.82, y + h * 0.40, 4)
        line(x + w * 0.32, y + h * 0.40, x + w * 0.32, y + h * 0.28, 2)
        line(x + w * 0.46, y + h * 0.40, x + w * 0.43, y + h * 0.72, 3)
        line(x + w * 0.53, y + h * 0.40, x + w * 0.68, y + h * 0.40, 2)
        if weapon == 30 or weapon == 31 or weapon == 29 or weapon == 28 then
            line(x + w * 0.18, y + h * 0.34, x + w * 0.18, y + h * 0.49, 2)
            line(x + w * 0.68, y + h * 0.40, x + w * 0.68, y + h * 0.55, 2)
        end
    end
end

local function drawStars(x, y, wanted)
    for i = 1, 6 do
        local active = i <= wanted
        local color = active and C.red or tocolor(62, 69, 82, 220)
        local scale = active and 1.08 or 0.92
        text("★", x + (i - 1) * 18, y, 18, 22, color, scale, "center")
    end
end

local function drawHUD()
    if not isElement(localPlayer) or isPlayerMapVisible() then return end
    sx, sy = guiGetScreenSize()

    local w, x, y = 354, sx - 374, 22
    local health = clamp(getElementHealth(localPlayer), 0, 100)
    local armor = clamp(getPedArmor(localPlayer), 0, 100)
    local cash = getPlayerMoney(localPlayer)
    local wanted = clamp(getPlayerWantedLevel(localPlayer), 0, 6)
    local weapon = getPedWeapon(localPlayer) or 0
    local slot = getPedWeaponSlot(localPlayer) or 0
    local clip = getPedAmmoInClip(localPlayer) or 0
    local totalAmmo = getPedTotalAmmo(localPlayer) or 0
    local weaponLabel = weaponNames[weapon] or ("WEAPON " .. tostring(weapon))
    local now = getTickCount()
    pulse = (math.sin(now / 430) + 1) * 0.5

    -- Main frame, layered edge and red corner marker
    rect(x, y, w, 198, C.bg)
    rect(x, y, w, 2, C.gold)
    rect(x + w - 3, y, 3, 198, C.red)
    rect(x, y, 4, 198, C.goldDim)
    rect(x + 9, y + 9, w - 22, 32, C.bg2)
    text("V", x + 18, y + 8, 27, 34, C.red, 1.55, "center", "default-bold")
    text("VENDRIX", x + 49, y + 8, 130, 34, C.gold, 1.08, "left")
    text("COMBAT INTERFACE", x + 170, y + 9, 155, 32, C.muted, 0.70, "right")
    rect(x + 12, y + 47, w - 27, 1, tocolor(105, 83, 40, 190))

    -- Health / armor modules
    text("HP", x + 15, y + 54, 31, 19, C.red, 0.78)
    text(math.floor(health), x + 44, y + 51, 43, 24, C.white, 1.02)
    text("%", x + 83, y + 56, 13, 18, C.muted, 0.68)
    bar(x + 15, y + 78, 151, 7, health, 100, C.red)
    rect(x + 15, y + 88, 151, 1, tocolor(255, 42, 75, 65))

    text("ARMOR", x + 184, y + 54, 54, 19, C.blue, 0.72)
    text(math.floor(armor), x + 241, y + 51, 40, 24, C.white, 1.02)
    bar(x + 184, y + 78, 145, 7, armor, 100, C.blue)
    text("VITALS", x + 15, y + 98, 60, 17, C.muted, 0.62)
    text("STABLE", x + 264, y + 98, 65, 17, health <= 25 and C.red or C.green, 0.62, "right")

    -- Cash and wanted level
    rect(x + 10, y + 120, w - 22, 31, C.bg2)
    text("$", x + 18, y + 120, 18, 31, C.gold, 1.05, "center")
    text(moneyString(cash), x + 40, y + 120, 140, 31, C.gold, 0.91)
    text("WANTED", x + 187, y + 120, 61, 31, C.muted, 0.62)
    drawStars(x + 248, y + 124, wanted)

    -- Weapon focus: large class silhouette and clear ammo readout
    rect(x + 10, y + 158, w - 22, 31, C.bg2)
    rect(x + 10, y + 158, 2, 31, C.gold)
    drawWeaponSilhouette(weapon, x + 17, y + 159, 47, 28, C.gold)
    text(weaponLabel, x + 70, y + 158, 143, 18, C.white, 0.72)
    text("SLOT " .. tostring(slot), x + 70, y + 174, 65, 12, C.muted, 0.55)
    text(tostring(clip), x + 216, y + 157, 53, 25, C.white, 1.03, "right")
    text("/", x + 269, y + 158, 10, 24, C.gold, 0.85, "center")
    text(tostring(totalAmmo), x + 278, y + 158, 42, 25, C.gold, 0.80, "left")
    text("AMMO", x + 216, y + 177, 103, 10, C.muted, 0.52, "right")
    rect(x + w - 14, y + 163, 2, 20, tocolor(255, 42, 75, 110 + math.floor(pulse * 120)))
end

local function hideNativeHUD()
    local components = {"health", "armour", "money", "weapon", "ammo", "wanted", "clock", "breath", "vehicle_name", "area_name", "radio"}
    for i = 1, #components do
        showPlayerHudComponent(components[i], false)
    end
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
addEventHandler("onClientRender", root, guardedRender)
