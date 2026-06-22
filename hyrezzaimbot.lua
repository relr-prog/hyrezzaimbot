-- HyrezzAimbot v3.0 (Optimized for Velocity PC)
-- by PTB, Nyx Kayrouz 2.2, TMTS
-- Full ESP + Predictive Aimbot + Anti-Detection
-- GitHub: https://github.com/relr-prog/hyrezzaimbot

-- ===== VERIFY EXECUTION =====
warn("[Hyrezz] Script loaded! Checking environment...")

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- ===== SAFE GET =====
local function safeGet(service)
    local success, result = pcall(function()
        return service
    end)
    return success and result or nil
end

-- ===== CONFIG DEFAULT =====
local CONFIG = {
    CIRCLE_RADIUS = 150,
    LOCK_PRIORITY = "CLOSEST",
    WARNING_ENABLED = true,
    MAX_KILLS = 10,
    SPACE_PRESS_COUNT = 8,
    AIMBOT_ENABLED = true,
    ESP_ENABLED = true,
    BULLET_SPEED = 1000,
    MAX_DISTANCE = 300,
    GRAVITY = -150
}

-- ===== VARIABLES =====
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
local espEnabled = true
local aimbotEnabled = true

-- ===== SAFE CALL =====
local function safeCall(func)
    local success, err = pcall(func)
    if not success then
        warn("[Hyrezz] Error: " .. tostring(err))
    end
    return success
end

-- ===== WATERMARK (Velocity Optimized) =====
local function createWatermark()
    if watermark then safeCall(function() watermark:Destroy() end) end
    local screenGui = safeCall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "WatermarkGUI"
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        gui.ResetOnSpawn = false
        return gui
    end)
    if not screenGui then return end
    watermark = screenGui

    local frame = safeCall(function()
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 250, 0, 30)
        f.Position = UDim2.new(0, 5, 0, 5)
        f.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        f.BackgroundTransparency = 0.3
        f.BorderSizePixel = 2
        f.BorderColor3 = Color3.fromRGB(200, 0, 0)
        f.Parent = screenGui
        f.Name = "WatermarkFrame"
        return f
    end)
    if not frame then return end

    safeCall(function()
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
    end)

    -- Animate watermark color
    task.spawn(function()
        local t = 0
        while watermark and watermark.Parent do
            t = t + 0.02
            local r = 0
            local g = 50 + 150 * (0.5 + 0.5 * math.sin(t))
            local b = 255
            safeCall(function()
                local title = watermark:FindFirstChild("WatermarkFrame") and watermark.WatermarkFrame:FindFirstChild("TextLabel")
                if title then
                    title.TextColor3 = Color3.fromRGB(r, g, b)
                end
            end)
            task.wait(0.05)
        end
    end)
end

-- ===== SETTINGS GUI (Velocity Optimized) =====
local function createSettingsGUI()
    if settingsGui then safeCall(function() settingsGui:Destroy() end) end
    local screenGui = safeCall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "SettingsGUI"
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        gui.ResetOnSpawn = false
        return gui
    end)
    if not screenGui then return end
    settingsGui = screenGui

    local mainFrame = safeCall(function()
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 380, 0, 320)
        f.Position = UDim2.new(0.5, -190, 0.6, -160)
        f.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        f.BackgroundTransparency = 0.1
        f.BorderSizePixel = 4
        f.BorderColor3 = Color3.fromRGB(0, 0, 0)ransparency = 0.7
        b.BorderSizePixel = 2
        b.BorderColor3 = Color3.fromRGB(0, 255, 0)
        b.Parent = LocalPlayer:WaitForChild("PlayerGui")
        b.Name = "ESPBox_" .. player.Name
        b.ZIndex = 999
        return b
    end)
    if box then espBoxes[player] = box end
end

-- ===== GET TARGETS =====
local function getTargets()
    local targets = {}
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local playerPos = safeCall(function()
        return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    end)
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

            local screenPos = safeCall(function()
                return Camera:WorldToViewportPoint(pos)
            end)
            if not screenPos then continue end
            local onScreen = screenPos
            if not onScreen then continue end
            local screenPosHead = safeCall(function()
                return Camera:WorldToViewportPoint(headPos)
            end)
            if not screenPosHead then continue end

            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude

            -- Visibility Check
            local visible = true
            safeCall(function()
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {player.Character, LocalPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                local ray = Workspace:Raycast(Camera.CFrame.Position, headPos - Camera.CFrame.Position, raycastParams)
                if ray then visible = false end
            end)

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

-- ===== UPDATE VELOCITY =====
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

-- ===== PREDICTIVE AIM =====
local function predictAim(targetData)
    local headPos = targetData.headPos
    local vel = targetVelocity
    local dist = targetData.dist
    local bulletSpeed = CONFIG.BULLET_SPEED
    local time = dist / bulletSpeed
    local drop = 0.5 * CONFIG.GRAVITY * time * time
    return headPos + vel * time + Vector3.new(0, drop, 0)
end

-- ===== KILL WARNING =====
local function showKillWarning()
    if warningText then safeCall(function() warningText:Destroy() end) end
    local screenGui = safeCall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "KillWarningGUI"
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        gui.ResetOnSpawn = false
        return gui
    end)
    if not screenGui then return end
    warningText = screenGui

    local frame = safeCall(function()
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 400, 0, 80)
        f.Position = UDim2.new(0.5, -200, 0.4, 0)
        f.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        f.BackgroundTransparency = 0.4
        f.BorderSizePixel = 2
        f.BorderColor3 = Color3.fromRGB(0, 0, 0)
        f.Parent = screenGui
        return f
    end)
    if not frame then return end

    safeCall(function()
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Text = "⚠️ TERLALU BANYAK KILL! ⚠️\nTekan SPACE " .. CONFIG.SPACE_PRESS_COUNT .. " kali untuk lanjut"
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.GothamBold
        text.TextSize = 16
        text.TextWrapped = true
        text.TextScaled = true
        text.Parent = frame
    end)
