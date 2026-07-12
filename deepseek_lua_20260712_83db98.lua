--[[ ABD HUB – COMPLETO (RAYFIELD) ]]

print("🚀 Iniciando Abd Hub...")

local function detectarMobile()
    local a = game:GetService("UserInputService")
    local b = a.TouchEnabled
    local c = workspace.CurrentCamera
    local d = c and c.ViewportSize or Vector2.new(0, 0)
    local e = d.X <= 1024 or d.Y <= 768
    local f = a.GyroscopeEnabled or a.AccelerometerEnabled
    local g = not a.KeyboardEnabled
    local h = identifyexecutor and identifyexecutor() or "Desconhecido"
    local i = h:lower():find("delta") or h:lower():find("arceus") or h:lower():find("fluxus") or h:lower():find("krnl")
    local j = b and (g or e or f or i)
    if b and i then j = true end
    return j
end

local isMobile = detectarMobile()
local nomeExecutor = identifyexecutor and identifyexecutor() or "Desconhecido"

print("✅ Mobile:", isMobile)
print("✅ Executor:", nomeExecutor)

local function httpSeguro(u)
    local s, r
    if game.HttpGet then
        s, r = pcall(function() return game:HttpGet(u) end)
        if s then return r end
    end
    if syn and syn.request then
        s, r = pcall(function() return syn.request({Url = u, Method = "GET"}).Body end)
        if s then return r end
    end
    if http and http.request then
        s, r = pcall(function() return http.request({Url = u, Method = "GET"}).Body end)
        if s then return r end
    end
    if http_request then
        s, r = pcall(function() return http_request({Url = u, Method = "GET"}).Body end)
        if s then return r end
    end
    if request then
        s, r = pcall(function() return request({Url = u, Method = "GET"}).Body end)
        if s then return r end
    end
    error("Falha ao carregar URL: " .. u)
end

