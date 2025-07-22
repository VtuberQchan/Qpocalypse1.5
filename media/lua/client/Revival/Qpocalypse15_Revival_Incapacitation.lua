Qpocalypse15.Incapacitation = {}

local CLIENT_COMMAND_INTERVAL_MINUTES = 2

local lastClientCommandUpdate

local conclude = function(player)
  if Qpocalypse15.Incapacitation.canRecoveryUnassisted(player) then
    Qpocalypse15.Incapacitation.revive(player, true)
  else
    Qpocalypse15.Incapacitation.kill(player)
  end
end

local stabilize = function(player)
  local body = player:getBodyDamage()

  if SandboxVars.Qpocalypse15.RecoveryRemovesInjuries then
    body:RestoreToFullHealth()
    return
  end

  body:setCatchACold(0)
  body:setHasACold(false)
  body:setColdStrength(0)
  body:setSneezeCoughActive(0)
  body:setSneezeCoughTime(0)
  body:setPoisonLevel(0)
  body:setFoodSicknessLevel(0)
  body:setBoredomLevel(0)
  body:setUnhappynessLevel(0)

  local parts = body:getBodyParts()
  for i = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
    local part = parts:get(i)

    part:setAdditionalPain(0)
    part:setBleeding(false)
    part:setBleedingTime(0)
    part:setInfectedWound(false)
    part:setWoundInfectionLevel(0)
    part:setNeedBurnWash(false)
    part:setLastTimeBurnWash(0)
  end
end

local setPerkLevel = function(player, perk, level)
  player:getXp():AddXP(perk, -999999)
  player:setPerkLevelDebug(perk, 0)

  player:getXp():AddXP(perk, PerkFactory.getPerk(perk):getTotalXpForLevel(level))
  xpUpdate.levelPerk(player, perk, level)
end

local reducePerkLevel = function(player, perk, modifier) setPerkLevel(player, perk, math.floor(player:getPerkLevel(perk) * (1 - (modifier / 100)))) end

local applyConsequences = function(player)
  if SandboxVars.Qpocalypse15.PassiveSkillLoss > 0 then
    reducePerkLevel(player, Perks.Fitness, SandboxVars.Qpocalypse15.PassiveSkillLoss)
    reducePerkLevel(player, Perks.Strength, SandboxVars.Qpocalypse15.PassiveSkillLoss)
  end

  if SandboxVars.Qpocalypse15.AgilitySkillLoss > 0 then
    reducePerkLevel(player, Perks.Sprinting, SandboxVars.Qpocalypse15.AgilitySkillLoss)
    reducePerkLevel(player, Perks.Lightfoot, SandboxVars.Qpocalypse15.AgilitySkillLoss)
    reducePerkLevel(player, Perks.Nimble, SandboxVars.Qpocalypse15.AgilitySkillLoss)
    reducePerkLevel(player, Perks.Sneak, SandboxVars.Qpocalypse15.AgilitySkillLoss)
  end

  if SandboxVars.Qpocalypse15.WeaponSkillLoss > 0 then
    reducePerkLevel(player, Perks.Aiming, SandboxVars.Qpocalypse15.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Reloading, SandboxVars.Qpocalypse15.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Axe, SandboxVars.Qpocalypse15.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Blunt, SandboxVars.Qpocalypse15.WeaponSkillLoss)
    reducePerkLevel(player, Perks.SmallBlunt, SandboxVars.Qpocalypse15.WeaponSkillLoss)
    reducePerkLevel(player, Perks.LongBlade, SandboxVars.Qpocalypse15.WeaponSkillLoss)
    reducePerkLevel(player, Perks.SmallBlade, SandboxVars.Qpocalypse15.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Spear, SandboxVars.Qpocalypse15.WeaponSkillLoss)
    reducePerkLevel(player, Perks.Maintenance, SandboxVars.Qpocalypse15.WeaponSkillLoss)
  end

  if SandboxVars.Qpocalypse15.OtherSkillLoss > 0 then
    reducePerkLevel(player, Perks.Woodwork, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.Cooking, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.Farming, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.Doctor, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.Electricity, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.MetalWelding, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.Mechanics, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.Tailoring, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.Fishing, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.Trapping, SandboxVars.Qpocalypse15.OtherSkillLoss)
    reducePerkLevel(player, Perks.PlantScavenging, SandboxVars.Qpocalypse15.OtherSkillLoss)
  end
