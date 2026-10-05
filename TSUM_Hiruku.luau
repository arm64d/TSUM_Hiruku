-- ============================================================
-- HIRUKU v17 FINAL — данные через SlotInfoUpdate
-- ============================================================

local Fluent
pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-modded/releases/download/1.5.1/FluentPro"))()
end)
if not Fluent then return warn("[Hiruku] Fluent не загрузился") end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ws = workspace

-- ЛОГ
local logLines = {}
local MAX_LOG = 8000
local function fileLog(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. table.concat(parts, " ")
    table.insert(logLines, line)
    if #logLines > MAX_LOG then table.remove(logLines, 1) end
end
local function log(...)
    print("[Hiruku]", ...)
    fileLog(...)
end
local function Notify(t, c, ty, i, d)
    pcall(function() Fluent:Notify({ Title = t, Content = c, Type = ty or "Info", Icon = i, Duration = d or 3 }) end)
end

-- ТЕМА
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
    Title = "Hiruku Lua — TSUM", SubTitle = "Resale Hunter v17", Version = "v17.0.0",
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

-- КОНСТАНТЫ
local RARITY_LIST = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exclusive", "ParisExclusive", "TokyoExclusive", "RickOwens", "RickOwensLegendary"}

-- ЗОЛОТОЙ для Legendary
local RARITY_COLORS = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(100, 200, 100),
    Rare = Color3.fromRGB(100, 150, 255),
    Epic = Color3.fromRGB(180, 100, 255),
    Legendary = Color3.fromRGB(255, 215, 0),   -- ЗОЛОТОЙ
    Mythic = Color3.fromRGB(255, 80, 80),
    Exclusive = Color3.fromRGB(255, 215, 0),
    ParisExclusive = Color3.fromRGB(200, 150, 255),
    TokyoExclusive = Color3.fromRGB(255, 120, 180),
    RickOwens = Color3.fromRGB(200, 200, 220),
    RickOwensLegendary = Color3.fromRGB(255, 100, 200),
}

-- Профиль → bias
local PROFILE_BIAS = {
    normal = 0,
    safe = -0.08,
    risky = 0.08,
    jackpot = -0.15,
    trap = 0.15,
}

local state = {
    chams = false, chamsRarity = "Legendary", chamsTask = nil, chamsHighlights = {},
    helpBuy = false, helpBuyTask = nil, helpBuyHighlights = {}, helpBuyLabels = {},
    autoBuy = false, autoBuyRarity = "Legendary", autoBuyTask = nil,
    fullSell = false, fullSellTask = nil,
    autoWalk = false, autoWalkConn = nil, autoWalkTarget = nil,
    currentWaypoints = nil, currentWaypointIndex = 1,
    walkStuckFrames = 0, lastWalkPos = nil,
    slotData = {},          -- slotRef → {name, rarity, price, itemConfig, profit}
    cartUids = {},
    itemByName = {},        -- name → {fairPrice, economyProfile}
}

-- ============================================================
-- УТИЛИТЫ
-- ============================================================
local function getChar()
    local c = LocalPlayer.Character
    if not c then return nil end
    return c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

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

-- ============================================================
-- КОНФИГИ — загружаем имена и цены
-- ============================================================
local function loadItemConfig()
    local items = {}
    
    -- ClothingConfig
    pcall(function()
        local mod = ReplicatedStorage:FindFirstChild("ClothingConfig")
        if not mod then return end
        local ok, cfg = pcall(require, mod)
        if not ok then return end
        local shopItems = cfg.SHOP_ITEMS or cfg
        local function scan(node, depth)
            if type(node) ~= "table" or depth > 6 then return end
            if node.name and (node.fairPrice or node.value) then
                items[node.name:lower()] = {
                    fairPrice = node.fairPrice or node.value,
                    profile = node.economyProfile or "normal",
                }
                return
            end
            for _, c in pairs(node) do scan(c, depth + 1) end
        end
        scan(shopItems, 0)
    end)
    
    -- AccessoryConfig
    pcall(function()
        local Configs = ReplicatedStorage:FindFirstChild("Configs")
        local mod = Configs and Configs:FindFirstChild("AccessoryConfig")
        if not mod then return end
        local ok, cfg = pcall(require, mod)
        if not ok then return end
        local function scan(node, depth)
            if type(node) ~= "table" or depth > 6 then return end
            if node.name and (node.fairPrice or node.value) then
                items[node.name:lower()] = {
                    fairPrice = node.fairPrice or node.value,
                    profile = node.economyProfile or "normal",
                }
                return
            end
            for _, c in pairs(node) do scan(c, depth + 1) end
        end
        scan(cfg, 0)
    end)
    
    state.itemByName = items
    local c = 0
    for _ in pairs(items) do c = c + 1 end
    log("Config: " .. c .. " предметов")
