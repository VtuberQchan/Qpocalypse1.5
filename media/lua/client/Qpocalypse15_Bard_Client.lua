-- Qpocalypse15 Bard System - Client Module

require "Qpocalypse15_Bard"

Qpocalypse15_BardClient = {}

-- Client-side bard state management
Qpocalypse15_BardClient.playerBardState = {}
Qpocalypse15_BardClient.activeBardPlayers = {}

-- Simple playing state check variable
Qpocalypse15_BardClient.isCurrentlyPlaying = false

-- Helper function for destroying guitar and unequipping
function Qpocalypse15_BardClient.destroyGuitarItem(player, guitar)
    if not player or not guitar then return end

    -- Unequip if the item in hand is the guitar
    if player:getPrimaryHandItem() == guitar then
        player:setPrimaryHandItem(nil)
    end
    if player:getSecondaryHandItem() == guitar then
        player:setSecondaryHandItem(nil)
    end

    -- Remove from inventory
    player:getInventory():Remove(guitar)
end

-- Add bard context menu
local function onFillInventoryObjectContextMenu(player, context, items)
    if not player or not items then return end
    local items = ISInventoryPane.getActualItems(items)
    
    for _, item in ipairs(items) do
        if item:getFullType() == "Qpocalypse15.BardGuitarAcoustic" then
            if not Qpocalypse15_BardClient.isCurrentlyPlaying then
                context:addOption(getText("ContextMenu_Qpocalypse15_PlayBard"), player, Qpocalypse15_BardClient.startPlayingBard)
            end
            break
        end
    end
end

