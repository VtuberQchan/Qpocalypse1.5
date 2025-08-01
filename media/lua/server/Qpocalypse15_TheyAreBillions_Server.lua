-- Qpocalypse15 TheyAreBillions - Server Module
-- Handles the TAB (They Are Billions) horde survival event

------------------------------------------------------------------
-- Namespace / Safe initialisation
------------------------------------------------------------------
Qpocalypse15_TheyAreBillionsServer = Qpocalypse15_TheyAreBillionsServer or {}
local TAB = Qpocalypse15_TheyAreBillionsServer

------------------------------------------------------------------
-- Constants
------------------------------------------------------------------
local TELEPORT_X, TELEPORT_Y, TELEPORT_Z = 300, 150, 0               -- Arena centre
local CLEAR_X1, CLEAR_Y1, CLEAR_X2, CLEAR_Y2 = 0, 0, 600, 300       -- Map cleanup area
local SPAWN_RADIUS = 50                                            -- Max spawn distance from player
local SPAWN_PER_TICK = 10                                          -- Zombies per minute
local MAX_NEAR_ZOMBIES = 40                                        -- Skip spawn if ≥ this amount nearby
local EVENT_DURATION_HOURS = 8                                     -- 8 in-game hours

------------------------------------------------------------------
-- Internal State
------------------------------------------------------------------
TAB.active        = TAB.active        or false       -- true while an event is running
TAB.players       = TAB.players       or {}          -- [onlineID] = { player = IsoPlayer, ox = int, oy = int, oz = int }
TAB.endWorldHour  = TAB.endWorldHour  or 0           -- In-game world age hour when event ends
TAB.paused        = TAB.paused        or false
TAB.remainingHour = TAB.remainingHour or 0

------------------------------------------------------------------
-- Helper : check if there is at least one living participant
------------------------------------------------------------------
local function TAB_hasActivePlayer()
    for id, data in pairs(TAB.players) do
        local ply = data.player or getPlayerByOnlineID(id)
        if ply and not ply:isDead() then
            return true
        end
    end
    return false
end

------------------------------------------------------------------
-- Utility helpers
------------------------------------------------------------------
local function TAB_log(msg)
    print("[Qpocalypse TAB] " .. tostring(msg))
end

local function TAB_worldHours()
    -- Use GameTime:getInstance() which is always available on server and client
    local gt = GameTime and GameTime:getInstance()
    local hours = (gt and gt:getWorldAgeHours()) or 0
    -- 디버그 로그 추가
    TAB_log("Current world hours: " .. tostring(hours))
    return hours
end

