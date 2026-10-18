
-- SPIRING AURA V3
-- LocalScript: StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui")

local alive = true
local state = {
    Camlock = false,
    TeamCheck = true,
    ESP = false,
    Fly = false,
    Noclip = false,
}

local links = {}
local highlights = {}
local labels = {}
local targetHead
local flightAttachment, flightVelocity, flightOrientation
local oldAutoRotate
local oldCollisions = {}
local noclipConnection
local flightSpeed = 55

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(links, c)
    return c
end

local function getCharacter(p)
    return p.Character
end

local function isFriendly(p)
    return state.TeamCheck
        and player.Team ~= nil
        and p.Team == player.Team
end

local function valid(p)
    if p == player or isFriendly(p) then return false end
    local char = getCharacter(p)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local head = char and char:FindFirstChild("Head")
    return hum ~= nil and hum.Health > 0 and head ~= nil
end

local function nearestHead()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if valid(p) then
            local head = p.Character:FindFirstChild("Head")
            local d = (head.Position - root.Position).Magnitude
            if d < bestDist then
                best, bestDist = head, d
            end
        end
    end
    return best
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SpiringAuraV3"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = guiParent

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(350, 410)
main.Position = UDim2.new(0.5, -175, 0.5, -205)
main.BackgroundColor3 = Color3.fromRGB(16, 14, 21)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local border = Instance.new("UIStroke", main)
border.Color = Color3.fromRGB(218, 48, 91)
border.Thickness = 1.5

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 78)
header.BackgroundColor3 = Color3.fromRGB(43, 18, 32)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local heading = Instance.new("TextLabel")
heading.Position = UDim2.fromOffset(18, 12)
heading.Size = UDim2.new(1, -30, 0, 28)
heading.BackgroundTransparency = 1
heading.Text = "SPIRING AURA"
heading.Font = Enum.Font.GothamBlack
heading.TextSize = 22
heading.TextXAlignment = Enum.TextXAlignment.Left
heading.TextColor3 = Color3.fromRGB(255, 83, 125)
heading.Parent = header

local sub = Instance.new("TextLabel")
sub.Position = UDim2.fromOffset(19, 43)
sub.Size = UDim2.new(1, -30, 0, 18)
sub.BackgroundTransparency = 1
sub.Text = "A U R A   C O N T R O L   /   V 3"
sub.Font = Enum.Font.Code
sub.TextSize = 10
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.TextColor3 = Color3.fromRGB(183, 153, 170)
sub.Parent = header

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(18, 88)
status.Size = UDim2.new(1, -36, 0, 27)
status.BackgroundColor3 = Color3.fromRGB(30, 27, 37)
status.Text = "●  READY"
status.Font = Enum.Font.Code
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(120, 238, 173)
status.Parent = main
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 7)

local function setStatus(s)
    if status.Parent then status.Text = "●  " .. s end
end

local function makeButton(text, y, key, callback)
    local b = Instance.new("TextButton")
    b.Position = UDim2.fromOffset(18, y)
    b.Size = UDim2.new(1, -36, 0, 42)
    b.BackgroundColor3 = Color3.fromRGB(31, 27, 38)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(238, 228, 238)
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

    local edge = Instance.new("UIStroke", b)
    edge.Color = Color3.fromRGB(70, 52, 73)

    local function refresh()
        b.Text = text .. (state[key] and "     [ON]" or "     [OFF]")
        b.BackgroundColor3 = state[key]
            and Color3.fromRGB(72, 24, 46)
            or Color3.fromRGB(31, 27, 38)
        edge.Color = state[key]
            and Color3.fromRGB(240, 58, 105)
            or Color3.fromRGB(70, 52, 73)
    end

    refresh()

    connect(b.Activated, function()
        if not alive then return end
        state[key] = not state[key]
        refresh()
        callback(state[key])
    end)

    return refresh
end

-- ESP
local function clearESP(p)
    if highlights[p] then highlights[p]:Destroy() end
    if labels[p] then labels[p]:Destroy() end
    highlights[p], labels[p] = nil, nil
