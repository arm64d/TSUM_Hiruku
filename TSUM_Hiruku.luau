local function BootLog(message)
    local line = "[Hiruku][BOOT] " .. tostring(message)
    pcall(function()
        if type(rconsoleprint) == "function" then rconsoleprint(line .. "\n") end
    end)
    warn(line)
end

BootLog("запуск v20.1.1")

local Fluent
local fluentSources = {
    "https://raw.githubusercontent.com/StyearX/Fluent-modded/main/dist/main.lua",
    "https://github.com/StyearX/Fluent-modded/releases/download/1.5.1/FluentPro",
}
local loadErr = nil
for _, url in ipairs(fluentSources) do
    local ok, result = pcall(function()
        if type(loadstring) ~= "function" then error("loadstring недоступен в этом executor") end
        local body = game:HttpGet(url, true)
        if type(body) ~= "string" or #body < 1000 then error("Fluent source пустой или повреждён") end
        local fn, compileErr = loadstring(body)
        if type(fn) ~= "function" then error(tostring(compileErr or "loadstring вернул не функцию")) end
        return fn()
    end)
    if ok and type(result) == "table" and type(result.CreateWindow) == "function" then
        Fluent = result
        BootLog("Fluent загружен: " .. url)
        break
    end
    loadErr = result
    BootLog("Fluent не загрузился: " .. url .. " | " .. tostring(result))
end
if not Fluent then
    BootLog("КРИТИЧЕСКАЯ ОШИБКА: Fluent не загружен | " .. tostring(loadErr))
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    BootLog("LocalPlayer ещё не появился, ожидаю...")
    local started = os.clock()
    repeat
        task.wait()
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer or os.clock() - started > 5
end
if not LocalPlayer then
    BootLog("КРИТИЧЕСКАЯ ОШИБКА: LocalPlayer не найден")
    return
end
local Camera = workspace.CurrentCamera
local ws = workspace
pcall(function() ws.StreamingTargetRadius = math.max(ws.StreamingTargetRadius, 100000) end)

local DEBUG_LOG = true
local function HLog(level, message, ...)
    if not DEBUG_LOG then return end
    local suffix = ""
    local ok, packed = pcall(function() return {...} end)
    if ok and #packed > 0 then
        local parts = {}
        for i, v in ipairs(packed) do parts[i] = tostring(v) end
        suffix = " | " .. table.concat(parts, " | ")
    end
    local line = "[Hiruku][" .. tostring(level) .. "] " .. tostring(message) .. suffix
    pcall(function()
        if level == "ERROR" and type(rconsoleerr) == "function" then rconsoleerr(line .. "\n")
        elseif type(rconsoleprint) == "function" then rconsoleprint(line .. "\n") end
    end)
    if level == "ERROR" then warn(line) else print(line) end
end

pcall(function()
    LogService.MessageOut:Connect(function(message, messageType)
        local mt = tostring(messageType)
        if mt:find("Error") or mt:find("MessageError") then
            HLog("ENGINE_ERROR", message)
        end
    end)
end)

pcall(function()
    ScriptContext.Error:Connect(function(message, trace, script)
        HLog("SCRIPT_ERROR", message, script and script:GetFullName() or "<unknown>")
        if trace and trace ~= "" then warn("[Hiruku][TRACE] " .. tostring(trace)) end
    end)
end)

local function Safe(label, fn, ...)
    local args = {...}
    local ok, a, b, c, d = xpcall(function() return fn(table.unpack(args)) end, debug.traceback)
    if not ok then
        HLog("ERROR", label, a)
        return false, a
    end
    return true, a, b, c, d
end

local function Notify(t, c, ty, i, d)
    pcall(function() Fluent:Notify({ Title = t, Content = c, Type = ty or "Info", Icon = i, Duration = d or 3 }) end)
end

local ANIME_BG = "rbxassetid://133541508207801"
local THEME = {
    Accent = Color3.fromRGB(150,35,235), AcrylicMain = Color3.fromRGB(15,6,28),
    AcrylicBorder = Color3.fromRGB(130,48,225),
    AcrylicGradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(32,13,58)), ColorSequenceKeypoint.new(.55, Color3.fromRGB(19,8,38)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10,4,20))}),
    AcrylicNoise = .6, TitleBarLine = Color3.fromRGB(190,85,255), Tab = Color3.fromRGB(27,11,48),
    Element = Color3.fromRGB(38,16,66), ElementBorder = Color3.fromRGB(100,36,180),
    InElementBorder = Color3.fromRGB(150,35,235), ElementTransparency = .86,
    ToggleSlider = Color3.fromRGB(46,22,78), ToggleToggled = Color3.fromRGB(190,85,255),
    SliderRail = Color3.fromRGB(46,22,78), Text = Color3.fromRGB(245,236,255),
    SubText = Color3.fromRGB(198,168,235), IconColor = Color3.fromRGB(226,190,255),
    Hover = Color3.fromRGB(48,21,84), HoverChange = .05, ShineEnabled = true,
    Shine = { Speed = .5, RotationSpeed = 24, ColorSequence = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(38,8,92)), ColorSequenceKeypoint.new(.5, Color3.fromRGB(255,60,196)), ColorSequenceKeypoint.new(1, Color3.fromRGB(38,8,92))})},
    StrokeShine = true, StrokeDark = Color3.fromRGB(70,20,135),
    ButtonGradient = { Background = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150,35,235)), ColorSequenceKeypoint.new(.5, Color3.fromRGB(110,22,195)), ColorSequenceKeypoint.new(1, Color3.fromRGB(48,10,105))}), Stroke = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150,35,235)), ColorSequenceKeypoint.new(.5, Color3.fromRGB(255,60,196)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150,35,235))}) }
}
THEME.Background = ANIME_BG
THEME.BackgroundTransparency = .12
THEME.ViewportBackgroundImages = true
THEME.DropdownOutsideWindowBackgroundImages = true
pcall(function() Fluent:RegisterCustomTheme("HirukuViolet", THEME) end)

local Window = Fluent:CreateWindow({
    Title = "Hiruku Lua — TSUM", SubTitle = "Resale Hunter v20", Version = "v20.1.0",
    TabWidth = 130, Size = UDim2.fromOffset(580,410), Acrylic = true,
    Theme = "HirukuViolet", MinimizeKey = Enum.KeyCode.LeftControl, Search = true,
    Icons = "solar/planet-bold", UserInfoTop = true, UserInfoTitle = "Welcome",
    UserInfoSubtitle = LocalPlayer.DisplayName, UserInfoColor = Color3.fromRGB(185,70,255),
})

