function OnEat_SyretteHighGradePainkillers(food, character, percent)
    local bodyDamage = character:getBodyDamage()
    local playerStats = character:getStats()
    --Anaesthesia 1000% of vanilla
    character:PainMeds(0.45f * 10.0f);
    character:setPainEffect(5400f * 5); --Effect 5 hours
    playerStats:setPain(10);
    --Poisoning +50%
    if character:getModData()["qpMorphine"] then
        bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 50)
    else
        bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 5)
        character:getModData()["qpMorphine"] = 5
    end
    --Fatigue +40%
    playerStats:setFatigue(playerStats:getFatigue() + 0.4)
end

function OnEat_SyretteAdrenalin(food, character, percent)
    local bodyDamage = character:getBodyDamage()
    local playerStats = character:getStats()
    --Fatigue -100%
    playerStats:setFatigue(0)
    --Endurance +50%
    playerStats:setEndurance(playerStats:getEndurance() + 0.5)
    character:getModData()["qpAdrenalin"] = 2
    --Panic +50%
    playerStats:setPanic(playerStats:getPanic() + 50)
    --Stress +50%
    playerStats:setStress(playerStats:getStress() + 50)
    --Poisoning +25%
    bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 25)
end

function OnEat_SyrettePrescriptionAntibiotic(food, character, percent)
    local bodyDamage = character:getBodyDamage()
    local playerStats = character:getStats()
    --Infection -100%
    bodyDamage:setFakeInfectionLevel(bodyDamage:getFakeInfectionLevel() - 100)
    --Poisoning +15%
    bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 15)
end

function OnEat_SyrettePrescriptionSedatives(food, character, percent)
    local bodyDamage = character:getBodyDamage()
    local playerStats = character:getStats()
    --Panic 0
    playerStats:setPanic(0)
    --Stress 0
    playerStats:setStress(0)
    --Beta Blockers 400%
    character:BetaBlockers(0.45f * 4.0f);
    --Unhappiness -50%
    bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - 50)
    --Fatigue +50%
    playerStats:setFatigue(playerStats:getFatigue() + 0.5)
    --Poisoning +25%
    bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 25)
end

function OnEat_BottleFluMedication(food, character, percent)
    local bodyDamage = character:getBodyDamage()
    local playerStats = character:getStats()
    
    --Cold treatment 40%
    if bodyDamage:getColdStrength() <= 40 then
        bodyDamage:setColdStrength(0.0f)
        bodyDamage:setHasACold(false)
        bodyDamage:setCatchACold(0.0f)
    else
        bodyDamage:setColdStrength(bodyDamage:getColdStrength() - 40.0);
    end
    --Fatigue +10%
    playerStats:setFatigue(playerStats:getFatigue() + 0.1)
    --Poisoning +10%
    bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 10)
end

function OnEat_HotDrinkFluMedication(food, character, percent)
    local bodyDamage = character:getBodyDamage()
    local playerStats = character:getStats()
    if food:getHeat() > 1.3f then
        --Cold treatment 50%
        if bodyDamage:getColdStrength() <= 50 then
            bodyDamage:setColdStrength(0.0f)
            bodyDamage:setHasACold(false)
            bodyDamage:setCatchACold(0.0f)
        else
            bodyDamage:setColdStrength(bodyDamage:getColdStrength() - 50.0);
        end
        --Pain medication 40% of vanilla
        if (character:getStats():getDrunkenness() > 10.0f) then
            character:PainMeds(0.15f * 0.4f);
        else
            character:PainMeds(0.45f * 0.4f);
        end
    else
        --Ineffective cold treatment 30%
        bodyDamage:setColdStrength(bodyDamage:getColdStrength() - 30.0);
        --Pain medication 10% of vanilla
        if (character:getStats():getDrunkenness() > 10.0f) then
            character:PainMeds(0.15f * 0.1f);
        else
            character:PainMeds(0.45f * 0.1f);
        end
    end
    --Fatigue +10%
    playerStats:setFatigue(playerStats:getFatigue() + 0.1)
    --Poisoning +10%
    bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 10)
end

function OnEat_BottleCoughSyrup(food, character, percent)
    local bodyDamage = character:getBodyDamage()
    local playerStats = character:getStats()
    
    --Cold treatment 10%
    if bodyDamage:getColdStrength() <= 10 then
        bodyDamage:setColdStrength(0.0f)
        bodyDamage:setHasACold(false)
        bodyDamage:setCatchACold(0.0f)
    else
        bodyDamage:setColdStrength(bodyDamage:getColdStrength() - 10.0);
    end
    --Poisoning +10%
    bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 5)
end

function OnEat_NasalSpray(food, character, percent)
    local bodyDamage = character:getBodyDamage()
    local playerStats = character:getStats()
    
    --Cold treatment 20%
    if bodyDamage:getColdStrength() <= 20 then
        bodyDamage:setColdStrength(0.0f)
        bodyDamage:setHasACold(false)
        bodyDamage:setCatchACold(0.0f)
    else
        bodyDamage:setColdStrength(bodyDamage:getColdStrength() - 20.0);
    end
    --Poisoning +10%
    bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 10)
end