local function TAB_distance2(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return dx * dx + dy * dy
end

------------------------------------------------------------------
-- Zombie helpers
------------------------------------------------------------------
local function TAB_clearZombiesInArea()
    local cell = getCell()
    if not cell or not cell:getZombieList() then return end

    local zombies = cell:getZombieList()
    for i = zombies:size()-1, 0, -1 do
        local zombie = zombies:get(i)
        if zombie then
            local zx, zy = zombie:getX(), zombie:getY()
            if zx >= CLEAR_X1 and zx <= CLEAR_X2 and zy >= CLEAR_Y1 and zy <= CLEAR_Y2 then
                zombie:removeFromWorld()
                zombie:removeFromSquare()
            end
        end
    end
    TAB_log("Cleared zombies in arena area.")
end

local function TAB_spawnZombiesNearPlayer(player)
    if not player then return end

    local px, py, pz = player:getX(), player:getY(), player:getZ()

    -- Count existing zombies in radius
    local cell = getCell()
    if not cell or not cell:getZombieList() then return end
    local nearCount = 0
    local zombies = cell:getZombieList()
    local r2 = SPAWN_RADIUS * SPAWN_RADIUS
    for i = 0, zombies:size()-1 do
        local z = zombies:get(i)
        if z and TAB_distance2(z:getX(), z:getY(), px, py) <= r2 then
            nearCount = nearCount + 1
            if nearCount >= MAX_NEAR_ZOMBIES then
                -- Even if we are skipping spawning due to crowding, still create noise to keep the horde interested
                if sendServerCommand then
                    sendServerCommand(player, 'TheyAreBillions', 'Noise', {})
                end
                break
            end
        end
    end

    if nearCount >= MAX_NEAR_ZOMBIES then
        return -- Too many, skip spawning this tick
    end

    local toSpawn = SPAWN_PER_TICK
    local spawnCount = 0
    while toSpawn > 0 do
        local sx = px + ZombRandBetween(-SPAWN_RADIUS, SPAWN_RADIUS)
        local sy = py + ZombRandBetween(-SPAWN_RADIUS, SPAWN_RADIUS)
        -- Keep within arena bounds to avoid weird spawning
        if sx < CLEAR_X1 then sx = CLEAR_X1 end
        if sx > CLEAR_X2 then sx = CLEAR_X2 end
        if sy < CLEAR_Y1 then sy = CLEAR_Y1 end
        if sy > CLEAR_Y2 then sy = CLEAR_Y2 end

        addZombiesInOutfit(sx, sy, pz, 1, "Default", nil)
        spawnCount = spawnCount + 1
        toSpawn = toSpawn - 1
    end

    -- Inform the player's client to create world noise that lures distant zombies
    if sendServerCommand then
        sendServerCommand(player, 'TheyAreBillions', 'Noise', {})
    end
end

------------------------------------------------------------------
-- Event lifecycle helpers
------------------------------------------------------------------
local function TAB_endEvent(success)
    if not TAB.active then return end

    TAB_log("TAB_endEvent called with success=" .. tostring(success))

    -- Instruct each participant client to return to original position
    for id, data in pairs(TAB.players) do
        if sendServerCommand then
            sendServerCommand(getPlayerByOnlineID(id) or nil, 'TheyAreBillions', 'Return', {
                x = data.ox,
                y = data.oy,
                z = data.oz or 0,
                success = success
            })
        end
    end

    -- Reset state
    TAB.players     = {}
    TAB.active      = false
    TAB.endWorldMin = 0

    TAB_log("TAB event ended (" .. (success and "success" or "fail") .. ")")
end

------------------------------------------------------------------
-- Timer tick – EveryOneMinute
------------------------------------------------------------------
function TAB.EveryOneMinute()
    if not TAB.active then return end

    TAB_log("EveryOneMinute tick - active event detected")

    if TAB.paused then
        if TAB_hasActivePlayer() then
            -- Resume automatically
            TAB.paused = false
            local addHr = TAB.remainingHour > 0 and TAB.remainingHour or EVENT_DURATION_HOURS
            TAB.endWorldHour = TAB_worldHours() + addHr
            TAB.remainingHour = 0
            TAB_log("Resuming TAB event automatically with "..tostring(addHr).." hours remaining")
        else
            return
        end
    end

    if not TAB_hasActivePlayer() then
        -- pause the event until someone reconnects
        TAB.paused = true
        TAB.remainingHour = TAB.endWorldHour - TAB_worldHours()
        TAB_log("TAB event paused (no active players) remaining="..tostring(TAB.remainingHour))
        return
    end

    -- Spawn zombies for each tracked player
    for id, data in pairs(TAB.players) do
        local ply = data.player or getPlayerByOnlineID(id)
        if ply and not ply:isDead() then
            TAB_spawnZombiesNearPlayer(ply)
        end
    end

    -- Check win condition / timeout
    local currentHour = TAB_worldHours()
    TAB_log("Time check: current=" .. tostring(currentHour) .. ", end=" .. tostring(TAB.endWorldHour))
    if currentHour >= TAB.endWorldHour then
        TAB_log("Event time exceeded, ending event")
        TAB_endEvent(true)
    end
end
Events.EveryOneMinute.Add(TAB.EveryOneMinute)

------------------------------------------------------------------
-- Player death handling
------------------------------------------------------------------
function TAB.OnPlayerDeath(player)
    if not TAB.active or not player then return end

    local id = player:getOnlineID()
    if TAB.players[id] then
        TAB.players[id] = nil
        -- If no players left in event, fail the event.
        if not next(TAB.players) then
            TAB_endEvent(false)
        end
    end
end
Events.OnPlayerDeath.Add(TAB.OnPlayerDeath)

------------------------------------------------------------------
-- Start / Join event for a player
------------------------------------------------------------------
local function TAB_addPlayerToEvent(player)
    if not player then return end

    local id = player:getOnlineID()
    if TAB.players[id] then return end -- already participating

    TAB.players[id] = {
        player = player,
        ox = player:getX(),
        oy = player:getY(),
        oz = player:getZ()
    }
    TAB_log("Added player to event: " .. tostring(player:getUsername()) .. " original pos: " .. tostring(player:getX()) .. "," .. tostring(player:getY()))
end

------------------------------------------------------------------
-- Client → Server command handler
------------------------------------------------------------------
function TAB.OnClientCommand(module, command, playerObj, args)
    if module ~= 'TheyAreBillions' then return end
    if command ~= 'StartEvent' then return end

    if not playerObj then return end

    -- First player starts the event, otherwise join & extend.
    if not TAB.active then
        TAB_log("Starting TAB event with player " .. tostring(playerObj:getUsername()))

        -- Cleanup arena first
        TAB_clearZombiesInArea()

        TAB.active = true
        local currentHour = TAB_worldHours()
        TAB.endWorldHour = currentHour + EVENT_DURATION_HOURS
        TAB_log("Event start time: " .. tostring(currentHour) .. ", planned end time: " .. tostring(TAB.endWorldHour))
        TAB.players = {}

        TAB_addPlayerToEvent(playerObj)
        -- (Teleport handled client-side)
    else
        TAB_log("Player " .. tostring(playerObj:getUsername()) .. " joined ongoing TAB event")

        if TAB.paused then
            TAB.paused = false
            local addHr = TAB.remainingHour > 0 and TAB.remainingHour or EVENT_DURATION_HOURS
            TAB.endWorldHour = TAB_worldHours() + addHr
            TAB.remainingHour = 0
            TAB_log("Resuming TAB event with "..tostring(addHr).." hours remaining")
        else
            -- Extend as usual
            local currentHour = TAB_worldHours()
            TAB.endWorldHour = currentHour + EVENT_DURATION_HOURS
            TAB_log("Extended event end time to: " .. tostring(TAB.endWorldHour))
        end

        -- Existing first player says line
        for _, data in pairs(TAB.players) do
            if data.player and not data.player:isDead() then
                local line = getText("IGUI_PlayerText_TABPlayerAdded")
                if line and line ~= '' then
                    data.player:Say(line)
                end
                break -- only first speaking player
            end
        end

        TAB_addPlayerToEvent(playerObj)
        -- (Teleport handled client-side)
    end
end
Events.OnClientCommand.Add(TAB.OnClientCommand)
