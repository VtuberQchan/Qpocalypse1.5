-- Qpocalypse15 DeathFlag Zombie AI Hooks
-- 좀비 AI 후킹 및 DeathFlag 효과 적용

require "server/Qpocalypse15_DeathFlag_Server"

-- 성능 최적화를 위한 캐시 변수들
local lastUpdateTime = 0
local UPDATE_INTERVAL = 500 -- 0.5초마다 업데이트 (500ms) - 더 반응적

-- 좀비 AI 수정을 위한 주기적 업데이트 함수
local function updateZombiesForDeathFlag()
    local currentTime = getTimestamp()
    
    -- 성능 최적화: 1초마다만 실행
    if (currentTime - lastUpdateTime) < UPDATE_INTERVAL then
        return
    end
    lastUpdateTime = currentTime
    
    -- 활성화된 DeathFlag가 없으면 건너뛰기
    if not Qpocalypse15_DeathFlag.activeFlags then
        return
    end
    
    local hasActiveFlags = false
    for _ in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        hasActiveFlags = true
        break
    end
    
    if not hasActiveFlags then
        return
    end
    
    -- 모든 플레이어 주변의 좀비들 처리
    for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        local flagPlayer = flagData.player
        if flagPlayer and not flagPlayer:isDead() then
            -- 플레이어의 현재 위치를 실시간으로 사용 (이동 가능)
            local flagX = flagPlayer:getX()
            local flagY = flagPlayer:getY()
            local range = flagData.range
            
            -- 주변 좀비들 찾기 (정확한 방법)
            local cell = getCell()
            if cell then
                -- 정수 좌표로 변환 및 범위 체크
                local startX = math.max(0, math.floor(flagX - range))
                local endX = math.min(cell:getMaxX(), math.floor(flagX + range))
                local startY = math.max(0, math.floor(flagY - range))
                local endY = math.min(cell:getMaxY(), math.floor(flagY + range))
                
                -- 모든 타일을 체크 (성능 최적화: 2칸씩 건너뛰기로 타협)
                for x = startX, endX, 2 do
                    for y = startY, endY, 2 do
                        local square = cell:getGridSquare(x, y, 0)
                        if square then
                            local zombieList = square:getZombieList()
                            if zombieList and zombieList:size() > 0 then
                                for i = 0, zombieList:size() - 1 do
                                    local zombie = zombieList:get(i)
                                    if zombie and not zombie:isDead() then
                                        local zombieX = zombie:getX()
                                        local zombieY = zombie:getY()
                                        local distance = math.sqrt((zombieX - flagX)^2 + (zombieY - flagY)^2)
                                        if distance <= range then
                                            -- 좀비를 DeathFlag 사용자에게 집중시키기
                                            local currentTarget = zombie:getTarget()
                                            if not currentTarget or 
                                              (instanceof(currentTarget, "IsoPlayer") and currentTarget ~= flagPlayer) then
                                                zombie:setTarget(flagPlayer)
                                                zombie:setTargetSeenTime(2500) -- 2.5초간 강제 타겟
                                                
                                                -- 좀비가 확실히 DeathFlag 사용자를 향하도록 추가 설정
                                                if zombie:getModData then
                                                    local modData = zombie:getModData()
                                                    modData.deathFlagTarget = flagPlayer:getOnlineID()
                                                    modData.deathFlagTime = getTimestamp()
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- 좀비가 플레이어를 감지하는 과정을 차단하는 함수
local function onZombieUpdate(zombie)
    if not zombie or zombie:isDead() then return end
    
    -- 활성화된 DeathFlag가 없으면 건너뛰기
    local hasActiveFlags = false
    for _ in pairs(Qpocalypse15_DeathFlag.activeFlags) do
        hasActiveFlags = true
        break
    end
    
    if not hasActiveFlags then return end
    
    local currentTarget = zombie:getTarget()
    if currentTarget and instanceof(currentTarget, "IsoPlayer") then
        -- 현재 타겟이 DeathFlag 보호 범위에 있는지 확인
        if not Qpocalypse15_DeathFlag.isPlayerVisibleToZombie(currentTarget, zombie) then
            -- 보호된 플레이어는 타겟에서 제거하고 DeathFlag 사용자로 리디렉션
                             for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
                 local flagPlayer = flagData.player
                 if flagPlayer and isZombieInDeathFlagRange(zombie, flagPlayer, flagData.range) then
                     zombie:setTarget(flagPlayer)
                     zombie:setTargetSeenTime(3000) -- 3초간 강제 타겟
                     break
                 end
             end
        end
    end
end

-- 좀비 노이즈 반응 후킹
local function onZombieHearNoise(zombie, noiseSource, volume, x, y)
    if not zombie or zombie:isDead() then return end
    
    -- DeathFlag 활성화 체크
         for playerID, flagData in pairs(Qpocalypse15_DeathFlag.activeFlags) do
         local flagPlayer = flagData.player
         if flagPlayer and isZombieInDeathFlagRange(zombie, flagPlayer, flagData.range) then
             -- 범위 내에서 발생한 모든 노이즈를 DeathFlag 사용자로 리디렉션
             zombie:setTarget(flagPlayer)
             zombie:setTargetSeenTime(3000)
             return
         end
     end
end

-- 공통 범위 체크 함수
local function isZombieInDeathFlagRange(zombie, flagPlayer, flagRange)
    if not zombie or not flagPlayer or zombie:isDead() or flagPlayer:isDead() then
        return false
    end
    
    local zombieX = zombie:getX()
    local zombieY = zombie:getY()
    local flagX = flagPlayer:getX()
    local flagY = flagPlayer:getY()
    local distance = math.sqrt((zombieX - flagX)^2 + (zombieY - flagY)^2)
    
    return distance <= flagRange
end

-- 이벤트 등록 (성능 최적화된 버전)
-- OnTick은 전체적인 좀비 타겟팅 관리용
Events.OnTick.Add(updateZombiesForDeathFlag)
-- OnZombieUpdate는 개별 좀비의 실시간 반응용 (더 즉각적)
Events.OnZombieUpdate.Add(onZombieUpdate) 