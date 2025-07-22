-- Qpocalypse15 Bard System - Shared Module
-- 바드 시스템의 공유 기능들

Qpocalypse15_Bard = {}

-- 바드 시스템 관련 상수들
Qpocalypse15_Bard.PLAY_RANGE = 20  -- 연주 효과 범위
Qpocalypse15_Bard.CALM_RANGE = 20  -- 진정 효과 범위
Qpocalypse15_Bard.MUSIC_FILES = {
    "Bardmusic1",
    "Bardmusic2", 
    "Bardmusic3",
    "Bardmusic4",
    "Bardmusic5"
}

-- 바드 상태
Qpocalypse15_Bard.BardState = {
    IDLE = 0,
    PLAYING = 1
}

-- 음악 파일을 랜덤으로 선택
function Qpocalypse15_Bard.getRandomMusicFile()
    local index = ZombRand(#Qpocalypse15_Bard.MUSIC_FILES) + 1
    return Qpocalypse15_Bard.MUSIC_FILES[index]
end

-- 플레이어가 바드 기타를 장비하고 있는지 확인
function Qpocalypse15_Bard.isPlayerEquippedWithBardGuitar(player)
    if not player then return false end
    
    local primaryWeapon = player:getPrimaryHandItem()
    if primaryWeapon and primaryWeapon:getType() == "BardGuitarAcoustic" then
        return true
    end
    
    local secondaryWeapon = player:getSecondaryHandItem()
    if secondaryWeapon and secondaryWeapon:getType() == "BardGuitarAcoustic" then
        return true
    end
    
    return false
end

-- 거리 계산 함수
function Qpocalypse15_Bard.getDistance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

-- 범위 내 플레이어들 찾기
function Qpocalypse15_Bard.getPlayersInRange(centerPlayer, range)
    local players = {}
    local centerX = centerPlayer:getX()
    local centerY = centerPlayer:getY()
    local centerZ = centerPlayer:getZ()
    
    -- 싱글플레이/멀티플레이 호환 플레이어 목록 가져오기
    local allPlayers = nil
    if isClient() and getOnlinePlayers then
        allPlayers = getOnlinePlayers()
    elseif IsoPlayer.getPlayers then
        allPlayers = IsoPlayer.getPlayers()
    else
        -- 플레이어 목록을 가져올 수 없으면 빈 테이블 반환
        return players
    end
    
    if allPlayers then
        for i = 0, allPlayers:size() - 1 do
            local player = allPlayers:get(i)
            if player and player ~= centerPlayer and player:getZ() == centerZ then
                local distance = Qpocalypse15_Bard.getDistance(centerX, centerY, player:getX(), player:getY())
                if distance <= range then
                    table.insert(players, player)
                end
            end
        end
    end
    
    return players
end 