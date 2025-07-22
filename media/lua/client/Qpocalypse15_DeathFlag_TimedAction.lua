require "TimedActions/ISBaseTimedAction"

ISQPDeathFlagAction = ISBaseTimedAction:derive("ISQPDeathFlagAction")

function ISQPDeathFlagAction:new(character, item)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = 60 -- 1 second (60 ticks)
    return o
end

function ISQPDeathFlagAction:isValid()
    return self.character and 
           self.item and 
           not self.character:isDead() and 
           self.character:getInventory():contains(self.item) and
           self.item:getType() == "DeathFlag"
end

function ISQPDeathFlagAction:update()
end

function ISQPDeathFlagAction:start()
    -- Re-check validity
    if not self:isValid() then
        self:stop()
        return
    end
    
    -- Select random dialogue (1~10)
    local randomNumber = ZombRand(10) + 1
    local dialogKey = "IGUI_PlayerText_DeathFlag" .. randomNumber
    local dialog = getText(dialogKey)
    
    -- If the dialogue is not properly loaded, prepare a fallback message
    if not dialog or dialog == dialogKey then
        dialog = "Death Flag activated!" -- Fallback message
    end
    
    -- Output dialogue via chat
    self.character:Say(dialog)
    
    -- Send DeathFlag activation command to server
    if isClient() then
        sendClientCommand(self.character, "Qpocalypse15_DeathFlag", "ActivateDeathFlag", {
            playerID = self.character:getOnlineID(),
            x = self.character:getX(),
            y = self.character:getY(),
            z = self.character:getZ()
        })
    else
        -- Execute after loading server module in single player
        local serverModule = require("server/Qpocalypse15_DeathFlag_Server")
        if Qpocalypse15_DeathFlag and Qpocalypse15_DeathFlag.activateDeathFlag then
            Qpocalypse15_DeathFlag.activateDeathFlag(self.character, {
                playerID = self.character:getOnlineID(),
                x = self.character:getX(),
                y = self.character:getY(),
                z = self.character:getZ()
            })
        else
            print("[DeathFlag Error] Cannot load server module.")
        end
    end
end

function ISQPDeathFlagAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISQPDeathFlagAction:perform()
    -- Final validity check
    if self.character and self.item and self.character:getInventory():contains(self.item) then
        -- Use item (remove)
        self.character:getInventory():Remove(self.item)
    end
    
    ISBaseTimedAction.perform(self)
end

function ISQPDeathFlagAction:complete()
    return true
end 