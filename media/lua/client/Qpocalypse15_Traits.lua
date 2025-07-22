--Qpocalypse15_Traits.lua
--Traits for Qpocalypse 1.5

require "2ProfessionFramework"
require "3ProfessionTraits"

Qpocalypse15 = Qpocalypse15 or {}

--Debug Log Function
local function DebugLog(message)
    print("[Qpocalypse1.5 Traits] " .. message)
end

---------Trait Functions---------
--Strongback
function StrongbackFunction()
    local player = getPlayer()
    local runnerBonus = 12
    local default = 8
    local strength = player:getPerkLevel(Perks.Strength)
    local runnerMaxWeightBonus = math.floor(runnerBonus + strength / 5)
    local defaultMaxWeightBonus = math.floor(default + strength / 5)
    if player:HasTrait("Strongback") then
        player:setMaxWeightBase(runnerMaxWeightBonus)
    else
        player:setMaxWeightBase(defaultMaxWeightBonus)
    end
    if player:getMaxWeightBase() > 50 then
        player:setMaxWeightBase(50)
    end
end

--Specialisation
function SpecialisationFunction(_player, _perk, _amount)
	local player = _player;
	local perk = _perk
	local amount = _amount
	local newamount = 0
	local skip = false
	local modifier = 10
	local perklvl = player:getPerkLevel(_perk)
	local perkxpmod = 1;
	--shift decimal over two places for calculation purposes.
	modifier = modifier * 0.01;
	if perk == Perks.Fitness or perk == Perks.Strength then
		skipxpadd = true
	end
	if skipxpadd == false then
		if player:HasTrait("VanguardSpecialisation") or player:HasTrait("ReconSpecialisation") or player:HasTrait("GunslingerSpecialisation") or player:HasTrait("CraftsmanSpecialisation") or player:HasTrait("EngineerSpecialisation") or player:HasTrait("ForagerSpecialisation") or player:HasTrait("FieldMedicSpecialisation") or player:HasTrait("RunnerSpecialisation") then
			if player:HasTrait("VanguardSpecialisation") then
				if perk == Perks.Sprinting or perk == Perks.Nimble or perk == Perks.Axe or perk == Perks.Blunt then
					skip = true
				end
			end
			if player:HasTrait("ReconSpecialisation") then
				if perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak or perk == Perks.SmallBlade or perk == Perks.LongBlade then
					skip = true
				end
			end
			if player:HasTrait("GunslingerSpecialisation") then
				if perk == Perks.Nimble or perk == Perks.Sneak or perk == Perks.Aiming or perk == Perks.Reloading or perk == Perks.SmallBlunt then
					skip = true
				end
			end
			if player:HasTrait("CraftsmanSpecialisation") then
				if perk == Perks.Maintenance or perk == Perks.Woodwork or perk == Perks.MetalWelding or perk == Perks.Tailoring then
					skip = true
				end
			end
			if player:HasTrait("EngineerSpecialisation") then
				if perk == Perks.Maintenance or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics then
					skip = true
				end
			end
			if player:HasTrait("ForagerSpecialisation") then
				if perk == Perks.Farming or perk == Perks.Fishing or perk == Perks.PlantScavenging or perk == Perks.Trapping then
					skip = true
				end
			end
            if player:HasTrait("FieldMedicSpecialisation") then
                if perk == Perks.Nimble or perk == Perks.SmallBlade or perk == Perks.Cooking or perk == Perks.Doctor then
                    skip = true
                end
            end
            if player:HasTrait("RunnerSpecialisation") then
                if perk == Perks.Nimble or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Sneak or perk == Perks.Driving or perk == Perks.Scavenging then
                    skip = true
                end
            end
			newamount = amount * modifier
			local currentxp = player:getXp():getXP(perk)
			local correctamount = currentxp - newamount
			local testxp = currentxp - amount
			--Check if the newxp amount would give the player a negative level.
			if skip == false then
				if perklvl == 0 and testxp <= 0 then
					skip = true;
				elseif perklvl == 1 and testxp <= 75 then
					skip = true;
				elseif perklvl == 2 and testxp <= 150 then
					skip = true;
				elseif perklvl == 3 and testxp <= 300 then
					skip = true;
				elseif perklvl == 4 and testxp <= 750 then
					skip = true;
				elseif perklvl == 5 and testxp <= 1500 then
					skip = true;
				elseif perklvl == 6 and testxp <= 3000 then
					skip = true;
				elseif perklvl == 7 and testxp <= 4500 then
					skip = true;
				elseif perklvl == 8 and testxp <= 6000 then
					skip = true;
				elseif perklvl == 9 and testxp <= 7500 then
					skip = true;
				elseif perklvl == 10 and testxp <= 9000 then
					skip = true;
				end
			end
			if skip == false then
				local xpforlevel = perk:getXpForLevel(perklvl) + 50
				while player:getXp():getXP(perk) > correctamount do
					local curxp = player:getXp():getXP(perk)
					if xpforlevel >= curxp then
						break ;
					else
						AddXP(player, perk, -1 * 0.1)
					end
				end
			end
		end
	else
		skipxpadd = false;
	end
