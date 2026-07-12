--[[ ABD HUB – Violence District + Extras (Português) ]]
-- Apenas textos da interface traduzidos. Código Roblox mantido em inglês.

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
-- CONFIGURAÇÕES (tudo em inglês para o Roblox)
-- =============================================
local Config = {
    ESP = {
        Killer = false,
        Survivor = false,
        Generator = false,
        Gate = false,
        Hook = false,
        Pallet = false,
        Window = false,
        Pumpkin = false,
        ShowOnlyClosestHook = false,
        ShowDistance = true,
        MaxDistance = 500
    },
    AutoFeatures = {
        AutoGenerator = false,
        GeneratorMode = "great",
        AutoLeaveGenerator = false,
        LeaveDistance = 15,
        LeaveKeybind = Enum.KeyCode.Q,
        AutoAttack = false,
        AttackRange = 10
    },
    Teleportation = {
        TeleportOffset = 3,
        SafeTeleport = true,
        TeleportDelay = 0.1
    },
    Performance = {
        UpdateRate = 0.5,
        UseDistanceCulling = true,
        MaxESPObjects = isMobile and 50 or 100,
        DisableParticles = false,
        LowerGraphics = false,
        DisableShadows = false,
        ReduceRenderDistance = false
    },
    Mobile = {
        TouchControlsEnabled = isMobile,
        ButtonSize = 80,
        ButtonTransparency = 0.3,
        AutoOptimize = true,
        AggressiveOptimization = false
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
local BillboardGuis = {}
local LastUpdate = 0
local UpdateConnection = nil
local LeaveGeneratorConnection = nil
local AutoAttackConnection = nil
local MobileUI = nil
local FPSCounterUI = nil
local FPSCounterEnabled = false

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
-- MINHAS FUNÇÕES EXTRAS (NOMES EM INGLÊS)
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
-- FUNÇÕES DO JOGO (Violence District)
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
        notify("Modo Mobile", "Use o botão SAIR", 3)
    end
end

local function stopAutoLeaveGenerator()
    if LeaveGeneratorConnection then
        LeaveGeneratorConnection:Disconnect()
        LeaveGeneratorConnection = nil
    end
end

local function performAutoAttack()
    if not isKiller() then return end
    local hrp = getCharacterRootPart()
    if not hrp then return end
    local target
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team and player.Team.Name == "Survivors" and player.Character then
            local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local dist = (tHRP.Position - hrp.Position).Magnitude
                if dist <= Config.AutoFeatures.AttackRange then
                    target = player
                    break
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
                    if basicAttack then basicAttack:FireServer(false) end
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
-- ESP (tudo em inglês para o Roblox)
-- =============================================
local function createHighlight(obj, color)
    if not validateInstance(obj) or obj:FindFirstChild("H") then return end
    safeCall(function()
        local h = Instance.new("Highlight")
        h.Name = "H"
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
    local existingH = obj:FindFirstChild("H")
    if existingH then existingH:Destroy() end
end

local function createLabel(obj, text, color)
    if not validateInstance(obj) then return end
    local rootPart = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or (obj:IsA("BasePart") and obj)
    if not rootPart then return end
    local playerRoot = getCharacterRootPart()
    if not playerRoot then return end
    local distance = (playerRoot.Position - rootPart.Position).Magnitude
    if Config.Performance.UseDistanceCulling and distance > Config.ESP.MaxDistance then
        if BillboardGuis[obj] then
            safeCall(function() if validateInstance(BillboardGuis[obj]) then BillboardGuis[obj]:Destroy() end end)
            BillboardGuis[obj] = nil
        end
        return
    end
    if BillboardGuis[obj] and validateInstance(BillboardGuis[obj]) then
        local textLabel = BillboardGuis[obj]:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.Text = Config.ESP.ShowDistance and string.format("%s\n%.0fm", text, distance) or text
        end
        return
    end
    safeCall(function()
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = rootPart
        billboard.Parent = obj
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = color
        textLabel.TextStrokeColor3 = Color3.new(0,0,0)
        textLabel.TextStrokeTransparency = 0
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextScaled = true
        textLabel.Text = Config.ESP.ShowDistance and string.format("%s\n%.0fm", text, distance) or text
        textLabel.Parent = billboard
        BillboardGuis[obj] = billboard
    end)
end

local function removeLabel(obj)
    if BillboardGuis[obj] then
        safeCall(function() if validateInstance(BillboardGuis[obj]) then BillboardGuis[obj]:Destroy() end end)
        BillboardGuis[obj] = nil
    end
end

local function clearAllESP()
    for obj, _ in pairs(Highlights) do removeHighlight(obj) end
    for obj, _ in pairs(BillboardGuis) do removeLabel(obj) end
    Highlights = {}
    BillboardGuis = {}
end

local function updatePlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Team then
            local teamName = player.Team.Name
            if teamName == "Killer" and Config.ESP.Killer then
                createHighlight(player.Character, Color3.fromRGB(255,0,0))
                createLabel(player.Character, player.Name .. "\n[ASSASSINO]", Color3.fromRGB(255,0,0))
            elseif teamName == "Survivors" and Config.ESP.Survivor then
                createHighlight(player.Character, Color3.fromRGB(0,255,0))
                createLabel(player.Character, player.Name .. "\n[SOBREVIVENTE]", Color3.fromRGB(0,255,0))
            else
                removeHighlight(player.Character)
                removeLabel(player.Character)
            end
        end
    end
end

local function updateGeneratorESP()
    if not Config.ESP.Generator then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            createHighlight(obj, Color3.fromRGB(203,132,66))
            createLabel(obj, "Gerador", Color3.fromRGB(203,132,66))
        end
    end
end

local function updateGateESP()
    if not Config.ESP.Gate then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Gate" then
            createHighlight(obj, Color3.fromRGB(255,255,255))
            createLabel(obj, "Portão", Color3.fromRGB(255,255,255))
        end
    end
end

local function updateHookESP()
    if not Config.ESP.Hook then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    if Config.ESP.ShowOnlyClosestHook then
        local hrp = getCharacterRootPart()
        if hrp then
            local closestHook, closestDist
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    local hookPart = obj:FindFirstChildWhichIsA("BasePart")
                    if hookPart then
                        local dist = (hookPart.Position - hrp.Position).Magnitude
                        if dist < (closestDist or math.huge) then
                            closestDist = dist
                            closestHook = obj
                        end
                    end
                end
            end
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Hook" then
                    removeHighlight(obj)
                    removeLabel(obj)
                end
            end
            if closestHook then
                if closestHook:FindFirstChild("Model") then
                    for _, part in ipairs(closestHook.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then
                            createHighlight(part, Color3.fromRGB(255,255,0))
                        end
                    end
                end
                createLabel(closestHook, "GANCHO MAIS PRÓXIMO", Color3.fromRGB(255,255,0))
            end
        end
    else
        for _, obj in ipairs(map:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == "Hook" then
                if obj:FindFirstChild("Model") then
                    for _, part in ipairs(obj.Model:GetDescendants()) do
                        if part:IsA("MeshPart") then
                            createHighlight(part, Color3.fromRGB(255,0,0))
                        end
                    end
                end
                createLabel(obj, "Gancho", Color3.fromRGB(255,0,0))
            end
        end
    end
end

local function updatePalletESP()
    if not Config.ESP.Pallet then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Palletwrong" then
            createHighlight(obj, Color3.fromRGB(255,255,0))
            createLabel(obj, "Palete", Color3.fromRGB(255,255,0))
        end
    end
end

local function updateWindowESP()
    if not Config.ESP.Window then return end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Window" then
            createHighlight(obj, Color3.fromRGB(173,216,230))
            createLabel(obj, "Janela", Color3.fromRGB(173,216,230))
        end
    end
end

local function updatePumpkinESP()
    if not Config.ESP.Pumpkin then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local pumpkins = map:FindFirstChild("Pumpkins")
    if not pumpkins then return end
    for _, obj in ipairs(pumpkins:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Pumpkin") then
            createHighlight(obj, Color3.fromRGB(255,140,0))
            createLabel(obj, "Abóbora", Color3.fromRGB(255,140,0))
        end
    end
end

local function updateAllESP()
    local currentTime = tick()
    if currentTime - LastUpdate < Config.Performance.UpdateRate then return end
    LastUpdate = currentTime
    local espCount = 0
    for obj, h in pairs(Highlights) do
        if not validateInstance(obj) or not validateInstance(h) then
            Highlights[obj] = nil
        else
            espCount = espCount + 1
        end
    end
    for obj, gui in pairs(BillboardGuis) do
        if not validateInstance(obj) or not validateInstance(gui) then
            BillboardGuis[obj] = nil
        end
    end
    if espCount >= Config.Performance.MaxESPObjects then return end
    updatePlayerESP()
    updateGeneratorESP()
    updateGateESP()
    updateHookESP()
    updatePalletESP()
    updateWindowESP()
    updatePumpkinESP()
end

local function startESP()
    if UpdateConnection then return end
    UpdateConnection = RunService.Heartbeat:Connect(updateAllESP)
    notify("ESP Iniciado", "Todos os ESP ativados", 2)
end

local function stopESP()
    if UpdateConnection then
        UpdateConnection:Disconnect()
        UpdateConnection = nil
    end
    clearAllESP()
    notify("ESP Parado", "Todos os ESP desativados", 2)
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

local function applyPerformanceSettings()
    if Config.Performance.DisableParticles then
        safeCall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Enabled = false
                end
            end
        end)
    end
    if Config.Performance.LowerGraphics then
        safeCall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    end
    if Config.Performance.DisableShadows then
        safeCall(function() game:GetService("Lighting").GlobalShadows = false end)
    end
    if Config.Performance.ReduceRenderDistance then
        safeCall(function()
            Workspace.StreamingEnabled = true
            Workspace.StreamingMinRadius = 32
            Workspace.StreamingTargetRadius = 64
        end)
    end
end

local function resetPerformanceSettings()
    safeCall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = true
            end
        end
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        game:GetService("Lighting").GlobalShadows = true
        game:GetService("Lighting").FogEnd = 100000
        for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
            if effect:IsA("PostEffect") then effect.Enabled = true end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then obj.Transparency = 0 end
        end
    end)
end

-- =============================================
-- CONTROLES MÓVEIS
-- =============================================
local function createMobileControls()
    if not isMobile or MobileUI then return end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileControls"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local leaveBtn = Instance.new("TextButton")
    leaveBtn.Size = UDim2.new(0, Config.Mobile.ButtonSize, 0, Config.Mobile.ButtonSize)
    leaveBtn.Position = UDim2.new(1, -100, 0.5, -40)
    leaveBtn.BackgroundColor3 = Color3.fromRGB(255,100,100)
    leaveBtn.BackgroundTransparency = Config.Mobile.ButtonTransparency
    leaveBtn.Text = "SAIR"
    leaveBtn.TextScaled = true
    leaveBtn.Font = Enum.Font.GothamBold
    leaveBtn.Parent = screenGui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,10)
    corner.Parent = leaveBtn
    leaveBtn.MouseButton1Click:Connect(leaveGenerator)
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, Config.Mobile.ButtonSize, 0, Config.Mobile.ButtonSize)
    tpBtn.Position = UDim2.new(1, -100, 0.5, 60)
    tpBtn.BackgroundColor3 = Color3.fromRGB(100,150,255)
    tpBtn.BackgroundTransparency = Config.Mobile.ButtonTransparency
    tpBtn.Text = "TP GER"
    tpBtn.TextScaled = true
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.Parent = screenGui
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0,10)
    corner2.Parent = tpBtn
    tpBtn.MouseButton1Click:Connect(function()
        local gens = getGeneratorsByDistance()
        if #gens > 0 then safeTeleport(gens[1].part.CFrame); notify("Teleportado!", "Gerador mais próximo", 2) end
    end)
    MobileUI = screenGui
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

-- Aba ESP
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)
ESPTab:CreateSection("ESP Jogadores")
ESPTab:CreateToggle({Name = "Assassino (Vermelho)", CurrentValue = false, Flag = "KillerESP", Callback = function(v) Config.ESP.Killer = v; if v then startESP() else for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character and p.Team and p.Team.Name == "Killer" then removeHighlight(p.Character); removeLabel(p.Character) end end end end})
ESPTab:CreateToggle({Name = "Sobrevivente (Verde)", CurrentValue = false, Flag = "SurvivorESP", Callback = function(v) Config.ESP.Survivor = v; if v then startESP() else for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character and p.Team and p.Team.Name == "Survivors" then removeHighlight(p.Character); removeLabel(p.Character) end end end end})
ESPTab:CreateSection("ESP Objetos")
ESPTab:CreateToggle({Name = "Gerador (Laranja)", CurrentValue = false, Flag = "GeneratorESP", Callback = function(v) Config.ESP.Generator = v; if v then startESP() else local map = Workspace:FindFirstChild("Map"); if map then for _, obj in ipairs(map:GetDescendants()) do if obj:IsA("Model") and obj.Name == "Generator" then removeHighlight(obj); removeLabel(obj) end end end end end})
ESPTab:CreateToggle({Name = "Portão (Branco)", CurrentValue = false, Flag = "GateESP", Callback = function(v) Config.ESP.Gate = v; if v then startESP() end end})
ESPTab:CreateToggle({Name = "Gancho (Vermelho)", CurrentValue = false, Flag = "HookESP", Callback = function(v) Config.ESP.Hook = v; if v then startESP() else local map = Workspace:FindFirstChild("Map"); if map then for _, obj in ipairs(map:GetDescendants()) do if obj:IsA("Model") and obj.Name == "Hook" then removeHighlight(obj); removeLabel(obj) end end end end end})
ESPTab:CreateToggle({Name = "Mostrar Só Gancho Mais Próximo", CurrentValue = false, Flag = "ShowOnlyClosestHook", Callback = function(v) Config.ESP.ShowOnlyClosestHook = v; if Config.ESP.Hook then updateHookESP() end end})
ESPTab:CreateToggle({Name = "Palete (Amarelo)", CurrentValue = false, Flag = "PalletESP", Callback = function(v) Config.ESP.Pallet = v; if v then startESP() end end})
ESPTab:CreateToggle({Name = "Janela (Azul Claro)", CurrentValue = false, Flag = "WindowESP", Callback = function(v) Config.ESP.Window = v; if v then startESP() end end})
ESPTab:CreateToggle({Name = "Abóbora (Laranja)", CurrentValue = false, Flag = "PumpkinESP", Callback = function(v) Config.ESP.Pumpkin = v; if v then startESP() end end})
ESPTab:CreateSection("Configurações")
ESPTab:CreateToggle({Name = "Mostrar Distância", CurrentValue = true, Flag = "ShowDistance", Callback = function(v) Config.ESP.ShowDistance = v end})
ESPTab:CreateSlider({Name = "Distância Máxima", Range = {100, 1000}, Increment = 50, CurrentValue = 500, Flag = "MaxDistance", Callback = function(v) Config.ESP.MaxDistance = v end})
ESPTab:CreateSlider({Name = "Taxa de Atualização", Range = {0.1, 2}, Increment = 0.1, CurrentValue = 0.5, Flag = "UpdateRate", Callback = function(v) Config.Performance.UpdateRate = v end})
ESPTab:CreateSlider({Name = "Máx Objetos ESP", Range = {25, 500}, Increment = 25, CurrentValue = isMobile and 50 or 100, Flag = "MaxESPObjects", Callback = function(v) Config.Performance.MaxESPObjects = v end})

