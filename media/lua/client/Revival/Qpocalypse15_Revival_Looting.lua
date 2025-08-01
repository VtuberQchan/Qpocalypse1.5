Qpocalypse15 = Qpocalypse15 or {}

require "TimedActions/ISBaseTimedAction"

-- Loot Timed Action: Removes one item from the incapacitated target and drops it on the ground.
Qpocalypse15.LootTimedAction = ISBaseTimedAction:derive("Qpocalypse15.LootTimedAction")

function Qpocalypse15.LootTimedAction:isValid()
    return true
end

function Qpocalypse15.LootTimedAction:update()
    self.character:faceThisObject(self.target)
end

function Qpocalypse15.LootTimedAction:waitToStart()
    self.character:faceThisObject(self.target)
    return self.character:shouldBeTurning()
end

function Qpocalypse15.LootTimedAction:start()
    -- Use the generic Loot animation so the player kneels near the body
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function Qpocalypse15.LootTimedAction:stop()
    ISBaseTimedAction.stop(self)
end

-- Helper that removes one item from target and drops it on the ground (single-player or server-side use)
local function QP15_DropOneItem(target)
    if not target then return end
    local inventory = target:getInventory()
    if inventory and not inventory:isEmpty() then
        local items = inventory:getItems()

        -- 1) Firstly, we'll make a list of unequipped items.
        local unequipped = {}
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it and not it:isEquipped() then
                table.insert(unequipped, it)
            end
        end

        -- 2) If there are candidates, choose one from them, otherwise choose one from all items.
        local chosen
        if #unequipped > 0 then
            -- ZombRand(n) returns 0..n-1, whereas Lua table indices start at 1
            chosen = unequipped[ZombRand(#unequipped) + 1]
        else
            chosen = items:get(ZombRand(items:size()))
        end

        if chosen then
            -- If an item is equipped, force it to unequip first.
            if chosen:isEquipped() then
                -- 1) If it's in hands, release it
                if target.getPrimaryHandItem and target:getPrimaryHandItem() == chosen then
                    target:setPrimaryHandItem(nil)
                end
                if target.getSecondaryHandItem and target:getSecondaryHandItem() == chosen then
                    target:setSecondaryHandItem(nil)
                end

                -- 2) If it's attached (holster, etc.)
                if target.removeAttachedItem then
                    target:removeAttachedItem(chosen)
                end

                -- 3) If it's worn on the body (BodyLocation exists)
                if chosen.getBodyLocation and target.setWornItem and chosen:getBodyLocation() then
                    target:setWornItem(chosen:getBodyLocation(), nil)
                end

                -- 4) Refresh inventory/model
                if target.getInventory then
                    target:getInventory():setDrawDirty(true)
                end
            end

            -- Determine the square once so we can drop multiple items at the same spot
            local square = target:getCurrentSquare() or target:getSquare()

            -- Gather every unequipped item with the same full-type as the chosen one.
            -- We iterate **after** the potential unequip step above so that `chosen` is now also unequipped.
            local toDrop = {}
            local chosenType = chosen:getFullType()
            for i = items:size() - 1, 0, -1 do
                local it = items:get(i)
                if it and not it:isEquipped() and it:getFullType() == chosenType then
                    table.insert(toDrop, it)
                end
            end

            -- Remove every collected item from inventory and spawn it in the world.
            for _, it in ipairs(toDrop) do
                inventory:Remove(it)
                if square then
                    square:AddWorldInventoryItem(it, 0.0, 0.0, 0.0)
                end
            end
        end
    end
end

function Qpocalypse15.LootTimedAction:perform()
    -- Save character reference in advance (because ISBaseTimedAction.perform() makes self.character nil)
    local player = self.character

    -- Handling item drops
    local needMore = true -- assume more items exist by default (safe for MP where client can't inspect target inventory)
    if isClient() then
        -- Multiplayer: ask server to handle the actual dropping
        Qpocalypse15.Sync.sendClient(player, Qpocalypse15.Sync.LOOT, Qpocalypse15.Sync.getArgsFromTarget(self.target))
    else
        -- Single-player: drop immediately on this side
        QP15_DropOneItem(self.target)

        -- Re-check the target inventory only on the side that actually removed the item
        local inv = self.target:getInventory()
        needMore = inv and not inv:isEmpty()
    end

    -- First finish the current timed-action, then queue the next one if needed.
    ISBaseTimedAction.perform(self)

    if needMore then
        ISTimedActionQueue.add(Qpocalypse15.LootTimedAction:new(player, self.target))
    end
end

function Qpocalypse15.LootTimedAction:new(character, target)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.target = target
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 300 -- Each item takes 300 ticks to loot

    if o.character:isTimedActionInstant() then
        o.maxTime = 1
    end

    luautils.walkAdj(character, target:getSquare())

    return o
end

-- ============= Context-menu integration ============= --
local function onLootAction(player, target)
    ISTimedActionQueue.add(Qpocalypse15.LootTimedAction:new(player, target))
end

local function onFillWorldObjectContextMenu_Loot(playerNum, context)
    local player = getSpecificPlayer(playerNum)
    -- If acting player is incapacitated, clear their menu and exit
    if Qpocalypse15.Incapacitation and Qpocalypse15.Incapacitation.isActive(player) then
        context:clear()
        return
    end

    -- clickedPlayer is a global provided by the game when right-clicking on a character
    if not clickedPlayer or not (Qpocalypse15.Incapacitation and Qpocalypse15.Incapacitation.isActive(clickedPlayer)) then
        return
    end

    -- Add the looting option to the context menu
    context:addOptionOnTop(string.format(getText("ContextMenu_Qpocalypse15_Looting"), clickedPlayer:getDisplayName()), player, onLootAction, clickedPlayer)
end
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu_Loot)

Qpocalypse15.Loot = Qpocalypse15.Loot or {}
Qpocalypse15.Loot.dropOneItem = QP15_DropOneItem

local function onServerCommand_LOOT(module, command, args)
    if module ~= Qpocalypse15.id or command ~= Qpocalypse15.Sync.LOOT then return end

    local localPlayer = getPlayer()
    if not localPlayer then return end

    -- Only the targeted player should drop an item
    if args and args.username and localPlayer:getUsername() == args.username then
        QP15_DropOneItem(localPlayer)
    end
end
Events.OnServerCommand.Add(onServerCommand_LOOT)
