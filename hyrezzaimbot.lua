-- HyrezzAimbot v2.0 (ESP + Predictive Aimbot + Anti-Detection)
-- by PTB, Nyx Kayrouz 2.2, TMTS

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-
local CONFIG = {
    CIRCLE_RADIUS = 150,
    LOCK_PRIORITY = "CLOSEST", -- "CLOSEST" "CENTER" for you to select lock priority
    WARNING_ENABLED = true,
    MAX_KILLS = 10,
    SPACE_PRESS_COUNT = 8,
    AIMBOT_ENABLED = true,
    ESP_ENABLED = true,
    BULLET_SPEED = 1000,
    MAX_DISTANCE = 300,
    GRAVITY = -150
}

-
local target = nil
local targetVelocity = Vector3.new()
local lastPos = nil
local lastTime = nil
local killCount = 0
local stopAimbot = false
local spacePressCount = 0
local isWaitingToContinue = false
local espLines = {}
local espBoxes = {}
local mainGui = nil
local settingsGui = nil
local circleGui = nil
local warningText = nil
local watermark = nil

-
local function safeCall(func)
    local success, err = pcall(func)
    if not success then
        warn("[Hyrezz] Error: " .. tostring(err))
    end
    return success
end

-
local function createWatermark()
    if watermark then watermark:Destroy() end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WatermarkGUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    watermark = screenGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 30)
    frame.Position = UDim2.new(0, 5, 0, 5)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(200, 0, 0)
    frame.Parent = screenGui
    frame.Name = "WatermarkFrame"

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 180, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "HyrezzAimbot"
    title.TextColor3 = Color3.fromRGB(0, 150, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(0, 200, 0, 15)
    sub.Position = UDim2.new(0, 0, 0, 18)
    sub.Text = "follow nyx kayrouz 2.2 & thanks to ptb TMTS"
    sub.TextColor3 = Color3.fromRGB(200, 200, 200)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 9
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = frame

    -
    task.spawn(function()
        local t = 0
        while watermark and watermark.Parent do
            t = t + 0.02
            local r = 0
            local g = 50 + 150 * (0.5 + 0.5 * math.sin(t))
            local b = 255
            safeCall(function()
                title.TextColor3 = Color3.fromRGB(r, g, b)
            end)
            task.wait(0.05)
        end
    end)
end

-
local function createSettingsGUI()
    if settingsGui then settingsGui:Destroy() end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SettingsGUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    settingsGui = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 320)
    mainFrame.Position = UDim2.new(0.5, -190, 0.6, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(80, 0, 0) -- merah tua
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 4
    mainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0) -- hitam
    mainFrame.Parent = screenGui
    mainFrame.Name = "MainFrame"
    mainFrame.ClipsDescendants = true

    -
    local innerBorder = Instance.new("Frame")
    innerBorder.Size = UDim2.new(1, -8, 1, -8)
    innerBorder.Position = UDim2.new(0, 4, 0, 4)
    innerBorder.BackgroundTransparency = 1
    innerBorder.BorderSizePixel = 2
    innerBorder.BorderColor3 = Color3.fromRGB(180, 0, 0)
    innerBorder.Parent = mainFrame
    innerBorder.Name = "InnerBorder"

    -
    mainFrame.Position = UDim2.new(0.5, -190, 0.8, -160)
    mainFrame.BackgroundTransparency = 1
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween1 = TweenService:Create(mainFrame, tweenInfo, {Position = UDim2.new(0.5, -190, 0.6, -160)})
    local tween2 = TweenService:Create(mainFrame, tweenInfo, {BackgroundTransparency = 0.1})
    tween1:Play()
    tween2:Play()

    -
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "⚙️ HyrezzAimbot Settings"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = mainFrame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    closeBtn.MouseButton1Click:Connect(function()
        if settingsGui then settingsGui:Destroy(); settingsGui = nil end
    end)

    -- Scrolling frame for options
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -50)
    scrollFrame.Position = UDim2.new(0, 5, 0, 40)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 350)
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.Parent = mainFrame

    local function addLabel(text, yPos)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.9, 0, 0, 20)
        label.Position = UDim2.new(0.05, 0, 0, yPos)
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = scrollFrame
        return label
    end

    local function addToggle(text, key, yPos, default)
        local label = addLabel(text, yPos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 60, 0, 20)
        btn.Position = UDim2.new(0.8, 0, 0, yPos)
        btn.Text = default and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Parent = scrollFrame
        btn.MouseButton1Click:Connect(function()
            CONFIG[key] = not CONFIG[key]
            btn.Text = CONFIG[key] and "ON" or "OFF"
            btn.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        end)
        return btn
    end

    local function addSlider(text, key, yPos, min, max, default)
        local label = addLabel(text .. ": " .. tostring(default), yPos)
        local slider = Instance.new("TextBox")
        slider.Size = UDim2.new(0, 60, 0, 20)
        slider.Position = UDim2.new(0.8, 0, 0, yPos)
        slider.Text = tostring(default)
        slider.TextColor3 = Color3.fromRGB(255, 255, 255)
        slider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        slider.BorderSizePixel = 0
        slider.Font = Enum.Font.Gotham
        slider.TextSize = 12
        slider.Parent = scrollFrame
        slider.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local val = tonumber(slider.Text)
                if val and val >= min and val <= max then
                    CONFIG[key] = val
                    label.Text = text .. ": " .. tostring(val)
                else
                    slider.Text = tostring(CONFIG[key])
                end
            end
        end)
        return slider
    end

    local yPos = 5
    addToggle("ESP", "ESP_ENABLED", yPos, CONFIG.ESP_ENABLED)
    yPos = yPos + 30
    addToggle("Aimbot", "AIMBOT_ENABLED", yPos, CONFIG.AIMBOT_ENABLED)
    yPos = yPos + 30
    addToggle("Warning (Back)", "WARNING_ENABLED", yPos, CONFIG.WARNING_ENABLED)
    yPos = yPos + 30
    addSlider("Circle Radius", "CIRCLE_RADIUS", yPos, 50, 300, CONFIG.CIRCLE_RADIUS)
    yPos = yPos + 30

    local priorityLabel = addLabel("Priority: " .. CONFIG.LOCK_PRIORITY, yPos)
    local priorityBtn = Instance.new("TextButton")
    priorityBtn.Size = UDim2.new(0, 80, 0, 20)
    priorityBtn.Position = UDim2.new(0.7, 0, 0, yPos)
    priorityBtn.Text = CONFIG.LOCK_PRIORITY
    priorityBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    priorityBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    priorityBtn.BorderSizePixel = 0
    priorityBtn.Font = Enum.Font.GothamBold
    priorityBtn.TextSize = 12
    priorityBtn.Parent = scrollFrame
    priorityBtn.MouseButton1Click:Connect(function()
        CONFIG.LOCK_PRIORITY = (CONFIG.LOCK_PRIORITY == "CLOSEST") and "CENTER" or "CLOSEST"
        priorityBtn.Text = CONFIG.LOCK_PRIORITY
        priorityLabel.Text = "Priority: " .. CONFIG.LOCK_PRIORITY
    end)
    yPos = yPos + 30

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0.6, 0, 0, 30)
    confirmBtn.Position = UDim2.new(0.2, 0, 0, yPos)
    confirmBtn.Text = " SAVE & START"
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    confirmBtn.BorderSizePixel = 0
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.TextSize = 14
    confirmBtn.Parent = scrollFrame
    confirmBtn.MouseButton1Click:Connect(function()
        if settingsGui then settingsGui:Destroy(); settingsGui = nil end
        warn("[Hyrezz] Settings applied")
    end)

    -
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 40)
end

