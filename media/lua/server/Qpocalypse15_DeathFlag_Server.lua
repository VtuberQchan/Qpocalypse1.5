-- Qpocalypse15 DeathFlag - Server Module

Qpocalypse15_DeathFlagServer = Qpocalypse15_DeathFlagServer or {}

-- Force safe initialization at startup
if not Qpocalypse15_DeathFlagServer.protectedPlayers or type(Qpocalypse15_DeathFlagServer.protectedPlayers) ~= 'table' then
    Qpocalypse15_DeathFlagServer.protectedPlayers = {}
end

-- Run initialisation
ensureProtectedPlayersTable()

-- Constants
local PROTECTION_LOOPS = 40 -- Number of EveryOneMinute ticks before protection expires

-- Clean up expired protections (called periodically)
local function cleanupExpiredProtections()
    ensureProtectedPlayersTable()
    
    -- Double-check that protectedPlayers is actually a table before using pairs()
    if not Qpocalypse15_DeathFlagServer.protectedPlayers or type(Qpocalypse15_DeathFlagServer.protectedPlayers) ~= 'table' then
        return
    end
    
    local toRemove = {}
    
    for id, loopsLeft in pairs(Qpocalypse15_DeathFlagServer.protectedPlayers) do
        -- Decrement remaining loops; if none remain mark for removal
        loopsLeft = (tonumber(loopsLeft) or 0) - 1
        if loopsLeft <= 0 then
            table.insert(toRemove, id)
        else
            Qpocalypse15_DeathFlagServer.protectedPlayers[id] = loopsLeft
        end
    end
    
    -- Remove expired items
    for _, id in ipairs(toRemove) do
        Qpocalypse15_DeathFlagServer.protectedPlayers[id] = nil
    end
    
    -- Notify clients when items are cleaned (safe server command to all clients)
    if #toRemove > 0 and sendServerCommand then
        sendServerCommand('DeathFlag', 'ProtectedRemove', { ids = toRemove })
    end
end

-- Handling when a client sends a protect request
local function onClientCommand(module, command, playerObj, args)
    if module ~= 'DeathFlag' or command ~= 'AddProtected' then return end
    if not args or type(args.ids) ~= 'table' then return end

    ensureProtectedPlayersTable()
    
    for _, id in ipairs(args.ids) do
        -- Reset or set protection to the full loop count
        Qpocalypse15_DeathFlagServer.protectedPlayers[id] = PROTECTION_LOOPS
    end

    -- Synchronise protection targets to all clients (safe server command to all clients)
    if sendServerCommand then
        sendServerCommand('DeathFlag', 'ProtectedAdd', { ids = args.ids })
    end
end
Events.OnClientCommand.Add(onClientCommand)

-- Clean up expired protections (performance optimisation)
Events.EveryOneMinute.Add(cleanupExpiredProtections) 
