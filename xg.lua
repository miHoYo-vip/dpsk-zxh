-- ============================================================
-- 加载 WindUI（统一界面库）
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
print("WindUI 加载完成")

-- ============================================================
-- 服务与全局变量
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

print("服务初始化完成")

-- ============================================================
-- 功能状态表
-- ============================================================
local Features = {
    Speed = false,
    SpeedValue = 50,
    OriginalWalkSpeed = 16,
    InfiniteJump = false,
    HighJump = false,
    JumpPower = 100,
    OriginalJumpPower = 50,

    Flying = false,
    FlyMode = "CameraControl",
    FixedHeight = 10,
    FlySpeed = 60,

    NoClip = false,
    NoFallDamage = false,

    ESP = false,
    ESPColorFriend = Color3.fromRGB(0, 255, 0),
    ESPColorEnemy = Color3.fromRGB(255, 0, 0),
    ESPNPC = false,
    ESPColorNPC = Color3.fromRGB(255, 255, 0),
    ESPTracer = false,

    Aimlock = false,
    AimTarget = nil,
    AimSmoothness = 0.2,
    AimPart = "HumanoidRootPart",

    NightVision = false,
    NightVisionColor = Color3.fromRGB(255, 255, 255),
    NightVisionBrightness = 1,
    Fullbright = false,
    NoFog = false,
    NoShadows = false,
    NoScreenEffects = false,
    CustomFOV = false,
    FOVValue = 70,
    FreeCamera = false,

    Translation = false,
    AutoReconnect = false,
    ReconnectAttempts = 0,
    MaxReconnectAttempts = 5,
    AntiAFK = false,

    SavedPos = nil,
    TeleportLoop = false,
    TeleportInterval = 1,

    InfiniteStamina = false,
    CustomGravity = false,
    GravityValue = 196.2,
    CustomGameSpeed = false,
    GameSpeedValue = 1,
    ShowFPSPing = false,
    SpinBot = false,
    SpinSpeed = 50,
}

-- 保存原始值
Features.OriginalCameraZoom = LocalPlayer.CameraMaxZoomDistance
Features.OriginalGravity = Workspace.Gravity
Features.OriginalGameSpeed = RunService.GlobalTimeScale
Features.OriginalFOV = Camera.FieldOfView

print("功能状态初始化完成")

-- ============================================================
-- 照明状态管理
-- ============================================================
local originalLighting = nil

local function saveLightingState()
    if not originalLighting then
        originalLighting = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            ColorShift_Top = Lighting.ColorShift_Top,
            ColorShift_Bottom = Lighting.ColorShift_Bottom,
            ExposureCompensation = Lighting.ExposureCompensation,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor,
            GlobalShadows = Lighting.GlobalShadows,
        }
    end
end

local function applyLightingFeatures()
    saveLightingState()
    if not originalLighting then return end

    if Features.NoFog then
        Lighting.FogEnd = 1e9
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.FogStart = originalLighting.FogStart
        Lighting.FogColor = originalLighting.FogColor
    end

    Lighting.GlobalShadows = Features.NoShadows and false or originalLighting.GlobalShadows

    if Features.Fullbright then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
    elseif Features.NightVision then
        Lighting.Brightness = Features.NightVisionBrightness
        Lighting.Ambient = Features.NightVisionColor
        Lighting.ColorShift_Top = Features.NightVisionColor
        Lighting.ColorShift_Bottom = Features.NightVisionColor
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.Ambient = originalLighting.Ambient
        Lighting.ColorShift_Top = originalLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = originalLighting.ColorShift_Bottom
    end
end

local function resetLighting()
    if originalLighting then
        pcall(function()
            Lighting.Ambient = originalLighting.Ambient
            Lighting.ColorShift_Bottom = originalLighting.ColorShift_Bottom
            Lighting.ColorShift_Top = originalLighting.ColorShift_Top
            Lighting.Brightness = originalLighting.Brightness
            Lighting.ExposureCompensation = originalLighting.ExposureCompensation
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.FogStart = originalLighting.FogStart
            Lighting.FogColor = originalLighting.FogColor
            Lighting.GlobalShadows = originalLighting.GlobalShadows
        end)
    end
end

-- ============================================================
-- 定义所有功能函数（按UI调用顺序，确保无遗漏）
-- ============================================================

-- 移动增强（Speed, InfiniteJump, HighJump, Stamina, Gravity）
function toggleSpeed(enable)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    if enable then
        Features.OriginalWalkSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = Features.SpeedValue
    else
        humanoid.WalkSpeed = Features.OriginalWalkSpeed
    end
    Features.Speed = enable
end

function setSpeedValue(value)
    Features.SpeedValue = value
    if Features.Speed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
end

local jumpConnection = nil
function toggleInfiniteJump(enable)
    Features.InfiniteJump = enable
    if enable then
        if not jumpConnection then
            jumpConnection = UserInputService.JumpRequest:Connect(function()
                if Features.InfiniteJump then
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then
                        local hum = char.Humanoid
                        if hum:GetState() ~= Enum.HumanoidStateType.Jumping then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end
            end)
        end
    else
        if jumpConnection then jumpConnection:Disconnect() end
        jumpConnection = nil
    end
end

function toggleHighJump(enable)
    Features.HighJump = enable
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    if enable then
        Features.OriginalJumpPower = humanoid.JumpPower
        humanoid.JumpPower = Features.JumpPower
    else
        humanoid.JumpPower = Features.OriginalJumpPower
    end
end

function setJumpPower(value)
    Features.JumpPower = value
    if Features.HighJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = value
    end
end

function toggleInfiniteStamina(enable)
    Features.InfiniteStamina = enable
    if enable then
        pcall(function()
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Exhaustion, false)
        end)
    else
        pcall(function()
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Exhaustion, true)
        end)
    end
end

function toggleCustomGravity(enable)
    Features.CustomGravity = enable
    if enable then
        Workspace.Gravity = Features.GravityValue
    else
        Workspace.Gravity = Features.OriginalGravity
    end
end

-- 飞行
local flyBodyVelocity, flyBodyGyro, flyConnection = nil, nil, nil

local function onFlyHeartbeat()
    if not Features.Flying then
        toggleFly(false)
        return
    end
    local char = LocalPlayer.Character
    if not char then
        toggleFly(false)
        return
    end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then
        toggleFly(false)
        return
    end

    local moveDir = Vector3.zero
    local camForward = Camera.CFrame.LookVector
    local camRight = Camera.CFrame.RightVector

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camForward end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camForward end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camRight end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camRight end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0, 1, 0) end

    if Features.FlyMode == "FixedHeight" then
        moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
        local diff = Features.FixedHeight - rootPart.Position.Y
        if math.abs(diff) > 0.5 then
            rootPart.CFrame = rootPart.CFrame:Lerp(rootPart.CFrame + Vector3.new(0, diff, 0), 0.1)
        end
    end

    if flyBodyVelocity then
        flyBodyVelocity.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * Features.FlySpeed) or Vector3.zero
    end
    if flyBodyGyro then
        local lookDir = Vector3.new(camForward.X, 0, camForward.Z)
        if lookDir.Magnitude > 0 then
            flyBodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookDir.Unit)
        end
    end
