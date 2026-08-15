-- ============================================================
-- 星光辅助 V2.1 · 修复移动端标签页不显示问题
-- ============================================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- 注册金黄色主题
WindUI:AddTheme({
    Name = "StarGold",
    Accent = "#FFD700",
    Outline = "#B8860B",
    Text = "#FFFFFF",
    Placeholder = "#A8A098",
})
WindUI:SetTheme("StarGold")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local player = LocalPlayer

local LoadStartTime = tick()

-- 金黄色配色
local C = {
    Gold = Color3.fromRGB(255, 215, 0),
    GoldDark = Color3.fromRGB(184, 134, 11),
    GoldLight = Color3.fromRGB(255, 235, 150),
    Text = Color3.fromRGB(255, 255, 240),
    TextSub = Color3.fromRGB(200, 195, 180),
}

-- 角色引用
local character, humanoid, hrp
local function refreshCharacter()
    character = player.Character
    if character then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        hrp = character:FindFirstChild("HumanoidRootPart")
    end
end
refreshCharacter()
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
    task.delay(0.5, reapplyAllFeatures)
end)

-- ============================================================
-- 功能状态表
-- ============================================================
local Features = {
    WalkSpeed = {Enabled = false, Value = 100, Default = 16},
    TpWalk = {Enabled = false, Value = 2},
    Fly1 = {Enabled = false, Value = 45},
    Fly2 = {Enabled = false, Value = 50, Flying = false},
    FreeMove = {Enabled = false, Value = 50},
    Noclip = {Enabled = false},
    BunnyHop = {Enabled = false, Value = 5},
    JumpHeight = {Enabled = false, Value = 100, Default = 7.2},
    AutoRun = {Enabled = false},
    SuperJump = {Enabled = false, Value = 200},
    WallClimb = {Enabled = false, Value = 50},
    GodMode = {Enabled = false},
    NoCooldown = {Enabled = false},
    InfiniteAmmo = {Enabled = false},
    AutoAttack = {Enabled = false},
    KillAura = {Enabled = false, Value = 20},
    Aimbot = {Enabled = false},
    RapidFire = {Enabled = false},
    AutoFire = {Enabled = false},
    NightVision = {Enabled = false},
    FullBright = {Enabled = false},
    ESP = {Enabled = false},
    Xray = {Enabled = false},
    NoFog = {Enabled = false},
    ColorFilter = {Enabled = false, Value = "Pink"},
    FreeCam = {Enabled = false},
    ThermalESP = {Enabled = false},
    MusicPlayer = {Enabled = false},
    AutoClicker = {Enabled = false, Value = 10},
    ClickerStart = {Enabled = false},
    ClickerMulti = {Enabled = false},
    FastInteract = {Enabled = false},
    AutoSave = {Enabled = false},
    AntiAfk = {Enabled = false},
    NpcDisplay = {Enabled = false, ShowHead = true, ShowTorso = true, ShowLimbs = true, ShowBones = true},
    PlayerDisplay = {Enabled = false, ShowHead = true, ShowTorso = true, ShowLimbs = true, ShowBones = true, ShowName = true, ShowDistance = true, ShowHealth = true},
    BoxCreature = {Enabled = false, BoxNpc = true, BoxPlayer = true, BoxOther = true, BoxAliveOnly = false, BoxMode = "3D", ShowHitbox = false, MaxDistance = 0},
    LineConnect = {Enabled = false, ConnectNpc = false, ConnectPlayer = true, ConnectOther = false, LineWallCheck = false, Origin = "Top", MaxDistance = 0},
    AimbotV2 = {Enabled = false, AimPlayer = true, AimNpc = false, AimOther = false, AimPart = "Head", CircleSize = 150, AimSpeed = 0.3, WallCheck = false, TeamCheck = false, AliveCheck = true, Smooth = true, Predict = false, CustomTarget = nil, MaxDistance = 0},
    AdvancedESP = {Enabled = false, ShowBox = true, BoxStyle = "Corner", BoxThickness = 1, ShowName = true, ShowHealth = true, ShowDistance = true, HealthStyle = "Bar", ShowChams = true, TeamCheck = false, ShowTeam = false, WallCheck = false, Tracer = false, TracerOrigin = "Bottom", Skeleton = false, MaxDistance = 300},
    DynamicIsland = {Enabled = true},
    ShowFps = {Enabled = false},
    ShowCoords = {Enabled = false},
    GravityMod = {Enabled = false, Value = 50, Default = 196.2},
    TimeOfDay = {Enabled = false, Value = 12},
    SitAnywhere = {Enabled = false},
    DangerWarning = {Enabled = false, Value = 50},
}

local Conns = {}
local function bind(name, conn)
    if Conns[name] then Conns[name]:Disconnect() end
    Conns[name] = conn
end
local function unbind(name)
    if Conns[name] then
        if typeof(Conns[name]) == "RBXScriptConnection" then
            Conns[name]:Disconnect()
        end
        Conns[name] = nil
    end
end

local ClickerThread, AntiAfkThread, AutoSaveThread, Fly1BtnY = 0, nil, nil, 0
local ToggleRefreshers = {}
local Updaters = {}

-- 辅助函数
local MoveStateNames = {"Climbing","FallingDown","Flying","Freefall","GettingUp","Jumping","Landed","Physics","PlatformStanding","Ragdoll","Running","RunningNoPhysics","Seated","StrafingNoPhysics","Swimming"}
local function disableMovementStates(hum)
    if not hum then return end
    for _, s in ipairs(MoveStateNames) do
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType[s], false) end)
    end
end
local function enableMovementStates(hum)
    if not hum then return end
    for _, s in ipairs(MoveStateNames) do
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType[s], true) end)
    end
end

local TargetCache = {Players = {}, Npcs = {}, Others = {}, All = {}}
local LastNpcScan = 0
local function updateTargetCache()
    TargetCache.Players = {}
    TargetCache.All = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local hrp2 = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Torso")
                local e = {Obj = p.Character, Hum = hum, Hrp = hrp2, IsPlayer = true, Plr = p}
                table.insert(TargetCache.Players, e)
                table.insert(TargetCache.All, e)
            end
        end
    end
    local now = tick()
    if now - LastNpcScan >= 0.5 then
        LastNpcScan = now
        TargetCache.Npcs = {}
        TargetCache.Others = {}
        for _, m in pairs(Workspace:GetDescendants()) do
            if m:IsA("Model") and m ~= character and not Players:GetPlayerFromCharacter(m) then
                local hum = m:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local hrp2 = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso")
                    local e = {Obj = m, Hum = hum, Hrp = hrp2, IsPlayer = false}
                    table.insert(TargetCache.Npcs, e)
                    table.insert(TargetCache.All, e)
                else
                    if m:FindFirstChild("Head") or m.PrimaryPart then
                        table.insert(TargetCache.Others, m)
                    end
                end
            end
        end
    end
end

local MAX_RENDER_DIST = 300
local function inRenderRange(partPos)
    if not hrp or not partPos then return false end
    return (hrp.Position - partPos).Magnitude <= MAX_RENDER_DIST
end

local function worldToScreen(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
end

local function isBlockedByWall(targetPart, targetChar)
    if not targetPart then return false end
    local rayParams = RaycastParams.new()
    local ignore = {character}
    if targetChar then table.insert(ignore, targetChar) end
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignore
    local dir = targetPart.Position - Camera.CFrame.Position
    local result = Workspace:Raycast(Camera.CFrame.Position, dir, rayParams)
    if result then
        local hit = result.Instance
        if hit and targetChar and hit:IsDescendantOf(targetChar) then return false end
        return true
    end
    return false
end

local function tryFireTool()
    local tool = character and character:FindFirstChildOfClass("Tool")
    if not tool then return end
    local now = tick()
    local last = tool:GetAttribute("SG_LastFire") or 0
    if now - last < 0.08 then return end
    local fired = false
    for _, evName in ipairs({"Fire", "Shoot", "Click", "Attack", "Activate", "RemoteEvent"}) do
        local ev = tool:FindFirstChild(evName)
        if ev and ev:IsA("RemoteEvent") then
            pcall(function() ev:FireServer() end)
            fired = true
            break
        end
    end
    if not fired then pcall(function() tool:Activate() end) end
    tool:SetAttribute("SG_LastFire", now)
end

local function getGoldColor(offset)
    local t = tick() * 0.3 + (offset or 0)
    local hue = 0.08 + 0.04 * math.sin(t * 0.5)
    return Color3.fromHSV(hue, 0.8 + 0.15 * math.sin(t * 0.3), 0.9 + 0.08 * math.sin(t * 0.4))
end

function reapplyAllFeatures()
    task.wait(0.5)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    for key, state in pairs(Features) do
        if type(state) == "table" and state.Enabled and Updaters[key] then
            pcall(Updaters[key])
        end
    end
end

-- ============================================================
-- 渲染系统（精简版）
-- ============================================================
local RenderFolder = Instance.new("Folder")
RenderFolder.Name = "StarRender"; RenderFolder.Parent = CoreGui

local Pools = {
    Npc = {Lines = {}, Dots = {}},
    Player = {Lines = {}, Dots = {}, Texts = {}},
    Box = {Lines = {}},
    Connect = {Lines = {}},
    Adv = {Boxes = {}, Lines = {}, Texts = {}, Bars = {}},
}

local function getFromPool(pool, parent)
    for i, obj in ipairs(pool) do
        if not obj.Parent then
            obj.Visible = true
            return obj
        end
    end
    local obj
    if pool == Pools.Npc.Lines or pool == Pools.Player.Lines or pool == Pools.Connect.Lines or pool == Pools.Adv.Lines or pool == Pools.Box.Lines then
        obj = Instance.new("Frame")
        obj.BorderSizePixel = 0
    elseif pool == Pools.Adv.Boxes then
        obj = Instance.new("Frame")
        obj.BorderSizePixel = 0
        obj.BackgroundTransparency = 1
    elseif pool == Pools.Npc.Dots or pool == Pools.Player.Dots then
        obj = Instance.new("Frame")
        obj.BorderSizePixel = 0
    elseif pool == Pools.Player.Texts or pool == Pools.Adv.Texts then
        obj = Instance.new("TextLabel")
        obj.BackgroundTransparency = 1
    elseif pool == Pools.Adv.Bars then
        obj = Instance.new("Frame")
        obj.BorderSizePixel = 0
    end
    obj.ZIndex = 9600
    table.insert(pool, obj)
    return obj
end

local function clearPool(pool)
    for _, obj in ipairs(pool) do
        if obj then obj.Visible = false; obj.Parent = nil end
    end
end

local BeamFolder = Instance.new("Folder")
BeamFolder.Name = "StarBeams"; BeamFolder.Parent = Workspace

local BeamPools = {
    Npc = {Beams = {}},
    Player = {Beams = {}},
    Connect = {Beams = {}},
    Adv = {Beams = {}},
}

local BEAM_W = 0.05

local function getBeam(pool, color, thickness)
    for _, b in ipairs(pool.Beams) do
        if not b.Enabled then
            b.Color = ColorSequence.new(color)
            b.Width0 = thickness
            b.Width1 = thickness
            b.Enabled = true
            return b
        end
    end
    local a0 = Instance.new("Attachment"); a0.Name = "A0"; a0.Parent = BeamFolder
    local a1 = Instance.new("Attachment"); a1.Name = "A1"; a1.Parent = BeamFolder
    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Color = ColorSequence.new(color)
    beam.Width0 = thickness; beam.Width1 = thickness
    beam.FaceCamera = true
    beam.Segments = 1
    beam.Transparency = NumberSequence.new(0)
    beam.LightInfluence = 0
    beam.ZOffset = 0
    beam.Parent = BeamFolder
    table.insert(pool.Beams, beam)
    return beam
end

local function clearBeams(pool)
    for _, b in ipairs(pool.Beams) do
        b.Enabled = false
    end
end

local function draw3DLine(pool, p1, p2, color, thickness)
    local beam = getBeam(pool, color, thickness or BEAM_W)
    beam.Attachment0.WorldPosition = p1
    beam.Attachment1.WorldPosition = p2
    return beam
end

local AdornPools = {
    Box = {Adorns = {}},
    Hitbox = {Adorns = {}},
}

local function getAdorn(pool, color)
    for _, a in ipairs(pool.Adorns) do
        if not a.Visible then
            a.Color3 = color
            a.Visible = true
            return a
        end
    end
    local adorn = Instance.new("BoxHandleAdornment")
    adorn.Adornee = Workspace.Terrain
    adorn.AlwaysOnTop = true
    adorn.Transparency = 0
    adorn.Color3 = color
    adorn.ZIndex = 0
    pcall(function() adorn.LineThickness = 0.2 end)
    adorn.Parent = Workspace
    table.insert(pool.Adorns, adorn)
    return adorn
end

local function clearAdorns(pool)
    for _, a in ipairs(pool.Adorns) do
        a.Visible = false
    end
end

local function drawBox3D(pool, char, color)
    local cf, size = char:GetBoundingBox()
    if not cf then return false end
    local sx, sy, sz = size.X, size.Y, size.Z
    if sx < 0.1 or sy < 0.1 or sz < 0.1 then return false end
    local adorn = getAdorn(pool, color)
    adorn.Size = size
    adorn.CFrame = CFrame.new(cf.Position)
    return true
end

local function drawHitbox3D(pool, char, color)
    local drawn = 0
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            if drawn >= 12 then break end
            local size = part.Size
            if size.X < 0.1 or size.Y < 0.1 or size.Z < 0.1 then continue end
            local adorn = getAdorn(pool, color)
            adorn.Size = size
            adorn.CFrame = CFrame.new(part.Position)
            drawn = drawn + 1
        end
    end
    return drawn > 0
end

local function drawHLine(pool, parent, x, y, w, color, t)
    local line = getFromPool(pool, parent)
    line.AnchorPoint = Vector2.new(0, 0)
    line.Size = UDim2.new(0, w, 0, t or 1.5)
    line.Position = UDim2.new(0, x, 0, y)
    line.Rotation = 0
    line.BackgroundColor3 = color
    line.Parent = parent
    return line
end

local function drawVLine(pool, parent, x, y, h, color, t)
    local line = getFromPool(pool, parent)
    line.AnchorPoint = Vector2.new(0, 0)
    line.Size = UDim2.new(0, t or 1.5, 0, h)
    line.Position = UDim2.new(0, x, 0, y)
    line.Rotation = 0
    line.BackgroundColor3 = color
    line.Parent = parent
    return line
end

local function drawBox2D(pool, parent, char, color)
    local hrp2 = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    local head = char:FindFirstChild("Head")
    if not hrp2 or not head then return false end
    local sp = Camera:WorldToViewportPoint(hrp2.Position)
    if sp.Z < 0 then return false end
    local hsp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    if hsp.Z < 0 then return false end
    local height = math.abs(hsp.Y - sp.Y) * 2.2
    local width = height * 0.6
    if height < 5 or width < 3 then return false end
    local x1, y1 = sp.X - width/2, sp.Y - height/2
    drawHLine(pool, parent, x1, y1, width, color)
    drawHLine(pool, parent, x1, y1 + height, width, color)
    drawVLine(pool, parent, x1, y1, height, color)
    drawVLine(pool, parent, x1 + width, y1, height, color)
    return true
end

local function drawBone(pool, p1, p2, color)
    if not p1 or not p2 then return nil end
    return draw3DLine(pool, p1.Position, p2.Position, color, BEAM_W)
end

local SkeletonR15 = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"LowerTorso", "HumanoidRootPart"}
}

