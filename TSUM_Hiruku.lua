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
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function Notify(title, content, ntype, icon, duration)
    pcall(function()
        Fluent:Notify({ Title = title, Content = content, Type = ntype or "Info", Icon = icon, Duration = duration or 3 })
    end)
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
    Title = "Hiruku Lua — TSUM", SubTitle = "Resale Hunter", Version = "v1.1.0",
    TabWidth = 130, Size = UDim2.fromOffset(580,410), Acrylic = true,
    Theme = "HirukuViolet", MinimizeKey = Enum.KeyCode.LeftControl, Search = true,
    Icons = "solar/planet-bold", UserInfoTop = true, UserInfoTitle = "Welcome",
    UserInfoSubtitle = LocalPlayer.DisplayName, UserInfoColor = Color3.fromRGB(185,70,255),
})

pcall(function() Fluent:SetErrorHandler(function(msg) Notify("Error", tostring(msg), "Error", nil, 5) end) end)

local Tabs = {
    AutoBuy = Window:AddTab({ Title = "Auto Buy", Icon = "solar/cart-bold" }),
    HelpBuy = Window:AddTab({ Title = "Help Buy", Icon = "solar/lightbulb-bold" }),
    Chams = Window:AddTab({ Title = "Chams Items", Icon = "solar/eye-bold" }),
    FullSell = Window:AddTab({ Title = "Auto Full-Sell", Icon = "solar/dollar-bold" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "solar/tuning-2-bold" }),
}

local state = {
    autoBuy = false, autoBuyRarity = "Legendary", autoBuyConn = nil,
    helpBuy = false, helpBuyConn = nil, helpBuyDrawings = {}, helpBuyHighlights = {},
    chams = false, chamsRarity = "Legendary", chamsConn = nil, chamsHighlights = {},
    fullSell = false, fullSellConn = nil,
    autoWalk = false, autoWalkConn = nil, autoWalkTarget = nil,
    lastAction = 0,
    itemCache = {},
    lastScan = 0,
}

local RARITIES = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "YXclusive"}
local RARITY_COLORS = {
    Common = Color3.fromRGB(180,180,180),
    Uncommon = Color3.fromRGB(100,200,100),
    Rare = Color3.fromRGB(100,150,255),
    Epic = Color3.fromRGB(180,100,255),
    Legendary = Color3.fromRGB(255,180,50),
    Mythic = Color3.fromRGB(255,80,80),
    YXclusive = Color3.fromRGB(20,20,20),
}

local function getChar()
    local c = LocalPlayer.Character
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return nil end
    return c, hrp, hum
end

local function getBalance()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local n = v.Name:lower()
            if n == "cash" or n == "money" or n == "balance" or n == "coins" then
                return tonumber(v.Value) or 0
            end
        end
    end
    return 0
end

local function getItemData(obj)
    local rarity = obj:GetAttribute("Rarity") or obj:GetAttribute("rarity") or obj:GetAttribute("RARE")
    local buyPrice = obj:GetAttribute("BuyPrice") or obj:GetAttribute("Price") or obj:GetAttribute("buyPrice")
    local sellPrice = obj:GetAttribute("SellPrice") or obj:GetAttribute("ResellPrice") or obj:GetAttribute("sellPrice")
    local itemName = obj:GetAttribute("ItemName") or obj:GetAttribute("Name") or obj.Name

    if not rarity then
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("StringValue") then
                local n = d.Name:lower()
                if n:find("rarity") then rarity = d.Value end
                if n:find("name") and itemName == obj.Name then itemName = d.Value end
            end
            if d:IsA("NumberValue") or d:IsA("IntValue") then
                local n = d.Name:lower()
                if n:find("buy") or n:find("price") then buyPrice = tonumber(d.Value) end
                if n:find("sell") or n:find("resell") then sellPrice = tonumber(d.Value) end
            end
        end
    end

    if rarity then
        rarity = tostring(rarity)
        for _, r in ipairs(RARITIES) do
            if rarity:lower() == r:lower() then rarity = r break end
        end
    end

    return {
        obj = obj,
        name = itemName,
        rarity = rarity,
        buyPrice = tonumber(buyPrice),
        sellPrice = tonumber(sellPrice),
    }
end

local function isItemObject(obj)
    if obj:IsA("Model") then
        local n = obj.Name:lower()
        if n:find("item") or n:find("cloth") or n:find("accessor") or n:find("shirt")
           or n:find("pants") or n:find("hat") or n:find("shoe") or n:find("bag")
           or n:find("jacket") or n:find("hoodie") or n:find("sneaker") or n:find("watch") then
            return true
        end
        for _, d in ipairs(obj:GetChildren()) do
            if d:IsA("Model") and (d.Name:lower():find("item") or d.Name:lower():find("cloth")) then
                return true
            end
        end
    end
    return false
