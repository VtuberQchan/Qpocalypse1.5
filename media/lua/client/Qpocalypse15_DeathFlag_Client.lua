-- Qpocalypse15 DeathFlag - Client Module

Qpocalypse15_DeathFlagClient = Qpocalypse15_DeathFlagClient or {}

-- Internal state tables/flags - Safe initialization
Qpocalypse15_DeathFlagClient.noisePlayer = Qpocalypse15_DeathFlagClient.noisePlayer or nil
Qpocalypse15_DeathFlagClient.noiseEndTime = Qpocalypse15_DeathFlagClient.noiseEndTime or 0
Qpocalypse15_DeathFlagClient.noiseLoopsLeft = Qpocalypse15_DeathFlagClient.noiseLoopsLeft or 0
Qpocalypse15_DeathFlagClient.isNoiseEventAdded = Qpocalypse15_DeathFlagClient.isNoiseEventAdded or false

-- Ensure protectedPlayers is always a table
if not Qpocalypse15_DeathFlagClient.protectedPlayers or type(Qpocalypse15_DeathFlagClient.protectedPlayers) ~= 'table' then
    Qpocalypse15_DeathFlagClient.protectedPlayers = {}
end
Qpocalypse15_DeathFlagClient.isZombieEventAdded = Qpocalypse15_DeathFlagClient.isZombieEventAdded or false
-- Flag to ensure ProtectionTimer is only added once
Qpocalypse15_DeathFlagClient.isProtectionTimerAdded = Qpocalypse15_DeathFlagClient.isProtectionTimerAdded or false
Qpocalypse15_DeathFlagClient.isPlayerUpdateEventAdded = Qpocalypse15_DeathFlagClient.isPlayerUpdateEventAdded or false

-- Constants
local PROTECTION_LOOPS = 25  -- Number of EveryOneMinute ticks before protection expires

local SHOUT_SOUND_NAME = "QP15_Shouting"
local SHOUT_SOUND_RANGE = 40  -- Distance in tiles within which players hear the shout
local WOOSH_SOUND_NAME = "QP15_Woosh"

--[[---------------------------------------------
    MP-Safe Player Utilities
    Returns an ArrayList of all players that this client knows about.
    Works in single-player, split-screen and multiplayer servers.
--]]
local function DF_getAllPlayers()
    if isClient() and getOnlinePlayers then
        return getOnlinePlayers()
    elseif IsoPlayer.getPlayers then
        return IsoPlayer.getPlayers()
    end
    return nil
end

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

    -- If loops have expired, stop generating noise
    if Qpocalypse15_DeathFlagClient.noiseLoopsLeft <= 0 then
        -- Play end dialogue before cleaning up
        local p = Qpocalypse15_DeathFlagClient.noisePlayer
        if p then
            local endLine = getText("IGUI_PlayerText_DeathFlagEnd")
            if endLine and endLine ~= "" then
                p:Say(endLine)
            end
        end

        Events.EveryOneMinute.Remove(Qpocalypse15_DeathFlagClient.NoiseEvent)
        Qpocalypse15_DeathFlagClient.isNoiseEventAdded = false
        Qpocalypse15_DeathFlagClient.noisePlayer = nil
        return
    end

    local p = Qpocalypse15_DeathFlagClient.noisePlayer
    AddWorldSound(p, 50, 100)

    -- Decrease remaining loops
    Qpocalypse15_DeathFlagClient.noiseLoopsLeft = Qpocalypse15_DeathFlagClient.noiseLoopsLeft - 1
end

function Qpocalypse15_DeathFlagClient.StartNoise(player)
    Qpocalypse15_DeathFlagClient.noisePlayer = player
    -- Initialise loop counter based on constant (EveryOneMinute ticks)
    Qpocalypse15_DeathFlagClient.noiseLoopsLeft = PROTECTION_LOOPS

    if not Qpocalypse15_DeathFlagClient.isNoiseEventAdded then
        Events.EveryOneMinute.Add(Qpocalypse15_DeathFlagClient.NoiseEvent)
        Qpocalypse15_DeathFlagClient.isNoiseEventAdded = true
    end
end

-- Temporary zombie ignorance for nearby players (20 tiles, 30s)
--[[---------------------------------------------
    Player Update Hook : keep transparency enforced every frame (MP may reset alpha)
--]]
function Qpocalypse15_DeathFlagClient.OnPlayerUpdate(player)
    -- Nothing to do if table missing or empty
    if not Qpocalypse15_DeathFlagClient.protectedPlayers or isTableEmpty(Qpocalypse15_DeathFlagClient.protectedPlayers) then
        return
    end

    local pid = player:getOnlineID()
    local data = Qpocalypse15_DeathFlagClient.protectedPlayers[pid]
    if data and data.player == player then
        -- Ensure alpha is still semi-transparent (network updates sometimes reset it)
        if math.abs(player:getAlpha() - 0.5) > 0.01 then
            player:setAlpha(0.5)
        end
    end
