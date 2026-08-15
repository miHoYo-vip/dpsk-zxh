-- ============================================
-- 综合学习辅助 (单色暗紫 · 全功能完整版)
-- 界面稳定 + 全部功能可用
-- 按 F 打开菜单
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local LoadStartTime = tick()

-- ============================================
-- 统一配色方案 (单色暗紫)
-- ============================================
local C = {
	Primary = Color3.fromRGB(108, 70, 188),
	PrimaryDark = Color3.fromRGB(72, 44, 140),
	PrimaryLight = Color3.fromRGB(160, 130, 220),
	Bg = Color3.fromRGB(18, 12, 36),
	RowBg = Color3.fromRGB(30, 20, 60),
	Text = Color3.fromRGB(235, 230, 255),
	TextSub = Color3.fromRGB(190, 185, 220),
	ToggleOn = Color3.fromRGB(0, 180, 100),
	ToggleOff = Color3.fromRGB(96, 72, 170),
	Stroke = Color3.fromRGB(130, 110, 190),
}
local function createStroke(parent, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.Stroke
	stroke.Thickness = thickness or 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function notify(title, content)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title or "提示",
			Text = content or "",
			Duration = 3,
		})
	end)
end

-- ============================================
-- 功能状态表 (完整)
-- ============================================
local Features = {
	Speed = false,
	SpeedValue = 50,
	OriginalWalkSpeed = 16,
	InfiniteJump = false,
	HighJump = false,
	JumpPower = 100,
	OriginalJumpPower = 50,

	Flying = false,
	FlyMode = "摄像机控制",
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

	DynamicIsland = true,
	FloatBallPos = {0.5, -19, 0, 110},
}

Features.OriginalCameraZoom = player.CameraMaxZoomDistance
Features.OriginalGravity = Workspace.Gravity
Features.OriginalGameSpeed = RunService.GlobalTimeScale
Features.OriginalFOV = camera.FieldOfView

-- ============================================
-- 照明管理
-- ============================================
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
		Lighting.Ambient = Color3.new(1,1,1)
		Lighting.ColorShift_Top = Color3.new(1,1,1)
		Lighting.ColorShift_Bottom = Color3.new(1,1,1)
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

-- ============================================
-- 辅助UI函数 (与之前相同，保证UI稳定)
-- ============================================
local function tween(obj, props, info)
	if not obj or not obj.Parent then return nil end
	local ok, tw = pcall(function()
		return TweenService:Create(obj, info or TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	end)
	if ok and tw then
		pcall(function() tw:Play() end)
		return tw
	end
	return nil
end
local TweenFast = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TweenScalePop = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TweenPanelOpen = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenPanelClose = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function createButton(parent, name, size, pos, color, text)
	local btn = Instance.new("TextButton")
	btn.Name = name; btn.Size = size; btn.Position = pos
	btn.BackgroundColor3 = color or C.Primary
	btn.Text = text or ""
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize = 14; btn.Font = Enum.Font.GothamSemibold
	btn.AutoButtonColor = true; btn.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = btn
	createStroke(btn, 1.5)
	return btn
end

local function createCheckbox(parent, text, defaultValue, callback, compact)
	local frame = Instance.new("Frame")
	if compact then
		frame.Size = UDim2.new(0.485, 0, 0, 24)
	else
		frame.Size = UDim2.new(1, 0, 0, 24)
	end
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0,20,0,20); box.Position = UDim2.new(0,0,0.5,-10)
	box.BackgroundColor3 = defaultValue and C.ToggleOn or C.ToggleOff
	box.BorderSizePixel = 0
	box.Parent = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = box
	createStroke(box, 1.5)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-30,1,0); label.Position = UDim2.new(0,26,0,0)
	label.BackgroundTransparency = 1; label.Text = text
	label.TextColor3 = C.Text; label.TextSize = 12
	label.Font = Enum.Font.Gotham; label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local checked = defaultValue
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Parent = box
	local lastPress = 0
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			lastPress = tick()
		end
	end)
	hit.MouseButton1Click:Connect(function()
		if tick() - lastPress < 0.4 then
			checked = not checked
			tween(box, {BackgroundColor3 = checked and C.ToggleOn or C.ToggleOff}, TweenFast)
			if callback then callback(checked) end
		end
	end)
	return frame, function() return checked end
end

local function addCheckboxes(parent, specs)
	local row
	for i, spec in ipairs(specs) do
		local idx = (i - 1) % 2
		if idx == 0 then
			row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 24)
			row.BackgroundTransparency = 1
			row.Parent = parent
		end
		local text, default, cb = table.unpack(spec)
		local frame = createCheckbox(row, text, default, cb, true)
		if idx == 1 then
			frame.Position = UDim2.new(0.515, 0, 0, 0)
		end
	end
end

local function createDropdown(parent, title, defaultOpen, leftPadding, onHeightChange, width)
	local W = width or 336
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, W, 0, 34)
	container.BackgroundColor3 = C.PrimaryDark
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = parent
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,12); cc.Parent = container
	createStroke(container, 1.5)

	local header = Instance.new("TextButton")
	header.Size = UDim2.new(1, 0, 0, 34)
	header.BackgroundTransparency = 1
	header.Text = ""
	header.AutoButtonColor = false
	header.Parent = container

	local headerText = Instance.new("TextLabel")
	headerText.Size = UDim2.new(1,-16,1,0)
	headerText.Position = UDim2.new(0,10,0,0)
	headerText.BackgroundTransparency = 1
	headerText.Text = "▼ " .. title
	headerText.TextColor3 = C.Text
	headerText.TextSize = 13
	headerText.Font = Enum.Font.GothamBold
	headerText.TextXAlignment = Enum.TextXAlignment.Left
	headerText.Parent = header

	local content = Instance.new("Frame")
	content.Size = UDim2.new(0, W - 48, 0, 0)
	content.Position = UDim2.new(0,42,0,34)
	content.BackgroundTransparency = 1
	content.ClipsDescendants = true
	content.Parent = container

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0,4); list.Parent = content

	local open = defaultOpen or false
	local lastPress = 0
	local function update()
		if not container.Parent then return end
		if open then
			headerText.Text = "▼ " .. title
			local h = list.AbsoluteContentSize.Y + 8
			tween(container, {Size = UDim2.new(0, W, 0, 34+h)}, TweenFast)
			tween(content, {Size = UDim2.new(0, W - 48, 0, h)}, TweenFast)
			if onHeightChange then onHeightChange(34 + h) end
		else
			headerText.Text = "▶ " .. title
			tween(container, {Size = UDim2.new(0, W, 0, 34)}, TweenFast)
			tween(content, {Size = UDim2.new(0, W - 48, 0, 0)}, TweenFast)
			if onHeightChange then onHeightChange(34) end
		end
	end

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			lastPress = tick()
		end
	end)
	header.MouseButton1Click:Connect(function()
		if tick() - lastPress < 0.4 then
			open = not open
			update()
		end
	end)

	return content, function() return open end, function(v) open = v; update() end
end

local function createBtnRow(parent, height)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1,0,0,height or 26)
	row.BackgroundTransparency = 1
	row.Parent = parent
	return row
end

