local esx = {}
local playerLoaded = promise.new()

CreateThread(function(threadId)
    while not ESX.IsPlayerLoaded() do
        Wait(500)
    end

    playerLoaded:resolve()
    TerminateThread(threadId)
end)

function esx.WaitPlayerLoaded()
    Citizen.Await(playerLoaded)
end

return esx