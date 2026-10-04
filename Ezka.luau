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

-- ============================================================
-- ЛОГ
-- ============================================================
local logLines = {}
local MAX_LOG = 5000

local function fileLog(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
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

-- ============================================================
-- ТЕМА
-- ============================================================
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
    Title = "Hiruku Lua — TSUM", SubTitle = "Resale Hunter v10", Version = "v10.0.0",
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
    Debug = Window:AddTab({ Title = "Debug", Icon = "solar/bug-bold" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "solar/tuning-2-bold" }),
}

-- ============================================================
-- КОНСТАНТЫ
-- ============================================================
local RARITY_LIST = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exclusive", "ParisExclusive", "TokyoExclusive", "RickOwens", "RickOwensLegendary"}
local RARITY_COLORS = {
    Common = Color3.fromRGB(180,180,180),
    Uncommon = Color3.fromRGB(100,200,100),
    Rare = Color3.fromRGB(100,150,255),
    Epic = Color3.fromRGB(180,100,255),
    Legendary = Color3.fromRGB(255,180,50),
    Mythic = Color3.fromRGB(255,80,80),
    Exclusive = Color3.fromRGB(255,215,0),
    ParisExclusive = Color3.fromRGB(200,150,255),
    TokyoExclusive = Color3.fromRGB(255,120,180),
    RickOwens = Color3.fromRGB(200,200,220),
    RickOwensLegendary = Color3.fromRGB(255,120,180),
}

