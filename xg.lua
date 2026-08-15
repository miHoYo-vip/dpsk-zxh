-- ============================================
-- 纯 UI 模板 (基于 Ninja Hub V6.1 界面)
-- 仅保留菜单展示与交互，无任何实际功能
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local LoadStartTime = tick()

-- 高饱和配色方案
local C = {
	Btn = Color3.fromRGB(88, 60, 160),
	BtnDark = Color3.fromRGB(64, 44, 120),
	Val = Color3.fromRGB(52, 36, 104),
	RowBg = Color3.fromRGB(30, 20, 66),
	TextSub = Color3.fromRGB(190, 195, 245),
}
local function createGrayStroke(parent, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(185, 185, 225)
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local PartColorOffsets = {}
local function getRainbowColor(offset, speed)
	speed = speed or 0.5
	local t = tick() * speed + (offset or 0)
	return Color3.fromHSV(t % 1, 1, 1)
end
local function getPartColor(key)
	if type(key) ~= "string" then key = tostring(key) end
	local off = PartColorOffsets[key]
	if not off then
		off = math.random() * 100
		PartColorOffsets[key] = off
	end
	return getRainbowColor(off, 0.05)
end

-- UI 状态（仅用于显示，不执行任何功能）
local States = {
	DynamicIsland = {Enabled = true},
	FloatBallPos = {0.5, -19, 0, 110},
	DemoToggle1 = {Enabled = false},
	DemoToggle2 = {Enabled = false},
	DemoSlider = {Value = 50},
	DemoDropdown = {Value = "选项 A"},
	DemoColor = {Value = "Pink"},
}

-- 辅助 UI 函数
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
	btn.BackgroundColor3 = color or C.Btn
	btn.Text = text or ""; btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize = 14; btn.Font = Enum.Font.GothamSemibold
	btn.AutoButtonColor = true; btn.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,14); c.Parent = btn
	return btn
end

-- 多选框 (checkbox)
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
	box.BackgroundColor3 = defaultValue and Color3.fromRGB(0,210,110) or Color3.fromRGB(96,72,170)
	box.BorderSizePixel = 0
	box.Parent = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = box
	createGrayStroke(box, 1.5)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,-30,1,0); label.Position = UDim2.new(0,26,0,0)
	label.BackgroundTransparency = 1; label.Text = text
	label.TextColor3 = Color3.fromRGB(230,230,255); label.TextSize = 12
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
			tween(box, {BackgroundColor3 = checked and Color3.fromRGB(0,210,110) or Color3.fromRGB(96,72,170)}, TweenFast)
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

-- 下拉菜单
local function createDropdown(parent, title, defaultOpen, leftPadding, onHeightChange, width)
	local W = width or 336
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, W, 0, 34)
	container.BackgroundColor3 = Color3.fromRGB(62,42,128)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = parent
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,12); cc.Parent = container
	createGrayStroke(container, 1.5)

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
	headerText.TextColor3 = Color3.fromRGB(255,255,255)
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

-- 三段式数值控件 (步进)
local StepMap = {DemoSlider = 5}
local MinMap = {DemoSlider = 1}
local MaxMap = {DemoSlider = 999}
local function createStepControl(parent, stateKey)
	local step = StepMap[stateKey] or 5
	local minV = MinMap[stateKey] or 1
	local maxV = MaxMap[stateKey] or 999

	local minus = Instance.new("TextButton")
	minus.Size = UDim2.new(0, 24, 0, 26); minus.Position = UDim2.new(0, 214, 0.5, -13)
	minus.BackgroundColor3 = C.Btn
	minus.Text = "−"; minus.TextColor3 = Color3.fromRGB(255,255,255)
	minus.TextSize = 14; minus.Font = Enum.Font.GothamBold
	minus.Parent = parent
	local mC = Instance.new("UICorner"); mC.CornerRadius = UDim.new(0, 8); mC.Parent = minus
	createGrayStroke(minus, 1.5)

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0, 50, 0, 26); valLabel.Position = UDim2.new(0, 240, 0.5, -13)
	valLabel.BackgroundColor3 = C.Val
	valLabel.BackgroundTransparency = 0.1
	valLabel.Text = tostring(States[stateKey].Value or 0)
	valLabel.TextColor3 = Color3.fromRGB(255,255,255)
	valLabel.TextSize = 11; valLabel.Font = Enum.Font.Gotham
	valLabel.Parent = parent
	local vC = Instance.new("UICorner"); vC.CornerRadius = UDim.new(0, 8); vC.Parent = valLabel
	createGrayStroke(valLabel, 1.5)

	local plus = Instance.new("TextButton")
	plus.Size = UDim2.new(0, 24, 0, 26); plus.Position = UDim2.new(0, 292, 0.5, -13)
	plus.BackgroundColor3 = C.Btn
	plus.Text = "+"; plus.TextColor3 = Color3.fromRGB(255,255,255)
	plus.TextSize = 14; plus.Font = Enum.Font.GothamBold
	plus.Parent = parent
	local pC = Instance.new("UICorner"); pC.CornerRadius = UDim.new(0, 8); pC.Parent = plus
	createGrayStroke(plus, 1.5)

	local function updateLabel()
		valLabel.Text = tostring(States[stateKey].Value)
	end
	minus.MouseButton1Click:Connect(function()
		States[stateKey].Value = math.max(minV, (States[stateKey].Value or 0) - step)
		updateLabel()
	end)
	plus.MouseButton1Click:Connect(function()
		States[stateKey].Value = math.min(maxV, (States[stateKey].Value or 0) + step)
		updateLabel()
	end)
	return minus, valLabel, plus
