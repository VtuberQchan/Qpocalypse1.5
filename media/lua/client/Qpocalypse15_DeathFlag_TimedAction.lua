require "TimedActions/ISBaseTimedAction"

ISQPDeathFlagAction = ISBaseTimedAction:derive("ISQPDeathFlagAction")

function ISQPDeathFlagAction:new(character, item)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = 60 -- 1초 (60 ticks)
    return o
end

function ISQPDeathFlagAction:isValid()
    return self.character and 
           self.item and 
           not self.character:isDead() and 
           self.character:getInventory():contains(self.item) and
           self.item:getType() == "DeathFlag"
end

function ISQPDeathFlagAction:update()
end

function ISQPDeathFlagAction:start()
    -- 유효성 재검사
    if not self:isValid() then
        self:stop()
        return
    end
    
    -- 랜덤 대사 선택 (1~10)
    local randomNumber = ZombRand(10) + 1
    local dialogKey = "IGUI_PlayerText_DeathFlag" .. randomNumber
    local dialog = getText(dialogKey)
    
    -- 대사가 제대로 로드되지 않았을 때 대비
    if not dialog or dialog == dialogKey then
        dialog = "Death Flag activated!" -- 폴백 메시지
    end
    
    -- 채팅으로 대사 출력
    self.character:Say(dialog)
    
    -- 서버에 DeathFlag 활성화 명령 전송
    if isClient() then
        sendClientCommand(self.character, "Qpocalypse15_DeathFlag", "ActivateDeathFlag", {
            playerID = self.character:getOnlineID(),
            x = self.character:getX(),
            y = self.character:getY(),
            z = self.character:getZ()
        })
    else
        -- 싱글플레이어에서는 서버 모듈 로드 후 실행
        local serverModule = require("server/Qpocalypse15_DeathFlag_Server")
        if Qpocalypse15_DeathFlag and Qpocalypse15_DeathFlag.activateDeathFlag then
            Qpocalypse15_DeathFlag.activateDeathFlag(self.character, {
                playerID = self.character:getOnlineID(),
                x = self.character:getX(),
                y = self.character:getY(),
                z = self.character:getZ()
            })
        else
            print("[DeathFlag Error] Cannot load server module.")
        end
    end
end

function ISQPDeathFlagAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISQPDeathFlagAction:perform()
    -- 최종 유효성 검사
    if self.character and self.item and self.character:getInventory():contains(self.item) then
        -- 아이템 사용 (제거)
        self.character:getInventory():Remove(self.item)
    end
    
    ISBaseTimedAction.perform(self)
end

function ISQPDeathFlagAction:complete()
    return true
end 