-- VENDRIX Signature HUD - server-authoritative session metadata.
-- This resource does not change money, health, account state, or gang membership.

local EVENT_SYNC = "vendrix:hud:sync"
local sessionCounter = 0
local playerSessionIds = {}

local function assignSessionId(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return
    end

    if not playerSessionIds[player] then
        sessionCounter = sessionCounter + 1
        playerSessionIds[player] = sessionCounter
    end

    setElementData(player, "vendrix:sessionID", playerSessionIds[player], true)
end

local function syncOnlineCount(target)
    local count = #getElementsByType("player")
    if isElement(target) then
        triggerClientEvent(target, EVENT_SYNC, resourceRoot, count)
    else
        triggerClientEvent(root, EVENT_SYNC, resourceRoot, count)
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    local players = getElementsByType("player")
    for i = 1, #players do
        assignSessionId(players[i])
    end
    syncOnlineCount()
end)

addEventHandler("onPlayerJoin", root, function()
    assignSessionId(source)
    syncOnlineCount()
end)

addEventHandler("onPlayerQuit", root, function()
    playerSessionIds[source] = nil
    syncOnlineCount()
end)

addEvent(EVENT_SYNC, true)
addEventHandler(EVENT_SYNC, resourceRoot, function()
    -- Only accept a request from a real client and respond to that client.
    if not client or source ~= resourceRoot then
        return
    end
    assignSessionId(client)
    syncOnlineCount(client)
end)

addEventHandler("onPlayerLogin", root, function()
    assignSessionId(source)
end)

addEventHandler("onPlayerLogout", root, function()
    -- Session ID is not an authentication token; it remains valid for this connection.
end)
