--[[ ABD HUB – VIOLENCE DISTRICT (PAINEL PRÓPRIO) ]]
-- Compatível com Delta, Arceus X, etc. (não precisa de Rayfield)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🚀 Carregando Abd Hub (Painel Próprio)...")

-- =============================================
-- DETECTAR MOBILE
-- =============================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local executorName = identifyexecutor and identifyexecutor() or "Desconhecido"
isMobile = isMobile or executorName:lower():find("delta") or executorName:lower():find("arceus") or executorName:lower():find("fluxus")

print("📱 Mobile:", isMobile and "SIM" or "NÃO")
print("⚙️ Executor:", executorName)

-- =============================================
-- VARIÁVEIS GLOBAIS
-- =============================================
local Config = {
    Velocidade = 16,
    Noclip = false,
    Godmode = false,
    Regen = false,
    RegenSpeed = 5,
    AntiKnockback = false,
    ESP = false,
    AutoGenerator = false,
    GeneratorMode = "great",
    AutoGeneratorRange = 25,
    AutoAttack = false,
    AttackRange = 10,
    AttackCooldown = 1.2,
    SkillCheckManual = false,
    AutoLeave = false,
    LeaveDistance = 15,
    LeaveKey = Enum.KeyCode.Q,
    TurboMode = false,
}

local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Highlights = {}
local lastAttackTime = 0
local AutoGenConnection, AutoAttackConnection, LeaveConnection

-- =============================================
-- FUNÇÕES AUXILIARES
-- =============================================
local function notify(title, content)
    print("["..title.."] "..content)
end

local function safeCall(func, ...)
    local s, r = pcall(func, ...)
    return s and r or nil
end

local function getHRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function isKiller()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
end

local function isSurvivor()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors"
end

-- =============================================
-- CRIAÇÃO DA GUI
-- =============================================
local gui
pcall(function()
    gui = Instance.new("ScreenGui")
    gui.Name = "AbdHub"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 3)
end)
if not gui or not gui.Parent then
    pcall(function()
        gui = Instance.new("ScreenGui")
        gui.Name = "AbdHub"
        gui.Parent = game:GetService("CoreGui")
    end)
end
if not gui or not gui.Parent then
    error("Não foi possível criar a GUI.")
end

-- Limpar sobras
for _, child in ipairs(gui:GetChildren()) do child:Destroy() end

-- =============================================
-- BOLINHA FLUTUANTE
-- =============================================
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 55, 0, 55)
floatBtn.Position = UDim2.new(0.02, 0, 0.75, 0)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
floatBtn.BackgroundTransparency = 0.2
floatBtn.BorderSizePixel = 3
floatBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.Text = "⚔️"
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.TextSize = 28
floatBtn.Font = Enum.Font.GothamBold
floatBtn.Parent = gui
local fCorner = Instance.new("UICorner")
fCorner.CornerRadius = UDim.new(1, 0)
fCorner.Parent = floatBtn

-- =============================================
-- PAINEL PRINCIPAL
-- =============================================
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 420)
panel.Position = UDim2.new(0.5, -160, 0.35, -210)
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
panel.BackgroundTransparency = 0
panel.BorderSizePixel = 3
panel.BorderColor3 = Color3.fromRGB(0, 240, 255)
panel.Visible = false
panel.Parent = gui
local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 12)
pCorner.Parent = panel

-- Barra de título
local titleBar = Instance.new("TextButton")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleBar.BackgroundTransparency = 0.2
titleBar.Text = "✦ ABD HUB ✦"
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
titleBar.TextSize = 18
titleBar.Font = Enum.Font.GothamBold
titleBar.Parent = panel
local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 12)
tCorner.Parent = titleBar

-- Botão fechar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 1)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

-- =============================================
-- ABAS
-- =============================================
local abaContainer = Instance.new("Frame")
abaContainer.Size = UDim2.new(1, 0, 0, 30)
abaContainer.Position = UDim2.new(0, 0, 0, 30)
abaContainer.BackgroundTransparency = 1
abaContainer.Parent = panel

