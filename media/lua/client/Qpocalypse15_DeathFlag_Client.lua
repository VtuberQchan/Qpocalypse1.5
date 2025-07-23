-- Qpocalypse15 DeathFlag - Client Module

Qpocalypse15_DeathFlagClient = Qpocalypse15_DeathFlagClient or {}

-- Internal state tables/flags - Safe initialization
Qpocalypse15_DeathFlagClient.noisePlayer = Qpocalypse15_DeathFlagClient.noisePlayer or nil
Qpocalypse15_DeathFlagClient.noiseEndTime = Qpocalypse15_DeathFlagClient.noiseEndTime or 0
Qpocalypse15_DeathFlagClient.isNoiseEventAdded = Qpocalypse15_DeathFlagClient.isNoiseEventAdded or false

-- Ensure protectedPlayers is always a table
if not Qpocalypse15_DeathFlagClient.protectedPlayers or type(Qpocalypse15_DeathFlagClient.protectedPlayers) ~= 'table' then
    Qpocalypse15_DeathFlagClient.protectedPlayers = {}
end
Qpocalypse15_DeathFlagClient.isZombieEventAdded = Qpocalypse15_DeathFlagClient.isZombieEventAdded or false
-- Flag to ensure ProtectionTimer is only added once
Qpocalypse15_DeathFlagClient.isProtectionTimerAdded = Qpocalypse15_DeathFlagClient.isProtectionTimerAdded or false

-- Constants
local PROTECTION_LOOPS = 40  -- Number of EveryOneMinute ticks before protection expires

local function isTableEmpty(tbl)
    if type(tbl) ~= 'table' then return true end
    for _ in pairs(tbl) do
        return false
    end
    return true
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
    Qpocalypse15_DeathFlagClient.noiseEndTime = getNowMs() + 5000 -- 5 real-time seconds

    if not Qpocalypse15_DeathFlagClient.isNoiseEventAdded then
        Events.EveryOneMinute.Add(Qpocalypse15_DeathFlagClient.NoiseEvent)
        Qpocalypse15_DeathFlagClient.isNoiseEventAdded = true
    end
end

-- Temporary zombie ignorance for nearby players (20 tiles, 30s)
function Qpocalypse15_DeathFlagClient.AddProtectedPlayer(tgtPlayer)
    if not tgtPlayer then return end

    -- Safe initialization
    if not Qpocalypse15_DeathFlagClient.protectedPlayers or type(Qpocalypse15_DeathFlagClient.protectedPlayers) ~= 'table' then
        Qpocalypse15_DeathFlagClient.protectedPlayers = {}
    end

    -- Save current alpha and apply semi-transparency
    local originalAlpha = tgtPlayer:getAlpha()
    tgtPlayer:setAlpha(0.5) -- semi-transparent

    Qpocalypse15_DeathFlagClient.protectedPlayers[tgtPlayer:getOnlineID()] = {
        player        = tgtPlayer,
        loopsLeft     = PROTECTION_LOOPS, -- expire after 40 in-game minutes
        originalAlpha = originalAlpha
    }

    -- Ensure zombie update hook is present
    if not Qpocalypse15_DeathFlagClient.isZombieEventAdded then
        Events.OnZombieUpdate.Add(Qpocalypse15_DeathFlagClient.OnZombieUpdate)
        Qpocalypse15_DeathFlagClient.isZombieEventAdded = true
    end

    -- Ensure protection timer (EveryOneMinute) is present
    if not Qpocalypse15_DeathFlagClient.isProtectionTimerAdded then
        Events.EveryOneMinute.Add(Qpocalypse15_DeathFlagClient.ProtectionTimer)
        Qpocalypse15_DeathFlagClient.isProtectionTimerAdded = true
    end
end

