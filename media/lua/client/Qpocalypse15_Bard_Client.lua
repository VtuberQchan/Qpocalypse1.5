-- Qpocalypse15 Bard System - Client Module
-- 클라이언트 측 바드 시스템 구현

require "shared/Qpocalypse15_Bard"

Qpocalypse15_BardClient = {}

-- 클라이언트 측 바드 상태 관리
Qpocalypse15_BardClient.playerBardState = {}
Qpocalypse15_BardClient.activeBardPlayers = {}

-- 단순한 연주 상태 체크용 변수
Qpocalypse15_BardClient.isCurrentlyPlaying = false

-- 기타 파괴 및 장비 해제 헬퍼 함수
function Qpocalypse15_BardClient.destroyGuitarItem(player, guitar)
    if not player or not guitar then return end

    -- 손에 들고 있는 아이템이 해당 기타라면 장비 해제
    if player:getPrimaryHandItem() == guitar then
        player:setPrimaryHandItem(nil)
    end
    if player:getSecondaryHandItem() == guitar then
        player:setSecondaryHandItem(nil)
    end

    -- 인벤토리에서 제거
    player:getInventory():Remove(guitar)
end

-- 바드 컨텍스트 메뉴 추가
local function onFillInventoryObjectContextMenu(player, context, items)
    if not player or not items then return end
    local items = ISInventoryPane.getActualItems(items)
    
    for _, item in ipairs(items) do
        if item:getFullType() == "Qpocalypse15.BardGuitarAcoustic" then
            -- 단순한 boolean 체크
            if not Qpocalypse15_BardClient.isCurrentlyPlaying then
                context:addOption(getText("ContextMenu_Qpocalypse15_PlayBard"), player, Qpocalypse15_BardClient.startPlayingBard)
            end
            break
        end
    end
end

--[[
    for i = 1, #items do
        local item = items[i]
        if item and instanceof(item, "InventoryItem") then
            if item:getFullType() == "Qpocalypse15.BardGuitarAcoustic" then
                -- 이미 연주 중인지 확인
                local playerID = player:getOnlineID()
                if not Qpocalypse15_BardClient.playerBardState[playerID] or 
                   Qpocalypse15_BardClient.playerBardState[playerID].state ~= Qpocalypse15_Bard.BardState.PLAYING then
                    context:addOption(getText("ContextMenu_Qpocalypse15_PlayBard"), player, Qpocalypse15_BardClient.startPlayingBard, item)
                end
                break
            end
        end
    end
end
]]--

-- 바드 연주 시작
function Qpocalypse15_BardClient.startPlayingBard()
    
    local player = getPlayer()
    -- 플레이어 고유 ID 저장 (싱글 및 멀티플레이 모두 호환)
    local playerID = player:getOnlineID()
    local guitar = player:getInventory():getFirstTypeRecurse("Qpocalypse15.BardGuitarAcoustic")
    
    -- 기타를 장비(양손 무기이므로 Secondary까지 설정해야 양손에 장착됨)
    
    player:setPrimaryHandItem(guitar)
    player:setSecondaryHandItem(guitar)
    
    -- 장비 설정이 성공했는지 확인
    if not Qpocalypse15_Bard.isPlayerEquippedWithBardGuitar(player) then
        print("Qpocalypse15 Bard: Failed to equip guitar, aborting")
        return
    end
    
    -- 랜덤 음악 선택 및 3D 클립 준비
    local musicFile  = Qpocalypse15_Bard.getRandomMusicFile()
    local gameSound  = GameSounds and GameSounds.getSound(musicFile) or nil
    local clip       = gameSound and gameSound:getRandomClip() or nil
    -- 3D 이미터 생성 (플레이어 위치)
    local emitter    = getWorld():getFreeEmitter(player:getX(), player:getY(), player:getZ())
    local soundID    = nil
    if emitter and clip then
        soundID = emitter:playClip(clip, nil) -- 3D 재생 (기본값 true)
    else
        print("Qpocalypse15 Bard: failed to obtain emitter or clip")
    end
    
    -- 서버에 연주 시작 알림 (안전한 전송)
    if sendClientCommand then
        sendClientCommand(player, "Qpocalypse15_Bard", "StartPlaying", {
            playerID = playerID,
            musicFile = musicFile,
            x = player:getX(),
            y = player:getY(),
            z = player:getZ()
        })
    end
    
    -- 클라이언트 상태 업데이트 (사운드는 서버 응답에서 처리)
    Qpocalypse15_BardClient.playerBardState[playerID] = {
        state     = Qpocalypse15_Bard.BardState.PLAYING,
        musicFile = musicFile,
        guitar    = guitar,
        emitter   = emitter,
        soundID   = soundID,
        startTime = getTimestamp()
    }
    
    -- 연주 상태 플래그 설정
    Qpocalypse15_BardClient.isCurrentlyPlaying = true
