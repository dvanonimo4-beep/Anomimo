--[[ ABD HUB – Violence District + Extras (Português) ]]
-- ESP simplificado (apenas cores) + Auto Ataque corrigido

local function detectMobilePlatform()
    local UserInputService = game:GetService("UserInputService")
    local hasTouchScreen = UserInputService.TouchEnabled
    local camera = workspace.CurrentCamera
    local viewportSize = camera and camera.ViewportSize or Vector2.new(0, 0)
    local isSmallScreen = viewportSize.X <= 1024 or viewportSize.Y <= 768
    local hasGyroscope = UserInputService.GyroscopeEnabled or UserInputService.AccelerometerEnabled
    local noKeyboard = not UserInputService.KeyboardEnabled
    local executorName = identifyexecutor and identifyexecutor() or "Unknown"
    local isMobileExecutor = executorName:lower():find("delta") or 
                             executorName:lower():find("arceus") or
                             executorName:lower():find("fluxus") or
                             executorName:lower():find("krnl")
    local isMobile = hasTouchScreen and (noKeyboard or isSmallScreen or hasGyroscope or isMobileExecutor)
    if hasTouchScreen and isMobileExecutor then isMobile = true end
    return isMobile
end

local isMobile = detectMobilePlatform()
local executorName = identifyexecutor and identifyexecutor() or "Unknown"

print("=== ABD HUB ===")
print("Plataforma:", isMobile and "Mobile" or "PC")
print("Executor:", executorName)

local function safeHttpGet(url)
    local success, result
    if game.HttpGet then
        success, result = pcall(function() return game:HttpGet(url) end)
        if success then return result end
    end
    if syn and syn.request then
        success, result = pcall(function() return syn.request({Url = url, Method = "GET"}).Body end)
        if success then return result end
    end
    if http and http.request then
        success, result = pcall(function() return http.request({Url = url, Method = "GET"}).Body end)
        if success then return result end
    end
    if http_request then
        success, result = pcall(function() return http_request({Url = url, Method = "GET"}).Body end)
        if success then return result end
    end
    if request then
        success, result = pcall(function() return request({Url = url, Method = "GET"}).Body end)
        if success then return result end
    end
    error("Falha ao carregar URL: " .. url)
end

