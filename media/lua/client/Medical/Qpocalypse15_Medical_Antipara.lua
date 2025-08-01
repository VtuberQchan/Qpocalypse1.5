-- Qpocalypse15_Medical_Antipara.lua

function OnEat_Antipara(food, player, percent)
    local bodyDamage = player:getBodyDamage()
    local infected = ParasiteZed.isParasiteInfected(player)
    if infected then
        player:getModData()['ParasiteInfectionTime'] = nil
        player:Say(getText("IGUI_AntiparaBuff"))
    else
        player:Say(getText("IGUI_AntiparaNotInfected"))
    end
end