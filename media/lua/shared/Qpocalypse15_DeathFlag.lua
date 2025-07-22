-- Main module for DeathFlag system

Qpocalypse15_DeathFlag = Qpocalypse15_DeathFlag or {}

-- Debug log function
local function DebugLog(message)
    print("[Qpocalypse15 DeathFlag] " .. message)
end

-- System initialization
function Qpocalypse15_DeathFlag.init()
    DebugLog("DeathFlag init...")
    
    -- Client-side initialization
    if isClient() or not isServer() then
        DebugLog("Client DeathFlag init...")
        local success, err = pcall(function()
            require "client/Qpocalypse15_DeathFlag_Client"
        end)
        if not success then
            DebugLog("Client module load failed: " .. tostring(err))
        end
    end
    
    -- Server-side initialization
    if isServer() or not isClient() then
        DebugLog("Server DeathFlag init...")
        local success1, err1 = pcall(function()
            require "server/Qpocalypse15_DeathFlag_Server"
        end)
        local success2, err2 = pcall(function()
            require "server/Qpocalypse15_DeathFlag_ZombieAI"
        end)
        
        if not success1 then
            DebugLog("Server module load failed: " .. tostring(err1))
        end
        if not success2 then
            DebugLog("Zombie AI module load failed: " .. tostring(err2))
        end
    end
    
    DebugLog("DeathFlag init complete!")
end

-- Initialize on game start
Events.OnGameStart.Add(Qpocalypse15_DeathFlag.init) 