local abas = {"Geral", "Jogo", "Proteção"}
local botoesAba = {}
local conteudosAba = {}

for i, nome in ipairs(abas) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, -4)
    btn.Position = UDim2.new((i-1)/3, 0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = nome
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = abaContainer
    table.insert(botoesAba, btn)
end

local function criarAba()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, -70)
    f.Position = UDim2.new(0, 0, 0, 65)
    f.BackgroundTransparency = 1
    f.Visible = false
    f.Parent = panel
    return f
end

local abaGeral = criarAba()
local abaJogo = criarAba()
local abaProtecao = criarAba()

conteudosAba[1] = abaGeral
conteudosAba[2] = abaJogo
conteudosAba[3] = abaProtecao

for i, btn in ipairs(botoesAba) do
    btn.MouseButton1Click:Connect(function()
        for j, b in ipairs(botoesAba) do
            b.TextColor3 = (j == i) and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(180, 180, 200)
        end
        for j, c in ipairs(conteudosAba) do
            c.Visible = (j == i)
        end
    end)
end
conteudosAba[1].Visible = true
botoesAba[1].TextColor3 = Color3.fromRGB(0, 240, 255)

-- =============================================
-- FUNÇÃO PARA CRIAR TOGGLES E SLIDERS
-- =============================================
local function criarToggle(parent, texto, x, y, w, h, cor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, h)
    btn.Position = UDim2.new(x, 0, y, 0)
    btn.BackgroundColor3 = cor
    btn.BackgroundTransparency = 0.15
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = texto .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = texto .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(50, 150, 50) or cor
        callback(state)
    end)
    return btn, state
end

local function criarBotao(parent, texto, x, y, w, h, cor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, h)
    btn.Position = UDim2.new(x, 0, y, 0)
    btn.BackgroundColor3 = cor
    btn.BackgroundTransparency = 0.15
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = texto
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function criarSlider(parent, texto, x, y, w, h, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, w, 0, h)
    frame.Position = UDim2.new(x, 0, y, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.5, 0)
    label.BackgroundTransparency = 1
    label.Text = texto .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.Parent = frame

    local menos = Instance.new("TextButton")
    menos.Size = UDim2.new(0, 30, 0, 0.4)
    menos.Position = UDim2.new(0.1, 0, 0.6, 0)
    menos.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    menos.Text = "−"
    menos.TextColor3 = Color3.fromRGB(255, 255, 255)
    menos.TextSize = 16
    menos.Font = Enum.Font.SourceSansBold
    menos.Parent = frame
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(0, 6)
    c1.Parent = menos

    local mais = Instance.new("TextButton")
    mais.Size = UDim2.new(0, 30, 0, 0.4)
    mais.Position = UDim2.new(0.7, 0, 0.6, 0)
    mais.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    mais.Text = "+"
    mais.TextColor3 = Color3.fromRGB(255, 255, 255)
    mais.TextSize = 16
    mais.Font = Enum.Font.SourceSansBold
    mais.Parent = frame
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 6)
    c2.Parent = mais

    local val = default
    menos.MouseButton1Click:Connect(function()
        val = math.max(min, val - 1)
        label.Text = texto .. ": " .. val
        callback(val)
    end)
    mais.MouseButton1Click:Connect(function()
        val = math.min(max, val + 1)
        label.Text = texto .. ": " .. val
        callback(val)
    end)

    return frame
end

-- =============================================
-- ABA GERAL (ESP + Velocidade)
-- =============================================
-- Velocidade
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 6, 0, 4)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "⚡ Velocidade: 16"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Font = Enum.Font.SourceSans
speedLabel.Parent = abaGeral

criarBotao(abaGeral, "−", 0.04, 0.18, 45, 28, Color3.fromRGB(200, 60, 60), function()
    Config.Velocidade = math.max(16, Config.Velocidade - 5)
    speedLabel.Text = "⚡ Velocidade: " .. Config.Velocidade
    applySpeed()
end)

