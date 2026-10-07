-- ============================================================================= --
-- AUTO QUEST MASTER CONTROLLER - FORCE CYCLE EDITION (2026)
-- ============================================================================= --
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local living = workspace:WaitForChild("Living")

--==================================================
-- CONFIGURAÇÕES PARAMETRIZADAS INTEGRADAS
--==================================================
local CONFIG = {
    NPC_NAME = "Officer Sam [Lvl. 1+]",
    NPC_POS = Vector3.new(-474, 10, -777),
    TWEEN_SPEED = 85,
    SPAM_DELAY = 0.05,
    
    -- COORDENADAS ATUALIZADAS (Mesmo botão para Option1 e Avançar Diálogo)
    CLICK_SCALE = Vector2.new(0.64592433, 0.660380185),
    
    COMBAT_NPC_NAME = "Thug",
    DISTANCE_BEHIND = 3,
    FLOAT_HEIGHT = 2,
    PLAYER_BELOW = 17,
    AUTOCLICK_INTERVAL = 0.12,
    Q_INTERVAL = 0.25,
}

--==================================================
-- VARIÁVEIS DE ESTADO DO JOGO
--==================================================
local isRunning = false
local currentStatus = "Aguardando"
local combatEnabled = false
local currentNPC = nil
local autoClickRunning = false
local qLoopRunning = false
local missaoSelecionada = false

--==================================================
-- INTERFACE GRÁFICA (GUI) - DESIGN ATUALIZADO
--==================================================
local gui = Instance.new("ScreenGui")
gui.Name = "MasterUnifiedFarmGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 300, 0, 190) -- Tamanho do design solicitado
main.Position = UDim2.new(0.5, -150, 0.5, -95) -- Centralização correspondente
main.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 70, 85)
stroke.Thickness = 1
stroke.Parent = main

-- Título do Script (Área para arrastar / Status Dinâmico)
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, 0, 0, 30)
titulo.Position = UDim2.new(0, 0, 0, 5)
titulo.BackgroundTransparency = 1
titulo.Text = "Status: Aguardando"
titulo.TextColor3 = Color3.fromRGB(255, 255, 255)
titulo.TextSize = 14
titulo.Font = Enum.Font.SourceSansBold
titulo.Parent = main

-- LISTA DE MISSÕES
local listaContainer = Instance.new("ScrollingFrame")
listaContainer.Size = UDim2.new(0, 260, 0, 85)
listaContainer.Position = UDim2.new(0.5, -130, 0, 40)
listaContainer.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
listaContainer.BorderSizePixel = 0
listaContainer.ScrollBarThickness = 2
listaContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
local layoutLista = Instance.new("UIListLayout", listaContainer)
layoutLista.Padding = UDim.new(0, 4)
Instance.new("UICorner", listaContainer).CornerRadius = UDim.new(0, 6)
listaContainer.Parent = main

-- Criar Botão da única Missão: Thug Lvl. 1
local btnMissao = Instance.new("TextButton")
btnMissao.Size = UDim2.new(1, 0, 0, 26)
btnMissao.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
btnMissao.TextColor3 = Color3.fromRGB(200, 200, 200)
btnMissao.Text = "Thug Lvl. 1"
btnMissao.Font = Enum.Font.SourceSansBold
btnMissao.TextSize = 13
Instance.new("UICorner", btnMissao).CornerRadius = UDim.new(0, 4)
btnMissao.Parent = listaContainer
listaContainer.CanvasSize = UDim2.new(0, 0, 0, layoutLista.AbsoluteContentSize.Y)