-
local function createCircle()
    if circleGui then circleGui:Destroy() end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CircleGUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    circleGui = screenGui

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, CONFIG.CIRCLE_RADIUS * 2, 0, CONFIG.CIRCLE_RADIUS * 2)
    circle.Position = UDim2.new(0.5, -CONFIG.CIRCLE_RADIUS, 0.5, -CONFIG.CIRCLE_RADIUS)
    circle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    circle.BackgroundTransparency = 0.8
    circle.BorderSizePixel = 2
    circle.BorderColor3 = Color3.fromRGB(255, 0, 0)
    circle.Parent = screenGui
    circle.Name = "Circle"
    circle.Visible = CONFIG.ESP_ENABLED

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 0, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    })
    gradient.Rotation = 0
    gradient.Parent = circle

    task.spawn(function()
        local rot = 0
        while circleGui and circleGui.Parent do
            rot = (rot + 0.5) % 360
            safeCall(function() gradient.Rotation = rot end)
            task.wait(0.05)
        end
    end)

    return screenGui
end

-
local function createESPLine(player)
    if espLines[player] then safeCall(function() espLines[player]:Destroy() end) end
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 2, 0, 200)
    line.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    line.BorderSizePixel = 0
    line.Parent = LocalPlayer:WaitForChild("PlayerGui")
    line.Name = "ESPLine_" .. player.Name
    line.ZIndex = 999
    espLines[player] = line
