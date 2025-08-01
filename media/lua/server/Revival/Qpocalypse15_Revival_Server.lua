local onClientCommand = function(module, command, player, args)
  if module ~= Qpocalypse15.id then return end

  Qpocalypse15.log("onClientCommand", player, command)

  if command == Qpocalypse15.Sync.INCAPACITATE then
    Qpocalypse15.Sync.sendServer(Qpocalypse15.Sync.INCAPACITATE, args)
  elseif command == Qpocalypse15.Sync.REVIVE then
    Qpocalypse15.Sync.sendServer(Qpocalypse15.Sync.REVIVE, args)
  elseif command == Qpocalypse15.Sync.LOOT then
    Qpocalypse15.Sync.sendServer(Qpocalypse15.Sync.LOOT, args) -- forward to all clients
  end
end
Events.OnClientCommand.Add(onClientCommand)