local Rayfield
print("📥 Carregando Rayfield...")
pcall(function()
    Rayfield = loadstring(httpSeguro('https://sirius.menu/rayfield'))()
end)
if not Rayfield then
    pcall(function()
        Rayfield = loadstring(httpSeguro('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
end
if not Rayfield then
    error("Falha ao carregar Rayfield")
end
print("✅ Rayfield carregado!")

local P = game:GetService("Players")
local W = game:GetService("Workspace")
local R = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local U = game:GetService("UserInputService")
local L = P.LocalPlayer

-- CONFIGURAÇÕES
local C = {
    ESP = {
        Assassino = false,
        Sobrevivente = false,
    },
    Auto = {
        AutoGerador = false,
        ModoGerador = "otimo",
        AutoSairGerador = false,
        DistanciaSair = 15,
        TeclaSair = Enum.KeyCode.Q,
        AutoAtaque = false,
        AlcanceAtaque = 10,
    },
    Teleporte = {
        AlturaOffset = 3,
        TeleporteSeguro = true,
        DelayTeleporte = 0.1,
    },
    Extra = {
        Velocidade = 16,
        AtravessarParedes = false,
        AntiMorte = false,
        Deus = false,
        Regenerar = false,
        VelocidadeRegen = 5,
        AntiKnockback = false,
        AntiQueda = false,
    }
}

-- VARIÁVEIS
local Destaques = {}
local ConexaoESP = nil
local meuChar = L.Character or L.CharacterAdded:Wait()
local loopRegen, loopDeus, loopAntiKB, loopAntiQueda, loopAntiMorte
local ConexaoSairGerador = nil
local ConexaoAtaqueAuto = nil

local function notificar(t, c, dur)
    pcall(function()
        Rayfield:Notify({Titulo = t, Conteudo = c, Duracao = dur or 3, Imagem = 4483362458})
    end)
end

local function chamarSeguro(f, ...)
    local s, r = pcall(f, ...)
    return s and r or nil
end

local function valido(i)
    return i and typeof(i) == "Instance" and i.Parent ~= nil
end

local function ehAssassino()
    return L.Team and L.Team.Name == "Killer"
end

local function ehSobrevivente()
    return L.Team and L.Team.Name == "Survivors"
end

local function pegarRaiz()
    return L.Character and L.Character:FindFirstChild("HumanoidRootPart")
end

-- FUNÇÕES EXTRAS
local function aplicarVelocidade()
    local h = meuChar:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = C.Extra.Velocidade end
end

local function aplicarAtravessar()
    if not meuChar then return end
    for _, p in ipairs(meuChar:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = not C.Extra.AtravessarParedes
        end
    end
end

local function iniciarAntiMorte()
    if loopAntiMorte then loopAntiMorte:Disconnect() end
    loopAntiMorte = R.Heartbeat:Connect(function()
        if C.Extra.AntiMorte and meuChar then
            local h = meuChar:FindFirstChildOfClass("Humanoid")
            if h then
                if h.Health <= 0 then
                    h.Health = h.MaxHealth
                    h:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                if h:GetState() == Enum.HumanoidStateType.Dead then
                    h:ChangeState(Enum.HumanoidStateType.GettingUp)
                    h.Health = h.MaxHealth
                end
            end
            for _, c in ipairs(meuChar:GetChildren()) do
                if c:IsA("Script") or c:IsA("LocalScript") then
                    c.Disabled = true
                end
            end
            local r = meuChar:FindFirstChild("HumanoidRootPart")
            if r then
                for _, c in ipairs(r:GetDescendants()) do
                    if c:IsA("Attachment") or c:IsA("RopeConstraint") then
                        c:Destroy()
                    end
                end
            end
            if not meuChar.Parent then
                local nc = L.Character
                if nc then meuChar = nc end
            end
        end
    end)
end

local function iniciarDeus()
    if loopDeus then loopDeus:Disconnect() end
    loopDeus = R.Heartbeat:Connect(function()
        if C.Extra.Deus and meuChar then
            local h = meuChar:FindFirstChildOfClass("Humanoid")
            if h then
                if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                if h.Health <= 0 then h.Health = h.MaxHealth end
            end
        end
    end)
end

local function iniciarRegen()
    if loopRegen then loopRegen:Disconnect() end
    loopRegen = R.Heartbeat:Connect(function()
        if C.Extra.Regenerar and meuChar then
            local h = meuChar:FindFirstChildOfClass("Humanoid")
            if h and h.Health < h.MaxHealth then
                h.Health = math.min(h.Health + C.Extra.VelocidadeRegen * 0.1, h.MaxHealth)
            end
        end
    end)
end

local function iniciarAntiKB()
    if loopAntiKB then loopAntiKB:Disconnect() end
    loopAntiKB = R.Heartbeat:Connect(function()
        if C.Extra.AntiKnockback and meuChar then
            local r = meuChar:FindFirstChild("HumanoidRootPart")
            if r then
                r.Velocity = Vector3.new(0, r.Velocity.Y, 0)
            end
        end
    end)
end

local function iniciarAntiQueda()
    if loopAntiQueda then loopAntiQueda:Disconnect() end
    loopAntiQueda = R.Heartbeat:Connect(function()
        if C.Extra.AntiQueda and meuChar then
            local h = meuChar:FindFirstChildOfClass("Humanoid")
            if h then
                local st = h:GetState()
                if st == Enum.HumanoidStateType.Freefall or
                   st == Enum.HumanoidStateType.Ragdoll or
                   st == Enum.HumanoidStateType.Physics then
                    h:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                local r = meuChar:FindFirstChild("HumanoidRootPart")
                if r and r.Velocity.Magnitude > 30 then
                    r.Velocity = Vector3.new(0, r.Velocity.Y, 0)
                end
            end
        end
    end)
end

local function atualizarExtras()
    aplicarVelocidade()
    aplicarAtravessar()
    if C.Extra.AntiMorte then iniciarAntiMorte() elseif loopAntiMorte then loopAntiMorte:Disconnect() end
    if C.Extra.Deus then iniciarDeus() elseif loopDeus then loopDeus:Disconnect() end
    if C.Extra.Regenerar then iniciarRegen() elseif loopRegen then loopRegen:Disconnect() end
    if C.Extra.AntiKnockback then iniciarAntiKB() elseif loopAntiKB then loopAntiKB:Disconnect() end
    if C.Extra.AntiQueda then iniciarAntiQueda() elseif loopAntiQueda then loopAntiQueda:Disconnect() end
end

L.CharacterAdded:Connect(function(c)
    meuChar = c
    wait(0.5)
    atualizarExtras()
end)

-- ESP SIMPLES
local function criarDestaque(obj, cor)
    if not valido(obj) then return end
    if obj:FindFirstChild("D") then return end
    chamarSeguro(function()
        local d = Instance.new("Highlight")
        d.Name = "D"
        d.Adornee = obj
        d.FillColor = cor
        d.OutlineColor = cor
        d.FillTransparency = 0.5
        d.OutlineTransparency = 0
        d.Parent = obj
        Destaques[obj] = d
    end)
end

local function removerDestaque(obj)
    if Destaques[obj] then
        chamarSeguro(function()
            if valido(Destaques[obj]) then
                Destaques[obj]:Destroy()
            end
        end)
        Destaques[obj] = nil
    end
    local e = obj:FindFirstChild("D")
    if e then e:Destroy() end
end

local function limparESP()
    for obj, _ in pairs(Destaques) do
        removerDestaque(obj)
    end
    Destaques = {}
end

local function atualizarESP()
    for _, p in ipairs(P:GetPlayers()) do
        if p ~= L and p.Character and p.Team then
            local tn = p.Team.Name
            if tn == "Killer" and C.ESP.Assassino then
                criarDestaque(p.Character, Color3.fromRGB(255, 0, 0))
            elseif tn == "Survivors" and C.ESP.Sobrevivente then
                criarDestaque(p.Character, Color3.fromRGB(0, 255, 0))
            else
                removerDestaque(p.Character)
            end
        end
    end
end

local function iniciarESP()
    if ConexaoESP then return end
    ConexaoESP = R.Heartbeat:Connect(atualizarESP)
    notificar("ESP Iniciado", "Assassino=Vermelho | Sobrevivente=Verde", 2)
end

local function pararESP()
    if ConexaoESP then
        ConexaoESP:Disconnect()
        ConexaoESP = nil
    end
    limparESP()
    notificar("ESP Parado", "Destaques removidos", 2)
end

-- GERADORES
local function pegarGeradores()
    local gens = {}
    local mapa = W:FindFirstChild("Map")
    if not mapa then return gens end
    for _, obj in ipairs(mapa:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local p = obj:FindFirstChildWhichIsA("BasePart")
            if p then
                table.insert(gens, {modelo = obj, parte = p, posicao = p.Position})
            end
        end
    end
    return gens
end

function pegarGeradoresPorDistancia()
    local raiz = pegarRaiz()
    if not raiz then return {} end
    local gens = pegarGeradores()
    for _, g in ipairs(gens) do
        g.distancia = (g.posicao - raiz.Position).Magnitude
    end
    table.sort(gens, function(a, b) return a.distancia < b.distancia end)
    return gens
end

function teleporteSeguro(cf, off)
    local raiz = pegarRaiz()
    if not raiz then return false end
    off = off or Vector3.new(0, C.Teleporte.AlturaOffset, 0)
    if C.Teleporte.TeleporteSeguro then
        chamarSeguro(function()
            for _, p in ipairs(L.Character:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end)
    end
    raiz.CFrame = cf + off
    if C.Teleporte.TeleporteSeguro then
        task.delay(0.5, function()
            chamarSeguro(function()
                for _, p in ipairs(L.Character:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.CanCollide = true
                    end
                end
            end)
        end)
    end
    return true
end

function sairGerador()
    local raiz = pegarRaiz()
    if not raiz then return false end
    local mapa = W:FindFirstChild("Map")
    if not mapa then return false end
    local ng, nd
    for _, obj in ipairs(mapa:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local p = obj:FindFirstChildWhichIsA("BasePart")
            if p then
                local d = (p.Position - raiz.Position).Magnitude
                if d < (nd or math.huge) then
                    nd = d
                    ng = p
                end
            end
        end
    end
    if not ng or nd > C.Auto.DistanciaSair then
        notificar("Longe", "Não está perto de um gerador", 2)
        return false
    end
    local dir = (raiz.Position - ng.Position).Unit
    local esc = raiz.Position + dir * (C.Auto.DistanciaSair + 15)
    local cf = CFrame.new(esc, esc + raiz.CFrame.LookVector)
    if teleporteSeguro(cf, Vector3.new(0, 2, 0)) then
        notificar("Escapou!", string.format("Fugiu %.0f studs", C.Auto.DistanciaSair + 15), 2)
        return true
    end
    return false
end

local function iniciarSairGerador()
    if ConexaoSairGerador then return end
    if not isMobile then
        ConexaoSairGerador = U.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.KeyCode == C.Auto.TeclaSair then
                sairGerador()
            end
        end)
        notificar("Sair Gerador", "Pressione " .. C.Auto.TeclaSair.Name, 3)
    else
        notificar("Modo Mobile", "Use o botão no menu", 3)
    end
end

local function pararSairGerador()
    if ConexaoSairGerador then
        ConexaoSairGerador:Disconnect()
        ConexaoSairGerador = nil
    end
end

local function ataqueAutomatico()
    if not ehAssassino() then return end
    local raiz = pegarRaiz()
    if not raiz then return end
    local alvo
    for _, p in ipairs(P:GetPlayers()) do
        if p ~= L and p.Team and p.Team.Name == "Survivors" and p.Character then
            local th = p.Character:FindFirstChild("HumanoidRootPart")
            if th then
                local d = (th.Position - raiz.Position).Magnitude
                if d <= C.Auto.AlcanceAtaque then
                    alvo = p
                    break
                end
            end
        end
    end
    if alvo then
        chamarSeguro(function()
            local remotes = RS:FindFirstChild("Remotes")
            if remotes then
                local ataques = remotes:FindFirstChild("Attacks")
                if ataques then
                    local ba = ataques:FindFirstChild("BasicAttack")
                    if ba then ba:FireServer(false) end
                end
            end
        end)
    end
end

local function iniciarAtaqueAuto()
    if ConexaoAtaqueAuto then return end
    if not ehAssassino() then
        notificar("Erro", "Precisa ser o Assassino!", 3)
        return
    end
    ConexaoAtaqueAuto = R.Heartbeat:Connect(function()
        if C.Auto.AutoAtaque then ataqueAutomatico() end
    end)
    notificar("Ataque Auto", "Alcance: " .. C.Auto.AlcanceAtaque, 3)
end

local function pararAtaqueAuto()
    if ConexaoAtaqueAuto then
        ConexaoAtaqueAuto:Disconnect()
        ConexaoAtaqueAuto = nil
    end
end

-- =============================================
-- CONSTRUÇÃO DA INTERFACE RAYFIELD
-- =============================================
local Janela = Rayfield:CreateWindow({
    Nome = "🎮 Abd Hub",
    TituloCarregamento = "Abd Hub",
    SubtituloCarregamento = "Completo",
    SalvarConfig = {Ativado = true, Pasta = nil, NomeArquivo = "AbdHub"},
    Discord = {Ativado = false},
    SistemaChave = false
})

print("✅ Janela criada!")

-- ABA ESP
local AbaESP = Janela:CriarAba("👁️ ESP", 4483362458)
AbaESP:CriarSecao("ESP Jogadores (Cores)")
AbaESP:CriarAlternar({
    Nome = "Assassino (Vermelho)",
    ValorAtual = false,
    Bandeira = "AssassinoESP",
    Callback = function(v)
        C.ESP.Assassino = v
        if v or C.ESP.Sobrevivente then iniciarESP() else pararESP() end
    end
})
AbaESP:CriarAlternar({
    Nome = "Sobrevivente (Verde)",
    ValorAtual = false,
    Bandeira = "SobreviventeESP",
    Callback = function(v)
        C.ESP.Sobrevivente = v
        if v or C.ESP.Assassino then iniciarESP() else pararESP() end
    end
})
AbaESP:CriarLabel("💡 Ative um deles para ver os jogadores destacados.")

print("✅ Aba ESP criada!")

-- ABA JOGO
local AbaJogo = Janela:CriarAba("🎮 Jogo", 4483362458)
AbaJogo:CriarSecao("Auto Gerador")
AbaJogo:CriarAlternar({
    Nome = "Auto Completar Geradores",
    ValorAtual = false,
    Bandeira = "AutoGerador",
    Callback = function(v)
        C.Auto.AutoGerador = v
        notificar("Auto Gerador", v and "Ativado" or "Desativado", 2)
    end
})
AbaJogo:CriarDropdown({
    Nome = "Modo Gerador",
    Opcoes = {"Ótimo (Rápido)", "Normal (Lento)"},
    OpcaoAtual = "Ótimo (Rápido)",
    Bandeira = "ModoGerador",
    Callback = function(o)
        C.Auto.ModoGerador = o:find("Ótimo") and "otimo" or "normal"
    end
})
AbaJogo:CriarSecao("Fuga Rápida")
AbaJogo:CriarAlternar({
    Nome = "Sair Gerador Rápido",
    ValorAtual = false,
    Bandeira = "AutoSairGerador",
    Callback = function(v)
        C.Auto.AutoSairGerador = v
        if v then iniciarSairGerador() else pararSairGerador() end
    end
})
AbaJogo:CriarBotao({
    Nome = "Sair Gerador Agora",
    Callback = sairGerador
})
AbaJogo:CriarSecao("Ações")
AbaJogo:CriarBotao({
    Nome = "Completar Todos Geradores (Instantâneo)",
    Callback = function()
        local mapa = W:FindFirstChild("Map")
        if not mapa then notificar("Erro", "Mapa não encontrado", 3) return end
        local completos = 0
        chamarSeguro(function()
            local remotes = RS:FindFirstChild("Remotes")
            if not remotes then return end
            local genRemotes = remotes:FindFirstChild("Generator")
            if not genRemotes then return end
            local reparar = genRemotes:FindFirstChild("RepairEvent")
            local habilidade = genRemotes:FindFirstChild("SkillCheckResultEvent")
            if not reparar or not habilidade then return end
            for _, obj in ipairs(mapa:GetDescendants()) do
                if obj:IsA("Model") and obj.Name == "Generator" then
                    for _, ponto in ipairs(obj:GetChildren()) do
                        if ponto.Name:find("GeneratorPoint") then
                            pcall(function()
                                for _ = 1, 10 do
                                    reparar:FireServer(ponto, true)
                                    habilidade:FireServer("success", 1, obj, ponto)
                                end
                                completos = completos + 1
                            end)
                        end
                    end
                end
            end
        end)
        if completos > 0 then
            notificar("Completo!", string.format("%d gerador(es)", completos), 4)
        else
            notificar("Falha", "Nenhum gerador encontrado", 3)
        end
    end
})
AbaJogo:CriarSecao("Assassino")
AbaJogo:CriarAlternar({
    Nome = "Auto Atacar Sobreviventes",
    ValorAtual = false,
    Bandeira = "AutoAtaque",
    Callback = function(v)
        C.Auto.AutoAtaque = v
        if v then iniciarAtaqueAuto() else pararAtaqueAuto() end
    end
})
AbaJogo:CriarControleDeslizante({
    Nome = "Alcance do Ataque",
    Intervalo = {5, 20},
    Incremento = 1,
    ValorAtual = 10,
    Bandeira = "AlcanceAtaque",
    Callback = function(v) C.Auto.AlcanceAtaque = v end
})
AbaJogo:CriarBotao({
    Nome = "Ativar Poder do Assassino",
    Callback = function()
        chamarSeguro(function()
            local remotes = RS:FindFirstChild("Remotes")
            if remotes then
                local kr = remotes:FindFirstChild("Killers")
                if kr then
                    local kf = kr:FindFirstChild("Killer")
                    if kf then
                        local ap = kf:FindFirstChild("ActivatePower")
                        if ap then
                            ap:FireServer()
                            notificar("Poder Ativado", "Acionado!", 2)
                        end
                    end
                end
            end
        end)
    end
})
AbaJogo:CriarBotao({
    Nome = "Ataque Básico",
    Callback = function()
        chamarSeguro(function()
            local remotes = RS:FindFirstChild("Remotes")
            if remotes then
                local ataques = remotes:FindFirstChild("Attacks")
                if ataques then
                    local ba = ataques:FindFirstChild("BasicAttack")
                    if ba then
                        ba:FireServer(false)
                        notificar("Ataque", "Executado", 2)
                    end
                end
            end
        end)
    end
})

print("✅ Aba Jogo criada!")

-- ABA TELEPORTE
local AbaTeleporte = Janela:CriarAba("🚀 Teleporte", 4483362458)
AbaTeleporte:CriarSecao("Teleporte para Gerador")
AbaTeleporte:CriarBotao({
    Nome = "Teleportar para o Mais Próximo",
    Callback = function()
        local gens = pegarGeradoresPorDistancia()
        if #gens == 0 then notificar("Não Encontrado", "Nenhum gerador", 3) return end
        if teleporteSeguro(gens[1].parte.CFrame) then
            notificar("Teleportado!", "Mais próximo", 3)
        end
    end
})
AbaTeleporte:CriarBotao({
    Nome = "Teleportar para o Mais Distante",
    Callback = function()
        local gens = pegarGeradoresPorDistancia()
        if #gens == 0 then notificar("Não Encontrado", "Nenhum gerador", 3) return end
        local far = gens[#gens]
        if teleporteSeguro(far.parte.CFrame) then
            notificar("Teleportado!", "Mais distante", 3)
        end
    end
})
AbaTeleporte:CriarBotao({
    Nome = "Teleportar por Todos os Geradores",
    Callback = function()
        local gens = pegarGeradoresPorDistancia()
        if #gens == 0 then notificar("Não Encontrado", "Nenhum gerador", 3) return end
        notificar("Iniciando", string.format("%d geradores", #gens), 3)
        task.spawn(function()
            for i, gen in ipairs(gens) do
                if not pegarRaiz() then break end
                teleporteSeguro(gen.parte.CFrame)
                notificar("Gerador " .. i, string.format("%d/%d", i, #gens), 2)
                task.wait(C.Teleporte.DelayTeleporte)
            end
            notificar("Completo!", "Visitou todos", 3)
        end)
    end
})

print("✅ Aba Teleporte criada!")

-- ABA PROTEÇÃO
local AbaProtecao = Janela:CriarAba("🛡️ Proteção", 4483362458)
AbaProtecao:CriarSecao("⚡ Velocidade")
AbaProtecao:CriarControleDeslizante({
    Nome = "Velocidade (16-100)",
    Intervalo = {16, 100},
    Incremento = 1,
    ValorAtual = 16,
    Bandeira = "SliderVelocidade",
    Callback = function(v)
        C.Extra.Velocidade = v
        aplicarVelocidade()
    end
})
AbaProtecao:CriarSecao("🚪 Atravessar")
AbaProtecao:CriarAlternar({
    Nome = "Atravessar Paredes",
    ValorAtual = false,
    Bandeira = "ToggleNoclip",
    Callback = function(v)
        C.Extra.AtravessarParedes = v
        aplicarAtravessar()
    end
})
AbaProtecao:CriarSecao("💀 Anti-Morte")
AbaProtecao:CriarAlternar({
    Nome = "Anti-Morte (Não Morre)",
    ValorAtual = false,
    Bandeira = "ToggleAntiMorte",
    Callback = function(v)
        C.Extra.AntiMorte = v
        if v then iniciarAntiMorte() elseif loopAntiMorte then loopAntiMorte:Disconnect() end
    end
})
AbaProtecao:CriarSecao("♾️ Deus")
AbaProtecao:CriarAlternar({
    Nome = "Deus (Vida Infinita)",
    ValorAtual = false,
    Bandeira = "ToggleDeus",
    Callback = function(v)
        C.Extra.Deus = v
        if v then iniciarDeus() elseif loopDeus then loopDeus:Disconnect() end
    end
})
AbaProtecao:CriarSecao("🩸 Regeneração")
AbaProtecao:CriarAlternar({
    Nome = "Regeneração Automática",
    ValorAtual = false,
    Bandeira = "ToggleRegen",
    Callback = function(v)
        C.Extra.Regenerar = v
        if v then iniciarRegen() elseif loopRegen then loopRegen:Disconnect() end
    end
})
AbaProtecao:CriarControleDeslizante({
    Nome = "Velocidade Regen (1-20)",
    Intervalo = {1, 20},
    Incremento = 1,
    ValorAtual = 5,
    Bandeira = "SliderRegen",
    Callback = function(v)
        C.Extra.VelocidadeRegen = v
    end
})
AbaProtecao:CriarSecao("🛡️ Anti-Knockback")
AbaProtecao:CriarAlternar({
    Nome = "Anti-Knockback",
    ValorAtual = false,
    Bandeira = "ToggleAntiKB",
    Callback = function(v)
        C.Extra.AntiKnockback = v
        if v then iniciarAntiKB() elseif loopAntiKB then loopAntiKB:Disconnect() end
    end
})
AbaProtecao:CriarSecao("⛔ Anti-Queda")
AbaProtecao:CriarAlternar({
    Nome = "Anti-Queda (Não Cair)",
    ValorAtual = false,
    Bandeira = "ToggleAntiQueda",
    Callback = function(v)
        C.Extra.AntiQueda = v
        if v then iniciarAntiQueda() elseif loopAntiQueda then loopAntiQueda:Disconnect() end
    end
})

print("✅ Aba Proteção criada!")

-- =============================================
-- LOOP AUTO GERADOR
-- =============================================
task.spawn(function()
    while task.wait(0.2) do
        if C.Auto.AutoGerador then
            chamarSeguro(function()
                local remotes = RS:FindFirstChild("Remotes")
                if not remotes then return end
                local genRemotes = remotes:FindFirstChild("Generator")
                if not genRemotes then return end
                local reparar = genRemotes:FindFirstChild("RepairEvent")
                local habilidade = genRemotes:FindFirstChild("SkillCheckResultEvent")
                if not reparar or not habilidade then return end
                local mapa = W:FindFirstChild("Map")
                if not mapa then return end
                for _, obj in ipairs(mapa:GetDescendants()) do
                    if obj:IsA("Model") and obj.Name == "Generator" then
                        for _, ponto in ipairs(obj:GetChildren()) do
                            if ponto.Name:find("GeneratorPoint") then
                                pcall(function()
                                    reparar:FireServer(ponto, true)
                                    local res = C.Auto.ModoGerador == "otimo" and "success" or "neutral"
                                    local val = C.Auto.ModoGerador == "otimo" and 1 or 0
                                    habilidade:FireServer(res, val, obj, ponto)
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
atualizarExtras()

notificar("Abd Hub", "Carregado com sucesso!", 4)

print("========================================")
print("✅ ABD HUB – COMPLETO")
print("📱 Mobile:", isMobile and "SIM" or "NÃO")
print("👁️ ESP: Cores (Vermelho/Verde)")
print("🛡️ Aba 'Proteção' com funções extras")
print("========================================")