end

function toggleFly(enable)
    if enable == Features.Flying and enable then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local rootPart = char.HumanoidRootPart
            if not flyBodyVelocity or not flyBodyVelocity.Parent then
                flyBodyVelocity = Instance.new("BodyVelocity")
                flyBodyVelocity.MaxForce = Vector3.new(9e6, 9e6, 9e6)
                flyBodyVelocity.Velocity = Vector3.zero
                flyBodyVelocity.Parent = rootPart

                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.MaxTorque = Vector3.new(9e6, 9e6, 9e6)
                flyBodyGyro.CFrame = rootPart.CFrame
                flyBodyGyro.Parent = rootPart
            end
        end
        return
    end

    Features.Flying = enable
    local char = LocalPlayer.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return end

    if enable then
        if flyConnection then flyConnection:Disconnect() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(9e6, 9e6, 9e6)
        flyBodyVelocity.Velocity = Vector3.zero
        flyBodyVelocity.Parent = rootPart

        if flyBodyGyro then flyBodyGyro:Destroy() end
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(9e6, 9e6, 9e6)
        flyBodyGyro.CFrame = rootPart.CFrame
        flyBodyGyro.Parent = rootPart

        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
        flyConnection = RunService.Heartbeat:Connect(onFlyHeartbeat)
    else
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = nil
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        flyBodyVelocity = nil
        if flyBodyGyro then flyBodyGyro:Destroy() end
        flyBodyGyro = nil
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
    end
end

-- 穿墙
local noclipCharConn, noclipAddedConn = nil, nil

local function setNoClipOnCharacter(char, enabled)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

local function onNoClipChildAdded(child)
    if Features.NoClip and child:IsA("BasePart") then
        child.CanCollide = false
    end
end

function toggleNoClip(enable)
    Features.NoClip = enable
    if noclipCharConn then noclipCharConn:Disconnect() end
    if noclipAddedConn then noclipAddedConn:Disconnect() end
    if enable then
        local char = LocalPlayer.Character
        if char then
            setNoClipOnCharacter(char, true)
            noclipCharConn = char.ChildAdded:Connect(onNoClipChildAdded)
        end
        noclipAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            if Features.NoClip then
                setNoClipOnCharacter(newChar, true)
                if noclipCharConn then noclipCharConn:Disconnect() end
                noclipCharConn = newChar.ChildAdded:Connect(onNoClipChildAdded)
            end
        end)
    else
        local char = LocalPlayer.Character
        if char then setNoClipOnCharacter(char, false) end
    end
end

-- 无摔落伤害
local fallDamageConn = nil
local function onHumanoidStateChanged(oldState, newState)
    if Features.NoFallDamage and newState == Enum.HumanoidStateType.FallingDown then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            task.spawn(function()
                task.wait(0.1)
                if humanoid and humanoid.Parent and Features.NoFallDamage then
                    if humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    if humanoid.Health < humanoid.MaxHealth then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end
            end)
        end
    end
end

function toggleNoFallDamage(enable)
    Features.NoFallDamage = enable
    if fallDamageConn then fallDamageConn:Disconnect() end
    if enable then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            fallDamageConn = humanoid.StateChanged:Connect(onHumanoidStateChanged)
        end
    end
end

-- 照明功能开关（夜视、全亮、去雾、去阴影）
local nightVisionConnection = nil
local fullbrightConnection = nil

function toggleNightVision(enable)
    Features.NightVision = enable
    if enable then
        if not nightVisionConnection then
            nightVisionConnection = RunService.RenderStepped:Connect(applyLightingFeatures)
        end
    else
        if nightVisionConnection then
            nightVisionConnection:Disconnect()
            nightVisionConnection = nil
        end
    end
    applyLightingFeatures()
end

function toggleFullbright(enable)
    Features.Fullbright = enable
    if enable then
        if not fullbrightConnection then
            fullbrightConnection = RunService.RenderStepped:Connect(applyLightingFeatures)
        end
    else
        if fullbrightConnection then
            fullbrightConnection:Disconnect()
            fullbrightConnection = nil
        end
    end
    applyLightingFeatures()
end

function toggleNoFog(enable)
    Features.NoFog = enable
    applyLightingFeatures()
end

function toggleNoShadows(enable)
    Features.NoShadows = enable
    applyLightingFeatures()
end

-- 屏幕特效
local originalEffectState = setmetatable({}, { __mode = "k" })

function toggleNoScreenEffects(enable)
    Features.NoScreenEffects = enable
    local effectTypes = {"BloomEffect", "ColorCorrectionEffect", "MotionBlurEffect", "DepthOfFieldEffect", "BlurEffect"}
    if enable then
        for _, descendant in ipairs(Lighting:GetDescendants()) do
            for _, typeName in ipairs(effectTypes) do
                if descendant:IsA(typeName) and originalEffectState[descendant] == nil then
                    originalEffectState[descendant] = descendant.Enabled
                    descendant.Enabled = false
                end
            end
        end
    else
        for obj, enabled in pairs(originalEffectState) do
            if obj and obj.Parent then
                pcall(function() obj.Enabled = enabled end)
            end
        end
        table.clear(originalEffectState)
    end
end

-- FOV 和 自由视角（之前缺失，现已补全）
function toggleFOV(enable)
    Features.CustomFOV = enable
    if enable then
        Camera.FieldOfView = Features.FOVValue
    else
        Camera.FieldOfView = Features.OriginalFOV
    end
end

function toggleFreeCamera(enable)
    Features.FreeCamera = enable
    if enable then
        LocalPlayer.CameraMaxZoomDistance = 200
    else
        LocalPlayer.CameraMaxZoomDistance = Features.OriginalCameraZoom
    end
end

-- 自定义游戏速度
function toggleCustomGameSpeed(enable)
    Features.CustomGameSpeed = enable
    if enable then
        RunService.GlobalTimeScale = Features.GameSpeedValue
    else
        RunService.GlobalTimeScale = Features.OriginalGameSpeed
    end
end

-- 自旋
local spinConnection = nil
function toggleSpinBot(enable)
    Features.SpinBot = enable
    if enable then
        if spinConnection then spinConnection:Disconnect() end
        spinConnection = RunService.RenderStepped:Connect(function()
            if not Features.SpinBot then return end
            local char = LocalPlayer.Character
            local rootPart = char and char:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(Features.SpinSpeed), 0)
            end
        end)
    else
        if spinConnection then
            spinConnection:Disconnect()
            spinConnection = nil
        end
    end
end

-- 自瞄系统（含按钮）
local aimConnection, aimButton = nil, nil