end

-- 颜色循环按钮
local ColorCycle = {"Red", "Blue", "Green", "Pink", "Yellow", "Cyan"}
local function createColorCycle(parent, stateKey)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 102, 0, 26); btn.Position = UDim2.new(0, 214, 0.5, -13)
	btn.BackgroundColor3 = C.Val
	btn.BackgroundTransparency = 0.1
	btn.Text = "颜色: " .. tostring(States[stateKey].Value or "Pink")
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.TextSize = 11; btn.Font = Enum.Font.Gotham
	btn.Parent = parent
	local cC = Instance.new("UICorner"); cC.CornerRadius = UDim.new(0, 8); cC.Parent = btn
	createGrayStroke(btn, 1.5)
	btn.MouseButton1Click:Connect(function()
		local cur = tostring(States[stateKey].Value or "Pink")
		local idx = 0
		for i, c in ipairs(ColorCycle) do
			if c:lower() == cur:lower() then idx = i break end
		end
		local next = ColorCycle[(idx % #ColorCycle) + 1]
		States[stateKey].Value = next
		btn.Text = "颜色: " .. next
	end)
	return btn
end

-- 开关 (Toggle)
local ToggleRefreshers = {}
local function createToggle(parent, stateKey, callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0,50,0,26)
	frame.BackgroundColor3 = Color3.fromRGB(96,72,170)
	frame.BorderSizePixel = 0; frame.Parent = parent
	local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(1,0); c1.Parent = frame
	createGrayStroke(frame, 2)

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0,22,0,22); circle.Position = UDim2.new(0,2,0.5,-11)
	circle.BackgroundColor3 = Color3.fromRGB(255,255,255); circle.BorderSizePixel = 0
	circle.Parent = frame
	local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(1,0); c2.Parent = circle

	local enabled = States[stateKey] and States[stateKey].Enabled or false
	local function update()
		if enabled then
			tween(frame, {BackgroundColor3 = Color3.fromRGB(0,210,110)}, TweenFast)
			tween(circle, {Position = UDim2.new(0,26,0.5,-11)}, TweenFast)
		else
			tween(frame, {BackgroundColor3 = Color3.fromRGB(96,72,170)}, TweenFast)
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
			States[stateKey].Enabled = enabled
			update()
			if callback then callback(enabled) end
		end
	end)
	return frame, function() return enabled end
end

-- 长按防误触拖拽 (简化版)
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
-- 构建主界面
-- ============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UITemplate"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 10000
local GuiParent = playerGui
pcall(function()
	if CoreGui then GuiParent = CoreGui end
end)
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
	og.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
		ColorSequenceKeypoint.new(0.25, Color3.fromHSV(0.25,1,1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
		ColorSequenceKeypoint.new(0.75, Color3.fromHSV(0.75,1,1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1)),
	})
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
	t1.Text = "⚡ UI 模板"
	t1.TextColor3 = Color3.fromRGB(255, 255, 255)
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

-- 颜色方案常量
local ISLAND_W, ISLAND_H = 190, 38
local PANEL_W, PANEL_H = 600, 360
local PanelOpen = false

