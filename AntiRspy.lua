local Blacklist = {
    ketamine    = true,
    simplespy   = true,
    cobalt      = true,
    dex         = true,
    xeal        = true,
}

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local kicked = false

local function localKick(spyName)
    if kicked then return end
    kicked = true

    local plr = Players.LocalPlayer
    local msg = "Spy Detected | Blacklisted Method"
    msg = msg .. "\n\nSpy détecté: " .. tostring(spyName or "Inconnu")

    if plr then pcall(function() plr:Kick(msg) end) end
    pcall(function() Players:Kick(msg) end)

    task.delay(0.25, function()
        pcall(function() TeleportService:Teleport(game.PlaceId) end)
    end)

    task.delay(1, function()
        pcall(function() game:Shutdown() end)
    end)
end

local function toSet(list)
    local s = {}
    for _, v in ipairs(list) do s[v] = true end
    return s
end

local CRITICAL_XEAL = toSet({
    "ChainRageGui","GilbertExecItemGui","DZeroPackGui","DavePackGui",
    "GilbertPackGui","WeaponPackGui","RifDodgeGui","ViralLeaderGui",
    "ViralRunnerGui","ViralExecutionerGui","ToolGripCustomGui",
    "ToolGripPanelGui","BossSongsPanelGui","VoicelinesHotbarGui",
    "SinStunVoicePanelGui","AnimReplaceGui","RifDodgePanelGui",
    "RifDodgeSetGui","NoIdleGui",
})

local SOFT_XEAL = toSet({
    "SinSwapGui","ExecModeGui","ExecAnimGui","SinLocoToggleGui",
    "SinStunToggleGui","SinStunGui","ToolGripGui","ToolGripShowGui",
    "ToolGripGizmoGui","ToolGripNudgeGui","BossMusicGui","MagnaGui",
    "BossSongsGui","LayoutEditorGui","VoicelinesGui","VoicelinesPanelGui",
    "GetInfectedGui","AttrBoostGui","QteSpamGui","VictimAnimGui",
})

local function getEnv()
    if type(getgenv) == "function" then
        local ok, g = pcall(getgenv)
        if ok then return g end
    end
    return _G
end

local function getGuiContainers()
    local list = {}

    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then list[#list + 1] = cg end

    local plr = Players.LocalPlayer
    if plr then
        local pg = plr:FindFirstChild("PlayerGui")
        if pg then list[#list + 1] = pg end
    end

    if type(gethui) == "function" then
        local ok2, h = pcall(gethui)
        if ok2 and h then list[#list + 1] = h end
    end

    return list
end

local function detectKetamine(containers, env)
    for i = 1, #containers do
        local ok, found = pcall(function()
            return containers[i]:FindFirstChild("Ketamine") ~= nil
        end)
        if ok and found then return true end
    end
    return env["__KetamineShared"] ~= nil
end

local function detectSimpleSpy(containers, env)
    if env.SimpleSpyExecuted == true
       and type(env.SimpleSpyShutdown) == "function" then
        return true
    end

    for i = 1, #containers do
        local ok, found = pcall(function()
            return containers[i]:FindFirstChild("SimpleSpy2") ~= nil
        end)
        if ok and found then return true end
    end

    for i = 1, #containers do
        local ok, found = pcall(function()
            for _, gui in ipairs(containers[i]:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    local topbar = gui:FindFirstChild("TopBar", true)
                    if topbar then
                        local simple = topbar:FindFirstChild("Simple")
                        if simple and simple:IsA("TextButton")
                           and simple.Text:sub(1, 9) == "SimpleSpy" then
                            return true
                        end
                    end
                end
            end
            return false
        end)
        if ok and found then return true end
    end

    return false
end

local function detectCobalt(containers, env)
    local cobalt = env.Cobalt
    if type(cobalt) == "table" then
        local ok, envname = pcall(function() return cobalt.envname end)
        if ok and envname == "Cobalt" then return true end
    end

    if env.CobaltInitialized == true then return true end

    for i = 1, #containers do
        local ok, found = pcall(function()
            return containers[i]:FindFirstChild("Cobalt") ~= nil
        end)
        if ok and found then return true end
    end

    return false
end

local function detectDex(containers, env)
    for i = 1, #containers do
        local ok, found = pcall(function()
            for _, gui in ipairs(containers[i]:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    if gui.Name:sub(1, 5) == "_DPP_" then
                        return true
                    end
                    local btn = gui:FindFirstChild("OpenButton", true)
                    if btn and btn:IsA("TextButton") and btn.Text == "Dex++" then
                        return true
                    end
                end
            end
            return false
        end)
        if ok and found then return true end
    end
    return false
end

local function detectXeal(containers, env)
    local softHits = 0
    local seen = {}

    for i = 1, #containers do
        local ok, isXeal = pcall(function()
            for _, gui in ipairs(containers[i]:GetChildren()) do
                local name = gui.Name
                if CRITICAL_XEAL[name] then return true end
                if SOFT_XEAL[name] and not seen[name] then
                    seen[name] = true
                    softHits = softHits + 1
                    if softHits >= 5 then return true end
                end
            end
            return false
        end)
        if ok and isXeal then return true end
    end

    return false
end

task.spawn(function()
    while not kicked do
        local containers = getGuiContainers()
        local env        = getEnv()
        local spy

        if Blacklist.xeal and detectXeal(containers, env) then
            spy = "Xeal"
        elseif Blacklist.ketamine and detectKetamine(containers, env) then
            spy = "Ketamine"
        elseif Blacklist.simplespy and detectSimpleSpy(containers, env) then
            spy = "SimpleSpy"
        elseif Blacklist.cobalt and detectCobalt(containers, env) then
            spy = "Cobalt"
        elseif Blacklist.dex and detectDex(containers, env) then
            spy = "Dex Explorer"
        end

        if spy then
            localKick(spy)
            break
        end

        task.wait(1)
    end
end)
