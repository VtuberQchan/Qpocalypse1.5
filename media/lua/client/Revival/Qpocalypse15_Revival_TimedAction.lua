require "TimedActions/ISBaseTimedAction"

Qpocalypse15.TimedAction = ISBaseTimedAction:derive("Qpocalypse15.ReviveTimedAction")

function Qpocalypse15.TimedAction:isValid() return true end

function Qpocalypse15.TimedAction:update() self.character:faceThisObject(self.target) end

function Qpocalypse15.TimedAction:waitToStart()
  self.character:faceThisObject(self.target)
  return self.character:shouldBeTurning()
end

local start

function Qpocalypse15.TimedAction:start()
  self:setActionAnim("Loot")
  self.character:SetVariable("LootPosition", "Low")
  start = getGameTime():getWorldAgeHours()
end

function Qpocalypse15.TimedAction:stop() ISBaseTimedAction.stop(self) end

function Qpocalypse15.TimedAction:perform()
  ISBaseTimedAction.perform(self)

  print("@@@@@@@ " .. tostring(getGameTime():getWorldAgeHours() - start))

  -- Consume the kit that was used
  local inv = self.character:getInventory()
  if inv then
    local kit = inv:getFirstTypeRecurse("Qpocalypse15.LightweightEmergencySurgeryKit") or inv:getFirstTypeRecurse("Qpocalypse15.EmergencySurgeryKit")
    if kit then inv:Remove(kit) end
  end

  if isClient() then Qpocalypse15.Sync.sendClient(self.character, Qpocalypse15.Sync.REVIVE, Qpocalypse15.Sync.getArgsFromTarget(self.target)) end
end

function Qpocalypse15.TimedAction:new(character, target)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.maxTime = SandboxVars.Qpocalypse15.AssistedRecoveryTicks - ((SandboxVars.Qpocalypse15.AssistedRecoveryTicks * character:getPerkLevel(Perks.Doctor)) / 20)
  o.stopOnWalk = true
  o.stopOnRun = true

  o.character = character
  o.target = target

  if o.character:isTimedActionInstant() then o.maxTime = 1 end

  luautils.walkAdj(character, target:getSquare())

  return o
end
