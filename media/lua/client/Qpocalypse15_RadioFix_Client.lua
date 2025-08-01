-- Qpocalypse15_RadioFix_Client.lua
-- Receives the UpdateAll command and injects radioData into Java VoiceManagerData.

--------------------------------------------------------------
-- Java class bindings (one-time, cost-free)
--------------------------------------------------------------
local RadioDataClass       = luajava.bindClass("zombie.core.raknet.VoiceManagerData$RadioData")
local VoiceManagerDataClass = luajava.bindClass("zombie.core.raknet.VoiceManagerData")

--------------------------------------------------------------
-- Helper: replace radioData list for a given player id
--------------------------------------------------------------
local function applyRadioData(pid, radios)
    local vm = VoiceManagerDataClass.get(pid)
    if not vm then return end                     -- player may have disconnected

    local list = vm.radioData
    list:clear()

    -- recreate Java RadioData objects
    for _, r in ipairs(radios) do
        local rd = luajava.new(RadioDataClass, r.distance, r.x, r.y)
        rd.freq  = r.freq
        list:add(rd)
    end
end

--------------------------------------------------------------
-- Main packet handler
--------------------------------------------------------------
local function onRadioSyncCmd(module, command, args)
    if module ~= "RadioSync" or command ~= "UpdateAll" then return end
    -- args = { {pid=xxx, radios={...}}, {pid=yyy, ...}, ... }
    for _, entry in ipairs(args) do
        applyRadioData(entry.pid, entry.radios)
    end
end

Events.OnServerCommand.Add(onRadioSyncCmd)