-- Start playing bard
function Qpocalypse15_BardClient.startPlayingBard()
    
    local player = getPlayer()
    -- Save player unique ID (compatible with single and multiplayer)
    local playerID = player:getOnlineID()
    local guitar = player:getInventory():getFirstTypeRecurse("Qpocalypse15.BardGuitarAcoustic")
    
    -- Equip guitar (since it's a two-handed weapon, we need to set Secondary as well)
    
    player:setPrimaryHandItem(guitar)
    player:setSecondaryHandItem(guitar)
    
    -- Check if equipment is successful
    if not Qpocalypse15_Bard.isPlayerEquippedWithBardGuitar(player) then
        print("Qpocalypse15 Bard: Failed to equip guitar, aborting")
        return
    end
    
    -- Select random music and prepare 3D clip
    local musicFile  = Qpocalypse15_Bard.getRandomMusicFile()
    local gameSound  = GameSounds and GameSounds.getSound(musicFile) or nil
    local clip       = gameSound and gameSound:getRandomClip() or nil
    -- Create 3D emitter (player position)
    local emitter    = getWorld():getFreeEmitter(player:getX(), player:getY(), player:getZ())
    local soundID    = nil
    if emitter and clip then
        soundID = emitter:playClip(clip, nil) -- 3D play (default true)
    else
        print("Qpocalypse15 Bard: failed to obtain emitter or clip")
    end
    
    -- Notify server of playing start (safe transmission)
    if sendClientCommand then
        sendClientCommand(player, "Qpocalypse15_Bard", "StartPlaying", {
            playerID = playerID,
            musicFile = musicFile,
            x = player:getX(),
            y = player:getY(),
            z = player:getZ()
        })
    end
    
    -- Update client state (sound handled by server response)
    Qpocalypse15_BardClient.playerBardState[playerID] = {
        state     = Qpocalypse15_Bard.BardState.PLAYING,
        musicFile = musicFile,
        guitar    = guitar,
        emitter   = emitter,
        soundID   = soundID,
        startTime = getTimestamp()
    }
    
    -- Set playing state flag
    Qpocalypse15_BardClient.isCurrentlyPlaying = true
end

-- Stop playing bard (manual stop - currently unused, can be used when UI is expanded)
function Qpocalypse15_BardClient.stopPlayingBard(player, destroyGuitar)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local bardState = Qpocalypse15_BardClient.playerBardState[playerID]
    
    if bardState and bardState.state == Qpocalypse15_Bard.BardState.PLAYING then
        -- Notify server of stop playing (safe transmission)
        if sendClientCommand then
            sendClientCommand(player, "Qpocalypse15_Bard", "StopPlaying", {
                playerID = playerID,
                destroyGuitar = destroyGuitar
            })
        end
        
        -- Stop sound (only own sound)
        if bardState.emitter and bardState.soundID then
            if bardState.emitter.stopSound then
                bardState.emitter:stopSound(bardState.soundID)
            else
                bardState.emitter:stopAll()
            end
        end
        
        -- Destroy guitar (only possible on client)
        if destroyGuitar and bardState.guitar then
            Qpocalypse15_BardClient.destroyGuitarItem(player, bardState.guitar)
            print("Qpocalypse15 Bard: Guitar destroyed for local player")
        end
        
        -- Initialize state
        Qpocalypse15_BardClient.playerBardState[playerID] = {
            state = Qpocalypse15_Bard.BardState.IDLE,
            musicFile = nil,
            guitar = nil,
            emitter = nil,
            soundID = nil
        }
        
        -- Reset playing state flag
        Qpocalypse15_BardClient.isCurrentlyPlaying = false
    end
end

-- Counter for performance optimization
Qpocalypse15_BardClient.updateCounter = 0

-- Detect equipment change and apply bard effects
local function onPlayerUpdate(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local bardState = Qpocalypse15_BardClient.playerBardState[playerID]
    
    if bardState and bardState.state == Qpocalypse15_Bard.BardState.PLAYING then
        -- Update 3D sound position and tick
        if bardState.emitter then
            bardState.emitter:setPos(player:getX(), player:getY(), player:getZ())
            bardState.emitter:tick()
        end
        
        -- Check if bard guitar is unequipped (important to check every time)
        if not Qpocalypse15_Bard.isPlayerEquippedWithBardGuitar(player) then
            -- Immediately process when unequipped (avoid duplicates)
            if bardState.emitter and bardState.soundID then
                if bardState.emitter.stopSound then
                    bardState.emitter:stopSound(bardState.soundID)
                else
                    bardState.emitter:stopAll()
                end
            end
            
            -- Immediately destroy guitar (already unequipped, so destroy guitar object)
            if bardState.guitar then
                Qpocalypse15_BardClient.destroyGuitarItem(player, bardState.guitar)
                print("Qpocalypse15 Bard: Guitar unequipped and destroyed")
            end
            
            -- Initialize state
            Qpocalypse15_BardClient.playerBardState[playerID] = {
                state = Qpocalypse15_Bard.BardState.IDLE,
                musicFile = nil,
                guitar = nil,
                emitter = nil,
                soundID = nil
            }
            
            -- Reset playing state flag
            Qpocalypse15_BardClient.isCurrentlyPlaying = false
            
            -- Notify server of state update only (guitar is already destroyed)
            if sendClientCommand then
                sendClientCommand(player, "Qpocalypse15_Bard", "StopPlaying", {
                    playerID = playerID,
                    destroyGuitar = false
                })
            end
        end
        
        -- Check own sound state (performance optimization: only 10 times per second)
        if Qpocalypse15_BardClient.updateCounter % 10 == 0 then
            Qpocalypse15_BardClient.checkMyBardSound(player)
        end
    end
    
    -- Performance optimization: only 10 times per second (approximately 1 second)
    Qpocalypse15_BardClient.updateCounter = Qpocalypse15_BardClient.updateCounter + 1
    if Qpocalypse15_BardClient.updateCounter % 10 == 0 then
        Qpocalypse15_BardClient.applyBardEffectsToLocalPlayer(player)
        Qpocalypse15_BardClient.updateBardPlayerPositions()
    end
end

-- Apply bard effects to local player
function Qpocalypse15_BardClient.applyBardEffectsToLocalPlayer(player)
    if not player or not player:isAlive() then return end
    
    local playerX = player:getX()
    local playerY = player:getY()
    local playerZ = player:getZ()
    
    -- Check if in range of active bard players
    local inBardRange = false
    for bardPlayerID, bardData in pairs(Qpocalypse15_BardClient.activeBardPlayers) do
        if bardData and bardData.x and bardData.y and bardData.z == playerZ then
            local distance = Qpocalypse15_Bard.getDistance(playerX, playerY, bardData.x, bardData.y)
            if distance <= Qpocalypse15_Bard.CALM_RANGE then
                inBardRange = true
                break
            end
        end
    end
    
    -- Check if you are playing bard
    local playerID = player:getOnlineID()
    local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
    if myBardState and myBardState.state == Qpocalypse15_Bard.BardState.PLAYING then
        inBardRange = true
    end
    
    -- Apply calm effect if in bard range
    if inBardRange then
        local stats = player:getStats()
        local bodyDamage = player:getBodyDamage()
        
        -- Reduce panic and stress (10 points at a time, minimum 0)
        local newPanic   = math.max(0, stats:getPanic()   - 10)
        local newStress  = math.max(0, stats:getStress()  - 10)
        stats:setPanic(newPanic)
        stats:setStress(newStress)
        
        -- Decrease unhappiness (balanced adjustment)
        local currentUnhappiness = bodyDamage:getUnhappynessLevel()
        if currentUnhappiness > 0 then
            local newUnhappiness = math.max(0, currentUnhappiness - 5) -- Adjusted to 5 for continuous application
            bodyDamage:setUnhappynessLevel(newUnhappiness)
        end
    end
end

-- Update bard player positions and check sound state
function Qpocalypse15_BardClient.updateBardPlayerPositions()
    -- Get list of players (compatible with single and multi-player)
    local allPlayers = nil
    if isClient() and getOnlinePlayers then
        allPlayers = getOnlinePlayers()
    elseif IsoPlayer.getPlayers then
        allPlayers = IsoPlayer.getPlayers()
    else
        -- Return if player list cannot be obtained
        return
    end
    
    -- Get local player only once (performance optimization)
    local localPlayer = getPlayer() or (getSpecificPlayer and getSpecificPlayer(0))
    
    local playersToRemove = {}
    
    for playerID, bardData in pairs(Qpocalypse15_BardClient.activeBardPlayers) do
        -- Find the corresponding player (disconnect detection)
        local bardPlayer = nil
        for i = 0, allPlayers:size() - 1 do
            local player = allPlayers:get(i)
            if player and player:getOnlineID() == playerID then
                bardPlayer = player
                break
            end
        end
        
        if not bardPlayer then
            -- Clean up if player disconnected
            table.insert(playersToRemove, playerID)
            print("Qpocalypse15 Bard: Player " .. playerID .. " disconnected, cleaning up")
        elseif bardData.emitter and bardData.soundID then
            -- Check sound playing state
            local isStillPlaying = false
            if bardData.emitter.isPlaying then
                isStillPlaying = bardData.emitter:isPlaying(bardData.soundID)
            end
            
            if not isStillPlaying then
                -- Clean up only locally if sound ended
                table.insert(playersToRemove, playerID)
                print("Qpocalypse15 Bard: Music ended for player: " .. playerID .. " (local cleanup)")
            else
                -- Update position if player is alive and sound is playing
                    -- Update emitter position to player's current position
                    local newX, newY, newZ = bardPlayer:getX(), bardPlayer:getY(), bardPlayer:getZ()
                    
                    -- Check distance (check if PLAY_RANGE is exceeded)
                    local isInRange = false
                    if localPlayer then
                        local distance = Qpocalypse15_Bard.getDistance(localPlayer:getX(), localPlayer:getY(), newX, newY)
                        local isSameLevel = localPlayer:getZ() == newZ
                        isInRange = isSameLevel and distance <= Qpocalypse15_Bard.PLAY_RANGE
                    end
                    
                    if not isInRange then
                        -- Stop sound only if out of range (keep state to allow re-entry)
                        if bardData.emitter and bardData.soundID then
                            if bardData.emitter.stopSound then
                                bardData.emitter:stopSound(bardData.soundID)
                            else
                                bardData.emitter:stopAll()
                            end
                            bardData.emitter = nil
                            bardData.soundID = nil
                            bardData.resyncRequested = false  -- Reset resync flag
                        end
                        print("Qpocalypse15 Bard: Player " .. playerID .. " out of range, sound paused")
                    elseif not bardData.emitter and isInRange then
                        -- Request resync to server if back in range (avoid duplicates)
                        if not bardData.resyncRequested and localPlayer and sendClientCommand then
                            sendClientCommand(localPlayer, "Qpocalypse15_Bard", "RequestResync", {
                                targetPlayerID = playerID
                            })
                            bardData.resyncRequested = true -- Avoid duplicate request flag
                            print("Qpocalypse15 Bard: Player " .. playerID .. " back in range, requesting resync")
                        end
                    elseif bardData.emitter and (math.abs(bardData.x - newX) > 0.1 or math.abs(bardData.y - newY) > 0.1 or bardData.z ~= newZ) then
                        -- Keep existing emitter and update position only
                        bardData.emitter:setPos(newX, newY, newZ)
                        bardData.emitter:tick()
                        bardData.x = newX
                        bardData.y = newY
                        bardData.z = newZ
                    end
                end
            end
        end
    
    -- Clean up players to remove (prevent memory leaks)
    for _, playerID in ipairs(playersToRemove) do
        local bardData = Qpocalypse15_BardClient.activeBardPlayers[playerID]
        if bardData then
            -- Safely clean up emitter
            if bardData.emitter then
                if bardData.soundID and bardData.emitter.stopSound then
                    bardData.emitter:stopSound(bardData.soundID)
                else
                    bardData.emitter:stopAll()
                end
                -- Remove emitter reference completely
                bardData.emitter = nil
                bardData.soundID = nil
            end
        end
        Qpocalypse15_BardClient.activeBardPlayers[playerID] = nil
    end
end

-- Check own bard sound state
function Qpocalypse15_BardClient.checkMyBardSound(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
    
    if myBardState and myBardState.state == Qpocalypse15_Bard.BardState.PLAYING then
        if myBardState.emitter and myBardState.soundID then
            -- Safe isPlaying call
            local isStillPlaying = false
            if myBardState.emitter.isPlaying then
                isStillPlaying = myBardState.emitter:isPlaying(myBardState.soundID)
            end
            
            if not isStillPlaying then
                -- Immediately process if own sound ended
                myBardState.state = Qpocalypse15_Bard.BardState.IDLE
                
                -- Reset playing state flag
                Qpocalypse15_BardClient.isCurrentlyPlaying = false
                if myBardState.emitter then
                    myBardState.emitter:stopAll()
                end
                
                -- Immediately destroy guitar (no delay)
                if myBardState.guitar then
                    Qpocalypse15_BardClient.destroyGuitarItem(player, myBardState.guitar)
                    print("Qpocalypse15 Bard: My music ended, guitar destroyed immediately")
                end
                
                -- Initialize state
                Qpocalypse15_BardClient.playerBardState[playerID] = {
                    state = Qpocalypse15_Bard.BardState.IDLE,
                    musicFile = nil,
                    guitar = nil,
                    emitter = nil,
                    soundID = nil
                }
                
                -- Notify server of state update (guitar is already destroyed)
                if sendClientCommand then
                    sendClientCommand(player, "Qpocalypse15_Bard", "StopPlaying", {
                        playerID = playerID,
                        destroyGuitar = false  -- Already destroyed, so false
                    })
                end
            end
        end
    end
end

-- Process bard start command from server
local function onServerCommand(module, command, args)
    if module ~= "Qpocalypse15_Bard" then return end
    
    if command == "StartPlayingForClients" then
        local playerID = args.playerID
        local musicFile = args.musicFile
        local x, y, z = args.x, args.y, args.z
        -- Get local player safely
        local localPlayer = nil
        if getPlayer then
            localPlayer = getPlayer()
        elseif getSpecificPlayer then
            localPlayer = getSpecificPlayer(0) -- For single player
        end
        
        -- Check distance (check if PLAY_RANGE is within)
        local shouldPlaySound = false
        if localPlayer then
            local distance = Qpocalypse15_Bard.getDistance(localPlayer:getX(), localPlayer:getY(), x, y)
            local isSameLevel = localPlayer:getZ() == z
            
            if localPlayer:getOnlineID() == playerID then
                -- Own bard always plays
                shouldPlaySound = true
            elseif isSameLevel and distance <= Qpocalypse15_Bard.PLAY_RANGE then
                -- Other player's bard only plays if in range
                shouldPlaySound = true
            end
        end
        
        if shouldPlaySound then
            -- Play music
            local emitter = getWorld():getFreeEmitter(x, y, z)
            if emitter then
                local soundID = emitter:playSound(musicFile)
                
                if not soundID then
                    print("Qpocalypse15 Bard: Failed to play sound: " .. musicFile)
                    
                    -- Need to restore state if own bard
                    if localPlayer and localPlayer:getOnlineID() == playerID then
                        local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
                        if myBardState then
                            -- Immediately destroy guitar and clean up state
                            if myBardState.guitar then
                                Qpocalypse15_BardClient.destroyGuitarItem(localPlayer, myBardState.guitar)
                                print("Qpocalypse15 Bard: Guitar destroyed due to sound failure")
                            end
                            
                            Qpocalypse15_BardClient.playerBardState[playerID] = {
                                state = Qpocalypse15_Bard.BardState.IDLE,
                                musicFile = nil,
                                guitar = nil,
                                emitter = nil,
                                soundID = nil
                            }
                            
                            -- Notify server of failure (safe transmission)
                            if sendClientCommand and localPlayer then
                                sendClientCommand(localPlayer, "Qpocalypse15_Bard", "StopPlaying", {
                                    playerID = playerID,
                                    destroyGuitar = false
                                })
                            end
                        end
                    end
                    return
                end
                
                -- Distinguish between own and other players
                if localPlayer and localPlayer:getOnlineID() == playerID then
                    -- Update own bard state
                    local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
                    if myBardState then
                        myBardState.emitter = emitter
                        myBardState.soundID = soundID
                    end
                else
                -- Add other player's bard state
                Qpocalypse15_BardClient.activeBardPlayers[playerID] = {
                    emitter = emitter,
                    soundID = soundID,
                    musicFile = musicFile,
                    x = x, y = y, z = z,
                    resyncRequested = false  -- Resync request flag
                }
                end
            else
                print("Qpocalypse15 Bard: Failed to get free emitter at " .. x .. ", " .. y .. ", " .. z)
            end
        else
            print("Qpocalypse15 Bard: Player out of range (" .. Qpocalypse15_Bard.PLAY_RANGE .. "), not playing sound")
        end
        
    elseif command == "StopPlayingForClients" then
        local playerID = args.playerID
        local localPlayer = nil
        if getPlayer then
            localPlayer = getPlayer()
        elseif getSpecificPlayer then
            localPlayer = getSpecificPlayer(0)
        end
        
        -- Clean up local state if own bard
        if localPlayer and localPlayer:getOnlineID() == playerID then
            local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
            if myBardState and myBardState.state == Qpocalypse15_Bard.BardState.PLAYING then
                if myBardState.emitter and myBardState.soundID then
                    if myBardState.emitter.stopSound then
                        myBardState.emitter:stopSound(myBardState.soundID)
                    else
                        myBardState.emitter:stopAll()
                    end
                end
                
                -- Additional guitar destruction (duplicate check)
                -- May already be processed on client, but check for safety
                if args.destroyGuitar then
                    local stillHasGuitar = false
                    local primaryItem = localPlayer:getPrimaryHandItem()
                    local secondaryItem = localPlayer:getSecondaryHandItem()
                    
                    if (primaryItem and primaryItem:getType() == "BardGuitarAcoustic") or
                       (secondaryItem and secondaryItem:getType() == "BardGuitarAcoustic") then
                        stillHasGuitar = true
                    end
                    
                    if stillHasGuitar then
                        local targetItem = primaryItem or secondaryItem
                        if targetItem then
                            Qpocalypse15_BardClient.destroyGuitarItem(localPlayer, targetItem)
                            print("Qpocalypse15 Bard: Guitar destroyed by server request (fallback)")
                        end
                    end
                end
                
                -- Initialize state
                Qpocalypse15_BardClient.playerBardState[playerID] = {
                    state = Qpocalypse15_Bard.BardState.IDLE,
                    musicFile = nil,
                    guitar = nil,
                    emitter = nil,
                    soundID = nil
                }
            end
        else
            -- If other player's bard
            local bardPlayer = Qpocalypse15_BardClient.activeBardPlayers[playerID]
            if bardPlayer and bardPlayer.emitter then
                if bardPlayer.emitter.stopSound and bardPlayer.soundID then
                    bardPlayer.emitter:stopSound(bardPlayer.soundID)
                else
                    bardPlayer.emitter:stopAll()
                end
            end
        end
        
        -- Remove from active bard player list
        Qpocalypse15_BardClient.activeBardPlayers[playerID] = nil
    end
end

-- Clean up bard state when player dies (local only, server handles itself)
local function onPlayerDeath(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local localPlayer = getPlayer()
    
    -- Clean up own bard state if local player died
    if localPlayer and localPlayer:getOnlineID() == playerID then
        local bardState = Qpocalypse15_BardClient.playerBardState[playerID]
        if bardState and bardState.state == Qpocalypse15_Bard.BardState.PLAYING then
            -- Stop sound
            if bardState.emitter and bardState.soundID then
                if bardState.emitter.stopSound then
                    bardState.emitter:stopSound(bardState.soundID)
                else
                    bardState.emitter:stopAll()
                end
            end
            
            -- Initialize state
            Qpocalypse15_BardClient.playerBardState[playerID] = {
                state = Qpocalypse15_Bard.BardState.IDLE,
                musicFile = nil,
                guitar = nil,
                emitter = nil,
                soundID = nil
            }
            
            -- Reset playing state flag
            Qpocalypse15_BardClient.isCurrentlyPlaying = false
            
            print("Qpocalypse15 Bard: Local player died, bard state cleared")
        end
    end
    
    -- Remove from activeBardPlayers if other player died
    if Qpocalypse15_BardClient.activeBardPlayers[playerID] then
        local bardData = Qpocalypse15_BardClient.activeBardPlayers[playerID]
        if bardData.emitter then
            if bardData.soundID and bardData.emitter.stopSound then
                bardData.emitter:stopSound(bardData.soundID)
            else
                bardData.emitter:stopAll()
            end
        end
        Qpocalypse15_BardClient.activeBardPlayers[playerID] = nil
        print("Qpocalypse15 Bard: Removed dead player " .. playerID .. " from active bards")
    end
end

-- Register events
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnServerCommand.Add(onServerCommand)
Events.OnPlayerDeath.Add(onPlayerDeath) 