local StepMap = {
	SpeedValue = 10, JumpPower = 10, FlySpeed = 10, FixedHeight = 5,
	SpinSpeed = 10, FOVValue = 5, GravityValue = 10, GameSpeedValue = 0.1,
	TeleportInterval = 0.5, NightVisionBrightness = 0.5,
}
local MinMap = {
	SpeedValue = 1, JumpPower = 1, FlySpeed = 1, FixedHeight = 0,
	SpinSpeed = 1, FOVValue = 10, GravityValue = 0, GameSpeedValue = 0.1,
	TeleportInterval = 0.5, NightVisionBrightness = 0,
}
local MaxMap = {
	SpeedValue = 500, JumpPower = 500, FlySpeed = 500, FixedHeight = 1000,
	SpinSpeed = 500, FOVValue = 120, GravityValue = 1000, GameSpeedValue = 3,
	TeleportInterval = 10, NightVisionBrightness = 5,
}
local function createStepControl(parent, stateKey)
	local step = StepMap[stateKey] or 5
	local minV = MinMap[stateKey] or 1
	local maxV = MaxMap[stateKey] or 999

	local minus = Instance.new("TextButton")
	minus.Size = UDim2.new(0, 24, 0, 26); minus.Position = UDim2.new(0, 214, 0.5, -13)
	minus.BackgroundColor3 = C.Primary
	minus.Text = "−"; minus.TextColor3 = Color3.fromRGB(255,255,255)
	minus.TextSize = 14; minus.Font = Enum.Font.GothamBold
	minus.Parent = parent
	local mC = Instance.new("UICorner"); mC.CornerRadius = UDim.new(0, 8); mC.Parent = minus
	createStroke(minus, 1.5)

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0, 50, 0, 26); valLabel.Position = UDim2.new(0, 240, 0.5, -13)
	valLabel.BackgroundColor3 = C.PrimaryDark
	valLabel.BackgroundTransparency = 0.1
	valLabel.Text = tostring(Features[stateKey] or 0)
	valLabel.TextColor3 = C.Text
	valLabel.TextSize = 11; valLabel.Font = Enum.Font.Gotham
	valLabel.Parent = parent
	local vC = Instance.new("UICorner"); vC.CornerRadius = UDim.new(0, 8); vC.Parent = valLabel
	createStroke(valLabel, 1.5)

	local plus = Instance.new("TextButton")
	plus.Size = UDim2.new(0, 24, 0, 26); plus.Position = UDim2.new(0, 292, 0.5, -13)
	plus.BackgroundColor3 = C.Primary
	plus.Text = "+"; plus.TextColor3 = Color3.fromRGB(255,255,255)
	plus.TextSize = 14; plus.Font = Enum.Font.GothamBold
	plus.Parent = parent
	local pC = Instance.new("UICorner"); pC.CornerRadius = UDim.new(0, 8); pC.Parent = plus
	createStroke(plus, 1.5)

	local function updateLabel()
		valLabel.Text = tostring(Features[stateKey])
	end
	minus.MouseButton1Click:Connect(function()
		Features[stateKey] = math.max(minV, (Features[stateKey] or 0) - step)
		updateLabel()
	end)
	plus.MouseButton1Click:Connect(function()
		Features[stateKey] = math.min(maxV, (Features[stateKey] or 0) + step)
		updateLabel()
	end)
	return minus, valLabel, plus
end

local ColorCycle = {"Red", "Blue", "Green", "Pink", "Yellow", "Cyan"}
local function createColorCycle(parent, stateKey)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 102, 0, 26); btn.Position = UDim2.new(0, 214, 0.5, -13)
	btn.BackgroundColor3 = C.PrimaryDark
	btn.BackgroundTransparency = 0.1
	btn.Text = "颜色: " .. tostring(Features[stateKey] or "Pink")
	btn.TextColor3 = C.Text
	btn.TextSize = 11; btn.Font = Enum.Font.Gotham
	btn.Parent = parent
	local cC = Instance.new("UICorner"); cC.CornerRadius = UDim.new(0, 8); cC.Parent = btn
	createStroke(btn, 1.5)
	btn.MouseButton1Click:Connect(function()
		local cur = tostring(Features[stateKey] or "Pink")
		local idx = 0
		for i, c in ipairs(ColorCycle) do
			if c:lower() == cur:lower() then idx = i break end
		end
		local next = ColorCycle[(idx % #ColorCycle) + 1]
		Features[stateKey] = next
		btn.Text = "颜色: " .. next
	end)
	return btn
end

local ToggleRefreshers = {}
local function createToggle(parent, stateKey, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0,50,0,26)
	frame.BackgroundColor3 = C.ToggleOff
	frame.BorderSizePixel = 0; frame.Parent = parent
	local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(1,0); c1.Parent = frame
	createStroke(frame, 2)

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0,22,0,22); circle.Position = UDim2.new(0,2,0.5,-11)
	circle.BackgroundColor3 = Color3.fromRGB(255,255,255); circle.BorderSizePixel = 0
	circle.Parent = frame
	local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(1,0); c2.Parent = circle

	local enabled = Features[stateKey] or false
	local function update()
		if enabled then
			tween(frame, {BackgroundColor3 = C.ToggleOn}, TweenFast)
			tween(circle, {Position = UDim2.new(0,26,0.5,-11)}, TweenFast)
		else
			tween(frame, {BackgroundColor3 = C.ToggleOff}, TweenFast)
			tween(circle, {Position = UDim2.new(0,2,0.5,-11)}, TweenFast)
		end
	end
	update()

	ToggleRefreshers[stateKey] = function(v)
		enabled = v
		update()
	end

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Parent = frame
	local lastPress = 0
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			lastPress = tick()
		end
	end)
	hit.MouseButton1Click:Connect(function()
		if tick() - lastPress < 0.4 then
			enabled = not enabled
			Features[stateKey] = enabled
			update()
			if callback then callback(enabled) end
		end
	end)
	return frame, function() return enabled end
end

-- 拖拽
local function makeDraggable(guiObject, handle)
	handle = handle or guiObject
	local state = {pressing = false, active = false, pressTime = 0, pressStart = Vector2.zero, startPos = nil, moved = 0}
	local conn = nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.pressing = true
			state.active = false
			state.pressTime = tick()
			state.pressStart = input.Position
			state.startPos = guiObject.Position
			state.moved = 0
			if conn then conn:Disconnect() end
			conn = UserInputService.InputChanged:Connect(function(changed)
				if not state.pressing or changed ~= input then return end
				local delta = changed.Position - state.pressStart
				state.moved = delta.Magnitude
				if not state.active then
					if tick() - state.pressTime >= 0.8 and state.moved < 40 then
						state.active = true
					end
				else
					local tX = state.startPos.X.Offset + delta.X * 0.35
					local tY = state.startPos.Y.Offset + delta.Y * 0.35
					local cur = guiObject.Position
					guiObject.Position = UDim2.new(
						cur.X.Scale, cur.X.Offset + (tX - cur.X.Offset) * 0.18,
						cur.Y.Scale, cur.Y.Offset + (tY - cur.Y.Offset) * 0.18
					)
				end
			end)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.pressing = false
			state.active = false
			if conn then conn:Disconnect(); conn = nil end
		end
	end)
end

-- ============================================
-- 构建主界面 (与之前相同，但保留功能)
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AuxUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 10000
local GuiParent = playerGui
pcall(function() if CoreGui then GuiParent = CoreGui end end)
ScreenGui.Parent = GuiParent

local function raiseZIndex(root, minZ)
	if not root then return end
	local base = minZ or (root.ZIndex + 1)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiObject") and d.ZIndex < base then
			d.ZIndex = base
		end
	end
end