end

local function getModelPos(obj)
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") then
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if pp then return pp.Position end
    end
    return nil
end

local function scanItems()
    local now = tick()
    if now - state.lastScan < 2 then return state.itemCache end
    state.lastScan = now

    local items = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isItemObject(obj) then
            local data = getItemData(obj)
            local pos = getModelPos(obj)
            if pos then
                data.pos = pos
                table.insert(items, data)
            end
        end
    end
    state.itemCache = items
    return items
end

local function findItemsByRarity(rarity)
    local all = scanItems()
    local filtered = {}
    for _, item in ipairs(all) do
        if item.rarity == rarity then
            table.insert(filtered, item)
        end
    end
    return filtered
end

local function findNearest(items, fromPos)
    if #items == 0 then return nil end
    local best = items[1]
    local bestDist = (items[1].pos - fromPos).Magnitude
    for i = 2, #items do
        local d = (items[i].pos - fromPos).Magnitude
        if d < bestDist then
            best = items[i]
            bestDist = d
        end
    end
    return best
end

local function findSeller()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("seller") or n:find("vendor") or n:find("shop") or n:find("trade")
               or n:find("market") or n:find("resell") or n:find("buyer") then
                local pos = getModelPos(obj)
                if pos then return { obj = obj, pos = pos, name = obj.Name } end
            end
        end
    end
    return nil
end

local function fireBuy(item)
    local bought = false
    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            local n = r.Name:lower()
            if n:find("buy") or n:find("purchase") or n:find("order") or n:find("resell") then
                pcall(function()
                    if r:IsA("RemoteFunction") then r:InvokeServer(item.obj)
                    else r:FireServer(item.obj) end
                end)
                bought = true
            end
        end
    end
    if not bought then
        local pp = item.obj:FindFirstChildOfClass("ProximityPrompt")
        if pp then pcall(function() fireproximityprompt(pp) end) end
    end
    return bought
end

local function fireSell()
    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            local n = r.Name:lower()
            if n:find("sell") or n:find("resell") or n:find("trade") then
                pcall(function()
                    if r:IsA("RemoteFunction") then r:InvokeServer()
                    else r:FireServer() end
                end)
            end
        end
    end
end

local function startAutoWalk(targetPos, onArrive, stopDist)
    stopDist = stopDist or 8
    state.autoWalk = true
    state.autoWalkTarget = targetPos
    if state.autoWalkConn then state.autoWalkConn:Disconnect() end
    state.autoWalkConn = RunService.Heartbeat:Connect(function()
        if not state.autoWalk then return end
        local _, hrp, hum = getChar()
        if not hrp or not hum then return end
        local target = state.autoWalkTarget
        if not target then state.autoWalk = false return end
        local dist = (target - hrp.Position).Magnitude
        if dist < stopDist then
            hum:Move(Vector3.zero, false)
            state.autoWalk = false
            if state.autoWalkConn then state.autoWalkConn:Disconnect() state.autoWalkConn = nil end
            if onArrive then onArrive() end
            return
        end
        local dir = (target - hrp.Position).Unit
        hum:Move(dir, false)
    end)
end

local function stopAutoWalk()
    state.autoWalk = false
    state.autoWalkTarget = nil
    if state.autoWalkConn then state.autoWalkConn:Disconnect() state.autoWalkConn = nil end
    local _, _, hum = getChar()
    if hum then hum:Move(Vector3.zero, false) end
end

local function createHighlight(obj, color)
    local hl = Instance.new("Highlight")
    hl.Name = "HirukuHL"
    hl.Adornee = obj
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = obj
    return hl
end

local function clearHighlights(t)
    for _, hl in pairs(t) do
        pcall(function() hl:Destroy() end)
    end
    for k in pairs(t) do t[k] = nil end
end

local function startAutoBuy()
    if state.autoBuy then return end
    state.autoBuy = true
    state.autoBuyConn = RunService.Heartbeat:Connect(function()
        if not state.autoBuy then return end
        local now = tick()
        if now - state.lastAction < 1.5 then return end
        state.lastAction = now

        local _, hrp = getChar()
        if not hrp then return end

        local items = findItemsByRarity(state.autoBuyRarity)
        if #items == 0 then return end

        local nearest = findNearest(items, hrp.Position)
        if not nearest then return end

        if (nearest.pos - hrp.Position).Magnitude < 12 then
            fireBuy(nearest)
            task.wait(0.8)
        else
            startAutoWalk(nearest.pos, nil, 10)
        end
    end)
    Notify("Auto Buy", "Редкость: " .. state.autoBuyRarity, "Success", nil, 3)