local Rayfield
pcall(function()
    Rayfield = loadstring(safeHttpGet('https://sirius.menu/rayfield'))()
end)
if not Rayfield then
    pcall(function()
        Rayfield = loadstring(safeHttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
end
if not Rayfield then
    error("Falha ao carregar Rayfield")
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- =============================================
-- CONFIGURAÇÕES
-- =============================================
local Config = {
    ESP = {
        Killer = false,
        Survivor = false,
    },
    AutoFeatures = {
        AutoGenerator = false,
        GeneratorMode = "great",
        AutoLeaveGenerator = false,
        LeaveDistance = 15,
        LeaveKeybind = Enum.KeyCode.Q,
        AutoAttack = false,
        AttackRange = 10,
        AttackCooldown = 0.3,
    },
    Teleportation = {
        TeleportOffset = 3,
        SafeTeleport = true,
        TeleportDelay = 0.1
    },
    Performance = {
        UpdateRate = 0.5,
        MaxESPObjects = isMobile and 50 or 100,
    },
    MyFeatures = {
        Speed = 16,
        Noclip = false,
        AntiDeath = false,
        Godmode = false,
        Regen = false,
        RegenSpeed = 5,
        AntiKnockback = false,
        AntiStun = false,
    }
}

-- =============================================
-- VARIÁVEIS
-- =============================================
local Highlights = {}
local LastUpdate = 0
local UpdateConnection = nil
local LeaveGeneratorConnection = nil
local AutoAttackConnection = nil
local lastAttackTime = 0

local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local regenLoop, godLoop, antiKBLoop, antiStunLoop, antiDeathLoop

-- =============================================
-- FUNÇÕES AUXILIARES
-- =============================================
local function notify(title, content, duration)
    pcall(function()
        Rayfield:Notify({Title = title, Content = content, Duration = duration or 3, Image = 4483362458})
    end)
end

local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    return success and result or nil
end

local function validateInstance(instance)
    return instance and typeof(instance) == "Instance" and instance.Parent ~= nil
end

local function isKiller()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer"
end

local function isSurvivor()
    return LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors"
end

local function getCharacterRootPart()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- =============================================
-- MINHAS FUNÇÕES EXTRAS
-- =============================================
local function applySpeed()
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Config.MyFeatures.Speed end
end

local function applyNoclip()
    if not myChar then return end
    for _, part in ipairs(myChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not Config.MyFeatures.Noclip
        end
    end
end

local function startAntiDeath()
    if antiDeathLoop then antiDeathLoop:Disconnect() end
    antiDeathLoop = RunService.Heartbeat:Connect(function()
        if Config.MyFeatures.AntiDeath and myChar then
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.Health <= 0 then
                    hum.Health = hum.MaxHealth
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                if hum:GetState() == Enum.HumanoidStateType.Dead then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    hum.Health = hum.MaxHealth
                end
            end
            for _, child in ipairs(myChar:GetChildren()) do
                if child:IsA("Script") or child:IsA("LocalScript") then
                    child.Disabled = true
                end
            end
            local hrp = myChar:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, c in ipairs(hrp:GetDescendants()) do
                    if c:IsA("Attachment") or c:IsA("RopeConstraint") then
                        c:Destroy()
                    end
                end
            end
            if not myChar.Parent then
                local newChar = LocalPlayer.Character
                if newChar then myChar = newChar end
            end
        end
    end)
end

local function startGodmode()
    if godLoop then godLoop:Disconnect() end
    godLoop = RunService.Heartbeat:Connect(function()
        if Config.MyFeatures.Godmode and myChar then
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
        if Config.MyFeatures.Regen and myChar then
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = math.min(hum.Health + Config.MyFeatures.RegenSpeed * 0.1, hum.MaxHealth)
            end
        end
    end)
end

local function startAntiKB()
    if antiKBLoop then antiKBLoop:Disconnect() end
    antiKBLoop = RunService.Heartbeat:Connect(function()
        if Config.MyFeatures.AntiKnockback and myChar then
            local root = myChar:FindFirstChild("HumanoidRootPart")
            if root then root.Velocity = Vector3.new(0, root.Velocity.Y, 0) end
        end
    end)
end

local function startAntiStun()
    if antiStunLoop then antiStunLoop:Disconnect() end
    antiStunLoop = RunService.Heartbeat:Connect(function()
        if Config.MyFeatures.AntiStun and myChar then
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            if hum then
                local state = hum:GetState()
                if state == Enum.HumanoidStateType.Freefall or
                   state == Enum.HumanoidStateType.Ragdoll or
                   state == Enum.HumanoidStateType.Physics then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                local root = myChar:FindFirstChild("HumanoidRootPart")
                if root and root.Velocity.Magnitude > 30 then
                    root.Velocity = Vector3.new(0, root.Velocity.Y, 0)
                end
            end
        end
    end)
end

local function updateMyFeatures()
    applySpeed()
    applyNoclip()
    if Config.MyFeatures.AntiDeath then startAntiDeath() elseif antiDeathLoop then antiDeathLoop:Disconnect() end
    if Config.MyFeatures.Godmode then startGodmode() elseif godLoop then godLoop:Disconnect() end
    if Config.MyFeatures.Regen then startRegen() elseif regenLoop then regenLoop:Disconnect() end
    if Config.MyFeatures.AntiKnockback then startAntiKB() elseif antiKBLoop then antiKBLoop:Disconnect() end
    if Config.MyFeatures.AntiStun then startAntiStun() elseif antiStunLoop then antiStunLoop:Disconnect() end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    myChar = char
    wait(0.5)
    updateMyFeatures()
end)

-- =============================================
-- FUNÇÕES DO JOGO
-- =============================================
local function getAllGenerators()
    local generators = {}
    local map = Workspace:FindFirstChild("Map")
    if not map then return generators end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local genPart = obj:FindFirstChildWhichIsA("BasePart")
            if genPart then
                table.insert(generators, {model = obj, part = genPart, position = genPart.Position})
            end
        end
    end
    return generators
end

function getGeneratorsByDistance()
    local hrp = getCharacterRootPart()
    if not hrp then return {} end
    local generators = getAllGenerators()
    for _, gen in ipairs(generators) do
        gen.distance = (gen.position - hrp.Position).Magnitude
    end
    table.sort(generators, function(a, b) return a.distance < b.distance end)
    return generators
end

function safeTeleport(targetCFrame, offset)
    local hrp = getCharacterRootPart()
    if not hrp then return false end
    offset = offset or Vector3.new(0, Config.Teleportation.TeleportOffset, 0)
    if Config.Teleportation.SafeTeleport then
        safeCall(function()
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
    hrp.CFrame = targetCFrame + offset
    if Config.Teleportation.SafeTeleport then
        task.delay(0.5, function()
            safeCall(function()
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end)
        end)
    end
    return true
end

function leaveGenerator()
    local hrp = getCharacterRootPart()
    if not hrp then return false end
    local map = Workspace:FindFirstChild("Map")
    if not map then return false end
    local nearestGen, nearestDist
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local genPart = obj:FindFirstChildWhichIsA("BasePart")
            if genPart then
                local dist = (genPart.Position - hrp.Position).Magnitude
                if dist < (nearestDist or math.huge) then
                    nearestDist = dist
                    nearestGen = genPart
                end
            end
        end
    end
    if not nearestGen or nearestDist > Config.AutoFeatures.LeaveDistance then
        notify("Longe", "Você não está perto de um gerador", 2)
        return false
    end
    local direction = (hrp.Position - nearestGen.Position).Unit
    local escapeDistance = Config.AutoFeatures.LeaveDistance + 15
    local escapePosition = hrp.Position + (direction * escapeDistance)
    local escapeCFrame = CFrame.new(escapePosition, escapePosition + hrp.CFrame.LookVector)
    if safeTeleport(escapeCFrame, Vector3.new(0, 2, 0)) then
        notify("Escapou!", string.format("Fugiu %.0f studs", escapeDistance), 2)
        return true
    end
    return false
end

local function startAutoLeaveGenerator()
    if LeaveGeneratorConnection then return end
    if not isMobile then
        LeaveGeneratorConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Config.AutoFeatures.LeaveKeybind then leaveGenerator() end
        end)
        notify("Sair Gerador", "Pressione " .. Config.AutoFeatures.LeaveKeybind.Name .. " para sair", 3)
    else
        notify("Modo Mobile", "Use o botão no menu Jogo", 3)
    end
end

local function stopAutoLeaveGenerator()
    if LeaveGeneratorConnection then
        LeaveGeneratorConnection:Disconnect()
        LeaveGeneratorConnection = nil
    end
end

-- =============================================
-- AUTO ATAQUE CORRIGIDO (COM COOLDOWN)
-- =============================================
local function performAutoAttack()
    if not isKiller() then return end
    
    local now = tick()
    if now - lastAttackTime < Config.AutoFeatures.AttackCooldown then return end
    
    local hrp = getCharacterRootPart()
    if not hrp then return end
    
    local target = nil
    local targetDist = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
            local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local dist = (tHRP.Position - hrp.Position).Magnitude
                if dist <= Config.AutoFeatures.AttackRange and dist < targetDist then
                    target = player
                    targetDist = dist
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
                    local basicAttack = attacks:FindFirstChild("BasicAttack")
                    if basicAttack then
                        basicAttack:FireServer(false)
                        lastAttackTime = now
                    end
                end
            end
        end)
    end
end

local function startAutoAttack()
    if AutoAttackConnection then return end
    if not isKiller() then
        notify("Erro", "Você precisa ser o Assassino!", 3)
        return
    end
    AutoAttackConnection = RunService.Heartbeat:Connect(function()
        if Config.AutoFeatures.AutoAttack then performAutoAttack() end
    end)
    notify("Ataque Auto", "Alcance: " .. Config.AutoFeatures.AttackRange .. " studs", 3)
end

local function stopAutoAttack()
    if AutoAttackConnection then
        AutoAttackConnection:Disconnect()
        AutoAttackConnection = nil
    end
end

-- =============================================
-- ESP SIMPLES (SÓ CORES – SEM TEXTOS)
-- =============================================
local function createHighlight(obj, color)
    if not validateInstance(obj) then return end
    if obj:FindFirstChild("D") then return end
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
    if Highlights[obj] then
        safeCall(function() if validateInstance(Highlights[obj]) then Highlights[obj]:Destroy() end end)
        Highlights[obj] = nil
    end
    local existing = obj:FindFirstChild("D")
    if existing then existing:Destroy() end
end

local function clearAllESP()
    for obj, _ in pairs(Highlights) do removeHighlight(obj) end
    Highlights = {}
end

local function updateAllESP()
    local currentTime = tick()
    if currentTime - LastUpdate < Config.Performance.UpdateRate then return end
    LastUpdate = currentTime
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team then
            local teamName = player.Team.Name
            if teamName == "Killer" and Config.ESP.Killer then
                createHighlight(player.Character, Color3.fromRGB(255,0,0))
            elseif teamName == "Survivors" and Config.ESP.Survivor then
                createHighlight(player.Character, Color3.fromRGB(0,255,0))
            else
                removeHighlight(player.Character)
            end
        end
    end
end

local function startESP()
    if UpdateConnection then return end
    UpdateConnection = RunService.Heartbeat:Connect(updateAllESP)
    notify("ESP Iniciado", "Apenas cores (Vermelho/Verde)", 2)
end

local function stopESP()
    if UpdateConnection then
        UpdateConnection:Disconnect()
        UpdateConnection = nil
    end
    clearAllESP()
    notify("ESP Parado", "Destaques removidos", 2)
end

-- =============================================
-- OTIMIZAÇÕES
-- =============================================
local function applyMobileOptimizations()
    if not isMobile then return end
    safeCall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").FogEnd = 100
        for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
            if effect:IsA("PostEffect") then effect.Enabled = false end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
        Workspace.StreamingEnabled = true
        Workspace.StreamingMinRadius = 32
        Workspace.StreamingTargetRadius = 64
        if Workspace:FindFirstChild("Terrain") then Workspace.Terrain.Decoration = false end
    end)
