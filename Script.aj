-- [[ CONFIGURAÇÕES DA INTERFACE PARA O DELTA ]] --
-- Ícone transparente com emoji pequeno (⚔️)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remove versões antigas
if PlayerGui:FindFirstChild("AnyMenu_Delta") then
    PlayerGui.AnyMenu_Delta:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnyMenu_Delta"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- =============================================
-- VARIÁVEIS DAS FUNÇÕES
-- =============================================
local valorVelocidade = 16
local espAtivado = false
local noclipAtivado = false
local antiKnockback = false
local godmodeAtivado = false
local noclipConnection = nil

-- =============================================
-- 1. ÍCONE FLUTUANTE (TRANSPARENTE + EMOJI PEQUENO)
-- =============================================
local IconButton = Instance.new("TextButton")
IconButton.Name = "IconeCavaleiro"
IconButton.Size = UDim2.new(0, 60, 0, 60)          -- Tamanho da bolinha
IconButton.Position = UDim2.new(0, 20, 0, 150)
IconButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
IconButton.BackgroundTransparency = 0.7           -- TRANSPARENTE (70% transparente)
IconButton.Text = "⚔️"
IconButton.TextColor3 = Color3.fromRGB(255, 255, 255)
IconButton.TextSize = 22                          -- EMOJI PEQUENO
IconButton.TextScaled = false                     -- Desativa o escalonamento automático
IconButton.Font = Enum.Font.GothamBold
IconButton.Active = true
IconButton.Parent = ScreenGui

-- Cantos arredondados (círculo)
local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = IconButton

-- Borda suave (dourada, mas transparente)
local IconStroke = Instance.new("UIStroke")
IconStroke.Color = Color3.fromRGB(200, 180, 100)
IconStroke.Thickness = 2
IconStroke.Transparency = 0.5                    -- Borda também transparente
IconStroke.Parent = IconButton

-- =============================================
-- 2. PAINEL PRINCIPAL (MANTIDO)
-- =============================================
local MainPanel = Instance.new("Frame")
MainPanel.Name = "any"
MainPanel.Size = UDim2.new(0, 280, 0, 320)
MainPanel.Position = UDim2.new(0.5, -140, 0.35, -160)
MainPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
MainPanel.BackgroundTransparency = 0.1
MainPanel.Visible = false
MainPanel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 12)
PanelCorner.Parent = MainPanel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(140, 140, 160)
PanelStroke.Thickness = 1.5
PanelStroke.Parent = MainPanel

local PanelTitle = Instance.new("TextLabel")
PanelTitle.Size = UDim2.new(1, 0, 0, 35)
PanelTitle.Position = UDim2.new(0, 0, 0, 0)
PanelTitle.BackgroundTransparency = 1
PanelTitle.Text = "any"
PanelTitle.TextColor3 = Color3.fromRGB(220, 220, 240)
PanelTitle.TextSize = 22
PanelTitle.Font = Enum.Font.SourceSansBold
PanelTitle.Parent = MainPanel

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 3)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Parent = MainPanel

-- =============================================
-- 3. SEÇÃO DE VELOCIDADE
-- =============================================
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0, 25)
SpeedLabel.Position = UDim2.new(0, 0, 0, 40)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Velocidade: " .. valorVelocidade
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
SpeedLabel.TextSize = 15
SpeedLabel.Font = Enum.Font.SourceSans
SpeedLabel.Parent = MainPanel

local MenosBtn = Instance.new("TextButton")
MenosBtn.Size = UDim2.new(0, 55, 0, 30)
MenosBtn.Position = UDim2.new(0, 35, 0, 70)
MenosBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
MenosBtn.Text = "-"
MenosBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MenosBtn.TextSize = 20
MenosBtn.Font = Enum.Font.SourceSansBold
MenosBtn.Parent = MainPanel
local MenosCorner = Instance.new("UICorner")
MenosCorner.CornerRadius = UDim.new(0, 6)
MenosCorner.Parent = MenosBtn

local MaisBtn = Instance.new("TextButton")
MaisBtn.Size = UDim2.new(0, 55, 0, 30)
MaisBtn.Position = UDim2.new(0, 120, 0, 70)
MaisBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 50)
MaisBtn.Text = "+"
MaisBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MaisBtn.TextSize = 20
MaisBtn.Font = Enum.Font.SourceSansBold
MaisBtn.Parent = MainPanel
local MaisCorner = Instance.new("UICorner")
MaisCorner.CornerRadius = UDim.new(0, 6)
MaisCorner.Parent = MaisBtn

local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(0, 55, 0, 30)
ResetBtn.Position = UDim2.new(0, 205, 0, 70)
ResetBtn.BackgroundColor3 = Color3.fromRGB(200, 170, 0)
ResetBtn.Text = "↺"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.TextSize = 20
ResetBtn.Font = Enum.Font.SourceSansBold
ResetBtn.Parent = MainPanel
local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 6)
ResetCorner.Parent = ResetBtn

-- =============================================
-- 4. BOTÕES EM GRADE (2 COLUNAS)
-- =============================================
local function criarBotao(texto, x, y, cor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 35)
    btn.Position = UDim2.new(x, 0, y, 0)
    btn.BackgroundColor3 = cor
    btn.Text = texto
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = MainPanel
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    return btn
end

