-- Qpocalypse15 Bard System - Server Module
-- Server-side implementation of the Bard system

require "Qpocalypse15_Bard"

Qpocalypse15_BardServer = {}

-- Server-side management of bard states
Qpocalypse15_BardServer.activeBards = {}

-- Process starting bard playing
function Qpocalypse15_BardServer.startBardPlaying(player, musicFile)
    if not player or not musicFile then return end
    
    local playerID = player:getOnlineID()
    local x, y, z = player:getX(), player:getY(), player:getZ()
    
    -- Save bard state
    Qpocalypse15_BardServer.activeBards[playerID] = {
        player = player,
        musicFile = musicFile,
        x = x, y = y, z = z
    }
    
    -- Send music playing command to all clients (safe transmission)
    if sendServerCommand then
        sendServerCommand("Qpocalypse15_Bard", "StartPlayingForClients", {
            playerID = playerID,
            musicFile = musicFile,
            x = x, y = y, z = z
        })
    end
    
    print("Qpocalypse15 Bard: Player " .. player:getDisplayName() .. " started playing " .. musicFile)
end

-- Process stopping bard playing
function Qpocalypse15_BardServer.stopBardPlaying(player, destroyGuitar)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local bardData = Qpocalypse15_BardServer.activeBards[playerID]
    
    if bardData then
        -- Guitar destruction is only possible on the client, so server does not handle it
        if destroyGuitar then
            print("Qpocalypse15 Bard: Guitar destruction requested for player: " .. player:getDisplayName() .. " (handled by client)")
        end
        
        -- Remove bard state
        Qpocalypse15_BardServer.activeBards[playerID] = nil
        
        -- Send music stop command to all clients (include destroyGuitar information)
        if sendServerCommand then
            sendServerCommand("Qpocalypse15_Bard", "StopPlayingForClients", {
                playerID = playerID,
                destroyGuitar = destroyGuitar  -- For client to determine additional guitar destruction
            })
        end
        
        print("Qpocalypse15 Bard: Player " .. player:getDisplayName() .. " stopped playing")
    end
end

-- Clean up bard states (handle disconnected/dead players)
function Qpocalypse15_BardServer.cleanupBardStates()
    local playersToRemove = {}
    
    for playerID, bardData in pairs(Qpocalypse15_BardServer.activeBards) do
        local bardPlayer = bardData.player
        
        if not bardPlayer or not bardPlayer:isAlive() then
            table.insert(playersToRemove, playerID)
        end
    end
    
    -- Remove players to clean up
    for _, playerID in ipairs(playersToRemove) do
        Qpocalypse15_BardServer.activeBards[playerID] = nil
        if sendServerCommand then
            sendServerCommand("Qpocalypse15_Bard", "StopPlayingForClients", {
                playerID = playerID
            })
        end
        print("Qpocalypse15 Bard: Cleaned up bard state for disconnected/dead player: " .. playerID)
    end
end

-- Process client commands
local function onClientCommand(module, command, player, args)
    if module ~= "Qpocalypse15_Bard" then return end
    
    if not player then return end
    
    if command == "StartPlaying" then
        local musicFile = args.musicFile
        -- Security check: Verify if the requester actually has a bard guitar
        if Qpocalypse15_Bard.isPlayerEquippedWithBardGuitar(player) then
            Qpocalypse15_BardServer.startBardPlaying(player, musicFile)
        else
            print("Qpocalypse15 Bard: Rejected StartPlaying from " .. player:getDisplayName() .. " - no guitar equipped")
        end
        
    elseif command == "StopPlaying" then
        local destroyGuitar = args.destroyGuitar
        local playerID = player:getOnlineID()
        
        -- Security check: Verify if the requester is actually in bard state
        if Qpocalypse15_BardServer.activeBards[playerID] then
            Qpocalypse15_BardServer.stopBardPlaying(player, destroyGuitar)
        else
            print("Qpocalypse15 Bard: Rejected StopPlaying from " .. player:getDisplayName() .. " - not in bard state")
        end
        
    elseif command == "RequestResync" then
        local targetPlayerID = args.targetPlayerID
        local bardData = Qpocalypse15_BardServer.activeBards[targetPlayerID]
        
        if bardData and bardData.player and not bardData.player:isDead() then
            -- If the player is still valid and playing, resend to requester
            if sendClientCommand then
                sendClientCommand(player, "Qpocalypse15_Bard", "StartPlayingForClients", {
                    playerID = targetPlayerID,
                    musicFile = bardData.musicFile,
                    x = bardData.player:getX(),
                    y = bardData.player:getY(),
                    z = bardData.player:getZ()
                })
                print("Qpocalypse15 Bard: Resync sent to " .. player:getDisplayName() .. " for player " .. targetPlayerID)
            end
        else
            print("Qpocalypse15 Bard: Resync rejected - target player invalid or dead")
        end
    end
end

-- Clean up bard state when player disconnects
local function onDisconnect(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    if Qpocalypse15_BardServer.activeBards[playerID] then
        Qpocalypse15_BardServer.stopBardPlaying(player, false)
    end
end

-- Regular bard state cleanup (every in-game minute)
local function onEveryOneMinute()
    Qpocalypse15_BardServer.cleanupBardStates()
end

-- Timer management function removed - not needed as client accurately detects sound end

-- Register events
Events.OnClientCommand.Add(onClientCommand)
Events.OnDisconnect.Add(onDisconnect)
Events.EveryOneMinute.Add(onEveryOneMinute)