local SkeletonR6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function getSkeleton(char)
    if char:FindFirstChild("UpperTorso") then return SkeletonR15 end
    return SkeletonR6
end

local AdvESPHighlights = {}
local ThermalHighlights = {}

local function clearRenderCache()
    for char, h in pairs(AdvESPHighlights) do
        pcall(function() h:Destroy() end)
        AdvESPHighlights[char] = nil
    end
    for _, pool in pairs(Pools) do
        for _, p in pairs(pool) do
            clearPool(p)
        end
    end
    for _, bp in pairs(BeamPools) do
        clearBeams(bp)
    end
    for _, ap in pairs(AdornPools) do
        clearAdorns(ap)
    end
end

-- ============================================================
-- 音乐播放器（仅保留核心，避免干扰）
-- ============================================================
local MusicDir = "/storage/emulated/0/Delta/StarMusic"
local Music = {
    Open = false, List = {}, Idx = 1,
    Current = nil, Playing = false, Mode = 0,
    ModeNames = {"🔁 列表循环", "🔂 单曲循环", "➡️ 顺序播放"},
    DirReady = false, Scanning = false,
}

local MusicPanel, MusicListFrame, MusicTimer = nil, nil, nil

local function musicToast(msg)
    WindUI:Notify({Title = "🎵 音乐", Content = msg, Duration = 2})
end

local function initMusicDir()
    Music.DirReady = false
    pcall(function()
        if not isfolder(MusicDir) then makefolder(MusicDir) end
        Music.DirReady = true
    end)
end

local function wavDuration(data)
    if data:sub(1, 4) ~= "RIFF" then return nil end
    if data:sub(9, 12) ~= "WAVE" then return nil end
    local byteRate = 0
    for i = 0, 3 do byteRate = byteRate + ((data:byte(33 + i) or 0) * (256 ^ i)) end
    if byteRate <= 0 then return nil end
    local dataSize = 0
    local pos = 13
    while pos <= #data - 8 do
        local id = data:sub(pos, pos + 3)
        local sz = 0
        for i = 0, 3 do sz = sz + ((data:byte(pos + 4 + i) or 0) * (256 ^ i)) end
        if id == "data" then dataSize = sz break end
        pos = pos + 8 + sz + (sz % 2)
    end
    if dataSize <= 0 then return nil end
    local sec = dataSize / byteRate
    if sec > 5 and sec < 36000 then return sec end
    return nil
end