-- GUI 引用表
local Gui = {}

-- 悬浮球
local function createFloatBall()
	if Gui.FloatBall then return Gui.FloatBall end
	local ball = Instance.new("Frame")
	ball.Name = "UITemplateBall"
	ball.Size = UDim2.new(0, 38, 0, 38)
	local savedPos = States.FloatBallPos
	if type(savedPos) == "table" and #savedPos == 4 then
		ball.Position = UDim2.new(savedPos[1], savedPos[2], savedPos[3], savedPos[4])
	else
		ball.Position = UDim2.new(0.5, -19, 0, 110)
	end
	ball.BackgroundTransparency = 0
	ball.BorderSizePixel = 0
	ball.ZIndex = 9100
	ball.Parent = ScreenGui

	local bg = Instance.new("UIGradient")
	bg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1)),
	})
	bg.Rotation = 0
	bg.Parent = ball
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1,0); bc.Parent = ball

	local core = Instance.new("Frame")
	core.Size = UDim2.new(1, -6, 1, -6)
	core.Position = UDim2.new(0, 3, 0, 3)
	core.BackgroundColor3 = Color3.fromRGB(5,5,15)
	core.BackgroundTransparency = 0.45
	core.BorderSizePixel = 0
	core.Parent = ball
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1,0); cc.Parent = core

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
	hit.MouseButton1Click:Connect(function()
		togglePanel()
	end)

	makeDraggable(ball, hit)
	raiseZIndex(ball, 9101)
	Gui.FloatBall = ball
	return ball
end