end

loadItemConfig()

-- ============================================================
-- SLOT INFO UPDATE — главный источник
-- ============================================================
local sr = ReplicatedStorage:FindFirstChild("ShopRemotes")
local removeFromCart = sr and sr:FindFirstChild("RemoveFromCart")

if sr then
    local siu = sr:FindFirstChild("SlotInfoUpdate")
    if siu then
        siu.OnClientEvent:Connect(function(arg)
            if type(arg) ~= "table" then return end
            local slots = arg.slots
            if type(slots) ~= "table" then return end
            
            for _, slot in ipairs(slots) do
                if type(slot) == "table" and slot.slotRef then
                    local key = typeof(slot.slotRef) == "Instance" and slot.slotRef or tostring(slot.slotRef)
                    
                    local cfg = state.itemByName[(slot.name or ""):lower()]
                    local fairPrice = cfg and cfg.fairPrice or 0
                    local profile = cfg and cfg.profile or "normal"
                    local bias = PROFILE_BIAS[profile] or 0
                    local shopPrice = slot.price or 0
                    
                    -- профит = fairPrice * 0.98 - shopPrice * (1 + bias)
                    local barigaOffer = fairPrice * 0.98
                    local actualCost = math.floor(shopPrice * (1 + bias))
                    local profit = math.floor(barigaOffer - actualCost)
                    
                    state.slotData[key] = {
                        name = slot.name,
                        rarity = slot.rarity,
                        price = shopPrice,
                        slotId = slot.slotId,
                        visualRef = slot.visualRef,
                        slotRef = slot.slotRef,
                        fairPrice = fairPrice,
                        profit = profit,
                        configFound = cfg ~= nil,
                    }
                end
            end
            
            log("SlotInfoUpdate: " .. #slots .. " слотов, кэш: " .. (function() local c=0 for _ in pairs(state.slotData) do c=c+1 end return c end)())
        end)
    end
    
    local sic = sr:FindFirstChild("SlotInfoClear")
    if sic then
        sic.OnClientEvent:Connect(function()
            state.slotData = {}
            log("SlotInfoClear — кэш очищен")
        end)
    end
    
    local cu = sr:FindFirstChild("CartUpdated")
    if cu then
        cu.OnClientEvent:Connect(function(...)
            state.cartUids = {}
            for _, a in ipairs({...}) do
                if type(a) == "table" then
                    for k, v in pairs(a) do
                        if type(v) == "string" and #v > 20 then
                            table.insert(state.cartUids, v)
                        end
                    end
                end
            end
        end)
    end
end

-- ============================================================
-- PATHFINDING
-- ============================================================
local lastStuckLog = 0
local function forceWalk(hum, hrp, targetPos)
    if not hum or not hrp or not targetPos then return end
    if hum.WalkSpeed < 16 then hum.WalkSpeed = 24 end
    hum:MoveTo(targetPos)
end

local function pathfindTo(targetPos, onArrive, stopDist)
    stopDist = stopDist or 8
    state.autoWalk = true
    state.autoWalkTarget = targetPos
    state.walkStuckFrames = 0
    state.lastWalkPos = nil
    state.currentWaypoints = nil
    state.currentWaypointIndex = 1
    if state.autoWalkConn then state.autoWalkConn:Disconnect() end
    local fc = 0
    state.autoWalkConn = RunService.Heartbeat:Connect(function()
        if not state.autoWalk then return end
        local c = LocalPlayer.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        local target = state.autoWalkTarget
        if not target then state.autoWalk = false return end
        local dist = (target - hrp.Position).Magnitude
        if dist < stopDist then
            state.autoWalk = false
            if state.autoWalkConn then state.autoWalkConn:Disconnect() state.autoWalkConn = nil end
            if onArrive then onArrive() end
            return
        end
        fc = fc + 1
        if fc % 90 == 0 or not state.currentWaypoints then
            pcall(function()
                local path = PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 5, AgentCanJump = true })
                path:ComputeAsync(hrp.Position, target)
                if path.Status == Enum.PathStatus.Success then
                    state.currentWaypoints = path:GetWaypoints()
                    state.currentWaypointIndex = 1
                else
                    state.currentWaypoints = nil
                end
            end)
        end
        if state.currentWaypoints and #state.currentWaypoints > 0 then
            local tw = nil
            for i = state.currentWaypointIndex, #state.currentWaypoints do
                local wp = state.currentWaypoints[i]
                if (wp.Position - hrp.Position).Magnitude > 2.5 then
                    tw = wp
                    state.currentWaypointIndex = i
                    break
                end
            end
            if tw then
                if tw.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                forceWalk(hum, hrp, tw.Position + Vector3.new(0, 2, 0))
            else
                forceWalk(hum, hrp, target + Vector3.new(0, 2, 0))
            end
        else
            forceWalk(hum, hrp, target + Vector3.new(0, 2, 0))
        end
    end)