local function mp3Duration(data)
    if #data < 128 then return nil end
    local off = 0
    if data:sub(1, 3) == "ID3" then
        local s = 0
        for i = 7, 10 do s = s * 128 + (data:byte(i) or 0) end
        off = s + 10
    end
    local i = off + 1
    while i <= #data - 4 do
        if data:byte(i) == 255 then
            local b2 = data:byte(i + 1) or 0
            if b2 >= 224 then
                local ver = math.floor(b2 / 8) % 4
                local layer = math.floor(b2 / 2) % 4
                local b3 = data:byte(i + 2) or 0
                local bitIdx = math.floor(b3 / 16) % 16
                if bitIdx > 0 and bitIdx < 15 then
                    local tbl
                    if ver == 3 and layer == 1 then tbl = {32,40,48,56,64,80,96,112,128,160,192,224,256,320}
                    elseif ver == 3 and layer == 2 then tbl = {32,48,56,64,80,96,112,128,160,192,224,256,320,384}
                    elseif ver == 3 and layer == 3 then tbl = {32,64,96,128,160,192,224,256,288,320,352,384,416,448}
                    elseif layer == 1 then tbl = {32,48,56,64,80,96,112,128,144,160,176,192,224,256}
                    else tbl = {8,16,24,32,40,48,56,64,80,96,112,128,144,160}
                    end
                    local kbps = tbl[bitIdx]
                    if kbps then
                        local sec = (#data - off) * 8 / (kbps * 1000)
                        if sec > 10 and sec < 36000 then return sec end
                    end
                end
            end
        end
        i = i + 1
        if i - off > 131072 then break end
    end
    return nil
end

local function fmtDur(sec)
    if not sec or sec <= 0 then return "--:--" end
    local m = math.floor(sec / 60)
    local s = math.floor(sec % 60)
    return string.format("%d:%02d", m, s)
end

local function loadLocalSongs()
    Music.Scanning = true
    musicToast("📂 扫描音乐...")
    task.spawn(function()
        local songs = {}
        local files = {}
        pcall(function() files = listfiles(MusicDir) end)
        local exts = {mp3 = true, wav = true, ogg = true, flac = true, aac = true, m4a = true}
        for _, f in ipairs(files) do
            local lower = tostring(f):lower()
            local ext = lower:match("%.([%w]+)$")
            if ext and exts[ext] then
                local base = f:match("([^/\\]+)$") or f
                local pureName = base:gsub("%.[%w]+$", "")
                local dur = 180
                if ext == "mp3" or ext == "wav" then
                    local okR, data = pcall(readfile, f)
                    if okR and data and #data > 128 then
                        dur = (ext == "wav") and wavDuration(data) or mp3Duration(data) or 180
                    end
                end
                table.insert(songs, {path = f, name = pureName, ext = ext, dur = dur})
            end
        end
        Music.List = songs
        Music.Idx = 1
        Music.Scanning = false
        if #songs == 0 then
            musicToast("🎵 未找到歌曲！请放入: " .. MusicDir)
        else
            musicToast("✅ 加载 " .. #songs .. " 首歌曲")
        end
        renderMusicList()
    end)
end

local function playSongAt(idx)
    local list = Music.List
    local s = list[idx]
    if not s then return end
    Music.Idx = idx
    Music.Current = s
    renderMusicList()
    task.spawn(function()
        local played = false
        local okP = pcall(function()
            if not playfile then error("执行器不支持playfile") end
            playfile(s.path)
        end)
        if okP then
            played = true
        else
            local rel = s.path:match("([^/\\]+)$")
            if rel then
                local okR = pcall(function() playfile(rel) end)
                if okR then played = true end
            end
        end
        if played then
            Music.Playing = true
            updateMusicPlayBtn()
            musicToast("▶ 播放: " .. s.name)
            if MusicTimer then task.cancel(MusicTimer) end
            local dur = math.max(s.dur or 180, 20)
            MusicTimer = task.delay(dur + 1.5, function()
                if Music.Current == s and Music.Playing then onMusicEnd() end
            end)
        else
            musicToast("⚠ 播放失败: " .. s.name)
        end
    end)
end

local function stopMusic()
    Music.Playing = false
    pcall(function() if stopfile then stopfile() end end)
    if MusicTimer then task.cancel(MusicTimer); MusicTimer = nil end
    updateMusicPlayBtn()
end

local function onMusicEnd()
    if #Music.List == 0 then return end
    if Music.Mode == 1 then
        playSongAt(Music.Idx)
    elseif Music.Mode == 2 then
        if Music.Idx < #Music.List then playSongAt(Music.Idx + 1) else stopMusic(); musicToast("✅ 播放列表已播完") end
    else
        playSongAt((Music.Idx % #Music.List) + 1)
    end
end

local function toggleMusicMode()
    Music.Mode = (Music.Mode + 1) % 3
    if MusicPanel and MusicPanel:FindFirstChild("ModeBtn") then
        MusicPanel.ModeBtn.Text = Music.ModeNames[Music.Mode + 1]
    end
end

local function updateMusicPlayBtn()
    if MusicPanel and MusicPanel:FindFirstChild("PlayBtn") then
        MusicPanel.PlayBtn.Text = Music.Playing and "⏸" or "▶"
        MusicPanel.PlayBtn.BackgroundColor3 = Music.Playing and C.GoldDark or C.Gold
    end
end

local function renderMusicList()
    if not MusicListFrame then return end
    for _, c in pairs(MusicListFrame:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    local list = Music.List
    if #list == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.Position = UDim2.new(0, 0, 0, 6)
        empty.BackgroundTransparency = 1
        empty.Text = Music.Scanning and "📂 扫描中..." or "未找到歌曲"
        empty.TextColor3 = C.TextSub
        empty.TextSize = 10
        empty.Font = Enum.Font.Gotham
        empty.TextWrapped = true
        empty.Parent = MusicListFrame
        return end
    local y = 0
    for i, s in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 30)
        row.Position = UDim2.new(0, 2, 0, y)
        row.BackgroundColor3 = Music.Current == s and C.GoldDark or Color3.fromRGB(30, 25, 40)
        row.BackgroundTransparency = 0.3
        row.BorderSizePixel = 0
        row.Parent = MusicListFrame
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = row
        local playHit = Instance.new("TextButton")
        playHit.Size = UDim2.new(1, 0, 1, 0)
        playHit.BackgroundTransparency = 1
        playHit.Text = ""
        playHit.AutoButtonColor = false
        playHit.Parent = row
        playHit.MouseButton1Click:Connect(function() playSongAt(i) end)
        local idxL = Instance.new("TextLabel")
        idxL.Size = UDim2.new(0, 22, 1, 0)
        idxL.Position = UDim2.new(0, 6, 0, 0)
        idxL.BackgroundTransparency = 1
        idxL.Text = Music.Current == s and "▶" or tostring(i)
        idxL.TextColor3 = Music.Current == s and C.Gold or C.TextSub
        idxL.TextSize = 10
        idxL.Font = Enum.Font.GothamBold
        idxL.TextXAlignment = Enum.TextXAlignment.Left
        idxL.Parent = row
        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(0, 180, 1, 0)
        nameL.Position = UDim2.new(0, 32, 0, 0)
        nameL.BackgroundTransparency = 1
        nameL.Text = s.name
        nameL.TextColor3 = C.Text
        nameL.TextSize = 10
        nameL.Font = Enum.Font.GothamSemibold
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        nameL.TextTruncate = Enum.TextTruncate.AtEnd
        nameL.Parent = row
        local durL = Instance.new("TextLabel")
        durL.Size = UDim2.new(0, 50, 1, 0)
        durL.Position = UDim2.new(1, -54, 0, 0)
        durL.BackgroundTransparency = 1
        durL.Text = fmtDur(s.dur)
        durL.TextColor3 = C.TextSub
        durL.TextSize = 9
        durL.Font = Enum.Font.Gotham
        durL.TextXAlignment = Enum.TextXAlignment.Right
        durL.Parent = row
        y = y + 32
    end
end

local function buildMusicPanel()
    local panel = Instance.new("Frame")
    panel.Name = "StarMusicPanel"
    panel.Size = UDim2.new(0, 220, 0, 34)
    panel.Position = UDim2.new(1, -230, 0.5, -150)
    panel.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
    panel.BackgroundTransparency = 0.15
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 9450
    panel.Parent = CoreGui
    local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 12); pc.Parent = panel
    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Gold
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = panel

    local titleBar = Instance.new("TextButton")
    titleBar.Size = UDim2.new(1, 0, 0, 34)
    titleBar.BackgroundTransparency = 1
    titleBar.Text = ""
    titleBar.AutoButtonColor = false
    titleBar.Parent = panel

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(0.5, 0, 1, 0)
    titleText.Position = UDim2.new(0, 8, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎵 星光音乐"
    titleText.TextColor3 = C.Gold
    titleText.TextSize = 11
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local playBtn = Instance.new("TextButton")
    playBtn.Name = "PlayBtn"
    playBtn.Size = UDim2.new(0, 32, 0, 26)
    playBtn.Position = UDim2.new(1, -76, 0.5, -13)
    playBtn.BackgroundColor3 = C.Gold
    playBtn.Text = "▶"
    playBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    playBtn.TextSize = 11
    playBtn.Font = Enum.Font.GothamBold
    playBtn.Parent = titleBar
    local pC = Instance.new("UICorner"); pC.CornerRadius = UDim.new(0, 7); pC.Parent = playBtn
    panel.PlayBtn = playBtn

    local modeBtn = Instance.new("TextButton")
    modeBtn.Name = "ModeBtn"
    modeBtn.Size = UDim2.new(0, 32, 0, 26)
    modeBtn.Position = UDim2.new(1, -42, 0.5, -13)
    modeBtn.BackgroundColor3 = C.GoldDark
    modeBtn.Text = "🔁"
    modeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    modeBtn.TextSize = 11
    modeBtn.Font = Enum.Font.GothamBold
    modeBtn.Parent = titleBar
    local mC = Instance.new("UICorner"); mC.CornerRadius = UDim.new(0, 7); mC.Parent = modeBtn
    panel.ModeBtn = modeBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -10, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    local cC = Instance.new("UICorner"); cC.CornerRadius = UDim.new(0, 7); cC.Parent = closeBtn

    playBtn.MouseButton1Click:Connect(function()
        if Music.Playing then stopMusic() else if Music.Current then playSongAt(Music.Idx) else musicToast("请先点击歌曲") end end
    end)
    modeBtn.MouseButton1Click:Connect(toggleMusicMode)
    closeBtn.MouseButton1Click:Connect(function()
        Features.MusicPlayer.Enabled = false
        panel.Visible = false
    end)

    local open = false
    titleBar.MouseButton1Click:Connect(function()
        open = not open
        if open then
            panel.Size = UDim2.new(0, 220, 0, 320)
            panel.ClipsDescendants = true
        else
            panel.Size = UDim2.new(0, 220, 0, 34)
            panel.ClipsDescendants = true
        end
    end)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -8, 0, 276)
    content.Position = UDim2.new(0, 4, 0, 38)
    content.BackgroundTransparency = 1
    content.Parent = panel

    MusicListFrame = Instance.new("Frame")
    MusicListFrame.Size = UDim2.new(1, 0, 0, 240)
    MusicListFrame.BackgroundColor3 = Color3.fromRGB(12, 8, 30)
    MusicListFrame.BackgroundTransparency = 0.2
    MusicListFrame.BorderSizePixel = 0
    MusicListFrame.ClipsDescendants = true
    MusicListFrame.Parent = content
    local mlc = Instance.new("UICorner"); mlc.CornerRadius = UDim.new(0, 8); mlc.Parent = MusicListFrame

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 50, 0, 22)
    refreshBtn.Position = UDim2.new(0.5, -25, 1, -26)
    refreshBtn.BackgroundColor3 = C.GoldDark
    refreshBtn.Text = "🔄 刷新"
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.TextSize = 10
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.Parent = content
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 7); rc.Parent = refreshBtn
    refreshBtn.MouseButton1Click:Connect(loadLocalSongs)

    MusicPanel = panel
    return panel
end

-- ============================================================
-- 功能实现 Updaters（精简但完整）
-- ============================================================

Updaters.WalkSpeed = function()
    if Features.WalkSpeed.Enabled then
        if Conns.WalkSpeed then return end
        Conns.WalkSpeed = RunService.Heartbeat:Connect(function()
            if humanoid and humanoid.WalkSpeed ~= Features.WalkSpeed.Value then
                humanoid.WalkSpeed = Features.WalkSpeed.Value
            end
        end)
    else
        unbind("WalkSpeed")
        if humanoid then humanoid.WalkSpeed = Features.WalkSpeed.Default or 16 end
    end
end

Updaters.JumpHeight = function()
    if Features.JumpHeight.Enabled then
        if Conns.JumpHeight then return end
        Conns.JumpHeight = RunService.Heartbeat:Connect(function()
            if humanoid and humanoid.JumpHeight ~= Features.JumpHeight.Value then
                humanoid.JumpHeight = Features.JumpHeight.Value
            end
        end)
    else
        unbind("JumpHeight")
        if humanoid then humanoid.JumpHeight = Features.JumpHeight.Default or 7.2 end
    end
end

Updaters.GravityMod = function()
    if Features.GravityMod.Enabled then
        if Conns.GravityMod then return end
        Conns.GravityMod = RunService.Heartbeat:Connect(function()
            if Workspace.Gravity ~= Features.GravityMod.Value then
                Workspace.Gravity = Features.GravityMod.Value
            end
        end)
    else
        unbind("GravityMod")
        Workspace.Gravity = Features.GravityMod.Default or 196.2
    end
end

Updaters.TpWalk = function()
    if Features.TpWalk.Enabled then
        if Conns.TpWalk then return end
        Features.Fly1.Enabled = false; Updaters.Fly1()
        Features.Fly2.Enabled = false; Updaters.Fly2()
        Features.FreeMove.Enabled = false; Updaters.FreeMove()
        if humanoid then disableMovementStates(humanoid) end
        Conns.TpWalk = RunService.Heartbeat:Connect(function()
            if not hrp or not humanoid then return end
            local dist = Features.TpWalk.Value or 2
            local md = humanoid.MoveDirection
            if md.Magnitude > 0 then
                local rp = RaycastParams.new()
                rp.FilterDescendantsInstances = {character}
                rp.FilterType = Enum.RaycastFilterType.Blacklist
                local res = Workspace:Raycast(hrp.Position, md * dist, rp)
                if res then
                    hrp.CFrame = hrp.CFrame + (res.Position - hrp.Position).Unit * dist
                else
                    hrp.CFrame = hrp.CFrame + md * dist
                end
            end
        end)
    else
        unbind("TpWalk")
        if humanoid then enableMovementStates(humanoid) end
    end
end

Updaters.Fly1 = function()
    if Features.Fly1.Enabled then
        if Conns.Fly1 then return end
        Features.Fly2.Enabled = false; Updaters.Fly2()
        Features.FreeMove.Enabled = false; Updaters.FreeMove()
        Features.TpWalk.Enabled = false; Updaters.TpWalk()
        if humanoid then disableMovementStates(humanoid) end
        Conns.Fly1 = RunService.Heartbeat:Connect(function(dt)
            if not hrp then return end
            local speed = math.clamp(Features.Fly1.Value or 45, 1, 500)
            local kbX = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            local kbZ = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            local kbY = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0)
            local moveY = kbY ~= 0 and kbY or Fly1BtnY
            local camCF = Camera.CFrame
            local dir = camCF.RightVector * kbX + camCF.LookVector * kbZ + Vector3.new(0, moveY, 0)
            if dir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + dir.Unit * (speed * dt)
            end
        end)
    else
        unbind("Fly1")
        if humanoid then enableMovementStates(humanoid) end
    end
end

Updaters.Fly2 = function()
    if Features.Fly2.Enabled then
        if Conns.Fly2 then return end
        Features.Fly1.Enabled = false; Updaters.Fly1()
        Features.FreeMove.Enabled = false; Updaters.FreeMove()
        Features.TpWalk.Enabled = false; Updaters.TpWalk()
        if humanoid then disableMovementStates(humanoid) end
        Conns.Fly2 = RunService.Heartbeat:Connect(function(dt)
            if not hrp or not Features.Fly2.Flying then return end
            local speed = math.clamp(Features.Fly2.Value or 50, 1, 500)
            local moveY = (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0)
            local moveX = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            local moveZ = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            local camCF = Camera.CFrame
            local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
            if forward.Magnitude < 0.01 then forward = Vector3.new(0, 0, -1) end
            forward = forward.Unit
            local dir = camCF.RightVector * moveX + forward * moveZ + Vector3.new(0, moveY, 0)
            if dir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + dir.Unit * (speed * dt)
            end
        end)
    else
        unbind("Fly2")
        Features.Fly2.Flying = false
        if humanoid then enableMovementStates(humanoid) end
    end
end

local FreeMoveBG, FreeMoveBV
Updaters.FreeMove = function()
    if Features.FreeMove.Enabled then
        if Conns.FreeMove then return end
        Features.Fly1.Enabled = false; Updaters.Fly1()
        Features.Fly2.Enabled = false; Updaters.Fly2()
        Features.TpWalk.Enabled = false; Updaters.TpWalk()
        Conns.FreeMove = RunService.RenderStepped:Connect(function()
            if not hrp or not humanoid then return end
            if not FreeMoveBG or not FreeMoveBG.Parent then
                FreeMoveBG = Instance.new("BodyGyro")
                FreeMoveBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                FreeMoveBG.P = 9e4
                FreeMoveBG.D = 100
                FreeMoveBG.CFrame = hrp.CFrame
                FreeMoveBG.Parent = hrp
                FreeMoveBV = Instance.new("BodyVelocity")
                FreeMoveBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                FreeMoveBV.P = 1e5
                FreeMoveBV.Velocity = Vector3.zero
                FreeMoveBV.Parent = hrp
                humanoid.PlatformStand = true
            end
            local speed = math.clamp(Features.FreeMove.Value or 50, 1, 500)
            local moveZ = (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
            local moveX = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            local moveY = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0)
            local camCF = Camera.CFrame
            local rightVec = camCF.RightVector
            local forwardVec = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
            if forwardVec.Magnitude < 0.01 then forwardVec = Vector3.new(0, 0, -1) end
            forwardVec = forwardVec.Unit
            local offset = rightVec * moveX + Vector3.new(0, moveY, 0) + forwardVec * moveZ
            if offset.Magnitude > 0 then offset = offset.Unit end
            FreeMoveBV.Velocity = offset * speed
            if forwardVec.Magnitude > 0.01 then
                FreeMoveBG.CFrame = CFrame.new(hrp.Position, hrp.Position + forwardVec)
            end
        end)
    else
        unbind("FreeMove")
        if FreeMoveBG then pcall(function() FreeMoveBG:Destroy() end); FreeMoveBG = nil end
        if FreeMoveBV then pcall(function() FreeMoveBV:Destroy() end); FreeMoveBV = nil end
        if humanoid then humanoid.PlatformStand = false end
    end
end

local NoclipCache = {}
Updaters.Noclip = function()
    if Features.Noclip.Enabled then
        if Conns.Noclip then return end
        NoclipCache = {}
        Conns.Noclip = RunService.Stepped:Connect(function()
            if not character then return end
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if NoclipCache[part] == nil then NoclipCache[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        end)
    else
        unbind("Noclip")
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and NoclipCache[part] ~= nil then
                    part.CanCollide = NoclipCache[part]
                end
            end
        end
        NoclipCache = {}
    end
end

local BunnyCount = 0
Updaters.BunnyHop = function()
    if Features.BunnyHop.Enabled then
        if Conns.BunnyJump then return end
        BunnyCount = 0
        Conns.BunnyJump = UserInputService.JumpRequest:Connect(function()
            if not humanoid then return end
            BunnyCount = BunnyCount + 1
            local bonus = math.min(BunnyCount * Features.BunnyHop.Value, 300)
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.delay(0.05, function()
                if hrp then
                    local vel = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = Vector3.new(vel.X, math.min(50 + bonus, 300), vel.Z)
                end
            end)
        end)
        Conns.BunnyLand = humanoid and humanoid.StateChanged:Connect(function(_, new)
            if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
                BunnyCount = 0
            end
        end) or nil
    else
        unbind("BunnyJump"); unbind("BunnyLand")
        BunnyCount = 0
    end
end

Updaters.AutoRun = function()
    if Features.AutoRun.Enabled then
        if Conns.AutoRun then return end
        Conns.AutoRun = RunService.Heartbeat:Connect(function()
            if humanoid then humanoid:Move(Vector3.new(0,0,-1), true) end
        end)
    else
        unbind("AutoRun")
    end
end

Updaters.SuperJump = function()
    if Features.SuperJump.Enabled then
        if Conns.SuperJump then return end
        Conns.SuperJump = UserInputService.JumpRequest:Connect(function()
            if hrp then
                local vel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, Features.SuperJump.Value, vel.Z)
            end
        end)
    else
        unbind("SuperJump")
    end