end

local function updateESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if not state.ESP or not valid(p) then
            clearESP(p)
        else
            local char = p.Character
            local head = char and char:FindFirstChild("Head")

            if char and head then
                if not highlights[p] or highlights[p].Adornee ~= char then
                    clearESP(p)

                    local h = Instance.new("Highlight")
                    h.Name = "AuraHighlight"
                    h.Adornee = char
                    h.FillColor = Color3.fromRGB(223, 37, 83)
                    h.OutlineColor = Color3.fromRGB(255, 142, 174)
                    h.FillTransparency = 0.72
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = gui
                    highlights[p] = h

                    local tag = Instance.new("BillboardGui")
                    tag.Name = "AuraNameTag"
                    tag.Adornee = head
                    tag.Size = UDim2.fromOffset(200, 30)
                    tag.StudsOffset = Vector3.new(0, 2.4, 0)
                    tag.AlwaysOnTop = true
                    tag.Parent = gui

                    local txt = Instance.new("TextLabel")
                    txt.Size = UDim2.fromScale(1, 1)
                    txt.BackgroundTransparency = 1
                    txt.Text = p.DisplayName .. "  @" .. p.Name
                    txt.TextColor3 = Color3.fromRGB(255, 125, 160)
                    txt.TextStrokeTransparency = 0.3
                    txt.Font = Enum.Font.GothamBold
                    txt.TextSize = 12
                    txt.Parent = tag
                    labels[p] = tag
                elseif labels[p] then
                    labels[p].Adornee = head
                end
            end
        end
    end
end

-- Flight
local function stopFlight()
    state.Fly = false

    if flightVelocity then flightVelocity:Destroy() end
    if flightOrientation then flightOrientation:Destroy() end
    if flightAttachment then flightAttachment:Destroy() end
    flightVelocity, flightOrientation, flightAttachment = nil, nil, nil

    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and oldAutoRotate ~= nil then hum.AutoRotate = oldAutoRotate end
    oldAutoRotate = nil
end

local function startFlight()
    stopFlight()

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    if not root or not hum then
        setStatus("WAIT FOR CHARACTER")
        return
    end

    state.Fly = true
    oldAutoRotate = hum.AutoRotate
    hum.AutoRotate = false

    flightAttachment = Instance.new("Attachment")
    flightAttachment.Parent = root

    flightVelocity = Instance.new("LinearVelocity")
    flightVelocity.Attachment0 = flightAttachment
    flightVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flightVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flightVelocity.MaxForce = 1000000
    flightVelocity.VectorVelocity = Vector3.zero
    flightVelocity.Parent = root

    flightOrientation = Instance.new("AlignOrientation")
    flightOrientation.Attachment0 = flightAttachment
    flightOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flightOrientation.MaxTorque = 1000000
    flightOrientation.Responsiveness = 20
    flightOrientation.Parent = root

    setStatus("FLIGHT ON  ·  WASD / SPACE / CTRL")
end

-- Noclip; restores the original collision settings when disabled.
local function setNoclip(on)
    state.Noclip = on

    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if on then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = player.Character
            if not char then return end

            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if oldCollisions[part] == nil then
                        oldCollisions[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)
    else
        for part, original in pairs(oldCollisions) do
            if part and part.Parent then part.CanCollide = original end
        end
        table.clear(oldCollisions)
    end
end

local refreshCam = makeButton("◎   HEAD CAMLOCK", 128, "Camlock", function(on)
    targetHead = on and nearestHead() or nil
    setStatus(on and (targetHead and "TARGET LOCKED" or "NO TARGET FOUND")
        or "CAMLOCK OFF")
end)

local refreshTeam = makeButton("◇   TEAM CHECK", 178, "TeamCheck", function()
    targetHead = state.Camlock and nearestHead() or nil
    updateESP()
    setStatus(state.TeamCheck and "TEAM FILTER ON" or "TEAM FILTER OFF")
end)

local refreshESP = makeButton("▣   PLAYER ESP", 228, "ESP", function(on)
    updateESP()
    setStatus(on and "ESP ENABLED" or "ESP DISABLED")
end)