-- 主面板
local function buildMainPanel()
	local MainPanel = Instance.new("Frame")
	MainPanel.Size = UDim2.new(0, ISLAND_W, 0, ISLAND_H)
	MainPanel.Position = UDim2.new(0.5, 0, 0, 10)
	MainPanel.AnchorPoint = Vector2.new(0.5, 0)
	MainPanel.BackgroundColor3 = Color3.fromRGB(0,0,0)
	MainPanel.BackgroundTransparency = 0.35
	MainPanel.ClipsDescendants = true
	MainPanel.BorderSizePixel = 0
	MainPanel.ZIndex = 9000
	MainPanel.Parent = ScreenGui
	local mpC = Instance.new("UICorner"); mpC.CornerRadius = UDim.new(0,24); mpC.Parent = MainPanel
	local mpStroke = createGrayStroke(MainPanel, 2)
	local mpGrad = Instance.new("UIGradient")
	mpGrad.Color = ColorSequence.new(Color3.fromRGB(24,14,56), Color3.fromRGB(38,22,84))
	mpGrad.Rotation = 90
	mpGrad.Parent = MainPanel
	local PanelScale = Instance.new("UIScale")
	PanelScale.Scale = 1
	PanelScale.Parent = MainPanel

	-- 玻璃光泽
	local GlassGlare = Instance.new("Frame")
	GlassGlare.Size = UDim2.new(1,0,0,90)
	GlassGlare.Position = UDim2.new(0,0,0,0)
	GlassGlare.BackgroundColor3 = Color3.fromRGB(255,255,255)
	GlassGlare.BackgroundTransparency = 1
	GlassGlare.BorderSizePixel = 0
	GlassGlare.Parent = MainPanel
	local ggGrad = Instance.new("UIGradient")
	ggGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
	ggGrad.Rotation = 90
	ggGrad.Transparency = NumberSequence.new(0.92, 1)
	ggGrad.Parent = GlassGlare

	local GlassUnder = Instance.new("Frame")
	GlassUnder.Size = UDim2.new(1,0,0,60)
	GlassUnder.Position = UDim2.new(0,0,1,-60)
	GlassUnder.BackgroundColor3 = Color3.fromRGB(255,255,255)
	GlassUnder.BackgroundTransparency = 1
	GlassUnder.BorderSizePixel = 0
	GlassUnder.Parent = MainPanel
	local guGrad = Instance.new("UIGradient")
	guGrad.Color = ColorSequence.new(Color3.fromRGB(120,140,255), Color3.fromRGB(255,255,255))
	guGrad.Rotation = 90
	guGrad.Transparency = NumberSequence.new(1, 0.95)
	guGrad.Parent = GlassUnder

	local TitleBar = Instance.new("Frame")
	TitleBar.Size = UDim2.new(1,0,0,ISLAND_H)
	TitleBar.Position = UDim2.new(0,0,0,0)
	TitleBar.BackgroundColor3 = Color3.fromRGB(255,255,255)
	TitleBar.BackgroundTransparency = 1
	TitleBar.BorderSizePixel = 0
	TitleBar.Parent = MainPanel

	local IslandLeftText = Instance.new("TextLabel")
	IslandLeftText.Size = UDim2.new(0,110,0,20)
	IslandLeftText.Position = UDim2.new(0,14,0.5,-10)
	IslandLeftText.BackgroundTransparency = 1
	IslandLeftText.Text = "⚡ UI 模板"
	IslandLeftText.TextColor3 = Color3.fromRGB(255,255,255)
	IslandLeftText.TextSize = 13
	IslandLeftText.Font = Enum.Font.GothamBold
	IslandLeftText.TextXAlignment = Enum.TextXAlignment.Left
	IslandLeftText.Parent = TitleBar

	local IslandDiv = Instance.new("Frame")
	IslandDiv.Size = UDim2.new(0,1,0,20)
	IslandDiv.Position = UDim2.new(0,126,0.5,-10)
	IslandDiv.BackgroundColor3 = Color3.fromRGB(200,200,220)
	IslandDiv.BackgroundTransparency = 0.3
	IslandDiv.BorderSizePixel = 0
	IslandDiv.Parent = TitleBar

	local BreatheDot = Instance.new("Frame")
	BreatheDot.Size = UDim2.new(0,10,0,10)
	BreatheDot.Position = UDim2.new(0,140,0.5,-5)
	BreatheDot.AnchorPoint = Vector2.new(0.5,0.5)
	BreatheDot.BackgroundColor3 = Color3.fromRGB(0,255,150)
	BreatheDot.BorderSizePixel = 0
	BreatheDot.Parent = TitleBar
	local bdC = Instance.new("UICorner"); bdC.CornerRadius = UDim.new(1,0); bdC.Parent = BreatheDot
	createGrayStroke(BreatheDot, 1)
	local BreatheDotScale = Instance.new("UIScale")
	BreatheDotScale.Scale = 1
	BreatheDotScale.Parent = BreatheDot

	local IslandRightText = Instance.new("TextLabel")
	IslandRightText.Size = UDim2.new(0,44,0,20)
	IslandRightText.Position = UDim2.new(1,-52,0.5,-10)
	IslandRightText.BackgroundTransparency = 1
	IslandRightText.Text = "≡ 菜单"
	IslandRightText.TextColor3 = Color3.fromRGB(255,255,255)
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

	local TopLine = Instance.new("Frame")
	TopLine.Size = UDim2.new(1,-80,0,1.5)
	TopLine.Position = UDim2.new(0,40,0,2)
	TopLine.BackgroundColor3 = Color3.fromRGB(255,255,255)
	TopLine.BackgroundTransparency = 1
	TopLine.BorderSizePixel = 0
	TopLine.Parent = ContentFrame
	local tlGrad = Instance.new("UIGradient")
	tlGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
	tlGrad.Rotation = 90
	tlGrad.Transparency = NumberSequence.new(1, 0, 1)
	tlGrad.Parent = TopLine
	Gui.TopLineGrad = tlGrad

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

	-- 玻璃卡片辅助
	local function createGlassCard(parent, size, radius)
		local outer = Instance.new("Frame")
		outer.Size = size
		outer.BackgroundTransparency = 0
		outer.BorderSizePixel = 0
		outer.Parent = parent
		local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, radius or 16); oc.Parent = outer
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new(Color3.fromRGB(255,50,160), Color3.fromRGB(50,110,255))
		grad.Rotation = 90
		grad.Parent = outer
		local inner = Instance.new("Frame")
		inner.Size = UDim2.new(1,-5,1,-5)
		inner.Position = UDim2.new(0,2.5,0,2.5)
		inner.BackgroundColor3 = Color3.fromRGB(26,18,62)
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
	AvatarImage.BackgroundColor3 = Color3.fromRGB(60,45,130)
	AvatarImage.BackgroundTransparency = 0
	AvatarImage.BorderSizePixel = 0
	AvatarImage.Parent = avatarCardInner
	local avC = Instance.new("UICorner"); avC.CornerRadius = UDim.new(0,14); avC.Parent = AvatarImage
	createGrayStroke(AvatarImage, 1.5)

	local nameCardInner, _ = createGlassCard(InfoSection, UDim2.new(0,92,0,28), 14)
	local PlayerNameLabel = Instance.new("TextLabel")
	PlayerNameLabel.Size = UDim2.new(1,-8,1,0)
	PlayerNameLabel.Position = UDim2.new(0,4,0,0)
	PlayerNameLabel.BackgroundTransparency = 1
	PlayerNameLabel.Text = player.DisplayName or player.Name
	PlayerNameLabel.TextColor3 = Color3.fromRGB(255,255,255)
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
	ServerInfoText.TextColor3 = Color3.fromRGB(200,220,255)
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
	VDivider.BackgroundColor3 = Color3.fromRGB(180,180,200)
	VDivider.BackgroundTransparency = 0.35
	VDivider.BorderSizePixel = 0
	VDivider.Parent = ContentFrame

	-- 左侧分类按钮栏
	local LeftBar = Instance.new("Frame")
	LeftBar.Size = UDim2.new(0,84,1,-8)
	LeftBar.Position = UDim2.new(0,120,0,4)
	LeftBar.BackgroundColor3 = Color3.fromRGB(22,16,56)
	LeftBar.BackgroundTransparency = 0.25
	LeftBar.BorderSizePixel = 0
	LeftBar.Parent = ContentFrame
	local lbC = Instance.new("UICorner"); lbC.CornerRadius = UDim.new(0,16); lbC.Parent = LeftBar
	createGrayStroke(LeftBar, 1)

	local ButtonWrap = Instance.new("Frame")
	ButtonWrap.Size = UDim2.new(1,0,1,0)
	ButtonWrap.BackgroundTransparency = 1
	ButtonWrap.Parent = LeftBar
	local LeftLayout = Instance.new("UIListLayout")
	LeftLayout.Padding = UDim.new(0,5); LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	LeftLayout.Parent = ButtonWrap
	local LeftPad = Instance.new("UIPadding"); LeftPad.PaddingTop = UDim.new(0,7); LeftPad.Parent = ButtonWrap

	-- 分类指示器
	local CatIndicator = Instance.new("Frame")
	CatIndicator.Size = UDim2.new(0,74,0,30)
	CatIndicator.Position = UDim2.new(0,5,0,9)
	CatIndicator.BackgroundTransparency = 0
	CatIndicator.BorderSizePixel = 0
	CatIndicator.ZIndex = 9005
	CatIndicator.Parent = LeftBar
	local ciC = Instance.new("UICorner"); ciC.CornerRadius = UDim.new(0,10); ciC.Parent = CatIndicator
	local ciGrad = Instance.new("UIGradient")
	ciGrad.Color = ColorSequence.new(Color3.fromRGB(255,50,150), Color3.fromRGB(50,110,255))
	ciGrad.Rotation = 90
	ciGrad.Parent = CatIndicator
	Gui.CatGrads = {ciGrad}
	Gui.CatIndicator = CatIndicator

	-- 右侧滚动内容
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

	-- 简单滚动
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
	BottomGlow.BackgroundColor3 = Color3.fromRGB(255,255,255)
	BottomGlow.BackgroundTransparency = 1
	BottomGlow.BorderSizePixel = 0
	BottomGlow.Parent = ContentFrame
	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
	bgGrad.Rotation = 90
	bgGrad.Transparency = NumberSequence.new(1, 0, 1)
	bgGrad.Parent = BottomGlow
	Gui.BottomGlow = BottomGlow

	local Watermark = Instance.new("TextLabel")
	Watermark.Size = UDim2.new(0,90,0,12)
	Watermark.Position = UDim2.new(1,-96,1,-18)
	Watermark.BackgroundTransparency = 1
	Watermark.Text = "UI TEMPLATE"
	Watermark.TextColor3 = Color3.fromRGB(255,255,255)
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