end

-- ===== UPDATE ESP & AIMBOT =====
local function updateESP()
    if not espEnabled then
        for player, line in pairs(espLines) do safeCall(function() line:Destroy() end) end
        espLines = {}
        for player, box in pairs(espBoxes) do safeCall(function() box:Destroy() end) end
        espBoxes = {}
        if circleGui then safeCall(function() circleGui.Enabled = false end) end
        return
    end
    if circleGui then safeCall(function() circleGui.Enabled = true end) end

    local targets = getTargets()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local playerPos = safeCall(function()
        return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    end)
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

        -- Line from top-center to target
        local topCenter = Vector2.new(Camera.ViewportSize.X / 2, 0)
        if line then
            line.Position = UDim2.new(0, topCenter.X, 0, topCenter.Y)
            line.Size = UDim2.new(0, 2, 0, (screenPos - topCenter).Magnitude)
            line.Rotation = math.deg(math.atan2(screenPos.Y - topCenter.Y, screenPos.X - topCenter.X))
            line.Visible = true
        end

        -- Box
        if box then
            local boxSize = 50
            local boxPos = screenPos - Vector2.new(boxSize/2, boxSize/2)
            box.Position = UDim2.new(0, boxPos.X, 0, boxPos.Y)
            box.Size = UDim2.new(0, boxSize, 0, boxSize)
            box.Visible = true

            if visible then
                local blink = math.sin(tick() * 4) > 0.5
                box.BorderColor3 = blink and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 200, 0)
                if line then line.BackgroundColor3 = Color3.fromRGB(0, 255, 0) end
            else
                box.BorderColor3 = Color3.fromRGB(255, 0, 0)
                if line then line.BackgroundColor3 = Color3.fromRGB(255, 0, 0) end
            end
        end

        if data.screenDist < minDist then
            minDist = data.screenDist
            closestTarget = data
        end
    end

    -- Clean up disconnected players
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

    -- Aimbot
    if aimbotEnabled and not stopAimbot and UserInputService:IsKeyDown(Enum.KeyCode.MouseButton2) then
        if closestTarget then
            local predicted = predictAim(closestTarget)
            safeCall(function()
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, predicted)
            end)
        end
    end

    -- Kill tracking
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

-- ===== KEYBINDS =====
local function setupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        -- Space continue
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

        -- Toggle settings
        if input.KeyCode == Enum.KeyCode.RightControl then
            if settingsGui then safeCall(function() settingsGui:Destroy() end); settingsGui = nil
            else createSettingsGUI() end
        end
    end)
end

-- ===== PLAYER REMOVED =====
local function onPlayerRemoved(player)
    if espLines[player] then safeCall(function() espLines[player]:Destroy() end) end
    if espBoxes[player] then safeCall(function() espBoxes[player]:Destroy() end) end
end
Players.PlayerRemoving:Connect(onPlayerRemoved)

-- ===== START =====
local function start()
    warn("[Hyrezz] Initializing...")
    
    -- Check if LocalPlayer is valid
    if not LocalPlayer or not LocalPlayer.Character then
        warn("[Hyrezz] Waiting for character...")
        LocalPlayer.CharacterAdded:Wait()
    end

    -- Create GUI elements
    createWatermark()
    createCircle()
    createSettingsGUI()
    setupKeybinds()
    
    -- Start the update loop
    RunService.Heartbeat:Connect(updateESP)
    
    -- Enable by default
    espEnabled = true
    aimbotEnabled = true
    
    warn("[Hyrezz] Aimbot + ESP Loaded!")
    warn("[Hyrezz] Right Ctrl - Settings | Right Click - Aim | Space (8x) - Continue after kill warning")
    warn("[Hyrezz] If nothing appears, try pressing Right Ctrl to open settings")
end

-- ===== SAFE START =====
local success, err = pcall(start)
if not success then
    warn("[Hyrezz] Failed to start: " .. tostring(err))
end

warn("[Hyrezz] Script execution complete! Check console for any errors.")
