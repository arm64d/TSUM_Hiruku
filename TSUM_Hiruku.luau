local Fluent
pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/StyearX/Fluent-modded/releases/download/1.5.1/FluentPro"))()
end)
if not Fluent then return warn("[Hiruku] Fluent не загрузился") end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players:GetPlayers()[1]
local Camera = workspace.CurrentCamera
local ws = workspace

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

local RARITY_LIST = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exclusive", "ParisExclusive", "TokyoExclusive", "RickOwens", "RickOwensLegendary"}

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
    chams = false, chamsRarity = "Legendary", chamsTask = nil, chamsHighlights = {},
    helpBuy = false, helpBuyTask = nil, helpBuyHighlights = {}, helpBuyLabels = {},
    autoBuy = false, autoBuyRarity = "Legendary", autoBuyTask = nil,
    fullSell = false, fullSellTask = nil,
    walkSpeed = 30,
    slotData = {},
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
    local balance = 0
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("TsumBankRemotes") or ReplicatedStorage:FindFirstChild("ATMRemotes")
        if remotes then
            local gb = remotes:FindFirstChild("GetBalance")
            if gb and gb:IsA("RemoteFunction") then
                local ok, res = pcall(function() return gb:InvokeServer() end)
                if ok and tonumber(res) then
                    balance = tonumber(res)
                end
            end
        end
    end)
    return balance
end

local sr = ReplicatedStorage:FindFirstChild("ShopRemotes")
if sr then
    local siu = sr:FindFirstChild("SlotInfoUpdate")
    if siu then
        siu.OnClientEvent:Connect(function(arg)
            if type(arg) ~= "table" or type(arg.slots) ~= "table" then return end
            for _, slot in ipairs(arg.slots) do
                if type(slot) == "table" and slot.slotRef and typeof(slot.slotRef) == "Instance" then
                    local cat = CATALOG[(slot.name or ""):lower()]
                    local rarity = cat and cat.rarity or slot.rarity
                    local fairPrice = cat and cat.fairPrice or 0
                    local profile = cat and cat.profile or "normal"
                    local bias = PROFILE_BIAS[profile] or 0
                    local cost = math.floor((slot.price or 0) * (1 + bias))
                    local bariga = math.floor(fairPrice * 0.98)
                    local profit = bariga - cost
                    
                    state.slotData[slot.slotRef] = {
                        name = slot.name,
                        price = slot.price,
                        rarity = rarity,
                        fairPrice = fairPrice,
                        profile = profile,
                        profit = profit,
                        slotRef = slot.slotRef,
                    }
                end
            end
        end)
    end