-- Aba Jogo
local GameplayTab = Window:CreateTab("🎮 Jogo", 4483362458)
GameplayTab:CreateSection("Auto")
GameplayTab:CreateToggle({Name = "Auto Completar Geradores", CurrentValue = false, Flag = "AutoGenerator", Callback = function(v) Config.AutoFeatures.AutoGenerator = v; notify("Auto Gerador", v and "Ativado" or "Desativado", 2) end})
GameplayTab:CreateDropdown({Name = "Modo Gerador", Options = {"Ótimo (Rápido)", "Normal (Lento)"}, CurrentOption = "Ótimo (Rápido)", Flag = "GeneratorMode", Callback = function(o) Config.AutoFeatures.GeneratorMode = o:find("Ótimo") and "great" or "normal" end})
GameplayTab:CreateSection("Fuga Rápida")
GameplayTab:CreateToggle({Name = "Habilitar Sair Gerador Rápido", CurrentValue = false, Flag = "AutoLeaveGenerator", Callback = function(v) Config.AutoFeatures.AutoLeaveGenerator = v; if v then startAutoLeaveGenerator() else stopAutoLeaveGenerator() end end})
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
GameplayTab:CreateToggle({Name = "Auto Atacar Sobreviventes Próximos", CurrentValue = false, Flag = "AutoAttack", Callback = function(v) Config.AutoFeatures.AutoAttack = v; if v then startAutoAttack() else stopAutoAttack() end end})
GameplayTab:CreateSlider({Name = "Alcance do Auto Ataque", Range = {5,20}, Increment = 1, CurrentValue = 10, Flag = "AttackRange", Callback = function(v) Config.AutoFeatures.AttackRange = v end})
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
TeleportTab:CreateButton({Name = "Teleportar para Gerador Mais Próximo", Callback = function()
    local gens = getGeneratorsByDistance()
    if #gens == 0 then notify("Não Encontrado", "Nenhum gerador no mapa", 3) return end
    if safeTeleport(gens[1].part.CFrame) then notify("Teleportado!", string.format("Mais próximo (%.0fm)", gens[1].distance), 3) end
end})
TeleportTab:CreateButton({Name = "Teleportar para Gerador Mais Distante", Callback = function()
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
TeleportTab:CreateButton({Name = "Mostrar Lista de Geradores (Console)", Callback = function()
    local gens = getGeneratorsByDistance()
    if #gens == 0 then notify("Não Encontrado", "Nenhum gerador", 3) return end
    print("\n=== LISTA DE GERADORES ===")
    for i, gen in ipairs(gens) do
        print(string.format("%d. Gerador a %.0fm - Posição: %s", i, gen.distance, tostring(gen.position)))
    end
    print("============================\n")
    notify("Lista Impressa", string.format("%d geradores encontrados", #gens), 3)
end})
TeleportTab:CreateSection("Outros Teleportes")
TeleportTab:CreateButton({Name = "Teleportar para Portão Mais Próximo", Callback = function()
    local hrp = getCharacterRootPart()
    if not hrp then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local nearestGate, nearestDist
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Gate" then
            local gatePart = obj:FindFirstChildWhichIsA("BasePart")
            if gatePart then
                local dist = (gatePart.Position - hrp.Position).Magnitude
                if dist < (nearestDist or math.huge) then
                    nearestDist = dist
                    nearestGate = gatePart
                end
            end
        end
    end
    if nearestGate then safeTeleport(nearestGate.CFrame); notify("Teleportado", string.format("Portão (%.0fm)", nearestDist), 3) else notify("Não Encontrado", "Nenhum portão encontrado", 3) end
end})
TeleportTab:CreateSection("Fuga do Sobrevivente")
TeleportTab:CreateButton({Name = "Escapar do Jogo (Sobrevivente)", Callback = function()
    if not isSurvivor() then notify("Erro", "Você precisa ser Sobrevivente!", 3) return end
    local hrp = getCharacterRootPart()
    if not hrp then return end
    local map = Workspace:FindFirstChild("Map")
    if not map then return end
    local gate
    for _, obj in ipairs(map:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Gate" then gate = obj; break end
    end
    if not gate then notify("Erro", "Nenhum portão encontrado", 3) return end
    local escapeZone = gate:FindFirstChild("Escape") or gate:FindFirstChildWhichIsA("BasePart")
    if escapeZone then
        safeTeleport(escapeZone.CFrame, Vector3.new(0,5,0))
        task.wait(0.5)
        safeCall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local gateRemote = remotes:FindFirstChild("Gate")
                if gateRemote then
                    local escapeEvent = gateRemote:FindFirstChild("Escape")
                    if escapeEvent then escapeEvent:FireServer() end
                end
            end
        end)
        notify("Fuga!", "Teleportado para a saída", 4)
    else
        notify("Erro", "Não foi possível encontrar zona de saída", 3)
    end
end})
TeleportTab:CreateSection("Configurações Teleporte")
TeleportTab:CreateSlider({Name = "Altura do Teleporte", Range = {0,10}, Increment = 1, CurrentValue = 3, Flag = "TeleportOffset", Callback = function(v) Config.Teleportation.TeleportOffset = v end})
TeleportTab:CreateSlider({Name = "Delay Multi-Teleporte", Range = {0.1,5}, Increment = 0.1, CurrentValue = 0.1, Flag = "TeleportDelay", Callback = function(v) Config.Teleportation.TeleportDelay = v end})
TeleportTab:CreateToggle({Name = "Teleporte Seguro", CurrentValue = true, Flag = "SafeTeleport", Callback = function(v) Config.Teleportation.SafeTeleport = v end})

-- Aba Configurações
local SettingsTab = Window:CreateTab("⚙️ Configurações", 4483362458)
SettingsTab:CreateSection("Desempenho")
SettingsTab:CreateToggle({Name = "Desabilitar Partículas", CurrentValue = false, Flag = "DisableParticles", Callback = function(v) Config.Performance.DisableParticles = v; applyPerformanceSettings() end})
SettingsTab:CreateToggle({Name = "Gráficos Baixos", CurrentValue = false, Flag = "LowerGraphics", Callback = function(v) Config.Performance.LowerGraphics = v; applyPerformanceSettings() end})
SettingsTab:CreateToggle({Name = "Desabilitar Sombras", CurrentValue = false, Flag = "DisableShadows", Callback = function(v) Config.Performance.DisableShadows = v; applyPerformanceSettings() end})
SettingsTab:CreateToggle({Name = "Reduzir Distância de Render", CurrentValue = false, Flag = "ReduceRenderDistance", Callback = function(v) Config.Performance.ReduceRenderDistance = v; applyPerformanceSettings() end})
SettingsTab:CreateButton({Name = "Resetar Desempenho", Callback = function()
    Config.Performance.DisableParticles = false
    Config.Performance.LowerGraphics = false
    Config.Performance.DisableShadows = false
    Config.Performance.ReduceRenderDistance = false
    resetPerformanceSettings()
    notify("Desempenho", "Redefinido para padrão", 2)
end})

if isMobile then
    SettingsTab:CreateSection("Controles Mobile")
    SettingsTab:CreateToggle({Name = "Habilitar Controles de Toque", CurrentValue = true, Flag = "TouchControls", Callback = function(v)
        if v then createMobileControls() elseif MobileUI then MobileUI:Destroy(); MobileUI = nil end
    end})
    SettingsTab:CreateSlider({Name = "Tamanho do Botão", Range = {60,120}, Increment = 10, CurrentValue = 80, Flag = "ButtonSize", Callback = function(v)
        Config.Mobile.ButtonSize = v
        if MobileUI then MobileUI:Destroy(); createMobileControls() end
    end})
    SettingsTab:CreateSlider({Name = "Transparência do Botão", Range = {0,0.8}, Increment = 0.1, CurrentValue = 0.3, Flag = "ButtonTransparency", Callback = function(v)
        Config.Mobile.ButtonTransparency = v
        if MobileUI then
            for _, btn in ipairs(MobileUI:GetChildren()) do
                if btn:IsA("TextButton") then btn.BackgroundTransparency = v end
            end
        end
    end})
end

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
-- LOOP AUTO GENERATOR
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
    task.wait(1)
    createMobileControls()
    if Config.Mobile.AutoOptimize then
        task.wait(0.5)
        applyMobileOptimizations()
    end
end

notify("Abd Hub", "Carregado com sucesso!", 4)
print("✅ ABD HUB – Violence District + Extras")
print("📱 Mobile:", isMobile and "SIM" or "NÃO")
print("🛡️ Aba 'Proteção' com funções extras")