local function getClosestPlayer()
    local closest, minDist = nil, math.huge
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local pos = root.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetRoot = player.Character:FindFirstChild(Features.AimPart) or player.Character:FindFirstChild("Torso")
                if targetRoot then
                    local dist = (pos - targetRoot.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

local function aimLoop()
    if not Features.Aimlock then return end
    if not Features.AimTarget or not Features.AimTarget.Character or not Features.AimTarget.Character:FindFirstChild(Features.AimPart) then
        Features.AimTarget = getClosestPlayer()
        if not Features.AimTarget then
            if aimButton and aimButton:FindFirstChild("TextLabel") then
                aimButton.TextLabel.Text = "无"
            end
            return
        end
    end
    local targetRoot = Features.AimTarget.Character:FindFirstChild(Features.AimPart) or Features.AimTarget.Character:FindFirstChild("Torso")
    if targetRoot then
        local targetCF = CFrame.new(Camera.CFrame.Position, targetRoot.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCF, Features.AimSmoothness)
        if aimButton and aimButton:FindFirstChild("TextLabel") then
            aimButton.TextLabel.Text = Features.AimTarget.Name:sub(1, 4)
        end
    end
end

function toggleAimlock(enable)
    Features.Aimlock = enable
    if enable then
        if not aimConnection then
            aimConnection = RunService.RenderStepped:Connect(aimLoop)
        end
        if aimButton and aimButton:FindFirstChild("TextLabel") then
            aimButton.TextLabel.Text = "开"
        end
    else
        if aimConnection then
            aimConnection:Disconnect()
            aimConnection = nil
        end
        Features.AimTarget = nil
        if aimButton and aimButton:FindFirstChild("TextLabel") then
            aimButton.TextLabel.Text = "关"
        end
    end
end

function createAimButton()
    if aimButton and aimButton.Parent then return end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimButtonGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.8, -30)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = frame

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = "关"
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.TextScaled = true
    text.Font = Enum.Font.GothamBold
    text.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = frame

    local isDragging = false
    local dragStartPos = nil
    local startMousePos = nil
    local moved = false

    local function startDrag(inputPos)
        isDragging = true
        moved = false
        dragStartPos = frame.Position
        startMousePos = inputPos
    end

    local function updateDrag(inputPos)
        if isDragging and startMousePos then
            local delta = inputPos - startMousePos
            if delta.Magnitude > 5 then moved = true end
            frame.Position = UDim2.new(
                dragStartPos.X.Scale,
                dragStartPos.X.Offset + delta.X,
                dragStartPos.Y.Scale,
                dragStartPos.Y.Offset + delta.Y
            )
        end
    end

    local function endDrag()
        if isDragging and not moved then
            toggleAimlock(not Features.Aimlock)
        end
        isDragging = false
    end

    button.MouseButton1Down:Connect(function(x, y)
        startDrag(Vector2.new(x, y))
    end)
    button.MouseMoved:Connect(function(x, y)
        updateDrag(Vector2.new(x, y))
    end)
    button.MouseButton1Up:Connect(endDrag)

    button.TouchBegan:Connect(function(touch)
        startDrag(touch.Position)
    end)
    button.TouchMoved:Connect(function(touch)
        updateDrag(touch.Position)
    end)
    button.TouchEnded:Connect(endDrag)

    aimButton = frame
end

-- ESP 系统（包含 Tracer）
local espObjects = {}
local espUpdateConn, espPlayerAddedConn, npcScanThread = nil, nil, nil

function clearESPFor(key)
    local data = espObjects[key]
    if data then
        if data.highlight then pcall(data.highlight.Destroy, data.highlight) end
        if data.billboard then pcall(data.billboard.Destroy, data.billboard) end
        if data.tracerLines then
            for _, line in pairs(data.tracerLines) do
                pcall(line.Destroy, line)
            end
        end
        espObjects[key] = nil
    end
end

function createESPForTarget(targetModel, color, name, isNPC)
    local rootPart = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChild("Torso")
    if not rootPart then return end
    local key = isNPC and targetModel or Players:GetPlayerFromCharacter(targetModel)
    if not key then return end
    clearESPFor(key)

    local highlight = Instance.new("Highlight")
    highlight.Adornee = targetModel
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0
    highlight.Parent = targetModel

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(2, 0, 0.6, 0)
    billboard.Adornee = rootPart
    billboard.AlwaysOnTop = true
    billboard.Parent = targetModel

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.Position = UDim2.new(0, 0, -0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local healthBg = Instance.new("Frame")
    healthBg.Size = UDim2.new(1, 0, 0.1, 0)
    healthBg.Position = UDim2.new(0, 0, 0.5, 0)
    healthBg.BackgroundColor3 = Color3.new(0, 0, 0)
    healthBg.BackgroundTransparency = 0.5
    healthBg.Parent = billboard

    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.Parent = healthBg

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distLabel.Position = UDim2.new(0, 0, 0.2, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    distLabel.TextScaled = true
    distLabel.Parent = billboard

    local espData = {
        isNPC = isNPC,
        character = targetModel,
        highlight = highlight,
        billboard = billboard,
        healthBar = healthBar,
        distLabel = distLabel,
        tracerLines = {},
    }

    if Features.ESPTracer then
        for _, partName in ipairs({"HumanoidRootPart", "Head"}) do
            local part = targetModel:FindFirstChild(partName)
            if part then
                local line = Drawing.new("Line")
                line.Color = color
                line.Thickness = 1.5
                line.Visible = false
                table.insert(espData.tracerLines, line)
            end
        end
    end

    espObjects[key] = espData
end

function updateESP()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for key, data in pairs(espObjects) do
        local char = data.character
        local humanoid = char and char:FindFirstChild("Humanoid")
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not humanoid or not root or not root.Parent then
            clearESPFor(key)
            continue
        end

        local dist = (myRoot.Position - root.Position).Magnitude
        pcall(function() data.distLabel.Text = string.format("%.0fm", dist) end)

        local hp = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        pcall(function()
            data.healthBar.Size = UDim2.new(hp, 0, 1, 0)
            data.healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
        end)

        if Features.ESPTracer and data.tracerLines then
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            for i, line in ipairs(data.tracerLines) do
                line.Visible = onScreen and screenPos.Z > 0
                if line.Visible then
                    local startPos = Camera:WorldToViewportPoint(myRoot.Position + Vector3.new(0, 3, 0))
                    line.From = Vector2.new(screenPos.X, screenPos.Y)
                    line.To = Vector2.new(startPos.X, startPos.Y)
                end
            end
        end
    end
end

function refreshAllPlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local isFriend = player.Team == LocalPlayer.Team
            local color = isFriend and Features.ESPColorFriend or Features.ESPColorEnemy
            createESPForTarget(player.Character, color, player.Name, false)
        end
    end
end

function toggleESP(enable)
    Features.ESP = enable
    if enable then
        refreshAllPlayerESP()
        if not espUpdateConn then
            espUpdateConn = RunService.Heartbeat:Connect(updateESP)
        end
        if not espPlayerAddedConn then
            espPlayerAddedConn = Players.PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function()
                    if Features.ESP and player.Character then
                        local isFriend = player.Team == LocalPlayer.Team
                        local color = isFriend and Features.ESPColorFriend or Features.ESPColorEnemy
                        createESPForTarget(player.Character, color, player.Name, false)
                    end
                end)
                player:GetPropertyChangedSignal("Team"):Connect(function()
                    if Features.ESP and player.Character then
                        local isFriend = player.Team == LocalPlayer.Team
                        local color = isFriend and Features.ESPColorFriend or Features.ESPColorEnemy
                        local data = espObjects[player]
                        if data then
                            data.highlight.FillColor = color
                        end
                    end
                end)
            end)
        end
    else
        local keysToRemove = {}
        for key, data in pairs(espObjects) do
            if not data.isNPC then
                table.insert(keysToRemove, key)
            end
        end
        for _, key in ipairs(keysToRemove) do
            clearESPFor(key)
        end
        if espPlayerAddedConn then
            espPlayerAddedConn:Disconnect()
            espPlayerAddedConn = nil
        end
        if not Features.ESPNPC and espUpdateConn then
            espUpdateConn:Disconnect()
            espUpdateConn = nil
        end
    end