criarBotao(abaGeral, "+", 0.26, 0.18, 45, 28, Color3.fromRGB(60, 200, 60), function()
    Config.Velocidade = math.min(100, Config.Velocidade + 5)
    speedLabel.Text = "⚡ Velocidade: " .. Config.Velocidade
    applySpeed()
end)

criarBotao(abaGeral, "↺", 0.48, 0.18, 45, 28, Color3.fromRGB(200, 170, 0), function()
    Config.Velocidade = 16
    speedLabel.Text = "⚡ Velocidade: 16"
    applySpeed()
end)

-- ESP
criarToggle(abaGeral, "👁️ ESP", 0.04, 0.35, 130, 30, Color3.fromRGB(40, 40, 55), function(v)
    Config.ESP = v
    if v then startESP() else stopESP() end
end)

-- Noclip
criarToggle(abaGeral, "🚪 NOCLIP", 0.52, 0.35, 130, 30, Color3.fromRGB(40, 40, 55), function(v)
    Config.Noclip = v
    applyNoclip()
end)

-- Anti-Knockback
criarToggle(abaGeral, "🛡️ ANTI-KB", 0.04, 0.55, 130, 30, Color3.fromRGB(40, 40, 55), function(v)
    Config.AntiKnockback = v
    if v then startAntiKB() elseif antiKBLoop then antiKBLoop:Disconnect() end
end)

-- =============================================
-- ABA JOGO
-- =============================================
-- Auto Generator
criarToggle(abaJogo, "⚡ AUTO GEN", 0.04, 0.06, 200, 30, Color3.fromRGB(40, 40, 55), function(v)
    Config.AutoGenerator = v
    if v then startAutoGen() else stopAutoGen() end
end)

-- Modo Gerador
local genLabel = Instance.new("TextLabel")
genLabel.Size = UDim2.new(1, 0, 0, 20)
genLabel.Position = UDim2.new(0, 6, 0.15, 0)
genLabel.BackgroundTransparency = 1
genLabel.Text = "Modo: Ótimo"
genLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
genLabel.TextSize = 13
genLabel.TextXAlignment = Enum.TextXAlignment.Left
genLabel.Font = Enum.Font.SourceSans
genLabel.Parent = abaJogo

criarBotao(abaJogo, "Ótimo", 0.04, 0.24, 80, 26, Color3.fromRGB(50, 150, 50), function()
    Config.GeneratorMode = "great"
    genLabel.Text = "Modo: Ótimo"
end)

criarBotao(abaJogo, "Normal", 0.34, 0.24, 80, 26, Color3.fromRGB(200, 170, 0), function()
    Config.GeneratorMode = "normal"
    genLabel.Text = "Modo: Normal"
end)

-- Turbo Mode
criarToggle(abaJogo, "🚀 TURBO", 0.04, 0.34, 150, 28, Color3.fromRGB(40, 40, 55), function(v)
    Config.TurboMode = v
    notify("Turbo", v and "Ativado (3x)" or "Desativado")
end)

-- Skill Check Manual
criarToggle(abaJogo, "🎯 SKILL CHECK PERF", 0.04, 0.42, 200, 30, Color3.fromRGB(40, 40, 55), function(v)
    Config.SkillCheckManual = v
    if v then setupSkillCheck() end
    notify("Skill Check", v and "Perfeito (manual)" or "Desativado")
end)

-- Distância Auto Generator
criarSlider(abaJogo, "Distância", 0.04, 0.52, 250, 35, 5, 50, 25, function(v)
    Config.AutoGeneratorRange = v
end)

-- Completar todos geradores
criarBotao(abaJogo, "📦 COMPLETAR TODOS", 0.04, 0.66, 280, 30, Color3.fromRGB(0, 150, 255), function()
    completeAllGenerators()
end)

-- Sair Gerador
criarToggle(abaJogo, "🚪 AUTO LEAVE", 0.04, 0.76, 200, 28, Color3.fromRGB(40, 40, 55), function(v)
    Config.AutoLeave = v
    if v then startAutoLeave() else stopAutoLeave() end
end)

-- Distância Leave
criarSlider(abaJogo, "Dist. Leave", 0.04, 0.84, 250, 35, 5, 30, 15, function(v)
    Config.LeaveDistance = v
end)

