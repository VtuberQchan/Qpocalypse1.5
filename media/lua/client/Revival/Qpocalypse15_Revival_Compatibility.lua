Qpocalypse15.Compatibility = {}

Qpocalypse15.Compatibility.initialize = function()
  if SandboxVars.ZombieLore.ZombiesDragDown and not SandboxVars.Qpocalypse15.DragDownAllowed then
    Qpocalypse15.log("Setting 'ZombieLore.ZombiesDragDown' to 'false' for compatibility.")
    SandboxVars.ZombieLore.ZombiesDragDown = false

    getSandboxOptions():getOptionByName("ZombieLore.ZombiesDragDown"):setValue(false)
    getSandboxOptions():toLua()
  end

  Qpocalypse15.Compatibility.banditsActive = getActivatedMods():contains("Bandits")
end
