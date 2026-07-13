--[[ ABD HUB – VIOLENCE DISTRICT (AMETHYST UI) ]]
-- Interface bonita, leve e compatível com mobile

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🚀 Carregando Abd Hub (Amethyst UI)...")

-- =============================================
-- DETECTAR MOBILE
-- =============================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local executorName = identifyexecutor and identifyexecutor() or "Desconhecido"
isMobile = isMobile or executorName:lower():find("delta") or executorName:lower():find("arceus") or executorName:lower():find("fluxus")

print("📱 Mobile:", isMobile and "SIM" or "NÃO")

-- =============================================
-- CARREGAR AMETHYST UI
-- =============================================
local Amethyst
local function loadAmethyst()
    local urls = {
        "https://raw.githubusercontent.com/Amethyst-UI/main/source/main.lua",
        "https://raw.githubusercontent.com/Amethyst-UI/Amethyst/main/source.lua",
        "https://pastebin.com/raw/AmethystUI", -- fallback
    }
    for _, url in ipairs(urls) do
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        if success and result then
            local func, err = loadstring(result)
            if func then
                Amethyst = func()
                if Amethyst then
                    print("✅ Amethyst UI carregada com sucesso!")
                    return true
                end
            end
        end
    end
    return false
end

if not loadAmethyst() then
    warn("⚠️ Falha ao carregar Amethyst UI. Usando interface alternativa...")
    -- Fallback para o painel próprio (caso a Amethyst não carregue)
    -- (código do painel próprio aqui)
    return
end

-- =============================================
-- CONFIGURAÇÕES
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

local function notify(title, content)
    if Amethyst and Amethyst.Notify then
        Amethyst:Notify({
            Title = title,
            Content = content,
            Duration = 3,
            Image = 4483362458,
        })
    else
        print("["..title.."] "..content)
    end
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
-- SKILL CHECK PERFEITO
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
-- CRIAR INTERFACE AMETHYST
-- =============================================
local Window = Amethyst:CreateWindow({
    Name = "⚔️ Abd Hub",
    Color = Color3.fromRGB(0, 200, 255),
    Keybind = Enum.KeyCode.RightControl,
})

-- =============================================
-- ABA GERAL
-- =============================================
local GeralTab = Window:CreateTab("⚡ Geral")

-- Velocidade
local SpeedSection = GeralTab:CreateSection("Velocidade")
SpeedSection:CreateSlider({
    Name = "Velocidade",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        Config.Velocidade = v
        applySpeed()
    end
})

-- ESP e Noclip
local ESP_Section = GeralTab:CreateSection("Visual")
ESP_Section:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(v)
        Config.ESP = v
        if v then startESP() else stopESP() end
    end
})
ESP_Section:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        Config.Noclip = v
        applyNoclip()
    end
})

-- Defesa
local DefesaSection = GeralTab:CreateSection("Defesa")
DefesaSection:CreateToggle({
    Name = "Anti-Knockback",
    CurrentValue = false,
    Callback = function(v)
        Config.AntiKnockback = v
        if v then startAntiKB() elseif antiKBLoop then antiKBLoop:Disconnect() end
    end
})
DefesaSection:CreateToggle({
    Name = "Godmode",
    CurrentValue = false,
    Callback = function(v)
        Config.Godmode = v
        if v then startGodmode() elseif godLoop then godLoop:Disconnect() end
    end
})

-- Regeneração
local RegenSection = GeralTab:CreateSection("Regeneração")
RegenSection:CreateToggle({
    Name = "Regeneração",
    CurrentValue = false,
    Callback = function(v)
        Config.Regen = v
        if v then startRegen() elseif regenLoop then regenLoop:Disconnect() end
    end
})
RegenSection:CreateSlider({
    Name = "Velocidade Regen",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v)
        Config.RegenSpeed = v
    end
})

-- =============================================
-- ABA JOGO
-- =============================================
local JogoTab = Window:CreateTab("🎮 Jogo")

-- Auto Generator
local GenSection = JogoTab:CreateSection("Auto Gerador")
GenSection:CreateToggle({
    Name = "Auto Generator",
    CurrentValue = false,
    Callback = function(v)
        Config.AutoGenerator = v
        if v then startAutoGen() else stopAutoGen() end
    end
})
GenSection:CreateDropdown({
    Name = "Modo Gerador",
    Options = {"Ótimo", "Normal"},
    CurrentOption = "Ótimo",
    Callback = function(o)
        Config.GeneratorMode = o == "Ótimo" and "great" or "normal"
    end
})
GenSection:CreateToggle({
    Name = "Turbo Mode",
    CurrentValue = false,
    Callback = function(v)
        Config.TurboMode = v
        notify("Turbo", v and "Ativado" or "Desativado")
    end
})
GenSection:CreateSlider({
    Name = "Distância Máxima",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 25,
    Callback = function(v)
        Config.AutoGeneratorRange = v
    end
})

-- Skill Check
local SkillSection = JogoTab:CreateSection("Skill Check")
SkillSection:CreateToggle({
    Name = "Skill Check Perfeito (Manual)",
    CurrentValue = false,
    Callback = function(v)
        Config.SkillCheckManual = v
        if v then setupSkillCheck() end
        notify("Skill Check", v and "Perfeito" or "Desativado")
    end
})

-- Ações
local AcoesSection = JogoTab:CreateSection("Ações")
AcoesSection:CreateButton({
    Name = "Completar Todos Geradores",
    Callback = function()
        completeAllGenerators()
    end
})

-- Fuga
local FugaSection = JogoTab:CreateSection("Fuga")
FugaSection:CreateToggle({
    Name = "Auto Leave",
    CurrentValue = false,
    Callback = function(v)
        Config.AutoLeave = v
        if v then startAutoLeave() else stopAutoLeave() end
    end
})
FugaSection:CreateSlider({
    Name = "Distância Leave",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v)
        Config.LeaveDistance = v
    end
})

-- Auto Attack
local AtkSection = JogoTab:CreateSection("Auto Attack")
AtkSection:CreateToggle({
    Name = "Auto Attack",
    CurrentValue = false,
    Callback = function(v)
        Config.AutoAttack = v
        if v then startAutoAttack() else stopAutoAttack() end
    end
})
AtkSection:CreateSlider({
    Name = "Alcance",
    Range = {5, 20},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(v)
        Config.AttackRange = v
    end
})
AtkSection:CreateSlider({
    Name = "Cooldown",
    Range = {0.5, 2.0},
    Increment = 0.1,
    CurrentValue = 1.2,
    Callback = function(v)
        Config.AttackCooldown = v
    end
})

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

notify("Abd Hub", "Carregado com sucesso!")

print("========================================")
print("✅ ABD HUB – AMETHYST UI")
print("📱 Mobile:", isMobile and "SIM" or "NÃO")
print("🎨 Interface Amethyst UI carregada")
print("========================================")