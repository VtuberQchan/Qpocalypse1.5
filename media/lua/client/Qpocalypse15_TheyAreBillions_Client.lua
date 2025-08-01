-- Qpocalypse15 TheyAreBillions - Client Module

-- Table namespace
Qpocalypse15_TheyAreBillions = Qpocalypse15_TheyAreBillions or {}

---------------------------------------------------------
-- Utility : safely get the local player (SP, MP, splitscreen)
---------------------------------------------------------
local function TAB_getLocalPlayer()
    -- Try the common helpers first (handles MP nicely)
    if getPlayer then
        local ply = getPlayer()
        if ply then return ply end
    end
    -- Fallback for single-player / splitscreen index 0
    if getSpecificPlayer then
        return getSpecificPlayer(0)
    end
    return nil
end

---------------------------------------------------------
-- Public API – called from other code / hotkeys, etc.
-- Teleport + event logic is handled server-side.
---------------------------------------------------------

---------------------------------------------------------
-- 10-minute Countdown before starting the TAB event
---------------------------------------------------------
-- Forward declaration to allow countdown tick to call it before definition
local TAB_onCountdownFinished

-- Countdown control vars
local _countdownInProgress   = false
local _countdownPlayer       = nil
local _countdownValue        = 0 -- from 10 down to 0

local function TAB_CountdownTick()
    if not _countdownInProgress or not _countdownPlayer then
        -- Safety cleanup
        Events.EveryOneMinute.Remove(TAB_CountdownTick)
        _countdownInProgress = false
        return
    end

    if _countdownValue > 0 then
        _countdownPlayer:Say(tostring(_countdownValue))
        _countdownValue = _countdownValue - 1
    else
        -- Countdown finished – trigger sound sequence & eventual event start
        Events.EveryOneMinute.Remove(TAB_CountdownTick)
        _countdownInProgress = false
        TAB_onCountdownFinished()
    end
end

-- Override previous OnCall to include countdown logic
function Qpocalypse15_TheyAreBillions.OnCall()
    if _countdownInProgress then return end -- already counting

    local player = TAB_getLocalPlayer()
    if not player then return end

    -- Initialise countdown
    _countdownInProgress = true
    _countdownPlayer     = player
    _countdownValue      = 9 -- we'll say 10 immediately, then 9 .. 1 in ticks

    player:Say("10") -- Immediate first number

    Events.EveryOneMinute.Add(TAB_CountdownTick)
end

---------------------------------------------------------
-- Context Menu integration (admin / debug only)
---------------------------------------------------------
local function TAB_contextStart(_, player)
    Qpocalypse15_TheyAreBillions.OnCall()
end

local function TAB_onFillWorldObjectContextMenu(playerNum, context)
    -- Only allow on admin clients or when debug mode is enabled
    if (isAdmin and isAdmin()) or (isDebugEnabled and isDebugEnabled()) then
        local label = getText("ContextMenu_Qpocalypse15_StartTAB")
        if label and label ~= "" then
            context:addOptionOnTop(label, getSpecificPlayer(playerNum), TAB_contextStart)
        else
            context:addOptionOnTop("Start TAB Event", getSpecificPlayer(playerNum), TAB_contextStart)
        end
    end
end
Events.OnFillWorldObjectContextMenu.Add(TAB_onFillWorldObjectContextMenu)

---------------------------------------------------------
-- Handle server instructions (return to original position)
---------------------------------------------------------
local function TAB_onServerCommand(module, command, args)
    if module ~= 'TheyAreBillions' then return end
    if command == 'Return' then
        local player = TAB_getLocalPlayer()
        if not player or not args then return end
        if args.x and args.y then
            player:setX(args.x)
            player:setY(args.y)
            player:setZ(args.z or 0)
            player:setLx(args.x)
            player:setLy(args.y)
            player:setLz(args.z or 0)
        end
        -- Optionally show message based on success
        if args.success and args.success == true then
            -- survived
            local txt = getTextOrNull("IGUI_PlayerText_TABSuccess") or "Survived the horde!"
            player:Say(txt)
        else
            local txt = getTextOrNull("IGUI_PlayerText_TABFail") or "The horde overwhelmed us..."
            player:Say(txt)
        end
    elseif command == 'Noise' then
        -- create world sound to attract zombies towards the player
        local player = TAB_getLocalPlayer()
        if player then
            AddWorldSound(player, 100, 100)
        end
    end
end
Events.OnServerCommand.Add(TAB_onServerCommand)

local OHMYGOD_SOUND_NAME = "QP15_OhMyGod"
local TAB_SOUND_NAME     = "QP15_TAB"

-- Sound sequence state (2D playback via SoundManager)
local _soundStage = 0  -- 0 = idle, 1 = first playing, 2 = second playing
local _soundID1   = nil
local _soundID2   = nil

local function TAB_SoundMonitor()
    if _soundStage == 0 then
        Events.OnTick.Remove(TAB_SoundMonitor)
        return
    end

    if _soundStage == 1 then
        if not _soundID1 or not isSoundPlaying(_soundID1) then
            -- First finished, play second
            _soundStage = 2
            _soundID2 = getSoundManager():PlaySound(TAB_SOUND_NAME, false, 1)
        end
    elseif _soundStage == 2 then
        if not _soundID2 or not isSoundPlaying(_soundID2) then
            -- All done; cleanup and notify server that music finished (event already started)
            _soundStage = 0
            Events.OnTick.Remove(TAB_SoundMonitor)
        end
    end
end

-- Countdown finished handler (definition after sound helpers, now locals are in scope)
function TAB_onCountdownFinished()
    if not _countdownPlayer then return end

    local startLine = getText("IGUI_PlayerText_TABStart")
    if startLine and startLine ~= "" then
        _countdownPlayer:Say(startLine)
    end

    -- Instruct server to start the event (handles zombie logic)
    -- Client-side teleport to arena centre (sync propagates automatically)
    _countdownPlayer:setX(300)
    _countdownPlayer:setY(150)
    _countdownPlayer:setZ(0)
    _countdownPlayer:setLx(300)
    _countdownPlayer:setLy(150)
    _countdownPlayer:setLz(0)

    if sendClientCommand then
        sendClientCommand(_countdownPlayer, 'TheyAreBillions', 'StartEvent', {})
    end

    -- Play OhMyGod sound (2D, non-positional)
    local sm = getSoundManager()
    if sm and sm.PlaySound then
        _soundID1 = sm:PlaySound(OHMYGOD_SOUND_NAME, false, 1)
        if _soundID1 then
            _soundStage = 1
            Events.OnTick.Add(TAB_SoundMonitor)
        end
    end
end
