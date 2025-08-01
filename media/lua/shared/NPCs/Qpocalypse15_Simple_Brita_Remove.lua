-- Qpocalypse15 - 간단한 Brita 좀비 제거
-- 직접 table 조작으로 Brita 좀비들을 제거합니다.

local function simpleBritaRemoval()
    -- 각 존에서 Brita 좀비들을 직접 제거
    if ZombiesZoneDefinition.Spiffo then
        for i = #ZombiesZoneDefinition.Spiffo, 1, -1 do
            local zombie = ZombiesZoneDefinition.Spiffo[i]
            if zombie and zombie.name == "Brita_Robbie" then
                table.remove(ZombiesZoneDefinition.Spiffo, i)
            end
        end
    end
    
    if ZombiesZoneDefinition.FarmingStore then
        for i = #ZombiesZoneDefinition.FarmingStore, 1, -1 do
            local zombie = ZombiesZoneDefinition.FarmingStore[i]
            if zombie and zombie.name == "Brita_Robbie_Blue" then
                table.remove(ZombiesZoneDefinition.FarmingStore, i)
            end
        end
    end
    
    if ZombiesZoneDefinition.Farm then
        for i = #ZombiesZoneDefinition.Farm, 1, -1 do
            local zombie = ZombiesZoneDefinition.Farm[i]
            if zombie and zombie.name == "Brita_Robbie_Green" then
                table.remove(ZombiesZoneDefinition.Farm, i)
            end
        end
    end
    
    if ZombiesZoneDefinition.McCoys then
        for i = #ZombiesZoneDefinition.McCoys, 1, -1 do
            local zombie = ZombiesZoneDefinition.McCoys[i]
            if zombie and zombie.name == "Brita_Robbie_Grey" then
                table.remove(ZombiesZoneDefinition.McCoys, i)
            end
        end
    end
    
    if ZombiesZoneDefinition.ConstructionSite then
        for i = #ZombiesZoneDefinition.ConstructionSite, 1, -1 do
            local zombie = ZombiesZoneDefinition.ConstructionSite[i]
            if zombie and zombie.name == "Brita_Robbie_Purple" then
                table.remove(ZombiesZoneDefinition.ConstructionSite, i)
            end
        end
    end
    
    if ZombiesZoneDefinition.CountryClub then
        for i = #ZombiesZoneDefinition.CountryClub, 1, -1 do
            local zombie = ZombiesZoneDefinition.CountryClub[i]
            if zombie and zombie.name == "Brita_Robbie_Yellow" then
                table.remove(ZombiesZoneDefinition.CountryClub, i)
            end
        end
    end
    
    print("[Qpocalypse15] All Brita zombies removed from spawn tables")
end

-- 게임 시작 시 실행
Events.OnGameStart.Add(simpleBritaRemoval)