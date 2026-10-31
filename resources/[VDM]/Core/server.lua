-- VENDRIX RPG - Core bootstrap
-- Keep this resource independent from optional gameplay resources.

local RESOURCE_NAME = getResourceName(getThisResource())

addEventHandler("onResourceStart", resourceRoot, function()
    outputServerLog(("[VENDRIX] %s started successfully."):format(RESOURCE_NAME))
end)

addEventHandler("onResourceStop", resourceRoot, function()
    outputServerLog(("[VENDRIX] %s stopped."):format(RESOURCE_NAME))
end)