end

local function stopAutoBuy()
    state.autoBuy = false
    if state.autoBuyConn then state.autoBuyConn:Disconnect() state.autoBuyConn = nil end
    stopAutoWalk()
    Notify("Auto Buy", "Выключен", "Info", nil, 2)
end

local function startHelpBuy()
    if state.helpBuy then return end
    state.helpBuy = true
    state.helpBuyDrawings = {}
    state.helpBuyHighlights = {}

    state.helpBuyConn = RunService.RenderStepped:Connect(function()
        if not state.helpBuy then return end
        clearHighlights(state.helpBuyHighlights)
        for _, d in pairs(state.helpBuyDrawings) do
            pcall(function() d:Remove() end)
        end
        state.helpBuyDrawings = {}

        local all = scanItems()
        local profitable = {}
        for _, item in ipairs(all) do
            if item.buyPrice and item.sellPrice and item.sellPrice > item.buyPrice then
                table.insert(profitable, item)
            end
        end

        for i, item in ipairs(profitable) do
            local hl = createHighlight(item.obj, Color3.fromRGB(0, 255, 100))
            state.helpBuyHighlights["hl" .. i] = hl

            local screenPos, onScreen = Camera:WorldToViewportPoint(item.pos)
            if onScreen then
                local line = Drawing.new("Line")
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(screenPos.X, screenPos.Y)
                line.Color = Color3.fromRGB(0, 255, 100)
                line.Thickness = 2
                line.Transparency = 0.6
                line.Visible = true
                state.helpBuyDrawings[i] = line
            end
        end
    end)

    Notify("Help Buy", "Включён", "Success", nil, 3)
end

local function stopHelpBuy()
    state.helpBuy = false
    if state.helpBuyConn then state.helpBuyConn:Disconnect() state.helpBuyConn = nil end
    clearHighlights(state.helpBuyHighlights)
    for _, d in pairs(state.helpBuyDrawings) do
        pcall(function() d:Remove() end)
    end
    state.helpBuyDrawings = {}
    Notify("Help Buy", "Выключен", "Info", nil, 2)
end

local function startChams()
    if state.chams then return end
    state.chams = true
    state.chamsHighlights = {}
    state.chamsConn = RunService.RenderStepped:Connect(function()
        if not state.chams then return end
        clearHighlights(state.chamsHighlights)
        local items = findItemsByRarity(state.chamsRarity)
        local color = RARITY_COLORS[state.chamsRarity] or Color3.fromRGB(255, 60, 196)
        for i, item in ipairs(items) do
            local hl = createHighlight(item.obj, color)
            state.chamsHighlights["hl" .. i] = hl
        end
    end)
    Notify("Chams", "Редкость: " .. state.chamsRarity, "Success", nil, 3)
end

local function stopChams()
    state.chams = false
    if state.chamsConn then state.chamsConn:Disconnect() state.chamsConn = nil end
    clearHighlights(state.chamsHighlights)
    Notify("Chams", "Выключен", "Info", nil, 2)
end

local function startFullSell()
    if state.fullSell then return end
    state.fullSell = true
    state.fullSellConn = RunService.Heartbeat:Connect(function()
        if not state.fullSell then return end
        local now = tick()
        if now - state.lastAction < 2.5 then return end
        state.lastAction = now

        local _, hrp = getChar()
        if not hrp then return end

        local all = scanItems()
        local profitable = {}
        for _, item in ipairs(all) do
            if item.buyPrice and item.sellPrice and item.sellPrice > item.buyPrice then
                table.insert(profitable, item)
            end
        end

        if #profitable == 0 then
            Notify("Full-Sell", "Нет выгодных предметов", "Info", nil, 2)
            return
        end

        table.sort(profitable, function(a, b)
            return (b.sellPrice - b.buyPrice) > (a.sellPrice - a.buyPrice)
        end)

        local balance = getBalance()
        local spent = 0
        for _, item in ipairs(profitable) do
            if spent + item.buyPrice > balance then break end
            startAutoWalk(item.pos, function()
                fireBuy(item)
                spent = spent + item.buyPrice
            end, 10)
            task.wait(0.5)
        end

        local seller = findSeller()
        if seller then
            startAutoWalk(seller.pos, function()
                fireSell()
                Notify("Full-Sell", "Продано на: " .. spent, "Success", nil, 3)
            end, 10)
        end
    end)
    Notify("Full-Sell", "Включён", "Success", nil, 3)
end