end

local function stopAutoWalk()
    state.autoWalk = false
    state.autoWalkTarget = nil
    state.currentWaypoints = nil
    if state.autoWalkConn then state.autoWalkConn:Disconnect() state.autoWalkConn = nil end
end

-- ============================================================
-- КЛИКИ
-- ============================================================
local function clickDetector(cd)
    if cd then pcall(function() fireclickdetector(cd) end) end
end

local function confirmPurchase()
    if sr then
        local cp = sr:FindFirstChild("ConfirmPurchase")
        if cp then pcall(function() cp:FireServer() end) end
    end
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

local function findSellerNear(pos)
    local best, bestDist = nil, math.huge
    for _, zone in ipairs(ws:GetChildren()) do
        if zone.Name:find("Shop_ShopZone") then
            local seller = zone:FindFirstChild("Seller")
            if seller then
                local hrp = seller:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local cd = hrp:FindFirstChild("ClickDetector")
                    local d = (hrp.Position - pos).Magnitude
                    if d < bestDist then
                        best, bestDist = { pos = hrp.Position, cd = cd }, d
                    end
                end
            end
        end
    end
    return best
end

local function sellAllToBariga()
    local br = ReplicatedStorage:FindFirstChild("BarigaRemotes")
    if not br then return end
    local tr = br:FindFirstChild("TriggerBariga")
    if tr then pcall(function() tr:FireServer() end) end
    task.wait(0.7)
    local inv = br:FindFirstChild("GetBarigaInventory")
    if inv then
        local ok, res = pcall(function() return inv:InvokeServer() end)
        if ok and type(res) == "table" then
            local uids = {}
            for _, it in pairs(res) do
                if type(it) == "table" and it.uid then table.insert(uids, it.uid) end
            end
            if #uids > 0 then
                local cf = br:FindFirstChild("ConfirmBarigaSale")
                if cf then
                    pcall(function() cf:FireServer(uids) end)
                    log("Продажа Барыге:", #uids)
                end
            end
        end
    end
    task.wait(0.4)
    local cl = br:FindFirstChild("CloseBariga")
    if cl then pcall(function() cl:FireServer() end) end
end

-- ============================================================
-- HIGHLIGHT / BILLBOARD
-- ============================================================
local function makeHL(obj, color, fill, outline)
    local ok, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "HirukuHL"
        h.Adornee = obj
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = fill or 0.5
        h.OutlineTransparency = outline or 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = obj
        return h
    end)
    return ok and hl or nil