local state = {
    autoBuy = false, autoBuyRarity = "Legendary", autoBuyConn = nil,
    helpBuy = false, helpBuyTask = nil,
    chams = false, chamsRarity = "Legendary", chamsTask = nil,
    fullSell = false, fullSellTask = nil,
    autoWalk = false, autoWalkConn = nil, autoWalkTarget = nil,
    lastAction = 0,
    slotData = {},
    db = {}, dbTime = 0,
    chamsHighlights = {},
    helpBuyHighlights = {},
    helpBuyLabels = {},
    pathCache = {},
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
        local handle = obj:FindFirstChild("Handle")
        if handle then return handle.Position end
        local fb = obj:FindFirstChildWhichIsA("BasePart")
        if fb then return fb.Position end
    end
    return nil
end

-- ============================================================
-- БАЗА
-- ============================================================
local function loadDB()
    local now = tick()
    if now - state.dbTime < 60 and next(state.db) then return state.db end
    state.dbTime = now
    local db = {}
    local ok = pcall(function()
        local ir = ReplicatedStorage:FindFirstChild("ItemIndexRemotes")
        if not ir then log("ItemIndexRemotes не найден") return end
        local ga = ir:FindFirstChild("GetAllItems")
        if not ga then log("GetAllItems не найден") return end
        local res = ga:InvokeServer()
        if type(res) == "table" and res.items then
            for _, it in pairs(res.items) do
                if type(it) == "table" and it.id then db[it.id] = it end
            end
        end
    end)
    if ok and next(db) then
        state.db = db
        local c = 0
        for _ in pairs(db) do c = c + 1 end
        log("DB loaded:", c, "предметов")
    end
    return db
end

local function findDBByName(name)
    if not name then return nil end
    local db = loadDB()
    local low = name:lower()
    for _, item in pairs(db) do
        if item.name and item.name:lower() == low then return item end
    end
    return nil
end

-- ============================================================
-- SLOT INFOPATCH — КЭШ
-- ============================================================
local sr = ReplicatedStorage:FindFirstChild("ShopRemotes")
if sr then
    local sip = sr:FindFirstChild("SlotInfoPatch")
    if sip then
        sip.OnClientEvent:Connect(function(...)
            local args = {...}
            for _, a in ipairs(args) do
                if type(a) == "table" then
                    for _, patch in pairs(a) do
                        if type(patch) == "table" and patch.slotRef then
                            local key = typeof(patch.slotRef) == "Instance" and patch.slotRef.Name or tostring(patch.slotRef)
                            if not patch.vacant and patch.name then
                                state.slotData[key] = {
                                    name = patch.name,
                                    rarity = patch.rarity,
                                    price = tonumber(patch.price) or 0,
                                    dbItem = findDBByName(patch.name),
                                }
                                log("Patch:", key, patch.name, patch.rarity, patch.price)
                            end
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
local function pathfindTo(targetPos, onArrive, stopDist)
    stopDist = stopDist or 8
    state.autoWalk = true
    state.autoWalkTarget = targetPos
    state.walkStuckFrames = 0
    state.lastWalkPos = nil
    state.pathRecompute = 0
    state.currentWaypoints = nil
    state.currentWaypointIndex = 1
    
    if state.autoWalkConn then state.autoWalkConn:Disconnect() end
    
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
        
        -- пересчёт пути каждые 30 кадров или если нет пути
        state.pathRecompute = state.pathRecompute + 1
        if state.pathRecompute > 30 or not state.currentWaypoints then
            state.pathRecompute = 0
            pcall(function()
                local path = PathfindingService:CreatePath({
                    AgentRadius = 2.5,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    AgentMaxSlope = 45,
                })
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
            -- ищем следующую точку, до которой > 3 стадов
            local targetWp = nil
            for i = state.currentWaypointIndex, #state.currentWaypoints do
                local wp = state.currentWaypoints[i]
                local d = (wp.Position - hrp.Position).Magnitude
                if d > 3 then
                    targetWp = wp
                    state.currentWaypointIndex = i
                    break
                end
            end
            if targetWp then
                if targetWp.Action == Enum.PathWaypointAction.Jump then
                    hum.Jump = true
                end
                hum:MoveTo(targetWp.Position + Vector3.new(0, 2, 0))
            else
                -- все точки пройдены, идём напрямую
                hum:MoveTo(target + Vector3.new(0, 2, 0))
            end
        else
            hum:MoveTo(target + Vector3.new(0, 2, 0))
        end
        
        -- защита от застревания
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
            if state.walkStuckFrames > 20 then
                log("Stuck, recomputing path")
                state.currentWaypoints = nil
                state.walkStuckFrames = 0
            end
        end
    end)
end

local function stopAutoWalk()
    state.autoWalk = false
    state.autoWalkTarget = nil
    state.currentWaypoints = nil
    if state.autoWalkConn then state.autoWalkConn:Disconnect() state.autoWalkConn = nil end
    local _, _, hum = getChar()
    if hum then pcall(function() hum:MoveTo(hum.RootPart.Position) end) end
end

-- ============================================================
-- ДЕЙСТВИЯ
-- ============================================================
local function clickDetector(cd)
    if cd then
        pcall(function() fireclickdetector(cd) end)
        log("Click:", cd:GetFullName())
    end
end

local function confirmPurchase()
    local remotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
    if remotes then
        local cp = remotes:FindFirstChild("ConfirmPurchase")
        if cp then
            pcall(function() cp:FireServer() end)
            log("ConfirmPurchase fired")
        end
    end
end

local function makeHighlight(obj, color)
    local ok, hl = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "HirukuHL"
        h.Adornee = obj
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.35
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = obj
        return h
    end)
    return ok and hl or nil
end

local function clearHighlights(t)
    for k, hl in pairs(t) do
        if typeof(hl) == "Instance" then
            pcall(function() hl.Adornee = nil hl:Destroy() end)
        end
        t[k] = nil
    end
end

-- ============================================================
-- СКАН
-- ============================================================
local function scanAll()
    local items = {}
    for _, zone in ipairs(workspace:GetChildren()) do
        if zone.Name:find("Shop_ShopZone") then
            local seller = zone:FindFirstChild("Seller")
            local sellerPart = seller and seller:FindFirstChild("HumanoidRootPart") or nil
            local sellerCD = sellerPart and sellerPart:FindFirstChild("ClickDetector") or nil
            local sellerPos = sellerPart and sellerPart.Position or nil
            
            local itemSlots = zone:FindFirstChild("ItemSlots")
            if itemSlots then
                for _, slot in ipairs(itemSlots:GetChildren()) do
                    if slot.Name:match("^Slot_?%d+$") then
                        local mannequin = slot:FindFirstChild("Mannequin")
                        if mannequin then
                            local torso = mannequin:FindFirstChild("Torso")
                            local detector = torso and torso:FindFirstChild("ClickDetector") or nil
                            local pos = getPos(mannequin)
                            if pos then
                                local data = state.slotData[slot.Name]
                                table.insert(items, {
                                    slot = slot,
                                    mannequin = mannequin,
                                    pos = pos,
                                    detector = detector,
                                    seller = seller,
                                    sellerPos = sellerPos,
                                    sellerCD = sellerCD,
                                    name = data and data.name,
                                    rarity = data and data.rarity,
                                    price = data and data.price or 0,
                                    dbItem = data and data.dbItem,
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    return items
end

local function findNearest(items, fromPos)
    if #items == 0 then return nil end
    local best, bestDist = items[1], (items[1].pos - fromPos).Magnitude
    for i = 2, #items do
        local d = (items[i].pos - fromPos).Magnitude
        if d < bestDist then best, bestDist = items[i], d end
    end
    return best
end

local function findBariga()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "BarigaNPC" then
            local pos = getPos(obj)
            if pos then return { obj = obj, pos = pos } end
        end
    end
    return nil
end

-- ============================================================
-- CHAMS — обновление раз в 3 сек
-- ============================================================
local function updateChams()
    clearHighlights(state.chamsHighlights)
    local items = scanAll()
    local color = RARITY_COLORS[state.chamsRarity] or Color3.fromRGB(255, 60, 196)
    local count = 0
    for i, item in ipairs(items) do
        if item.rarity == state.chamsRarity and item.mannequin then
            local hl = makeHighlight(item.mannequin, color)
            if hl then
                state.chamsHighlights[i] = hl
                count = count + 1
            end
        end
    end
    log("Chams updated:", state.chamsRarity, "count:", count)
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
    clearHighlights(state.chamsHighlights)
    Notify("Chams", "Выключен", "Info", nil, 2)
end

-- ============================================================
-- AUTO BUY
-- ============================================================
local function startAutoBuy()
    if state.autoBuy then return end
    state.autoBuy = true
    log("AutoBuy START:", state.autoBuyRarity)
    state.autoBuyConn = RunService.Heartbeat:Connect(function()
        if not state.autoBuy then return end
        local now = tick()
        if now - state.lastAction < 2 then return end
        state.lastAction = now
        local _, hrp = getChar()
        if not hrp then return end
        
        local items = scanAll()
        local targets = {}
        for _, item in ipairs(items) do
            if item.rarity == state.autoBuyRarity and item.detector then
                table.insert(targets, item)
            end
        end
        log("AutoBuy целей:", #targets)
        if #targets == 0 then return end
        
        local nearest = findNearest(targets, hrp.Position)
        if not nearest then return end
        
        if (nearest.pos - hrp.Position).Magnitude < 12 then
            clickDetector(nearest.detector)
            task.wait(0.5)
            if nearest.sellerCD and nearest.sellerPos then
                pathfindTo(nearest.sellerPos, function()
                    clickDetector(nearest.sellerCD)
                    task.wait(0.6)
                    confirmPurchase()
                end, 10)
            end
        else
            pathfindTo(nearest.pos, nil, 10)
        end
    end)
    Notify("Auto Buy", state.autoBuyRarity, "Success", nil, 3)
end

local function stopAutoBuy()
    state.autoBuy = false
    if state.autoBuyConn then state.autoBuyConn:Disconnect() state.autoBuyConn = nil end
    stopAutoWalk()
    Notify("Auto Buy", "Выключен", "Info", nil, 2)
end

-- ============================================================
-- HELP BUY
-- ============================================================
local function updateHelpBuy()
    clearHighlights(state.helpBuyHighlights)
    for _, l in pairs(state.helpBuyLabels) do pcall(function() l:Remove() end) end
    state.helpBuyLabels = {}
    
    local items = scanAll()
    local count = 0
    for i, item in ipairs(items) do
        if item.dbItem and item.price > 0 then
            local fair = tonumber(item.dbItem.fairPrice) or 0
            if fair > 0 then
                local profit = math.floor(fair - item.price)
                if profit > 0 then
                    count = count + 1
                    local hl = makeHighlight(item.mannequin, Color3.fromRGB(0, 255, 100))
                    if hl then state.helpBuyHighlights[count] = hl end
                    
                    local sp, onScreen = Camera:WorldToViewportPoint(item.pos)
                    if onScreen then
                        local txt = Drawing.new("Text")
                        txt.Text = "+" .. profit .. "₽"
                        txt.Color = Color3.fromRGB(0, 255, 100)
                        txt.Outline = true
                        txt.OutlineColor = Color3.new(0, 0, 0)
                        txt.Center = true
                        txt.Size = 16
                        txt.Position = Vector2.new(sp.X, sp.Y - 25)
                        txt.Visible = true
                        state.helpBuyLabels[count] = txt
                    end
                end
            end
        end
    end
    log("HelpBuy updated, count:", count)
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
    Notify("Help Buy", "Ищу прибыльное", "Success", nil, 3)
end

local function stopHelpBuy()
    state.helpBuy = false
    if state.helpBuyTask then pcall(function() task.cancel(state.helpBuyTask) end) end
    clearHighlights(state.helpBuyHighlights)
    for _, l in pairs(state.helpBuyLabels) do pcall(function() l:Remove() end) end
    state.helpBuyLabels = {}
    Notify("Help Buy", "Выключен", "Info", nil, 2)
end

-- ============================================================
-- FULL-SELL
-- ============================================================
local function sellAllToBariga()
    local br = ReplicatedStorage:FindFirstChild("BarigaRemotes")
    if not br then return end
    local trigger = br:FindFirstChild("TriggerBariga")
    if trigger then pcall(function() trigger:FireServer() end) end
    task.wait(0.6)
    local inv = br:FindFirstChild("GetBarigaInventory")
    if inv then
        local ok, res = pcall(function() return inv:InvokeServer() end)
        if ok and type(res) == "table" then
            local uids = {}
            for _, item in pairs(res) do
                if type(item) == "table" and item.uid then table.insert(uids, item.uid) end
            end
            if #uids > 0 then
                local confirm = br:FindFirstChild("ConfirmBarigaSale")
                if confirm then
                    pcall(function() confirm:FireServer(uids) end)
                    log("Продажа Барыге, uids:", #uids)
                end
            end
        end
    end
    task.wait(0.4)
    local close = br:FindFirstChild("CloseBariga")
    if close then pcall(function() close:FireServer() end) end
end

local function startFullSell()
    if state.fullSell then return end
    state.fullSell = true
    log("FullSell START")
    state.fullSellTask = task.spawn(function()
        while state.fullSell do
            task.wait(5)
            if not state.fullSell then break end
            local _, hrp = getChar()
            if not hrp then continue end
            
            -- 1. Ищем прибыльные
            local items = scanAll()
            local targets = {}
            for _, item in ipairs(items) do
                if item.detector then
                    local fair = item.dbItem and tonumber(item.dbItem.fairPrice) or 0
                    if fair > item.price and item.price > 0 then
                        item.profit = fair - item.price
                        table.insert(targets, item)
                    end
                end
            end
            table.sort(targets, function(a, b) return a.profit > b.profit end)
            log("FullSell целей:", #targets)
            
            -- 2. Скупаем топ-5
            if #targets > 0 then
                for i = 1, math.min(#targets, 5) do
                    if not state.fullSell then break end
                    local item = targets[i]
                    pathfindTo(item.pos, function() clickDetector(item.detector) end, 10)
                    task.wait(1)
                end
                
                if targets[1] and targets[1].sellerCD then
                    pathfindTo(targets[1].sellerPos, function()
                        clickDetector(targets[1].sellerCD)
                        task.wait(0.6)
                        confirmPurchase()
                    end, 10)
                    task.wait(1)
                end
            end
            
            -- 3. Продаём Барыге
            local bariga = findBariga()
            if bariga then
                pathfindTo(bariga.pos, function()
                    sellAllToBariga()
                    Notify("Full-Sell", "Продажа завершена", "Success", nil, 3)
                end, 10)
                task.wait(1)
            end
        end
    end)
    Notify("Full-Sell", "Включён", "Success", nil, 3)
end

local function stopFullSell()
    state.fullSell = false
    if state.fullSellTask then pcall(function() task.cancel(state.fullSellTask) end) end
    stopAutoWalk()
    Notify("Full-Sell", "Выключен", "Info", nil, 2)
end

-- ============================================================
-- КНОПКА ОТКРЫТИЯ МЕНЮ
-- ============================================================
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
local holdingDrag, holdToken = false, 0
mainBtn:SetAttribute("Locked", false)
mainBtn.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = not mainBtn:GetAttribute("Locked")
    holdingDrag = true
    dragStart = input.Position
    startPos = mainBtn.Position
    holdToken = holdToken + 1
    local token = holdToken
    task.delay(1, function()
        if holdingDrag and token == holdToken then
            local ns = not mainBtn:GetAttribute("Locked")
            mainBtn:SetAttribute("Locked", ns)
            Notify(ns and "Locked" or "Unlocked", ns and "Закреплено" or "Можно двигать", "Info", nil, 2)
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
        if mainBtn:GetAttribute("Locked") then return end
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
                if obj:IsA("Frame") and obj.Name == "Main" and obj.Size.X.Offset > 300 then return obj end
            end
            for _, obj in ipairs(gui:GetChildren()) do
                if obj:IsA("Frame") and obj.Size.X.Offset > 300 then return obj end
            end
        end
    end
    return nil
end

local function WindowOpenAnimation()
    local frame = findWindowFrame()
    if not frame then return end
    local orig = frame.Size
    frame.Size = UDim2.new(orig.X.Scale, 0, orig.Y.Scale, 0)
    pcall(function() TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = orig}):Play() end)
end

mainBtn.MouseButton1Click:Connect(function()
    PlaySound(({"7127123605","438666542"})[math.random(2)])
    uiOpen = not uiOpen
    if uiOpen then
        pcall(function() Window:Show() end)
        task.wait(0.05)
        WindowOpenAnimation()
    else
        pcall(function() Window:Hide() end)
    end
    local orig = UDim2.new(0, 60, 0, 60)
    local press = UDim2.new(0, 48, 0, 48)
    pcall(function() TweenService:Create(mainBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = press}):Play() end)
    task.wait(0.08)
    pcall(function() TweenService:Create(mainBtn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = orig}):Play() end)
end)

-- ============================================================
-- КНОПКА SAVE LOG
-- ============================================================
local saveBtnGui = Instance.new("ScreenGui")
saveBtnGui.Name = "HirukuSaveBtn"
saveBtnGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
saveBtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
saveBtnGui.ResetOnSpawn = false

local saveBtn = Instance.new("TextButton")
saveBtn.Name = "SaveLogButton"
saveBtn.Parent = saveBtnGui
saveBtn.Size = UDim2.new(0, 180, 0, 55)
saveBtn.Position = UDim2.new(0, 15, 0.5, -27)
saveBtn.BackgroundColor3 = Color3.fromRGB(150, 35, 235)
saveBtn.BackgroundTransparency = 0.05
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.TextSize = 15
saveBtn.Font = Enum.Font.GothamBold
saveBtn.Text = "SAVE LOG (0)"
saveBtn.AutoButtonColor = false
saveBtn.BorderSizePixel = 0
saveBtn.ZIndex = 200
saveBtn.Visible = true

local saveCorner = Instance.new("UICorner", saveBtn)
saveCorner.CornerRadius = UDim.new(0, 10)

local saveStroke = Instance.new("UIStroke", saveBtn)
saveStroke.Color = Color3.fromRGB(255, 255, 255)
saveStroke.Thickness = 2

local saveGrad = Instance.new("UIGradient", saveBtn)
saveGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 35, 235)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 15, 160))
})
saveGrad.Rotation = 45