-- 动态装饰
task.spawn(function()
	while true do
		task.wait(0.08)
		local t = tick() * 0.15
		local c = Color3.fromHSV(t % 1, 1, 1)
		if Gui.MainPanel then
			local st = Gui.MainPanel:FindFirstChildOfClass("UIStroke")
			if st then st.Color = c end
		end
		if Gui.IslandLeftText then Gui.IslandLeftText.TextColor3 = c end
		if Gui.BreatheDot then
			Gui.BreatheDot.BackgroundColor3 = c
			local s = 0.7 + 0.3 * math.sin(tick() * 4)
			Gui.BreatheDot.Size = UDim2.new(0, 10 * s, 0, 10 * s)
		end
		if Gui.BottomGlow then
			local g = Gui.BottomGlow:FindFirstChildOfClass("UIGradient")
			if g then g.Color = ColorSequence.new(c, c) end
		end
		if Gui.TopLineGrad then Gui.TopLineGrad.Color = ColorSequence.new(c, c) end
		if Gui.CatGrads then
			for _, g in ipairs(Gui.CatGrads) do
				local p = (t + 0.11) % 1
				g.Color = ColorSequence.new(
					Color3.fromHSV(p, 1, 1),
					Color3.fromHSV((p + 0.25) % 1, 1, 1)
				)
			end
		end
	end
end)

