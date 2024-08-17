local webhookUrl = "webhook here"
local playerTimeouts = {}
local timeoutThreshold = 15000
local playerCoords = {}

function logCrash(playerId, reason, coords)
    local playerName = GetPlayerName(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    
    local filteredIdentifiers = {}
    for _, id in ipairs(identifiers) do
        if string.match(id, "license:") or
           string.match(id, "xbl:") or
           string.match(id, "live:") or
           string.match(id, "discord:") or
           string.match(id, "ip:") or
           string.match(id, "fivem:") then
            table.insert(filteredIdentifiers, id)
        end
    end

    local embedContent = {
        {
            ["title"] = "🚨 Player Crash Detected 🚨",
            ["description"] = "A player has experienced a crash or disconnect.",
            ["color"] = 16711680, 
            ["fields"] = {
                {
                    ["name"] = "Player Name",
                    ["value"] = playerName,
                    ["inline"] = true
                },
                {
                    ["name"] = "Reason",
                    ["value"] = reason,
                    ["inline"] = true
                },
                {
                    ["name"] = "Location",
                    ["value"] = string.format("**X**: %.2f\n**Y**: %.2f\n**Z**: %.2f", coords.x, coords.y, coords.z),
                    ["inline"] = true
                },
                {
                    ["name"] = "Identifiers",
                    ["value"] = table.concat(filteredIdentifiers, "\n"),
                    ["inline"] = false
                }
            },
            ["footer"] = {
                ["text"] = "Crash Logger | Powered by Jenkins.International"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ"), 
            ["thumbnail"] = {
                ["url"] = "Server LOGO here" 
            },
            ["author"] = {
                ["name"] = "Crash Logger",
                ["icon_url"] = "Server LOGO here" 
            }
        }
    }

    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({
        username = "Crash Logger",
        embeds = embedContent
    }), { ['Content-Type'] = 'application/json' })

    print(string.format("Player %s crashed. Reason: %s. Location: x: %.2f, y: %.2f, z: %.2f", playerName, reason, coords.x, coords.y, coords.z))
end

RegisterNetEvent('crashLogger:heartbeat')
AddEventHandler('crashLogger:heartbeat', function(coords)
    local playerId = source
    playerTimeouts[playerId] = os.time()
    playerCoords[playerId] = coords 
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) 

        local currentTime = os.time()
        for playerId, lastHeartbeat in pairs(playerTimeouts) do
            if (currentTime - lastHeartbeat) > (timeoutThreshold / 1000) then
                local coords = playerCoords[playerId] or {x = 0, y = 0, z = 0}
                logCrash(playerId, "Game Crash or Unexpected Disconnect", coords)
                playerTimeouts[playerId] = nil
                playerCoords[playerId] = nil
            end
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    if playerTimeouts[playerId] then
        playerTimeouts[playerId] = nil
        local coords = playerCoords[playerId] or {x = 0, y = 0, z = 0} 
        if string.find(string.lower(reason), "crash") then
            logCrash(playerId, reason, coords)
        end
        playerCoords[playerId] = nil
    end
end)