btnMissao.MouseButton1Click:Connect(function()
    missaoSelecionada = not missaoSelecionada
    if missaoSelecionada then
        btnMissao.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        btnMissao.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        btnMissao.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btnMissao.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- BOTÃO DE LIGAR / DESLIGAR ATIVAÇÃO (Botão Unificado)
local btnFarm = Instance.new("TextButton")
btnFarm.Size = UDim2.new(0, 260, 0, 36)
btnFarm.Position = UDim2.new(0.5, -130, 0, 138)
btnFarm.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Verde Inicial
btnFarm.TextColor3 = Color3.fromRGB(255, 255, 255)
btnFarm.Text = "LIGAR BOT"
btnFarm.Font = Enum.Font.SourceSansBold
btnFarm.TextSize = 15
Instance.new("UICorner", btnFarm).CornerRadius = UDim.new(0, 6)
btnFarm.Parent = main

-- LÓGICA DE SISTEMA DRAGGABLE (Arrastar Janela Fluidamente)
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

--==================================================
-- FUNÇÕES DE LEITURA EXATA
--==================================================
local function getCharacterElements()
    local char = player.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

local function getStandMorph()
    local playerModel = living:FindFirstChild(player.Name)
    return playerModel and playerModel:FindFirstChild("StandMorph")
end

local function getNPCHealth(npc)
    if not npc then return nil end
    local health = npc:FindFirstChild("Health")
    return (health and health:IsA("DoubleConstrainedValue")) and health or nil
end

local function getNPCHRP(npc)
    if not npc then return nil end
    return npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") or npc:FindFirstChild("UpperTorso")
end

local function isDialogueGuiActive()
    return playerGui:FindFirstChild("DialogueGui") ~= nil or playerGui:FindFirstChild("Dialogue") ~= nil
end

local function getQuestData()
    local stats = player:FindFirstChild("PlayerStats")
    if not stats then return "", 0, 0 end
    local quest = stats:FindFirstChild("Quest")
    local progress = stats:FindFirstChild("QuestProgress")
    local maxProgress = stats:FindFirstChild("QuestMaxProgress")
    
    local questValue = quest and quest.Value or ""
    local progressValue = progress and progress.Value or 0
    local maxProgressValue = maxProgress and maxProgress.Value or 0
    
    if questValue == "/" or string.gsub(questValue, " ", "") == "" then
        questValue = ""
    end
    return questValue, progressValue, maxProgressValue
end

local function fastWait(condition, timeout)
    local start = os.clock()
    while os.clock() - start < timeout do
        if not isRunning then return false end
        local success, result = pcall(condition)
        if success and result then return true end
        task.wait(0.1)
    end
    return false
end

--==================================================
-- ENTRADAS VIRTUAIS DO COMBATE
--==================================================
local function sendClick()
    VirtualInputManager:SendMouseButtonEvent(1, 1, 0, true, game, 0)
    task.wait(0.04)
    VirtualInputManager:SendMouseButtonEvent(1, 1, 0, false, game, 0)
end

local function startAutoClick()
    if autoClickRunning then return end
    autoClickRunning = true
    task.spawn(function()
        while autoClickRunning and combatEnabled and isRunning do
            pcall(sendClick)
            task.wait(CONFIG.AUTOCLICK_INTERVAL)
        end
        autoClickRunning = false
    end)
end

local function startQLoop()
    if qLoopRunning then return end
    qLoopRunning = true
    task.spawn(function()
        while combatEnabled and qLoopRunning and isRunning do
            if getStandMorph() then break end
            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game) end)
            task.wait(0.04)
            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game) end)
            task.wait(CONFIG.Q_INTERVAL)
        end
        qLoopRunning = false
    end)
end

local function returnStandToPlayer()
    currentNPC = nil
    local stand = getStandMorph()
    local _, humanoid, hrp = getCharacterElements()
    if stand and hrp and hrp.Parent then
        stand:PivotTo(hrp.CFrame * CFrame.new(0, 0, 3))
    end
    if humanoid then camera.CameraSubject = humanoid end
end

local function setCombatState(wantEnabled)
    if wantEnabled then
        local _, humanoid, _ = getCharacterElements()
        if not humanoid or humanoid.Health <= 0 then return end
        combatEnabled = true
        currentNPC = nil
        startAutoClick()
        if not getStandMorph() then startQLoop() end
    else
        combatEnabled = false
        autoClickRunning = false
        qLoopRunning = false
        returnStandToPlayer()
    end
end

local function findTargetNPC()
    for _, npc in ipairs(living:GetChildren()) do
        if npc:IsA("Model") and npc.Name == CONFIG.COMBAT_NPC_NAME then
            local health = getNPCHealth(npc)