-- FPS/信息更新 (占位)
task.spawn(function()
	while true do
		task.wait(1)
		if Gui.MainPanel and Gui.MainPanel.Size.Y.Offset > 100 then
			local ping = 0
			pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
			if Gui.ServerInfoText then
				Gui.ServerInfoText.Text = string.format("服务器: %s\nPlaceId: %d\n延迟: %dms", "UI模板", game.PlaceId or 0, ping)
			end
			if Gui.StatText then
				local count = 0
				for _, s in pairs(States) do
					if type(s) == "table" and s.Enabled then count = count + 1 end
				end
				Gui.StatText.Text = "已开启: " .. count .. " 个功能"
			end
			if Gui.NearestText then
				Gui.NearestText.Text = "最近: 无"
			end
		end
	end
end)

-- 面板切换
function togglePanel()
	PanelOpen = not PanelOpen
	if Gui.MainPanel then Gui.MainPanel.Visible = true end
	if PanelOpen then
		if States.DynamicIsland and States.DynamicIsland.Enabled then
			Gui.MainPanel.Size = UDim2.new(0, ISLAND_W, 0, ISLAND_H)
		else
			Gui.MainPanel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
		end
		Gui.ContentScale.Scale = 0.9
		Gui.PanelScale.Scale = 0.92
		tween(Gui.MainPanel, {Size = UDim2.new(0, PANEL_W, 0, PANEL_H)}, TweenPanelOpen)
		tween(Gui.PanelScale, {Scale = 1}, TweenScalePop)
		tween(Gui.ContentScale, {Scale = 1}, TweenScalePop)
		-- 重新渲染功能列表
		pcall(Gui.refreshFeatures)
		Gui.IslandRightText.Text = "✕ 收起"
	else
		if States.DynamicIsland and States.DynamicIsland.Enabled then
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

-- 构建界面
buildMainPanel()
createFloatBall()

