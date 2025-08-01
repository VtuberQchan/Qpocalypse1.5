-- Qpocalypse15_Medical_Antizom.lua

function OnEat_Antizom(food, player, percent)
    local bodyDamage = player:getBodyDamage()
    local infected = bodyDamage:IsInfected()
    if infected then
        bodyDamage:setInfected(true)
        bodyDamage:setInfectionMortalityDuration(-1)
        bodyDamage:setInfectionTime(-1)
        bodyDamage:setInfectionLevel(0)
        local bodyParts = bodyDamage:getBodyParts()
        for i=bodyParts:size()-1, 0, -1  do
            local bodyPart = bodyParts:get(i)
            bodyPart:SetInfected(true)
        end
        bodyDamage:setInfected(true)
        bodyDamage:setInfectionLevel(0)
        player:Say(getText("IGUI_AntizomBuff"))
    else
        player:Say(getText("IGUI_AntizomNotInfected"))
    end
end