local EspBtn = criarBotao("👁️ ESP", 0.04, 0.38, Color3.fromRGB(40, 40, 55))
local NoclipBtn = criarBotao("🚪 NOCLIP", 0.54, 0.38, Color3.fromRGB(40, 40, 55))
local KnockbackBtn = criarBotao("🛡️ ANTI-KB", 0.04, 0.58, Color3.fromRGB(40, 40, 55))
local GodmodeBtn = criarBotao("💀 IMORTAL", 0.54, 0.58, Color3.fromRGB(40, 40, 55))

-- =============================================
-- LÓGICA DE INTERAÇÃO
-- =============================================
IconButton.MouseButton1Click:Connect(function()
    MainPanel.Visible = not MainPanel.Visible
end)

CloseButton.MouseButton1Click:Connect(function()
    MainPanel.Visible = false
end)

-- =============================================
-- SISTEMA DE VELOCIDADE
-- =============================================
local function aplicarVelocidade()
    SpeedLabel.Text = "Velocidade: " .. valorVelocidade
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        character:FindFirstChildOfClass("Humanoid").WalkSpeed = valorVelocidade
    end
end

MenosBtn.MouseButton1Click:Connect(function()
    valorVelocidade = math.clamp(valorVelocidade - 5, 16, 100)
    aplicarVelocidade()
end)

MaisBtn.MouseButton1Click:Connect(function()
    valorVelocidade = math.clamp(valorVelocidade + 5, 16, 100)
    aplicarVelocidade()
end)

ResetBtn.MouseButton1Click:Connect(function()
    valorVelocidade = 16
    aplicarVelocidade()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then hum.WalkSpeed = valorVelocidade end
end)

-- =============================================
-- LÓGICA DO ESP
-- =============================================
local function criarESP(character)
    if not character then return end
    local p = Players:GetPlayerFromCharacter(character)
    if p == LocalPlayer then return end
    if character:FindFirstChild("Any_Highlight") then
        character.Any_Highlight:Destroy()
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "Any_Highlight"
    highlight.FillColor = Color3.fromRGB(0, 255, 100)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineTransparency = 0
    highlight.Adornee = character
    highlight.Enabled = espAtivado
    highlight.Parent = character
end

local function monitorarJogador(p)
    if p == LocalPlayer then return end
    if p.Character then criarESP(p.Character) end
    p.CharacterAdded:Connect(criarESP)
end

for _, player in ipairs(Players:GetPlayers()) do monitorarJogador(player) end
Players.PlayerAdded:Connect(monitorarJogador)

EspBtn.MouseButton1Click:Connect(function()
    espAtivado = not espAtivado
    if espAtivado then
        EspBtn.Text = "👁️ ESP: ON"
        EspBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        EspBtn.Text = "👁️ ESP"
        EspBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Any_Highlight") then
            player.Character.Any_Highlight.Enabled = espAtivado
        end
    end
end)

-- =============================================
-- LÓGICA DO NOCLIP
-- =============================================
local function loopNoclip()
    local character = LocalPlayer.Character
    if character and noclipAtivado then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.NoPhysics)
        end
    end
end

NoclipBtn.MouseButton1Click:Connect(function()
    noclipAtivado = not noclipAtivado
    if noclipAtivado then
        NoclipBtn.Text = "🚪 NOCLIP: ON"
        NoclipBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        noclipConnection = RunService.Stepped:Connect(loopNoclip)
    else
        NoclipBtn.Text = "🚪 NOCLIP"
        NoclipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end
end)

-- =============================================
-- LÓGICA DO ANTI-KNOCKBACK
-- =============================================
KnockbackBtn.MouseButton1Click:Connect(function()
    antiKnockback = not antiKnockback
    if antiKnockback then
        KnockbackBtn.Text = "🛡️ ANTI-KB: ON"
        KnockbackBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        KnockbackBtn.Text = "🛡️ ANTI-KB"
        KnockbackBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    if antiKnockback then
        local humanoid = char:WaitForChild("Humanoid")
        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if antiKnockback and humanoid.Health > 0 then
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Velocity = Vector3.new(0, rootPart.Velocity.Y, 0)
                end
            end
        end)
    end
end)

-- =============================================
-- LÓGICA DO MODO IMORTAL (GODMODE)
-- =============================================
local godmodeLoop = nil

local function ativarGodmode()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid.MaxHealth = 99999
    humanoid.Health = 99999
    if godmodeLoop then godmodeLoop:Disconnect() end
    godmodeLoop = RunService.Heartbeat:Connect(function()
        if godmodeAtivado then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end
        end
    end)
end

local function desativarGodmode()
    if godmodeLoop then
        godmodeLoop:Disconnect()
        godmodeLoop = nil
    end
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end
end

GodmodeBtn.MouseButton1Click:Connect(function()
    godmodeAtivado = not godmodeAtivado
    if godmodeAtivado then
        GodmodeBtn.Text = "💀 IMORTAL: ON"
        GodmodeBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        ativarGodmode()
    else
        GodmodeBtn.Text = "💀 IMORTAL"
        GodmodeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        desativarGodmode()
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    wait(0.5)
    if godmodeAtivado then
        ativarGodmode()
    end
end)

-- =============================================
-- ARRASTAR ÍCONE (MOBILE)
-- =============================================
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    IconButton.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

IconButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = IconButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

IconButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

print("✅ Ícone transparente com emoji pequeno carregado!")
print("⚔️ Toque no ícone para abrir o painel")
