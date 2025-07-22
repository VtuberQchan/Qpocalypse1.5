function Qpocalypse15MedicalEveryHours()
    player = getPlayer()
    if player:getModData()["qpSneezeTimerMin"] then
        if player:getModData()["qpSneezeTimerMin"] <= 0 then
            player:getBodyDamage():setNastyColdSneezeTimerMin(200)
            player:getBodyDamage():TriggerSneezeCough()
            player:getBodyDamage():setSneezeCoughActive(1)
            player:getModData()["qpSneezeTimerMin"] = nil
        else
            player:getModData()["qpSneezeTimerMin"] = player:getModData()["qpSneezeTimerMin"] - 1
        end
    end
    if player:getModData()["qpMorphine"] then
        if player:getModData()["qpMorphine"] <= 0 then
            player:getModData()["qpMorphine"] = nil
        else
            player:getModData()["qpMorphine"] = player:getModData()["qpMorphine"] - 1
        end
    end
    if player:getModData()["qpBurnTreatment"] then
        if player:getModData()["qpBurnTreatment"] <= 0 then
            player:getModData()["qpBurnTreatment"] = nil
        else
            player:getModData()["qpBurnTreatment"] = player:getModData()["qpBurnTreatment"] - 1
        end
    end
    if player:getModData()["qpAdrenalin"] then
        if player:getModData()["qpAdrenalin"] <= 0 then
            player:getModData()["qpAdrenalin"] = nil
            player:getStats():setFatigue(1)
            player:getStats():setHunger(player:getStats():getHunger() + 0.2)
        else
            player:getModData()["qpAdrenalin"] = player:getModData()["qpAdrenalin"] - 1
        end
    end
end

Events.EveryHours.Add(Qpocalypse15MedicalEveryHours)