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
        DebugLog("Client DeathFlag init (modules auto-loaded).")
    end
    
    -- Server-side initialization
    if isServer() or not isClient() then
        DebugLog("Server DeathFlag init (modules auto-loaded).")
    end
    
    DebugLog("DeathFlag init complete!")
end

-- Initialize on game start
Events.OnGameStart.Add(Qpocalypse15_DeathFlag.init) 