end

Updaters.WallClimb = function()
    if Features.WallClimb.Enabled then
        if Conns.WallClimb then return end
        Conns.WallClimb = RunService.Heartbeat:Connect(function()
            if not hrp then return end
            local ray = Ray.new(hrp.Position, hrp.CFrame.LookVector * 2)
            local hit = Workspace:FindPartOnRay(ray, character)
            if hit then
                local vel = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, Features.WallClimb.Value, vel.Z)
            end
        end)
    else
        unbind("WallClimb")
    end
end

Updaters.GodMode = function()
    if Features.GodMode.Enabled then
        if Conns.God then return end
        Conns.God = RunService.Heartbeat:Connect(function()
            if humanoid then
                humanoid.Health = humanoid.MaxHealth
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            end
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanTouch = false end
                end
            end
        end)
    else
        unbind("God")
        if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanTouch = true end
            end
        end
    end
end

local NoCdLast = 0
Updaters.NoCooldown = function()
    if Features.NoCooldown.Enabled then
        if Conns.NoCooldown then return end
        NoCdLast = 0
        Conns.NoCooldown = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - NoCdLast < 0.5 then return end
            NoCdLast = now
            local function zeroTool(tool)
                if not tool then return end
                for _, obj in pairs(tool:GetDescendants()) do
                    if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("DoubleConstrainedValue") then
                        local n = obj.Name:lower()
                        if n:find("cool") or n:find("cd") or n:find("delay") or n:find("interval") then
                            obj.Value = 0
                        end
                    end
                end
            end
            local tool = character and character:FindFirstChildOfClass("Tool")
            zeroTool(tool)
            for _, t in pairs(player.Backpack:GetChildren()) do
                if t:IsA("Tool") then zeroTool(t) end
            end
        end)
    else
        unbind("NoCooldown")
    end
end

local InfAmmoLast = 0
Updaters.InfiniteAmmo = function()
    if Features.InfiniteAmmo.Enabled then
        if Conns.InfAmmo then return end
        InfAmmoLast = 0
        Conns.InfAmmo = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - InfAmmoLast < 0.5 then return end
            InfAmmoLast = now
            local function refill(tool)
                if not tool then return end
                for _, obj in pairs(tool:GetDescendants()) do
                    if obj:IsA("IntValue") or obj:IsA("NumberValue") then
                        local n = obj.Name:lower()
                        if n:find("ammo") or n:find("bullet") or n:find("mag") or n:find("clip") or n:find("reserve") then
                            obj.Value = 9999
                        end
                    end
                end
            end
            local tool = character and character:FindFirstChildOfClass("Tool")
            refill(tool)
            for _, t in pairs(player.Backpack:GetChildren()) do
                if t:IsA("Tool") then refill(t) end
            end
        end)
    else
        unbind("InfAmmo")
    end
end

Updaters.AutoAttack = function()
    if Features.AutoAttack.Enabled then
        if Conns.AutoAtk then return end
        Conns.AutoAtk = RunService.Heartbeat:Connect(function() tryFireTool() end)
    else
        unbind("AutoAtk")
    end
end

Updaters.KillAura = function()
    if Features.KillAura.Enabled then
        if Conns.KillAura then return end
        local tickCount = 0
        Conns.KillAura = RunService.Heartbeat:Connect(function()
            if not hrp then return end
            tickCount = tickCount + 1
            if tickCount % 2 ~= 0 then return end
            local range = Features.KillAura.Value
            updateTargetCache()
            for _, e in ipairs(TargetCache.All) do
                if e.Hrp and (hrp.Position - e.Hrp.Position).Magnitude <= range then
                    if e.IsPlayer then tryFireTool() end
                    pcall(function() e.Hum.Health = 0 end)
                end
            end
        end)
    else
        unbind("KillAura")
    end
end

Updaters.Aimbot = function()
    if Features.Aimbot.Enabled then
        if Conns.Aimbot then return end
        Conns.Aimbot = RunService.Heartbeat:Connect(function()
            if not hrp then return end
            local closest, minDist = nil, math.huge
            updateTargetCache()
            for _, e in ipairs(TargetCache.Players) do
                if e.Hrp then
                    local d = (hrp.Position - e.Hrp.Position).Magnitude
                    if d < minDist then minDist = d; closest = e.Hrp end
                end
            end
            if closest then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
            end
        end)
    else
        unbind("Aimbot")
    end
end

Updaters.RapidFire = function()
    if Features.RapidFire.Enabled then
        if Conns.Rapid then return end
        Conns.Rapid = RunService.Heartbeat:Connect(function() tryFireTool() end)
    else
        unbind("Rapid")
    end
end

