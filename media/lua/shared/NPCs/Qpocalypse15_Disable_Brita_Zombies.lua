-- Qpocalypse15 - Brita 좀비 확률 0으로 설정
-- Brita의 좀비들의 스폰 확률을 0으로 만듭니다.

local function disableBritaZombies()
    -- 비활성화할 Brita 좀비 이름들
    local britaZombieNames = {
        "Brita_Robbie",
        "Brita_Robbie_Blue", 
        "Brita_Robbie_Green",
        "Brita_Robbie_Grey",
        "Brita_Robbie_Purple",
        "Brita_Robbie_Yellow"
    }
    
    -- 모든 존 정의를 확인하고 Brita 좀비들의 확률을 0으로 설정
    for zoneName, zoneData in pairs(ZombiesZoneDefinition) do
        if type(zoneData) == "table" then
            for i, zombie in ipairs(zoneData) do
                if zombie and zombie.name then
                    for _, britaName in ipairs(britaZombieNames) do
                        if zombie.name == britaName then
                            zombie.chance = 0
                            print("[Qpocalypse15] Set " .. britaName .. " chance to 0 in " .. zoneName)
                            break
                        end
                    end
                end
            end
        end
    end
end

-- 게임 시작 시 Brita 좀비들을 비활성화
Events.OnGameStart.Add(disableBritaZombies)