local root = getNPCHRP(npc)
if health and health.Value > 0 and root then
return npc
end
end
end
return nil
end
--==================================================
-- MOTOR DE ATUALIZAÇÃO DE COMBATE (HEARTBEAT)
--==================================================
RunService.Heartbeat:Connect(function()
if not combatEnabled or not isRunning then return end
local _, humanoid, hrp = getCharacterElements()
if not humanoid or humanoid.Health <= 0 or not hrp or not hrp.Parent then
setCombatState(false)
return
end
local stand = getStandMorph()
if not stand then
currentNPC = nil
startQLoop()
return
end
qLoopRunning = false
if currentNPC then
local health = getNPCHealth(currentNPC)
local npcHrp = getNPCHRP(currentNPC)
if not health or health.Value <= 0 or not npcHrp or not npcHrp.Parent then
currentNPC = nil
end
end
if not currentNPC then
currentNPC = findTargetNPC()
if not currentNPC then
returnStandToPlayer()
return
end
end
local npcHrp = getNPCHRP(currentNPC)
if npcHrp then
local npcHumanoid = currentNPC:FindFirstChildOfClass("Humanoid")
if npcHumanoid then camera.CameraSubject = npcHumanoid end
local standTargetCFrame = npcHrp.CFrame * CFrame.new(0, CONFIG.FLOAT_HEIGHT, CONFIG.DISTANCE_BEHIND)
stand:PivotTo(standTargetCFrame)
local playerTargetCFrame = npcHrp.CFrame * CFrame.new(0, -CONFIG.PLAYER_BELOW, 0)
pcall(function()
hrp.AssemblyLinearVelocity = Vector3.zero
hrp.AssemblyAngularVelocity = Vector3.zero
hrp.CFrame = playerTargetCFrame
end)
end
end)
--==================================================
-- ROTA DE CRIAÇÃO E DIÁLOGOS
--==================================================
local function simularCliqueEscala(coordenadasEscala)
local screenSize = camera.ViewportSize
local pixelX = coordenadasEscala.X * screenSize.X
local pixelY = coordenadasEscala.Y * screenSize.Y
VirtualInputManager:SendMouseButtonEvent(pixelX, pixelY, 0, true, game, 0)
task.wait(0.01)
VirtualInputManager:SendMouseButtonEvent(pixelX, pixelY, 0, false, game, 0)
end
local function walkToNPC()
currentStatus = "Teleportando pro NPC"
setCombatState(false)
local _, _, root = getCharacterElements()
if not root then return false end
pcall(function() root.Anchored = false end)
local distance = (root.Position - CONFIG.NPC_POS).Magnitude
if distance <= 5 then return true end
local duration = distance / CONFIG.TWEEN_SPEED
pcall(function()
root.AssemblyLinearVelocity = Vector3.zero
root.AssemblyAngularVelocity = Vector3.zero
end)
local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
CFrame = CFrame.new(CONFIG.NPC_POS + Vector3.new(0, 1.5, 0))
})
local finished = false
local connection = tween.Completed:Connect(function() finished = true end)
tween:Play()
local success = fastWait(function() return finished end, duration + 2)
connection:Disconnect()
if not success then
tween:Cancel()
return false
end
pcall(function() root.Anchored = true end)
task.wait(0.2)
pcall(function() root.Anchored = false end)
return true
end
local function triggerPrompt()
currentStatus = "Pressionando E"
local folder = workspace:FindFirstChild("Dialogues")
local npc = folder and folder:FindFirstChild(CONFIG.NPC_NAME)
local prompt = npc and npc:FindFirstChildOfClass("ProximityPrompt")
if not prompt then return false end
prompt.RequiresLineOfSight = false
local ok = pcall(function() fireproximityprompt(prompt) end)
if not ok then
pcall(function()
prompt:InputHoldBegin()
task.wait(prompt.HoldDuration + 0.02)
prompt:InputHoldEnd()
end)
end
task.wait(0.5)
return true
end
local function clearAllDialogues()
currentStatus = "Spamando Cliques"
local menuApareceu = fastWait(function() return isDialogueGuiActive() end, 3)
if not menuApareceu then return false end
while isRunning and isDialogueGuiActive() do
pcall(function() simularCliqueEscala(CONFIG.CLICK_SCALE) end)
task.wait(CONFIG.SPAM_DELAY)
end
task.wait(0.4)
return true
end
local function executeHuntingFarming()
currentStatus = "Matando Thugs (KNPC)"
setCombatState(true)
task.wait(1.0)
while isRunning do
local questName, currentProgress, maxProgress = getQuestData()
if questName == "" then
print("[AutoFarm] Ciclo de caça finalizado com sucesso!")
break
end
print(string.format("[Progresso] %s: %d / %d", questName, currentProgress, maxProgress))
task.wait(0.5)
end
setCombatState(false)
return true
end
-- ============================================================================= --
-- GERENCIADOR DE REPETIÇÃO FORÇADA
-- ============================================================================= --
local function runMasterFarmCycle()
print("[AutoFarm] Iniciando nova rota obrigatória completa...")
local steps = { walkToNPC, triggerPrompt, clearAllDialogues, executeHuntingFarming }
for _, step in ipairs(steps) do
if not isRunning then return end
local success = step()
if not success then
warn("[Sistema] Quebra na sequência detectada. Reiniciando ciclo de segurança...")
setCombatState(false)
pcall(function()
local _, _, root = getCharacterElements()
if root then root.Anchored = false end
end)
task.wait(2)
return
end
end
end
local function startBot()
if isRunning then return end
isRunning = true
task.spawn(function()
while isRunning do
runMasterFarmCycle()
task.wait(1.0)
end
currentStatus = "Aguardando"
end)
end
local function stopBot()
isRunning = false
setCombatState(false)
pcall(function()
local _, _, root = getCharacterElements()
if root then root.Anchored = false end
end)
end
player.CharacterAdded:Connect(function()
setCombatState(false)
task.wait(0.5)
end)
-- Loop de Atualização do Status na Janela Principal
task.spawn(function()
while main.Parent do
titulo.Text = "Status: " .. currentStatus
task.wait(0.2)
end
end)
--==================================================
-- VÍNCULO DO BOTÃO ALTERNADOR DA JANELE
--==================================================
btnFarm.MouseButton1Click:Connect(function()
if not missaoSelecionada then
btnFarm.Text = "Selecione a missão primeiro!"
task.wait(1.5)
btnFarm.Text = isRunning and "DESLIGAR BOT" or "LIGAR BOT"
return
end
if isRunning then
stopBot()
btnFarm.Text = "LIGAR BOT"
btnFarm.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Verde
else
startBot()
btnFarm.Text = "DESLIGAR BOT"
btnFarm.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Vermelho
end
end)