local Tabs = {
    AutoBuy = Window:AddTab({ Title = "Auto Buy", Icon = "solar/cart-bold" }),
    HelpBuy = Window:AddTab({ Title = "Help Buy", Icon = "solar/lightbulb-bold" }),
    Chams = Window:AddTab({ Title = "Chams", Icon = "solar/eye-bold" }),
    FullSell = Window:AddTab({ Title = "Full-Sell", Icon = "solar/dollar-bold" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "solar/tuning-2-bold" }),
}

local RARITY_LIST = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exclusive", "ParisExclusive", "TokyoExclusive", "RickOwens", "RickOwensLegendary"}

local RARITY_COLORS = {
    Common = Color3.fromRGB(140, 140, 145),
    Uncommon = Color3.fromRGB(80, 200, 80),
    Rare = Color3.fromRGB(60, 140, 255),
    Epic = Color3.fromRGB(180, 70, 255),
    Legendary = Color3.fromRGB(255, 180, 30),
    Mythic = Color3.fromRGB(255, 80, 80),
    Exclusive = Color3.fromRGB(138, 43, 226),
    ParisExclusive = Color3.fromRGB(212, 175, 55),
    TokyoExclusive = Color3.fromRGB(255, 120, 180),
    RickOwens = Color3.fromRGB(200, 200, 200),
    RickOwensLegendary = Color3.fromRGB(220, 220, 220),
}


local function normalizeRarity(v)
    if v == nil then return nil end
    local s = tostring(v):gsub("%s+", "")
    local low = s:lower()
    for _, rarity in ipairs(RARITY_LIST) do
        if rarity:lower() == low then return rarity end
    end
    return tostring(v)
end

local function parseMoneyText(v)
    if v == nil then return nil end
    local s = tostring(v):gsub("%s", "")
    local raw = s:match("([%d][%d%.,]*)[₽$€]") or s:match("[₽$€]([%d][%d%.,]*)") or s:match("(%d[%d%.,]*)")
    if not raw then return nil end
    local digits = raw:gsub("[^%d]", "")
    if digits == "" then return nil end
    local n = tonumber(digits)
    if n and n >= 0 then return n end
    return nil
end
local function getItemShop(ref)
    local obj = ref
    while obj and obj ~= ws do
        if obj.Name:find("Shop_ShopZone") then
            local seller = obj:FindFirstChild("Seller", true)
            local hrp = seller and seller:FindFirstChild("HumanoidRootPart")
            if hrp then return obj, seller, hrp end
            return obj, nil, nil
        end
        obj = obj.Parent
    end
    return nil, nil, nil
end

local PROFILE_BIAS = {
    normal = 0, safe = -0.08, risky = 0.08, jackpot = -0.15, trap = 0.15,
}

local CATALOG = {}
local function indexCatalog(cfg)
    if not cfg then return 0 end
    local cnt = 0
    local function scan(node, depth)
        if type(node) ~= "table" or depth > 6 then return end
        if node.name and (node.fairPrice or node.value) then
            CATALOG[node.name:lower()] = {
                rarity = node.rarity,
                fairPrice = node.fairPrice or node.value,
                profile = node.economyProfile or "normal",
            }
            cnt = cnt + 1
            return
        end
        for _, c in pairs(node) do scan(c, depth + 1) end
    end
    scan(cfg, 0)
    return cnt
end

local cc = ReplicatedStorage:FindFirstChild("ClothingConfig")
if cc then
    local ok, cfg = pcall(require, cc)
    if ok then indexCatalog(cfg.SHOP_ITEMS or cfg) end
end

local Configs = ReplicatedStorage:FindFirstChild("Configs")
if Configs then
    for _, name in ipairs({"AccessoryConfig", "TokyoClothingConfig", "TokyoAccessoryConfig", "ParisClothingConfig", "ParisAccessoryConfig"}) do
        local mod = Configs:FindFirstChild(name) or ReplicatedStorage:FindFirstChild(name)
        if mod then
            local ok, cfg = pcall(require, mod)
            if ok then indexCatalog(cfg) end
        end
    end
end

local state = {
    chams = false, chamsRarity = "All", chamsTask = nil, chamsHighlights = {}, chamsProxies = {},
    helpBuy = false, helpBuyTask = nil, helpBuyHighlights = {}, helpBuyLabels = {},
    autoBuy = false, autoBuyRarity = "Legendary", autoBuyTask = nil,
    fullSell = false, fullSellTask = nil,
    walkSpeed = 30,
    slotData = {},
    remoteRecords = {}, balanceSource = nil, balanceLast = 0, balanceLastSource = "",
    walking = false, walkConn = nil, walkWaypoints = nil, walkWpIndex = 1,
    walkTarget = nil, walkStuck = 0, walkLastPos = nil, walkStart = 0,
}

local function getChar()
    local c = LocalPlayer.Character
    if not c then return nil end
    return c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

LocalPlayer.CharacterAdded:Connect(function()
    stopWalk()
    task.wait(0.5)
    local c = LocalPlayer.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = state.walkSpeed end
end)

