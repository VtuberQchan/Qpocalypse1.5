-- Qpocalypse15 DeathFlag System - Client Module
-- 클라이언트 측 DeathFlag 시스템 구현

require "Qpocalypse15_DeathFlag_TimedAction"

Qpocalypse15_DeathFlagClient = {}
-- DeathFlag 컨텍스트 메뉴 추가
local function onFillInventoryObjectContextMenu(player, context, items)
    if not player or not items then return end
    local items = ISInventoryPane.getActualItems(items)
    
    for _, item in ipairs(items) do 
        if item:getFullType() == "Qpocalypse15.DeathFlag" then
            context:addOption(getText("ContextMenu_Qpocalypse15_DeathFlag"), player, Qpocalypse15_DeathFlagClient.useDeathFlag)
        end
        break
    end
end

-- DeathFlag 사용 시작
function Qpocalypse15_DeathFlagClient.useDeathFlag()
    local player = getPlayer()
    local item = player:getInventory():getFirstTypeRecurse("Qpocalypse15.DeathFlag")

    if not player or not item then 
        print("[DeathFlag Error] Invalid player or item")
        return 
    end
    
    -- 플레이어 상태 검사
    if player:isDead() then
        print("[DeathFlag Error] Dead players cannot use DeathFlag")
        return
    end
    
    -- 아이템 타입 검사
    if item:getFullType() ~= "Qpocalypse15.DeathFlag" then
        print("[DeathFlag Error] Invalid item type: " .. tostring(item:getFullType()))
        return
    end
    
    -- TimedAction 큐에 추가
    ISTimedActionQueue.add(ISQPDeathFlagAction:new(player, item))
end

-- 서버 명령 처리
local function onServerCommand(module, command, args)
    if module ~= "Qpocalypse15_DeathFlag" then return end
    
    if command == "DeathFlagActivated" then
        -- DeathFlag가 활성화되었을 때 클라이언트 처리
        local playerID = args.playerID
        local localPlayer = getPlayer()
        
        if localPlayer and localPlayer:getOnlineID() == playerID then
            -- 자신이 DeathFlag를 사용한 경우
            print("[DeathFlag] 사망 플래그가 활성화되었습니다!")
        end
    elseif command == "DeathFlagDeactivated" then
        -- DeathFlag 효과가 끝났을 때 클라이언트 처리
        local playerID = args.playerID
        local localPlayer = getPlayer()
        
        if localPlayer and localPlayer:getOnlineID() == playerID then
            -- 자신의 DeathFlag 효과가 끝난 경우
            print("[DeathFlag] 사망 플래그 효과가 종료되었습니다.")
        end
    end
end

-- 이벤트 등록
Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
Events.OnServerCommand.Add(onServerCommand) 