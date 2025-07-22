-- Qpocalypse15 DeathFlag - Client Module

-- ***************************************************************************
-- * DeathFlag Extended Functionality                                        *
-- ***************************************************************************

-- Internal state tables/flags
Qpocalypse15_DeathFlagClient.noisePlayer = nil
Qpocalypse15_DeathFlagClient.noiseEndTime = 0
Qpocalypse15_DeathFlagClient.isNoiseEventAdded = false

Qpocalypse15_DeathFlagClient.protectedPlayers = {} -- [onlineID] = { player = IsoPlayer, endTime = number }
Qpocalypse15_DeathFlagClient.isZombieEventAdded = false

-- Utility : current real-time in milliseconds (Project Zomboid helper)
local function getNowMs()
    return getTimestampMs and getTimestampMs() or (os.time() * 1000)
end

-- World noise every in-game minute for 30 real-time seconds

function Qpocalypse15_DeathFlagClient.NoiseEvent()
    if not Qpocalypse15_DeathFlagClient.noisePlayer then return end

    local now = getNowMs()
    if now > Qpocalypse15_DeathFlagClient.noiseEndTime then
        -- Stop the noise event
        Events.EveryOneMinute.Remove(Qpocalypse15_DeathFlagClient.NoiseEvent)
        Qpocalypse15_DeathFlagClient.isNoiseEventAdded = false
        Qpocalypse15_DeathFlagClient.noisePlayer = nil
        return
    end

    local p = Qpocalypse15_DeathFlagClient.noisePlayer
    AddWorldSound(p, 50, 100)
end

function Qpocalypse15_DeathFlagClient.StartNoise(player)
    Qpocalypse15_DeathFlagClient.noisePlayer = player
    Qpocalypse15_DeathFlagClient.noiseEndTime = getNowMs() + 30000 -- 30 real-time seconds

    if not Qpocalypse15_DeathFlagClient.isNoiseEventAdded then
        Events.EveryOneMinute.Add(Qpocalypse15_DeathFlagClient.NoiseEvent)
        Qpocalypse15_DeathFlagClient.isNoiseEventAdded = true
    end
end

-- Temporary zombie ignorance for nearby players (20 tiles, 30s)
function Qpocalypse15_DeathFlagClient.AddProtectedPlayer(tgtPlayer)
    if not tgtPlayer then return end

    -- Save current alpha and apply semi-transparency
    local originalAlpha = tgtPlayer:getAlpha()
    tgtPlayer:setAlpha(0.5) -- semi-transparent

    Qpocalypse15_DeathFlagClient.protectedPlayers[tgtPlayer:getOnlineID()] = {
        player        = tgtPlayer,
        endTime       = getNowMs() + 30000, -- 30 seconds protection
        originalAlpha = originalAlpha
    }

    -- Ensure zombie update hook is present
    if not Qpocalypse15_DeathFlagClient.isZombieEventAdded then
        Events.OnZombieUpdate.Add(Qpocalypse15_DeathFlagClient.OnZombieUpdate)
        Qpocalypse15_DeathFlagClient.isZombieEventAdded = true
    end
end

function Qpocalypse15_DeathFlagClient.OnZombieUpdate(zombie)
    local now = getNowMs()
    local removeList = {}

    for id, data in pairs(Qpocalypse15_DeathFlagClient.protectedPlayers) do
        if now > data.endTime then
            table.insert(removeList, id)
        else
            local p = data.player
            if p and zombie:getTarget() == p then
                zombie:setTarget(nil)
            end
        end
    end

    -- Clean up expired protections
    for _, id in ipairs(removeList) do
        local data = Qpocalypse15_DeathFlagClient.protectedPlayers[id]
        if data and data.player then
            -- Restore original transparency
            data.player:setAlpha(data.originalAlpha or 1.0)
        end
        Qpocalypse15_DeathFlagClient.protectedPlayers[id] = nil
    end

    -- Remove event if table empty
    local isEmpty = true
    for _ in pairs(Qpocalypse15_DeathFlagClient.protectedPlayers) do
        isEmpty = false
        break
    end
    if isEmpty and Qpocalypse15_DeathFlagClient.isZombieEventAdded then
        Events.OnZombieUpdate.Remove(Qpocalypse15_DeathFlagClient.OnZombieUpdate)
        Qpocalypse15_DeathFlagClient.isZombieEventAdded = false
    end
end

-- Helper to register all nearby players (excluding source) within 20 tiles
function Qpocalypse15_DeathFlagClient.RegisterNearbyPlayers(sourcePlayer)
    local sx, sy = sourcePlayer:getX(), sourcePlayer:getY()
    for i = 0, getNumActivePlayers() - 1 do
        local other = getSpecificPlayer(i)
        if other and other ~= sourcePlayer then
            local dx = sx - other:getX()
            local dy = sy - other:getY()
            if (dx * dx + dy * dy) <= 400 then -- 20 tiles squared
                Qpocalypse15_DeathFlagClient.AddProtectedPlayer(other)
            end
        end
    end
end

-- Add DeathFlag context menu
local function onFillInventoryObjectContextMenu(player, context, items)
    if not player or not items then return end
    local items = ISInventoryPane.getActualItems(items)
    
    for _, item in ipairs(items) do
        if item:getFullType() == "Qpocalypse15.DeathFlag" then
            context:addOption(getText("ContextMenu_Qpocalypse15_DeathFlag"), player, Qpocalypse15_DeathFlagClient.RaiseDeathFlag)
        end
    end
end

function Qpocalypse15_DeathFlagClient.DeleteDeathFlagItem(player, item)
    local player = getPlayer()
    player:getInventory():Remove(item)
end

function Qpocalypse15_DeathFlagClient.RaiseDeathFlag()
    local player = getPlayer()
    local deathFlag = player:getInventory():getFirstTypeRecurse("Qpocalypse15.DeathFlag")
    if deathFlag then
        Qpocalypse15_DeathFlagClient.DeleteDeathFlagItem(player, deathFlag)

        -- Player says a random death flag line
        local randomIndex = ZombRand(10) + 1
        local textKey = "IGUI_PlayerText_DeathFlag" .. tostring(randomIndex)
        local line = getText(textKey)
        if line and line ~= "" then
            player:Say(line)
        end

        -- Start periodic noise for 30 real-time seconds
        Qpocalypse15_DeathFlagClient.StartNoise(player)

        -- Protect nearby players from zombie aggro for 30 real-time seconds
        Qpocalypse15_DeathFlagClient.RegisterNearbyPlayers(player)
        
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)