-- Qpocalypse15_Remove_Robbie.lua

local function removeRobbie()
    for _, zombie in ipairs(ZombiesZoneDefinition.Spiffo or {}) do
        if zombie.name == "Brita_Robbie" then zombie.chance = 0 end
    end
    
    for _, zombie in ipairs(ZombiesZoneDefinition.FarmingStore or {}) do
        if zombie.name == "Brita_Robbie_Blue" then zombie.chance = 0 end
    end
    
    for _, zombie in ipairs(ZombiesZoneDefinition.Farm or {}) do
        if zombie.name == "Brita_Robbie_Green" then zombie.chance = 0 end
    end
    
    for _, zombie in ipairs(ZombiesZoneDefinition.McCoys or {}) do
        if zombie.name == "Brita_Robbie_Grey" then zombie.chance = 0 end
    end
    
    for _, zombie in ipairs(ZombiesZoneDefinition.ConstructionSite or {}) do
        if zombie.name == "Brita_Robbie_Purple" then zombie.chance = 0 end
    end
    
    for _, zombie in ipairs(ZombiesZoneDefinition.CountryClub or {}) do
        if zombie.name == "Brita_Robbie_Yellow" then zombie.chance = 0 end
    end
    
    print("[Qpocalypse15] All Brita Robbie zombie spawn chances set to 0")
end

Events.OnGameStart.Add(removeRobbie)