local function getPos(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
        local h = obj:FindFirstChild("Handle")
        if h then return h.Position end
        local fb = obj:FindFirstChildWhichIsA("BasePart")
        if fb then return fb.Position end
    end
    return nil
end

local function getBalance()
    local candidates = {}
    local function add(value, score, source)
        local n = tonumber(value)
        if n and n >= 0 then candidates[#candidates + 1] = {value=n, score=score, source=source} end
    end
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, v in ipairs(pg:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                local t = tostring(v.Text or "")
                local n = parseMoneyText(t)
                if n ~= nil then
                    local name = v.Name:lower()
                    local parentName = v.Parent and v.Parent.Name:lower() or ""
                    local score = 5
                    if t:find("₽") then score = 10 end
                    if name:find("balance") or name:find("money") or name:find("cash") or name:find("wallet") then score = score + 5 end
                    if parentName:find("balance") or parentName:find("money") or parentName:find("cash") or parentName:find("wallet") then score = score + 3 end
                    add(n, score, v:GetFullName())
                end
            end
        end
    end
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                local n = v.Name:lower()
                if n:find("cash") or n:find("money") or n:find("balance") or n:find("rub") or n:find("wallet") then
                    add(v.Value, 7, v:GetFullName())
                end
            end
        end
    end
    for _, key in ipairs({"Balance","balance","Cash","cash","Money","money","Wallet","wallet","Currency","currency"}) do
        add(LocalPlayer:GetAttribute(key), 6, "Attribute:" .. key)
    end
    if #candidates == 0 and pg then
        for _, v in ipairs(pg:GetDescendants()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                local n = v.Name:lower()
                if n:find("cash") or n:find("money") or n:find("balance") or n:find("rub") or n:find("wallet") then
                    add(v.Value, 4, v:GetFullName())
                end
            end
        end
    end
    table.sort(candidates, function(a,b)
        if a.score == b.score then
            if a.source == state.balanceLastSource then return true end
            return a.value == state.balanceLast
        end
        return a.score > b.score
    end)
    local best = candidates[1]
    if best then
        state.balanceLast = best.value
        state.balanceLastSource = best.source
        state.balanceSource = best.source
        return best.value
    end
    return 0
end
local function ingestRemoteRecord(value, depth, sourceName)
    if depth > 7 or type(value) ~= "table" then return end
    local name = value.name or value.itemName or value.clothingName or value.title or value.Name
    local rarity = normalizeRarity(value.rarity or value.Rarity or value.itemRarity or value.ItemRarity or value.ItemType)
    local price = tonumber(value.price or value.Price or value.cost or value.Cost or value.buyPrice or value.BuyPrice)
    local fair = tonumber(value.fairPrice or value.FairPrice or value.value or value.Value or value.sellPrice or value.SellPrice)
    local pos = value.position or value.Position or value.location or value.Location or value.worldPosition
    if typeof(pos) ~= "Vector3" then
        if type(pos) == "table" and pos.X and pos.Y and pos.Z then pos = Vector3.new(pos.X,pos.Y,pos.Z) end
    end
    if name or rarity or price or fair or typeof(pos) == "Vector3" then
        local key = tostring(name or "?") .. "|" .. tostring(rarity or "?") .. "|" .. tostring(pos or "?")
        state.remoteRecords[key] = {name=name, rarity=rarity, price=price or 0, fairPrice=fair or 0, position=pos, source=sourceName, updated=tick()}
    end
    for _, child in pairs(value) do
        if type(child) == "table" then ingestRemoteRecord(child, depth + 1, sourceName) end
    end
end

local function ingestShopData(value)
    local seen = {}
    local function scan(node, depth)
        if depth > 5 or seen[node] then return end
        if type(node) ~= "table" then return end
        seen[node] = true
        local ref = node.slotRef or node.slot or node.itemRef or node.mannequin or node.model or node.instance
        if typeof(ref) == "Instance" then
            local name = node.name or node.itemName or node.clothingName or node.title
            local price = node.price or node.Price or node.cost or node.Cost or node.buyPrice or node.BuyPrice
            local rarity = normalizeRarity(node.rarity or node.Rarity or node.itemRarity or node.ItemRarity)
            local cat = name and CATALOG[tostring(name):lower()]
            rarity = rarity or (cat and normalizeRarity(cat.rarity))
            price = tonumber(price) or (cat and tonumber(cat.fairPrice)) or 0
            if rarity or name or price > 0 then
                local old = state.slotData[ref] or {}
                local man = ref:FindFirstChild("Mannequin", true)
                state.slotData[ref] = {
                    name = name or old.name, price = price > 0 and price or old.price or 0,
                    rarity = rarity or old.rarity, fairPrice = old.fairPrice or (cat and cat.fairPrice) or 0,
                    profile = old.profile or (cat and cat.profile) or "normal",
                    profit = (price > 0 and (tonumber(old.fairPrice or (cat and cat.fairPrice) or 0) or 0) > 0) and math.max(0, math.floor((tonumber(old.fairPrice or (cat and cat.fairPrice) or 0) or 0) * 0.98 - price)) or old.profit or 0, slotRef = ref,
                    position = (man and getPos(man)) or getPos(ref) or old.position,
                }
            end
        end
        for k, v in pairs(node) do
            if type(v) == "table" then scan(v, depth + 1) end
        end
    end
    if type(value) == "table" then scan(value, 0) end
end

local sr = ReplicatedStorage:FindFirstChild("ShopRemotes")
if sr then
    local siu = sr:FindFirstChild("SlotInfoUpdate")
    if siu and siu:IsA("RemoteEvent") then
        siu.OnClientEvent:Connect(ingestShopData)
    end
end

local function hookShopRemote(obj)
    if not obj:IsA("RemoteEvent") then return end
    local n = obj.Name:lower()
    local p = obj.Parent and obj.Parent.Name:lower() or ""
    if not (n:find("shop") or n:find("slot") or n:find("cloth") or n:find("item") or n:find("stock") or n:find("catalog") or n:find("mannequin") or n:find("product") or n:find("price") or p:find("shop") or p:find("cloth") or p:find("item")) then return end
    pcall(function() obj.OnClientEvent:Connect(function(...) for i = 1, select("#", ...) do local v=select(i,...); ingestShopData(v); ingestRemoteRecord(v,0,obj:GetFullName()) end end) end)
end
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do hookShopRemote(obj) end
ReplicatedStorage.DescendantAdded:Connect(function(obj) task.defer(function() hookShopRemote(obj) end) end)

local function stopWalk()
    state.walking = false
    state.walkWaypoints = nil
    if state.walkConn then state.walkConn:Disconnect() state.walkConn = nil end
    local c = LocalPlayer.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:MoveTo(hum.RootPart.Position) end) end
    end
end

local function buildPath(hrp, targetPos)
    local offsets = {Vector3.zero, Vector3.new(8,0,0), Vector3.new(-8,0,0), Vector3.new(0,0,8), Vector3.new(0,0,-8), Vector3.new(6,0,6), Vector3.new(-6,0,6), Vector3.new(6,0,-6), Vector3.new(-6,0,-6)}
    for _, offset in ipairs(offsets) do
        local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentMaxSlope = 45, WaypointSpacing = 4})
        local ok = pcall(function() path:ComputeAsync(hrp.Position, targetPos + offset) end)
        if ok and path.Status == Enum.PathStatus.Success then return path:GetWaypoints() end
    end
    return nil
end

local function walkTo(targetPos, onArrive, stopDist)
    stopDist = stopDist or 8
    stopWalk()

    local c = LocalPlayer.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    hum.WalkSpeed = state.walkSpeed
    state.walking = true
    state.walkTarget = targetPos
    state.walkLastPos = hrp.Position
    state.walkStuck = 0
    state.walkStart = tick()
    state.walkRecalc = 0
    state.walkCharacter = c

    state.walkWaypoints = buildPath(hrp, targetPos)
    state.walkWpIndex = 2

    local function issueMove(currentHrp, currentHum)
        if not state.walking or not currentHrp or not currentHum then return end
        local waypoints = state.walkWaypoints
        local wp = waypoints and waypoints[state.walkWpIndex]
        if wp then
            if wp.Action == Enum.PathWaypointAction.Jump then
                currentHum.Jump = true
            end
            currentHum:MoveTo(wp.Position)
        elseif (targetPos - currentHrp.Position).Magnitude <= 10 then
            currentHum:MoveTo(targetPos)
        end
    end

    issueMove(hrp, hum)

    state.walkConn = RunService.Heartbeat:Connect(function()
        if not state.walking then return end
        if tick() - state.walkStart > 60 then
            stopWalk()
            return
        end

        local currentChar = LocalPlayer.Character
        local currentHrp = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
        if not currentChar or not currentHrp or not currentHum then
            return
        end

        if state.walkCharacter ~= currentChar then
            state.walkCharacter = currentChar
            currentHum.WalkSpeed = state.walkSpeed
            state.walkLastPos = currentHrp.Position
            state.walkStuck = 0
            state.walkWaypoints = buildPath(currentHrp, targetPos)
            state.walkWpIndex = 2
            issueMove(currentHrp, currentHum)
            return
        end

        local curPos = currentHrp.Position
        local dist = (targetPos - curPos).Magnitude

        if dist < stopDist then
            stopWalk()
            if onArrive then task.spawn(onArrive) end
            return
        end

        local moved = (curPos - state.walkLastPos).Magnitude
        if moved < 0.05 then
            state.walkStuck = state.walkStuck + (1/60)
        else
            state.walkStuck = 0
        end
        state.walkLastPos = curPos

        if state.walkStuck > 5 then
            state.walkStuck = 0
            state.walkRecalc = (state.walkRecalc or 0) + 1
            if state.walkRecalc > 6 then
                state.walkRecalc = 0
            end
            state.walkWaypoints = buildPath(currentHrp, targetPos)
            state.walkWpIndex = 2
        end

        if state.walkWaypoints then
            local wp = state.walkWaypoints[state.walkWpIndex]
            if wp and (wp.Position - curPos).Magnitude < 5 then
                state.walkWpIndex = state.walkWpIndex + 1
            end
        end

        issueMove(currentHrp, currentHum)
    end)
end

local function clickDetector(cd)
    if cd then pcall(function() fireclickdetector(cd) end) end
end

local function clickGuiButton(btn)
    if not btn or not btn.Visible then return false end
    if not getconnections then return false end
    local ok, conns = pcall(getconnections, btn.Activated)
    if not ok or #conns == 0 then return false end
    for _, c in ipairs(conns) do
        if c.Fire then pcall(function() c:Fire() end) end
    end
    return true
end

local function findBariga()
    for _, obj in ipairs(ws:GetDescendants()) do
        if obj.Name == "BarigaNPC" then
            local pos = getPos(obj)
            if pos then return { obj = obj, pos = pos } end
        end
    end
    return nil
end

local function findBarigaPrompt()
    for _, obj in ipairs(ws:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Name == "BarigaPrompt" then
            return obj
        end
    end
    return nil
end

local function closeBariga()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end

    local barigaUI = pg:FindFirstChild("BarigaUI")
    if not barigaUI then return end

    local candidates = {
        barigaUI:FindFirstChild("CloseBariga", true),
        barigaUI:FindFirstChild("Close", true),
        barigaUI:FindFirstChild("Exit", true),
        barigaUI:FindFirstChild("Back", true),
    }

    for _, btn in ipairs(candidates) do
        if btn and btn:IsA("GuiButton") and btn.Visible then
            if clickGuiButton(btn) then
                task.wait(0.5)
                return
            end
        end
    end

    pcall(function()
        barigaUI.Enabled = false
    end)
end

local function sellAllToBariga(onDone)
    local br = ReplicatedStorage:FindFirstChild("BarigaRemotes")
    if not br then
        closeBariga()
        if onDone then onDone() end
        return
    end

    local prompt = findBarigaPrompt()
    if not prompt then
        closeBariga()
        if onDone then onDone() end
        return
    end

    pcall(function() fireproximityprompt(prompt) end)

    task.wait(2)
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local rGui = pg:FindFirstChild("BarigaResponseGui")
    if not rGui then
        closeBariga()
        if onDone then onDone() end
        return
    end

    local responses = rGui:FindFirstChild("Responses")
    local r1 = responses and responses:FindFirstChild("Response1")
    if r1 then clickGuiButton(r1) end

    task.wait(2)
    local barigaUI = pg:FindFirstChild("BarigaUI")
    if not barigaUI then
        closeBariga()
        if onDone then onDone() end
        return
    end

    task.wait(3)

    local seller = barigaUI:FindFirstChild("Seller")
    if seller then
        local actionFrame = seller:FindFirstChild("ActionFrame")
        if actionFrame then
            local accept = actionFrame:FindFirstChild("Accept")
            if accept then clickGuiButton(accept) end
        end
    end

    task.wait(2)

    local prompt2 = barigaUI:FindFirstChild("SellingPrompt")
    if prompt2 then
        local down = prompt2:FindFirstChild("Down")
        if down then
            local yes = down:FindFirstChild("Yes")
            if yes and yes.Visible then clickGuiButton(yes) end
        end
    end

    task.wait(5)
    closeBariga()
    task.wait(0.5)
    if onDone then onDone() end
end

local function getItemMannequin(ref)
    if not ref then return nil end
    local man = ref:FindFirstChild("Mannequin")
    if man then return man end
    return nil
end

local function getItemDetector(ref)
    local man = getItemMannequin(ref)
    if not man then return nil end
    local torso = man:FindFirstChild("Torso")
    if not torso then return nil end
    return torso:FindFirstChild("ClickDetector")
end

local function readBalanceStable()
    local last = nil
    local same = 0
    for _ = 1, 8 do
        local value = getBalance()
        if value and value > 0 then
            if last == value then
                same = same + 1
                if same >= 2 then return value end
            else
                last = value
                same = 0
            end
        end
        task.wait(0.35)
    end
    return last or 0
end

local function waitForBalanceDrop(before, expected)
    local deadline = tick() + 10
    local required = math.max(1, math.floor(expected * 0.98))
    local after = before
    while tick() < deadline do
        task.wait(0.5)
        after = getBalance()
        if after > 0 and before - after >= required then
            return true, after
        end
    end
    return false, after
end

local function pointInsideZone(zone, pos)
    if not zone or not pos then return false end
    local ok, cf, size = pcall(function() return zone:GetBoundingBox() end)
    if not ok then return true end
    local localPos = cf:PointToObjectSpace(pos)
    return math.abs(localPos.X) <= size.X/2 + 8 and math.abs(localPos.Y) <= size.Y/2 + 12 and math.abs(localPos.Z) <= size.Z/2 + 8
end

local function buyItemsList(itemsList, onDone)
    if #itemsList == 0 then Notify("Buy", "Список пуст", "Error", nil, 3); if onDone then onDone(false) end; return end
    local groups, order = {}, {}
    for _, item in ipairs(itemsList) do
        local price = tonumber(item.data and item.data.price) or 0
        local shop, seller, sellerRoot = getItemShop(item.ref)
        if price > 0 and shop then
            local group = groups[shop]
            if not group then group={shop=shop,seller=seller,sellerRoot=sellerRoot,items={}}; groups[shop]=group; order[#order+1]=group end
            group.items[#group.items+1]=item
        end
    end
    if #order == 0 then Notify("Buy", "Не удалось определить ShopZone", "Error", nil, 4); if onDone then onDone(false) end; return end
    local gi=1
    local function nextGroup()
        if gi>#order then if onDone then onDone(true) end; return end
        local group=order[gi]; gi+=1
        local expected=0
        for _,item in ipairs(group.items) do expected += tonumber(item.data.price) or 0 end
        local balance=readBalanceStable()
        if balance<=0 or balance<expected then
            Notify("Buy", balance<=0 and "Баланс не определён" or ("Недостаточно: "..math.floor(balance).." ₽ / нужно "..math.floor(expected).." ₽"), "Error", nil, 5)
            nextGroup(); return
        end
        local _, hrp= getChar()
        if not hrp then return end
        local zoneCF,zoneSize=group.shop:GetBoundingBox()
        local zoneCenter=zoneCF.Position
        local function ensureInside(cb)
            local _, r=getChar()
            if r and pointInsideZone(group.shop,r.Position) then cb(); return end
            walkTo(zoneCenter, cb, 6)
        end
        local idx=1
        local function nextItem()
            if idx>#group.items then
                ensureInside(function()
                    local _,r=getChar()
                    if not r or not pointInsideZone(group.shop,r.Position) then Notify("Buy","Не удалось остаться в ShopZone","Error",nil,5); return end
                    if not group.sellerRoot then
                        local seller=group.shop:FindFirstChild("Seller",true); group.seller=seller; group.sellerRoot=seller and seller:FindFirstChild("HumanoidRootPart")
                    end
                    if not group.sellerRoot then Notify("Buy","Продавец не найден в ShopZone","Error",nil,5); return end
                    walkTo(group.sellerRoot.Position,function()
                        local _,rr=getChar()
                        if not rr or not pointInsideZone(group.shop,rr.Position) then Notify("Buy","Вышли из ShopZone до оплаты","Error",nil,5); return end
                        local cd=group.seller and group.seller:FindFirstChild("ClickDetector",true)
                        if cd then clickDetector(cd) end
                        task.wait(1)
                        local cp=ReplicatedStorage:FindFirstChild("ShopRemotes") and ReplicatedStorage.ShopRemotes:FindFirstChild("ConfirmPurchase")
                        local before=readBalanceStable()
                        if before<expected then Notify("Buy","Баланс изменился до оплаты","Error",nil,5); return end
                        if not cp or not cp:IsA("RemoteEvent") then Notify("Buy","ConfirmPurchase не найден","Error",nil,5); return end
                        HLog("BUY","ConfirmPurchase", "expected="..expected, "before="..before, "shop="..group.shop:GetFullName())
                        local ok,err=pcall(function() cp:FireServer() end)
                        if not ok then HLog("ERROR","ConfirmPurchase",err); return end
                        local paid,after=waitForBalanceDrop(before,expected)
                        if not paid then Notify("Buy","Оплата не подтверждена","Error",nil,6); HLog("ERROR","PAYMENT_NOT_CONFIRMED",before,after,expected); return end
                        Notify("Buy","Оплачено "..math.floor(expected).." ₽ | остаток "..math.floor(after),"Success",nil,3)
                        task.wait(1); nextGroup()
                    end,5)
                end)
                return
            end
            ensureInside(function()
                local item=group.items[idx]; idx+=1
                if not item.pos or not pointInsideZone(group.shop,item.pos) then Notify("Buy","Пропуск предмета вне ShopZone","Error",nil,4); nextItem(); return end
                walkTo(item.pos,function()
                    local _,r=getChar()
                    if not r or not pointInsideZone(group.shop,r.Position) then ensureInside(nextItem); return end
                    if item.detector then clickDetector(item.detector) else Notify("Buy","ClickDetector отсутствует","Error",nil,4); return end
                    task.wait(.7); nextItem()
                end,5)
            end)
        end
        ensureInside(nextItem)
    end
    nextGroup()
end
local function clearTable(t)
    for k, v in pairs(t) do
        if typeof(v) == "Instance" then
            pcall(function() v.Adornee = nil v:Destroy() end)
        end
        t[k] = nil
    end
end

local function makeHL(obj, color, fill)
    local ok, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "HirukuHL"
        h.Adornee = obj
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = fill or 0.4
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = workspace
        return h
    end)
    return ok and hl or nil
end

local function makeChamsProxy(pos, color)
    if not pos then return nil end
    local ok, part, hl = pcall(function()
        local p = Instance.new("Part")
        p.Name = "HirukuChamsProxy"
        p.Size = Vector3.new(3, 5, 3)
        p.CFrame = CFrame.new(pos)
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Transparency = 0.82
        p.Material = Enum.Material.ForceField
        p.Color = color
        p.Parent = workspace
        local h = Instance.new("Highlight")
        h.Name = "HirukuProxyHL"
        h.Adornee = p
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.25
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = p
        return p, h
    end)
    if ok then return part, hl end
    return nil
end

local function countSlotsByRarity()
    local counts = {}
    for _, data in pairs(state.slotData) do
        local r = data.rarity or "nil"
        counts[r] = (counts[r] or 0) + 1
    end
    return counts
end

local function getLiveMannequins()
    local result = {}
    local seen = {}
    for _, obj in ipairs(ws:GetDescendants()) do
        if obj.Name == "Mannequin" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            local ref = obj.Parent
            local cached = ref and state.slotData[ref]
            local rarity = cached and cached.rarity
            local name = cached and cached.name
            local price = cached and cached.price
            if not rarity then rarity = normalizeRarity(obj:GetAttribute("Rarity") or obj:GetAttribute("rarity")) end
            name = name or obj:GetAttribute("ItemName") or obj:GetAttribute("Name")
            price = price or obj:GetAttribute("Price") or obj:GetAttribute("price")
            if not rarity and name then
                local cat = CATALOG[tostring(name):lower()]
                rarity = cat and normalizeRarity(cat.rarity)
                price = price or (cat and cat.fairPrice)
            end
            if not rarity then
                local text = obj:GetAttribute("ItemType") or obj:GetAttribute("Type")
                rarity = normalizeRarity(text)
            end
            if rarity and not seen[obj] then
                seen[obj] = true
                local shop = getItemShop(ref)
                local livePrice = tonumber(price) or 0
                local fair = cached and cached.fairPrice or 0
                local profit = cached and cached.profit or 0
                if livePrice > 0 and fair > 0 then profit = math.floor(fair * 0.98 - livePrice) end
                result[#result + 1] = {mannequin = obj, ref = ref, rarity = rarity, name = name, price = livePrice, profit = profit, data = cached, shop = shop}
            end
        end
    end
    for ref, data in pairs(state.slotData) do
        local man = getItemMannequin(ref)
        if man and man.Parent and not seen[man] then
            seen[man] = true
            result[#result + 1] = {mannequin = man, ref = ref, rarity = normalizeRarity(data.rarity), name = data.name, price = tonumber(data.price) or 0, profit = data.profit or 0, data = data, shop = getItemShop(ref)}
        end
    end
    for _, tag in ipairs(CollectionService:GetAllTags()) do
        local low=tag:lower()
        if low:find("mannequin") or low:find("clothing") or low:find("shop") or low:find("item") then
            for _,obj in ipairs(CollectionService:GetTagged(tag)) do
                local pos=getPos(obj)
                local name=obj:GetAttribute("ItemName") or obj:GetAttribute("Name") or obj.Name
                local rarity=normalizeRarity(obj:GetAttribute("Rarity") or obj:GetAttribute("rarity") or obj:GetAttribute("ItemRarity"))
                local price=tonumber(obj:GetAttribute("Price") or obj:GetAttribute("price")) or 0
                local cat=name and CATALOG[tostring(name):lower()]
                rarity=rarity or (cat and normalizeRarity(cat.rarity))
                price=price>0 and price or (cat and tonumber(cat.fairPrice) or 0)
                if pos and rarity then result[#result+1]={mannequin=obj:IsA("Model") and obj or nil,ref=obj,rarity=rarity,name=name,price=price,profit=0,data=nil,shop=getItemShop(obj),position=pos,tagged=true} end
            end
        end
    end
    for _, rec in pairs(state.remoteRecords) do
        if rec.position and rec.rarity then
            local selected = state.chamsRarity == "All" or normalizeRarity(state.chamsRarity) == normalizeRarity(rec.rarity)
            if selected then
                result[#result+1] = {mannequin=nil, ref=nil, rarity=normalizeRarity(rec.rarity), name=rec.name, price=rec.price or 0, profit=((rec.fairPrice or 0)>0 and (rec.price or 0)>0) and math.max(0,math.floor(rec.fairPrice*0.98-rec.price)) or 0, data=nil, shop=nil, position=rec.position, remote=true}
            end
        end
    end
    return result
end

local function updateChams()
    clearTable(state.chamsHighlights)
    for key, proxy in pairs(state.chamsProxies) do pcall(function() proxy:Destroy() end); state.chamsProxies[key]=nil end
    if not state.chams then return 0 end
    local cnt=0; local liveRefs={}
    for _,item in ipairs(getLiveMannequins()) do
        local rarity=normalizeRarity(item.rarity)
        local selected=state.chamsRarity=="All" or normalizeRarity(state.chamsRarity)==rarity
        local color=RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255)
        if selected and item.mannequin and item.mannequin.Parent then
            liveRefs[item.ref]=true
            local hl=makeHL(item.mannequin,color,.4)
            if hl then state.chamsHighlights[item.mannequin]=hl; cnt+=1 end
        elseif selected and item.position then
            local key="remote:"..tostring(item.name)..":"..tostring(item.position)
            local proxy=makeChamsProxy(item.position,color)
            if proxy then state.chamsProxies[key]=proxy; cnt+=1 end
        end
    end
    for ref,data in pairs(state.slotData) do
        if not liveRefs[ref] and data.position and data.rarity then
            local rarity=normalizeRarity(data.rarity)
            if state.chamsRarity=="All" or normalizeRarity(state.chamsRarity)==rarity then
                local proxy=makeChamsProxy(data.position,RARITY_COLORS[rarity] or Color3.fromRGB(255,255,255))
                if proxy then state.chamsProxies[ref]=proxy; cnt+=1 end
            end
        end
    end
    return cnt
end
local function startChams()
    if state.chams then return end
    state.chams = true
    local cnt = updateChams() or 0
    local total = 0
    for _ in pairs(state.slotData) do total = total + 1 end
    
    if cnt == 0 then
        local counts = countSlotsByRarity()
        local line = ""
        for r, c in pairs(counts) do
            line = line .. r .. ":" .. c .. " "
        end
        Notify("Chams", "0 из " .. state.chamsRarity .. " | В кэше: " .. (line ~= "" and line or "пусто"), "Info", nil, 5)
    else
        Notify("Chams", state.chamsRarity .. " × " .. cnt, "Success", nil, 3)
    end
    
    state.chamsTask = task.spawn(function()
        while state.chams do
            task.wait(1)
            if state.chams then updateChams() end
        end
    end)
end

local function stopChams()
    state.chams = false
    if state.chamsTask then pcall(function() task.cancel(state.chamsTask) end) end
    clearTable(state.chamsHighlights)
    for key, proxy in pairs(state.chamsProxies) do
        pcall(function() proxy:Destroy() end)
        state.chamsProxies[key] = nil
    end
    Notify("Chams", "Выключен", "Info", nil, 2)
end

local function makeBillboard(part, text, color)
    if not part then return nil end
    local ok, bb = pcall(function()
        local b = Instance.new("BillboardGui")
        b.Name = "HirukuLabel"
        b.Size = UDim2.new(0, 240, 0, 32)
        b.StudsOffset = Vector3.new(0, 4, 0)
        b.AlwaysOnTop = true
        b.LightInfluence = 0
        b.MaxDistance = math.huge
        b.Parent = part
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color
        lbl.TextStrokeTransparency = 0
        lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
        lbl.Parent = b
        return b
    end)
    return ok and bb or nil
end

local function updateHelpBuy()
    clearTable(state.helpBuyHighlights)
    for _,l in pairs(state.helpBuyLabels) do pcall(function() l:Destroy() end) end
    state.helpBuyLabels={}
    if not state.helpBuy then return end
    local _,playerHrp=getChar(); if not playerHrp then return end
    local cnt=0
    for _,item in ipairs(getLiveMannequins()) do
        local man=item.mannequin; local pos=item.position or (man and getPos(man))
        if man and man.Parent and pos and (pos-playerHrp.Position).Magnitude<=20 then
            local price=tonumber(item.price) or 0
            local fair=tonumber(item.data and item.data.fairPrice) or 0
            if fair<=0 then
                local cat=item.name and CATALOG[tostring(item.name):lower()]; fair=cat and tonumber(cat.fairPrice) or 0
            end
            local profit=tonumber(item.profit) or ((fair>0 and price>0) and math.floor(fair*.98-price) or 0)
            if profit>0 then
                cnt+=1
                local color=profit>=4000 and Color3.fromRGB(255,70,70) or profit>=1500 and Color3.fromRGB(255,170,40) or Color3.fromRGB(70,230,120)
                local hl=makeHL(man,color,.85); if hl then state.helpBuyHighlights[cnt]=hl end
                local roi=price>0 and math.floor(profit/price*100) or 0
                local text="["..tostring(item.rarity or "?").."] "..math.floor(price).." ₽ → +"..math.floor(profit).." ₽ ("..roi.."%)"
                local bb=makeBillboard(man,text,color); if bb then state.helpBuyLabels[cnt]=bb end
            end
        end
    end
end
local function startHelpBuy()
    if state.helpBuy then return end
    state.helpBuy = true
    updateHelpBuy()
    state.helpBuyTask = task.spawn(function()
        while state.helpBuy do
            task.wait(2)
            if state.helpBuy then updateHelpBuy() end
        end
    end)
    Notify("Help Buy", "Подсветка профита", "Success", nil, 3)
end

local function stopHelpBuy()
    state.helpBuy = false
    if state.helpBuyTask then pcall(function() task.cancel(state.helpBuyTask) end) end
    clearTable(state.helpBuyHighlights)
    for _, l in pairs(state.helpBuyLabels) do pcall(function() l:Destroy() end) end
    state.helpBuyLabels = {}
    Notify("Help Buy", "Выключен", "Info", nil, 2)
end

local function getMannequinsByRarity(rarity)
    local list = {}
    for _, item in ipairs(getLiveMannequins()) do
        local man = item.mannequin
        local ref = item.ref
        if normalizeRarity(item.rarity) == normalizeRarity(rarity) and man and man.Parent and (tonumber(item.price) or 0) > 0 then
            local pos = getPos(man)
            local cd = ref and getItemDetector(ref)
            if pos and cd then
                local data = item.data or {
                    name = item.name,
                    price = item.price,
                    rarity = item.rarity,
                    profit = item.profit,
                    slotRef = ref,
                }
                table.insert(list, { pos = pos, detector = cd, data = data, ref = ref, mannequin = man })
            end
        end
    end
    return list
end

local function getAllItems()
    local list = {}
    for _, item in ipairs(getLiveMannequins()) do
        local man = item.mannequin
        local ref = item.ref
        if man and man.Parent and (item.profit or 0) > 0 and (tonumber(item.price) or 0) > 0 then
            local pos = getPos(man)
            local cd = ref and getItemDetector(ref)
            if pos and cd then
                local data = item.data or {
                    name = item.name,
                    price = item.price,
                    rarity = item.rarity,
                    profit = item.profit,
                    slotRef = ref,
                }
                table.insert(list, { pos = pos, detector = cd, data = data, ref = ref, mannequin = man })
            end
        end
    end
    return list
end

local function autoBuyLoop()
    while state.autoBuy do
        task.wait(2)
        if not state.autoBuy then break end
        
        local _, hrp = getChar()
        if not hrp then continue end
        
        local targets = getMannequinsByRarity(state.autoBuyRarity)
        
        if #targets == 0 then
            local counts = countSlotsByRarity()
            local has = false
            for r, c in pairs(counts) do
                if r == state.autoBuyRarity then has = true break end
            end
            if not has then
                Notify("Auto Buy", "Нет доступных " .. state.autoBuyRarity, "Error", nil, 3)
                task.wait(3)
            end
            continue 
        end
        
        Notify("Auto Buy", "Целей " .. #targets, "Info", nil, 2)
        
        table.sort(targets, function(a, b) return (a.data.profit or 0) > (b.data.profit or 0) end)
        
        local balance = getBalance()
        local spent = 0
        local toBuy = {}
        for _, t in ipairs(targets) do
            if spent + (t.data.price or 0) > balance then break end
            spent = spent + (t.data.price or 0)
            table.insert(toBuy, t)
        end
        
        if #toBuy > 0 then
            buyItemsList(toBuy, function()
                local bariga = findBariga()
                if bariga then
                    walkTo(bariga.pos, function()
                        sellAllToBariga()
                    end, 10)
                else
                    Notify("Bariga", "Не найден", "Error", nil, 3)
                end
            end)
        end
        
        while state.autoBuy and state.walking do task.wait(0.5) end
        task.wait(5)
    end
end

local function startAutoBuy()
    if state.autoBuy then return end
    state.autoBuy = true
    state.autoBuyTask = task.spawn(autoBuyLoop)
    Notify("Auto Buy", state.autoBuyRarity, "Success", nil, 3)
end

local function stopAutoBuy()
    state.autoBuy = false
    if state.autoBuyTask then pcall(function() task.cancel(state.autoBuyTask) end) end
    stopWalk()
    Notify("Auto Buy", "Выключен", "Info", nil, 2)
end

local function fullSellLoop()
    while state.fullSell do
        task.wait(3)
        if not state.fullSell then break end
        
        local _, hrp = getChar()
        if not hrp then continue end
        
        local targets = getAllItems()
        
        if #targets == 0 then
            Notify("Full-Sell", "Нет доступных прибыльных предметов", "Info", nil, 2)
            task.wait(3)
            continue 
        end
        
        Notify("Full-Sell", "Целей " .. #targets, "Info", nil, 2)
        table.sort(targets, function(a, b) return (a.data.profit or 0) > (b.data.profit or 0) end)
        
        local balance = getBalance()
        local spent = 0
        local toBuy = {}
        for _, t in ipairs(targets) do
            if spent + (t.data.price or 0) > balance then break end
            spent = spent + (t.data.price or 0)
            table.insert(toBuy, t)
        end
        
        if #toBuy > 0 then
            buyItemsList(toBuy, function()
                local bariga = findBariga()
                if bariga then
                    walkTo(bariga.pos, function()
                        sellAllToBariga()
                    end, 10)
                else
                    Notify("Bariga", "Не найден", "Error", nil, 3)
                end
            end)
        end
        
        while state.fullSell and state.walking do task.wait(0.5) end
        task.wait(5)
    end
end

local function startFullSell()
    if state.fullSell then return end
    state.fullSell = true
    state.fullSellTask = task.spawn(fullSellLoop)
    Notify("Full-Sell", "Включён", "Success", nil, 3)
end

local function stopFullSell()
    state.fullSell = false
    if state.fullSellTask then pcall(function() task.cancel(state.fullSellTask) end) end
    stopWalk()
    Notify("Full-Sell", "Выключен", "Info", nil, 2)
end

local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "HirukuOpenUi"
toggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toggleGui.ResetOnSpawn = false

local mainBtn = Instance.new("TextButton")
mainBtn.Name = "HirukuButton"
mainBtn.Parent = toggleGui
mainBtn.BackgroundColor3 = Color3.fromRGB(20,10,35)
mainBtn.BackgroundTransparency = 0.05
mainBtn.AnchorPoint = Vector2.new(0.5, 0.5)
mainBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
mainBtn.Size = UDim2.new(0, 60, 0, 60)
mainBtn.Text = "HL"
mainBtn.TextColor3 = Color3.fromRGB(230,190,255)
mainBtn.TextSize = 24
mainBtn.Font = Enum.Font.GothamBold
mainBtn.AutoButtonColor = false
mainBtn.ClipsDescendants = true

local corner = Instance.new("UICorner", mainBtn)
corner.CornerRadius = UDim.new(0.25, 0)
local stroke = Instance.new("UIStroke", mainBtn)
stroke.Color = Color3.fromRGB(190,85,255)
stroke.Thickness = 2
local grad = Instance.new("UIGradient", mainBtn)
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60,20,110)),
    ColorSequenceKeypoint.new(.5, Color3.fromRGB(150,35,235)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(48,10,105))
})
grad.Rotation = 45
RunService.RenderStepped:Connect(function(dt)
    if grad and grad.Parent then grad.Rotation = (grad.Rotation + dt * 30) % 360 end
end)

local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
mainBtn.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = true
    dragStart = input.Position
    startPos = mainBtn.Position
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false end
    end)
end)
mainBtn.InputChanged:Connect(function(input)
    if not dragStart then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local uiOpen = true
mainBtn.MouseButton1Click:Connect(function()
    uiOpen = not uiOpen
    if uiOpen then pcall(function() Window:Show() end)
    else pcall(function() Window:Hide() end) end
end)

local secAB = Tabs.AutoBuy:AddSection("Auto Buy", "solar/cart-bold")
secAB:AddDropdown("ABRarity", {
    Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "Legendary", Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do state.autoBuyRarity = k break end
        else state.autoBuyRarity = v end
    end
})
secAB:AddToggle("ABToggle", {
    Title = "Auto Buy", Description = "Скупает выбранную редкость на весь баланс → Барыга",
    Icon = "solar/cart-bold", Default = false,
    Callback = function(v) if v then startAutoBuy() else stopAutoBuy() end end
})

local secHB = Tabs.HelpBuy:AddSection("Help Buy", "solar/lightbulb-bold")
secHB:AddToggle("HBToggle", {
    Title = "Help Buy", Description = "Подсвечивает профит через стены",
    Icon = "solar/lightbulb-bold", Default = false,
    Callback = function(v) if v then startHelpBuy() else stopHelpBuy() end end
})

local secCH = Tabs.Chams:AddSection("Chams", "solar/eye-bold")
secCH:AddDropdown("CHRarity", {
    Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "All", Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do state.chamsRarity = k break end
        else state.chamsRarity = v end
        if state.chams then updateChams() end
    end
})
secCH:AddToggle("CHToggle", {
    Title = "Chams", Description = "Подсветка через стены (цвет = редкость)",
    Icon = "solar/eye-bold", Default = false,
    Callback = function(v) if v then startChams() else stopChams() end end
})

local secFS = Tabs.FullSell:AddSection("Auto Full-Sell", "solar/dollar-bold")
secFS:AddToggle("FSToggle", {
    Title = "Auto Full-Sell", Description = "Скупает всё прибыльное на весь баланс → Барыга",
    Icon = "solar/dollar-bold", Default = false,
    Callback = function(v) if v then startFullSell() else stopFullSell() end end
})

local secSET = Tabs.Settings:AddSection("Настройки", "solar/tuning-2-bold")

secSET:AddSlider("WalkSpeed", {
    Title = "Walk Speed", Icon = "solar/running-bold",
    Min = 16, Max = 80, Default = 30, Rounding = 0,
    Callback = function(v) state.walkSpeed = v end
})

secSET:AddButton({
    Title = "Редкости в кэше", Description = "Покажет какие редкости сейчас в кэше",
    Icon = "solar/list-bold",
    Callback = function()
        local counts = countSlotsByRarity()
        local line = ""
        for r, c in pairs(counts) do
            line = line .. r .. ":" .. c .. "  "
        end
        if line == "" then line = "пусто" end
        Notify("Кэш", line, "Info", nil, 6)
    end
})

secSET:AddButton({
    Title = "Очистить кэш", Description = "Сбросить сохранённые данные о слотах",
    Icon = "solar/trash-bin-bold",
    Callback = function()
        state.slotData = {}
        Notify("Кэш", "Очищен", "Info", nil, 2)
    end
})

secSET:AddButton({
    Title = "Показать баланс", Icon = "solar/wallet-bold",
    Callback = function()
        local b = getBalance()
        Notify("Баланс", tostring(math.floor(b)) .. " ₽ | " .. tostring(state.balanceLastSource), "Info", nil, 5)
        HLog("BALANCE", b, state.balanceLastSource)
    end
})

secSET:AddButton({
    Title = "Диагностика", Icon = "solar/bug-bold",
    Callback = function()
        HLog("DIAG", "balance", getBalance(), "source", state.balanceLastSource, "slotData", #state.slotData)
        for _,obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") and (obj.Name:lower():find("shop") or obj.Name:lower():find("cloth") or obj.Name:lower():find("item") or obj.Name:lower():find("catalog") or obj.Name:lower():find("price")) then HLog("REMOTE", obj:GetFullName()) end
        end
        Notify("Диагностика", "Данные отправлены в консоль Delta", "Success", nil, 3)
    end
})

secSET:AddButton({
    Title = "Найти Барыгу", Icon = "solar/map-point-bold",
    Callback = function()
        local b = findBariga()
        if b then Notify("Bariga", "Найден", "Success", nil, 3)
        else Notify("Bariga", "Не найден", "Error", nil, 3) end
    end
})

Fluent:SetTheme("HirukuViolet")
Notify("Hiruku Lua — TSUM", "v20.1 загружен", "Success", "solar/planet-bold", 4)
task.delay(0.5, function() pcall(function() Window:SelectTab(1) end) end)