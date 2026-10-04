-- ============================================================
-- HIRUKU v14 FINAL
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
local MAX_LOG = 5000
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
    Title = "Hiruku Lua — TSUM", SubTitle = "Resale Hunter v14", Version = "v14.0.0",
    TabWidth = 130, Size = UDim2.fromOffset(580,410), Acrylic = true,
    Theme = "HirukuViolet", MinimizeKey = Enum.KeyCode.LeftControl, Search = true,
    Icons = "solar/planet-bold", UserInfoTop = true, UserInfoTitle = "Welcome",
    UserInfoSubtitle = LocalPlayer.DisplayName, UserInfoColor = Color3.fromRGB(185,70,255),
})

pcall(function() Fluent:SetErrorHandler(function(msg) log("UI Error:", msg) end) end)

local Tabs = {
    AutoBuy = Window:AddTab({ Title = "Auto Buy", Icon = "solar/cart-bold" }),
    HelpBuy = Window:AddTab({ Title = "Help Buy", Icon = "solar/lightbulb-bold" }),
    Chams = Window:AddTab({ Title = "Chams", Icon = "solar/eye-bold" }),
    FullSell = Window:AddTab({ Title = "Full-Sell", Icon = "solar/dollar-bold" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "solar/tuning-2-bold" }),
}

-- РЕДКОСТИ (из наших тестов)
local RARITY_LIST = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exclusive", "ParisExclusive", "TokyoExclusive", "RickOwens", "RickOwensLegendary"}

-- Цвета по редкости
local RARITY_COLORS = {
    Common = Color3.fromRGB(150, 150, 150),
    Uncommon = Color3.fromRGB(0, 200, 0),
    Rare = Color3.fromRGB(0, 150, 255),
    Epic = Color3.fromRGB(180, 0, 255),
    Legendary = Color3.fromRGB(255, 165, 0),
    Mythic = Color3.fromRGB(255, 0, 100),
    Exclusive = Color3.fromRGB(255, 215, 0),
    ParisExclusive = Color3.fromRGB(200, 150, 255),
    TokyoExclusive = Color3.fromRGB(255, 120, 180),
    RickOwens = Color3.fromRGB(200, 200, 220),
    RickOwensLegendary = Color3.fromRGB(255, 100, 200),
}

-- Приблизительные цены по редкости
local RARITY_PRICES = {
    Common = 1000,
    Uncommon = 2000,
    Rare = 5000,
    Epic = 15000,
    Legendary = 40000,
    Mythic = 80000,
    Exclusive = 150000,
    ParisExclusive = 100000,
    TokyoExclusive = 100000,
    RickOwens = 120000,
    RickOwensLegendary = 200000,
}

-- Классификация по длине ShirtTemplate ID + префиксу
local function classifyRarity(shirtId, pantsId, hasAccessory)
    local id = shirtId or pantsId
    if not id then return "Common" end
    local idNum = tonumber(id)
    if not idNum then return "Common" end
    local len = #tostring(idNum)
    
    -- базовая классификация по длине
    local base = "Common"
    if len <= 8 then base = "Common"
    elseif len <= 10 then base = "Uncommon"
    elseif len <= 11 then base = "Rare"
    elseif len <= 12 then base = "Epic"
    elseif len <= 13 then base = "Legendary"
    else base = "Mythic" end
    
    -- если есть аксессуар, может быть RickOwens или Exclusive
    if hasAccessory and len >= 13 then
        -- грубо: очень длинные + аксессуар = RickOwens
        base = "RickOwens"
    end
    
    return base
end