end

-- 바드 연주 중지 (수동 중지용 - 현재 미사용, UI 확장 시 활용 가능)
function Qpocalypse15_BardClient.stopPlayingBard(player, destroyGuitar)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local bardState = Qpocalypse15_BardClient.playerBardState[playerID]
    
    if bardState and bardState.state == Qpocalypse15_Bard.BardState.PLAYING then
        -- 서버에 연주 중지 알림 (안전한 전송)
        if sendClientCommand then
            sendClientCommand(player, "Qpocalypse15_Bard", "StopPlaying", {
                playerID = playerID,
                destroyGuitar = destroyGuitar
            })
        end
        
        -- 사운드 중지 (자신의 사운드만)
        if bardState.emitter and bardState.soundID then
            if bardState.emitter.stopSound then
                bardState.emitter:stopSound(bardState.soundID)
            else
                bardState.emitter:stopAll()
            end
        end
        
        -- 기타 파괴 (클라이언트에서만 가능)
        if destroyGuitar and bardState.guitar then
            Qpocalypse15_BardClient.destroyGuitarItem(player, bardState.guitar)
            print("Qpocalypse15 Bard: Guitar destroyed for local player")
        end
        
        -- 상태 초기화
        Qpocalypse15_BardClient.playerBardState[playerID] = {
            state = Qpocalypse15_Bard.BardState.IDLE,
            musicFile = nil,
            guitar = nil,
            emitter = nil,
            soundID = nil
        }
        
        -- 연주 상태 플래그 해제
        Qpocalypse15_BardClient.isCurrentlyPlaying = false
    end
end

-- 성능 최적화를 위한 카운터
Qpocalypse15_BardClient.updateCounter = 0