end

function FixSpecialisationFunction(player, perk)
	if player:getXp():getXP(perk) < 0 then
		player:getXp():setXPToLevel(Perks.perk, player:getPerkLevel(perk))
	end
end

--Cmbat Specialisation
function VanguardCombatSpecialisation(_actor, _target, _weapon, _damage)
	local player = getPlayer()
	local weapon = _weapon
	local weapondata = weapon:getModData()
	local critchance = player:getPerkLevel(Perks.Axe) + player:getPerkLevel(Perks.Blunt) + 5
	local damage = _damage
	if _actor == player and player:HasTrait("VanguardSpecialisation") then
		if weapon:getCategories():contains("Axe") or weapon:getCategories():contains("Blunt") then
			if player:HasTrait("Lucky") then
				critchance = critchance + 1 * luckimpact
			end
			if player:HasTrait("Unlucky") then
				critchance = critchance - 1 * luckimpact
			end
			if _target:isZombie() and ZombRand(0, 101) <= critchance and player:HasTrait("mundane") == false then
				damage = damage * 2
			end
			_target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1)
			if _target:getHealth() <= 0 and _target:isAlive() then
				_target:update()
			end
			if weapondata.iLastWeaponCond == nil then
				weapondata.iLastWeaponCond = weapon:getCondition()
			end
			if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
				if weapon:getCondition() < weapon:getConditionMax() then
					weapon:setCondition(weapon:getCondition() + 1)
				end
			end
			weapondata.iLastWeaponCond = weapon:getCondition()
		end
	end
end

function ReconCombatSpecialisation(_actor, _target, _weapon, _damage)
	local player = getPlayer()
	local weapon = _weapon
	local weapondata = weapon:getModData()
	local critchance = player:getPerkLevel(Perks.SmallBlade) + player:getPerkLevel(Perks.SmallBlunt)
	local damage = _damage
	if _actor == player and player:HasTrait("ReconSpecialisation") then
		if weapon:getCategories():contains("SmallBlade") or weapon:getCategories():contains("SmallBlunt") or weapon:getCategories():contains("LongBlade") then
			if player:HasTrait("Lucky") then
				critchance = critchance + 1 * luckimpact
			end
			if player:HasTrait("Unlucky") then
				critchance = critchance - 1 * luckimpact
			end
			if _target:isZombie() and ZombRand(0, 101) <= critchance and player:HasTrait("mundane") == false then
				damage = damage * 2
			end
			_target:setHealth(_target:getHealth() - (damage * 1.2) * 0.1)
			if _target:getHealth() <= 0 and _target:isAlive() then
				_target:update()
			end
			if weapondata.iLastWeaponCond == nil then
				weapondata.iLastWeaponCond = weapon:getCondition()
			end
			if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
				if weapon:getCondition() < weapon:getConditionMax() then
					weapon:setCondition(weapon:getCondition() + 1)
				end
			end
			weapondata.iLastWeaponCond = weapon:getCondition()
		end
	end
end

function GunslingerCombatSpecialisation(_actor, _weapon)
	local player = getPlayer()
	local weapon = _weapon
	local weapondata = weapon:getModData()
	local maxCapacity = weapon:getMaxAmmo()
	local currentCapacity = weapon:getCurrentAmmoCount()
	local chance = 10 + player:getPerkLevel(Perks.Aiming) + player:getPerkLevel(Perks.Reloading)
	if _actor == player and player:HasTrait("GunslingerSpecialisation") and weapon:getSubCategory() == "Firearm" then
		if player:HasTrait("Lucky") then
			chance = chance + 5 * luckimpact
		end
		if player:HasTrait("Unlucky") then
			chance = chance - 5 * luckimpact
		end

		if weapondata.iLastWeaponCond == nil then
			weapondata.iLastWeaponCond = weapon:getCondition()
		end
		if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
			if weapon:getCondition() < weapon:getConditionMax() then
				weapon:setCondition(weapon:getCondition() + 1)
			end
		end
		weapondata.iLastWeaponCond = weapon:getCondition()
		if SandboxVars.MoreTraits.ProwessGunsAmmoRestore == true and ZombRand(0, 101) <= chance then
			if currentCapacity < maxCapacity and currentCapacity > 0 then
				weapon:setCurrentAmmoCount(currentCapacity + 1)
				if MoreTraits.settings.ProwessGunsAmmo == true then
					HaloTextHelper.addText(player, getText("IGUI_progunammo"), HaloTextHelper.getColorGreen());
				end
			end
		end
	end
end