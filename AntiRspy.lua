local Blacklist = {
    ketamine    = true,
    simplespy   = true,
    cobalt      = true,
    dex         = true,
    xeal        = true,
}

local kicked = false

local function localKick(spyName)
    if kicked then return end
    kicked = true

    local Players = game:GetService("Players")
    local plr = Players.LocalPlayer

    local msg = "Spy Detected | Blacklisted Method"
    msg = msg .. "\n\nSpy détecté: " .. tostring(spyName or "Inconnu")

    if plr then
        pcall(function() plr:Kick(msg) end)
    end
    pcall(function() Players:Kick(msg) end)

    task.delay(0.25, function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end)
    end)

    task.delay(1, function()
        pcall(function() game:Shutdown() end)
    end)
end

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function getEnv()
    local g = safeCall(function()
        if type(getgenv) == "function" then
            return getgenv()
        end
    end)
    return g or _G
end

local function getGuiContainers()
    local list = {}

    safeCall(function()
        table.insert(list, game:GetService("CoreGui"))
    end)

    safeCall(function()
        local plr = game:GetService("Players").LocalPlayer
        if plr then
            local pg = plr:FindFirstChild("PlayerGui")
            if pg then table.insert(list, pg) end
        end
    end)

    safeCall(function()
        if type(gethui) == "function" then
            local h = gethui()
            if h then table.insert(list, h) end
        end
    end)

    return list
end

local function detectKetamine()
    for _, container in ipairs(getGuiContainers()) do
        local ok, found = pcall(function()
            return container:FindFirstChild("Ketamine") ~= nil
        end)
        if ok and found then return true end
    end

    local env = getEnv()
    if env["__KetamineShared"] then return true end

    return false
end

local function detectSimpleSpy()
    local env = getEnv()

    if env.SimpleSpyExecuted == true
       and type(env.SimpleSpyShutdown) == "function" then
        return true
    end

    local containers = getGuiContainers()

    for _, container in ipairs(containers) do
        local ok, found = pcall(function()
            return container:FindFirstChild("SimpleSpy2") ~= nil
        end)
        if ok and found then return true end
    end

    for _, container in ipairs(containers) do
        local ok, found = pcall(function()
            for _, gui in ipairs(container:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    local topbar = gui:FindFirstChild("TopBar", true)
                    if topbar then
                        local simple = topbar:FindFirstChild("Simple")
                        if simple and simple:IsA("TextButton")
                           and typeof(simple.Text) == "string"
                           and simple.Text:find("SimpleSpy", 1, true) == 1 then
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

local function detectCobalt()
    local env = getEnv()
    local cobalt = env.Cobalt

    if typeof(cobalt) == "table" then
        local ok1, envname = pcall(function() return cobalt.envname end)
        if ok1 and envname == "Cobalt" then return true end
    end

    if env.CobaltInitialized == true then return true end

    for _, container in ipairs(getGuiContainers()) do
        local ok, found = pcall(function()
            return container:FindFirstChild("Cobalt") ~= nil
        end)
        if ok and found then return true end
    end

    return false
end

local function detectDex()
    local containers = getGuiContainers()

    for _, container in ipairs(containers) do
        local ok, found = pcall(function()
            for _, v in ipairs(container:GetChildren()) do
                if v:IsA("ScreenGui") then
                    local name = v.Name
                    if typeof(name) == "string"
                       and #name > 5
                       and name:sub(1, 5) == "_DPP_" then
                        return true
                    end
                end
            end
            return false
        end)
        if ok and found then return true end
    end

    for _, container in ipairs(containers) do
        local ok, found = pcall(function()
            for _, gui in ipairs(container:GetChildren()) do
                if gui:IsA("ScreenGui") then
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

local function detectXeal()
    local containers = getGuiContainers()

    local criticalGuis = {
        "ChainRageGui",
        "GilbertExecItemGui",
        "DZeroPackGui",
        "DavePackGui",
        "GilbertPackGui",
        "WeaponPackGui",
        "RifDodgeGui",
        "ViralLeaderGui",
        "ViralRunnerGui",
        "ViralExecutionerGui",
        "ToolGripCustomGui",
        "ToolGripPanelGui",
        "BossSongsPanelGui",
        "VoicelinesHotbarGui",
        "SinStunVoicePanelGui",
        "AnimReplaceGui",
        "RifDodgePanelGui",
        "RifDodgeSetGui",
        "NoIdleGui",
    }
    for _, container in ipairs(containers) do
        for _, guiName in ipairs(criticalGuis) do
            local ok, found = pcall(function()
                return container:FindFirstChild(guiName) ~= nil
            end)
            if ok and found then return true end
        end
    end

    local softGuis = {
        "SinSwapGui",
        "ExecModeGui",
        "ExecAnimGui",
        "SinLocoToggleGui",
        "SinStunToggleGui",
        "SinStunGui",
        "ToolGripGui",
        "ToolGripShowGui",
        "ToolGripGizmoGui",
        "ToolGripNudgeGui",
        "BossMusicGui",
        "MagnaGui",
        "BossSongsGui",
        "LayoutEditorGui",
        "VoicelinesGui",
        "VoicelinesPanelGui",
        "GetInfectedGui",
        "AttrBoostGui",
        "QteSpamGui",
        "VictimAnimGui",
    }
    local softHits, seen = 0, {}
    for _, container in ipairs(containers) do
        for _, guiName in ipairs(softGuis) do
            if not seen[guiName] then
                local ok, found = pcall(function()
                    return container:FindFirstChild(guiName) ~= nil
                end)
                if ok and found then
                    seen[guiName] = true
                    softHits = softHits + 1
                    if softHits >= 5 then return true end
                end
            end
        end
    end

    return false
end

task.spawn(function()
    while not kicked do
        local spy = nil

        if Blacklist.xeal and detectXeal() then
            spy = "Xeal"
        elseif Blacklist.ketamine and detectKetamine() then
            spy = "Ketamine"
        elseif Blacklist.simplespy and detectSimpleSpy() then
            spy = "SimpleSpy"
        elseif Blacklist.cobalt and detectCobalt() then
            spy = "Cobalt"
        elseif Blacklist.dex and detectDex() then
            spy = "Dex Explorer"
        end

        if spy then
            localKick(spy)
            break
        end

        task.wait(1)
    end
end)