end

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

    -- Local player announcement (always, even if renewed)
    local localPlayer = getPlayer() or (getSpecificPlayer and getSpecificPlayer(0))
    if localPlayer and localPlayer == tgtPlayer then
        local startLine = getText("IGUI_PlayerText_DeathFlagProtectionStart")
        if startLine and startLine ~= "" then
            tgtPlayer:Say(startLine)
        end
    end

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

    -- Ensure player update hook is present (maintain alpha)
    if not Qpocalypse15_DeathFlagClient.isPlayerUpdateEventAdded then
        Events.OnPlayerUpdate.Add(Qpocalypse15_DeathFlagClient.OnPlayerUpdate)
        Qpocalypse15_DeathFlagClient.isPlayerUpdateEventAdded = true
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

    -- Also remove player update hook if no one is protected
    if isTableEmpty(Qpocalypse15_DeathFlagClient.protectedPlayers) and Qpocalypse15_DeathFlagClient.isPlayerUpdateEventAdded then
        Events.OnPlayerUpdate.Remove(Qpocalypse15_DeathFlagClient.OnPlayerUpdate)
        Qpocalypse15_DeathFlagClient.isPlayerUpdateEventAdded = false
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

            -- If this is the local player's client, play woosh sound once
            local localPlayer = getPlayer() or (getSpecificPlayer and getSpecificPlayer(0))
            if localPlayer and data.player == localPlayer then
                localPlayer:Say("IGUI_PlayerText_DeathFlagProtectionEnd")
                -- 2D sound playback (non-positional)
                -- getSoundManager():PlaySound(WOOSH_SOUND_NAME, false, 1)
            end
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

    -- Remove player update hook if table empty
    if isEmpty and Qpocalypse15_DeathFlagClient.isPlayerUpdateEventAdded then
        Events.OnPlayerUpdate.Remove(Qpocalypse15_DeathFlagClient.OnPlayerUpdate)
        Qpocalypse15_DeathFlagClient.isPlayerUpdateEventAdded = false
    end
end

-- Helper to register all nearby players (excluding source) within 20 tiles
function Qpocalypse15_DeathFlagClient.RegisterNearbyPlayers(sourcePlayer)
    local sx, sy = sourcePlayer:getX(), sourcePlayer:getY()

    local allPlayers = DF_getAllPlayers()
    if not allPlayers then return end

    for i = 0, allPlayers:size() - 1 do
        local other = allPlayers:get(i)
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
    local ids = {}
    local sx, sy = sourcePlayer:getX(), sourcePlayer:getY()

    local allPlayers = DF_getAllPlayers()
    if not allPlayers then return ids end

    for i = 0, allPlayers:size() - 1 do
        local other = allPlayers:get(i)
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

function Qpocalypse15_DeathFlagClient.PlayShoutSound(x, y, z, sourcePlayerID)
    local localPlayer = nil
    if getPlayer then
        localPlayer = getPlayer()
    elseif getSpecificPlayer then
        localPlayer = getSpecificPlayer(0)
    end
    if not localPlayer then return end

    local shouldPlay = false
    if localPlayer:getOnlineID() == sourcePlayerID then
        shouldPlay = true
    else
        if localPlayer:getZ() == z then
            local dx = localPlayer:getX() - x
            local dy = localPlayer:getY() - y
            if (dx * dx + dy * dy) <= (SHOUT_SOUND_RANGE * SHOUT_SOUND_RANGE) then
                shouldPlay = true
            end
        end
    end

    if shouldPlay then
        local emitter = getWorld():getFreeEmitter(x, y, z)
        if emitter then
            local gameSound = GameSounds and GameSounds.getSound(SHOUT_SOUND_NAME) or nil
            local clip = gameSound and gameSound:getRandomClip() or nil

            if clip and emitter.playClip then
                emitter:playClip(clip, nil) -- 3D clip play (nil => default positional)
            else
                -- Fallback: play by sound name if clip is unavailable
                emitter:playSound(SHOUT_SOUND_NAME)
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
        if ids and #ids > 0 then
            sendClientCommand('DeathFlag', 'AddProtected', { ids = ids })
        end

        -- Notify server to broadcast shout sound to nearby players
        if sendClientCommand then
            sendClientCommand('DeathFlag', 'StartShoutSound', {
                playerID = player:getOnlineID(),
                x = player:getX(),
                y = player:getY(),
                z = player:getZ()
            })
        end
        
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)

-- Receive protected information from the server for client-side synchronisation
local function onServerCommand(module, command, args)
    if module ~= 'DeathFlag' then return end

    if command == 'ProtectedAdd' and args and args.ids then
        if type(args.ids) == 'table' then
            -- Obtain full player list once for efficiency
            local allPlayers = DF_getAllPlayers()
            if not allPlayers then return end

            for _, id in ipairs(args.ids) do
                local targetPlayer = nil
                for i = 0, allPlayers:size() - 1 do
                    local p = allPlayers:get(i)
                    if p and p:getOnlineID() == id then
                        targetPlayer = p
                        break
                    end
                end
                if targetPlayer then
                    Qpocalypse15_DeathFlagClient.AddProtectedPlayer(targetPlayer)
                end
            end
        end
    elseif command == 'StartShoutSound' and args then
        Qpocalypse15_DeathFlagClient.PlayShoutSound(args.x, args.y, args.z, args.playerID)
    end
end
Events.OnServerCommand.Add(onServerCommand)