--Qpocalypse15_Professions_Items.lua
--Starting Items for Qpocalypse 1.5

require "Qpocalypse15_Professions_Setup"

Qpocalypse15 = Qpocalypse15 or {}

--Debug Log Function
local function DebugLog(message)
    print("[Qpocalypse1.5 Professions Items] " .. message)
end

-- Initial items distribution for professions
function Qpocalypse15.initProfessionsItems(_player)
	local player = _player;
	local inv = player:getInventory();

	if player:HasTrait("VanguardSpecialisation") then
		inv:addItemOnServer(inv:AddItem("Base.BaseballBatNails"))
	end

	if player:HasTrait("ReconSpecialisation") then
		inv:addItemOnServer(inv:AddItem("Base.HuntingKnife"))
	end

	if player:HasTrait("GunslingerSpecialisation") then
		inv:addItemOnServer(inv:AddItem("Base.Pistol"))
		inv:addItemOnServer(inv:AddItem("Base.9mmClip"))
		inv:addItemOnServer(inv:AddItem("Base.9mmClip"))
		inv:addItemOnServer(inv:AddItem("Base.Bullets9mmBox"))
		inv:addItemOnServer(inv:AddItem("Base.Suppressor_Bottle"))
	end

    if player:HasTrait("CraftsmanSpecialisation") then
        inv:addItemOnServer(inv:AddItem("Base.Hammer"))
    end
    
    if player:HasTrait("EngineerSpecialisation") then
        inv:addItemOnServer(inv:AddItem("Base.Wrench"))
    end

    if player:HasTrait("ForagerSpecialisation") then
        inv:addItemOnServer(inv:AddItem("Base.Shovel"))
    end

    if player:HasTrait("FieldMedicSpecialisation") then
        inv:addItemOnServer(inv:AddItem("Base.MortarPestle"))
        inv:addItemOnServer(inv:AddItem("Qpocalypse15.EmergencySurgeryKit"))
        inv:addItemOnServer(inv:AddItem("Qpocalypse15.EmergencySurgeryKit"))
    end

    if player:HasTrait("RunnerSpecialisation") then
        inv:addItemOnServer(inv:AddItem("Qpocalypse15.BagRunnerSatchel"))
    end
end

Events.OnNewGame.Add(Qpocalypse15.initProfessionsItems)