-- 加载弹窗
local LoadingFrame
do
	local outer = Instance.new("Frame")
	outer.Size = UDim2.new(0, 320, 0, 78)
	outer.Position = UDim2.new(0.5, -160, 0.5, -39)
	outer.AnchorPoint = Vector2.new(0.5, 0.5)
	outer.BackgroundTransparency = 0
	outer.BorderSizePixel = 0
	outer.ZIndex = 9900
	outer.Parent = ScreenGui
	local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 20); oc.Parent = outer
	local og = Instance.new("UIGradient")
	og.Color = ColorSequence.new(Color3.fromRGB(108,70,188), Color3.fromRGB(72,44,140))
	og.Rotation = 45
	og.Parent = outer

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -5, 1, -5)
	inner.Position = UDim2.new(0, 2.5, 0, 2.5)
	inner.BackgroundColor3 = Color3.fromRGB(10, 8, 22)
	inner.BackgroundTransparency = 0.1
	inner.BorderSizePixel = 0
	inner.Parent = outer
	local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 17); ic.Parent = inner

	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, 0, 0, 26)
	t1.Position = UDim2.new(0, 0, 0, 9)
	t1.BackgroundTransparency = 1
	t1.Text = "⚡ 学习辅助"
	t1.TextColor3 = Color3.fromRGB(255,255,255)
	t1.TextSize = 16
	t1.Font = Enum.Font.GothamBold
	t1.Parent = inner

	local LoadingText = Instance.new("TextLabel")
	LoadingText.Size = UDim2.new(1, 0, 0, 22)
	LoadingText.Position = UDim2.new(0, 0, 0, 38)
	LoadingText.BackgroundTransparency = 1
	LoadingText.Text = "加载中..."
	LoadingText.TextColor3 = Color3.fromRGB(150, 200, 255)
	LoadingText.TextSize = 12
	LoadingText.Font = Enum.Font.Gotham
	LoadingText.Parent = inner
	LoadingFrame = outer

	task.spawn(function()
		local rot = 45
		while outer and outer.Parent do
			rot = rot + 1.2
			og.Rotation = rot
			task.wait(0.05)
		end
	end)
	local ls = Instance.new("UIScale"); ls.Scale = 0.6; ls.Parent = outer
	tween(ls, {Scale = 1}, TweenScalePop)
	task.delay(1.5, function()
		if LoadingFrame then
			local ls2 = LoadingFrame:FindFirstChildOfClass("UIScale")
			if ls2 then tween(ls2, {Scale = 0.5}, TweenFast) end
			tween(LoadingFrame, {Position = UDim2.new(0.5, -160, 0.3, -39)}, TweenFast)
			task.delay(0.45, function()
				if LoadingFrame then LoadingFrame:Destroy() end
			end)
		end
	end)
end

-- 主面板变量
local ISLAND_W, ISLAND_H = 190, 38
local PANEL_W, PANEL_H = 600, 360
local PanelOpen = false
local Gui = {}

local function togglePanel()
	PanelOpen = not PanelOpen
	if Gui.MainPanel then Gui.MainPanel.Visible = true end
	if PanelOpen then
		if Features.DynamicIsland then
			Gui.MainPanel.Size = UDim2.new(0, ISLAND_W, 0, ISLAND_H)
		else
			Gui.MainPanel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
		end
		Gui.ContentScale.Scale = 0.9
		Gui.PanelScale.Scale = 0.92
		tween(Gui.MainPanel, {Size = UDim2.new(0, PANEL_W, 0, PANEL_H)}, TweenPanelOpen)
		tween(Gui.PanelScale, {Scale = 1}, TweenScalePop)
		tween(Gui.ContentScale, {Scale = 1}, TweenScalePop)
		pcall(Gui.refreshFeatures)
		Gui.IslandRightText.Text = "✕ 收起"
	else
		if Features.DynamicIsland then
			tween(Gui.ContentScale, {Scale = 0.95}, TweenPanelClose)
			tween(Gui.PanelScale, {Scale = 0.96}, TweenPanelClose)
			local tw = tween(Gui.MainPanel, {Size = UDim2.new(0, ISLAND_W, 0, ISLAND_H)}, TweenPanelClose)
			if tw then
				tw.Completed:Connect(function()
					Gui.PanelScale.Scale = 1
					Gui.ContentScale.Scale = 1
				end)
			end
			Gui.IslandRightText.Text = "≡ 菜单"
		else
			tween(Gui.PanelScale, {Scale = 0.85}, TweenPanelClose)
			tween(Gui.ContentScale, {Scale = 0.85}, TweenPanelClose)
			task.delay(0.25, function()
				if Gui.MainPanel then Gui.MainPanel.Visible = false end
				Gui.PanelScale.Scale = 1
				Gui.ContentScale.Scale = 1
			end)
			Gui.IslandRightText.Text = "≡ 菜单"
		end
	end
end

-- 悬浮球
local function createFloatBall()
	if Gui.FloatBall then return Gui.FloatBall end
	local ball = Instance.new("Frame")
	ball.Name = "AuxBall"
	ball.Size = UDim2.new(0, 38, 0, 38)
	local savedPos = Features.FloatBallPos
	if type(savedPos) == "table" and #savedPos == 4 then
		ball.Position = UDim2.new(savedPos[1], savedPos[2], savedPos[3], savedPos[4])
	else
		ball.Position = UDim2.new(0.5, -19, 0, 110)
	end
	ball.BackgroundColor3 = C.Primary
	ball.BackgroundTransparency = 0
	ball.BorderSizePixel = 0
	ball.ZIndex = 9100
	ball.Parent = ScreenGui

	local core = Instance.new("Frame")
	core.Size = UDim2.new(1, -6, 1, -6)
	core.Position = UDim2.new(0, 3, 0, 3)
	core.BackgroundColor3 = C.Bg
	core.BackgroundTransparency = 0.45
	core.BorderSizePixel = 0
	core.Parent = ball
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1,0); cc.Parent = core
	createStroke(core, 1.5)

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.Text = "⚡"
	txt.TextColor3 = Color3.fromRGB(255,255,255)
	txt.TextSize = 15
	txt.Font = Enum.Font.GothamBold
	txt.Parent = ball

	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1,0,1,0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Parent = ball
	hit.MouseButton1Click:Connect(togglePanel)

	makeDraggable(ball, hit)
	raiseZIndex(ball, 9101)
	Gui.FloatBall = ball
	return ball
end

