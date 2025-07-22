Qpocalypse15.Sync = {}

Qpocalypse15.Sync.INCAPACITATE = "incapacitate"
Qpocalypse15.Sync.REVIVE = "revive"

local ANIMATION_VARIABLE = "Qpocalypse15_Incapacitated"

Qpocalypse15.Sync.isMultiplayer = function() return getWorld():getGameMode() == "Multiplayer" end

Qpocalypse15.Sync.getArgsFromTarget = function(target) return { username = target:getUsername() } end

Qpocalypse15.Sync.getTargetFromArgs = function(args)
  if not args or not args.username then return end
  return getPlayerFromUsername(args.username)
end

Qpocalypse15.Sync.sendClient = function(player, command, args) sendClientCommand(player, Qpocalypse15.id, command, args) end

Qpocalypse15.Sync.sendServer = function(command, args) sendServerCommand(Qpocalypse15.id, command, args) end

Qpocalypse15.Sync.applyEffects = function(player, value)
  if value and not Qpocalypse15.Incapacitation.isActive(player) then player:playDeadSound() end

  player:getModData().Qpocalypse15_Incapacitated = value or nil

  if value then
    player:StopAllActionQueue()

    player:setVariable("ExerciseStarted", false);
    player:setVariable("ExerciseEnded", true);
    player:setVariable(ANIMATION_VARIABLE, true)
  else
    player:clearVariable(ANIMATION_VARIABLE)
    player:setGhostMode(false)
  end

  player:setOnFloor(value)
end