end

-- =============================================
-- INTERFACE RAYFIELD
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "🎮 Abd Hub - Violence District",
    LoadingTitle = "Carregando Abd Hub...",
    LoadingSubtitle = "Compatível com Mobile",
    ConfigurationSaving = {Enabled = true, FolderName = nil, FileName = "AbdHubConfig"},
    Discord = {Enabled = false},
    KeySystem = false
})

-- Aba ESP (SIMPLES – SÓ CORES)
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
ESPTab:CreateSection("ESP Jogadores (Somente Cores)")
ESPTab:CreateToggle({Name = "Assassino (Vermelho)", CurrentValue = false, Flag = "KillerESP", Callback = function(v)
    Config.ESP.Killer = v
    if v or Config.ESP.Survivor then startESP() else stopESP() end
end})
ESPTab:CreateToggle({Name = "Sobrevivente (Verde)", CurrentValue = false, Flag = "SurvivorESP", Callback = function(v)
    Config.ESP.Survivor = v
    if v or Config.ESP.Killer then startESP() else stopESP() end
end})
ESPTab:CreateLabel("💡 Ative um dos dois para ver os jogadores destacados.")

-- Aba Jogo
local GameplayTab = Window:CreateTab("🎮 Jogo", 4483362458)
GameplayTab:CreateSection("Auto Gerador")
GameplayTab:CreateToggle({Name = "Auto Completar Geradores", CurrentValue = false, Flag = "AutoGenerator", Callback = function(v) Config.AutoFeatures.AutoGenerator = v; notify("Auto Gerador", v and "Ativado" or "Desativado", 2) end})
GameplayTab:CreateDropdown({Name = "Modo Gerador", Options = {"Ótimo (Rápido)", "Normal (Lento)"}, CurrentOption = "Ótimo (Rápido)", Flag = "GeneratorMode", Callback = function(o) Config.AutoFeatures.GeneratorMode = o:find("Ótimo") and "great" or "normal" end})
GameplayTab:CreateSection("Fuga Rápida")
GameplayTab:CreateToggle({Name = "Sair Gerador Rápido", CurrentValue = false, Flag = "AutoLeaveGenerator", Callback = function(v) Config.AutoFeatures.AutoLeaveGenerator = v; if v then startAutoLeaveGenerator() else stopAutoLeaveGenerator() end end})
if not isMobile then
    GameplayTab:CreateDropdown({Name = "Tecla para Sair", Options = {"Q","E","F","G","X","Z","V","B"}, CurrentOption = "Q", Flag = "LeaveKeybind", Callback = function(o) local map = {Q=Enum.KeyCode.Q, E=Enum.KeyCode.E, F=Enum.KeyCode.F, G=Enum.KeyCode.G, X=Enum.KeyCode.X, Z=Enum.KeyCode.Z, V=Enum.KeyCode.V, B=Enum.KeyCode.B}; Config.AutoFeatures.LeaveKeybind = map[o]; if Config.AutoFeatures.AutoLeaveGenerator then stopAutoLeaveGenerator(); startAutoLeaveGenerator() end end})
