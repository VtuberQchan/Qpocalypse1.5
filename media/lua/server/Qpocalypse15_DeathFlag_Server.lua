-- Qpocalypse15 DeathFlag System - Server Module
-- 서버 측 DeathFlag 시스템 구현

Qpocalypse15_DeathFlag = {}

-- 활성화된 DeathFlag 정보를 저장하는 테이블
Qpocalypse15_DeathFlag.activeFlags = {}

-- DeathFlag 활성화 함수
function Qpocalypse15_DeathFlag.activateDeathFlag(player, args)
    if not player or not args then return end
    
    local playerID = args.playerID or player:getOnlineID()
    local x = args.x or player:getX()
    local y = args.y or player:getY()
    local z = args.z or player:getZ()
    
    -- DeathFlag 정보 저장
    Qpocalypse15_DeathFlag.activeFlags[playerID] = {
        player = player,
        x = x,
        y = y,
        z = z,
        startTime = getTimestamp(),
        duration = 15000, -- 15초 (밀리초)
        range = 20 -- 20칸 범위
    }
    
    print("[DeathFlag Server] DeathFlag activated for player " .. tostring(playerID))
    
    -- 클라이언트에 알림
    if isServer() then
        sendServerCommand("Qpocalypse15_DeathFlag", "DeathFlagActivated", {
            playerID = playerID,
            x = x, y = y, z = z
        })
    end
    
    -- 글로벌 타이머 시작
    Qpocalypse15_DeathFlag.startGlobalTimer()
end

-- DeathFlag 비활성화 함수
function Qpocalypse15_DeathFlag.deactivateDeathFlag(playerID)
    if not Qpocalypse15_DeathFlag.activeFlags[playerID] then return end
    
    print("[DeathFlag Server] DeathFlag deactivated for player " .. tostring(playerID))
    
    -- 데이터 제거
    Qpocalypse15_DeathFlag.activeFlags[playerID] = nil
    
    -- 클라이언트에 알림
    if isServer() then
        sendServerCommand("Qpocalypse15_DeathFlag", "DeathFlagDeactivated", {
            playerID = playerID
        })
    end
end

-- 좀비가 플레이어를 타겟팅할 때 호출되는 함수
function Qpocalypse15_DeathFlag.modifyZombieTarget(zombie, originalTarget)
    if not zombie or not originalTarget then return originalTarget end
    
    -- 활성화된 DeathFlag가 있는지 확인
    for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        local flagPlayer = flagData.player
        if flagPlayer and not flagPlayer:isDead() then
            local zombieX = zombie:getX()
            local zombieY = zombie:getY()
            -- 플레이어의 현재 위치를 실시간으로 사용
            local flagX = flagPlayer:getX()
            local flagY = flagPlayer:getY()
            
            -- 좀비가 DeathFlag 범위 내에 있는지 확인
            local distanceToFlag = math.sqrt((zombieX - flagX)^2 + (zombieY - flagY)^2)
            if distanceToFlag <= flagData.range then
                
                -- 원래 타겟이 DeathFlag 사용자가 아니고, 범위 내의 다른 플레이어라면
                if originalTarget ~= flagPlayer then
                    local targetX = originalTarget:getX()
                    local targetY = originalTarget:getY()
                    local distanceTargetToFlag = math.sqrt((targetX - flagX)^2 + (targetY - flagY)^2)
                    
                    -- 원래 타겟이 DeathFlag 범위 내에 있다면 DeathFlag 사용자로 타겟 변경
                    if distanceTargetToFlag <= flagData.range then
                        return flagPlayer
                    end
                end
            end
        end
    end
    
    return originalTarget
end

-- 플레이어가 좀비에게 보이는지 확인하는 함수 (좀비 인식 차단)
function Qpocalypse15_DeathFlag.isPlayerVisibleToZombie(player, zombie)
    if not player or not zombie then return true end
    
    local playerID = player:getOnlineID()
    
    -- 활성화된 DeathFlag가 있는지 확인
    for flagPlayerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        -- 자신이 DeathFlag 사용자라면 정상적으로 보임
        if playerID == flagPlayerID then
            return true
        end
        
        local flagPlayer = flagData.player
        if flagPlayer and not flagPlayer:isDead() then
            local playerX = player:getX()
            local playerY = player:getY()
            -- 플레이어의 현재 위치를 실시간으로 사용
            local flagX = flagPlayer:getX()
            local flagY = flagPlayer:getY()
            
            -- 플레이어가 DeathFlag 범위 내에 있는지 확인
            local distanceToFlag = math.sqrt((playerX - flagX)^2 + (playerY - flagY)^2)
            if distanceToFlag <= flagData.range then
                -- 범위 내의 다른 플레이어는 좀비가 볼 수 없음
                return false
            end
        end
    end
    
    return true
end

-- 클라이언트 명령 처리
local function onClientCommand(module, command, player, args)
    if module ~= "Qpocalypse15_DeathFlag" then return end
    
    if command == "ActivateDeathFlag" then
        Qpocalypse15_DeathFlag.activateDeathFlag(player, args)
    end
end

-- 글로벌 타이머 (메모리 누수 방지)
local globalTimerActive = false

local function globalTimer()
    if not globalTimerActive then return end
    
    local currentTime = getTimestamp()
    local toRemove = {}
    
    for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        if flagData then
            local elapsedTime = currentTime - flagData.startTime -- 밀리초 단위로 직접 비교
            if elapsedTime >= flagData.duration then
                table.insert(toRemove, playerID)
            end
        end
    end
    
    -- 만료된 플래그들 제거
    for _, playerID in ipairs(toRemove) do
        Qpocalypse15_DeathFlag.deactivateDeathFlag(playerID)
    end
    
    -- 더 이상 활성 플래그가 없으면 타이머 중지
    local hasActiveFlags = false
    for _ in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        hasActiveFlags = true
        break
    end
    
    if not hasActiveFlags then
        globalTimerActive = false
        Events.OnTick.Remove(globalTimer)
    end
end

-- 타이머 활성화 함수
function Qpocalypse15_DeathFlag.startGlobalTimer()
    if not globalTimerActive then
        globalTimerActive = true
        Events.OnTick.Add(globalTimer)
    end
end

-- 타이머 중지 함수
function Qpocalypse15_DeathFlag.stopGlobalTimer()
    globalTimerActive = false
    Events.OnTick.Remove(globalTimer)
end

-- 플레이어 연결 해제 시 DeathFlag 정리
local function onDisconnect(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    if Qpocalypse15_DeathFlag.activeFlags[playerID] then
        print("[DeathFlag Server] Player disconnected, cleaning up DeathFlag for " .. tostring(playerID))
        Qpocalypse15_DeathFlag.deactivateDeathFlag(playerID)
    end
end

-- 플레이어 사망 시 DeathFlag 정리
local function onPlayerDeath(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    if Qpocalypse15_DeathFlag.activeFlags[playerID] then
        print("[DeathFlag Server] Player died, cleaning up DeathFlag for " .. tostring(playerID))
        Qpocalypse15_DeathFlag.deactivateDeathFlag(playerID)
    end
end

-- 이벤트 등록
Events.OnClientCommand.Add(onClientCommand)
Events.OnDisconnect.Add(onDisconnect)
Events.OnPlayerDeath.Add(onPlayerDeath) 