-- Auto Attack
criarToggle(abaJogo, "⚔️ AUTO ATTACK", 0.04, 0.94, 200, 28, Color3.fromRGB(40, 40, 55), function(v)
    Config.AutoAttack = v
    if v then startAutoAttack() else stopAutoAttack() end
end)

-- =============================================
-- ABA PROTEÇÃO
-- =============================================
-- Godmode
criarToggle(abaProtecao, "♾️ GODMODE", 0.04, 0.06, 200, 30, Color3.fromRGB(40, 40, 55), function(v)
    Config.Godmode = v
    if v then startGodmode() elseif godLoop then godLoop:Disconnect() end
end)

-- Regeneração
criarToggle(abaProtecao, "🩸 REGEN", 0.04, 0.18, 200, 30, Color3.fromRGB(40, 40, 55), function(v)
    Config.Regen = v
    if v then startRegen() elseif regenLoop then regenLoop:Disconnect() end
end)

-- Velocidade da Regeneração
criarSlider(abaProtecao, "Regen Speed", 0.04, 0.32, 250, 35, 1, 20, 5, function(v)
    Config.RegenSpeed = v
end)

-- =============================================
-- FUNÇÕES DE PROTEÇÃO
-- =============================================
local function applySpeed()
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Config.Velocidade end
end

