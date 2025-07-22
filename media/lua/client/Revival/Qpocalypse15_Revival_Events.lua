local onGameTimeLoaded = function()
  Qpocalypse15.Compatibility.initialize()

  if Qpocalypse15.Sync.isMultiplayer() then return end

  local player = getPlayer()
  if player and Qpocalypse15.Incapacitation.isActive(player) then player:setAsleep(false) end
end
Events.OnGameTimeLoaded.Add(onGameTimeLoaded)

local onPlayerUpdate = function(player)
  if player:isDead() or (not Qpocalypse15.Incapacitation.isActive(player) and player:getBodyDamage():getHealth() >= SandboxVars.Qpocalypse15.IncapacitatedHealth) then return end

  if Qpocalypse15.Compatibility.banditsActive and player:getVariableBoolean("Bandit") then return end

  Qpocalypse15.Incapacitation.applyMechanics(player, true)
end
Events.OnPlayerUpdate.Add(onPlayerUpdate)

local onPlayerDeath = function(player) Qpocalypse15.Panel.destroy(player) end
Events.OnPlayerDeath.Add(onPlayerDeath)

local onWeaponHitCharacter = function(attacker, defender, _, damage)
  if not Qpocalypse15.Incapacitation.isActive(defender) or not instanceof(attacker, "IsoPlayer") or damage <= 0 then return end
  Qpocalypse15.Incapacitation.kill(defender)
end
Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)

local onPreUIDraw = function()
  if not getPlayer() then return end
  Qpocalypse15.UI.applyEffectiveHealth(true)
end
Events.OnPreUIDraw.Add(onPreUIDraw)

local onPostUIDraw = function()
  if not getPlayer() then return end
  Qpocalypse15.UI.applyEffectiveHealth(false)
end
Events.OnPostUIDraw.Add(onPostUIDraw)

local onServerCommand = function(module, command, args)
  if module ~= Qpocalypse15.id then return end

  if command == Qpocalypse15.Sync.INCAPACITATE then
    local player = Qpocalypse15.Sync.getTargetFromArgs(args)
    if not player then return end

    Qpocalypse15.Sync.applyEffects(player, true)
  elseif command == Qpocalypse15.Sync.REVIVE then
    local player = Qpocalypse15.Sync.getTargetFromArgs(args)
    if not player then Qpocalypse15.log("Invalid player for Revive command") end

    Qpocalypse15.Incapacitation.revive(player, false)
  end
end
Events.OnServerCommand.Add(onServerCommand)