end

local checkPassives = function(player) return not SandboxVars.Qpocalypse15.RecoveryRequiresPassive or player:getPerkLevel(Perks.Fitness) > 0 and player:getPerkLevel(Perks.Strength) > 0 end

Qpocalypse15.Incapacitation.applyMechanics = function(player, value)
  local modData = player:getModData()
  local firstTime = value and not modData.Qpocalypse15_Incapacitated

  Qpocalypse15.Sync.applyEffects(player, value)

  player:setGhostMode(value)
  player:setBlockMovement(value)
  player:setIgnoreAimingInput(value)
  player:setInvincible(value)

  local playerNum = player:getPlayerNum()

  if value then
    if firstTime then
      player:dropHandItems()

      if not checkPassives(player) then
        Qpocalypse15.Incapacitation.kill(player)
        return
      end

      applyConsequences(player)
    end

    player:nullifyAiming()
    player:setPerformingAnAction(false)

    local cursor = getCell():getDrag(playerNum)
    if cursor then cursor:exitCursor() end

    local currentTime = getGameTime():getWorldAgeHours()

    if isClient() then
      if not lastClientCommandUpdate or currentTime - lastClientCommandUpdate > (CLIENT_COMMAND_INTERVAL_MINUTES / 60) then
        Qpocalypse15.Sync.sendClient(player, Qpocalypse15.Sync.INCAPACITATE, Qpocalypse15.Sync.getArgsFromTarget(player))

        if lastClientCommandUpdate then
          lastClientCommandUpdate = currentTime
        else
          lastClientCommandUpdate = 0
        end
      end
    end

    player:setAsleep(Qpocalypse15.Panel.isFastForwarding(player))

    stabilize(player)

    Qpocalypse15.Panel.show(player)

    local limit = SandboxVars.Qpocalypse15.IncapacitatedTime <= 0 and (Qpocalypse15.Sync.isMultiplayer() and nil or 1) or SandboxVars.Qpocalypse15.IncapacitatedTime
    if limit then
      if not modData.Qpocalypse15_IncapacitatedStart then modData.Qpocalypse15_IncapacitatedStart = currentTime end

      local remaining = (modData.Qpocalypse15_IncapacitatedStart + limit) - currentTime
      Qpocalypse15.Panel.setTimeRemaining(player, remaining)
      if remaining <= 0 then conclude(player) end
    end
  else
    Qpocalypse15.Panel.destroy(player)

    modData.Qpocalypse15_IncapacitatedStart = nil

    player:setAsleep(false)
  end

  if UIManager.getFadeAlpha(playerNum) == 1 then UIManager.FadeIn(playerNum, 0) end
end

Qpocalypse15.Incapacitation.isActive = function(player) return player:getModData().Qpocalypse15_Incapacitated end

Qpocalypse15.Incapacitation.canRecoveryUnassisted = function(player)
  if (SandboxVars.Qpocalypse15.UnassistedRecovery or isClient()) and not SandboxVars.Qpocalypse15.UnassistedRecovery then return false end
  return checkPassives(player)
end

Qpocalypse15.Incapacitation.kill = function(player)
  Qpocalypse15.Incapacitation.applyMechanics(player, false)
  player:getBodyDamage():ReduceGeneralHealth(999)
  Qpocalypse15.UI.setActualHealth(player, 0)
end

Qpocalypse15.Incapacitation.revive = function(player, original)
  Qpocalypse15.Incapacitation.applyMechanics(player, false)

  local recoveryHealth
  if SandboxVars.Qpocalypse15.RecoveryHealth >= 100 then
    recoveryHealth = 100
    player:getBodyDamage():RestoreToFullHealth()
  else
    recoveryHealth = Qpocalypse15.UI.getActualHealth(SandboxVars.Qpocalypse15.RecoveryHealth)

    player:getBodyDamage():AddGeneralHealth(999)
    player:getBodyDamage():ReduceGeneralHealth(100 - recoveryHealth)
  end
  Qpocalypse15.UI.setActualHealth(player, recoveryHealth)

  if original then Qpocalypse15.Sync.sendClient(player, Qpocalypse15.Sync.REVIVE, Qpocalypse15.Sync.getArgsFromTarget(player)) end
end
