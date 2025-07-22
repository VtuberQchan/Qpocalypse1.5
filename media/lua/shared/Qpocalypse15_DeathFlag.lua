-- Qpocalypse15 DeathFlag System - Main Module
-- DeathFlag 시스템 메인 모듈

Qpocalypse15_DeathFlag = Qpocalypse15_DeathFlag or {}

-- 디버그 로그 함수
local function DebugLog(message)
    print("[Qpocalypse15 DeathFlag] " .. message)
end

-- 시스템 초기화
function Qpocalypse15_DeathFlag.init()
    DebugLog("DeathFlag init...")
    
    -- 클라이언트 측 초기화
    if isClient() or not isServer() then
        DebugLog("Client DeathFlag init...")
        local success, err = pcall(function()
            require "client/Qpocalypse15_DeathFlag_Client"
        end)
        if not success then
            DebugLog("Client module load failed: " .. tostring(err))
        end
    end
    
    -- 서버 측 초기화
    if isServer() or not isClient() then
        DebugLog("Server DeathFlag init...")
        local success1, err1 = pcall(function()
            require "server/Qpocalypse15_DeathFlag_Server"
        end)
        local success2, err2 = pcall(function()
            require "server/Qpocalypse15_DeathFlag_ZombieAI"
        end)
        
        if not success1 then
            DebugLog("Server module load failed: " .. tostring(err1))
        end
        if not success2 then
            DebugLog("Zombie AI module load failed: " .. tostring(err2))
        end
    end
    
    DebugLog("DeathFlag init complete!")
end

-- 게임 시작 시 초기화
Events.OnGameStart.Add(Qpocalypse15_DeathFlag.init) 