end

function scanNPCs()
    if not Features.ESPNPC then return end
    local playersChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then playersChars[p.Character] = true end
    end
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") and not playersChars[model] then
            if not espObjects[model] then
                createESPForTarget(model, Features.ESPColorNPC, "NPC", true)
            end
        end
    end
end

function toggleESPNPC(enable)
    Features.ESPNPC = enable
    if enable then
        scanNPCs()
        if not espUpdateConn then
            espUpdateConn = RunService.Heartbeat:Connect(updateESP)
        end
        if npcScanThread then task.cancel(npcScanThread) end
        npcScanThread = task.spawn(function()
            while Features.ESPNPC do
                task.wait(5)
                scanNPCs()
            end
        end)
    else
        local keysToRemove = {}
        for key, data in pairs(espObjects) do
            if data.isNPC then
                table.insert(keysToRemove, key)
            end
        end
        for _, key in ipairs(keysToRemove) do
            clearESPFor(key)
        end
        if npcScanThread then task.cancel(npcScanThread) end
        if not Features.ESP and espUpdateConn then
            espUpdateConn:Disconnect()
            espUpdateConn = nil
        end
    end
end

-- FPS/Ping 悬浮窗
local fpsGui = nil
local fpsPingConnection = nil
local fpsInputConnections = {}

local function disconnectFPSInputs()
    for _, conn in ipairs(fpsInputConnections) do
        conn:Disconnect()
    end
    table.clear(fpsInputConnections)
end

