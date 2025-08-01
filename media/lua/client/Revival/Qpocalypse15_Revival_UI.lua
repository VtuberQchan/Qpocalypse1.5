Qpocalypse15.UI = {}

local playersHealth = {}
Qpocalypse15.UI.setActualHealth = function(player, value)
  if playersHealth[player:getPlayerNum()] then playersHealth[player:getPlayerNum()] = value end
end

Qpocalypse15.UI.getEffectiveHealth = function(actual) return ((actual - SandboxVars.Qpocalypse15.IncapacitatedHealth) / (100 - SandboxVars.Qpocalypse15.IncapacitatedHealth)) * 100 end
Qpocalypse15.UI.getActualHealth = function(effective) return ((effective / 100) * (100 - SandboxVars.Qpocalypse15.IncapacitatedHealth)) + SandboxVars.Qpocalypse15.IncapacitatedHealth end

Qpocalypse15.UI.applyEffectiveHealth = function(value)
  if value then playersHealth = {} end

  local players = isClient() and getOnlinePlayers() or IsoPlayer.getPlayers()
  if not players then return end

  for i = 0, players:size() - 1 do
    local player = players:get(i)
    if player then
      local body = player:isLocalPlayer() and player:getBodyDamage() or player:getBodyDamageRemote()

      if value then
        playersHealth[i] = body:getHealth()
        if Qpocalypse15.Incapacitation.isActive(player) then
          body:setOverallBodyHealth(0.5)
        elseif not player:isDead() then
          body:setOverallBodyHealth(Qpocalypse15.UI.getEffectiveHealth(playersHealth[i]))
        end
      else
        body:setOverallBodyHealth(playersHealth[i])
      end
    end
  end
end

local onReviveAction = function(player, target) ISTimedActionQueue.add(Qpocalypse15.TimedAction:new(player, target)) end

local onFillWorldObjectContextMenu = function(playerNum, context)
  local player = getSpecificPlayer(playerNum)
  if Qpocalypse15.Incapacitation.isActive(player) then
    context:clear()
    return
  end

  if not clickedPlayer or not Qpocalypse15.Incapacitation.isActive(clickedPlayer) then return end

  local hasFirstAidSkill = SandboxVars.Qpocalypse15.FirstAidRequired == 0 or SandboxVars.Qpocalypse15.FirstAidRequired <= player:getPerkLevel(Perks.Doctor)
  local hasSurgeryKit = player:getInventory():getCountType("Qpocalypse15.EmergencySurgeryKit") > 0
  local hasLightweightSurgeryKit = player:getInventory():getCountType("Qpocalypse15.LightweightEmergencySurgeryKit") > 0

  -- Lightweight kit ignores First Aid requirement
  local canRevive = hasLightweightSurgeryKit or (hasSurgeryKit and hasFirstAidSkill)

  if canRevive then
    context:addOptionOnTop(string.format(getText("ContextMenu_Qpocalypse15_Action"), clickedPlayer:getDisplayName()), player, onReviveAction, clickedPlayer)
  else
    local option = context:addOptionOnTop(string.format(getText("ContextMenu_Qpocalypse15_ActionUnavailable"), clickedPlayer:getDisplayName(), SandboxVars.Qpocalypse15.FirstAidRequired))
    option.notAvailable = true
  end
end
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

local onFillInventoryObjectContextMenu = function(playerNum, context)
  local player = getSpecificPlayer(playerNum)
  if Qpocalypse15.Incapacitation.isActive(player) then
    context:clear()
    return
  end
end
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)

local original_ISFitnessUI_onClick = ISFitnessUI.onClick
ISFitnessUI.onClick = function(self, button)
  if button.internal == "OK" and Qpocalypse15.Incapacitation.isActive(self.player) then return end
  original_ISFitnessUI_onClick(self, button)
end

local original_ISEmoteRadialMenu_checkKey = ISEmoteRadialMenu.checkKey
ISEmoteRadialMenu.checkKey = function(key)
  local player = getSpecificPlayer(0)
  if not player or Qpocalypse15.Incapacitation.isActive(player) then return false end
  return original_ISEmoteRadialMenu_checkKey(key)
end

local original_ISSearchManager_toggleSearchMode = ISSearchManager.toggleSearchMode
ISSearchManager.toggleSearchMode = function(self, _isSearchMode)
  if Qpocalypse15.Incapacitation.isActive(self.character) then
    self.updateTick = 0
    return
  end
  original_ISSearchManager_toggleSearchMode(self, _isSearchMode)
end
