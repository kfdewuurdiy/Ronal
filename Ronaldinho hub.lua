local player = game:GetService("Players").LocalPlayer
local guiName = "MiniDreyGui"
local superJumpPower = 100
local boostSpeed = 35
local boostTime = 1.2
local invisTime = 1.6

local espEnabled = false
local espObjects = {}

local platformActive = false
local platformPart = nil

-- Marcação
local markedPosition = nil
local markActive = false
local markPart = nil

-- ESP
local function createESPForPlayer(target)
    if target == player or espObjects[target] then return end
    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = "ESP"
    Billboard.Size = UDim2.new(0, 200, 0, 30)
    Billboard.AlwaysOnTop = true
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.Parent = workspace

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, 0, 1, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = target.Name
    NameLabel.TextColor3 = Color3.new(1, 0.6, 0)
    NameLabel.TextStrokeTransparency = 0
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 18
    NameLabel.Parent = Billboard

    espObjects[target] = Billboard

    local function update()
        if espEnabled and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            Billboard.Adornee = target.Character.HumanoidRootPart
            Billboard.Enabled = true
        else
            Billboard.Enabled = false
        end
    end

    target.CharacterAdded:Connect(update)
    game:GetService("RunService").RenderStepped:Connect(update)
    target.AncestryChanged:Connect(function()
        if not target:IsDescendantOf(game:GetService("Players")) then
            Billboard:Destroy()
            espObjects[target] = nil
        end
    end)
end

local function setupESP()
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        createESPForPlayer(p)
    end
    game:GetService("Players").PlayerAdded:Connect(createESPForPlayer)
end

setupESP()

local function updateESPState()
    for target, gui in pairs(espObjects) do
        if espEnabled and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            gui.Adornee = target.Character.HumanoidRootPart
            gui.Enabled = true
        else
            gui.Enabled = false
        end
    end
end

-- Super Pulo Humano
local function humanSuperJump()
    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        local originalJumpPower = humanoid.JumpPower
        humanoid.JumpPower = superJumpPower
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        wait(math.random(0.28,0.52))
        humanoid.JumpPower = originalJumpPower
    end
end

-- Boost de Velocidade (mola)
local function speedBoost()
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = boostSpeed
        local running = true
        local t = 0
        local heartbeatConn
        heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
            if running and humanoid.WalkSpeed ~= boostSpeed then
                humanoid.WalkSpeed = boostSpeed
            end
        end)
        while t < boostTime do
            t = t + wait(0.05)
        end
        running = false
        if heartbeatConn then heartbeatConn:Disconnect() end
        humanoid.WalkSpeed = originalSpeed
    end
end

-- Invisibilidade temporária com contador
local invisRunning = false
local function tempInvis(btn)
    if invisRunning or not player.Character then return end
    invisRunning = true
    local char = player.Character

    -- Salva transparências
    local transpTable = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            transpTable[part] = part.Transparency
            part.Transparency = 1
            if part:FindFirstChild("face") then
                part.face.Transparency = 1
            end
        end
        if part:IsA("Decal") then
            transpTable[part] = part.Transparency
            part.Transparency = 1
        end
    end

    -- Oculta o nome
    local head = char:FindFirstChild("Head")
    if head then
        for _, v in pairs(head:GetChildren()) do
            if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
                v.Enabled = false
            end
        end
    end

    -- Contador visual no botão
    local t = invisTime
    while t > 0 do
        btn.Text = string.format("%.1f Second", t)
        t = t - 0.1
        wait(0.1)
    end
    btn.Text = "Ficar Invisível Temporário"

    -- Restaura transparências
    for obj, transp in pairs(transpTable) do
        if obj and obj.Parent then
            obj.Transparency = transp
        end
    end

    -- Restaura o nome
    if head then
        for _, v in pairs(head:GetChildren()) do
            if v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
                v.Enabled = true
            end
        end
    end

    invisRunning = false
end

-- Plataforma Verde (com ajuste do Brainrot/CanCollide)
local function startPlatform()
    if platformActive or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    platformActive = true
    local root = player.Character.HumanoidRootPart

    platformPart = Instance.new("Part")
    platformPart.Size = Vector3.new(5, 0.5, 5)
    platformPart.Anchored = true
    platformPart.CanCollide = true
    platformPart.Color = Color3.fromRGB(0,255,0)
    platformPart.Material = Enum.Material.Neon
    platformPart.Parent = workspace

    local height = root.Position.Y - 3
    while platformActive do
        -- Detecta se está segurando o Brainrot
        local holdingBrainrot = false
        for _, item in pairs(player.Character:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("brainrot")) then
                holdingBrainrot = true
            end
        end
        platformPart.CanCollide = not holdingBrainrot
        height = height + 0.25
        platformPart.Position = Vector3.new(root.Position.X, height, root.Position.Z)
        wait(0.03)
    end
    if platformPart then
        platformPart:Destroy()
        platformPart = nil
    end