local function applyNoclip()
    if not myChar then return end
    for _, part in ipairs(myChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not Config.Noclip
        end
    end
end

local godLoop, regenLoop, antiKBLoop

local function startGodmode()
    if godLoop then godLoop:Disconnect() end
    godLoop = RunService.Heartbeat:Connect(function()
        if Config.Godmode and myChar then
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                if hum.Health <= 0 then hum.Health = hum.MaxHealth end
            end
        end
    end)
end

local function startRegen()
    if regenLoop then regenLoop:Disconnect() end
    regenLoop = RunService.Heartbeat:Connect(function()
        if Config.Regen and myChar then
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = math.min(hum.Health + Config.RegenSpeed * 0.1, hum.MaxHealth)
            end
        end
    end)
end

local function startAntiKB()
    if antiKBLoop then antiKBLoop:Disconnect() end
    antiKBLoop = RunService.Heartbeat:Connect(function()
        if Config.AntiKnockback and myChar then
            local root = myChar:FindFirstChild("HumanoidRootPart")
            if root then root.Velocity = Vector3.new(0, root.Velocity.Y, 0) end
        end
    end)
end

-- =============================================
-- SKILL CHECK PERFEITO (MANUAL)
-- =============================================
local function setupSkillCheck()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local genRemotes = remotes:FindFirstChild("Generator")
    if not genRemotes then return end
    local skill = genRemotes:FindFirstChild("SkillCheckResultEvent")
    if not skill then return end
    local original = skill.FireServer
    skill.FireServer = function(self, result, value, generator, point)
        if Config.SkillCheckManual then
            return original(self, "success", 1, generator, point)
        else
            return original(self, result, value, generator, point)
        end
    end
end

-- =============================================
-- ESP
-- =============================================
local function createHighlight(obj, color)
    if not obj or obj:FindFirstChild("D") then return end
    safeCall(function()
        local h = Instance.new("Highlight")
        h.Name = "D"
        h.Adornee = obj
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.Parent = obj
        Highlights[obj] = h
    end)
end

local function removeHighlight(obj)
    if Highlights[obj] then safeCall(function() Highlights[obj]:Destroy() end) end
    Highlights[obj] = nil
    local existing = obj:FindFirstChild("D")
    if existing then existing:Destroy() end
end

local function clearESP()
    for obj, _ in pairs(Highlights) do removeHighlight(obj) end
    Highlights = {}
end

local UpdateConnection

local function updateESP()
    if not Config.ESP then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team then
            if player.Team.Name == "Killer" then
                createHighlight(player.Character, Color3.fromRGB(255,0,0))
            elseif player.Team.Name == "Survivors" then
                createHighlight(player.Character, Color3.fromRGB(0,255,0))
            end
        end
    end
    -- Paletas
    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Pallet") or obj.Name:find("Palete")) then
                local dropped = false
                local primary = obj:FindFirstChildWhichIsA("BasePart")
                if primary then
                    if math.abs(primary.Orientation.X or 0) > 30 or math.abs(primary.Orientation.Z or 0) > 30 then
                        dropped = true
                    end
                    if primary.Position.Y < 1.5 then
                        dropped = true
                    end
                end
                if dropped then
                    removeHighlight(obj)
                else
                    createHighlight(obj, Color3.fromRGB(255,255,0))
                end
            end
        end
    end
end

local function startESP()
    if UpdateConnection then return end
    UpdateConnection = RunService.Heartbeat:Connect(updateESP)
    notify("ESP", "Ativado")
end

local function stopESP()
    if UpdateConnection then
        UpdateConnection:Disconnect()
        UpdateConnection = nil
    end
    clearESP()
    notify("ESP", "Desativado")
end

-- =============================================
-- AUTO GENERATOR
-- =============================================
local function getGeneratorRemotes()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then remotes = ReplicatedStorage end
    local gen = remotes:FindFirstChild("Generator") or remotes:FindFirstChild("Generators")
    if not gen then return nil, nil end
    local repair = gen:FindFirstChild("RepairEvent") or gen:FindFirstChild("Repair")
    local skill = gen:FindFirstChild("SkillCheckResultEvent") or gen:FindFirstChild("SkillCheck")
    return repair, skill
end

local function autoGenLoop()
    if not Config.AutoGenerator then return end
    local hrp = getHRP()
    if not hrp then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local nearest = math.huge
    local target = nil
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < nearest then
                    nearest = dist
                    target = obj
                end
            end
        end
    end
    if nearest > Config.AutoGeneratorRange or not target then return end
    local repair, skill = getGeneratorRemotes()
    if not repair or not skill then return end
    local repeats = Config.TurboMode and 3 or 1
    for _, point in ipairs(target:GetChildren()) do
        if point.Name:find("GeneratorPoint") then
            for i = 1, repeats do
                pcall(function()
                    repair:FireServer(point, true)
                    local result = Config.GeneratorMode == "great" and "success" or "neutral"
                    local value = Config.GeneratorMode == "great" and 1 or 0
                    skill:FireServer(result, value, target, point)
                end)
            end
        end
    end
end

local function startAutoGen()
    if AutoGenConnection then return end
    AutoGenConnection = RunService.Heartbeat:Connect(autoGenLoop)
    notify("Auto Gen", "Ativado")
end

local function stopAutoGen()
    if AutoGenConnection then
        AutoGenConnection:Disconnect()
        AutoGenConnection = nil
    end
    notify("Auto Gen", "Desativado")
end

local function completeAllGenerators()
    local map = Workspace:FindFirstChild("Map")
    if not map then notify("Erro", "Mapa não encontrado") return end
    local repair, skill = getGeneratorRemotes()
    if not repair or not skill then notify("Erro", "Remotos não encontrados") return end
    local count = 0
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            for _, point in ipairs(obj:GetChildren()) do
                if point.Name:find("GeneratorPoint") then
                    pcall(function()
                        for i = 1, 15 do
                            repair:FireServer(point, true)
                            skill:FireServer("success", 1, obj, point)
                        end
                        count = count + 1
                    end)
                end
            end
        end
    end
    notify("Completo!", count > 0 and string.format("%d geradores", count) or "Nenhum encontrado")
end

-- =============================================
-- AUTO LEAVE
-- =============================================
local function leaveGenerator()
    local hrp = getHRP()
    if not hrp then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local nearest = math.huge
    local target = nil
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < nearest then
                    nearest = dist
                    target = part
                end
            end
        end
    end
    if not target or nearest > Config.LeaveDistance then
        notify("Longe", "Não está perto de um gerador")
        return
    end
    local dir = (hrp.Position - target.Position).Unit
    local esc = hrp.Position + dir * (Config.LeaveDistance + 15)
    hrp.CFrame = CFrame.new(esc)
    notify("Escapou!", "Saiu do gerador")
end

local function startAutoLeave()
    if LeaveConnection then return end
    if not isMobile then
        LeaveConnection = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Config.LeaveKey then leaveGenerator() end
        end)
    end
    notify("Auto Leave", "Ativado")
