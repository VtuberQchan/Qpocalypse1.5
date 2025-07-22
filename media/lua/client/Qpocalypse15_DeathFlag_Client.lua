-- Qpocalypse15 DeathFlag System - Client Module

require "Qpocalypse15_DeathFlag_TimedAction"

Qpocalypse15_DeathFlagClient = {}
-- Add DeathFlag context menu
local function onFillInventoryObjectContextMenu(player, context, items)
    if not player or not items then return end
    local items = ISInventoryPane.getActualItems(items)
    
    for _, item in ipairs(items) do 
        if item:getFullType() == "Qpocalypse15.DeathFlag" then
            context:addOption(getText("ContextMenu_Qpocalypse15_DeathFlag"), player, Qpocalypse15_DeathFlagClient.useDeathFlag)
        end
        break
    end
end

-- Start using DeathFlag
function Qpocalypse15_DeathFlagClient.useDeathFlag()
    local player = getPlayer()
    local item = player:getInventory():getFirstTypeRecurse("Qpocalypse15.DeathFlag")

    if not player or not item then 
        print("[DeathFlag Error] Invalid player or item")
        return 
    end
    
    -- Check player state
    if player:isDead() then
        print("[DeathFlag Error] Dead players cannot use DeathFlag")
        return
    end
    
    -- Check item type
    if item:getFullType() ~= "Qpocalypse15.DeathFlag" then
        print("[DeathFlag Error] Invalid item type: " .. tostring(item:getFullType()))
        return
    end
    
    -- Add to TimedAction queue
    ISTimedActionQueue.add(ISQPDeathFlagAction:new(player, item))
end

-- Process server command
local function onServerCommand(module, command, args)
    if module ~= "Qpocalypse15_DeathFlag" then return end
    
    if command == "DeathFlagActivated" then
        -- Client processing when DeathFlag is activated
        local playerID = args.playerID
        local localPlayer = getPlayer()
        
        if localPlayer and localPlayer:getOnlineID() == playerID then
            -- If you used DeathFlag
            print("[DeathFlag] DeathFlag Raised")
        end
    elseif command == "DeathFlagDeactivated" then
        -- Client processing when DeathFlag effect ends
        local playerID = args.playerID
        local localPlayer = getPlayer()
        
        if localPlayer and localPlayer:getOnlineID() == playerID then
            -- If your DeathFlag effect ends
            print("[DeathFlag] DeathFlag Ended")
            localPlayer:Say(getText("IGUI_PlayerText_DeathFlagEnd"))
        end
    end
end

-- Register events
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
Events.OnServerCommand.Add(onServerCommand) 