end

local function clearTable(t)
    for k, v in pairs(t) do
        if typeof(v) == "Instance" then
            pcall(function() v.Adornee = nil v:Destroy() end)
        end
        t[k] = nil
    end
end

local function makeBillboard(part, text, color)
    if not part then return nil end
    local ok, bb = pcall(function()
        local b = Instance.new("BillboardGui")
        b.Name = "HirukuLabel"
        b.Size = UDim2.new(0, 240, 0, 32)
        b.StudsOffset = Vector3.new(0, 3.2, 0)
        b.AlwaysOnTop = true
        b.LightInfluence = 0
        b.MaxDistance = 1000
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

-- ============================================================
-- 1. CHAMS
-- ============================================================
local function updateChams()
    clearTable(state.chamsHighlights)
    local color = RARITY_COLORS[state.chamsRarity] or Color3.fromRGB(255, 215, 0)
    local cnt = 0
    for key, data in pairs(state.slotData) do
        if data.rarity == state.chamsRarity then
            local adornee = (typeof(data.visualRef) == "Instance" and data.visualRef) 
                            or (typeof(data.slotRef) == "Instance" and data.slotRef)
            if adornee then
                local hl = makeHL(adornee, color, 0.4, 0)
                if hl then
                    state.chamsHighlights[key] = hl
                    cnt = cnt + 1
                end
            end
        end
    end
    log("Chams:", state.chamsRarity, "count:", cnt)
end

local function startChams()
    if state.chams then return end
    state.chams = true
    updateChams()
    state.chamsTask = task.spawn(function()
        while state.chams do
            task.wait(2)
            if state.chams then updateChams() end
        end
    end)
    Notify("Chams", state.chamsRarity, "Success", nil, 3)
end

local function stopChams()
    state.chams = false
    if state.chamsTask then pcall(function() task.cancel(state.chamsTask) end) end
    clearTable(state.chamsHighlights)
    Notify("Chams", "Выключен", "Info", nil, 2)
end

-- ============================================================
-- 2. HELP BUY
-- ============================================================
local function updateHelpBuy()
    clearTable(state.helpBuyHighlights)
    for _, l in pairs(state.helpBuyLabels) do pcall(function() l:Destroy() end) end
    state.helpBuyLabels = {}
    local cnt = 0
    for key, data in pairs(state.slotData) do
        if data.profit and data.profit > 0 then
            cnt = cnt + 1
            local color
            if data.profit >= 4000 then color = Color3.fromRGB(255, 70, 70)
            elseif data.profit >= 1500 then color = Color3.fromRGB(255, 170, 40)
            else color = Color3.fromRGB(70, 230, 120) end
            
            local adornee = (typeof(data.visualRef) == "Instance" and data.visualRef) 
                            or (typeof(data.slotRef) == "Instance" and data.slotRef)
            if adornee then
                local hl = makeHL(adornee, color, 0.85, 0)
                if hl then state.helpBuyHighlights[key] = hl end
                
                local roi = math.floor((data.profit / data.price) * 100)
                local text = "[" .. (data.rarity or "?") .. "] $" .. data.price .. " → +$" .. data.profit .. " (" .. roi .. "%)"
                local bb = makeBillboard(adornee, text, color)
                if bb then state.helpBuyLabels[key] = bb end
            end
        end
    end
    log("HelpBuy count:", cnt)
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
    Notify("Help Buy", "Показываю профит", "Success", nil, 3)
end

local function stopHelpBuy()
    state.helpBuy = false
    if state.helpBuyTask then pcall(function() task.cancel(state.helpBuyTask) end) end
    clearTable(state.helpBuyHighlights)
    for _, l in pairs(state.helpBuyLabels) do pcall(function() l:Destroy() end) end
    state.helpBuyLabels = {}
    Notify("Help Buy", "Выключен", "Info", nil, 2)
end

-- ============================================================
-- 3. AUTO BUY
-- ============================================================
local function autoBuyLoop()
    while state.autoBuy do
        task.wait(2)
        if not state.autoBuy then break end
        local _, hrp = getChar()
        if not hrp then continue end
        
        local targets = {}
        for key, data in pairs(state.slotData) do
            if data.rarity == state.autoBuyRarity then
                local adornee = (typeof(data.visualRef) == "Instance" and data.visualRef) 
                                or (typeof(data.slotRef) == "Instance" and data.slotRef)
                if adornee then
                    local pos = getPos(adornee)
                    if pos then
                        local torso = adornee:IsA("Model") and adornee:FindFirstChild("Torso")
                        local cd = torso and torso:FindFirstChild("ClickDetector")
                        table.insert(targets, { pos = pos, cd = cd, name = data.name })
                    end
                end
            end
        end
        log("AutoBuy targets:", #targets)
        if #targets == 0 then continue end
        
        table.sort(targets, function(a, b)
            return (a.pos - hrp.Position).Magnitude < (b.pos - hrp.Position).Magnitude
        end)
        local nearest = targets[1]
        
        if (nearest.pos - hrp.Position).Magnitude < 12 then
            clickDetector(nearest.cd)
            task.wait(0.4)
            local seller = findSellerNear(hrp.Position)
            if seller and seller.cd then
                pathfindTo(seller.pos, function()
                    clickDetector(seller.cd)
                    task.wait(0.6)
                    confirmPurchase()
                    task.wait(1)
                end, 10)
            end
        else
            pathfindTo(nearest.pos, nil, 10)
        end
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
    stopAutoWalk()
    Notify("Auto Buy", "Выключен", "Info", nil, 2)
end

-- ============================================================
-- 4. FULL-SELL
-- ============================================================
local function fullSellLoop()
    while state.fullSell do
        task.wait(3)
        if not state.fullSell then break end
        local _, hrp = getChar()
        if not hrp then continue end
        
        local targets = {}
        for key, data in pairs(state.slotData) do
            if data.profit and data.profit > 0 then
                local adornee = (typeof(data.visualRef) == "Instance" and data.visualRef) 
                                or (typeof(data.slotRef) == "Instance" and data.slotRef)
                if adornee then
                    local pos = getPos(adornee)
                    if pos then
                        local torso = adornee:IsA("Model") and adornee:FindFirstChild("Torso")
                        local cd = torso and torso:FindFirstChild("ClickDetector")
                        table.insert(targets, { pos = pos, cd = cd, profit = data.profit, name = data.name })
                    end
                end
            end
        end
        table.sort(targets, function(a, b) return a.profit > b.profit end)
        log("FullSell targets:", #targets)
        
        for i = 1, math.min(#targets, 5) do
            if not state.fullSell then break end
            local it = targets[i]
            if (it.pos - hrp.Position).Magnitude < 12 then
                clickDetector(it.cd)
                task.wait(0.3)
            else
                pathfindTo(it.pos, function() clickDetector(it.cd) end, 10)
                task.wait(1)
            end
        end
        
        local seller = findSellerNear(hrp.Position)
        if seller and seller.cd then
            pathfindTo(seller.pos, function()
                clickDetector(seller.cd)
                task.wait(0.6)
                confirmPurchase()
            end, 10)
            task.wait(1)
        end
        
        local bariga = findBariga()
        if bariga then
            pathfindTo(bariga.pos, function()
                sellAllToBariga()
                Notify("Full-Sell", "Продажа", "Success", nil, 3)
            end, 10)
            task.wait(2)
        end
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
    stopAutoWalk()
    Notify("Full-Sell", "Выключен", "Info", nil, 2)
end

-- ============================================================
-- КНОПКА + SAVE
-- ============================================================
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "HirukuOpenUi"
toggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toggleGui.ResetOnSpawn = false

local mainBtn = Instance.new("TextButton")
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
grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(60,20,110)), ColorSequenceKeypoint.new(.5, Color3.fromRGB(150,35,235)), ColorSequenceKeypoint.new(1, Color3.fromRGB(48,10,105)) })
grad.Rotation = 45
RunService.RenderStepped:Connect(function(dt)
    if grad and grad.Parent then grad.Rotation = (grad.Rotation + dt * 30) % 360 end
end)

local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local holdingDrag, holdToken = false, 0
mainBtn.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = true
    holdingDrag = true
    dragStart = input.Position
    startPos = mainBtn.Position
    holdToken = holdToken + 1
    local token = holdToken
    task.delay(1, function()
        if holdingDrag and token == holdToken then
            Notify("Locked", "Закреплено", "Info", nil, 2)
        end
    end)
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false holdingDrag = false end
    end)