end

local function stopAutoLeave()
    if LeaveConnection then
        LeaveConnection:Disconnect()
        LeaveConnection = nil
    end
    notify("Auto Leave", "Desativado")
end

-- =============================================
-- AUTO ATTACK
-- =============================================
local function performAutoAttack()
    if not isKiller() then return end
    local now = tick()
    if now - lastAttackTime < Config.AttackCooldown then return end
    local hrp = getHRP()
    if not hrp then return end
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed < 12 then return end
    local target = nil
    local dist = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
            local t = player.Character:FindFirstChild("HumanoidRootPart")
            if t then
                local d = (t.Position - hrp.Position).Magnitude
                if d < dist and d <= Config.AttackRange then
                    dist = d
                    target = player
                end
            end
        end
    end
    if target then
        safeCall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local attacks = remotes:FindFirstChild("Attacks")
                if attacks then
                    local basic = attacks:FindFirstChild("BasicAttack")
                    if basic then
                        basic:FireServer(false)
                        lastAttackTime = now
                        if hum then task.delay(0.1, function() if hum and hum.Parent then hum.WalkSpeed = hum.WalkSpeed end end) end
                    end
                end
            end
        end)
    end
end

local function startAutoAttack()
    if AutoAttackConnection then return end
    if not isKiller() then notify("Erro", "Precisa ser o Assassino!") return end
    AutoAttackConnection = RunService.Heartbeat:Connect(function()
        if Config.AutoAttack then performAutoAttack() end
    end)
    notify("Auto Attack", "Ativado")
end

local function stopAutoAttack()
    if AutoAttackConnection then
        AutoAttackConnection:Disconnect()
        AutoAttackConnection = nil
    end
    notify("Auto Attack", "Desativado")
end

-- =============================================
-- INTERAÇÃO DO PAINEL
-- =============================================
local aberto = false
floatBtn.MouseButton1Click:Connect(function()
    aberto = not aberto
    panel.Visible = aberto
    floatBtn.Text = aberto and "⚔️" or "≡"
    floatBtn.BackgroundColor3 = aberto and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(80, 80, 80)
end)

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
    aberto = false
    floatBtn.Text = "≡"
    floatBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
end)

-- =============================================
-- ARRASTAR BOLINHA E PAINEL
-- =============================================
local dragB = false; local dB, posB
floatBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragB = true
        dB = i.Position
        posB = floatBtn.Position
    end
end)
floatBtn.InputEnded:Connect(function() dragB = false end)

local dragP = false; local dP, posP
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragP = true
        dP = i.Position
        posP = panel.Position
    end
end)
titleBar.InputEnded:Connect(function() dragP = false end)

UserInputService.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        if dragB then
            local delta = i.Position - dB
            floatBtn.Position = UDim2.new(posB.X.Scale, posB.X.Offset + delta.X, posB.Y.Scale, posB.Y.Offset + delta.Y)
        end
        if dragP then
            local delta = i.Position - dP
            panel.Position = UDim2.new(posP.X.Scale, posP.X.Offset + delta.X, posP.Y.Scale, posP.Y.Offset + delta.Y)
        end
    end
end)

-- =============================================
-- INICIALIZAR
-- =============================================
applySpeed()
applyNoclip()
setupSkillCheck()
if Config.AutoGenerator then startAutoGen() end
if Config.AutoAttack then startAutoAttack() end
if Config.AutoLeave then startAutoLeave() end
if Config.ESP then startESP() end

print("========================================")
print("✅ ABD HUB – Painel Próprio Carregado!")
print("📱 Mobile:", isMobile and "SIM" or "NÃO")
print("⚔️ Toque na bolinha para abrir o painel")
print("🎯 Skill Check Perfeito (Manual) incluso")
print("========================================")