--Qpocalypse15_Traits_Setup.lua
--Traits Setup for Qpocalypse 1.5

require("NPCs/MainCreationMethods")
require("Qpocalypse15_Traits")

Qpocalypse15 = Qpocalypse15 or {}

--Debug Log Function
local function DebugLog(message)
    print("[Qpocalypse1.5 Traits Setup] " .. message)
end

---------New Traits---------
--Strongback
ProfessionFramework.addTrait('Strongback', {
    name = "UI_trait_strongback",
    description = "UI_trait_strongbackdesc",
    exclude = {
        "Weak",
        "Unfit",
    },
    profession = true,
    OnGameStart = function(trait)
        Events.EveryTenMinutes.Add(StrongbackFunction)
    end
})

--Specialisations--
ProfessionFramework.addTrait('VanguardSpecialisation', {
    name = "UI_trait_vanguardspecialisation",
    description = "UI_trait_vanguardspecialisationdesc",
    profession = true,
    OnGameStart = function(trait)
        Events.AddXP.Add(SpecialisationFunction)
        Events.LevelPerk.Add(FixSpecialisationFunction)
        Events.OnWeaponHitCharacter.Add(VanguardCombatSpecialisation)
    end
})

ProfessionFramework.addTrait('ReconSpecialisation', {
    name = "UI_trait_reconspecialisation",
    description = "UI_trait_reconspecialisationdesc",
    profession = true,
    OnGameStart = function(trait)
        Events.AddXP.Add(SpecialisationFunction)
        Events.LevelPerk.Add(FixSpecialisationFunction)
        Events.OnWeaponHitCharacter.Add(ReconCombatSpecialisation)
    end
})

ProfessionFramework.addTrait('GunslingerSpecialisation', {
    name = "UI_trait_gunslingerspecialisation",
    description = "UI_trait_gunslingerspecialisationdesc",
    profession = true,
    OnGameStart = function(trait)
        Events.AddXP.Add(SpecialisationFunction)
        Events.LevelPerk.Add(FixSpecialisationFunction)
        Events.OnWeaponHitCharacter.Add(GunslingerCombatSpecialisation)
    end
})

ProfessionFramework.addTrait('CraftsmanSpecialisation', {
    name = "UI_trait_craftsmanspecialisation",
    description = "UI_trait_craftsmanspecialisationdesc",
    profession = true,
    OnGameStart = function(trait)
        Events.AddXP.Add(SpecialisationFunction)
        Events.LevelPerk.Add(FixSpecialisationFunction)
    end
})

ProfessionFramework.addTrait('EngineerSpecialisation', {
    name = "UI_trait_engineerspecialisation",
    description = "UI_trait_engineerspecialisationdesc",
    profession = true,
    OnGameStart = function(trait)
        Events.AddXP.Add(SpecialisationFunction)
        Events.LevelPerk.Add(FixSpecialisationFunction)
    end
})

ProfessionFramework.addTrait('ForagerSpecialisation', {
    name = "UI_trait_foragerspecialisation",
    description = "UI_trait_foragerspecialisationdesc",
    profession = true,
    OnGameStart = function(trait)
        Events.AddXP.Add(SpecialisationFunction)
        Events.LevelPerk.Add(FixSpecialisationFunction)
    end
})

ProfessionFramework.addTrait('FieldMedicSpecialisation', {
    name = "UI_trait_fieldmedicspecialisation",
    description = "UI_trait_fieldmedicspecialisationdesc",
    profession = true,
    OnGameStart = function(trait)
        Events.AddXP.Add(SpecialisationFunction)
        Events.LevelPerk.Add(FixSpecialisationFunction)
    end
})

ProfessionFramework.addTrait('RunnerSpecialisation', {
    name = "UI_trait_runnerspecialisation",
    description = "UI_trait_runnerspecialisationdesc",
    profession = true,
    OnGameStart = function(trait)
        Events.AddXP.Add(SpecialisationFunction)
        Events.LevelPerk.Add(FixSpecialisationFunction)
    end
})
--End of Specialisations--