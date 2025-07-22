-- Qpocalypse15 DeathFlag System - Server Module
-- Server-side implementation of the DeathFlag system

Qpocalypse15_DeathFlag = {}

-- Table to store activated DeathFlag information
Qpocalypse15_DeathFlag.activeFlags = {}

-- DeathFlag activation function
function Qpocalypse15_DeathFlag.activateDeathFlag(player, args)
    if not player or not args then return end
    
    local playerID = args.playerID or player:getOnlineID()
    local x = args.x or player:getX()
    local y = args.y or player:getY()
    local z = args.z or player:getZ()
    
    -- Save DeathFlag information
    Qpocalypse15_DeathFlag.activeFlags[playerID] = {
        player = player,
        x = x,
        y = y,
        z = z,
        startTime = getTimestamp(),
        duration = 15000, -- 15 seconds (milliseconds)
        range = 20 -- 20 blocks range
    }
    
    print("[DeathFlag Server] DeathFlag activated for player " .. tostring(playerID))
    
    -- Notify client
    if isServer() then
        sendServerCommand("Qpocalypse15_DeathFlag", "DeathFlagActivated", {
            playerID = playerID,
            x = x, y = y, z = z
        })
    end
    
    -- Start global timer
    Qpocalypse15_DeathFlag.startGlobalTimer()
end

-- DeathFlag deactivation function
function Qpocalypse15_DeathFlag.deactivateDeathFlag(playerID)
    if not Qpocalypse15_DeathFlag.activeFlags[playerID] then return end
    
    print("[DeathFlag Server] DeathFlag deactivated for player " .. tostring(playerID))
    
    -- Remove data
    Qpocalypse15_DeathFlag.activeFlags[playerID] = nil
    
    -- Notify client
    if isServer() then
        sendServerCommand("Qpocalypse15_DeathFlag", "DeathFlagDeactivated", {
            playerID = playerID
        })
    end
end

-- Function called when a zombie targets a player
function Qpocalypse15_DeathFlag.modifyZombieTarget(zombie, originalTarget)
    if not zombie or not originalTarget then return originalTarget end
    
    -- Check if there is an activated DeathFlag
    for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        local flagPlayer = flagData.player
        if flagPlayer and not flagPlayer:isDead() then
            local zombieX = zombie:getX()
            local zombieY = zombie:getY()
            -- Use current player position in real-time
            local flagX = flagPlayer:getX()
            local flagY = flagPlayer:getY()
            
            -- Check if the zombie is within the DeathFlag range
            local distanceToFlag = math.sqrt((zombieX - flagX)^2 + (zombieY - flagY)^2)
            if distanceToFlag <= flagData.range then
                
                -- If the original target is not the DeathFlag user and is within the range of another player
                if originalTarget ~= flagPlayer then
                    local targetX = originalTarget:getX()
                    local targetY = originalTarget:getY()
                    local distanceTargetToFlag = math.sqrt((targetX - flagX)^2 + (targetY - flagY)^2)
                    
                    -- If the original target is within the DeathFlag range, change the target to the DeathFlag user
                    if distanceTargetToFlag <= flagData.range then
                        return flagPlayer
                    end
                end
            end
        end
    end
    
    return originalTarget
end

-- Function to check if a player is visible to a zombie (zombie recognition block)
function Qpocalypse15_DeathFlag.isPlayerVisibleToZombie(player, zombie)
    if not player or not zombie then return true end
    
    local playerID = player:getOnlineID()
    
    -- Check if there is an activated DeathFlag
    for flagPlayerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        -- If you are the DeathFlag user, it will be normal
        if playerID == flagPlayerID then
            return true
        end
        
        local flagPlayer = flagData.player
        if flagPlayer and not flagPlayer:isDead() then
            local playerX = player:getX()
            local playerY = player:getY()
            -- Use current player position in real-time
            local flagX = flagPlayer:getX()
            local flagY = flagPlayer:getY()
            
            -- Check if the player is within the DeathFlag range
            local distanceToFlag = math.sqrt((playerX - flagX)^2 + (playerY - flagY)^2)
            if distanceToFlag <= flagData.range then
                -- Other players within the range cannot be seen by zombies
                return false
            end
        end
    end
    
    return true
end

-- Process client commands
local function onClientCommand(module, command, player, args)
    if module ~= "Qpocalypse15_DeathFlag" then return end
    
    if command == "ActivateDeathFlag" then
        Qpocalypse15_DeathFlag.activateDeathFlag(player, args)
    end
end

-- Global timer (memory leak prevention)
local globalTimerActive = false

local function globalTimer()
    if not globalTimerActive then return end
    
    local currentTime = getTimestamp()
    local toRemove = {}
    
    for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        if flagData then
            local elapsedTime = currentTime - flagData.startTime -- Direct comparison in milliseconds
            if elapsedTime >= flagData.duration then
                table.insert(toRemove, playerID)
            end
        end
    end
    
    -- Remove expired flags
    for _, playerID in ipairs(toRemove) do
        Qpocalypse15_DeathFlag.deactivateDeathFlag(playerID)
    end
    
    -- If there are no more active flags, stop the timer
    local hasActiveFlags = false
    for _ in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        hasActiveFlags = true
        break
    end
    
    if not hasActiveFlags then
        globalTimerActive = false
        Events.OnTick.Remove(globalTimer)
    end
end

-- Function to activate the timer
function Qpocalypse15_DeathFlag.startGlobalTimer()
    if not globalTimerActive then
        globalTimerActive = true
        Events.OnTick.Add(globalTimer)
    end
end

-- Function to stop the timer
function Qpocalypse15_DeathFlag.stopGlobalTimer()
    globalTimerActive = false
    Events.OnTick.Remove(globalTimer)
end

-- Clean up DeathFlag when a player disconnects
local function onDisconnect(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    if Qpocalypse15_DeathFlag.activeFlags[playerID] then
        print("[DeathFlag Server] Player disconnected, cleaning up DeathFlag for " .. tostring(playerID))
        Qpocalypse15_DeathFlag.deactivateDeathFlag(playerID)
    end
end

-- Clean up DeathFlag when a player dies
local function onPlayerDeath(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    if Qpocalypse15_DeathFlag.activeFlags[playerID] then
        print("[DeathFlag Server] Player died, cleaning up DeathFlag for " .. tostring(playerID))
        Qpocalypse15_DeathFlag.deactivateDeathFlag(playerID)
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.OnDisconnect.Add(onDisconnect)
Events.OnPlayerDeath.Add(onPlayerDeath) 