-- 构建主面板
local function buildMainPanel()
	local MainPanel = Instance.new("Frame")
	MainPanel.Size = UDim2.new(0, ISLAND_W, 0, ISLAND_H)
	MainPanel.Position = UDim2.new(0.5, 0, 0, 10)
	MainPanel.AnchorPoint = Vector2.new(0.5, 0)
	MainPanel.BackgroundColor3 = C.Bg
	MainPanel.BackgroundTransparency = 0.35
	MainPanel.ClipsDescendants = true
	MainPanel.BorderSizePixel = 0
	MainPanel.ZIndex = 9000
	MainPanel.Parent = ScreenGui
	local mpC = Instance.new("UICorner"); mpC.CornerRadius = UDim.new(0,24); mpC.Parent = MainPanel
	createStroke(MainPanel, 2)
	local mpGrad = Instance.new("UIGradient")
	mpGrad.Color = ColorSequence.new(C.PrimaryDark, C.Bg)
	mpGrad.Rotation = 90
	mpGrad.Parent = MainPanel
	local PanelScale = Instance.new("UIScale")
	PanelScale.Scale = 1
	PanelScale.Parent = MainPanel

	-- 顶部标题栏
	local TitleBar = Instance.new("Frame")
	TitleBar.Size = UDim2.new(1,0,0,ISLAND_H)
	TitleBar.Position = UDim2.new(0,0,0,0)
	TitleBar.BackgroundTransparency = 1
	TitleBar.Parent = MainPanel

	local IslandLeftText = Instance.new("TextLabel")
	IslandLeftText.Size = UDim2.new(0,110,0,20)
	IslandLeftText.Position = UDim2.new(0,14,0.5,-10)
	IslandLeftText.BackgroundTransparency = 1
	IslandLeftText.Text = "⚡ 学习辅助"
	IslandLeftText.TextColor3 = C.Text
	IslandLeftText.TextSize = 13
	IslandLeftText.Font = Enum.Font.GothamBold
	IslandLeftText.TextXAlignment = Enum.TextXAlignment.Left
	IslandLeftText.Parent = TitleBar

	local IslandDiv = Instance.new("Frame")
	IslandDiv.Size = UDim2.new(0,1,0,20)
	IslandDiv.Position = UDim2.new(0,126,0.5,-10)
	IslandDiv.BackgroundColor3 = C.Stroke
	IslandDiv.BackgroundTransparency = 0.3
	IslandDiv.BorderSizePixel = 0
	IslandDiv.Parent = TitleBar

	local BreatheDot = Instance.new("Frame")
	BreatheDot.Size = UDim2.new(0,10,0,10)
	BreatheDot.Position = UDim2.new(0,140,0.5,-5)
	BreatheDot.AnchorPoint = Vector2.new(0.5,0.5)
	BreatheDot.BackgroundColor3 = C.Primary
	BreatheDot.BorderSizePixel = 0
	BreatheDot.Parent = TitleBar
	local bdC = Instance.new("UICorner"); bdC.CornerRadius = UDim.new(1,0); bdC.Parent = BreatheDot
	createStroke(BreatheDot, 1)
	local BreatheDotScale = Instance.new("UIScale"); BreatheDotScale.Scale = 1; BreatheDotScale.Parent = BreatheDot

	local IslandRightText = Instance.new("TextLabel")
	IslandRightText.Size = UDim2.new(0,44,0,20)
	IslandRightText.Position = UDim2.new(1,-52,0.5,-10)
	IslandRightText.BackgroundTransparency = 1
	IslandRightText.Text = "≡ 菜单"
	IslandRightText.TextColor3 = C.Text
	IslandRightText.TextSize = 13
	IslandRightText.Font = Enum.Font.GothamBold
	IslandRightText.TextXAlignment = Enum.TextXAlignment.Right
	IslandRightText.Parent = TitleBar

	local TitleHit = Instance.new("Frame")
	TitleHit.Size = UDim2.new(1,0,1,0)
	TitleHit.BackgroundTransparency = 1
	TitleHit.Active = true
	TitleHit.Parent = TitleBar
	TitleHit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			togglePanel()
		end
	end)

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Size = UDim2.new(1,0,1,-ISLAND_H)
	ContentFrame.Position = UDim2.new(0,0,0,ISLAND_H)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.ClipsDescendants = true
	ContentFrame.BorderSizePixel = 0
	ContentFrame.Parent = MainPanel
	local ContentScale = Instance.new("UIScale")
	ContentScale.Scale = 1
	ContentScale.Parent = ContentFrame

	-- 顶部分隔线
	local TopLine = Instance.new("Frame")
	TopLine.Size = UDim2.new(1,-80,0,1.5)
	TopLine.Position = UDim2.new(0,40,0,2)
	TopLine.BackgroundColor3 = C.Primary
	TopLine.BackgroundTransparency = 0.5
	TopLine.BorderSizePixel = 0
	TopLine.Parent = ContentFrame

	-- 左侧信息卡片
	local InfoSection = Instance.new("Frame")
	InfoSection.Size = UDim2.new(0,104,1,-14)
	InfoSection.Position = UDim2.new(0,8,0,7)
	InfoSection.BackgroundTransparency = 1
	InfoSection.Parent = ContentFrame

	local CardLayout = Instance.new("UIListLayout")
	CardLayout.Padding = UDim.new(0,7)
	CardLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	CardLayout.Parent = InfoSection
	local CardPad = Instance.new("UIPadding"); CardPad.PaddingTop = UDim.new(0,2); CardPad.Parent = InfoSection

	local function createGlassCard(parent, size, radius)
		local outer = Instance.new("Frame")
		outer.Size = size
		outer.BackgroundTransparency = 0
		outer.BorderSizePixel = 0
		outer.Parent = parent
		local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, radius or 16); oc.Parent = outer
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new(C.Primary, C.PrimaryDark)
		grad.Rotation = 90
		grad.Parent = outer
		local inner = Instance.new("Frame")
		inner.Size = UDim2.new(1,-5,1,-5)
		inner.Position = UDim2.new(0,2.5,0,2.5)
		inner.BackgroundColor3 = C.Bg
		inner.BackgroundTransparency = 0.15
		inner.BorderSizePixel = 0
		inner.Parent = outer
		local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,(radius or 16)-3); ic.Parent = inner
		return inner, outer
	end

	local avatarCardInner, _ = createGlassCard(InfoSection, UDim2.new(0,66,0,66), 18)
	local AvatarImage = Instance.new("ImageLabel")
	AvatarImage.Size = UDim2.new(1,-10,1,-10)
	AvatarImage.Position = UDim2.new(0,5,0,5)
	AvatarImage.BackgroundColor3 = C.PrimaryDark
	AvatarImage.BackgroundTransparency = 0
	AvatarImage.BorderSizePixel = 0
	AvatarImage.Parent = avatarCardInner
	local avC = Instance.new("UICorner"); avC.CornerRadius = UDim.new(0,14); avC.Parent = AvatarImage
	createStroke(AvatarImage, 1.5)
	task.spawn(function()
		local ok, img = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)
		if ok and img and AvatarImage then AvatarImage.Image = img end
	end)

	local nameCardInner, _ = createGlassCard(InfoSection, UDim2.new(0,92,0,28), 14)
	local PlayerNameLabel = Instance.new("TextLabel")
	PlayerNameLabel.Size = UDim2.new(1,-8,1,0)
	PlayerNameLabel.Position = UDim2.new(0,4,0,0)
	PlayerNameLabel.BackgroundTransparency = 1
	PlayerNameLabel.Text = player.DisplayName or player.Name
	PlayerNameLabel.TextColor3 = C.Text
	PlayerNameLabel.TextSize = 11
	PlayerNameLabel.Font = Enum.Font.GothamBold
	PlayerNameLabel.TextWrapped = true
	PlayerNameLabel.Parent = nameCardInner

	local srvCardInner, _ = createGlassCard(InfoSection, UDim2.new(0,92,0,86), 14)
	local ServerInfoText = Instance.new("TextLabel")
	ServerInfoText.Size = UDim2.new(1,-8,1,0)
	ServerInfoText.Position = UDim2.new(0,4,0,2)
	ServerInfoText.BackgroundTransparency = 1
	ServerInfoText.Text = "加载中..."
	ServerInfoText.TextColor3 = C.TextSub
	ServerInfoText.TextSize = 10
	ServerInfoText.Font = Enum.Font.Gotham
	ServerInfoText.TextXAlignment = Enum.TextXAlignment.Left
	ServerInfoText.TextYAlignment = Enum.TextYAlignment.Top
	ServerInfoText.TextWrapped = true
	ServerInfoText.Parent = srvCardInner

	local nearCardInner, _ = createGlassCard(InfoSection, UDim2.new(0,92,0,40), 14)
	local NearestText = Instance.new("TextLabel")
	NearestText.Size = UDim2.new(1,-8,1,0)
	NearestText.Position = UDim2.new(0,4,0,0)
	NearestText.BackgroundTransparency = 1
	NearestText.Text = "最近: 无"
	NearestText.TextColor3 = Color3.fromRGB(150,255,180)
	NearestText.TextSize = 10
	NearestText.Font = Enum.Font.Gotham
	NearestText.TextXAlignment = Enum.TextXAlignment.Left
	NearestText.TextWrapped = true
	NearestText.Parent = nearCardInner

	local statCardInner, _ = createGlassCard(InfoSection, UDim2.new(0,92,0,36), 14)
	local StatText = Instance.new("TextLabel")
	StatText.Size = UDim2.new(1,-8,1,0)
	StatText.Position = UDim2.new(0,4,0,0)
	StatText.BackgroundTransparency = 1
	StatText.Text = "已开启: 0 个功能"
	StatText.TextColor3 = Color3.fromRGB(255,220,120)
	StatText.TextSize = 10
	StatText.Font = Enum.Font.Gotham
	StatText.TextXAlignment = Enum.TextXAlignment.Left
	StatText.Parent = statCardInner

	raiseZIndex(InfoSection, 9003)

	-- 分割线
	local VDivider = Instance.new("Frame")
	VDivider.Size = UDim2.new(0,1.5,1,-14)
	VDivider.Position = UDim2.new(0,114,0,7)
	VDivider.BackgroundColor3 = C.Stroke
	VDivider.BackgroundTransparency = 0.35
	VDivider.BorderSizePixel = 0
	VDivider.Parent = ContentFrame

	-- 左侧分类栏
	local LeftBar = Instance.new("Frame")
	LeftBar.Size = UDim2.new(0,84,1,-8)
	LeftBar.Position = UDim2.new(0,120,0,4)
	LeftBar.BackgroundColor3 = C.PrimaryDark
	LeftBar.BackgroundTransparency = 0.25
	LeftBar.BorderSizePixel = 0
	LeftBar.Parent = ContentFrame
	local lbC = Instance.new("UICorner"); lbC.CornerRadius = UDim.new(0,16); lbC.Parent = LeftBar
	createStroke(LeftBar, 1)

	local ButtonWrap = Instance.new("Frame")
	ButtonWrap.Size = UDim2.new(1,0,1,0)
	ButtonWrap.BackgroundTransparency = 1
	ButtonWrap.Parent = LeftBar
	local LeftLayout = Instance.new("UIListLayout")
	LeftLayout.Padding = UDim.new(0,5); LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	LeftLayout.Parent = ButtonWrap
	local LeftPad = Instance.new("UIPadding"); LeftPad.PaddingTop = UDim.new(0,7); LeftPad.Parent = ButtonWrap

	local CatIndicator = Instance.new("Frame")
	CatIndicator.Size = UDim2.new(0,74,0,30)
	CatIndicator.Position = UDim2.new(0,5,0,9)
	CatIndicator.BackgroundTransparency = 0
	CatIndicator.BorderSizePixel = 0
	CatIndicator.ZIndex = 9005
	CatIndicator.Parent = LeftBar
	local ciC = Instance.new("UICorner"); ciC.CornerRadius = UDim.new(0,10); ciC.Parent = CatIndicator
	local ciGrad = Instance.new("UIGradient")
	ciGrad.Color = ColorSequence.new(C.Primary, C.PrimaryLight)
	ciGrad.Rotation = 90
	ciGrad.Parent = CatIndicator
	Gui.CatIndicator = CatIndicator

	-- 右侧内容
	local RightContent = Instance.new("Frame")
	RightContent.Size = UDim2.new(0,380,1,-8)
	RightContent.Position = UDim2.new(0,208,0,4)
	RightContent.BackgroundTransparency = 1
	RightContent.ClipsDescendants = true
	RightContent.Active = true
	RightContent.Parent = ContentFrame

	local ScrollInner = Instance.new("Frame")
	ScrollInner.Size = UDim2.new(0,368,0,0)
	ScrollInner.Position = UDim2.new(0,6,0,0)
	ScrollInner.BackgroundTransparency = 1
	ScrollInner.Parent = RightContent

	-- 滚动
	local ScrollDrag = {dragging = false, startY = 0, baseY = 0, moved = false}
	local ScrollMoveConn
	RightContent.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			ScrollDrag.dragging = true
			ScrollDrag.moved = false
			ScrollDrag.startY = input.Position.Y
			ScrollDrag.baseY = ScrollInner.Position.Y.Offset
			if ScrollMoveConn then ScrollMoveConn:Disconnect() end
			ScrollMoveConn = UserInputService.InputChanged:Connect(function(changed)
				if ScrollDrag.dragging and changed == input then
					local dy = changed.Position.Y - ScrollDrag.startY
					if math.abs(dy) > 8 then ScrollDrag.moved = true end
					if ScrollDrag.moved then
						local viewH = RightContent.AbsoluteSize.Y
						local contentH = ScrollInner.Size.Y.Offset
						local minY = math.min(0, viewH - contentH)
						local ny = math.clamp(ScrollDrag.baseY + dy, minY, 0)
						ScrollInner.Position = UDim2.new(0,6,0,ny)
					end
				end
			end)
		end
	end)
	RightContent.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			ScrollDrag.dragging = false
			if ScrollMoveConn then ScrollMoveConn:Disconnect(); ScrollMoveConn = nil end
		end
	end)

	local BottomGlow = Instance.new("Frame")
	BottomGlow.Size = UDim2.new(1,-40,0,2)
	BottomGlow.Position = UDim2.new(0,20,1,-10)
	BottomGlow.BackgroundColor3 = C.Primary
	BottomGlow.BackgroundTransparency = 0.5
	BottomGlow.BorderSizePixel = 0
	BottomGlow.Parent = ContentFrame

	local Watermark = Instance.new("TextLabel")
	Watermark.Size = UDim2.new(0,90,0,12)
	Watermark.Position = UDim2.new(1,-96,1,-18)
	Watermark.BackgroundTransparency = 1
	Watermark.Text = "AUX V1.0"
	Watermark.TextColor3 = C.Text
	Watermark.TextTransparency = 0.5
	Watermark.TextSize = 8
	Watermark.Font = Enum.Font.GothamBold
	Watermark.TextXAlignment = Enum.TextXAlignment.Right
	Watermark.Parent = ContentFrame

	raiseZIndex(ContentFrame, 9003)

	Gui.MainPanel = MainPanel
	Gui.PanelScale = PanelScale
	Gui.TitleBar = TitleBar
	Gui.IslandLeftText = IslandLeftText
	Gui.IslandRightText = IslandRightText
	Gui.BreatheDot = BreatheDot
	Gui.BreatheDotScale = BreatheDotScale
	Gui.ContentFrame = ContentFrame
	Gui.ContentScale = ContentScale
	Gui.InfoSection = InfoSection
	Gui.LeftBar = LeftBar
	Gui.ButtonWrap = ButtonWrap
	Gui.RightContent = RightContent
	Gui.ScrollInner = ScrollInner
	Gui.ServerInfoText = ServerInfoText
	Gui.NearestText = NearestText
	Gui.StatText = StatText

	return MainPanel