function toggleFPSPing(enable)
    Features.ShowFPSPing = enable
    if fpsGui then fpsGui:Destroy() end
    if not enable then
        if fpsPingConnection then fpsPingConnection:Disconnect() end
        disconnectFPSInputs()
        return
    end

    fpsGui = Instance.new("ScreenGui")
    fpsGui.Name = "FPSPingDisplay"
    fpsGui.ResetOnSpawn = false
    fpsGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 150, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = fpsGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, -10, 0.5, 0)
    fpsLabel.Position = UDim2.new(0, 5, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 60"
    fpsLabel.TextColor3 = Color3.new(1, 1, 1)
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextScaled = true
    fpsLabel.Parent = frame

    local pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(1, -10, 0.5, 0)
    pingLabel.Position = UDim2.new(0, 5, 0.5, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: 0ms"
    pingLabel.TextColor3 = Color3.new(1, 1, 1)
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextScaled = true
    pingLabel.Parent = frame

    -- 拖动支持
    local isDragging = false
    local dragStartPos, startMousePos, moved = nil, nil, false

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local absPos = frame.AbsolutePosition
            local absSize = frame.AbsoluteSize
            if pos.X >= absPos.X and pos.X <= absPos.X + absSize.X and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y then
                isDragging = true
                moved = false
                dragStartPos = frame.Position
                startMousePos = pos
            end
        end
    end

    local function onInputChanged(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startMousePos
            if delta.Magnitude > 5 then moved = true end
            frame.Position = UDim2.new(
                dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
                dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
            )
        end
    end

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end

    table.insert(fpsInputConnections, UserInputService.InputBegan:Connect(onInputBegan))
    table.insert(fpsInputConnections, UserInputService.InputChanged:Connect(onInputChanged))
    table.insert(fpsInputConnections, UserInputService.InputEnded:Connect(onInputEnded))

    local accTime = 0
    local frameCount = 0

    if fpsPingConnection then fpsPingConnection:Disconnect() end
    fpsPingConnection = RunService.RenderStepped:Connect(function(dt)
        accTime = accTime + dt
        frameCount = frameCount + 1

        if accTime < 0.5 then return end

        local fps = math.floor(frameCount / accTime + 0.5)
        local ping = 0
        local success, seconds = pcall(function()
            return LocalPlayer:GetNetworkPing()
        end)
        if success and type(seconds) == "number" then
            ping = math.floor(seconds * 1000 + 0.5)
        end

        fpsLabel.Text = string.format("FPS: %d", fps)
        pingLabel.Text = string.format("Ping: %dms", ping)
        if ping < 50 then
            pingLabel.TextColor3 = Color3.new(0, 1, 0)
        elseif ping < 100 then
            pingLabel.TextColor3 = Color3.new(1, 1, 0)
        else
            pingLabel.TextColor3 = Color3.new(1, 0, 0)
        end

        accTime = 0
        frameCount = 0
    end)
end

-- 翻译系统
local translationGeneration = 0
local translationInFlight = {}
local translationCache = {}
local originalTextState = setmetatable({}, { __mode = "k" })

local function isEnglish(text)
    if not text or text == "" then return false end
    local eng, total = 0, 0
    for char in text:gmatch(".") do
        local byte = string.byte(char)
        if byte then
            total = total + 1
            if (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) then eng = eng + 1 end
        end
    end
    return total > 0 and (eng / total) > 0.5
end

local function translateTextAsync(text, callback, gen)
    local cacheKey = text
    if translationCache[cacheKey] then
        callback(translationCache[cacheKey])
        return
    end

    if translationInFlight[cacheKey] then
        callback(nil)
        return
    end

    translationInFlight[cacheKey] = true
    task.spawn(function()
        local success, result = pcall(function()
            local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=zh-CN&dt=t&q=" .. HttpService:UrlEncode(text)
            local response = game:HttpGet(url)
            local decoded = HttpService:JSONDecode(response)
            if decoded and decoded[1] and decoded[1][1] and decoded[1][1][1] then
                return decoded[1][1][1]
            end
            return nil
        end)
        translationInFlight[cacheKey] = nil
        if success and result then
            translationCache[cacheKey] = result
            if gen == translationGeneration then
                callback(result)
            end
        else
            if gen == translationGeneration then
                callback(nil)
            end
        end
    end)
end

local function restoreAllTexts()
    for obj, originalText in pairs(originalTextState) do
        if obj and obj.Parent and obj.Text ~= nil then
            pcall(function() obj.Text = originalText end)
        end
    end
    table.clear(originalTextState)
    table.clear(translationCache)
end

local function processTextObject(obj, gen)
    if not Features.Translation then return end
    if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
    local original = obj.Text
    if not original or original == "" then return end
    if not isEnglish(original) then return end
    if originalTextState[obj] == nil then
        originalTextState[obj] = original
    end

    if translationCache[original] then
        pcall(function() obj.Text = translationCache[original] end)
    else
        translateTextAsync(original, function(translated)
            if translated and translated ~= original and gen == translationGeneration then
                if obj and obj.Parent and obj.Text == original then
                    pcall(function() obj.Text = translated end)
                end
            end
        end, gen)
    end
end

local function scanAllUIs(gen)
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if PlayerGui then
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            processTextObject(obj, gen)
        end
    end
    for _, obj in ipairs(CoreGui:GetDescendants()) do
        if obj.Name ~= "AimButtonGui" and obj.Name ~= "FPSPingDisplay" and obj.Name ~= "LearnAux" then
            processTextObject(obj, gen)
        end
    end
end

local translationThread = nil
function toggleTranslation(enable)
    Features.Translation = enable
    if not enable then
        restoreAllTexts()
        if translationThread then task.cancel(translationThread) end
        translationThread = nil
        return
    end

    translationGeneration = translationGeneration + 1
    local currentGen = translationGeneration

    if translationThread then task.cancel(translationThread) end
    translationThread = task.spawn(function()
        while Features.Translation do
            scanAllUIs(currentGen)
            task.wait(2)
        end
    end)
end

-- 自动重连 & 反AFK
local autoReconnectConn = nil
function toggleAutoReconnect(enable)
    Features.AutoReconnect = enable
    if autoReconnectConn then autoReconnectConn:Disconnect() end
    if not enable then return end

    autoReconnectConn = Players.PlayerRemoving:Connect(function(player)
        if player ~= LocalPlayer then return end
        if not Features.AutoReconnect then return end
        Features.ReconnectAttempts = 0
        task.spawn(function()
            while Features.AutoReconnect and Features.ReconnectAttempts < Features.MaxReconnectAttempts do
                Features.ReconnectAttempts += 1
                task.wait(3)
                pcall(function()
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                end)
                task.wait(5)
                if Players.LocalPlayer and Players.LocalPlayer.Parent then break end
            end
        end)
    end)
end

local antiAFKThread = nil
function toggleAntiAFK(enable)
    Features.AntiAFK = enable
    if antiAFKThread then task.cancel(antiAFKThread) end
    if not enable then return end

    antiAFKThread = task.spawn(function()
        while Features.AntiAFK do
            task.wait(30)
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if humanoid and root then
                local moveDir = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
                humanoid:Move(root.Position + moveDir * 0.1)
            end
        end
        antiAFKThread = nil
    end)
end

-- 工具函数
function showPlayerInfo()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local info = string.format("名称: %s\nID: %d\n团队: %s\n位置: %.1f, %.1f, %.1f",
        LocalPlayer.Name, LocalPlayer.UserId,
        LocalPlayer.Team and LocalPlayer.Team.Name or "无",
        root and root.Position.X or 0,
        root and root.Position.Y or 0,
        root and root.Position.Z or 0)
    WindUI:Notify({ Title = "玩家信息", Content = info, Duration = 5 })
end

function killSelf()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
        WindUI:Notify({ Title = "操作成功", Content = "已击杀自己，将重生", Duration = 2 })
    else
        WindUI:Notify({ Title = "错误", Content = "找不到角色", Duration = 2 })
    end
end

function showServerRegion()
    task.spawn(function()
        local success, result = pcall(function()
            local url = "http://ip-api.com/json/" .. game.JobId
            local response = game:HttpGet(url)
            local decoded = HttpService:JSONDecode(response)
            if decoded then
                return string.format("服务器ID: %s\n国家: %s\n城市: %s\n运营商: %s",
                    game.JobId, decoded.country or "?", decoded.city or "?", decoded.isp or "?")
            end
            return "无法获取"
        end)
        if success then
            WindUI:Notify({ Title = "服务器信息", Content = result, Duration = 5 })
        else
            WindUI:Notify({ Title = "错误", Content = "查询失败", Duration = 3 })
        end
    end)
end

-- 瞬移系统
function saveCurrentPos()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        Features.SavedPos = root.Position
        WindUI:Notify({ Title = "坐标已保存", Content = string.format("(%.1f, %.1f, %.1f)", root.Position.X, root.Position.Y, root.Position.Z), Duration = 2 })
    else
        WindUI:Notify({ Title = "错误", Content = "未找到 HumanoidRootPart", Duration = 2 })
    end
end

function teleportToSaved()
    if not Features.SavedPos then
        WindUI:Notify({ Title = "错误", Content = "请先保存坐标", Duration = 2 })
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(Features.SavedPos)
        WindUI:Notify({ Title = "传送成功", Content = "已传送到保存位置", Duration = 2 })
    end
end

function teleportToInput(x, y, z)
    local pos = Vector3.new(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
    if pos.Magnitude > 10000 then
        WindUI:Notify({ Title = "错误", Content = "坐标超出合理范围", Duration = 2 })
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
        WindUI:Notify({ Title = "传送成功", Content = string.format("已传送到 (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z), Duration = 2 })
    end
end

function teleportToPlayer(playerName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == playerName and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local char = LocalPlayer.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = targetRoot.CFrame
                        WindUI:Notify({ Title = "传送成功", Content = "已传送到 " .. player.Name, Duration = 2 })
                        return
                    end
                end
            end
        end
    end
    WindUI:Notify({ Title = "错误", Content = "未找到玩家或角色无效", Duration = 2 })
end

function teleportPlayerToMe(playerName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == playerName and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local char = LocalPlayer.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        targetRoot.CFrame = root.CFrame
                        WindUI:Notify({ Title = "传送成功", Content = player.Name .. " 已传送到您身边", Duration = 2 })
                        return
                    end
                end
            end
        end
    end
    WindUI:Notify({ Title = "错误", Content = "未找到玩家或角色无效", Duration = 2 })
end

local teleportLoopThread = nil
function toggleTeleportLoop(enable)
    Features.TeleportLoop = enable
    if teleportLoopThread then task.cancel(teleportLoopThread) end
    if not enable then
        WindUI:Notify({ Title = "循环传送", Content = "已关闭", Duration = 2 })
        return
    end
    if not Features.SavedPos then
        WindUI:Notify({ Title = "错误", Content = "请先保存坐标", Duration = 2 })
        return
    end
    teleportLoopThread = task.spawn(function()
        while Features.TeleportLoop and Features.SavedPos do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(Features.SavedPos)
            end
            task.wait(Features.TeleportInterval)
        end
        teleportLoopThread = nil
    end)
    WindUI:Notify({ Title = "循环传送", Content = "已开启，间隔 " .. Features.TeleportInterval .. " 秒", Duration = 2 })
end

-- 配置导入导出
local function packValue(value)
    local t = typeof(value)
    if t == "Color3" then
        return { __type = "Color3", R = value.R, G = value.G, B = value.B }
    elseif t == "Vector3" then
        return { __type = "Vector3", X = value.X, Y = value.Y, Z = value.Z }
    elseif t == "number" or t == "string" or t == "boolean" then
        return value
    else
        return nil
    end
end

local function unpackValue(data)
    if type(data) == "table" then
        if data.__type == "Color3" then
            return Color3.new(data.R, data.G, data.B)
        elseif data.__type == "Vector3" then
            return Vector3.new(data.X, data.Y, data.Z)
        end
    end
    return data
end

local CONFIG_KEYS = {
    "SpeedValue", "JumpPower", "FlySpeed", "FixedHeight", "TeleportInterval",
    "FOVValue", "GravityValue", "GameSpeedValue", "NightVisionBrightness",
    "ESPColorFriend", "ESPColorEnemy", "ESPColorNPC",
    "Speed", "InfiniteJump", "HighJump", "Flying", "FlyMode", "NoClip",
    "NoFallDamage", "ESP", "ESPNPC", "Aimlock", "AimSmoothness", "AimPart",
    "NightVision", "Fullbright", "NoFog", "NoShadows", "NoScreenEffects",
    "CustomFOV", "FreeCamera", "AutoReconnect", "AntiAFK", "TeleportLoop",
    "InfiniteStamina", "CustomGravity", "CustomGameSpeed", "ShowFPSPing",
    "SpinBot", "SpinSpeed",
}

function exportConfig()
    local config = {}
    for _, key in ipairs(CONFIG_KEYS) do
        local value = Features[key]
        if value ~= nil then
            config[key] = packValue(value)
        end
    end
    local json = HttpService:JSONEncode(config)
    pcall(function() setclipboard(json) end)
    WindUI:Notify({ Title = "配置已导出", Content = "已复制到剪贴板", Duration = 3 })
end

function importConfig()
    local json = pcall(getclipboard) and getclipboard() or ""
    if json == "" then
        WindUI:Notify({ Title = "错误", Content = "剪贴板为空或无法读取", Duration = 3 })
        return
    end
    pcall(function()
        local config = HttpService:JSONDecode(json)
        for key, value in pairs(config) do
            if table.find(CONFIG_KEYS, key) then
                local unpacked = unpackValue(value)
                if unpacked ~= nil then
                    Features[key] = unpacked
                end
            end
        end
        WindUI:Notify({ Title = "配置已导入", Content = "请手动重新开关功能生效", Duration = 3 })
    end)
end

-- ============================================================
-- 重写 UI 构建部分（确保所有回调都安全）
-- ============================================================
local Window = WindUI:CreateWindow({
    Title = "综合学习辅助 (融合增强版)",
    Icon = "book-open",
    Author = "WindUI 融合版",
    Folder = "LearnAux",
    Size = UDim2.fromOffset(780, 620),
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 200,
    HasOutline = true,
})

print("主窗口创建成功")

local Tabs = {
    Player = Window:Tab({ Title = "玩家", Icon = "user" }),
    Movement = Window:Tab({ Title = "移动", Icon = "move" }),
    Visual = Window:Tab({ Title = "视觉", Icon = "eye" }),
    Translation = Window:Tab({ Title = "翻译", Icon = "languages" }),
    Server = Window:Tab({ Title = "服务器", Icon = "server" }),
    Teleport = Window:Tab({ Title = "瞬移", Icon = "map-pin" }),
    Misc = Window:Tab({ Title = "杂项", Icon = "settings" }),
}

print("标签页创建完成")

-- 使用 pcall 包裹每个标签页的内容，防止个别错误阻断整体
pcall(function()
    Tabs.Player:Section({ Title = "实用工具" })
    Tabs.Player:Button({ Title = "杀死自己 (快速重生)", Callback = killSelf })
    Tabs.Player:Button({ Title = "查看我的信息", Callback = showPlayerInfo })
    Tabs.Player:Toggle({ Title = "反 AFK", Value = false, Callback = function(s) toggleAntiAFK(s) end })
    Tabs.Player:Toggle({ Title = "自动重连 (最多5次)", Value = false, Callback = function(s) toggleAutoReconnect(s) end })
    Tabs.Player:Toggle({ Title = "自定义游戏速度", Value = false, Callback = function(s) toggleCustomGameSpeed(s) end })
    Tabs.Player:Slider({ Title = "游戏速度倍数", Value = { Min = 0.1, Max = 3, Default = 1, Step = 0.1 }, Callback = function(v) Features.GameSpeedValue = v if Features.CustomGameSpeed then RunService.GlobalTimeScale = v end end })
end)

pcall(function()
    Tabs.Movement:Section({ Title = "基础移动增强" })
    Tabs.Movement:Toggle({ Title = "加速移动", Value = false, Callback = function(s) toggleSpeed(s) end })
    Tabs.Movement:Slider({ Title = "移动速度", Value = { Min = 16, Max = 200, Default = 50 }, Callback = function(v) setSpeedValue(v) end })
    Tabs.Movement:Toggle({ Title = "无限跳跃", Value = false, Callback = function(s) toggleInfiniteJump(s) end })
    Tabs.Movement:Toggle({ Title = "高跳", Value = false, Callback = function(s) toggleHighJump(s) end })
    Tabs.Movement:Slider({ Title = "跳跃力度", Value = { Min = 50, Max = 300, Default = 100 }, Callback = function(v) setJumpPower(v) end })
    Tabs.Movement:Toggle({ Title = "无限体力", Value = false, Callback = function(s) toggleInfiniteStamina(s) end })

    Tabs.Movement:Section({ Title = "飞行设置" })
    Tabs.Movement:Toggle({ Title = "飞行模式 (快捷键 F)", Value = false, Callback = function(s) toggleFly(s) end })
    Tabs.Movement:Dropdown({
        Title = "飞行控制模式",
        Values = { "默认 (全方向)", "固定高度 (锁定Y轴)", "摄像机控制" },
        Value = "摄像机控制",
        Callback = function(option)
            if option == "默认 (全方向)" then Features.FlyMode = "Default"
            elseif option == "固定高度 (锁定Y轴)" then Features.FlyMode = "FixedHeight"
            elseif option == "摄像机控制" then Features.FlyMode = "CameraControl"
            end
        end
    })
    Tabs.Movement:Slider({ Title = "固定高度", Value = { Min = 0, Max = 100, Default = 10 }, Callback = function(v) Features.FixedHeight = v end })
    Tabs.Movement:Slider({ Title = "飞行速度", Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(v) Features.FlySpeed = v end })

    Tabs.Movement:Section({ Title = "其他" })
    Tabs.Movement:Toggle({ Title = "穿墙 (NoClip)", Value = false, Callback = function(s) toggleNoClip(s) end })
    Tabs.Movement:Toggle({ Title = "无摔落伤害", Value = false, Callback = function(s) toggleNoFallDamage(s) end })
    Tabs.Movement:Toggle({ Title = "自定义重力", Value = false, Callback = function(s) toggleCustomGravity(s) end })
    Tabs.Movement:Slider({ Title = "重力数值", Value = { Min = 0, Max = 300, Default = 196.2 }, Callback = function(v) Features.GravityValue = v if Features.CustomGravity then Workspace.Gravity = v end end })
end)

pcall(function()
    Tabs.Visual:Section({ Title = "玩家透视 & 自瞄" })
    Tabs.Visual:Toggle({ Title = "启用 ESP", Value = false, Callback = function(s) toggleESP(s) end })
    Tabs.Visual:Toggle({
        Title = "ESP 线条 (Tracer)",
        Value = false,
        Callback = function(s)
            Features.ESPTracer = s
            local keys = {}
            for key in pairs(espObjects) do
                table.insert(keys, key)
            end
            for _, key in ipairs(keys) do
                clearESPFor(key)
            end
            if Features.ESP then
                refreshAllPlayerESP()
            end
            if Features.ESPNPC then
                task.spawn(function()
                    toggleESPNPC(true)
                end)
            end
        end
    })
    Tabs.Visual:Colorpicker({
        Title = "友方 ESP 颜色",
        Default = Color3.fromRGB(0, 255, 0),
        Callback = function(c)
            Features.ESPColorFriend = c
            for key, data in pairs(espObjects) do
                if not data.isNPC then
                    local player = Players:GetPlayerFromCharacter(data.character)
                    if player then
                        local isFriend = player.Team == LocalPlayer.Team
                        pcall(function() data.highlight.FillColor = isFriend and c or Features.ESPColorEnemy end)
                    end
                end
            end
        end
    })
    Tabs.Visual:Colorpicker({
        Title = "敌方 ESP 颜色",
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(c)
            Features.ESPColorEnemy = c
            for key, data in pairs(espObjects) do
                if not data.isNPC then
                    local player = Players:GetPlayerFromCharacter(data.character)
                    if player then
                        local isFriend = player.Team == LocalPlayer.Team
                        pcall(function() data.highlight.FillColor = isFriend and Features.ESPColorFriend or c end)
                    end
                end
            end
        end
    })
    Tabs.Visual:Toggle({ Title = "透视 NPC", Value = false, Callback = function(s) toggleESPNPC(s) end })
    Tabs.Visual:Colorpicker({
        Title = "NPC ESP 颜色",
        Default = Color3.fromRGB(255, 255, 0),
        Callback = function(c)
            Features.ESPColorNPC = c
            for key, data in pairs(espObjects) do
                if data.isNPC then pcall(function() data.highlight.FillColor = c end) end
            end
        end
    })
    Tabs.Visual:Toggle({ Title = "自瞄 (锁定最近)", Value = false, Callback = function(s) toggleAimlock(s) end })
    Tabs.Visual:Dropdown({
        Title = "自瞄锁定部位",
        Values = { "身体 (HumanoidRootPart)", "头部 (Head)" },
        Value = "身体 (HumanoidRootPart)",
        Callback = function(v)
            Features.AimPart = v == "身体 (HumanoidRootPart)" and "HumanoidRootPart" or "Head"
        end
    })
    Tabs.Visual:Slider({ Title = "自瞄平滑度", Value = { Min = 0.05, Max = 1, Default = 0.2, Step = 0.05 }, Callback = function(v) Features.AimSmoothness = v end })
    Tabs.Visual:Button({
        Title = "创建/显示自瞄拖动按钮",
        Callback = function()
            createAimButton()
            WindUI:Notify({ Title = "自瞄按钮已创建", Content = "拖动圆形按钮到任意位置，点击切换开关", Duration = 3 })
        end
    })

    Tabs.Visual:Section({ Title = "环境视觉效果" })
    Tabs.Visual:Toggle({ Title = "夜视", Value = false, Callback = function(s) toggleNightVision(s) end })
    Tabs.Visual:Colorpicker({ Title = "夜视颜色", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) Features.NightVisionColor = c if Features.NightVision then applyLightingFeatures() end end })
    Tabs.Visual:Slider({ Title = "夜视亮度", Value = { Min = 0, Max = 3, Default = 1 }, Callback = function(v) Features.NightVisionBrightness = v if Features.NightVision then applyLightingFeatures() end end })
    Tabs.Visual:Toggle({ Title = "全亮 (Fullbright)", Value = false, Callback = function(s) toggleFullbright(s) end })
    Tabs.Visual:Toggle({ Title = "去除雾效", Value = false, Callback = function(s) toggleNoFog(s) end })
    Tabs.Visual:Toggle({ Title = "移除阴影", Value = false, Callback = function(s) toggleNoShadows(s) end })
    Tabs.Visual:Toggle({ Title = "移除屏幕特效", Value = false, Callback = function(s) toggleNoScreenEffects(s) end })

    Tabs.Visual:Section({ Title = "视角设置" })
    Tabs.Visual:Toggle({ Title = "自定义视野(FOV)", Value = false, Callback = function(s) toggleFOV(s) end })
    Tabs.Visual:Slider({ Title = "视野角度", Value = { Min = 50, Max = 120, Default = 70 }, Callback = function(v) Features.FOVValue = v if Features.CustomFOV then Camera.FieldOfView = v end end })
    Tabs.Visual:Toggle({ Title = "自由视角(拉远)", Value = false, Callback = function(s) toggleFreeCamera(s) end })
    Tabs.Visual:Toggle({ Title = "显示FPS/Ping悬浮窗", Value = false, Callback = function(s) toggleFPSPing(s) end })
    Tabs.Visual:Toggle({ Title = "自旋 (SpinBot)", Value = false, Callback = function(s) toggleSpinBot(s) end })
    Tabs.Visual:Slider({ Title = "自旋速度", Value = { Min = 10, Max = 360, Default = 50 }, Callback = function(v) Features.SpinSpeed = v end })
end)

pcall(function()
    Tabs.Translation:Section({ Title = "UI 自动翻译 (英→中)" })
    Tabs.Translation:Toggle({ Title = "启用翻译", Value = false, Callback = function(s) toggleTranslation(s) end })
    Tabs.Translation:Button({ Title = "清空翻译缓存并恢复原文本", Callback = function() restoreAllTexts() WindUI:Notify({ Title = "缓存已清空，原文本已恢复", Duration = 2 }) end })
end)

pcall(function()
    Tabs.Server:Section({ Title = "服务器状态" })
    local serverInfoPara = Tabs.Server:Paragraph({
        Title = "实时信息",
        Desc = "加载中...",
        Image = "server",
        ImageSize = 30,
    })
    local function updateServerInfo()
        pcall(function()
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            local ping = math.floor(LocalPlayer:GetPing() * 1000)
            local playerCount = #Players:GetPlayers()
            local maxPlayers = Players.MaxPlayers
            local serverTime = os.date("%H:%M:%S")
            local placeName = "未知"
            pcall(function() placeName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)
            local info = string.format(
                "📍 游戏: %s\n👥 在线: %d / %d\n📶 Ping: %d ms\n🎮 FPS: %d\n⏰ 服务器时间: %s",
                placeName, playerCount, maxPlayers, ping, fps, serverTime
            )
            serverInfoPara:SetDesc(info)
        end)
    end
    task.spawn(function()
        while task.wait(5) do updateServerInfo() end
    end)

    Tabs.Server:Section({ Title = "玩家列表" })
    local playerListPara = Tabs.Server:Paragraph({
        Title = "当前玩家",
        Desc = "点击下方按钮刷新",
        Image = "users",
        ImageSize = 30,
    })
    local function refreshPlayerList()
        local list = ""
        for _, player in ipairs(Players:GetPlayers()) do
            local status = player == LocalPlayer and " (你)" or ""
            list = list .. player.Name .. status .. "\n"
        end
        playerListPara:SetDesc(list or "无玩家")
    end
    refreshPlayerList()
    Tabs.Server:Button({ Title = "刷新玩家列表", Callback = refreshPlayerList })
    Tabs.Server:Button({ Title = "查询服务器地区", Callback = showServerRegion })
end)

pcall(function()
    Tabs.Teleport:Section({ Title = "坐标管理" })
    local coordDesc = Tabs.Teleport:Paragraph({
        Title = "已保存坐标",
        Desc = "未保存",
        Image = "map-pin",
        ImageSize = 26,
    })
    local function updateCoordDisplay()
        if Features.SavedPos then
            coordDesc:SetDesc(string.format("(%.1f, %.1f, %.1f)", Features.SavedPos.X, Features.SavedPos.Y, Features.SavedPos.Z))
        else
            coordDesc:SetDesc("未保存")
        end
    end
    Tabs.Teleport:Button({
        Title = "保存当前坐标",
        Callback = function()
            saveCurrentPos()
            updateCoordDisplay()
        end
    })
    Tabs.Teleport:Button({ Title = "传送到保存坐标", Callback = function() teleportToSaved() updateCoordDisplay() end })

    Tabs.Teleport:Section({ Title = "手动输入坐标" })
    local xInput = Tabs.Teleport:Input({ Title = "X", Value = "0", Placeholder = "X" })
    local yInput = Tabs.Teleport:Input({ Title = "Y", Value = "0", Placeholder = "Y" })
    local zInput = Tabs.Teleport:Input({ Title = "Z", Value = "0", Placeholder = "Z" })
    Tabs.Teleport:Button({
        Title = "传送到输入坐标",
        Callback = function()
            local x = tonumber(xInput:GetValue()) or 0
            local y = tonumber(yInput:GetValue()) or 0
            local z = tonumber(zInput:GetValue()) or 0
            teleportToInput(x, y, z)
        end
    })

    Tabs.Teleport:Section({ Title = "玩家传送" })
    local function getPlayerNames()
        local names = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then table.insert(names, player.Name) end
        end
        return names
    end
    local playerDropdown = Tabs.Teleport:Dropdown({
        Title = "选择玩家",
        Values = getPlayerNames(),
        Value = nil,
        Multi = false,
        AllowNone = true,
        Callback = function() end
    })
    Tabs.Teleport:Button({
        Title = "传送至该玩家",
        Callback = function()
            local selected = playerDropdown:GetValue()
            if selected and selected ~= "" then teleportToPlayer(selected)
            else WindUI:Notify({ Title = "错误", Content = "请先选择玩家", Duration = 2 }) end
        end
    })
    Tabs.Teleport:Button({
        Title = "将该玩家传送到我",
        Callback = function()
            local selected = playerDropdown:GetValue()
            if selected and selected ~= "" then teleportPlayerToMe(selected)
            else WindUI:Notify({ Title = "错误", Content = "请先选择玩家", Duration = 2 }) end
        end
    })

    Tabs.Teleport:Section({ Title = "循环传送" })
    Tabs.Teleport:Toggle({
        Title = "启用循环传送 (需先保存坐标)",
        Value = false,
        Callback = function(s) toggleTeleportLoop(s) end
    })
    Tabs.Teleport:Slider({
        Title = "传送间隔 (秒)",
        Value = { Min = 0.5, Max = 10, Default = 1 },
        Callback = function(v) Features.TeleportInterval = v end
    })
end)

pcall(function()
    Tabs.Misc:Section({ Title = "系统" })
    Tabs.Misc:Dropdown({
        Title = "切换主题",
        Values = {"Dark", "Light", "Blue", "Purple", "Green"},
        Default = "Dark",
        Callback = function(theme) Window:SetTheme(theme) end
    })
    Tabs.Misc:Button({ Title = "导出配置到剪贴板", Callback = exportConfig })
    Tabs.Misc:Button({ Title = "从剪贴板导入配置", Callback = importConfig })
    Tabs.Misc:Button({
        Title = "重置所有功能",
        Callback = function()
            toggleSpeed(false)
            toggleInfiniteJump(false)
            toggleHighJump(false)
            toggleFly(false)
            toggleNoClip(false)
            toggleNoFallDamage(false)
            toggleInfiniteStamina(false)
            toggleCustomGravity(false)
            toggleESP(false)
            toggleESPNPC(false)
            toggleAimlock(false)
            toggleNightVision(false)
            toggleFullbright(false)
            toggleNoFog(false)
            toggleNoShadows(false)
            toggleNoScreenEffects(false)
            toggleFPSPing(false)
            toggleCustomGameSpeed(false)
            toggleFOV(false)
            toggleFreeCamera(false)
            toggleTranslation(false)
            toggleAutoReconnect(false)
            toggleAntiAFK(false)
            toggleTeleportLoop(false)
            toggleSpinBot(false)
            resetLighting()
            if aimButton and aimButton.Parent then aimButton.Parent:Destroy() end
            if fpsGui then fpsGui:Destroy() end
            WindUI:Notify({ Title = "已重置", Content = "所有功能已关闭", Duration = 3 })
        end
    })
end)

-- ========== 窗口打开按钮 ==========
Window:EditOpenButton({
    Title = "打开辅助",
    Icon = "shield",
    CornerRadius = UDim.new(0, 12),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("00FF87"), Color3.fromHex("60EFFF")),
    Draggable = true,
})

Window:Open()
WindUI:Notify({ Title = "欢迎", Content = "融合增强版已加载，按 F 切换飞行，F1 开关UI", Duration = 5, Icon = "info" })

-- 自动创建自瞄按钮
task.wait(1)
createAimButton()

-- ============================================================
-- 快捷键
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        if not UserInputService:GetFocusedTextBox() then
            toggleFly(not Features.Flying)
            WindUI:Notify({ Title = "飞行", Content = Features.Flying and "已开启" or "已关闭", Duration = 2 })
        end
    elseif input.KeyCode == Enum.KeyCode.F1 then
        if not UserInputService:GetFocusedTextBox() then
            Window:Toggle()
        end
    end
end)

-- ============================================================
-- 清理
-- ============================================================
local function cleanup()
    toggleSpeed(false)
    toggleInfiniteJump(false)
    toggleHighJump(false)
    toggleFly(false)
    toggleNoClip(false)
    toggleNoFallDamage(false)
    toggleInfiniteStamina(false)
    toggleCustomGravity(false)
    toggleESP(false)
    toggleESPNPC(false)
    toggleAimlock(false)
    toggleNightVision(false)
    toggleFullbright(false)
    toggleNoFog(false)
    toggleNoShadows(false)
    toggleNoScreenEffects(false)
    toggleFPSPing(false)
    toggleCustomGameSpeed(false)
    toggleFOV(false)
    toggleFreeCamera(false)
    toggleTranslation(false)
    toggleAutoReconnect(false)
    toggleAntiAFK(false)
    toggleTeleportLoop(false)
    toggleSpinBot(false)
    resetLighting()
    if aimButton and aimButton.Parent then aimButton.Parent:Destroy() end
    if fpsGui then fpsGui:Destroy() end
    print("学习辅助已清理完成")
end

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then cleanup() end
end)

print("脚本加载完成！UI 已显示")