end

local function createESPBox(player)
    if espBoxes[player] then safeCall(function() espBoxes[player]:Destroy() end) end
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 50, 0, 70)
    box.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    box.BackgroundTransparency = 0.7
    box.BorderSizePixel = 2
    box.BorderColor3 = Color3.fromRGB(0, 255, 0)
    box.Parent = LocalPlayer:WaitForChild("PlayerGui")
    box.Name = "ESPBox_" .. player.Name
    box.ZIndex = 999
    espBoxes[player] = box
end

-
local function getTargets()
    local targets = {}
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not playerPos then return targets end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local head = player.Character:FindFirstChild("Head")
            if not hrp or not head then continue end
            local pos = hrp.Position
            local headPos = head.Position
            local dist = (pos - playerPos).Magnitude
            if dist > CONFIG.MAX_DISTANCE then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
            if not onScreen then continue end
            local screenPosHead, _ = Camera:WorldToViewportPoint(headPos)
            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude

            -
            local visible = true
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {player.Character, LocalPlayer.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            local ray = Workspace:Raycast(Camera.CFrame.Position, headPos - Camera.CFrame.Position, raycastParams)
            if ray then visible = false end

            table.insert(targets, {
                player = player,
                hrp = hrp,
                head = head,
                pos = pos,
                headPos = headPos,
                screenPos = Vector2.new(screenPos.X, screenPos.Y),
                screenHeadPos = Vector2.new(screenPosHead.X, screenPosHead.Y),
                dist = dist,
                screenDist = screenDist,
                visible = visible,
                velocity = targetVelocity
            })
        end
    end
    return targets
end

-
local function updateVelocity(targetData)
    if not targetData then return end
    local now = tick()
    local pos = targetData.pos
    if lastPos and lastTime then
        local dt = now - lastTime
        if dt > 0 then
            targetVelocity = (pos - lastPos) / dt
        end
    end
    lastPos = pos
    lastTime = now
end

-
local function predictAim(targetData)
    local headPos = targetData.headPos
    local vel = targetVelocity
    local dist = targetData.dist
    local bulletSpeed = CONFIG.BULLET_SPEED
    local time = dist / bulletSpeed
    local drop = 0.5 * CONFIG.GRAVITY * time * time
    return headPos + vel * time + Vector3.new(0, drop, 0)
end

-
local function showKillWarning()
    if warningText then warningText:Destroy() end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KillWarningGUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    warningText = screenGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 80)
    frame.Position = UDim2.new(0.5, -200, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    frame.Parent = screenGui

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.Text = " TERLALU BANYAK KILL! \nTekan SPACE " .. CONFIG.SPACE_PRESS_COUNT .. " kali untuk lanjut"
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.TextWrapped = true
    text.TextScaled = true
    text.Parent = frame
end

-
local function updateESP()
    if not CONFIG.ESP_ENABLED then
        for player, line in pairs(espLines) do safeCall(function() line:Destroy() end) end
        espLines = {}
        for player, box in pairs(espBoxes) do safeCall(function() box:Destroy() end) end
        espBoxes = {}
        if circleGui then circleGui.Enabled = false end
        return
    end
    if circleGui then 
        circleGui.Enabled = true
        local circle = circleGui:FindFirstChild("Circle")
        if circle then circle.Visible = true end
    end

    local targets = getTargets()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not playerPos then return end

    local closestTarget = nil
    local minDist = math.huge

    for _, data in ipairs(targets) do
        local player = data.player
        local screenPos = data.screenPos
        local visible = data.visible
        local dist = data.dist

        updateVelocity(data)

        if not espLines[player] then createESPLine(player) end
        if not espBoxes[player] then createESPBox(player) end
        local line = espLines[player]
        local box = espBoxes[player]

        -
        local topCenter = Vector2.new(Camera.ViewportSize.X / 2, 0)
        line.Position = UDim2.new(0, topCenter.X, 0, topCenter.Y)
        line.Size = UDim2.new(0, 2, 0, (screenPos - topCenter).Magnitude)
        line.Rotation = math.deg(math.atan2(screenPos.Y - topCenter.Y, screenPos.X - topCenter.X))
        line.Visible = true

        -
        local boxSize = 50
        local boxPos = screenPos - Vector2.new(boxSize/2, boxSize/2)
        box.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y)
        box.Size = UDim2.new(0, boxSize, 0, boxSize)
        box.Visible = true

        if visible then
            local blink = math.sin(tick() * 4) > 0.5
            box.BorderColor3 = blink and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 200, 0)
            line.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        else
            box.BorderColor3 = Color3.fromRGB(255, 0, 0)
            line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end

        if data.screenDist < minDist then
            minDist = data.screenDist
            closestTarget = data
        end
    end

    -
    for player, line in pairs(espLines) do
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            safeCall(function() line:Destroy() end)
            espLines[player] = nil
        end
    end
    for player, box in pairs(espBoxes) do
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            safeCall(function() box:Destroy() end)
            espBoxes[player] = nil
        end
    end

    -
    if CONFIG.AIMBOT_ENABLED and not stopAimbot and UserInputService:IsKeyDown(Enum.KeyCode.MouseButton2) then
        if closestTarget then
            local predicted = predictAim(closestTarget)
            safeCall(function()
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, predicted)
            end)
        end
    end

    -
    if target and target.Character and target.Character:FindFirstChild("Humanoid") then
        if target.Character.Humanoid.Health <= 0 then
            killCount = killCount + 1
            target = nil
            if killCount >= CONFIG.MAX_KILLS and not isWaitingToContinue then
                isWaitingToContinue = true
                stopAimbot = true
                spacePressCount = 0
                showKillWarning()
                task.wait(10)
                if isWaitingToContinue then
                    isWaitingToContinue = false
                    stopAimbot = false
                    killCount = 0
                    if warningText then warningText:Destroy(); warningText = nil end
                end
            end
        end
    end