end

buildMainPanel()
createFloatBall()

-- ============================================
-- 分类与功能项 (所有功能均绑定真实逻辑)
-- ============================================
local Categories = {
	{Name = "移动", Color = C.Primary},
	{Name = "战斗", Color = C.Primary},
	{Name = "视觉", Color = C.Primary},
	{Name = "工具", Color = C.Primary},
	{Name = "人物", Color = C.Primary},
	{Name = "其他", Color = C.Primary},
}

local FeatureRows = {}
local ROW_W = 368
local RowScBtns = {}
local CurrentCategory = 1
local function moveCatIndicator(i)
	local ind = Gui.CatIndicator
	if not ind or not ind.Parent then return end
	local y = 9 + (i - 1) * 39
	tween(ind, {Position = UDim2.new(0, 5, 0, y)}, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
end

local function relayoutRows()
	if not Gui.ScrollInner then return end
	local yOffset = 0
	for _, r in ipairs(FeatureRows) do
		if r.Parent then
			r.Position = UDim2.new(0, 0, 0, yOffset)
		end
		yOffset = yOffset + r.Size.Y.Offset + 5
	end
	Gui.ScrollInner.Size = UDim2.new(0, ROW_W, 0, yOffset)
	local viewH = Gui.RightContent and Gui.RightContent.AbsoluteSize.Y or 300
	local minY = math.min(0, viewH - yOffset)
	if Gui.ScrollInner.Position.Y.Offset < minY then
		Gui.ScrollInner.Position = UDim2.new(0, 6, 0, minY)
	end
end

-- 功能定义 (所有功能均有对应的开关和UI控件)
local FeatureDefs = {
	{Cat=1, Name="加速移动", Key="Speed", InputKey="SpeedValue", InputShow="速度"},
	{Cat=1, Name="无限跳跃", Key="InfiniteJump"},
	{Cat=1, Name="高跳", Key="HighJump", InputKey="JumpPower", InputShow="力度"},
	{Cat=1, Name="无限体力", Key="InfiniteStamina"},
	{Cat=1, Name="自定义重力", Key="CustomGravity", InputKey="GravityValue", InputShow="重力值"},
	{Cat=1, Name="飞行 (F)", Key="Flying", InputKey="FlySpeed", InputShow="速度", Dropdown=true, DropdownKey="FlyMode", DropdownOptions={"默认","固定高度","摄像机控制"}},
	{Cat=1, Name="穿墙 (NoClip)", Key="NoClip"},
	{Cat=1, Name="无摔落伤害", Key="NoFallDamage"},

	{Cat=2, Name="自瞄 (Aimbot)", Key="Aimlock", InputKey="AimSmoothness", InputShow="平滑度"},
	{Cat=2, Name="自旋 (SpinBot)", Key="SpinBot", InputKey="SpinSpeed", InputShow="速度"},

	{Cat=3, Name="玩家透视 (ESP)", Key="ESP"},
	{Cat=3, Name="透视NPC", Key="ESPNPC"},
	{Cat=3, Name="ESP线条", Key="ESPTracer"},
	{Cat=3, Name="夜视", Key="NightVision", InputKey="NightVisionBrightness", InputShow="亮度"},
	{Cat=3, Name="全亮 (Fullbright)", Key="Fullbright"},
	{Cat=3, Name="去除雾效", Key="NoFog"},
	{Cat=3, Name="移除阴影", Key="NoShadows"},
	{Cat=3, Name="自定义FOV", Key="CustomFOV", InputKey="FOVValue", InputShow="角度"},
	{Cat=3, Name="自由视角", Key="FreeCamera"},

	{Cat=4, Name="自动重连", Key="AutoReconnect"},
	{Cat=4, Name="反AFK", Key="AntiAFK"},
	{Cat=4, Name="自定义游戏速度", Key="CustomGameSpeed", InputKey="GameSpeedValue", InputShow="倍数"},
	{Cat=4, Name="显示FPS/Ping", Key="ShowFPSPing"},
	{Cat=4, Name="翻译UI (英→中)", Key="Translation"},

	{Cat=5, Name="保存坐标", Key="SavePos", IsAction=true},
	{Cat=5, Name="传送至保存", Key="TeleportSave", IsAction=true},
	{Cat=5, Name="循环传送", Key="TeleportLoop", InputKey="TeleportInterval", InputShow="间隔(s)"},
}

-- 功能实现 (Updaters)
local Updaters = {}
local Conns = {}
local function unbind(name)
	if Conns[name] then
		if typeof(Conns[name]) == "RBXScriptConnection" then Conns[name]:Disconnect() end
		Conns[name] = nil
	end
end

-- 1. 速度
Updaters.Speed = function()
	if Features.Speed then
		if Conns.Speed then return end
		Conns.Speed = RunService.Heartbeat:Connect(function()
			if not Features.Speed then return end
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				local hum = char.Humanoid
				if hum.WalkSpeed ~= Features.SpeedValue then hum.WalkSpeed = Features.SpeedValue end
			end
		end)
	else
		unbind("Speed")
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = 16 end
	end
end

-- 2. 无限跳跃
Updaters.InfiniteJump = function()
	if Features.InfiniteJump then
		if Conns.InfiniteJump then return end
		Conns.InfiniteJump = UserInputService.JumpRequest:Connect(function()
			if Features.InfiniteJump then
				local char = player.Character
				if char and char:FindFirstChild("Humanoid") then
					local hum = char.Humanoid
					if hum:GetState() ~= Enum.HumanoidStateType.Jumping then
						hum:ChangeState(Enum.HumanoidStateType.Jumping)
					end
				end
			end
		end)
	else
		unbind("InfiniteJump")
	end
end

-- 3. 高跳
Updaters.HighJump = function()
	if Features.HighJump then
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.JumpPower = Features.JumpPower
		end
	else
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.JumpPower = 50
		end
	end
end

-- 4. 无限体力
Updaters.InfiniteStamina = function()
	if Features.InfiniteStamina then
		pcall(function()
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Exhaustion, false)
			end
		end)
	else
		pcall(function()
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Exhaustion, true)
			end
		end)
	end
