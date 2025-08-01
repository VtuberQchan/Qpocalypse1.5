-- Qpocalypse15_RadioFix_Server.lua
-- Broadcasts all players' radioData to every client at a fixed interval.

local SYNC_REAL_SECONDS = 1.0      -- how often to broadcast (real-time seconds)
local nextSyncTime      = 0.0      -- accumulator for the timer

----------------------------------------------------------------------
-- Helper: safely fetch maximum VOIP distance.
-- Falls back to a sensible default when the RakVoice
-- library isn't available (e.g. on dedicated servers).
----------------------------------------------------------------------
local function GetVoiceMaxDistance()
    if type(RakVoice) == "table" and type(RakVoice.GetMaxDistance) == "function" then
        return RakVoice.GetMaxDistance()
    else
        -- Vanilla default VOIP range in tiles. Adjust for your server if needed.
        return 50
    end
end

----------------------------------------------------------------------
-- Helper: collect every turned-on radio around a player
----------------------------------------------------------------------
local function gatherRadiosForPlayer(player)
    local result = {}

    -- (0) direct voice dummy, identical to Java index 0
                    result[#result + 1] = {
                    freq     = 0,
                    distance = GetVoiceMaxDistance(),
                    x        = math.floor(player:getX()),
                    y        = math.floor(player:getY())
                }

    ------------------------------------------------------------------
    -- (1) inventory-held radios
    ------------------------------------------------------------------
    local invItems = player:getInventory():getItems()
    for i = 0, invItems:size() - 1 do
        local it = invItems:get(i)
        if it and type(it.getDeviceData) == "function" then
            local dd = it:getDeviceData()
            if dd and type(dd.getIsTurnedOn) == "function" and dd:getIsTurnedOn() then
                result[#result + 1] = {
                    freq     = dd:getChannel(),
                    distance = dd:getTransmitRange(),
                    x        = math.floor(player:getX()),
                    y        = math.floor(player:getY())
                }
            end
        end
    end

    ------------------------------------------------------------------
    -- (2) world, furniture, placed, vehicle radios within 4 tiles
    ------------------------------------------------------------------
    local cell = getCell()
    for dx = -4, 4 do
        for dy = -4, 4 do
            for dz = -1, 1 do
                local sq = cell:getGridSquare(player:getX() + dx,
                                              player:getY() + dy,
                                              player:getZ() + dz)
                if sq then
                    -- world inventory objects
                    local wObjs = sq:getWorldObjects()
                    if wObjs then
                        for j = 0, wObjs:size() - 1 do
                            local wObj = wObjs:get(j)
                            -- Some IsoObjects may not have a getItem method, so check and call
                            if wObj and type(wObj.getItem) == "function" then
                                local wItem = wObj:getItem()
                                if wItem and type(wItem.getDeviceData) == "function" then
                                    local dd = wItem:getDeviceData()
                                    if dd and type(dd.getIsTurnedOn) == "function" and dd:getIsTurnedOn() then
                                        result[#result + 1] = {
                                            freq     = dd:getChannel(),
                                            distance = dd:getTransmitRange(),
                                            x        = sq:getX(), y = sq:getY()
                                        }
                                    end
                                end
                            end
                        end
                    end

                    -- square-embedded IsoRadio / furniture
                    local objs = sq:getObjects()
                    if objs then
                        for j = 0, objs:size() - 1 do
                            local obj = objs:get(j)
                            -- Check because some IsoObjects do not have a getDeviceData method
                            if obj and type(obj.getDeviceData) == "function" then
                                local dd = obj:getDeviceData()
                                if dd and type(dd.getIsTurnedOn) == "function" and dd:getIsTurnedOn() then
                                    result[#result + 1] = {
                                        freq     = dd:getChannel(),
                                        distance = dd:getTransmitRange(),
                                        x        = sq:getX(), y = sq:getY()
                                    }
                                end
                            end
                        end
                    end

                    -- vehicle radio (part id = "Radio")
                    if sq:getVehicleContainer()
                    and sq == sq:getVehicleContainer():getSquare() then
                        local part = sq:getVehicleContainer():getPartById("Radio")
                        if part and type(part.getDeviceData) == "function" then
                            local dd = part:getDeviceData()
                            if dd and type(dd.getIsTurnedOn) == "function" and dd:getIsTurnedOn() then
                                result[#result + 1] = {
                                    freq     = dd:getChannel(),
                                    distance = dd:getTransmitRange(),
                                    x        = sq:getX(), y = sq:getY()
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return result
end

----------------------------------------------------------------------
-- Core: build payload for **all** players and broadcast
----------------------------------------------------------------------
local function broadcastAllRadioData()
    -- throttle to SYNC_REAL_SECONDS
    local now = getTimestampMs() * 0.001   -- real-time seconds since epoch
    if now < nextSyncTime then return end
    nextSyncTime = now + SYNC_REAL_SECONDS

    local payload = {}
    local players = getOnlinePlayers()

    for i = 0, players:size() - 1 do
        local p = players:get(i)
        payload[#payload + 1] = {
            pid    = p:getOnlineID(),
            radios = gatherRadiosForPlayer(p)
        }
    end

    -- broadcast; sendServerCommand with nil player → all connections
    sendServerCommand("RadioSync", "UpdateAll", payload)
end

----------------------------------------------------------------------
-- Hook into the main loop
----------------------------------------------------------------------
Events.EveryOneMinute.Add(broadcastAllRadioData)