end

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
    local path = PathfindingService:CreatePath({
        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true,
        AgentMaxSlope = 45, WaypointSpacing = 15,
    })
    local ok = pcall(function() path:ComputeAsync(hrp.Position, targetPos) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then return nil end
    return path:GetWaypoints()
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
        else
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

local function buyItemsList(itemsList, onDone)
    if #itemsList == 0 then 
        Notify("Buy", "Список пуст", "Error", nil, 3)
        if onDone then onDone() end
        return 
    end
    
    Notify("Buy", "Покупаем " .. #itemsList .. " предметов", "Info", nil, 2)
    
    local bestSeller, bestDist = nil, math.huge
    local _, hrp = getChar()
    if not hrp then return end
    
    for _, zone in ipairs(ws:GetChildren()) do
        if zone.Name:find("Shop_ShopZone") then
            local seller = zone:FindFirstChild("Seller")
            if seller then
                local shrp = seller:FindFirstChild("HumanoidRootPart")
                if shrp then
                    local d = (shrp.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestSeller = { pos = shrp.Position, cd = shrp:FindFirstChild("ClickDetector") }
                    end
                end
            end
        end
    end
    
    if not bestSeller then 
        Notify("Buy", "Продавец не найден", "Error", nil, 3)
        return 
    end
    
    local idx = 1
    local function nextItem()
        if idx > #itemsList then
            walkTo(bestSeller.pos, function()
                if bestSeller.cd then clickDetector(bestSeller.cd) end
                task.wait(1)
                local shopRemotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
                if shopRemotes then
                    local cp = shopRemotes:FindFirstChild("ConfirmPurchase")
                    if cp then pcall(function() cp:FireServer() end) end
                end
                task.wait(2)
                if onDone then onDone() end
            end, 10)
            return
        end
        
        local item = itemsList[idx]
        idx = idx + 1
        walkTo(item.pos, function()
            if item.detector then clickDetector(item.detector) end
            task.wait(0.5)
            nextItem()
        end, 10)
    end
    
    nextItem()
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

local function countSlotsByRarity()
    local counts = {}
    for _, data in pairs(state.slotData) do
        local r = data.rarity or "nil"
        counts[r] = (counts[r] or 0) + 1
    end
    return counts
end

local function updateChams()
    clearTable(state.chamsHighlights)
    if not state.chams then return end
    local color = RARITY_COLORS[state.chamsRarity] or Color3.fromRGB(255, 180, 30)
    local cnt = 0
    for ref, data in pairs(state.slotData) do
        if data.rarity == state.chamsRarity and ref.Parent then
            local man = getItemMannequin(ref)
            local hl = man and makeHL(man, color, 0.4)
            if hl then state.chamsHighlights[ref] = hl end
            cnt = cnt + 1
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
            task.wait(3)
            if state.chams then updateChams() end
        end
    end)
end

local function stopChams()
    state.chams = false
    if state.chamsTask then pcall(function() task.cancel(state.chamsTask) end) end
    clearTable(state.chamsHighlights)
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
    for _, l in pairs(state.helpBuyLabels) do pcall(function() l:Destroy() end) end
    state.helpBuyLabels = {}
    if not state.helpBuy then return end
    local cnt = 0
    local _, playerHrp = getChar()
    if not playerHrp then return end
    for ref, data in pairs(state.slotData) do
        local man = getItemMannequin(ref)
        local manPos = man and getPos(man)
        local distance = manPos and (manPos - playerHrp.Position).Magnitude
        if ref.Parent and man and man.Parent and distance and distance <= 20 and data.profit and data.profit > 0 then
            cnt = cnt + 1
            local color
            if data.profit >= 4000 then color = Color3.fromRGB(255, 70, 70)
            elseif data.profit >= 1500 then color = Color3.fromRGB(255, 170, 40)
            else color = Color3.fromRGB(70, 230, 120) end
            
            local man = getItemMannequin(ref)
            local hl = man and makeHL(man, color, 0.85)
            if hl then state.helpBuyHighlights[cnt] = hl end
            
            local roi = data.price > 0 and math.floor((data.profit / data.price) * 100) or 0
            local text = "[" .. (data.rarity or "?") .. "] $" .. data.price .. " → +$" .. data.profit .. " (" .. roi .. "%)"
            local bb = man and makeBillboard(man, text, color)
            if bb then state.helpBuyLabels[cnt] = bb end
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
    for ref, data in pairs(state.slotData) do
        local man = getItemMannequin(ref)
        if data.rarity == rarity and ref.Parent and man and man.Parent then
            local pos = getPos(man)
            local cd = getItemDetector(ref)
            if pos and cd then
                table.insert(list, { pos = pos, detector = cd, data = data, ref = ref, mannequin = man })
            end
        end
    end
    return list
end

local function getAllItems()
    local list = {}
    for ref, data in pairs(state.slotData) do
        local man = getItemMannequin(ref)
        if ref.Parent and man and man.Parent and data.profit and data.profit > 0 then
            local pos = getPos(man)
            local cd = getItemDetector(ref)
            if pos and cd then
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
                Notify("Auto Buy", "Нет " .. state.autoBuyRarity .. " в кэше", "Error", nil, 3)
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
            Notify("Full-Sell", "Нет прибыльных в кэше", "Info", nil, 2)
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
    Title = "Редкость", Icon = "solar/star-bold", Values = RARITY_LIST, Default = "Legendary", Multi = false,
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
        Notify("Баланс", tostring(b) .. " ₽", "Info", nil, 3)
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