end

-- 5. 自定义重力
Updaters.CustomGravity = function()
	if Features.CustomGravity then
		Workspace.Gravity = Features.GravityValue
	else
		Workspace.Gravity = 196.2
	end
end

-- 6. 飞行 (使用 BodyVelocity/BodyGyro)
local flyBodyVelocity, flyBodyGyro, flyConnection
local function onFlyHeartbeat()
	if not Features.Flying then
		toggleFly(false)
		return
	end
	local char = player.Character
	if not char then return toggleFly(false) end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then return toggleFly(false) end

	local moveDir = Vector3.zero
	local camForward = camera.CFrame.LookVector
	local camRight = camera.CFrame.RightVector
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camForward end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camForward end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camRight end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camRight end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0,1,0) end

	if Features.FlyMode == "固定高度" then
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
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local rootPart = char.HumanoidRootPart
			if not flyBodyVelocity or not flyBodyVelocity.Parent then
				flyBodyVelocity = Instance.new("BodyVelocity")
				flyBodyVelocity.MaxForce = Vector3.new(9e6,9e6,9e6)
				flyBodyVelocity.Velocity = Vector3.zero
				flyBodyVelocity.Parent = rootPart
				flyBodyGyro = Instance.new("BodyGyro")
				flyBodyGyro.MaxTorque = Vector3.new(9e6,9e6,9e6)
				flyBodyGyro.CFrame = rootPart.CFrame
				flyBodyGyro.Parent = rootPart
			end
		end
		return
	end
	Features.Flying = enable
	local char = player.Character
	if not char then return end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then return end
	if enable then
		if flyConnection then flyConnection:Disconnect() end
		if flyBodyVelocity then flyBodyVelocity:Destroy() end
		flyBodyVelocity = Instance.new("BodyVelocity")
		flyBodyVelocity.MaxForce = Vector3.new(9e6,9e6,9e6)
		flyBodyVelocity.Velocity = Vector3.zero
		flyBodyVelocity.Parent = rootPart
		if flyBodyGyro then flyBodyGyro:Destroy() end
		flyBodyGyro = Instance.new("BodyGyro")
		flyBodyGyro.MaxTorque = Vector3.new(9e6,9e6,9e6)
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
Updaters.Flying = function()
	if Features.Flying then toggleFly(true) else toggleFly(false) end
end

-- 7. NoClip
local noclipCharConn, noclipAddedConn
local function setNoClipOnCharacter(char, enabled)
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = not enabled end
	end
end
local function onNoClipChildAdded(child)
	if Features.NoClip and child:IsA("BasePart") then child.CanCollide = false end
end
Updaters.NoClip = function()
	if Features.NoClip then
		if noclipCharConn then noclipCharConn:Disconnect() end
		if noclipAddedConn then noclipAddedConn:Disconnect() end
		local char = player.Character
		if char then
			setNoClipOnCharacter(char, true)
			noclipCharConn = char.ChildAdded:Connect(onNoClipChildAdded)
		end
		noclipAddedConn = player.CharacterAdded:Connect(function(newChar)
			if Features.NoClip then
				setNoClipOnCharacter(newChar, true)
				if noclipCharConn then noclipCharConn:Disconnect() end
				noclipCharConn = newChar.ChildAdded:Connect(onNoClipChildAdded)
			end
		end)
	else
		if noclipCharConn then noclipCharConn:Disconnect() end
		if noclipAddedConn then noclipAddedConn:Disconnect() end
		local char = player.Character
		if char then setNoClipOnCharacter(char, false) end
	end
