-- Qpocalypse15 DeathFlag Zombie AI Hooks
-- Zombie AI hooks and DeathFlag effect application

require "server/Qpocalypse15_DeathFlag_Server"

-- Cache variables for performance optimization
local lastUpdateTime = 0
local UPDATE_INTERVAL = 500 -- Update every 0.5 seconds (500ms) - more responsive

-- Periodic update function for modifying zombie AI
local function updateZombiesForDeathFlag()
    local currentTime = getTimestamp()
    
    -- Performance optimization: only run every second
    if (currentTime - lastUpdateTime) < UPDATE_INTERVAL then
        return
    end
    lastUpdateTime = currentTime
    
    -- Skip if there are no activated DeathFlags
    if not Qpocalypse15_DeathFlag.activeFlags then
        return
    end
    
    local hasActiveFlags = false
    for _ in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        hasActiveFlags = true
        break
    end
    
    if not hasActiveFlags then
        return
    end
    
    -- Process all zombies around all players
    for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        local flagPlayer = flagData.player
        if flagPlayer and not flagPlayer:isDead() then
            -- Use current player position in real-time (movable)
            local flagX = flagPlayer:getX()
            local flagY = flagPlayer:getY()
            local range = flagData.range
            
            -- Find nearby zombies (exact method)
            local cell = getCell()
            if cell then
                -- Convert to integer coordinates and check range
                local startX = math.max(0, math.floor(flagX - range))
                local endX = math.min(cell:getMaxX(), math.floor(flagX + range))
                local startY = math.max(0, math.floor(flagY - range))
                local endY = math.min(cell:getMaxY(), math.floor(flagY + range))
                
                -- Check all tiles (performance optimization: skip 2 tiles)
                for x = startX, endX, 2 do
                    for y = startY, endY, 2 do
                        local square = cell:getGridSquare(x, y, 0)
                        if square then
                            local zombieList = square:getZombieList()
                            if zombieList and zombieList:size() > 0 then
                                for i = 0, zombieList:size() - 1 do
                                    local zombie = zombieList:get(i)
                                    if zombie and not zombie:isDead() then
                                        local zombieX = zombie:getX()
                                        local zombieY = zombie:getY()
                                        local distance = math.sqrt((zombieX - flagX)^2 + (zombieY - flagY)^2)
                                        if distance <= range then
                                            -- Focus the zombie on the DeathFlag user
                                            local currentTarget = zombie:getTarget()
                                            if not currentTarget or 
                                              (instanceof(currentTarget, "IsoPlayer") and currentTarget ~= flagPlayer) then
                                                zombie:setTarget(flagPlayer)
                                                zombie:setTargetSeenTime(2500) -- Force target for 2.5 seconds
                                                
                                                -- Additional setting to ensure the zombie is definitely targeting the DeathFlag user
                                                if zombie:getModData then
                                                    local modData = zombie:getModData()
                                                    modData.deathFlagTarget = flagPlayer:getOnlineID()
                                                    modData.deathFlagTime = getTimestamp()
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Function to block the process of zombies detecting players
local function onZombieUpdate(zombie)
    if not zombie or zombie:isDead() then return end
    
    -- Skip if there are no activated DeathFlags
    local hasActiveFlags = false
    for _ in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        hasActiveFlags = true
        break
    end
    
    if not hasActiveFlags then return end
    
    local currentTarget = zombie:getTarget()
    if currentTarget and instanceof(currentTarget, "IsoPlayer") then
        -- Check if the current target is within the DeathFlag protection range
        if not Qpocalypse15_DeathFlag.isPlayerVisibleToZombie(currentTarget, zombie) then
            -- Protected players are removed from the target and redirected to the DeathFlag user
                             for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
                 local flagPlayer = flagData.player
                 if flagPlayer and isZombieInDeathFlagRange(zombie, flagPlayer, flagData.range) then
                     zombie:setTarget(flagPlayer)
                     zombie:setTargetSeenTime(3000) -- Force target for 3 seconds
                     break
                 end
             end
        end
    end
end

-- Zombie noise response hook
local function onZombieHearNoise(zombie, noiseSource, volume, x, y)
    if not zombie or zombie:isDead() then return end
    
    -- Check if DeathFlag is activated
         for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
         local flagPlayer = flagData.player
         if flagPlayer and isZombieInDeathFlagRange(zombie, flagPlayer, flagData.range) then
             -- Redirect all noise within the range to the DeathFlag user
             zombie:setTarget(flagPlayer)
             zombie:setTargetSeenTime(3000)
             return
         end
     end
end

-- Common range check function
local function isZombieInDeathFlagRange(zombie, flagPlayer, flagRange)
    if not zombie or not flagPlayer or zombie:isDead() or flagPlayer:isDead() then
        return false
    end
    
    local zombieX = zombie:getX()
    local zombieY = zombie:getY()
    local flagX = flagPlayer:getX()
    local flagY = flagPlayer:getY()
    local distance = math.sqrt((zombieX - flagX)^2 + (zombieY - flagY)^2)
    
    return distance <= flagRange
end

-- Register events (optimized version)
-- OnTick is for overall zombie targeting management
Events.OnTick.Add(updateZombiesForDeathFlag)
-- OnZombieUpdate is for individual zombie's real-time response (more immediate)
Events.OnZombieUpdate.Add(onZombieUpdate) 