-- ============================================
-- 分类与功能项 (占位)
-- ============================================
local Categories = {
	{Name = "示范", Color = Color3.fromRGB(0,150,255)},
	{Name = "控件", Color = Color3.fromRGB(255,60,60)},
	{Name = "展示", Color = Color3.fromRGB(150,50,255)},
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

-- 功能列表 (占位)
local Features = {
	{Cat=1, Name="演示开关 1", Key="DemoToggle1"},
	{Cat=1, Name="演示开关 2", Key="DemoToggle2"},
	{Cat=1, Name="演示滑块", Key="DemoSlider", Input=true},
	{Cat=1, Name="演示颜色", Key="DemoColor", Input=true},
	{Cat=2, Name="下拉菜单示例", HasDropdown=true},
}

-- 刷新功能列表 (UI生成)
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
	for _, feat in ipairs(Features) do
		if feat.Cat == CurrentCategory then
			local row = nil
			local ok = pcall(function()
				local isDrop = feat.HasDropdown
				local rowH = isDrop and 34 or 42
				row = Instance.new("Frame")
				row.Size = UDim2.new(0, ROW_W, 0, rowH)
				row.Position = UDim2.new(0, 0, 0, yOffset)
				row.BackgroundColor3 = Color3.fromRGB(30,20,66)
				row.BackgroundTransparency = 0.15
				row.BorderSizePixel = 0
				row.Parent = Gui.ScrollInner
				row.ZIndex = 9003
				local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = row
				createGrayStroke(row, 1.5)

				local scBtn = Instance.new("TextButton")
				scBtn.Size = UDim2.new(0,24,0,24); scBtn.Position = UDim2.new(0,2,0.5,-12)
				scBtn.BackgroundColor3 = C.BtnDark
				scBtn.Text = "⚡"; scBtn.TextColor3 = Color3.fromRGB(255,255,255)
				scBtn.TextSize = 11; scBtn.Font = Enum.Font.GothamBold
				scBtn.Parent = row
				local scC = Instance.new("UICorner"); scC.CornerRadius = UDim.new(0,8); scC.Parent = scBtn
				createGrayStroke(scBtn, 1.5)
				RowScBtns[feat.Key] = scBtn

				if isDrop then
					local dropContent = createDropdown(row, feat.Name, false, 10, function(newHeight)
						if not row.Parent then return end
						row.Size = UDim2.new(0, ROW_W, 0, newHeight)
						relayoutRows()
					end, ROW_W - 32)
					local dropContainer = dropContent.Parent
					dropContainer.Position = UDim2.new(0, 32, 0, 0)

					-- 下拉菜单内容示例：复选框
					addCheckboxes(dropContent, {
						{"子选项 1", false, function(v) print("子选项1:", v) end},
						{"子选项 2", true, function(v) print("子选项2:", v) end},
					})
				else
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(0,84,1,0); label.Position = UDim2.new(0,32,0,0)
					label.BackgroundTransparency = 1; label.Text = feat.Name
					label.TextColor3 = Color3.fromRGB(238,238,255); label.TextSize = 12
					label.Font = Enum.Font.GothamSemibold; label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = row

					local tg = createToggle(row, feat.Key)
					tg.Position = UDim2.new(0, 316, 0.5, -13)

					if feat.Input then
						if feat.Key == "DemoColor" then
							createColorCycle(row, feat.Key)
						else
							createStepControl(row, feat.Key)
						end
					end
				end
				raiseZIndex(row, 9004)
			end)
			if ok and row then
				table.insert(FeatureRows, row)
				yOffset = yOffset + (feat.HasDropdown and 39 or 47)
			end
		end
	end
	Gui.ScrollInner.Size = UDim2.new(0, ROW_W, 0, yOffset)
	Gui.ScrollInner.Position = UDim2.new(0, 6, 0, 0)
end

-- 分类按钮
local CatBtns = {}
for i, cat in ipairs(Categories) do
	local outer = Instance.new("Frame")
	outer.Size = UDim2.new(0, 78, 0, 34)
	outer.BackgroundTransparency = 0
	outer.BorderSizePixel = 0
	outer.Parent = Gui.ButtonWrap
	local oC = Instance.new("UICorner"); oC.CornerRadius = UDim.new(0, 12); oC.Parent = outer
	local oGrad = Instance.new("UIGradient")
	oGrad.Color = ColorSequence.new(Color3.fromRGB(255,50,150), Color3.fromRGB(50,110,255))
	oGrad.Rotation = 90
	oGrad.Parent = outer
	if not Gui.CatGrads then Gui.CatGrads = {} end
	table.insert(Gui.CatGrads, oGrad)

	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -4, 1, -4)
	inner.Position = UDim2.new(0, 2, 0, 2)
	inner.BackgroundColor3 = Color3.fromRGB(22,16,56)
	inner.BackgroundTransparency = 0.3
	inner.BorderSizePixel = 0
	inner.Parent = outer
	local iC = Instance.new("UICorner"); iC.CornerRadius = UDim.new(0, 10); iC.Parent = inner

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1,0,1,0)
	text.BackgroundTransparency = 1
	text.Text = cat.Name
	text.TextColor3 = Color3.fromRGB(255,255,255)
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
	CatBtns[i] = hit
end

-- 初始选中第一个分类
pcall(Gui.refreshFeatures)
moveCatIndicator(1)

-- ============================================
-- 全局点击岛/球切换
-- ============================================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if Gui.MainPanel and Gui.MainPanel.Visible then
			local pos = input.Position
			local vs = camera.ViewportSize
			if vs and vs.X > 0 then
				local w = Gui.MainPanel.Size.X.Offset
				if w <= 0 then w = ISLAND_W end
				local halfW = w / 2 + 16
				if pos.X >= vs.X/2 - halfW and pos.X <= vs.X/2 + halfW
					and pos.Y >= -4 and pos.Y <= ISLAND_H + 22 then
					togglePanel()
				end
			end
		end
	end
end)

-- ============================================
-- 键盘快捷键 (F 切换面板)
-- ============================================
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.F then
		togglePanel()
	end
end)

print("[UI Template] 加载完成，按 F 切换菜单")