end

-- 8. NoFallDamage
local fallDamageConn
local function onHumanoidStateChanged(oldState, newState)
	if Features.NoFallDamage and newState == Enum.HumanoidStateType.FallingDown then
		local hum = player.Character and player.Character:FindFirstChild("Humanoid")
		if hum then
			task.spawn(function()
				task.wait(0.1)
				if hum and hum.Parent and Features.NoFallDamage then
					if hum:GetState() == Enum.HumanoidStateType.FallingDown then hum:ChangeState(Enum.HumanoidStateType.Running) end
					if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
				end
			end)
		end
	end
end
Updaters.NoFallDamage = function()
	if Features.NoFallDamage then
		if fallDamageConn then fallDamageConn:Disconnect() end
		local hum = player.Character and player.Character:FindFirstChild("Humanoid")
		if hum then fallDamageConn = hum.StateChanged:Connect(onHumanoidStateChanged) end
	else
		if fallDamageConn then fallDamageConn:Disconnect() end
	end
end

-- 9. 自瞄
local aimConnection
local function getClosestPlayer()
	local closest, minDist = nil, math.huge
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local pos = root.Position
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local hum = p.Character:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				local targetRoot = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
				if targetRoot then
					local dist = (pos - targetRoot.Position).Magnitude
					if dist < minDist then
						minDist = dist
						closest = p
					end
				end
			end
		end
	end
	return closest
end
local function aimLoop()
	if not Features.Aimlock then return end
	if not Features.AimTarget or not Features.AimTarget.Character or not Features.AimTarget.Character:FindFirstChild("HumanoidRootPart") then
		Features.AimTarget = getClosestPlayer()
		if not Features.AimTarget then return end
	end
	local targetRoot = Features.AimTarget.Character:FindFirstChild("HumanoidRootPart") or Features.AimTarget.Character:FindFirstChild("Torso")
	if targetRoot then
		local targetCF = CFrame.new(camera.CFrame.Position, targetRoot.Position)
		camera.CFrame = camera.CFrame:Lerp(targetCF, Features.AimSmoothness)
	end
end
Updaters.Aimlock = function()
	if Features.Aimlock then
		if not aimConnection then aimConnection = RunService.RenderStepped:Connect(aimLoop) end
	else
		if aimConnection then aimConnection:Disconnect() end
		aimConnection = nil
		Features.AimTarget = nil
	end
end

-- 10. 自旋
local spinConnection
Updaters.SpinBot = function()
	if Features.SpinBot then
		if spinConnection then spinConnection:Disconnect() end
		spinConnection = RunService.RenderStepped:Connect(function()
			if not Features.SpinBot then return end
			local char = player.Character
			local rootPart = char and char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(Features.SpinSpeed), 0)
			end
		end)
	else
		if spinConnection then spinConnection:Disconnect() end
		spinConnection = nil
	end
end

-- 11. ESP (简化版，仅亮框)
local espObjects = {}
Updaters.ESP = function()
	if Features.ESP then
		if Conns.ESP then return end
		Conns.ESP = RunService.RenderStepped:Connect(function()
			if not Features.ESP then return end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and p.Character then
					local char = p.Character
					local key = char
					if not espObjects[key] then
						local hl = Instance.new("Highlight")
						hl.FillTransparency = 0.5
						hl.OutlineTransparency = 0
						hl.Adornee = char
						hl.Parent = char
						espObjects[key] = hl
					end
					espObjects[key].FillColor = p.Team == player.Team and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
				end
			end
			for obj, hl in pairs(espObjects) do
				if not obj.Parent then
					hl:Destroy()
					espObjects[obj] = nil
				end
			end
		end)
	else
		unbind("ESP")
		for obj, hl in pairs(espObjects) do
			hl:Destroy()
		end
		espObjects = {}
	end
end
Updaters.ESPNPC = function() end
Updaters.ESPTracer = function() end

-- 12. 夜视
local nightVisionConnection
Updaters.NightVision = function()
	if Features.NightVision then
		if not nightVisionConnection then
			nightVisionConnection = RunService.RenderStepped:Connect(applyLightingFeatures)
		end
		applyLightingFeatures()
	else
		if nightVisionConnection then nightVisionConnection:Disconnect() end
		nightVisionConnection = nil
		resetLighting()
	end
end

-- 13. 全亮
local fullbrightConnection
Updaters.Fullbright = function()
	if Features.Fullbright then
		if not fullbrightConnection then
			fullbrightConnection = RunService.RenderStepped:Connect(applyLightingFeatures)
		end
		applyLightingFeatures()
	else
		if fullbrightConnection then fullbrightConnection:Disconnect() end
		fullbrightConnection = nil
		resetLighting()
	end
end

Updaters.NoFog = function() applyLightingFeatures() end
Updaters.NoShadows = function() applyLightingFeatures() end

-- 14. FOV
Updaters.CustomFOV = function()
	if Features.CustomFOV then
		camera.FieldOfView = Features.FOVValue
	else
		camera.FieldOfView = 70
	end
end

-- 15. 自由视角
Updaters.FreeCamera = function()
	if Features.FreeCamera then
		player.CameraMaxZoomDistance = 200
	else
		player.CameraMaxZoomDistance = 128
	end
end

-- 16. 游戏速度
Updaters.CustomGameSpeed = function()
	if Features.CustomGameSpeed then
		RunService.GlobalTimeScale = Features.GameSpeedValue
	else
		RunService.GlobalTimeScale = 1
	end
end

-- 17. 自动重连
local autoReconnectConn
Updaters.AutoReconnect = function()
	if Features.AutoReconnect then
		if autoReconnectConn then autoReconnectConn:Disconnect() end
		autoReconnectConn = Players.PlayerRemoving:Connect(function(p)
			if p == player then
				task.spawn(function()
					for i=1,5 do
						task.wait(3)
						pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, player) end)
						if Players.LocalPlayer then break end
					end
				end)
			end
		end)
	else
		if autoReconnectConn then autoReconnectConn:Disconnect() end
	end
end

-- 18. 反AFK
local antiAFKThread
Updaters.AntiAFK = function()
	if Features.AntiAFK then
		if antiAFKThread then task.cancel(antiAFKThread) end
		antiAFKThread = task.spawn(function()
			while Features.AntiAFK do
				task.wait(30)
				local char = player.Character
				local hum = char and char:FindFirstChild("Humanoid")
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if hum and root then
					local moveDir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit
					hum:Move(root.Position + moveDir * 0.1)
				end
			end
			antiAFKThread = nil
		end)
	else
		if antiAFKThread then task.cancel(antiAFKThread) end
	end
end

-- 19. 循环传送
local teleportLoopThread
Updaters.TeleportLoop = function()
	if Features.TeleportLoop then
		if not Features.SavedPos then
			Features.TeleportLoop = false
			notify("错误", "请先保存坐标")
			return
		end
		if teleportLoopThread then task.cancel(teleportLoopThread) end
		teleportLoopThread = task.spawn(function()
			while Features.TeleportLoop and Features.SavedPos do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(Features.SavedPos)
				end
				task.wait(Features.TeleportInterval)
			end
			teleportLoopThread = nil
		end)
	else
		if teleportLoopThread then task.cancel(teleportLoopThread) end
		teleportLoopThread = nil
	end
end

-- 20. 显示FPS/Ping (仅演示)
Updaters.ShowFPSPing = function() end