end)
mainBtn.InputChanged:Connect(function(input)
    if not dragStart then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if (input.Position - dragStart).Magnitude > 6 then holdingDrag = false end
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

-- SAVE LOG
local saveGui = Instance.new("ScreenGui")
saveGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
saveGui.ResetOnSpawn = false
local saveBtn = Instance.new("TextButton")
saveBtn.Parent = saveGui
saveBtn.Size = UDim2.new(0, 180, 0, 50)
saveBtn.Position = UDim2.new(0, 15, 0.5, -25)
saveBtn.BackgroundColor3 = Color3.fromRGB(150, 35, 235)
saveBtn.TextColor3 = Color3.new(1, 1, 1)
saveBtn.Text = "SAVE LOG (0)"
saveBtn.TextSize = 14
saveBtn.Font = Enum.Font.GothamBold
saveBtn.AutoButtonColor = false
local sc = Instance.new("UICorner", saveBtn)
sc.CornerRadius = UDim.new(0, 10)
task.spawn(function()
    while saveBtn.Parent do
        saveBtn.Text = "SAVE LOG (" .. #logLines .. ")"
        task.wait(0.5)
    end
end)
saveBtn.MouseButton1Click:Connect(function()
    if not writefile then return end
    local name = "hiruku_log_" .. game.PlaceId .. "_" .. os.time() .. ".txt"
    pcall(function() writefile(name, table.concat(logLines, "\n")) end)
    saveBtn.Text = "✓ " .. name
    task.wait(3)
end)

-- UI
local secAB = Tabs.AutoBuy:AddSection("Auto Buy", "solar/cart-bold")
secAB:AddDropdown("ABRarity", { Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "Legendary", Multi = false,
    Callback = function(v) if type(v) == "table" then for k in pairs(v) do state.autoBuyRarity = k break end else state.autoBuyRarity = v end end })
secAB:AddToggle("ABToggle", { Title = "Auto Buy", Description = "Идёт и покупает выбранную редкость", Icon = "solar/cart-bold", Default = false,
    Callback = function(v) if v then startAutoBuy() else stopAutoBuy() end end })

local secHB = Tabs.HelpBuy:AddSection("Help Buy", "solar/lightbulb-bold")
secHB:AddToggle("HBToggle", { Title = "Help Buy", Description = "Показывает профит", Icon = "solar/lightbulb-bold", Default = false,
    Callback = function(v) if v then startHelpBuy() else stopHelpBuy() end end })

local secCH = Tabs.Chams:AddSection("Chams", "solar/eye-bold")
secCH:AddDropdown("CHRarity", { Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "Legendary", Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do state.chamsRarity = k break end else state.chamsRarity = v end
        if state.chams then updateChams() end
    end })
secCH:AddToggle("CHToggle", { Title = "Chams", Description = "Подсветка через стены", Icon = "solar/eye-bold", Default = false,
    Callback = function(v) if v then startChams() else stopChams() end end })

local secFS = Tabs.FullSell:AddSection("Full-Sell", "solar/dollar-bold")
secFS:AddToggle("FSToggle", { Title = "Auto Full-Sell", Description = "Скупает топ → Продавец → Барыга", Icon = "solar/dollar-bold", Default = false,
    Callback = function(v) if v then startFullSell() else stopFullSell() end end })

Fluent:SetTheme("HirukuViolet")
Notify("Hiruku Lua — TSUM", "v17 загружен", "Success", "solar/planet-bold", 4)
log("=== v17 READY ===")
task.delay(0.5, function() pcall(function() Window:SelectTab(1) end) end)