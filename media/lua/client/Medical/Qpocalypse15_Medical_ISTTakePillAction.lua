local oldISTakePillAction_perform = ISTakePillAction.perform
function ISTakePillAction:perform()
    local bodyDamage = self.character:getBodyDamage()
    local playerStats = self.character:getStats()
    
    if self.item:getType() == "PillsCommercialPainkillers" then
        --Anaesthesia 100% of vanilla
        if (self.character:getStats():getDrunkenness() > 10.0f) then
            self.character:PainMeds(0.15f * 1f);
            self.character:setPainEffect(5400f * 3); --Effect 3 hours
        else
            self.character:PainMeds(0.45f * 1f);
            self.character:setPainEffect(5400f * 3); --Effect 3 hours
        end
        --Cold treatment 5%
        if bodyDamage:getColdStrength() <= 5 then
            bodyDamage:setColdStrength(0.0f)
            bodyDamage:setHasACold(false)
            bodyDamage:setCatchACold(0.0f)
        else
            bodyDamage:setColdStrength(bodyDamage:getColdStrength() - 5.0);
        end
        --Poisoning 5%
        bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 5)
        
    elseif self.item:getType() == "PillsPrescriptionPainkillers" then
        --Pain medication 120% of vanilla
        if (playerStats:getDrunkenness() > 10.0f) then
            self.character:PainMeds(0.15f * 1.2f);
            self.character:setPainEffect(5400f * 6); --Effect 6 hours
        else
            self.character:PainMeds(0.45f * 1.2f);
            self.character:setPainEffect(5400f * 6); --Effect 6 hours
        end

        --Cold treatment 10%
        if bodyDamage:getColdStrength() <= 10 then
            bodyDamage:setColdStrength(0.0f)
            bodyDamage:setHasACold(false)
            bodyDamage:setCatchACold(0.0f)
        else
            bodyDamage:setColdStrength(bodyDamage:getColdStrength() - 10.0);
        end
        --Poisoning +25%
        bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 25)
        
    elseif self.item:getType() == "PillsCaffeine" then
        --Fatigue -30%
        playerStats:setFatigue(playerStats:getFatigue() - 0.3)
        --Poisoning 25%
        bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 25)
        
    elseif self.item:getType() == "PillsCommercialAntibiotic" then
        --Infection -75%
        bodyDamage:setFakeInfectionLevel(bodyDamage:getFakeInfectionLevel() - 75)
        --Poisoning +15%
        bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 15)

    elseif self.item:getType() == "PillsAntiPoisoning" then
        --Poisoning 0
        bodyDamage:setPoisonLevel(0)
        --Hunger/Thirst + 50
        playerStats:setHunger(playerStats:getHunger() + 0.5)
        playerStats:setThirst(playerStats:getThirst() + 0.5)
        --Fatigue +15%
        playerStats:setFatigue(playerStats:getFatigue() + 0.15)
        
    elseif self.item:getType() == "PillsCommercialSedative" then
        --Remove panic 150% of vanilla
        if (playerStats:getDrunkenness() > 10.0f) then
            self.character:BetaBlockers(0.15f * 1.5f);
        else
            self.character:BetaBlockers(0.45f * 1.5f);
        end
        --Remove stress to 25%
        if playerStats:getStress() <= 0.25 then
            playerStats:setStress(0)
        else
            playerStats:setStress(playerStats:getStress() - 0.25)
        end
        --Unhappiness -5%
        bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - 5)
        --Poisoning +15%
        bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 15)
        --Fatigue +10%
        playerStats:setFatigue(playerStats:getFatigue() + 0.1)
        
    elseif self.item:getType() == "PillsPharmacyPrescription" then
        --Poisoning +10%
        bodyDamage:setPoisonLevel(bodyDamage:getPoisonLevel() + 10)
    end
    
    oldISTakePillAction_perform(self)
    self.item:Use()
end