Updaters.AutoFire = function()
    if Features.AutoFire.Enabled then
        if Conns.AutoFire then return end
        local tickCount = 0
        Conns.AutoFire = RunService.Heartbeat:Connect(function()
            if not Features.AimbotV2.Enabled then return end
            tickCount = tickCount + 1
            if tickCount % 3 ~= 0 then return end
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            local radius = Features.AimbotV2.CircleSize / 2
            updateTargetCache()
            local targets = {}
            local ct = Features.AimbotV2.CustomTarget
            if ct and ct.Parent then table.insert(targets, ct)
            else
                if Features.AimbotV2.AimPlayer then
                    for _, e in ipairs(TargetCache.Players) do table.insert(targets, e.Obj) end
                end
                if Features.AimbotV2.AimNpc then
                    for _, e in ipairs(TargetCache.Npcs) do table.insert(targets, e.Obj) end
                end
            end
            for _, char in ipairs(targets) do
                local aimPart = char:FindFirstChild(Features.AimbotV2.AimPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if aimPart then
                    local sp, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                    if onScreen and sp.Z >= 0 then
                        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if dist <= radius then tryFireTool(); break end
                    end
                end
            end
        end)
    else
        unbind("AutoFire")
    end
end

-- 视觉
local OrigLighting = {}
Updaters.NightVision = function()
    if Features.NightVision.Enabled then
        if Conns.Night then return end
        OrigLighting.Brightness = Lighting.Brightness
        OrigLighting.ClockTime = Lighting.ClockTime
        OrigLighting.FogEnd = Lighting.FogEnd
        OrigLighting.GlobalShadows = Lighting.GlobalShadows
        Conns.Night = RunService.Heartbeat:Connect(function()
            Lighting.Brightness = 10
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        end)
    else
        unbind("Night")
        Lighting.Brightness = OrigLighting.Brightness or 1
        Lighting.ClockTime = OrigLighting.ClockTime or 12
        Lighting.FogEnd = OrigLighting.FogEnd or 1000
        Lighting.GlobalShadows = OrigLighting.GlobalShadows ~= false
    end
end

Updaters.FullBright = function()
    if Features.FullBright.Enabled then
        if Conns.Bright then return end
        Conns.Bright = RunService.Heartbeat:Connect(function()
            Lighting.Brightness = 100
            Lighting.GlobalShadows = false
            for _, v in pairs(Lighting:GetDescendants()) do
                if v:IsA("PostEffect") then v.Enabled = false end
            end
        end)
    else
        unbind("Bright")
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
    end
end

local EspFolder = Instance.new("Folder")
EspFolder.Name = "StarESP"; EspFolder.Parent = CoreGui
Updaters.ESP = function()
    if Features.ESP.Enabled then
        if Conns.ESP then return end
        local tickCount = 0
        Conns.ESP = RunService.RenderStepped:Connect(function()
            tickCount = tickCount + 1
            if tickCount % 2 ~= 0 then return end
            for _, v in pairs(EspFolder:GetChildren()) do v:Destroy() end
            updateTargetCache()
            for _, e in ipairs(TargetCache.Players) do
                local char = e.Obj
                local hrp2 = e.Hrp
                if not hrp2 or not inRenderRange(hrp2.Position) then continue end
                local minV = Vector3.new(math.huge, math.huge, math.huge)
                local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
                local hasPart = false
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        hasPart = true
                        local pos = part.Position
                        minV = Vector3.new(math.min(minV.X, pos.X), math.min(minV.Y, pos.Y), math.min(minV.Z, pos.Z))
                        maxV = Vector3.new(math.max(maxV.X, pos.X), math.max(maxV.Y, pos.Y), math.max(maxV.Z, pos.Z))
                    end
                end
                if not hasPart then continue end
                local min2d = Vector2.new(math.huge, math.huge)
                local max2d = Vector2.new(-math.huge, -math.huge)
                local visible = false
                local pts = {
                    Vector3.new(minV.X, minV.Y, minV.Z), Vector3.new(minV.X, maxV.Y, minV.Z),
                    Vector3.new(maxV.X, minV.Y, minV.Z), Vector3.new(maxV.X, maxV.Y, minV.Z),
                    Vector3.new(minV.X, minV.Y, maxV.Z), Vector3.new(minV.X, maxV.Y, maxV.Z),
                    Vector3.new(maxV.X, minV.Y, maxV.Z), Vector3.new(maxV.X, maxV.Y, maxV.Z),
                }
                for _, pt in ipairs(pts) do
                    local sp = Camera:WorldToViewportPoint(pt)
                    if sp.Z >= 0 then
                        visible = true
                        local p2 = Vector2.new(sp.X, sp.Y)
                        min2d = Vector2.new(math.min(min2d.X, p2.X), math.min(min2d.Y, p2.Y))
                        max2d = Vector2.new(math.max(max2d.X, p2.X), math.max(max2d.Y, p2.Y))
                    end
                end
                if not visible then continue end
                local size = max2d - min2d
                if size.X < 3 or size.Y < 3 then continue end
                local box = Instance.new("Frame")
                box.Size = UDim2.new(0, size.X, 0, size.Y)
                box.Position = UDim2.new(0, min2d.X, 0, min2d.Y)
                box.BackgroundTransparency = 1
                box.BorderSizePixel = 0
                box.Parent = EspFolder
                local stroke = Instance.new("UIStroke")
                stroke.Color = getGoldColor(e.Plr.UserId)
                stroke.Thickness = 1.5
                stroke.Parent = box
                local nl = Instance.new("TextLabel")
                nl.Size = UDim2.new(1,0,0,18); nl.Position = UDim2.new(0,0,0,-18)
                nl.BackgroundTransparency = 1; nl.Text = e.Plr.Name
                nl.TextColor3 = C.Gold; nl.TextSize = 11
                nl.Font = Enum.Font.GothamBold; nl.Parent = box
            end
        end)
    else
        unbind("ESP")
        for _, v in pairs(EspFolder:GetChildren()) do v:Destroy() end
    end
end

local function isCharPart(v)
    if character and v:IsDescendantOf(character) then return true end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and v:IsDescendantOf(p.Character) then return true end
    end
    return false
end
local XrayTick = 0
Updaters.Xray = function()
    if Features.Xray.Enabled then
        if Conns.Xray then return end
        local function applyXray()
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.LocalTransparencyModifier = isCharPart(v) and 0 or 0.5
                end
            end
        end
        applyXray()
        Conns.Xray = Workspace.DescendantAdded:Connect(function(v)
            if v:IsA("BasePart") then
                v.LocalTransparencyModifier = isCharPart(v) and 0 or 0.5
            end
        end)
        Conns.XrayTimer = RunService.Heartbeat:Connect(function()
            XrayTick = XrayTick + 1
            if XrayTick >= 180 then
                XrayTick = 0
                applyXray()
            end
        end)
    else
        unbind("Xray"); unbind("XrayTimer")
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.LocalTransparencyModifier = 0 end
        end
    end
end

Updaters.NoFog = function()
    if Features.NoFog.Enabled then
        if Conns.NoFog then return end
        Conns.NoFog = RunService.Heartbeat:Connect(function()
            Lighting.FogEnd = 100000; Lighting.FogStart = 0
        end)
    else
        unbind("NoFog")
    end
end

local FilterFrame = Instance.new("Frame")
FilterFrame.Size = UDim2.new(1,0,1,0); FilterFrame.BackgroundTransparency = 1
FilterFrame.Visible = false; FilterFrame.ZIndex = 9000; FilterFrame.Parent = CoreGui
Updaters.ColorFilter = function()
    if Features.ColorFilter.Enabled then
        FilterFrame.Visible = true
        local c = Features.ColorFilter.Value:lower()
        local colorMap = {
            red = Color3.fromRGB(255,0,0), blue = Color3.fromRGB(0,0,255),
            green = Color3.fromRGB(0,255,0), pink = Color3.fromRGB(255,0,255),
            yellow = Color3.fromRGB(255,255,0), cyan = Color3.fromRGB(0,255,255),
        }
        FilterFrame.BackgroundColor3 = colorMap[c] or Color3.fromRGB(255,100,100)
        FilterFrame.BackgroundTransparency = 0.3
    else
        FilterFrame.Visible = false
    end
end

local OrigCamType = Camera.CameraType
Updaters.FreeCam = function()
    if Features.FreeCam.Enabled then
        if Conns.FreeCam then return end
        OrigCamType = Camera.CameraType
        Camera.CameraType = Enum.CameraType.Scriptable
        local camPos = Camera.CFrame.Position
        local camRot = Camera.CFrame.Rotation
        Conns.FreeCam = RunService.Heartbeat:Connect(function(dt)
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
            if move.Magnitude > 0 then camPos = camPos + move.Unit * 50 * dt end
            local delta = UserInputService:GetMouseDelta()
            camRot = camRot * CFrame.Angles(math.rad(-delta.Y*0.3), math.rad(-delta.X*0.3), 0)
            Camera.CFrame = CFrame.new(camPos) * camRot
        end)
    else
        unbind("FreeCam")
        Camera.CameraType = OrigCamType
    end
end

Updaters.ThermalESP = function()
    if Features.ThermalESP.Enabled then
        if Conns.Thermal then return end
        Conns.Thermal = RunService.Heartbeat:Connect(function()
            updateTargetCache()
            local seen = {}
            for _, e in ipairs(TargetCache.Players) do
                local p = e.Plr
                local char = e.Obj
                if e.Hrp and not inRenderRange(e.Hrp.Position) then continue end
                seen[p] = true
                local h = ThermalHighlights[p]
                if not h or not h.Parent then
                    h = Instance.new("Highlight")
                    h.Name = "SG_Thermal"
                    h.FillTransparency = 0.4
                    h.OutlineTransparency = 0
                    h.OutlineColor = Color3.fromRGB(255,255,255)
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Adornee = char
                    h.Parent = char
                    ThermalHighlights[p] = h
                end
                h.FillColor = getGoldColor(p.UserId + 10)
            end
            for p, h in pairs(ThermalHighlights) do
                if not seen[p] then
                    pcall(function() h:Destroy() end)
                    ThermalHighlights[p] = nil
                end
            end
        end)
    else
        unbind("Thermal")
        for p, h in pairs(ThermalHighlights) do
            pcall(function() h:Destroy() end)
            ThermalHighlights[p] = nil
        end
    end
end

-- 工具
Updaters.MusicPlayer = function()
    if Features.MusicPlayer.Enabled then
        if not MusicPanel then buildMusicPanel() end
        MusicPanel.Visible = true
        initMusicDir()
        if Music.DirReady and #Music.List == 0 then loadLocalSongs() end
    else
        if MusicPanel then MusicPanel.Visible = false end
    end
end

local ClickerBalls = {}
local function createClickerBall()
    local ball = Instance.new("Frame")
    ball.Size = UDim2.new(0, 35, 0, 35)
    ball.Position = UDim2.new(0.4 + math.random() * 0.2, 0, 0.4 + math.random() * 0.2, 0)
    ball.BackgroundColor3 = C.Gold
    ball.BackgroundTransparency = 0.2
    ball.Visible = false
    ball.ZIndex = 9100
    ball.Parent = CoreGui
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = ball
    local stroke = Instance.new("UIStroke"); stroke.Color = C.Gold; stroke.Thickness = 2; stroke.Parent = ball
    local crossH = Instance.new("Frame")
    crossH.Size = UDim2.new(0, 20, 0, 2); crossH.Position = UDim2.new(0.5, -10, 0.5, -1)
    crossH.BackgroundColor3 = Color3.fromRGB(255,255,255); crossH.BorderSizePixel = 0
    crossH.Parent = ball
    local crossV = Instance.new("Frame")
    crossV.Size = UDim2.new(0, 2, 0, 20); crossV.Position = UDim2.new(0.5, -1, 0.5, -10)
    crossV.BackgroundColor3 = Color3.fromRGB(255,255,255); crossV.BorderSizePixel = 0
    crossV.Parent = ball
    table.insert(ClickerBalls, ball)
    return ball
end
Gui = {ClickerBalls = ClickerBalls}

Updaters.AutoClicker = function()
    if Features.AutoClicker.Enabled then
        if Conns.ClickerColor then return end
        Conns.ClickerColor = RunService.Heartbeat:Connect(function()
            for i, ball in ipairs(ClickerBalls) do
                if ball and ball.Visible then
                    ball.BackgroundColor3 = getGoldColor(i * 5)
                end
            end
        end)
    else
        unbind("ClickerColor")
    end
end

Updaters.ClickerStart = function()
    if Features.ClickerStart.Enabled then
        if ClickerThread then return end
        ClickerThread = task.spawn(function()
            local inset = GuiService:GetGuiInset()
            while Features.ClickerStart.Enabled do
                for _, ball in ipairs(ClickerBalls) do
                    if ball and ball.Visible and ball.Parent then
                        local pos = ball.AbsolutePosition + ball.AbsoluteSize / 2 + Vector2.new(inset.X, inset.Y)
                        pcall(function()
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                            task.wait(0.01)
                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                        end)
                    end
                end
                task.wait(math.max(Features.AutoClicker.Value or 10, 1) / 1000)
            end
            ClickerThread = nil
        end)
    else
        ClickerThread = nil
    end
end

Updaters.ClickerMulti = function()
    if Features.ClickerMulti.Enabled then
        for i = 1, 3 do
            if #ClickerBalls < 8 then createClickerBall() end
        end
    else
        while #ClickerBalls > 2 do
            local b = table.remove(ClickerBalls)
            if b then b:Destroy() end
        end
    end
    for _, ball in ipairs(ClickerBalls) do
        ball.Visible = Features.AutoClicker.Enabled
    end
end

Updaters.FastInteract = function()
    if Features.FastInteract.Enabled then
        if Conns.FastInt then return end
        Conns.FastInt = RunService.Heartbeat:Connect(function()
            for _, p in pairs(Workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then p.HoldDuration = 0 end
            end
        end)
    else
        unbind("FastInt")
    end
end

Updaters.AutoSave = function()
    if Features.AutoSave.Enabled then
        if AutoSaveThread then return end
        AutoSaveThread = task.spawn(function()
            while Features.AutoSave.Enabled do
                pcall(function()
                    local save = {}
                    for k, v in pairs(Features) do
                        if type(v) == "table" then
                            save[k] = {}
                            for kk, vv in pairs(v) do
                                if type(vv) ~= "function" and type(vv) ~= "userdata" and type(vv) ~= "Instance" then
                                    save[k][kk] = vv
                                end
                            end
                        end
                    end
                    writefile("StarAux_Config.json", HttpService:JSONEncode(save))
                end)
                task.wait(15)
            end
            AutoSaveThread = nil
        end)
    else
        AutoSaveThread = nil
    end
end

Updaters.AntiAfk = function()
    if Features.AntiAfk.Enabled then
        if AntiAfkThread then return end
        AntiAfkThread = task.spawn(function()
            while Features.AntiAfk.Enabled do
                pcall(function()
                    if hrp then
                        local bv = Instance.new("BodyVelocity")
                        bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.zero
                        bv.Parent = hrp; task.wait(0.1); bv:Destroy()
                    end
                end)
                task.wait(60)
            end
            AntiAfkThread = nil
        end)
    else
        AntiAfkThread = nil
    end
end

-- 人物渲染
Updaters.NpcDisplay = function()
    if Features.NpcDisplay.Enabled then
        if Conns.NpcDisp then return end
        local tickCount = 0
        Conns.NpcDisp = RunService.RenderStepped:Connect(function()
            tickCount = tickCount + 1
            if tickCount % 2 ~= 0 then return end
            clearBeams(BeamPools.Npc)
            clearPool(Pools.Npc.Dots)
            updateTargetCache()
            local count = 0
            for _, e in ipairs(TargetCache.Npcs) do
                if count >= 50 then break end
                local model = e.Obj
                if e.Hrp and not inRenderRange(e.Hrp.Position) then continue end
                local skeleton = getSkeleton(model)
                for _, pair in ipairs(skeleton) do
                    local p1 = model:FindFirstChild(pair[1])
                    local p2 = model:FindFirstChild(pair[2])
                    if p1 and p2 and Features.NpcDisplay.ShowBones then
                        drawBone(BeamPools.Npc, p1, p2, getGoldColor(model.Name:byte(1) or 1))
                    end
                end
                for _, partName in ipairs({"Head","UpperTorso","LowerTorso","Torso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}) do
                    local part = model:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        local sp, onScreen = worldToScreen(part.Position)
                        if onScreen then
                            local shouldShow = false
                            if partName == "Head" and Features.NpcDisplay.ShowHead then shouldShow = true end
                            if (partName == "UpperTorso" or partName == "LowerTorso" or partName == "Torso") and Features.NpcDisplay.ShowTorso then shouldShow = true end
                            if (partName:find("Arm") or partName:find("Leg")) and Features.NpcDisplay.ShowLimbs then shouldShow = true end
                            if shouldShow then
                                local dot = getFromPool(Pools.Npc.Dots, RenderFolder)
                                dot.Size = UDim2.new(0, 6, 0, 6)
                                dot.Position = UDim2.new(0, sp.X-3, 0, sp.Y-3)
                                dot.BackgroundColor3 = getGoldColor(model.Name:byte(1) + #partName)
                                dot.Parent = RenderFolder
                            end
                        end
                    end
                end
                count = count + 1
            end
        end)
    else
        unbind("NpcDisp")
        clearBeams(BeamPools.Npc)
        clearPool(Pools.Npc.Dots)
    end
end

Updaters.PlayerDisplay = function()
    if Features.PlayerDisplay.Enabled then
        if Conns.PlayerDisp then return end
        Conns.PlayerDisp = RunService.RenderStepped:Connect(function()
            clearBeams(BeamPools.Player)
            clearPool(Pools.Player.Dots)
            clearPool(Pools.Player.Texts)
            updateTargetCache()
            for _, e in ipairs(TargetCache.Players) do
                local char = e.Obj
                local p = e.Plr
                local hum = e.Hum
                local targetHrp = e.Hrp
                if not targetHrp or not inRenderRange(targetHrp.Position) then continue end
                local skeleton = getSkeleton(char)
                for _, pair in ipairs(skeleton) do
                    local p1 = char:FindFirstChild(pair[1])
                    local p2 = char:FindFirstChild(pair[2])
                    if p1 and p2 and Features.PlayerDisplay.ShowBones then
                        drawBone(BeamPools.Player, p1, p2, getGoldColor(p.UserId))
                    end
                end
                local sp, onScreen = worldToScreen(targetHrp.Position)
                if onScreen then
                    local txtLines = {}
                    if Features.PlayerDisplay.ShowName then table.insert(txtLines, p.Name) end
                    if Features.PlayerDisplay.ShowHealth and hum then
                        table.insert(txtLines, string.format("❤ %.0f", hum.Health))
                    end
                    if Features.PlayerDisplay.ShowDistance and hrp and targetHrp then
                        table.insert(txtLines, string.format("%.1fm", (hrp.Position - targetHrp.Position).Magnitude))
                    end
                    if #txtLines > 0 then
                        local label = getFromPool(Pools.Player.Texts, RenderFolder)
                        label.Size = UDim2.new(0, 130, 0, 44)
                        label.Position = UDim2.new(0, sp.X-65, 0, sp.Y-58)
                        label.Text = table.concat(txtLines, "\n")
                        label.TextColor3 = C.Gold
                        label.TextSize = 11
                        label.Font = Enum.Font.GothamBold
                        label.Parent = RenderFolder
                    end
                    for _, partName in ipairs({"Head","UpperTorso","LowerTorso","Torso"}) do
                        local part = char:FindFirstChild(partName)
                        if part and part:IsA("BasePart") then
                            local psp, pon = worldToScreen(part.Position)
                            if pon then
                                local shouldShow = false
                                if partName == "Head" and Features.PlayerDisplay.ShowHead then shouldShow = true end
                                if (partName == "UpperTorso" or partName == "LowerTorso" or partName == "Torso") and Features.PlayerDisplay.ShowTorso then shouldShow = true end
                                if shouldShow then
                                    local dot = getFromPool(Pools.Player.Dots, RenderFolder)
                                    dot.Size = UDim2.new(0, 6, 0, 6)
                                    dot.Position = UDim2.new(0, psp.X-3, 0, psp.Y-3)
                                    dot.BackgroundColor3 = getGoldColor(p.UserId + #partName)
                                    dot.Parent = RenderFolder
                                end
                            end
                        end
                    end
                end
            end
        end)
    else
        unbind("PlayerDisp")
        clearBeams(BeamPools.Player)
        clearPool(Pools.Player.Dots)
        clearPool(Pools.Player.Texts)
    end
end

Updaters.BoxCreature = function()
    if Features.BoxCreature.Enabled then
        if Conns.BoxCreature then return end
        Conns.BoxCreature = RunService.RenderStepped:Connect(function()
            clearPool(Pools.Box.Lines)
            clearAdorns(AdornPools.Box)
            clearAdorns(AdornPools.Hitbox)
            updateTargetCache()
            local maxD = Features.BoxCreature.MaxDistance or 0
            local function drawFor(char, key)
                local hrp2 = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
                if hrp2 and not inRenderRange(hrp2.Position) then return end
                if maxD ~= 0 and hrp and hrp2 then
                    if (hrp.Position - hrp2.Position).Magnitude > maxD then return end
                end
                if Features.BoxCreature.ShowHitbox then
                    drawHitbox3D(AdornPools.Hitbox, char, C.Gold)
                elseif Features.BoxCreature.BoxMode == "3D" then
                    drawBox3D(AdornPools.Box, char, getGoldColor(key:byte(1) or 1))
                else
                    drawBox2D(Pools.Box.Lines, RenderFolder, char, getGoldColor(key:byte(1) or 1))
                end
            end
            if Features.BoxCreature.BoxPlayer then
                for _, e in ipairs(TargetCache.Players) do drawFor(e.Obj, e.Obj.Name) end
            end
            if Features.BoxCreature.BoxNpc then
                for _, e in ipairs(TargetCache.Npcs) do drawFor(e.Obj, e.Obj.Name) end
            end
            if Features.BoxCreature.BoxOther then
                for _, m in ipairs(TargetCache.Others) do drawFor(m, m.Name) end
            end
        end)
    else
        unbind("BoxCreature")
        clearPool(Pools.Box.Lines)
        clearAdorns(AdornPools.Box)
        clearAdorns(AdornPools.Hitbox)
    end
end

Updaters.LineConnect = function()
    if Features.LineConnect.Enabled then
        if Conns.LineConnect then return end
        Conns.LineConnect = RunService.RenderStepped:Connect(function()
            clearBeams(BeamPools.Connect)
            updateTargetCache()
            local o = Features.LineConnect.Origin or "Top"
            local maxD = Features.LineConnect.MaxDistance or 0
            local offsetY = o == "Top" and 3 or (o == "Bottom" and -3 or 0)
            local origin = Camera.CFrame:PointToWorldSpace(Vector3.new(0, offsetY, -6))
            local function drawLineTo(char, key)
                if not char then return end
                local head = char:FindFirstChild("Head")
                local hrp2 = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                local endPos = head and head.Position or (hrp2 and hrp2.Position or nil)
                if not endPos or not inRenderRange(endPos) then return end
                if maxD ~= 0 and hrp and (hrp.Position - endPos).Magnitude > maxD then return end
                if Features.LineConnect.LineWallCheck then
                    local checkPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                    if checkPart and isBlockedByWall(checkPart, char) then return end
                end
                draw3DLine(BeamPools.Connect, origin, endPos, getGoldColor(key:byte(1) or 1))
            end
            if Features.LineConnect.ConnectPlayer then
                for _, e in ipairs(TargetCache.Players) do drawLineTo(e.Obj, e.Plr.Name) end
            end
            if Features.LineConnect.ConnectNpc then
                for _, e in ipairs(TargetCache.Npcs) do drawLineTo(e.Obj, e.Obj.Name) end
            end
            if Features.LineConnect.ConnectOther then
                for _, m in ipairs(TargetCache.Others) do drawLineTo(m, m.Name) end
            end
        end)
    else
        unbind("LineConnect")
        clearBeams(BeamPools.Connect)
    end
end

local AimScanTick = 0
local AimClosest = nil
Updaters.AimbotV2 = function()
    if Features.AimbotV2.Enabled then
        if Conns.AimbotV2 then return end
        AimClosest = nil
        AimScanTick = 0
        Conns.AimbotV2 = RunService.RenderStepped:Connect(function()
            AimScanTick = AimScanTick + 1
            if AimScanTick % 3 == 0 then
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                local radius = Features.AimbotV2.CircleSize / 2
                local maxD = Features.AimbotV2.MaxDistance or 0
                local best, bestDist = nil, math.huge
                updateTargetCache()
                local targets = {}
                local ct = Features.AimbotV2.CustomTarget
                if ct and ct.Parent then
                    local hum = ct:FindFirstChildOfClass("Humanoid")
                    local hrp2 = ct:FindFirstChild("HumanoidRootPart") or ct:FindFirstChild("Torso")
                    table.insert(targets, {Obj = ct, Hum = hum, Hrp = hrp2})
                else
                    Features.AimbotV2.CustomTarget = nil
                    if Features.AimbotV2.AimPlayer then
                        for _, e in ipairs(TargetCache.Players) do table.insert(targets, e) end
                    end
                    if Features.AimbotV2.AimNpc then
                        for _, e in ipairs(TargetCache.Npcs) do table.insert(targets, e) end
                    end
                    if Features.AimbotV2.AimOther then
                        for _, m in ipairs(TargetCache.Others) do
                            table.insert(targets, {Obj = m, Hum = nil, Hrp = m.PrimaryPart})
                        end
                    end
                end
                for _, e in ipairs(targets) do
                    local char = e.Obj
                    local hum = e.Hum
                    if Features.AimbotV2.AliveCheck and hum and hum.Health <= 0 then continue end
                    if Features.AimbotV2.TeamCheck and e.Plr and e.Plr.Team ~= nil and e.Plr.Team == player.Team then continue end
                    local aimPart = char:FindFirstChild(Features.AimbotV2.AimPart) or char:FindFirstChild("Head") or e.Hrp
                    if not aimPart then continue end
                    local sp, onScreen = worldToScreen(aimPart.Position)
                    if not onScreen then continue end
                    if (Vector2.new(sp.X, sp.Y) - center).Magnitude > radius then continue end
                    if Features.AimbotV2.WallCheck and isBlockedByWall(aimPart, char) then continue end
                    local worldDist = hrp and (hrp.Position - aimPart.Position).Magnitude or 0
                    if maxD ~= 0 and worldDist > maxD then continue end
                    local aimPos = aimPart.Position
                    if Features.AimbotV2.Predict and aimPart:IsA("BasePart") then
                        local dist3 = (Camera.CFrame.Position - aimPos).Magnitude
                        aimPos = aimPos + aimPart.AssemblyLinearVelocity * (dist3 / 1000)
                    end
                    if worldDist < bestDist then bestDist = worldDist; best = aimPos end
                end
                AimClosest = best
            end
            if AimClosest then
                local targetCF = CFrame.new(Camera.CFrame.Position, AimClosest)
                if Features.AimbotV2.Smooth then
                    Camera.CFrame = Camera.CFrame:Lerp(targetCF, Features.AimbotV2.AimSpeed or 0.3)
                else
                    Camera.CFrame = targetCF
                end
            end
        end)
    else
        unbind("AimbotV2")
        AimClosest = nil
    end
end

Updaters.AdvancedESP = function()
    if Features.AdvancedESP.Enabled then
        if Conns.AdvESP then return end
        local tickCount = 0
        Conns.AdvESP = RunService.RenderStepped:Connect(function()
            tickCount = tickCount + 1
            if tickCount % 2 ~= 0 then return end
            clearPool(Pools.Adv.Boxes)
            clearPool(Pools.Adv.Lines)
            clearPool(Pools.Adv.Texts)
            clearPool(Pools.Adv.Bars)
            clearBeams(BeamPools.Adv)
            local valid = {}
            local targets = {}
            updateTargetCache()
            for _, e in ipairs(TargetCache.Players) do
                table.insert(targets, {Char=e.Obj, Hum=e.Hum, IsPlayer=true, Plr=e.Plr})
            end
            for _, e in ipairs(TargetCache.Npcs) do
                table.insert(targets, {Char=e.Obj, Hum=e.Hum, IsPlayer=false})
            end
            local maxDist = Features.AdvancedESP.MaxDistance or 300
            local camPos = Camera.CFrame.Position
            for _, t in ipairs(targets) do
                local hum = t.Hum
                local char = t.Char
                if t.IsPlayer and Features.AdvancedESP.TeamCheck and not Features.AdvancedESP.ShowTeam
                    and t.Plr.Team ~= nil and t.Plr.Team == player.Team then continue end
                local hrp2 = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                local head = char:FindFirstChild("Head")
                if not hrp2 or not head then continue end
                if not inRenderRange(hrp2.Position) then continue end
                local sp, onScreen = worldToScreen(hrp2.Position)
                if not onScreen then continue end
                local dist = (hrp2.Position - camPos).Magnitude
                if maxDist ~= 0 and dist > maxDist then continue end
                if Features.AdvancedESP.WallCheck and isBlockedByWall(hrp2, char) then continue end
                valid[char] = true
                if Features.AdvancedESP.ShowChams then
                    local h = AdvESPHighlights[char]
                    if not h or not h.Parent then
                        h = Instance.new("Highlight")
                        h.Name = "SG_AdvESP"
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillTransparency = 0.7
                        h.OutlineTransparency = 0
                        h.Adornee = char
                        h.Parent = char
                        AdvESPHighlights[char] = h
                    end
                    local c = getGoldColor(char.Name:byte(1) or 1)
                    h.FillColor = c
                    h.OutlineColor = c
                end
                local headSp = worldToScreen(head.Position)
                local height = math.abs(headSp.Y - sp.Y) * 2.2
                local width = height * 0.6
                if Features.AdvancedESP.ShowBox and height >= 5 then
                    local boxX = sp.X - width/2
                    local boxY = sp.Y - height/2
                    local color = getGoldColor(char.Name:byte(1) or 1)
                    local thickness = Features.AdvancedESP.BoxThickness or 1
                    if Features.AdvancedESP.BoxStyle == "Corner" then
                        local cs = width * 0.2
                        drawHLine(Pools.Adv.Lines, RenderFolder, boxX, boxY, cs, color, thickness)
                        drawVLine(Pools.Adv.Lines, RenderFolder, boxX, boxY, cs, color, thickness)
                        drawHLine(Pools.Adv.Lines, RenderFolder, boxX + width - cs, boxY, cs, color, thickness)
                        drawVLine(Pools.Adv.Lines, RenderFolder, boxX + width, boxY, cs, color, thickness)
                        drawHLine(Pools.Adv.Lines, RenderFolder, boxX, boxY + height, cs, color, thickness)
                        drawVLine(Pools.Adv.Lines, RenderFolder, boxX, boxY + height - cs, cs, color, thickness)
                        drawHLine(Pools.Adv.Lines, RenderFolder, boxX + width - cs, boxY + height, cs, color, thickness)
                        drawVLine(Pools.Adv.Lines, RenderFolder, boxX + width, boxY + height - cs, cs, color, thickness)
                    else
                        drawHLine(Pools.Adv.Lines, RenderFolder, boxX, boxY, width, color, thickness)
                        drawHLine(Pools.Adv.Lines, RenderFolder, boxX, boxY + height, width, color, thickness)
                        drawVLine(Pools.Adv.Lines, RenderFolder, boxX, boxY, height, color, thickness)
                        drawVLine(Pools.Adv.Lines, RenderFolder, boxX + width, boxY, height, color, thickness)
                    end
                    if Features.AdvancedESP.ShowHealth and hum and Features.AdvancedESP.HealthStyle ~= "Text" then
                        local barBg = getFromPool(Pools.Adv.Bars, RenderFolder)
                        barBg.Size = UDim2.new(0, 4, 0, height)
                        barBg.Position = UDim2.new(0, boxX - 6, 0, boxY)
                        barBg.BackgroundColor3 = Color3.fromRGB(0,0,0)
                        barBg.BackgroundTransparency = 0.4
                        barBg.Parent = RenderFolder
                        local ratio = hum.Health / hum.MaxHealth
                        local barFill = getFromPool(Pools.Adv.Bars, RenderFolder)
                        barFill.Size = UDim2.new(0, 4, 0, math.max(0, height * ratio))
                        barFill.Position = UDim2.new(0, boxX - 6, 0, boxY + height * (1 - ratio))
                        barFill.BackgroundColor3 = ratio > 0.6 and Color3.fromRGB(0,255,80) or (ratio > 0.3 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,60,60))
                        barFill.Parent = RenderFolder
                    end
                end
                if Features.AdvancedESP.ShowName then
                    local nameL = getFromPool(Pools.Adv.Texts, RenderFolder)
                    nameL.Size = UDim2.new(0, 120, 0, 16)
                    nameL.Position = UDim2.new(0, headSp.X - 60, 0, headSp.Y - 20)
                    nameL.Text = t.IsPlayer and t.Plr.Name or char.Name
                    nameL.TextColor3 = C.Gold
                    nameL.TextSize = 12
                    nameL.Font = Enum.Font.GothamBold
                    nameL.Parent = RenderFolder
                end
                if Features.AdvancedESP.ShowHealth and hum and Features.AdvancedESP.HealthStyle ~= "Bar" then
                    local hpL = getFromPool(Pools.Adv.Texts, RenderFolder)
                    hpL.Size = UDim2.new(0, 120, 0, 14)
                    hpL.Position = UDim2.new(0, headSp.X - 60, 0, headSp.Y - 5)
                    local ratio = hum.Health / hum.MaxHealth
                    hpL.Text = string.format("❤ %.0f/%.0f", hum.Health, hum.MaxHealth)
                    hpL.TextColor3 = ratio > 0.6 and Color3.fromRGB(0,255,100) or (ratio > 0.3 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,60,60))
                    hpL.TextSize = 10
                    hpL.Font = Enum.Font.Gotham
                    hpL.Parent = RenderFolder
                end
                if Features.AdvancedESP.ShowDistance then
                    local dL = getFromPool(Pools.Adv.Texts, RenderFolder)
                    dL.Size = UDim2.new(0, 120, 0, 14)
                    dL.Position = UDim2.new(0, headSp.X - 60, 0, headSp.Y + 10)
                    dL.Text = string.format("%.0fm", dist)
                    dL.TextColor3 = C.TextSub
                    dL.TextSize = 10
                    dL.Font = Enum.Font.Gotham
                    dL.Parent = RenderFolder
                end
                if Features.AdvancedESP.Tracer then
                    draw3DLine(BeamPools.Adv, camPos, hrp2.Position, getGoldColor(char.Name:byte(1) or 1))
                end
                if Features.AdvancedESP.Skeleton then
                    local skeleton = getSkeleton(char)
                    for _, pair in ipairs(skeleton) do
                        local p1 = char:FindFirstChild(pair[1])
                        local p2 = char:FindFirstChild(pair[2])
                        if p1 and p2 then
                            drawBone(BeamPools.Adv, p1, p2, getGoldColor(char.Name:byte(1) + #pair[1]))
                        end
                    end
                end
            end
            for char, h in pairs(AdvESPHighlights) do
                if not valid[char] then
                    pcall(function() h:Destroy() end)
                    AdvESPHighlights[char] = nil
                end
            end
        end)
    else
        unbind("AdvESP")
        clearPool(Pools.Adv.Boxes)
        clearPool(Pools.Adv.Lines)
        clearPool(Pools.Adv.Texts)
        clearPool(Pools.Adv.Bars)
        clearBeams(BeamPools.Adv)
        for char, h in pairs(AdvESPHighlights) do
            pcall(function() h:Destroy() end)
            AdvESPHighlights[char] = nil
        end
    end
end

-- 系统
local FpsCount, FpsLast = 0, tick()
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0, 230, 0, 28)
InfoLabel.Position = UDim2.new(0, 10, 0, 65)
InfoLabel.BackgroundColor3 = Color3.fromRGB(0,0,0)
InfoLabel.BackgroundTransparency = 0.5
InfoLabel.Text = ""
InfoLabel.TextColor3 = C.Gold
InfoLabel.TextSize = 13
InfoLabel.Font = Enum.Font.GothamBold
InfoLabel.Visible = false
InfoLabel.ZIndex = 9350
InfoLabel.Parent = CoreGui

Updaters.ShowFps = function()
    if Features.ShowFps.Enabled then
        InfoLabel.Visible = true
        if Conns.FPS then return end
        Conns.FPS = RunService.Heartbeat:Connect(function()
            FpsCount = FpsCount + 1
            local now = tick()
            if now - FpsLast >= 1 then
                local txt = "FPS: " .. FpsCount
                if Features.ShowCoords.Enabled and hrp then
                    local pos = hrp.Position
                    txt = txt .. string.format(" | %.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
                end
                InfoLabel.Text = txt
                FpsCount = 0; FpsLast = now
            end
        end)
    else
        unbind("FPS")
        if not Features.ShowCoords.Enabled then InfoLabel.Visible = false end
    end
end

Updaters.ShowCoords = function()
    if Features.ShowCoords.Enabled then
        InfoLabel.Visible = true
        if Conns.Coords then return end
        Conns.Coords = RunService.Heartbeat:Connect(function()
            if hrp then
                local pos = hrp.Position
                local txt = string.format("坐标: %.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
                if Features.ShowFps.Enabled then
                    txt = (InfoLabel.Text:match("FPS: %d+") or "FPS: --") .. " | " .. txt
                end
                InfoLabel.Text = txt
            end
        end)
    else
        unbind("Coords")
        if not Features.ShowFps.Enabled then InfoLabel.Visible = false end
    end
end

Updaters.TimeOfDay = function()
    if Features.TimeOfDay.Enabled then
        if Conns.Time then return end
        Conns.Time = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = Features.TimeOfDay.Value
        end)
    else
        unbind("Time")
    end
end

Updaters.SitAnywhere = function()
    if Features.SitAnywhere.Enabled then
        if Conns.Sit then return end
        Conns.Sit = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.X then
                if humanoid then humanoid.Sit = true end
            end
        end)
    else
        unbind("Sit")
    end
end

local WarnLabel = Instance.new("TextLabel")
WarnLabel.Size = UDim2.new(0, 300, 0, 34)
WarnLabel.Position = UDim2.new(0.5, -150, 0.25, -17)
WarnLabel.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
WarnLabel.BackgroundTransparency = 0.3
WarnLabel.Text = ""
WarnLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
WarnLabel.TextSize = 14
WarnLabel.Font = Enum.Font.GothamBold
WarnLabel.Visible = false
WarnLabel.ZIndex = 9360
WarnLabel.Parent = CoreGui

Updaters.DangerWarning = function()
    if Features.DangerWarning.Enabled then
        if Conns.Danger then return end
        local tickCount = 0
        Conns.Danger = RunService.Heartbeat:Connect(function()
            tickCount = tickCount + 1
            if tickCount % 3 ~= 0 then return end
            if not hrp then WarnLabel.Visible = false; return end
            local range = Features.DangerWarning.Value or 50
            local closest, closestDist = nil, math.huge
            updateTargetCache()
            for _, e in ipairs(TargetCache.All) do
                if e.Hrp then
                    local d = (hrp.Position - e.Hrp.Position).Magnitude
                    if d < closestDist then closestDist = d; closest = e end
                end
            end
            if closest and closestDist <= range then
                local name = closest.IsPlayer and closest.Plr.Name or closest.Obj.Name
                WarnLabel.Text = string.format("⚠ %s 接近中! (%.0fm)", name, closestDist)
                WarnLabel.Visible = true
            else
                WarnLabel.Visible = false
            end
        end)
    else
        unbind("Danger")
        WarnLabel.Visible = false
    end
end

-- 灵动岛
Updaters.DynamicIsland = function() end

-- ============================================================
-- 使用 WindUI 的 Section 和 Toggle 构建 UI（不用 Tab）
-- ============================================================
local Window = WindUI:CreateWindow({
    Title = "星光辅助 · 融合版",
    Icon = "star",
    Author = "星光 · 移植 Ninja Hub",
    Folder = "StarAux",
    Size = UDim2.fromOffset(400, 520),
    Transparent = false,
    Theme = "StarGold",
    SideBarWidth = 0,
    HasOutline = true,
})

-- 用下拉菜单切换分类
local categories = {
    "移动",
    "战斗",
    "视觉",
    "工具",
    "人物",
    "系统"
}

local currentCategory = "移动"
local contentContainer = nil

-- 创建分类切换下拉
Window:Section({ Title = "分类导航" })
Window:Dropdown({
    Title = "选择功能分类",
    Values = categories,
    Value = "移动",
    Callback = function(v)
        currentCategory = v
        rebuildContent()
    end
})

-- 创建内容容器（动态刷新）
local function rebuildContent()
    if contentContainer then
        contentContainer:Destroy()
    end
    contentContainer = Window:Section({ Title = currentCategory .. " · 功能列表" })

    if currentCategory == "移动" then
        contentContainer:Toggle({ Title = "加速移动", Value = false, Callback = function(v) Features.WalkSpeed.Enabled = v; Updaters.WalkSpeed() end })
        contentContainer:Slider({ Title = "移动速度", Value = { Min = 1, Max = 500, Default = 100 }, Callback = function(v) Features.WalkSpeed.Value = v end })
        contentContainer:Toggle({ Title = "传送行走", Value = false, Callback = function(v) Features.TpWalk.Enabled = v; Updaters.TpWalk() end })
        contentContainer:Slider({ Title = "传送距离", Value = { Min = 1, Max = 100, Default = 2 }, Callback = function(v) Features.TpWalk.Value = v end })
        contentContainer:Toggle({ Title = "飞行模式 (F键)", Value = false, Callback = function(v) Features.Fly1.Enabled = v; Updaters.Fly1() end })
        contentContainer:Slider({ Title = "飞行速度", Value = { Min = 1, Max = 500, Default = 45 }, Callback = function(v) Features.Fly1.Value = v end })
        contentContainer:Toggle({ Title = "飞行模式2 (WASD+EQ)", Value = false, Callback = function(v) Features.Fly2.Enabled = v; Updaters.Fly2() end })
        contentContainer:Slider({ Title = "飞行速度2", Value = { Min = 1, Max = 500, Default = 50 }, Callback = function(v) Features.Fly2.Value = v end })
        contentContainer:Toggle({ Title = "自由移动", Value = false, Callback = function(v) Features.FreeMove.Enabled = v; Updaters.FreeMove() end })
        contentContainer:Slider({ Title = "自由移动速度", Value = { Min = 1, Max = 500, Default = 50 }, Callback = function(v) Features.FreeMove.Value = v end })
        contentContainer:Toggle({ Title = "穿墙 (NoClip)", Value = false, Callback = function(v) Features.Noclip.Enabled = v; Updaters.Noclip() end })
        contentContainer:Toggle({ Title = "超级连跳", Value = false, Callback = function(v) Features.BunnyHop.Enabled = v; Updaters.BunnyHop() end })
        contentContainer:Slider({ Title = "连跳增量", Value = { Min = 1, Max = 100, Default = 5 }, Callback = function(v) Features.BunnyHop.Value = v end })
        contentContainer:Toggle({ Title = "跳高修改", Value = false, Callback = function(v) Features.JumpHeight.Enabled = v; Updaters.JumpHeight() end })
        contentContainer:Slider({ Title = "跳跃高度", Value = { Min = 1, Max = 500, Default = 100 }, Callback = function(v) Features.JumpHeight.Value = v end })
        contentContainer:Toggle({ Title = "自动奔跑", Value = false, Callback = function(v) Features.AutoRun.Enabled = v; Updaters.AutoRun() end })
        contentContainer:Toggle({ Title = "超级跳跃", Value = false, Callback = function(v) Features.SuperJump.Enabled = v; Updaters.SuperJump() end })
        contentContainer:Slider({ Title = "超级跳跃力度", Value = { Min = 1, Max = 500, Default = 200 }, Callback = function(v) Features.SuperJump.Value = v end })
        contentContainer:Toggle({ Title = "爬墙模式", Value = false, Callback = function(v) Features.WallClimb.Enabled = v; Updaters.WallClimb() end })
        contentContainer:Slider({ Title = "爬墙速度", Value = { Min = 1, Max = 200, Default = 50 }, Callback = function(v) Features.WallClimb.Value = v end })

    elseif currentCategory == "战斗" then
        contentContainer:Toggle({ Title = "无敌模式", Value = false, Callback = function(v) Features.GodMode.Enabled = v; Updaters.GodMode() end })
        contentContainer:Toggle({ Title = "攻击无间隔", Value = false, Callback = function(v) Features.NoCooldown.Enabled = v; Updaters.NoCooldown() end })
        contentContainer:Toggle({ Title = "无限子弹", Value = false, Callback = function(v) Features.InfiniteAmmo.Enabled = v; Updaters.InfiniteAmmo() end })
        contentContainer:Toggle({ Title = "自动攻击", Value = false, Callback = function(v) Features.AutoAttack.Enabled = v; Updaters.AutoAttack() end })
        contentContainer:Toggle({ Title = "杀戮光环", Value = false, Callback = function(v) Features.KillAura.Enabled = v; Updaters.KillAura() end })
        contentContainer:Slider({ Title = "杀戮光环范围", Value = { Min = 1, Max = 100, Default = 20 }, Callback = function(v) Features.KillAura.Value = v end })
        contentContainer:Toggle({ Title = "自动瞄准 (简单)", Value = false, Callback = function(v) Features.Aimbot.Enabled = v; Updaters.Aimbot() end })
        contentContainer:Toggle({ Title = "快速射击", Value = false, Callback = function(v) Features.RapidFire.Enabled = v; Updaters.RapidFire() end })
        contentContainer:Toggle({ Title = "自动开火", Value = false, Callback = function(v) Features.AutoFire.Enabled = v; Updaters.AutoFire() end })

    elseif currentCategory == "视觉" then
        contentContainer:Toggle({ Title = "夜视模式", Value = false, Callback = function(v) Features.NightVision.Enabled = v; Updaters.NightVision() end })
        contentContainer:Toggle({ Title = "全亮模式", Value = false, Callback = function(v) Features.FullBright.Enabled = v; Updaters.FullBright() end })
        contentContainer:Toggle({ Title = "玩家透视 (ESP)", Value = false, Callback = function(v) Features.ESP.Enabled = v; Updaters.ESP() end })
        contentContainer:Toggle({ Title = "地图透视 (X光)", Value = false, Callback = function(v) Features.Xray.Enabled = v; Updaters.Xray() end })
        contentContainer:Toggle({ Title = "清除迷雾", Value = false, Callback = function(v) Features.NoFog.Enabled = v; Updaters.NoFog() end })
        contentContainer:Toggle({ Title = "颜色滤镜", Value = false, Callback = function(v) Features.ColorFilter.Enabled = v; Updaters.ColorFilter() end })
        contentContainer:Dropdown({ Title = "滤镜颜色", Values = {"Red","Blue","Green","Pink","Yellow","Cyan"}, Value = "Pink", Callback = function(v) Features.ColorFilter.Value = v end })
        contentContainer:Toggle({ Title = "自由视角", Value = false, Callback = function(v) Features.FreeCam.Enabled = v; Updaters.FreeCam() end })
        contentContainer:Toggle({ Title = "热能透视", Value = false, Callback = function(v) Features.ThermalESP.Enabled = v; Updaters.ThermalESP() end })

    elseif currentCategory == "工具" then
        contentContainer:Toggle({ Title = "🎵 音乐播放器", Value = false, Callback = function(v)
            Features.MusicPlayer.Enabled = v
            Updaters.MusicPlayer()
            if v then WindUI:Notify({Title = "🎵 音乐播放器", Content = "已开启，点击右侧金色悬浮窗", Duration = 3}) end
        end })
        contentContainer:Toggle({ Title = "连点器", Value = false, Callback = function(v) Features.AutoClicker.Enabled = v; Updaters.AutoClicker() end })
        contentContainer:Slider({ Title = "连点间隔 (ms)", Value = { Min = 1, Max = 5000, Default = 10 }, Callback = function(v) Features.AutoClicker.Value = v end })
        contentContainer:Toggle({ Title = "连点启动", Value = false, Callback = function(v) Features.ClickerStart.Enabled = v; Updaters.ClickerStart() end })
        contentContainer:Toggle({ Title = "多球模式", Value = false, Callback = function(v) Features.ClickerMulti.Enabled = v; Updaters.ClickerMulti() end })
        contentContainer:Toggle({ Title = "快速交互", Value = false, Callback = function(v) Features.FastInteract.Enabled = v; Updaters.FastInteract() end })
        contentContainer:Toggle({ Title = "自动保存配置", Value = false, Callback = function(v) Features.AutoSave.Enabled = v; Updaters.AutoSave() end })
        contentContainer:Toggle({ Title = "反AFK", Value = false, Callback = function(v) Features.AntiAfk.Enabled = v; Updaters.AntiAfk() end })

    elseif currentCategory == "人物" then
        contentContainer:Toggle({ Title = "启用 NPC 显示", Value = false, Callback = function(v) Features.NpcDisplay.Enabled = v; Updaters.NpcDisplay() end })
        contentContainer:Toggle({ Title = "NPC:头部", Value = true, Callback = function(v) Features.NpcDisplay.ShowHead = v end })
        contentContainer:Toggle({ Title = "NPC:身体", Value = true, Callback = function(v) Features.NpcDisplay.ShowTorso = v end })
        contentContainer:Toggle({ Title = "NPC:四肢", Value = true, Callback = function(v) Features.NpcDisplay.ShowLimbs = v end })
        contentContainer:Toggle({ Title = "NPC:骨骼", Value = true, Callback = function(v) Features.NpcDisplay.ShowBones = v end })
        contentContainer:Toggle({ Title = "启用玩家显示", Value = false, Callback = function(v) Features.PlayerDisplay.Enabled = v; Updaters.PlayerDisplay() end })
        contentContainer:Toggle({ Title = "玩家:头部", Value = true, Callback = function(v) Features.PlayerDisplay.ShowHead = v end })
        contentContainer:Toggle({ Title = "玩家:身体", Value = true, Callback = function(v) Features.PlayerDisplay.ShowTorso = v end })
        contentContainer:Toggle({ Title = "玩家:四肢", Value = true, Callback = function(v) Features.PlayerDisplay.ShowLimbs = v end })
        contentContainer:Toggle({ Title = "玩家:骨骼", Value = true, Callback = function(v) Features.PlayerDisplay.ShowBones = v end })
        contentContainer:Toggle({ Title = "玩家:名字", Value = true, Callback = function(v) Features.PlayerDisplay.ShowName = v end })
        contentContainer:Toggle({ Title = "玩家:距离", Value = true, Callback = function(v) Features.PlayerDisplay.ShowDistance = v end })
        contentContainer:Toggle({ Title = "玩家:血量", Value = true, Callback = function(v) Features.PlayerDisplay.ShowHealth = v end })
        contentContainer:Toggle({ Title = "启用框选", Value = false, Callback = function(v) Features.BoxCreature.Enabled = v; Updaters.BoxCreature() end })
        contentContainer:Toggle({ Title = "框选NPC", Value = true, Callback = function(v) Features.BoxCreature.BoxNpc = v end })
        contentContainer:Toggle({ Title = "框选玩家", Value = true, Callback = function(v) Features.BoxCreature.BoxPlayer = v end })
        contentContainer:Toggle({ Title = "显示碰撞箱", Value = false, Callback = function(v) Features.BoxCreature.ShowHitbox = v end })
        contentContainer:Dropdown({ Title = "框选模式", Values = {"3D","2D"}, Value = "3D", Callback = function(v) Features.BoxCreature.BoxMode = v end })
        contentContainer:Slider({ Title = "框选最大距离", Value = { Min = 0, Max = 5000, Default = 0 }, Callback = function(v) Features.BoxCreature.MaxDistance = v end })
        contentContainer:Toggle({ Title = "启用连线", Value = false, Callback = function(v) Features.LineConnect.Enabled = v; Updaters.LineConnect() end })
        contentContainer:Toggle({ Title = "连接玩家", Value = true, Callback = function(v) Features.LineConnect.ConnectPlayer = v end })
        contentContainer:Toggle({ Title = "连接NPC", Value = false, Callback = function(v) Features.LineConnect.ConnectNpc = v end })
        contentContainer:Dropdown({ Title = "线起点", Values = {"Top","Bottom","Cross"}, Value = "Top", Callback = function(v) Features.LineConnect.Origin = v end })
        contentContainer:Toggle({ Title = "启用智能自瞄", Value = false, Callback = function(v) Features.AimbotV2.Enabled = v; Updaters.AimbotV2() end })
        contentContainer:Toggle({ Title = "自瞄玩家", Value = true, Callback = function(v) Features.AimbotV2.AimPlayer = v end })
        contentContainer:Toggle({ Title = "自瞄NPC", Value = false, Callback = function(v) Features.AimbotV2.AimNpc = v end })
        contentContainer:Toggle({ Title = "检测墙体", Value = false, Callback = function(v) Features.AimbotV2.WallCheck = v end })
        contentContainer:Toggle({ Title = "平滑瞄准", Value = true, Callback = function(v) Features.AimbotV2.Smooth = v end })
        contentContainer:Dropdown({ Title = "瞄准部位", Values = {"Head","HumanoidRootPart","Torso"}, Value = "Head", Callback = function(v) Features.AimbotV2.AimPart = v end })
        contentContainer:Slider({ Title = "圆圈大小", Value = { Min = 50, Max = 500, Default = 150 }, Callback = function(v) Features.AimbotV2.CircleSize = v end })
        contentContainer:Slider({ Title = "瞄准速度", Value = { Min = 0.02, Max = 0.9, Default = 0.3 }, Callback = function(v) Features.AimbotV2.AimSpeed = v end })
        contentContainer:Toggle({ Title = "启用高级透视", Value = false, Callback = function(v) Features.AdvancedESP.Enabled = v; Updaters.AdvancedESP() end })
        contentContainer:Toggle({ Title = "显示方框", Value = true, Callback = function(v) Features.AdvancedESP.ShowBox = v end })
        contentContainer:Toggle({ Title = "显示名字", Value = true, Callback = function(v) Features.AdvancedESP.ShowName = v end })
        contentContainer:Toggle({ Title = "显示血量", Value = true, Callback = function(v) Features.AdvancedESP.ShowHealth = v end })
        contentContainer:Toggle({ Title = "显示距离", Value = true, Callback = function(v) Features.AdvancedESP.ShowDistance = v end })
        contentContainer:Toggle({ Title = "骨骼线", Value = false, Callback = function(v) Features.AdvancedESP.Skeleton = v end })
        contentContainer:Toggle({ Title = "追踪线", Value = false, Callback = function(v) Features.AdvancedESP.Tracer = v end })
        contentContainer:Toggle({ Title = "上色渲染", Value = true, Callback = function(v) Features.AdvancedESP.ShowChams = v end })
        contentContainer:Dropdown({ Title = "方框样式", Values = {"Corner","Full"}, Value = "Corner", Callback = function(v) Features.AdvancedESP.BoxStyle = v end })
        contentContainer:Dropdown({ Title = "血条样式", Values = {"Bar","Text","Both"}, Value = "Bar", Callback = function(v) Features.AdvancedESP.HealthStyle = v end })

    elseif currentCategory == "系统" then
        contentContainer:Toggle({ Title = "显示 FPS", Value = false, Callback = function(v) Features.ShowFps.Enabled = v; Updaters.ShowFps() end })
        contentContainer:Toggle({ Title = "显示坐标", Value = false, Callback = function(v) Features.ShowCoords.Enabled = v; Updaters.ShowCoords() end })
        contentContainer:Toggle({ Title = "重力修改", Value = false, Callback = function(v) Features.GravityMod.Enabled = v; Updaters.GravityMod() end })
        contentContainer:Slider({ Title = "重力值", Value = { Min = 0, Max = 1000, Default = 50 }, Callback = function(v) Features.GravityMod.Value = v end })
        contentContainer:Toggle({ Title = "时间修改", Value = false, Callback = function(v) Features.TimeOfDay.Enabled = v; Updaters.TimeOfDay() end })
        contentContainer:Slider({ Title = "时间 (小时)", Value = { Min = 0, Max = 24, Default = 12 }, Callback = function(v) Features.TimeOfDay.Value = v end })
        contentContainer:Toggle({ Title = "随处坐下 (按 X)", Value = false, Callback = function(v) Features.SitAnywhere.Enabled = v; Updaters.SitAnywhere() end })
        contentContainer:Toggle({ Title = "危险警告", Value = false, Callback = function(v) Features.DangerWarning.Enabled = v; Updaters.DangerWarning() end })
        contentContainer:Slider({ Title = "警告距离", Value = { Min = 1, Max = 500, Default = 50 }, Callback = function(v) Features.DangerWarning.Value = v end })
    end
end

-- 首次构建
rebuildContent()

-- ============================================================
-- 快捷键
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        if not UserInputService:GetFocusedTextBox() then
            Features.Fly1.Enabled = not Features.Fly1.Enabled
            Updaters.Fly1()
            WindUI:Notify({Title = "飞行", Content = Features.Fly1.Enabled and "✈ 已开启" or "✈ 已关闭", Duration = 2})
        end
    end
end)

-- ============================================================
-- 启动
-- ============================================================
local elapsed = tick() - LoadStartTime

buildMusicPanel()

for key, state in pairs(Features) do
    if type(state) == "table" and state.Enabled and Updaters[key] then
        pcall(Updaters[key])
    end
end

Window:Open()
WindUI:Notify({
    Title = "✨ 星光辅助 V2.1",
    Content = string.format("加载 %.2fs | 下拉菜单切换分类 | F键飞行", elapsed),
    Duration = 5,
    Icon = "star"
})

print(string.format("[星光辅助] 加载完成 | 耗时 %.2fs", elapsed))

-- ============================================================
-- 清理
-- ============================================================
local function cleanup()
    for name in pairs(Conns) do unbind(name) end
    clearRenderCache()
    if FreeMoveBG then pcall(function() FreeMoveBG:Destroy() end) end
    if FreeMoveBV then pcall(function() FreeMoveBV:Destroy() end) end
    print("星光辅助已清理")
end

Players.PlayerRemoving:Connect(function(p)
    if p == LocalPlayer then cleanup() end
end)
