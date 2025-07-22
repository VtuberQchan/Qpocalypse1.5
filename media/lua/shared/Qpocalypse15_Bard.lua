-- Qpocalypse15 Bard System - Shared Module
-- Shared functions for the Bard system

Qpocalypse15_Bard = {}

-- Constants related to the Bard system
Qpocalypse15_Bard.PLAY_RANGE = 20  -- Play effect range
Qpocalypse15_Bard.CALM_RANGE = 20  -- Calm effect range
Qpocalypse15_Bard.MUSIC_FILES = {
    "Bardmusic1",
    "Bardmusic2", 
    "Bardmusic3",
    "Bardmusic4",
    "Bardmusic5"
}

-- Bard state
Qpocalypse15_Bard.BardState = {
    IDLE = 0,
    PLAYING = 1
}

-- Select a random music file
function Qpocalypse15_Bard.getRandomMusicFile()
    local index = ZombRand(#Qpocalypse15_Bard.MUSIC_FILES) + 1
    return Qpocalypse15_Bard.MUSIC_FILES[index]
end

-- Check if the player is equipped with a bard guitar
function Qpocalypse15_Bard.isPlayerEquippedWithBardGuitar(player)
    if not player then return false end
    
    local primaryWeapon = player:getPrimaryHandItem()
    if primaryWeapon and primaryWeapon:getType() == "BardGuitarAcoustic" then
        return true
    end
    
    local secondaryWeapon = player:getSecondaryHandItem()
    if secondaryWeapon and secondaryWeapon:getType() == "BardGuitarAcoustic" then
        return true
    end
    
    return false
end

-- Distance calculation function
function Qpocalypse15_Bard.getDistance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

-- Find players within a range
function Qpocalypse15_Bard.getPlayersInRange(centerPlayer, range)
    local players = {}
    local centerX = centerPlayer:getX()
    local centerY = centerPlayer:getY()
    local centerZ = centerPlayer:getZ()
    
    -- Get a list of players (single/multiplayer compatible)
    local allPlayers = nil
    if isClient() and getOnlinePlayers then
        allPlayers = getOnlinePlayers()
    elseif IsoPlayer.getPlayers then
        allPlayers = IsoPlayer.getPlayers()
    else
        -- If the player list cannot be obtained, return an empty table
        return players
    end
    
    if allPlayers then
        for i = 0, allPlayers:size() - 1 do
            local player = allPlayers:get(i)
            if player and player ~= centerPlayer and player:getZ() == centerZ then
                local distance = Qpocalypse15_Bard.getDistance(centerX, centerY, player:getX(), player:getY())
                if distance <= range then
                    table.insert(players, player)
                end
            end
        end
    end
    
    return players
end 