end

local function stopPlatform()
    platformActive = false
end

-- ENTRAR DEBAIXO DA TERRA (SÓ COM BRAINROT NA MÃO)
local camera = workspace.CurrentCamera
local offsetY = 16      -- Altura da câmera acima do personagem
local underGroundY = -10 -- Quanto o personagem vai para baixo

local function isBrainrotEquipped()
    local char = player.Character
    if not char then return false end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("brainrot") then
            return true
        end
    end
    return false
end

local function enterUnderground()
    if not isBrainrotEquipped() then
        warn("Você precisa estar com o Brainrot equipado!")
        return
    end

    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart

    -- Move personagem para debaixo da terra
    root.CFrame = root.CFrame + Vector3.new(0, underGroundY, 0)

    -- Câmera fica em cima do personagem
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = root.CFrame + Vector3.new(0, offsetY, 0)

    local running = true
    local conn = game:GetService("RunService").RenderStepped:Connect(function()
        if running and root and camera then
            camera.CFrame = root.CFrame + Vector3.new(0, offsetY, 0)
        end
    end)

    -- Sai do modo terra após 4 segundos
    local function exitUnderground()
        running = false
        if conn then conn:Disconnect() end
        camera.CameraType = Enum.CameraType.Custom
    end

    delay(4, exitUnderground)
end

-- MARCAÇÃO: clique para marcar e levitar até o ponto
local function markLocation()
    markActive = not markActive
    if markActive then
        markedPosition = nil
        if markPart then markPart:Destroy() end
        markPart = nil
        -- Espera o próximo clique
        local mouse = player:GetMouse()
        mouse.Button1Down:Connect(function()
            if markActive then
                local hit = mouse.Hit
                markedPosition = hit.Position
                -- Cria uma bola visual no ponto marcado
                if markPart then markPart:Destroy() end
                markPart = Instance.new("Part")
                markPart.Shape = Enum.PartType.Ball
                markPart.Size = Vector3.new(2,2,2)
                markPart.Anchored = true
                markPart.CanCollide = false
                markPart.Material = Enum.Material.Neon
                markPart.Color = Color3.fromRGB(255, 255, 0)
                markPart.Position = markedPosition
                markPart.Parent = workspace
            end
        end)
    else
        -- Se desativar e existir marca, levita até lá
        if markedPosition and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local startPos = root.Position
            local endPos = markedPosition
            local steps = 100
            for i = 1, steps do
                local alpha = i/steps
                local newPos = startPos:Lerp(endPos + Vector3.new(0,3,0), alpha)
                root.CFrame = CFrame.new(newPos)
                wait(0.01)
            end
            -- Remove marca visual
            if markPart then markPart:Destroy() end
            markPart = nil
            markedPosition = nil
        end
    end
end