end
GameplayTab:CreateSlider({Name = "Distância de Detecção", Range = {5,30}, Increment = 1, CurrentValue = 15, Flag = "LeaveDistance", Callback = function(v) Config.AutoFeatures.LeaveDistance = v end})
GameplayTab:CreateButton({Name = "Sair Gerador Agora", Callback = leaveGenerator})
GameplayTab:CreateSection("Ações Manuais")
GameplayTab:CreateButton({Name = "Completar Todos Geradores (Instantâneo)", Callback = function()
    local map = Workspace:FindFirstChild("Map")
    if not map then notify("Erro", "Mapa não encontrado", 3) return end
    local completed = 0
    safeCall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local genRemotes = remotes:FindFirstChild("Generator")
        if not genRemotes then return end
        local repair = genRemotes:FindFirstChild("RepairEvent")
        local skill = genRemotes:FindFirstChild("SkillCheckResultEvent")
        if not repair or not skill then return end
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Generator" then
                for _, point in ipairs(obj:GetChildren()) do
                    if point.Name:find("GeneratorPoint") then
                        pcall(function()
                            for _ = 1, 10 do
                                repair:FireServer(point, true)
                                skill:FireServer("success", 1, obj, point)
                            end
                            completed = completed + 1
                        end)
                    end
                end
            end
        end
    end)
    if completed > 0 then notify("Completo!", string.format("%d gerador(es) completos", completed), 4) else notify("Falha", "Nenhum gerador encontrado", 3) end
end})
GameplayTab:CreateSection("Poderes do Assassino")
GameplayTab:CreateToggle({Name = "Auto Atacar Sobreviventes", CurrentValue = false, Flag = "AutoAttack", Callback = function(v)
    Config.AutoFeatures.AutoAttack = v
    if v then startAutoAttack() else stopAutoAttack() end
end})
GameplayTab:CreateSlider({Name = "Alcance do Ataque", Range = {5,20}, Increment = 1, CurrentValue = 10, Flag = "AttackRange", Callback = function(v) Config.AutoFeatures.AttackRange = v end})
GameplayTab:CreateSlider({Name = "Cooldown do Ataque (s)", Range = {0.1, 1.0}, Increment = 0.1, CurrentValue = 0.3, Flag = "AttackCooldown", Callback = function(v) Config.AutoFeatures.AttackCooldown = v end})
GameplayTab:CreateButton({Name = "Ativar Poder do Assassino", Callback = function()
    safeCall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local killerRemotes = remotes:FindFirstChild("Killers")
            if killerRemotes then
                local killerFolder = killerRemotes:FindFirstChild("Killer")
                if killerFolder then
                    local activate = killerFolder:FindFirstChild("ActivatePower")
                    if activate then activate:FireServer(); notify("Poder Ativado", "Poder do assassino acionado", 2) end
                end
            end
        end
    end)
end})
GameplayTab:CreateButton({Name = "Ataque Básico (Assassino)", Callback = function()
    safeCall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local attacks = remotes:FindFirstChild("Attacks")
            if attacks then
                local basic = attacks:FindFirstChild("BasicAttack")
                if basic then basic:FireServer(false); notify("Ataque", "Ataque básico executado", 2) end
            end
        end
    end)
end})