local function stopFullSell()
    state.fullSell = false
    if state.fullSellConn then state.fullSellConn:Disconnect() state.fullSellConn = nil end
    stopAutoWalk()
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
    if grad and grad.Parent then
        grad.Rotation = (grad.Rotation + dt * 30) % 360
    end
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
            local newState = not mainBtn:GetAttribute("Locked")
            mainBtn:SetAttribute("Locked", newState)
            Notify(newState and "Locked" or "Unlocked", newState and "Закреплено" or "Можно двигать", "Info", nil, 2)
        end
    end)
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
            holdingDrag = false
        end
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

local function PlaySound(soundId)
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. soundId
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
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
    local origSize = frame.Size
    frame.Size = UDim2.new(origSize.X.Scale, 0, origSize.Y.Scale, 0)
    pcall(function()
        TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = origSize}):Play()
    end)
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
    local origSize = UDim2.new(0, 60, 0, 60)
    local pressSize = UDim2.new(0, 48, 0, 48)
    pcall(function()
        TweenService:Create(mainBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = pressSize}):Play()
    end)
    task.wait(0.08)
    pcall(function()
        TweenService:Create(mainBtn, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = origSize}):Play()
    end)
end)

local RARITY_LIST = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "YXclusive"}

local secAutoBuy = Tabs.AutoBuy:AddSection("Auto Buy", "solar/cart-bold")
secAutoBuy:AddDropdown("AutoBuyRarity", {
    Title = "Редкость",
    Description = "Скупает предметы этой редкости",
    Icon = "solar/star-bold",
    Values = RARITY_LIST,
    Default = "Legendary",
    Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do state.autoBuyRarity = k break end
        else state.autoBuyRarity = v end
    end
})
secAutoBuy:AddToggle("AutoBuy", { Title = "Auto Buy", Description = "Идёт к ближайшему и покупает", Icon = "solar/cart-bold", Default = false, Callback = function(v) if v then startAutoBuy() else stopAutoBuy() end end })

local secHelpBuy = Tabs.HelpBuy:AddSection("Help Buy", "solar/lightbulb-bold")
secHelpBuy:AddToggle("HelpBuy", { Title = "Help Buy", Description = "Подсветка выгодных предметов", Icon = "solar/lightbulb-bold", Default = false, Callback = function(v) if v then startHelpBuy() else stopHelpBuy() end end })

local secChams = Tabs.Chams:AddSection("Chams Items", "solar/eye-bold")
secChams:AddDropdown("ChamsRarity", {
    Title = "Редкость",
    Icon = "solar/star-bold",
    Values = RARITY_LIST,
    Default = "Legendary",
    Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do state.chamsRarity = k break end
        else state.chamsRarity = v end
    end
})
secChams:AddToggle("Chams", { Title = "Chams Items", Description = "Подсветка предметов через стены", Icon = "solar/eye-bold", Default = false, Callback = function(v) if v then startChams() else stopChams() end end })

local secFullSell = Tabs.FullSell:AddSection("Auto Full-Sell", "solar/dollar-bold")
secFullSell:AddToggle("FullSell", { Title = "Auto Full-Sell", Description = "Скупает и продаёт всё выгодное", Icon = "solar/dollar-bold", Default = false, Callback = function(v) if v then startFullSell() else stopFullSell() end end })
secFullSell:AddButton({
    Title = "Найти продавца",
    Description = "Ищет seller/vendor в workspace",
    Icon = "solar/map-point-bold",
    Callback = function()
        local seller = findSeller()
        if seller then
            Notify("Seller", "Найден: " .. seller.name, "Success", nil, 3)
        else
            Notify("Seller", "Не найден", "Error", nil, 3)
        end
    end
})

local secSet = Tabs.Settings:AddSection("Font", "solar/text-bold")
local FONT_LIST = {"Gotham", "GothamBold", "SourceSans", "SourceSansBold", "Code", "Roboto", "RobotoCondensed", "Ubuntu", "Arial", "Antique", "Fantasy", "SciFi", "Cartoon"}

local function applyFontToGui(fontName)
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
    Notify("Font", "Применён: " .. fontName, "Success", nil, 2)
end

secSet:AddDropdown("FontPicker", {
    Title = "Font",
    Description = "Шрифт только для меню",
    Icon = "solar/text-bold",
    Values = FONT_LIST,
    Default = "Gotham",
    Multi = false,
    Callback = function(v)
        if type(v) == "table" then for k in pairs(v) do applyFontToGui(k) break end
        else applyFontToGui(v) end
    end
})

Fluent:SetTheme("HirukuViolet")

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    local _, _, hum = getChar()
    if hum then hum:Move(Vector3.zero, false) end
end)

Notify("Hiruku Lua — TSUM", "Загружен", "Success", "solar/planet-bold", 4)
task.delay(0.5, function() pcall(function() Window:SelectTab(1) end) end)