-- 장비 변경 감지 및 바드 효과 적용
local function onPlayerUpdate(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local bardState = Qpocalypse15_BardClient.playerBardState[playerID]
    
    if bardState and bardState.state == Qpocalypse15_Bard.BardState.PLAYING then
        -- 3D 사운드 위치 및 틱 업데이트
        if bardState.emitter then
            bardState.emitter:setPos(player:getX(), player:getY(), player:getZ())
            bardState.emitter:tick()
        end
        
        -- 바드 기타가 장비 해제되었는지 확인 (중요하므로 매번 체크)
        if not Qpocalypse15_Bard.isPlayerEquippedWithBardGuitar(player) then
            -- 장비 해제 시 즉시 처리 (중복 방지)
            if bardState.emitter and bardState.soundID then
                if bardState.emitter.stopSound then
                    bardState.emitter:stopSound(bardState.soundID)
                else
                    bardState.emitter:stopAll()
                end
            end
            
            -- 즉시 기타 파괴 (이미 장비 해제되었으므로 guitar 객체로 파괴)
            if bardState.guitar then
                Qpocalypse15_BardClient.destroyGuitarItem(player, bardState.guitar)
                print("Qpocalypse15 Bard: Guitar unequipped and destroyed")
            end
            
            -- 상태 초기화
            Qpocalypse15_BardClient.playerBardState[playerID] = {
                state = Qpocalypse15_Bard.BardState.IDLE,
                musicFile = nil,
                guitar = nil,
                emitter = nil,
                soundID = nil
            }
            
            -- 연주 상태 플래그 해제
            Qpocalypse15_BardClient.isCurrentlyPlaying = false
            
            -- 서버에 상태 업데이트만 알림 (기타는 이미 파괴됨)
            if sendClientCommand then
                sendClientCommand(player, "Qpocalypse15_Bard", "StopPlaying", {
                    playerID = playerID,
                    destroyGuitar = false
                })
            end
        end
        
        -- 자신의 사운드 상태 확인 (성능 최적화: 10번에 1번만)
        if Qpocalypse15_BardClient.updateCounter % 10 == 0 then
            Qpocalypse15_BardClient.checkMyBardSound(player)
        end
    end
    
    -- 성능 최적화: 10번에 1번만 실행 (약 1초마다)
    Qpocalypse15_BardClient.updateCounter = Qpocalypse15_BardClient.updateCounter + 1
    if Qpocalypse15_BardClient.updateCounter % 10 == 0 then
        Qpocalypse15_BardClient.applyBardEffectsToLocalPlayer(player)
        Qpocalypse15_BardClient.updateBardPlayerPositions()
    end
end

-- 로컬 플레이어에게 바드 효과 적용
function Qpocalypse15_BardClient.applyBardEffectsToLocalPlayer(player)
    if not player or not player:isAlive() then return end
    
    local playerX = player:getX()
    local playerY = player:getY()
    local playerZ = player:getZ()
    
    -- 활성 바드 플레이어들 중 범위 내에 있는지 확인
    local inBardRange = false
    for bardPlayerID, bardData in pairs(Qpocalypse15_BardClient.activeBardPlayers) do
        if bardData and bardData.x and bardData.y and bardData.z == playerZ then
            local distance = Qpocalypse15_Bard.getDistance(playerX, playerY, bardData.x, bardData.y)
            if distance <= Qpocalypse15_Bard.CALM_RANGE then
                inBardRange = true
                break
            end
        end
    end
    
    -- 자신이 바드를 연주하고 있는 경우도 확인
    local playerID = player:getOnlineID()
    local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
    if myBardState and myBardState.state == Qpocalypse15_Bard.BardState.PLAYING then
        inBardRange = true
    end
    
    -- 바드 범위 내에 있으면 진정 효과 적용
    if inBardRange then
        local stats = player:getStats()
        local bodyDamage = player:getBodyDamage()
        
        -- 패닉 및 스트레스 완화 (한 번에 10포인트씩 감소, 최소 0)
        local newPanic   = math.max(0, stats:getPanic()   - 10)
        local newStress  = math.max(0, stats:getStress()  - 10)
        stats:setPanic(newPanic)
        stats:setStress(newStress)
        
        -- 불행도 감소 (균형잡힌 조정)
        local currentUnhappiness = bodyDamage:getUnhappynessLevel()
        if currentUnhappiness > 0 then
            local newUnhappiness = math.max(0, currentUnhappiness - 5) -- 지속적으로 적용되므로 5로 조정
            bodyDamage:setUnhappynessLevel(newUnhappiness)
        end
    end
end

-- 바드 플레이어 위치 업데이트 및 사운드 상태 확인
function Qpocalypse15_BardClient.updateBardPlayerPositions()
    -- 싱글플레이/멀티플레이 호환 플레이어 목록 가져오기
    local allPlayers = nil
    if isClient() and getOnlinePlayers then
        allPlayers = getOnlinePlayers()
    elseif IsoPlayer.getPlayers then
        allPlayers = IsoPlayer.getPlayers()
    else
        -- 플레이어 목록을 가져올 수 없으면 반환
        return
    end
    
    -- 로컬 플레이어 한 번만 가져오기 (성능 최적화)
    local localPlayer = getPlayer() or (getSpecificPlayer and getSpecificPlayer(0))
    
    local playersToRemove = {}
    
    for playerID, bardData in pairs(Qpocalypse15_BardClient.activeBardPlayers) do
        -- 해당 플레이어 찾기 (연결 해제 감지)
        local bardPlayer = nil
        for i = 0, allPlayers:size() - 1 do
            local player = allPlayers:get(i)
            if player and player:getOnlineID() == playerID then
                bardPlayer = player
                break
            end
        end
        
        if not bardPlayer then
            -- 플레이어가 연결 해제되었으면 정리
            table.insert(playersToRemove, playerID)
            print("Qpocalypse15 Bard: Player " .. playerID .. " disconnected, cleaning up")
        elseif bardData.emitter and bardData.soundID then
            -- 사운드 재생 상태 확인
            local isStillPlaying = false
            if bardData.emitter.isPlaying then
                isStillPlaying = bardData.emitter:isPlaying(bardData.soundID)
            end
            
            if not isStillPlaying then
                -- 사운드가 끝났으면 로컬에서만 정리
                table.insert(playersToRemove, playerID)
                print("Qpocalypse15 Bard: Music ended for player: " .. playerID .. " (local cleanup)")
            else
                -- 플레이어가 살아있고 사운드가 재생 중이면 위치 업데이트
                    -- 플레이어의 현재 위치로 emitter 위치 업데이트
                    local newX, newY, newZ = bardPlayer:getX(), bardPlayer:getY(), bardPlayer:getZ()
                    
                    -- 거리 체크 (PLAY_RANGE를 벗어났는지 확인)
                    local isInRange = false
                    if localPlayer then
                        local distance = Qpocalypse15_Bard.getDistance(localPlayer:getX(), localPlayer:getY(), newX, newY)
                        local isSameLevel = localPlayer:getZ() == newZ
                        isInRange = isSameLevel and distance <= Qpocalypse15_Bard.PLAY_RANGE
                    end
                    
                    if not isInRange then
                        -- 범위를 벗어났으면 사운드만 중지 (상태는 유지하여 재진입 시 재생 가능)
                        if bardData.emitter and bardData.soundID then
                            if bardData.emitter.stopSound then
                                bardData.emitter:stopSound(bardData.soundID)
                            else
                                bardData.emitter:stopAll()
                            end
                            bardData.emitter = nil
                            bardData.soundID = nil
                            bardData.resyncRequested = false  -- 재동기화 플래그 리셋
                        end
                        print("Qpocalypse15 Bard: Player " .. playerID .. " out of range, sound paused")
                    elseif not bardData.emitter and isInRange then
                        -- 범위 안으로 다시 들어왔으면 서버에 재동기화 요청 (중복 방지)
                        if not bardData.resyncRequested and localPlayer and sendClientCommand then
                            sendClientCommand(localPlayer, "Qpocalypse15_Bard", "RequestResync", {
                                targetPlayerID = playerID
                            })
                            bardData.resyncRequested = true -- 중복 요청 방지 플래그
                            print("Qpocalypse15 Bard: Player " .. playerID .. " back in range, requesting resync")
                        end
                    elseif bardData.emitter and (math.abs(bardData.x - newX) > 0.1 or math.abs(bardData.y - newY) > 0.1 or bardData.z ~= newZ) then
                        -- 위치가 변경되었으면 새로운 emitter로 교체
                        bardData.emitter:stopAll()
                        
                        local newEmitter = getWorld():getFreeEmitter(newX, newY, newZ)
                        if newEmitter then
                            local newSoundID = newEmitter:playSound(bardData.musicFile)
                            if newSoundID then
                                bardData.emitter = newEmitter
                                bardData.soundID = newSoundID
                                bardData.x = newX
                                bardData.y = newY
                                bardData.z = newZ
                            end
                        end
                    end
                end
            end
        end
    
    -- 제거할 플레이어들 정리 (메모리 누수 방지)
    for _, playerID in ipairs(playersToRemove) do
        local bardData = Qpocalypse15_BardClient.activeBardPlayers[playerID]
        if bardData then
            -- 안전한 emitter 정리
            if bardData.emitter then
                if bardData.soundID and bardData.emitter.stopSound then
                    bardData.emitter:stopSound(bardData.soundID)
                else
                    bardData.emitter:stopAll()
                end
                -- emitter 참조 완전 제거
                bardData.emitter = nil
                bardData.soundID = nil
            end
        end
        Qpocalypse15_BardClient.activeBardPlayers[playerID] = nil
    end
end

-- 자신의 바드 사운드 상태 확인
function Qpocalypse15_BardClient.checkMyBardSound(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
    
    if myBardState and myBardState.state == Qpocalypse15_Bard.BardState.PLAYING then
        if myBardState.emitter and myBardState.soundID then
            -- 안전한 isPlaying 호출
            local isStillPlaying = false
            if myBardState.emitter.isPlaying then
                isStillPlaying = myBardState.emitter:isPlaying(myBardState.soundID)
            end
            
            if not isStillPlaying then
                -- 자신의 사운드가 끝났으면 즉시 처리
                myBardState.state = Qpocalypse15_Bard.BardState.IDLE
                
                -- 연주 상태 플래그 해제
                Qpocalypse15_BardClient.isCurrentlyPlaying = false
                if myBardState.emitter then
                    myBardState.emitter:stopAll()
                end
                
                -- 즉시 기타 파괴 (지연 없이)
                if myBardState.guitar then
                    Qpocalypse15_BardClient.destroyGuitarItem(player, myBardState.guitar)
                    print("Qpocalypse15 Bard: My music ended, guitar destroyed immediately")
                end
                
                -- 상태 초기화
                Qpocalypse15_BardClient.playerBardState[playerID] = {
                    state = Qpocalypse15_Bard.BardState.IDLE,
                    musicFile = nil,
                    guitar = nil,
                    emitter = nil,
                    soundID = nil
                }
                
                -- 서버에 상태 업데이트 알림 (기타 파괴는 이미 완료)
                if sendClientCommand then
                    sendClientCommand(player, "Qpocalypse15_Bard", "StopPlaying", {
                        playerID = playerID,
                        destroyGuitar = false  -- 이미 파괴했으므로 false
                    })
                end
            end
        end
    end
end

-- 서버로부터 바드 시작 명령 처리
local function onServerCommand(module, command, args)
    if module ~= "Qpocalypse15_Bard" then return end
    
    if command == "StartPlayingForClients" then
        local playerID = args.playerID
        local musicFile = args.musicFile
        local x, y, z = args.x, args.y, args.z
        -- 안전한 로컬 플레이어 가져오기
        local localPlayer = nil
        if getPlayer then
            localPlayer = getPlayer()
        elseif getSpecificPlayer then
            localPlayer = getSpecificPlayer(0) -- 싱글플레이어인 경우
        end
        
        -- 거리 체크 (PLAY_RANGE 내에 있는지 확인)
        local shouldPlaySound = false
        if localPlayer then
            local distance = Qpocalypse15_Bard.getDistance(localPlayer:getX(), localPlayer:getY(), x, y)
            local isSameLevel = localPlayer:getZ() == z
            
            if localPlayer:getOnlineID() == playerID then
                -- 자신의 바드는 항상 재생
                shouldPlaySound = true
            elseif isSameLevel and distance <= Qpocalypse15_Bard.PLAY_RANGE then
                -- 다른 플레이어의 바드는 범위 내에서만 재생
                shouldPlaySound = true
            end
        end
        
        if shouldPlaySound then
            -- 음악 재생
            local emitter = getWorld():getFreeEmitter(x, y, z)
            if emitter then
                local soundID = emitter:playSound(musicFile)
                
                if not soundID then
                    print("Qpocalypse15 Bard: Failed to play sound: " .. musicFile)
                    
                    -- 자신의 바드인 경우 상태 복구 필요
                    if localPlayer and localPlayer:getOnlineID() == playerID then
                        local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
                        if myBardState then
                            -- 즉시 기타 파괴 및 상태 정리
                            if myBardState.guitar then
                                Qpocalypse15_BardClient.destroyGuitarItem(localPlayer, myBardState.guitar)
                                print("Qpocalypse15 Bard: Guitar destroyed due to sound failure")
                            end
                            
                            Qpocalypse15_BardClient.playerBardState[playerID] = {
                                state = Qpocalypse15_Bard.BardState.IDLE,
                                musicFile = nil,
                                guitar = nil,
                                emitter = nil,
                                soundID = nil
                            }
                            
                            -- 서버에 실패 알림 (안전한 전송)
                            if sendClientCommand and localPlayer then
                                sendClientCommand(localPlayer, "Qpocalypse15_Bard", "StopPlaying", {
                                    playerID = playerID,
                                    destroyGuitar = false
                                })
                            end
                        end
                    end
                    return
                end
                
                -- 자신인 경우와 다른 플레이어인 경우 구분
                if localPlayer and localPlayer:getOnlineID() == playerID then
                    -- 자신의 바드 상태 업데이트
                    local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
                    if myBardState then
                        myBardState.emitter = emitter
                        myBardState.soundID = soundID
                    end
                else
                                    -- 다른 플레이어의 바드 상태 추가
                Qpocalypse15_BardClient.activeBardPlayers[playerID] = {
                    emitter = emitter,
                    soundID = soundID,
                    musicFile = musicFile,
                    x = x, y = y, z = z,
                    resyncRequested = false  -- 재동기화 요청 플래그
                }
                end
            else
                print("Qpocalypse15 Bard: Failed to get free emitter at " .. x .. ", " .. y .. ", " .. z)
            end
        else
            print("Qpocalypse15 Bard: Player out of range (" .. Qpocalypse15_Bard.PLAY_RANGE .. "), not playing sound")
        end
        
    elseif command == "StopPlayingForClients" then
        local playerID = args.playerID
        local localPlayer = nil
        if getPlayer then
            localPlayer = getPlayer()
        elseif getSpecificPlayer then
            localPlayer = getSpecificPlayer(0)
        end
        
        -- 자신의 바드인 경우 로컬 상태 정리
        if localPlayer and localPlayer:getOnlineID() == playerID then
            local myBardState = Qpocalypse15_BardClient.playerBardState[playerID]
            if myBardState and myBardState.state == Qpocalypse15_Bard.BardState.PLAYING then
                if myBardState.emitter and myBardState.soundID then
                    if myBardState.emitter.stopSound then
                        myBardState.emitter:stopSound(myBardState.soundID)
                    else
                        myBardState.emitter:stopAll()
                    end
                end
                
                -- 추가 기타 파괴 (중복 체크)
                -- 이미 클라이언트에서 처리되었을 수 있지만 안전성을 위해 재확인
                if args.destroyGuitar then
                    local stillHasGuitar = false
                    local primaryItem = localPlayer:getPrimaryHandItem()
                    local secondaryItem = localPlayer:getSecondaryHandItem()
                    
                    if (primaryItem and primaryItem:getType() == "BardGuitarAcoustic") or
                       (secondaryItem and secondaryItem:getType() == "BardGuitarAcoustic") then
                        stillHasGuitar = true
                    end
                    
                    if stillHasGuitar then
                        local targetItem = primaryItem or secondaryItem
                        if targetItem then
                            Qpocalypse15_BardClient.destroyGuitarItem(localPlayer, targetItem)
                            print("Qpocalypse15 Bard: Guitar destroyed by server request (fallback)")
                        end
                    end
                end
                
                -- 상태 초기화
                Qpocalypse15_BardClient.playerBardState[playerID] = {
                    state = Qpocalypse15_Bard.BardState.IDLE,
                    musicFile = nil,
                    guitar = nil,
                    emitter = nil,
                    soundID = nil
                }
            end
        else
            -- 다른 플레이어의 바드인 경우
            local bardPlayer = Qpocalypse15_BardClient.activeBardPlayers[playerID]
            if bardPlayer and bardPlayer.emitter then
                if bardPlayer.emitter.stopSound and bardPlayer.soundID then
                    bardPlayer.emitter:stopSound(bardPlayer.soundID)
                else
                    bardPlayer.emitter:stopAll()
                end
            end
        end
        
        -- 활성 바드 플레이어 목록에서 제거
        Qpocalypse15_BardClient.activeBardPlayers[playerID] = nil
    end
end

-- 플레이어 사망 시 바드 상태 정리 (로컬만, 서버는 자체적으로 정리)
local function onPlayerDeath(player)
    if not player then return end
    
    local playerID = player:getOnlineID()
    local localPlayer = getPlayer()
    
    -- 로컬 플레이어가 죽은 경우 자신의 바드 상태 정리
    if localPlayer and localPlayer:getOnlineID() == playerID then
        local bardState = Qpocalypse15_BardClient.playerBardState[playerID]
        if bardState and bardState.state == Qpocalypse15_Bard.BardState.PLAYING then
            -- 사운드 중지
            if bardState.emitter and bardState.soundID then
                if bardState.emitter.stopSound then
                    bardState.emitter:stopSound(bardState.soundID)
                else
                    bardState.emitter:stopAll()
                end
            end
            
            -- 상태 초기화
            Qpocalypse15_BardClient.playerBardState[playerID] = {
                state = Qpocalypse15_Bard.BardState.IDLE,
                musicFile = nil,
                guitar = nil,
                emitter = nil,
                soundID = nil
            }
            
            -- 연주 상태 플래그 해제
            Qpocalypse15_BardClient.isCurrentlyPlaying = false
            
            print("Qpocalypse15 Bard: Local player died, bard state cleared")
        end
    end
    
    -- 다른 플레이어가 죽은 경우 activeBardPlayers에서 제거
    if Qpocalypse15_BardClient.activeBardPlayers[playerID] then
        local bardData = Qpocalypse15_BardClient.activeBardPlayers[playerID]
        if bardData.emitter then
            if bardData.soundID and bardData.emitter.stopSound then
                bardData.emitter:stopSound(bardData.soundID)
            else
                bardData.emitter:stopAll()
            end
        end
        Qpocalypse15_BardClient.activeBardPlayers[playerID] = nil
        print("Qpocalypse15 Bard: Removed dead player " .. playerID .. " from active bards")
    end
end

-- 이벤트 등록
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
Events.OnPlayerUpdate.Add(onPlayerUpdate)
Events.OnServerCommand.Add(onServerCommand)
Events.OnPlayerDeath.Add(onPlayerDeath) 