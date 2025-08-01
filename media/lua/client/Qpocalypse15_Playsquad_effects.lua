function psc_GiveBardGuitarAcoustic()
    local player = getPlayer()
    local data = psc_GetSpecificData()

    player:getInventory():AddItem("Qpocalypse15.BardGuitarAcoustic")
    player:Say(data.viewer .. getText("IGUI_PlayerText_BardGuitarAcousticAquired"))
end

function psc_GiveDeathFlag()
    local player = getPlayer()
    local data = psc_GetSpecificData()

    player:getInventory():AddItem("Qpocalypse15.DeathFlag")
    player:Say(data.viewer .. getText("IGUI_PlayerText_DeathFlagAquired"))
end

function psc_GiveRabbitBread()
    local player = getPlayer()
    local data = psc_GetSpecificData()

    player:getInventory():AddItem("Qpocalypse15.RabbitBread")
    player:Say(data.viewer .. getText("IGUI_PlayerText_RabbitBreadAquired"))
end

function psc_GiveLightweightEmergencyKit()
    local player = getPlayer()
    local data = psc_GetSpecificData()
    
    player:getInventory():AddItem("Qpocalypse15.LightweightEmergencyKit")
    player:Say(data.viewer .. getText("IGUI_PlayerText_LightweightEmergencyKitAquired"))
end

function psc_GiveAntipara()
    local player = getPlayer()
    local data = psc_GetSpecificData()

    player:getInventory():AddItem("Qpocalypse15.Antipara")
    player:Say(data.viewer .. getText("IGUI_PlayerText_AntiparaAquired"))
end

function psc_EventTheyAreBillions()
    local player = getPlayer()
    local data = psc_GetSpecificData()

    Qpocalypse15_TheyAreBillions.OnCall()
end