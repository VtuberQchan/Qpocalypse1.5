if not Qpocalypse15 then Qpocalypse15 = {} end
Qpocalypse15.id = "Qpocalypse15"

local prefixMessage = function(...)
  local args = { ... }
  for i = 1, #args do args[i] = tostring(args[i]) end
  return "[" .. Qpocalypse15.id .. "] " .. table.concat(args, " | ")
end

Qpocalypse15.log = function(...) if getDebug() or isServer() then print(prefixMessage(...)) end end

Qpocalypse15.error = function(...) error(prefixMessage(...)) end

Qpocalypse15.test = function(player)
  if not player then player = getPlayer() end

  Qpocalypse15.Incapacitation.applyMechanics(player, true)

  Qpocalypse15.log("Test", player:getUsername())
end

Qpocalypse15.reset = function(player)
  if not player then player = getPlayer() end

  Qpocalypse15.Incapacitation.revive(player, true)
  player:getBodyDamage():RestoreToFullHealth()
  Qpocalypse15.UI.setActualHealth(player, 100)

  Qpocalypse15.Panel.destroy(player)

  Qpocalypse15.log("Reset", player:getUsername())
end

Qpocalypse15.log("Initialized.")