task.spawn(function()
    while saveBtn.Parent do
        saveBtn.Text = "SAVE LOG (" .. #logLines .. ")"
        task.wait(0.5)
    end
end)

saveBtn.MouseButton1Click:Connect(function()
    if not writefile then
        saveBtn.Text = "НЕТ writefile"
        print("[Hiruku] writefile недоступен")
        task.wait(2)
        return
    end
    local name = "hiruku_log_" .. game.PlaceId .. "_" .. os.time() .. ".txt"
    local ok = pcall(function() writefile(name, table.concat(logLines, "\n")) end)
    if ok then
        saveBtn.Text = "✓ СОХРАНЕНО"
        print("[Hiruku] Файл сохранён: " .. name .. " (" .. #logLines .. " строк)")
    else
        saveBtn.Text = "ОШИБКА"
        print("[Hiruku] Ошибка writefile")
    end
    task.wait(3)
    saveBtn.Text = "SAVE LOG (" .. #logLines .. ")"
end)

-- ============================================================
-- UI ЭЛЕМЕНТЫ
-- ============================================================
local secAutoBuy = Tabs.AutoBuy:AddSection("Auto Buy", "solar/cart-bold")
secAutoBuy:AddDropdown("AutoBuyRarity", {
    Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "Legendary", Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do state.autoBuyRarity = k break end else state.autoBuyRarity = v end
    end
})
secAutoBuy:AddToggle("AutoBuy", { Title = "Auto Buy", Description = "Кликает по манекену → покупает у продавца", Icon = "solar/cart-bold", Default = false, Callback = function(v) if v then startAutoBuy() else stopAutoBuy() end end })

local secHelpBuy = Tabs.HelpBuy:AddSection("Help Buy", "solar/lightbulb-bold")
secHelpBuy:AddToggle("HelpBuy", { Title = "Help Buy", Description = "Подсветка прибыльного (+X₽)", Icon = "solar/lightbulb-bold", Default = false, Callback = function(v) if v then startHelpBuy() else stopHelpBuy() end end })

local secChams = Tabs.Chams:AddSection("Chams Items", "solar/eye-bold")
secChams:AddDropdown("ChamsRarity", {
    Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "Legendary", Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do state.chamsRarity = k break end else state.chamsRarity = v end
        if state.chams then updateChams() end
    end
})
secChams:AddToggle("Chams", { Title = "Chams", Description = "Подсветка через стены", Icon = "solar/eye-bold", Default = false, Callback = function(v) if v then startChams() else stopChams() end end })

local secFullSell = Tabs.FullSell:AddSection("Auto Full-Sell", "solar/dollar-bold")
secFullSell:AddToggle("FullSell", { Title = "Auto Full-Sell", Description = "Скупает → продаёт Барыге", Icon = "solar/dollar-bold", Default = false, Callback = function(v) if v then startFullSell() else stopFullSell() end end })

local secDebug = Tabs.Debug:AddSection("Debug", "solar/bug-bold")
secDebug:AddButton({ Title = "Показать кэш", Icon = "solar/list-bold", Callback = function()
    local c = 0
    for k, v in pairs(state.slotData) do
        c = c + 1
        if c <= 20 then log(k, v.name, v.rarity, v.price) end
    end
    log("Всего в кэше:", c)
    Notify("Cache", "Записей: " .. c, "Info", nil, 3)
end })
secDebug:AddButton({ Title = "Показать цели скана", Icon = "solar/eye-bold", Callback = function()
    local items = scanAll()
    log("Манекенов:", #items)
    local withRarity = 0
    for _, item in ipairs(items) do
        if item.rarity then withRarity = withRarity + 1 end
    end
    log("С редкостью:", withRarity)
    Notify("Scan", #items .. " / " .. withRarity, "Info", nil, 3)
end })
secDebug:AddButton({ Title = "Test Pathfinding", Icon = "solar/route-bold", Callback = function()
    local _, hrp = getChar()
    if not hrp then return end
    local items = scanAll()
    if #items == 0 then Notify("Test", "Нет манекенов", "Error") return end
    pathfindTo(items[1].pos, function() Notify("Test", "Дошёл", "Success", nil, 3) end, 8)
end })
secDebug:AddButton({ Title = "Сохранить лог", Icon = "solar/diskette-bold", Callback = function()
    if not writefile then Notify("Log", "writefile нет", "Error") return end
    local name = "hiruku_log_" .. game.PlaceId .. "_" .. os.time() .. ".txt"
    local ok = pcall(function() writefile(name, table.concat(logLines, "\n")) end)
    if ok then
        Notify("Log", "Сохранено: " .. name, "Success", nil, 4)
        print("[Hiruku] " .. name)
    end
end })
secDebug:AddButton({ Title = "Очистить лог", Icon = "solar/trash-bin-bold", Callback = function()
    logLines = {}
    Notify("Log", "Очищено", "Info", nil, 2)
end })

local secSet = Tabs.Settings:AddSection("Font", "solar/text-bold")
local FONT_LIST = {"Gotham", "GothamBold", "SourceSans", "SourceSansBold", "Code", "Roboto", "RobotoCondensed", "Ubuntu", "Arial", "Antique", "Fantasy", "SciFi", "Cartoon"}
local function applyFontToGui(fontName)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name == "HirukuOpenUi" or gui.Name:lower():find("fluent") or gui.Name == "HirukuSaveBtn" then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    pcall(function() obj.Font = Enum.Font[fontName] end)
                end
            end
        end
    end
    Notify("Font", "Применён: " .. fontName, "Success", nil, 2)
end
secSet:AddDropdown("FontPicker", {
    Title = "Font", Description = "Только меню", Icon = "solar/text-bold",
    Values = FONT_LIST, Default = "Gotham", Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do applyFontToGui(k) break end else applyFontToGui(v) end
    end
})

Fluent:SetTheme("HirukuViolet")
Notify("Hiruku Lua — TSUM", "v10 загружен", "Success", "solar/planet-bold", 4)
log("=== v10 READY ===")
log("PlaceId:", game.PlaceId)
log("Кнопка SAVE LOG слева по центру")
task.delay(0.5, function() pcall(function() Window:SelectTab(1) end) end)