end

-
local function setupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -
        if input.KeyCode == Enum.KeyCode.Space and isWaitingToContinue then
            spacePressCount = spacePressCount + 1
            if spacePressCount >= CONFIG.SPACE_PRESS_COUNT then
                isWaitingToContinue = false
                stopAimbot = false
                killCount = 0
                if warningText then warningText:Destroy(); warningText = nil end
                warn("[Hyrezz] Continued")
            end
        end

        -
        if input.KeyCode == Enum.KeyCode.RightControl then
            if settingsGui then settingsGui:Destroy(); settingsGui = nil
            else createSettingsGUI() end
        end
    end)
end

-
local function onPlayerRemoved(player)
    if espLines[player] then safeCall(function() espLines[player]:Destroy() end) end
    if espBoxes[player] then safeCall(function() espBoxes[player]:Destroy() end) end
end
Players.PlayerRemoving:Connect(onPlayerRemoved)

-
local function start()
    createWatermark()
    createCircle()
    createSettingsGUI()
    setupKeybinds()
    RunService.Heartbeat:Connect(updateESP)
    warn("[Hyrezz] Aimbot + ESP Loaded!")
    warn("[Hyrezz] Right Ctrl - Settings | Right Click - Aim | Space (8x) - Continue after kill warning")
end

start()