local state = {
    -- Chams
    chams = false, chamsRarity = "Legendary", chamsTask = nil,
    chamsHighlights = {},
    -- Help Buy
    helpBuy = false, helpBuyTask = nil,
    helpBuyHighlights = {}, helpBuyLabels = {},
    -- Auto Buy
    autoBuy = false, autoBuyRarity = "Legendary", autoBuyTask = nil,
    -- Full Sell
    fullSell = false, fullSellTask = nil,
    -- Pathfinding
    autoWalk = false, autoWalkConn = nil, autoWalkTarget = nil,
    currentWaypoints = nil, currentWaypointIndex = 1,
    walkStuckFrames = 0, lastWalkPos = nil,
    -- Кэш
    mannequins = {}, lastScan = 0,
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
-- СКАН МАНЕКЕНОВ С ОПРЕДЕЛЕНИЕМ РЕДКОСТИ
-- ============================================================
local function scanMannequins()
    local now = tick()
    if now - state.lastScan < 3 then return state.mannequins end
    state.lastScan = now
    
    local mannequins = {}
    for _, zone in ipairs(ws:GetChildren()) do
        if zone.Name:find("Shop_ShopZone") then
            local slots = zone:FindFirstChild("ItemSlots")
            if slots then
                for _, slot in ipairs(slots:GetChildren()) do
                    if slot.Name:match("^Slot_?%d+$") then
                        local man = slot:FindFirstChild("Mannequin")
                        if man then
                            local shirt = man:FindFirstChildOfClass("Shirt")
                            local pants = man:FindFirstChildOfClass("Pants")
                            local shirtId = shirt and shirt.ShirtTemplate and shirt.ShirtTemplate:match("rbxassetid://(%d+)")
                            local pantsId = pants and pants.PantsTemplate and pants.PantsTemplate:match("rbxassetid://(%d+)")
                            
                            -- ищем аксессуары
                            local hasAccessory = false
                            for _, d in ipairs(man:GetChildren()) do
                                if d:IsA("Accessory") then hasAccessory = true break end
                            end
                            
                            local rarity = classifyRarity(shirtId, pantsId, hasAccessory)
                            local price = RARITY_PRICES[rarity] or 1000
                            
                            local torso = man:FindFirstChild("Torso")
                            local detector = torso and torso:FindFirstChild("ClickDetector")
                            
                            local pos = getPos(man)
                            
                            if pos and detector then
                                table.insert(mannequins, {
                                    man = man, slot = slot, zone = zone,
                                    pos = pos, detector = detector,
                                    rarity = rarity, price = price,
                                    shirtId = shirtId, pantsId = pantsId,
                                    hasAccessory = hasAccessory,
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    state.mannequins = mannequins
    log("Скан: " .. #mannequins .. " манекенов")
    return mannequins
end

local function findNearest(items, fromPos, filterFn)
    if not fromPos then return nil end
    local best, bestDist = nil, math.huge
    for _, item in ipairs(items) do
        if not filterFn or filterFn(item) then
            local d = (item.pos - fromPos).Magnitude
            if d < bestDist then
                best, bestDist = item, d
            end
        end
    end
    return best
end

-- ============================================================
-- PATHFINDING
-- ============================================================
local function forceWalkTo(hum, hrp, targetPos)
    if not hum or not hrp or not targetPos then return end
    if hum.WalkSpeed < 16 then hum.WalkSpeed = 24 end
    hum:MoveTo(targetPos)
    local vel = hrp.AssemblyLinearVelocity
    local flatVel = Vector3.new(vel.X, 0, vel.Z)
    if flatVel.Magnitude < 0.5 then
        local dir = targetPos - hrp.Position
        dir = Vector3.new(dir.X, 0, dir.Z)
        if dir.Magnitude > 0.1 then
            dir = dir.Unit
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * 20, vel.Y, dir.Z * 20)
        end
    end
end

local lastStuckLog = 0

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
        if fc % 60 == 0 or not state.currentWaypoints then
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
                forceWalkTo(hum, hrp, tw.Position + Vector3.new(0, 2, 0))
            else
                forceWalkTo(hum, hrp, target + Vector3.new(0, 2, 0))
            end
        else
            forceWalkTo(hum, hrp, target + Vector3.new(0, 2, 0))
        end
        
        if not state.lastWalkPos then
            state.lastWalkPos = hrp.Position
        else
            local moved = (hrp.Position - state.lastWalkPos).Magnitude
            state.lastWalkPos = hrp.Position
            if moved < 0.02 then
                state.walkStuckFrames = state.walkStuckFrames + 1
            else
                state.walkStuckFrames = 0
            end
            if state.walkStuckFrames > 60 then
                local now = tick()
                if now - lastStuckLog > 5 then
                    log("Stuck")
                    lastStuckLog = now
                end
                state.walkStuckFrames = 0
                state.currentWaypoints = nil
            end
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
-- КЛИКИ / ДЕЙСТВИЯ
-- ============================================================
local function clickDetector(cd)
    if cd then pcall(function() fireclickdetector(cd) end) end
end

local function confirmPurchase()
    local sr = ReplicatedStorage:FindFirstChild("ShopRemotes")
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
                        best, bestDist = { seller = seller, pos = hrp.Position, cd = cd }, d
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
                    log("Продажа Барыге:", #uids, "предметов")
                end
            end
        end
    end
    task.wait(0.4)
    local cl = br:FindFirstChild("CloseBariga")
    if cl then pcall(function() cl:FireServer() end) end
end

-- ============================================================
-- ХЕЛПЕРЫ ДЛЯ HIGHLIGHT / LABEL
-- ============================================================
local function makeHighlight(obj, color, fill, outline)
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

local function makeBillboard(man, text, color)
    local part = man:FindFirstChild("Torso") or man.PrimaryPart
    if not part then return nil end
    local ok, bg = pcall(function()
        local b = Instance.new("BillboardGui")
        b.Name = "HirukuLabel"
        b.Size = UDim2.new(0, 180, 0, 28)
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
    return ok and bg or nil
end

-- ============================================================
-- 1. CHAMS — только выбранная редкость, без ограничений дальности
-- ============================================================
local function updateChams()
    clearTable(state.chamsHighlights)
    local items = scanMannequins()
    local color = RARITY_COLORS[state.chamsRarity] or Color3.fromRGB(255, 60, 196)
    local cnt = 0
    for i, item in ipairs(items) do
        if item.rarity == state.chamsRarity then
            local hl = makeHighlight(item.man, color, 0.5, 0)
            if hl then
                state.chamsHighlights[i] = hl
                cnt = cnt + 1
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
            task.wait(3)
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
-- 2. HELP BUY — профит по редкости
-- ============================================================
local function updateHelpBuy()
    clearTable(state.helpBuyHighlights)
    for _, l in pairs(state.helpBuyLabels) do pcall(function() l:Destroy() end) end
    state.helpBuyLabels = {}
    
    local items = scanMannequins()
    local cnt = 0
    for i, item in ipairs(items) do
        -- профит = fairPrice ≈ price × 0.98 (из наших тестов)
        local profit = math.floor(item.price * 0.98)
        -- если прибыль положительная (всегда) — показываем
        local color = RARITY_COLORS[item.rarity] or Color3.fromRGB(0, 255, 100)
        local hl = makeHighlight(item.man, color, 0.85, 0)
        if hl then state.helpBuyHighlights[i] = hl end
        
        local text = item.rarity .. " +" .. profit .. "₽"
        local bg = makeBillboard(item.man, text, color)
        if bg then state.helpBuyLabels[i] = bg end
        cnt = cnt + 1
    end
    log("HelpBuy:", cnt)
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
-- 3. AUTO BUY — выбранная редкость
-- ============================================================
local function autoBuyLoop()
    while state.autoBuy do
        task.wait(2)
        if not state.autoBuy then break end
        local _, hrp = getChar()
        if not hrp then continue end
        
        local items = scanMannequins()
        local targets = {}
        for _, it in ipairs(items) do
            if it.rarity == state.autoBuyRarity then
                table.insert(targets, it)
            end
        end
        log("AutoBuy targets:", #targets)
        if #targets == 0 then continue end
        
        local nearest = findNearest(targets, hrp.Position)
        if not nearest then continue end
        
        -- идём к манекену
        if (nearest.pos - hrp.Position).Magnitude < 12 then
            clickDetector(nearest.detector)
            task.wait(0.4)
            -- идём к продавцу
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
-- 4. FULL SELL — топ профит, покупка, продажа Барыге
-- ============================================================
local function fullSellLoop()
    while state.fullSell do
        task.wait(3)
        if not state.fullSell then break end
        local _, hrp = getChar()
        if not hrp then continue end
        
        local items = scanMannequins()
        -- сортируем по профиту (по редкости)
        local targets = {}
        for _, it in ipairs(items) do
            it.profit = math.floor(it.price * 0.98)
            table.insert(targets, it)
        end
        table.sort(targets, function(a, b) return a.profit > b.profit end)
        
        -- скупаем топ 5
        for i = 1, math.min(#targets, 5) do
            if not state.fullSell then break end
            local it = targets[i]
            if (it.pos - hrp.Position).Magnitude < 12 then
                clickDetector(it.detector)
                task.wait(0.3)
            else
                pathfindTo(it.pos, function() clickDetector(it.detector) end, 10)
                task.wait(1)
            end
        end
        
        -- к продавцу
        local seller = findSellerNear(hrp.Position)
        if seller and seller.cd then
            pathfindTo(seller.pos, function()
                clickDetector(seller.cd)
                task.wait(0.6)
                confirmPurchase()
            end, 10)
            task.wait(1)
        end
        
        -- к Барыге
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
-- КНОПКА + SAVE LOG
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
local function PlaySound(sid)
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = "rbxassetid://" .. sid
        s.Parent = SoundService
        s:Play()
        s.Ended:Connect(function() s:Destroy() end)
    end)
end

local function findWindowFrame()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name:lower():find("fluent") then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("Frame") and obj.Size.X.Offset > 300 then return obj end
            end
        end
    end
    return nil
end

mainBtn.MouseButton1Click:Connect(function()
    PlaySound(({"7127123605","438666542"})[math.random(2)])
    uiOpen = not uiOpen
    if uiOpen then
        pcall(function() Window:Show() end)
    else
        pcall(function() Window:Hide() end)
    end
    local orig = UDim2.new(0, 60, 0, 60)
    local press = UDim2.new(0, 48, 0, 48)
    pcall(function() TweenService:Create(mainBtn, TweenInfo.new(0.08), {Size = press}):Play() end)
    task.wait(0.08)
    pcall(function() TweenService:Create(mainBtn, TweenInfo.new(0.18), {Size = orig}):Play() end)
end)

-- SAVE LOG кнопка
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
saveBtn.BorderSizePixel = 0
saveBtn.ZIndex = 200
local sc = Instance.new("UICorner", saveBtn)
sc.CornerRadius = UDim.new(0, 10)
task.spawn(function()
    while saveBtn.Parent do
        saveBtn.Text = "SAVE LOG (" .. #logLines .. ")"
        task.wait(0.5)
    end
end)
saveBtn.MouseButton1Click:Connect(function()
    if not writefile then saveBtn.Text = "НЕТ writefile" task.wait(2) return end
    local name = "hiruku_log_" .. game.PlaceId .. "_" .. os.time() .. ".txt"
    local ok = pcall(function() writefile(name, table.concat(logLines, "\n")) end)
    if ok then saveBtn.Text = "✓ " .. name print("[Hiruku] " .. name)
    else saveBtn.Text = "ОШИБКА" end
    task.wait(3)
    saveBtn.Text = "SAVE LOG (" .. #logLines .. ")"
end)

-- ============================================================
-- UI ЭЛЕМЕНТЫ
-- ============================================================

-- AUTO BUY
local secAB = Tabs.AutoBuy:AddSection("Auto Buy", "solar/cart-bold")
secAB:AddDropdown("ABRarity", { Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "Legendary", Multi = false,
    Callback = function(v) if type(v) == "table" then for k in pairs(v) do state.autoBuyRarity = k break end else state.autoBuyRarity = v end end })
secAB:AddToggle("ABToggle", { Title = "Auto Buy", Description = "Скупает выбранную редкость", Icon = "solar/cart-bold", Default = false,
    Callback = function(v) if v then startAutoBuy() else stopAutoBuy() end end })

-- HELP BUY
local secHB = Tabs.HelpBuy:AddSection("Help Buy", "solar/lightbulb-bold")
secHB:AddToggle("HBToggle", { Title = "Help Buy", Description = "Показывает профит каждой вещи", Icon = "solar/lightbulb-bold", Default = false,
    Callback = function(v) if v then startHelpBuy() else stopHelpBuy() end end })

-- CHAMS
local secCH = Tabs.Chams:AddSection("Chams", "solar/eye-bold")
secCH:AddDropdown("CHRarity", { Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "Legendary", Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do state.chamsRarity = k break end else state.chamsRarity = v end
        if state.chams then updateChams() end
    end })
secCH:AddToggle("CHToggle", { Title = "Chams", Description = "Подсветка через стены, без ограничений дальности", Icon = "solar/eye-bold", Default = false,
    Callback = function(v) if v then startChams() else stopChams() end end })

-- FULL SELL
local secFS = Tabs.FullSell:AddSection("Full-Sell", "solar/dollar-bold")
secFS:AddToggle("FSToggle", { Title = "Auto Full-Sell", Description = "Скупает топ → Продавец → Барыга", Icon = "solar/dollar-bold", Default = false,
    Callback = function(v) if v then startFullSell() else stopFullSell() end end })

-- SETTINGS
local secSET = Tabs.Settings:AddSection("Font", "solar/text-bold")
local FONT_LIST = {"Gotham", "GothamBold", "SourceSans", "SourceSansBold", "Code", "Roboto", "RobotoCondensed", "Ubuntu", "Arial", "Antique", "Fantasy", "SciFi", "Cartoon"}
local function applyFont(fontName)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name == "HirukuOpenUi" or gui.Name:lower():find("fluent") then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    pcall(function() obj.Font = Enum.Font[fontName] end)
                end
            end
        end
    end
end
secSET:AddDropdown("FontPicker", { Title = "Font", Icon = "solar/text-bold", Values = FONT_LIST, Default = "Gotham", Multi = false,
    Callback = function(v) if type(v) == "table" then for k in pairs(v) do applyFont(k) break end else applyFont(v) end end })

Fluent:SetTheme("HirukuViolet")
Notify("Hiruku Lua — TSUM", "v14 загружен", "Success", "solar/planet-bold", 4)
log("=== v14 READY ===")
task.delay(0.5, function() pcall(function() Window:SelectTab(1) end) end)