--[[ media/lua/shared/NPCs/Qpocalypse15_RemoveRobbie.lua
local robbies = {
    "Brita_Robbie", "Brita_Robbie_Blue", "Brita_Robbie_Green",
    "Brita_Robbie_Grey", "Brita_Robbie_Purple", "Brita_Robbie_Yellow",
}

local function zeroRobbieChance()
    if not ZombiesZoneDefinition then return end
    for _, zoneTable in pairs(ZombiesZoneDefinition) do
        if type(zoneTable) == "table" then
            for _, entry in ipairs(zoneTable) do
                for _, r in ipairs(robbies) do
                    if entry.name == r then
                        entry.chance = 0
                    end
                end
            end
        end
    end
end

Events.OnInitWorld.Add(zeroRobbieChance)]]--