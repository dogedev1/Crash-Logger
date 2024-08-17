Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        TriggerServerEvent('crashLogger:heartbeat', {x = coords.x, y = coords.y, z = coords.z})
    end
end)
