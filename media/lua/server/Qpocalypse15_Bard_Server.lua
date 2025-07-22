-- Qpocalypse15 Bard System - Server Module
-- 서버 측 바드 시스템 구현

require "shared/Qpocalypse15_Bard"

Qpocalypse15_BardServer = {}

-- 서버 측 바드 상태 관리
Qpocalypse15_BardServer.activeBards = {}

-- 바드 연주 시작 처리
function Qpocalypse15_BardServer.startBardPlaying(player, musicFile)
    if not player or not musicFile then return end
    
    local playerID = player:getOnlineID()
    local x, y, z = player:getX(), player:getY(), player:getZ()
    
    -- 바드 상태 저장
    Qpocalypse15_BardServer.activeBards[playerID] = {
        player = player,
        musicFile = musicFile,
        x = x, y = y, z = z
    }
    
    -- 모든 클라이언트에 음악 재생 명령 전송 (안전한 전송)
    if sendServerCommand then
        sendServerCommand("Qpocalypse15_Bard", "StartPlayingForClients", {
            playerID = playerID,
            musicFile = musicFile,
            x = x, y = y, z = z
        })
    end
    
    print("Qpocalypse15 Bard: Player " .. player:getDisplayName() .. " started playing " .. musicFile)
end

-- 바드 연주 중지 처리
function Qpocalypse15_BardServer.stopBardPlaying(player, destroyGuitar)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local bardData = Qpocalypse15_BardServer.activeBards[playerID]
    
    if bardData then
        -- 기타 파괴는 클라이언트에서만 가능하므로 서버에서는 처리하지 않음
        if destroyGuitar then
            print("Qpocalypse15 Bard: Guitar destruction requested for player: " .. player:getDisplayName() .. " (handled by client)")
        end
        
        -- 바드 상태 제거
        Qpocalypse15_BardServer.activeBards[playerID] = nil
        
        -- 모든 클라이언트에 음악 중지 명령 전송 (destroyGuitar 정보 포함)
        if sendServerCommand then
            sendServerCommand("Qpocalypse15_Bard", "StopPlayingForClients", {
                playerID = playerID,
                destroyGuitar = destroyGuitar  -- 클라이언트에서 추가 기타 파괴 여부 결정용
            })
        end
        
        print("Qpocalypse15 Bard: Player " .. player:getDisplayName() .. " stopped playing")
    end
end

-- 바드 상태 정리 (연결 해제된 플레이어나 죽은 플레이어 처리)
function Qpocalypse15_BardServer.cleanupBardStates()
    local playersToRemove = {}
    
    for playerID, bardData in pairs(Qpocalypse15_BardServer.activeBards) do
        local bardPlayer = bardData.player
        
        if not bardPlayer or not bardPlayer:isAlive() then
            table.insert(playersToRemove, playerID)
        end
    end
    
    -- 정리할 플레이어들 제거
    for _, playerID in ipairs(playersToRemove) do
        Qpocalypse15_BardServer.activeBards[playerID] = nil
        if sendServerCommand then
            sendServerCommand("Qpocalypse15_Bard", "StopPlayingForClients", {
                playerID = playerID
            })
        end
        print("Qpocalypse15 Bard: Cleaned up bard state for disconnected/dead player: " .. playerID)
    end
end

-- 클라이언트 명령 처리
local function onClientCommand(module, command, player, args)
    if module ~= "Qpocalypse15_Bard" then return end
    
    if not player then return end
    
    if command == "StartPlaying" then
        local musicFile = args.musicFile
        -- 보안: 요청자가 실제로 바드 기타를 가지고 있는지 확인
        if Qpocalypse15_Bard.isPlayerEquippedWithBardGuitar(player) then
            Qpocalypse15_BardServer.startBardPlaying(player, musicFile)
        else
            print("Qpocalypse15 Bard: Rejected StartPlaying from " .. player:getDisplayName() .. " - no guitar equipped")
        end
        
    elseif command == "StopPlaying" then
        local destroyGuitar = args.destroyGuitar
        local playerID = player:getOnlineID()
        
        -- 보안: 요청자가 실제로 바드 상태에 있는지 확인
        if Qpocalypse15_BardServer.activeBards[playerID] then
            Qpocalypse15_BardServer.stopBardPlaying(player, destroyGuitar)
        else
            print("Qpocalypse15 Bard: Rejected StopPlaying from " .. player:getDisplayName() .. " - not in bard state")
        end
        
    elseif command == "RequestResync" then
        local targetPlayerID = args.targetPlayerID
        local bardData = Qpocalypse15_BardServer.activeBards[targetPlayerID]
        
        if bardData and bardData.player and not bardData.player:isDead() then
            -- 해당 플레이어가 여전히 유효하고 연주 중이면 요청자에게 다시 전송
            if sendClientCommand then
                sendClientCommand(player, "Qpocalypse15_Bard", "StartPlayingForClients", {
                    playerID = targetPlayerID,
                    musicFile = bardData.musicFile,
                    x = bardData.player:getX(),
                    y = bardData.player:getY(),
                    z = bardData.player:getZ()
                })
                print("Qpocalypse15 Bard: Resync sent to " .. player:getDisplayName() .. " for player " .. targetPlayerID)
            end
        else
            print("Qpocalypse15 Bard: Resync rejected - target player invalid or dead")
        end
    end
end

-- 플레이어 연결 해제 시 바드 상태 정리
local function onDisconnect(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    if Qpocalypse15_BardServer.activeBards[playerID] then
        Qpocalypse15_BardServer.stopBardPlaying(player, false)
    end
end

-- 정기적인 바드 상태 정리 (1분마다)
local function onEveryOneMinute()
    Qpocalypse15_BardServer.cleanupBardStates()
end

-- 타이머 관리 함수 제거됨 - 클라이언트에서 사운드 종료를 정확히 감지하므로 불필요

-- 이벤트 등록
Events.OnClientCommand.Add(onClientCommand)
Events.OnDisconnect.Add(onDisconnect)
Events.EveryOneMinute.Add(onEveryOneMinute) -- 인게임 1분마다 상태 정리 