-- Decrement protection loops every in-game minute
function Qpocalypse15_DeathFlagClient.ProtectionTimer()
    if not Qpocalypse15_DeathFlagClient.protectedPlayers or type(Qpocalypse15_DeathFlagClient.protectedPlayers) ~= 'table' then
        Qpocalypse15_DeathFlagClient.protectedPlayers = {}
    end

    local removeList = {}

    for id, data in pairs(Qpocalypse15_DeathFlagClient.protectedPlayers) do
        if type(data) ~= 'table' or not data.loopsLeft then
            table.insert(removeList, id)
        else
            data.loopsLeft = data.loopsLeft - 1
            if data.loopsLeft <= 0 then
                table.insert(removeList, id)
            end
        end
    end

    -- Cleanup expired protections
    for _, id in ipairs(removeList) do
        local data = Qpocalypse15_DeathFlagClient.protectedPlayers[id]
        if data and data.player then
            data.player:setAlpha(data.originalAlpha or 1.0)
        end
        Qpocalypse15_DeathFlagClient.protectedPlayers[id] = nil
    end

    -- Remove timer if table empty
    if isTableEmpty(Qpocalypse15_DeathFlagClient.protectedPlayers) and Qpocalypse15_DeathFlagClient.isProtectionTimerAdded then
        Events.EveryOneMinute.Remove(Qpocalypse15_DeathFlagClient.ProtectionTimer)
        Qpocalypse15_DeathFlagClient.isProtectionTimerAdded = false
    end
end

function Qpocalypse15_DeathFlagClient.OnZombieUpdate(zombie)
    -- Safe initialization
    if not Qpocalypse15_DeathFlagClient.protectedPlayers or type(Qpocalypse15_DeathFlagClient.protectedPlayers) ~= 'table' then
        Qpocalypse15_DeathFlagClient.protectedPlayers = {}
        return
    end

    -- If table is empty, nothing to process
    if isTableEmpty(Qpocalypse15_DeathFlagClient.protectedPlayers) then
        return
    end

    local removeList = {}

    -- Double-check before using pairs() to prevent "Expected a table" error
    if type(Qpocalypse15_DeathFlagClient.protectedPlayers) ~= 'table' then
        Qpocalypse15_DeathFlagClient.protectedPlayers = {}
        return
    end

    for id, data in pairs(Qpocalypse15_DeathFlagClient.protectedPlayers) do
        if type(data) ~= 'table' or not data.loopsLeft or data.loopsLeft <= 0 then
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

    -- Remove events if table empty
    local isEmpty = (type(Qpocalypse15_DeathFlagClient.protectedPlayers) ~= 'table') or isTableEmpty(Qpocalypse15_DeathFlagClient.protectedPlayers)
    if isEmpty and Qpocalypse15_DeathFlagClient.isZombieEventAdded then
        Events.OnZombieUpdate.Remove(Qpocalypse15_DeathFlagClient.OnZombieUpdate)
        Qpocalypse15_DeathFlagClient.isZombieEventAdded = false
    end

    if isEmpty and Qpocalypse15_DeathFlagClient.isProtectionTimerAdded then
        Events.EveryOneMinute.Remove(Qpocalypse15_DeathFlagClient.ProtectionTimer)
        Qpocalypse15_DeathFlagClient.isProtectionTimerAdded = false
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

-- Utility : gather onlineIDs (source + 20tiles) -> broadcast to server
function Qpocalypse15_DeathFlagClient.GetNearbyPlayerIDs(sourcePlayer)
    local ids = { sourcePlayer:getOnlineID() }
    local sx, sy = sourcePlayer:getX(), sourcePlayer:getY()
    for i = 0, getNumActivePlayers() - 1 do
        local other = getSpecificPlayer(i)
        if other and other ~= sourcePlayer then
            local dx = sx - other:getX()
            local dy = sy - other:getY()
            if (dx * dx + dy * dy) <= 400 then
                table.insert(ids, other:getOnlineID())
            end
        end
    end
    return ids
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

        -- Send protected list to server (synchronise all client+server)
        local ids = Qpocalypse15_DeathFlagClient.GetNearbyPlayerIDs(player)
        sendClientCommand('DeathFlag', 'AddProtected', { ids = ids })
        
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)

-- Receive protected information from the server for client-side synchronisation
local function onServerCommand(module, command, args)
    if module == 'DeathFlag' and command == 'ProtectedAdd' and args and args.ids then
        if type(args.ids) == 'table' then
            for _, id in ipairs(args.ids) do
                for i = 0, getNumActivePlayers() - 1 do
                    local p = getSpecificPlayer(i)
                    if p and p:getOnlineID() == id then
                        Qpocalypse15_DeathFlagClient.AddProtectedPlayer(p)
                        break
                    end
                end
            end
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)