local refreshFly = makeButton("✦   FLIGHT  [F]", 278, "Fly", function(on)
    if on then
        startFlight()
    else
        stopFlight()
        setStatus("FLIGHT OFF")
    end
end)

local refreshNoclip = makeButton("◇   NOCLIP  [N]", 328, "Noclip", function(on)
    setNoclip(on)
    setStatus(on and "NOCLIP ON" or "NOCLIP OFF")
end)

local unload = Instance.new("TextButton")
unload.Position = UDim2.fromOffset(18, 378)
unload.Size = UDim2.new(1, -36, 0, 25)
unload.BackgroundColor3 = Color3.fromRGB(104, 25, 49)
unload.Text = "UNLOAD"
unload.Font = Enum.Font.GothamBold
unload.TextSize = 11
unload.TextColor3 = Color3.new(1, 1, 1)
unload.Parent = main
Instance.new("UICorner", unload).CornerRadius = UDim.new(0, 7)

-- Camera lock runs after Roblox's normal camera update.
pcall(function()
    RunService:UnbindFromRenderStep("SpiringAuraCamera")
end)

RunService:BindToRenderStep(
    "SpiringAuraCamera",
    Enum.RenderPriority.Camera.Value + 1,
    function()
        if not alive then return end

        if state.Camlock then
            if not targetHead or not targetHead.Parent then
                targetHead = nearestHead()
            end

            local cam = workspace.CurrentCamera
            if cam and targetHead and targetHead.Parent then
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetHead.Position)
            end
        end

        if state.Fly and flightVelocity and flightOrientation then
            local cam = workspace.CurrentCamera
            if cam then
                local direction = Vector3.zero

                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    direction += cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    direction -= cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    direction += cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    direction -= cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    direction += Vector3.yAxis
                end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    direction -= Vector3.yAxis
                end

                if direction.Magnitude > 0 then
                    direction = direction.Unit
                end

                flightVelocity.VectorVelocity = direction * flightSpeed

                local look = cam.CFrame.LookVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                if flatLook.Magnitude > 0.001 then
                    flightOrientation.CFrame = CFrame.lookAt(
                        Vector3.zero, flatLook.Unit
                    )
                end
            end
        end
    end
)

-- Keyboard shortcuts
connect(UIS.InputBegan, function(input, processed)
    if processed or not alive then return end

    if input.KeyCode == Enum.KeyCode.C then
        state.Camlock = not state.Camlock
        targetHead = state.Camlock and nearestHead() or nil
        refreshCam()
        setStatus(state.Camlock and "CAMLOCK ON" or "CAMLOCK OFF")

    elseif input.KeyCode == Enum.KeyCode.F then
        state.Fly = not state.Fly
        if state.Fly then startFlight() else stopFlight() end
        refreshFly()

    elseif input.KeyCode == Enum.KeyCode.N then
        setNoclip(not state.Noclip)
        refreshNoclip()
    end
end)

-- Keep ESP updated when players respawn or teams change.
local espTimer = 0
connect(RunService.Heartbeat, function(dt)
    espTimer += dt
    if espTimer >= 0.5 then
        espTimer = 0
        if alive and state.ESP then updateESP() end
    end
end)

connect(Players.PlayerRemoving, function(p)
    clearESP(p)
    if targetHead and player.Character ~= nil then
        if p.Character and targetHead:IsDescendantOf(p.Character) then
            targetHead = nil
        end
    end
end)

-- Draggable header
local dragging = false
local dragStart, startPos

connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

connect(unload.Activated, function()
    if not alive then return end
    alive = false

    pcall(function()
        RunService:UnbindFromRenderStep("SpiringAuraCamera")
    end)

    stopFlight()
    setNoclip(false)

    for _, c in ipairs(links) do
        if c.Connected then c:Disconnect() end
    end
    if noclipConnection then noclipConnection:Disconnect() end

    for p in pairs(highlights) do clearESP(p) end
    gui:Destroy()
end)

print("SPIRING AURA V3 loaded")
