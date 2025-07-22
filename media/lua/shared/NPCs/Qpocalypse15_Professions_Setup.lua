--Qpocalypse15_Professions.lua
--Professions for Qpocalypse 1.5

require("Qpocalypse15_Traits_Setup")

Qpocalypse15 = Qpocalypse15 or {}

--Debug Log Function
local function DebugLog(message)
    print("[Qpocalypse1.5 Professions] " .. message)
end

--Remove all vanilla professions
ProfessionFramework.RemoveDefaultProfessions = true

--Always use starting kits
ProfessionFramework.AlwaysUseStartingKits = true

---------Combatant Professions---------
--Vanguard
ProfessionFramework.addProfession("Vanguard", {
    icon = "profession_Qpocalypse15_vanguard",
    name = "UI_prof_Qpocalypse15_vanguard",
    cost = -4,
    xp = {
        [Perks.Strength] = 2,
        [Perks.Sprinting] = 2,
        [Perks.Nimble] = 2,
        [Perks.Axe] = 2,
        [Perks.Blunt] = 2,
    },
    inventory = {
        "Base.BaseballBatNails",
    },
    traits = {
        "VanguardSpecialisation",
    },
    recipes = {
        --Placeholder, will be changed
    },
})

--Recon
ProfessionFramework.addProfession("Recon", {
    icon = "profession_Qpocalypse15_recon",
    name = "UI_prof_Qpocalypse15_recon",
    cost = -2,
    xp = {
        [Perks.Fitness] = 2,
        [Perks.Sprinting] = 1,
        [Perks.Lightfoot] = 1,
        [Perks.Nimble] = 2,
        [Perks.Sneak] = 1,
        [Perks.SmallBlade] = 4,
        [Perks.LongBlade] = 1,
    },
    inventory = {
        "Base.HuntingKnife",
    },
    traits = {
        "ReconSpecialisation",
    },
    recipes = {
    },
})

--Gunslinger
ProfessionFramework.addProfession("Gunslinger", {
    icon = "profession_Qpocalypse15_gunslinger",
    name = "UI_prof_Qpocalypse15_gunslinger",
    cost = 0,
    xp = {
        [Perks.Strength] = 1,
        [Perks.Fitness] = 1,
        [Perks.Nimble] = 1,
        [Perks.Sneak] = 1,
        [Perks.SmallBlunt] = 1,
        [Perks.Aiming] = 3,
        [Perks.Reloading] = 3,
    },
    inventory = {
        "Base.Pistol",
        "Base.9mmClip",
        "Base.9mmClip",
        "Base.Bullets9mmBox",
        "Base.Suppressor_Bottle",
    },
    traits = {
        "GunslingerSpecialisation",
    },
    recipes = {
    },
})

---------Specialist Professions---------
--Craftsman
ProfessionFramework.addProfession("Craftsman", {
    icon = "profession_Qpocalypse15_craftsman",
    name = "UI_prof_Qpocalypse15_craftsman",
    cost = 4,
    xp = {
        [Perks.Maintenance] = 2,
        [Perks.Woodwork] = 2,
        [Perks.MetalWelding] = 1,
        [Perks.Tailoring] = 2,
    },
    inventory = {
        "Base.Hammer",
    },
    traits = {
        "CraftsmanSpecialisation",
    },
    recipes = {
        "Make Metal Walls",
        "Make Metal Fences",
        "Make Metal Containers",
        "Make Metal Sheet",
        "Make Small Metal Sheet",
        "Make Metal Roof",
    },
})