-- GUI
local function createGui()
    local oldGui = player.PlayerGui:FindFirstChild(guiName)
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player:WaitForChild("PlayerGui")

    local Frame = Instance.new("Frame")
    Frame.Parent = ScreenGui
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    Frame.Size = UDim2.new(0, 350, 0, 370)
    Frame.Position = UDim2.new(0.5, -175, 0.5, -185)
    Frame.Active = true
    Frame.Draggable = true

    local Title = Instance.new("TextLabel")
    Title.Parent = Frame
    Title.Text = "Kaio Universal GUI"
    Title.Size = UDim2.new(1, -60, 0, 30)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(220, 220, 220)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20

    local MinButton = Instance.new("TextButton")
    MinButton.Parent = Frame
    MinButton.Text = "_"
    MinButton.Size = UDim2.new(0, 30, 0, 30)
    MinButton.Position = UDim2.new(1, -60, 0, 0)
    MinButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    MinButton.TextColor3 = Color3.fromRGB(255,255,255)
    MinButton.Font = Enum.Font.GothamBold
    MinButton.TextSize = 18

    local CloseButton = Instance.new("TextButton")
    CloseButton.Parent = Frame
    CloseButton.Text = "X"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
    CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 18

    local ButtonArea = Instance.new("Frame")
    ButtonArea.Parent = Frame
    ButtonArea.Size = UDim2.new(1, -20, 1, -50)
    ButtonArea.Position = UDim2.new(0, 10, 0, 40)
    ButtonArea.BackgroundTransparency = 1

    -- BOOST DE VELOCIDADE (mola)
    local BoostButton = Instance.new("TextButton")
    BoostButton.Parent = ButtonArea
    BoostButton.Size = UDim2.new(0, 230, 0, 30)
    BoostButton.Position = UDim2.new(0, 0, 0, 0)
    BoostButton.Text = "Boost de Velocidade (Mola)"
    BoostButton.Font = Enum.Font.GothamBold
    BoostButton.TextSize = 15

    BoostButton.MouseButton1Click:Connect(function()
        BoostButton.Text = "Boost Ativo!"
        speedBoost()
        BoostButton.Text = "Boost de Velocidade (Mola)"
    end)

    -- Invisibilidade temporária com contador
    local InvisButton = Instance.new("TextButton")
    InvisButton.Parent = ButtonArea
    InvisButton.Size = UDim2.new(0, 230, 0, 30)
    InvisButton.Position = UDim2.new(0, 0, 0, 40)
    InvisButton.Text = "Ficar Invisível Temporário"
    InvisButton.Font = Enum.Font.GothamBold
    InvisButton.TextSize = 15

    InvisButton.MouseButton1Click:Connect(function()
        tempInvis(InvisButton)
    end)

    -- Super Pulo Humano
    local SuperJumpButton = Instance.new("TextButton")
    SuperJumpButton.Parent = ButtonArea
    SuperJumpButton.Size = UDim2.new(0, 230, 0, 30)
    SuperJumpButton.Position = UDim2.new(0, 0, 0, 80)
    SuperJumpButton.Text = "Super Pulo Humano"
    SuperJumpButton.Font = Enum.Font.GothamBold
    SuperJumpButton.TextSize = 15
    SuperJumpButton.MouseButton1Click:Connect(humanSuperJump)

    -- Plataforma Verde
    local PlatformButton = Instance.new("TextButton")
    PlatformButton.Parent = ButtonArea
    PlatformButton.Size = UDim2.new(0, 230, 0, 30)
    PlatformButton.Position = UDim2.new(0, 0, 0, 120)
    PlatformButton.Text = "Segure para Plataforma Verde"
    PlatformButton.Font = Enum.Font.GothamBold
    PlatformButton.TextSize = 15
    PlatformButton.MouseButton1Down:Connect(startPlatform)
    PlatformButton.MouseButton1Up:Connect(stopPlatform)
    PlatformButton.MouseLeave:Connect(stopPlatform)

    -- ESP Toggle
    local ESPButton = Instance.new("TextButton")
    ESPButton.Parent = ButtonArea
    ESPButton.Size = UDim2.new(0, 230, 0, 30)
    ESPButton.Position = UDim2.new(0, 0, 0, 160)
    ESPButton.Text = "Ativar ESP"
    ESPButton.Font = Enum.Font.GothamBold
    ESPButton.TextSize = 15

    ESPButton.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        ESPButton.Text = espEnabled and "Desativar ESP" or "Ativar ESP"
        updateESPState()
    end)

    -- ENTRAR DEBAIXO DA TERRA
    local UndergroundButton = Instance.new("TextButton")
    UndergroundButton.Parent = ButtonArea
    UndergroundButton.Size = UDim2.new(0, 230, 0, 30)
    UndergroundButton.Position = UDim2.new(0, 0, 0, 200)
    UndergroundButton.Text = "Entrar Debaixo da Terra (Brainrot)"
    UndergroundButton.Font = Enum.Font.GothamBold
    UndergroundButton.TextSize = 15

    UndergroundButton.MouseButton1Click:Connect(function()
        enterUnderground()
    end)

    -- MARCAÇÃO
    local MarkButton = Instance.new("TextButton")
    MarkButton.Parent = ButtonArea
    MarkButton.Size = UDim2.new(0, 230, 0, 30)
    MarkButton.Position = UDim2.new(0, 0, 0, 240)
    MarkButton.Text = "Marcação: Ativar/Ir"
    MarkButton.Font = Enum.Font.GothamBold
    MarkButton.TextSize = 15

    MarkButton.MouseButton1Click:Connect(function()
        markLocation()
    end)

    -- Minimizar/Maximizar
    local minimized = false
    MinButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        ButtonArea.Visible = not minimized
        MinButton.Text = minimized and "☐" or "_"
        Frame.Size = minimized and UDim2.new(0, 350, 0, 40) or UDim2.new(0, 350, 0, 370)
    end)

    -- Fechar
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        stopPlatform()
        if markPart then markPart:Destroy() end
    end)

    -- Persistência após respawn
    player.CharacterAdded:Connect(function()
        wait(1)
        if not player.PlayerGui:FindFirstChild(guiName) then
            createGui()
        end
    end)
end

createGui()