-- Aba Teleporte
local TeleportTab = Window:CreateTab("🚀 Teleporte", 4483362458)
TeleportTab:CreateSection("Teleporte para Gerador")
TeleportTab:CreateButton({Name = "Teleportar para Mais Próximo", Callback = function()
    local gens = getGeneratorsByDistance()
    if #gens == 0 then notify("Não Encontrado", "Nenhum gerador no mapa", 3) return end
    if safeTeleport(gens[1].part.CFrame) then notify("Teleportado!", string.format("Mais próximo (%.0fm)", gens[1].distance), 3) end
end})
TeleportTab:CreateButton({Name = "Teleportar para Mais Distante", Callback = function()
    local gens = getGeneratorsByDistance()
    if #gens == 0 then notify("Não Encontrado", "Nenhum gerador no mapa", 3) return end
    local far = gens[#gens]
    if safeTeleport(far.part.CFrame) then notify("Teleportado!", string.format("Mais distante (%.0fm)", far.distance), 3) end
end})
TeleportTab:CreateButton({Name = "Teleportar por Todos Geradores", Callback = function()
    local gens = getGeneratorsByDistance()
    if #gens == 0 then notify("Não Encontrado", "Nenhum gerador no mapa", 3) return end
    notify("Iniciando", string.format("Teleportando por %d geradores...", #gens), 3)
    task.spawn(function()
        for i, gen in ipairs(gens) do
            if not getCharacterRootPart() then break end
            safeTeleport(gen.part.CFrame)
            notify("Gerador " .. i, string.format("%d/%d (%.0fm)", i, #gens, gen.distance), 2)
            task.wait(Config.Teleportation.TeleportDelay)
        end
        notify("Completo!", "Visitou todos os geradores", 3)
    end)
end})
TeleportTab:CreateSection("Configurações Teleporte")
TeleportTab:CreateSlider({Name = "Altura do Teleporte", Range = {0,10}, Increment = 1, CurrentValue = 3, Flag = "TeleportOffset", Callback = function(v) Config.Teleportation.TeleportOffset = v end})
TeleportTab:CreateSlider({Name = "Delay Multi-Teleporte", Range = {0.1,5}, Increment = 0.1, CurrentValue = 0.1, Flag = "TeleportDelay", Callback = function(v) Config.Teleportation.TeleportDelay = v end})
TeleportTab:CreateToggle({Name = "Teleporte Seguro", CurrentValue = true, Flag = "SafeTeleport", Callback = function(v) Config.Teleportation.SafeTeleport = v end})

-- Aba Proteção
local MyTab = Window:CreateTab("🛡️ Proteção", 4483362458)
MyTab:CreateSection("⚡ Velocidade")
MyTab:CreateSlider({Name = "Velocidade (16-100)", Range = {16, 100}, Increment = 1, CurrentValue = 16, Flag = "SpeedSlider", Callback = function(v) Config.MyFeatures.Speed = v; applySpeed() end})
MyTab:CreateSection("🚪 Atravessar")
MyTab:CreateToggle({Name = "Atravessar Paredes (Noclip)", CurrentValue = false, Flag = "NoclipToggle", Callback = function(v) Config.MyFeatures.Noclip = v; applyNoclip() end})
MyTab:CreateSection("💀 Anti-Morte")
MyTab:CreateToggle({Name = "Anti-Morte (Não Morre)", CurrentValue = false, Flag = "AntiDeathToggle", Callback = function(v) Config.MyFeatures.AntiDeath = v; if v then startAntiDeath() elseif antiDeathLoop then antiDeathLoop:Disconnect() end end})
MyTab:CreateSection("♾️ Deus")
MyTab:CreateToggle({Name = "Deus (Vida Infinita)", CurrentValue = false, Flag = "GodmodeToggle", Callback = function(v) Config.MyFeatures.Godmode = v; if v then startGodmode() elseif godLoop then godLoop:Disconnect() end end})
MyTab:CreateSection("🩸 Regeneração")
MyTab:CreateToggle({Name = "Regeneração Automática", CurrentValue = false, Flag = "RegenToggle", Callback = function(v) Config.MyFeatures.Regen = v; if v then startRegen() elseif regenLoop then regenLoop:Disconnect() end end})
MyTab:CreateSlider({Name = "Velocidade da Regeneração (1-20 HP/s)", Range = {1, 20}, Increment = 1, CurrentValue = 5, Flag = "RegenSpeedSlider", Callback = function(v) Config.MyFeatures.RegenSpeed = v end})
MyTab:CreateSection("🛡️ Anti-Knockback")
MyTab:CreateToggle({Name = "Anti-Knockback (Não Ser Empurrado)", CurrentValue = false, Flag = "AntiKBToggle", Callback = function(v) Config.MyFeatures.AntiKnockback = v; if v then startAntiKB() elseif antiKBLoop then antiKBLoop:Disconnect() end end})
MyTab:CreateSection("⛔ Anti-Queda")
MyTab:CreateToggle({Name = "Anti-Queda (Não Cair / Ragdoll)", CurrentValue = false, Flag = "AntiStunToggle", Callback = function(v) Config.MyFeatures.AntiStun = v; if v then startAntiStun() elseif antiStunLoop then antiStunLoop:Disconnect() end end})

-- =============================================
-- LOOP AUTO GERADOR
-- =============================================
task.spawn(function()
    while task.wait(0.2) do
        if Config.AutoFeatures.AutoGenerator then
            safeCall(function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if not remotes then return end
                local genRemotes = remotes:FindFirstChild("Generator")
                if not genRemotes then return end
                local repair = genRemotes:FindFirstChild("RepairEvent")
                local skill = genRemotes:FindFirstChild("SkillCheckResultEvent")
                if not repair or not skill then return end
                local map = Workspace:FindFirstChild("Map")
                if not map then return end
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == "Generator" then
                        for _, point in ipairs(obj:GetChildren()) do
                            if point.Name:find("GeneratorPoint") then
                                pcall(function()
                                    repair:FireServer(point, true)
                                    local result = Config.AutoFeatures.GeneratorMode == "great" and "success" or "neutral"
                                    local value = Config.AutoFeatures.GeneratorMode == "great" and 1 or 0
                                    skill:FireServer(result, value, obj, point)
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- =============================================
-- INICIALIZAR
-- =============================================
updateMyFeatures()

if isMobile then
    task.wait(0.5)
    applyMobileOptimizations()
end

notify("Abd Hub", "Carregado com sucesso!", 4)
print("========================================")
print("✅ ABD HUB – ESP só cores + Ataque corrigido")
print("📱 Mobile:", isMobile and "SIM" or "NÃO")
print("👁️ ESP: Apenas cores (sem textos)")
print("⚔️ Auto Ataque com cooldown ajustável")
print("========================================")