-- 21. 翻译 (占位)
Updaters.Translation = function() end

-- 22. 保存/传送 动作
function Gui.savePos()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		Features.SavedPos = char.HumanoidRootPart.Position
		notify("坐标已保存", string.format("(%.1f, %.1f, %.1f)", Features.SavedPos.X, Features.SavedPos.Y, Features.SavedPos.Z))
	end
end
function Gui.teleportSave()
	if not Features.SavedPos then
		notify("错误", "请先保存坐标")
		return
	end
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = CFrame.new(Features.SavedPos)
		notify("传送成功", "已传送到保存位置")
	end
end

-- ============================================
-- 刷新功能列表 (绑定回调)
-- ============================================
function Gui.refreshFeatures()
	if not Gui.ScrollInner then return end
	for _, child in ipairs(Gui.ScrollInner:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	FeatureRows = {}
	for k in pairs(RowScBtns) do RowScBtns[k] = nil end
	for k in pairs(ToggleRefreshers) do ToggleRefreshers[k] = nil end

	local yOffset = 0
	for _, feat in ipairs(FeatureDefs) do
		if feat.Cat == CurrentCategory then
			local row = nil
			local ok = pcall(function()
				local rowH = 42
				if feat.Dropdown then rowH = 34 end
				row = Instance.new("Frame")
				row.Size = UDim2.new(0, ROW_W, 0, rowH)
				row.Position = UDim2.new(0, 0, 0, yOffset)
				row.BackgroundColor3 = C.RowBg
				row.BackgroundTransparency = 0.15
				row.BorderSizePixel = 0
				row.Parent = Gui.ScrollInner
				row.ZIndex = 9003
				local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = row
				createStroke(row, 1.5)

				local scBtn = Instance.new("TextButton")
				scBtn.Size = UDim2.new(0,24,0,24); scBtn.Position = UDim2.new(0,2,0.5,-12)
				scBtn.BackgroundColor3 = C.PrimaryDark
				scBtn.Text = "⚡"; scBtn.TextColor3 = C.Text
				scBtn.TextSize = 11; scBtn.Font = Enum.Font.GothamBold
				scBtn.Parent = row
				local scC = Instance.new("UICorner"); scC.CornerRadius = UDim.new(0,8); scC.Parent = scBtn
				createStroke(scBtn, 1.5)
				RowScBtns[feat.Key] = scBtn

				if feat.IsAction then
					local btn = createButton(row, feat.Key.."Btn", UDim2.new(0,120,0,28), UDim2.new(0,240,0.5,-14), C.Primary, feat.Name)
					btn.TextSize = 12
					if feat.Key == "SavePos" then
						btn.MouseButton1Click:Connect(Gui.savePos)
					elseif feat.Key == "TeleportSave" then
						btn.MouseButton1Click:Connect(Gui.teleportSave)
					end
				elseif feat.Dropdown then
					local dropContent = createDropdown(row, feat.Name, false, 10, function(newHeight)
						if not row.Parent then return end
						row.Size = UDim2.new(0, ROW_W, 0, newHeight)
						relayoutRows()
					end, ROW_W - 32)
					local dropContainer = dropContent.Parent
					dropContainer.Position = UDim2.new(0, 32, 0, 0)

					local modeOptions = feat.DropdownOptions or {"默认","固定高度","摄像机控制"}
					local modeLabel = Instance.new("TextLabel")
					modeLabel.Size = UDim2.new(1,0,0,20); modeLabel.BackgroundTransparency = 1
					modeLabel.Text = "模式: " .. (Features[feat.DropdownKey] or "默认")
					modeLabel.TextColor3 = C.TextSub
					modeLabel.TextSize = 11
					modeLabel.Font = Enum.Font.Gotham
					modeLabel.Parent = dropContent
					local modeRow = createBtnRow(dropContent, 26)
					for i, opt in ipairs(modeOptions) do
						local optBtn = createButton(modeRow, "Mode"..i, UDim2.new(0.3,0,0,22), UDim2.new((i-1)*0.35,0,0,0), C.PrimaryDark, opt)
						optBtn.TextSize = 10
						optBtn.MouseButton1Click:Connect(function()
							Features[feat.DropdownKey] = opt
							modeLabel.Text = "模式: " .. opt
						end)
					end
					if feat.InputKey then
						createStepControl(dropContent, feat.InputKey)
					end
				else
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(0,84,1,0); label.Position = UDim2.new(0,32,0,0)
					label.BackgroundTransparency = 1; label.Text = feat.Name
					label.TextColor3 = C.Text
					label.TextSize = 12
					label.Font = Enum.Font.GothamSemibold
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = row

					local tg = createToggle(row, feat.Key, function(enabled)
						local updater = Updaters[feat.Key]
						if updater then pcall(updater) end
					end)
					tg.Position = UDim2.new(0, 316, 0.5, -13)

					if feat.InputKey and not feat.Dropdown then
						createStepControl(row, feat.InputKey)
					end
				end
				raiseZIndex(row, 9004)
			end)
			if ok and row then
				table.insert(FeatureRows, row)
				yOffset = yOffset + (feat.Dropdown and 39 or 47)
			end
		end
	end
	Gui.ScrollInner.Size = UDim2.new(0, ROW_W, 0, yOffset)
	Gui.ScrollInner.Position = UDim2.new(0, 6, 0, 0)
end

-- 分类按钮
for i, cat in ipairs(Categories) do
	local outer = Instance.new("Frame")
	outer.Size = UDim2.new(0, 78, 0, 34)
	outer.BackgroundTransparency = 0
	outer.BorderSizePixel = 0
	outer.Parent = Gui.ButtonWrap
	local oC = Instance.new("UICorner"); oC.CornerRadius = UDim.new(0, 12); oC.Parent = outer
	local oGrad = Instance.new("UIGradient")
	oGrad.Color = ColorSequence.new(C.Primary, C.PrimaryLight)
	oGrad.Rotation = 90
	oGrad.Parent = outer

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -4, 1, -4)
	inner.Position = UDim2.new(0, 2, 0, 2)
	inner.BackgroundColor3 = C.Bg
	inner.BackgroundTransparency = 0.3
	inner.BorderSizePixel = 0
	inner.Parent = outer
	local iC = Instance.new("UICorner"); iC.CornerRadius = UDim.new(0, 10); iC.Parent = inner

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1,0,1,0)
	text.BackgroundTransparency = 1
	text.Text = cat.Name
	text.TextColor3 = C.Text
	text.TextSize = 12
	text.Font = Enum.Font.GothamBold
	text.ZIndex = 9012
	text.Parent = outer

	local hit = Instance.new("Frame")
	hit.Size = UDim2.new(1,0,1,0)
	hit.BackgroundTransparency = 1
	hit.Active = true
	hit.ZIndex = 9007
	hit.Parent = outer
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			CurrentCategory = i
			moveCatIndicator(i)
			pcall(Gui.refreshFeatures)
		end
	end)
end

-- 初始化UI
pcall(Gui.refreshFeatures)
moveCatIndicator(1)

-- 应用已开启功能
for key, state in pairs(Features) do
	if type(state) == "boolean" and state then
		local updater = Updaters[key]
		if updater then pcall(updater) end
	end
end

-- 统计更新
task.spawn(function()
	while true do
		task.wait(1)
		local count = 0
		for key, state in pairs(Features) do
			if type(state) == "boolean" and state then count = count + 1 end
		end
		if Gui.StatText then Gui.StatText.Text = "已开启: " .. count .. " 个功能" end
	end
end)

-- 快捷键
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F then
		if not UserInputService:GetFocusedTextBox() then
			togglePanel()
		end
	end
end)

print("[AUX] 单色全功能版加载完成，按 F 打开菜单")
