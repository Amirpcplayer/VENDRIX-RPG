local function handleGPS(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return
    end

    local x, y, z = getElementPosition(player)
    local rotation = getPedRotation(player)
    local interior = getElementInterior(player)
    local dimension = getElementDimension(player)

    outputChatBox("#D4AF37========== VENDRIX GPS ==========", player, 255, 255, 255, true)
    outputChatBox(string.format("#FFFFFFX: #55FF55%.6f", x), player, 255, 255, 255, true)
    outputChatBox(string.format("#FFFFFFY: #55FF55%.6f", y), player, 255, 255, 255, true)
    outputChatBox(string.format("#FFFFFFZ: #55FF55%.6f", z), player, 255, 255, 255, true)
    outputChatBox(string.format("#FFFFFFRotation: #55FF55%.3f", rotation), player, 255, 255, 255, true)
    outputChatBox(string.format("#FFFFFFInterior: #55FF55%d", interior), player, 255, 255, 255, true)
    outputChatBox(string.format("#FFFFFFDimension: #55FF55%d", dimension), player, 255, 255, 255, true)
    outputChatBox("#D4AF37================================", player, 255, 255, 255, true)
end

addCommandHandler("gps", handleGPS)

outputDebugString("[VENDRIX] GPS resource loaded.", 3)