--Engineer
ProfessionFramework.addProfession("Engineer", {
    icon = "profession_Qpocalypse15_engineer",
    name = "UI_prof_Qpocalypse15_engineer",
    cost = 4,
    xp = {
        [Perks.Electricity] = 2,
        [Perks.MetalWelding] = 2,
        [Perks.Mechanics] = 2,
    },
    inventory = {
        "Base.Wrench",
    },
    traits = {
        "EngineerSpecialisation",
    },
    recipes = {
        "Generator",
        "Make Remote Controller V1",
        "Make Remote Controller V2",
        "Make Remote Controller V3",
        "Make Remote Trigger",
        "Make Timer",
        "Craft Makeshift Radio",
        "Craft Makeshift HAM Radio",
        "Craft Makeshift Walkie Talkie",
        "Make Aerosol bomb",
        "Make Flame bomb",
        "Make Pipe bomb",
        "Make Noise generator",
        "Make Smoke Bomb",
        "Make Metal Walls",
        "Make Metal Fences",
        "Make Metal Containers",
        "Make Metal Sheet",
        "Make Small Metal Sheet",
        "Make Metal Roof",
        "Basic Mechanics",
        "Intermediate Mechanics",
        "Advanced Mechanics",
        "Make Metal Workbench",
        "Make File",
    },
})

--Forager
ProfessionFramework.addProfession("Forager", {
    icon = "profession_Qpocalypse15_forager",
    name = "UI_prof_Qpocalypse15_forager",
    cost = 6,
    xp = {
        [Perks.Farming] = 2,
        [Perks.Fishing] = 2,
        [Perks.PlantScavenging] = 2,
        [Perks.Trapping] = 2,
    },
    inventory = {
        "Base.Shovel",
    },
    traits = {
        "Herbalist2",
        "ForagerSpecialisation",
    },
    recipes = {
        "Make Mildew Cure",
        "Make Flies Cure",
        "Make Fishing Rod",
        "Fix Fishing Rod",
        "Get Wire Back",
        "Make Fishing Net",
        "Make Stick Trap",
        "Make Snare Trap",
        "Make Wooden Box Trap",
        "Make Trap Box",
        "Make Cage Trap",
    },
})

--Field Medic
ProfessionFramework.addProfession("Field Medic", {
    icon = "profession_Qpocalypse15_field_medic",
    name = "UI_prof_Qpocalypse15_field_medic",
    cost = 6,
    xp = {
        [Perks.Nimble] = 1,
        [Perks.SmallBlade] = 1,
        [Perks.Cooking] = 2,
        [Perks.Doctor] = 4,
    },
    inventory = {
        "Base.MortarPestle",
        "Qpocalypse15.EmergencySurgeryKit",
        "Qpocalypse15.EmergencySurgeryKit",
    },
    traits = {
        "FieldMedicSpecialisation",
    },
    recipes = {
        "Make Cake Batter",
        "Make Pie Dough",
        "Make Bread Dough",
        "Make Biscuits",
        "Make Chocolate Cookie Dough",
        "Make Chocolate Chip Cookie Dough",
        "Make Oatmeal Cookie Dough",
        "Make Shortbread Cookie Dough",
        "Make Sugar Cookie Dough",
        "Make Pizza",
        "Make PillsCommercialPainkillers",
        "Make PillsPrescriptionPainkillers",
        "Make SyretteHighGradePainkillers",
        "Make PillsCaffeine",
        "Make SyretteAdrenalin",
        "Make PillsCommercialAntibiotic",
        "Make SyrettePrescriptionAntibiotic",
        "Make PillsAntiPoisoning",
        "Make PillsCommercialSedative",
        "Make SyrettePrescriptionSedatives",
        "Make BottleFluMedication",
        "Make PowderPackFluMedication",
        "Make BurnTreatment",
        "Make PowderPackHemostatic",
        "Make Tourniquet",
        "Make NasalSpray",
        "Make EmergencySurgeryKit",
    },
})

--Runner
ProfessionFramework.addProfession("Runner", {
    icon = "profession_Qpocalypse15_runner",
    name = "UI_prof_Qpocalypse15_runner",
    cost = 4,
    xp = {
        [Perks.Nimble] = 1,
        [Perks.Sprinting] = 1,
        [Perks.Lightfoot] = 1,
        [Perks.Sneak] = 1,
        [Perks.Driving] = 4,
        [Perks.Scavenging] = 4,
    },
    inventory = {
        "Qpocalypse15.BagRunnerSatchel",
    },
    traits = {
        "Dextrous2",
        "Strongback",
        "RunnerSpecialisation",
    },
    recipes = {
    },
})