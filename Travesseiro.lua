--[[
Nick Hub - WindUI Panel (Full Functional with Whitelist & New Jail + FE System)
]]

-- Whitelist
local AllowedPlayers = {
    ["Foortataq"] = true,
    ["Bakugo_Master4"] = true,
    ["Kilozord"] = true,
    ["victor2014de"] = true,
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not AllowedPlayers[LocalPlayer.Name] then
    return -- jogador não autorizado
end

-- Carregar WindUI
local WindUI
do
    local ok, result = pcall(function()
        return require("./src/init")
    end)
    if ok then
        WindUI = result
    else
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end
end

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local function getCharacter(plr)
    return plr and plr.Character or plr.CharacterAdded:Wait()
end

-- BoolValues do FE System
local IsPaidPanel = Instance.new("BoolValue")
IsPaidPanel.Name = "IsPaidPanel"
IsPaidPanel.Value = true -- apenas painel pode executar comandos
IsPaidPanel.Parent = LocalPlayer

local FEAccess = Instance.new("BoolValue")
FEAccess.Name = "FEAccess"
FEAccess.Value = true -- painel/hub podem ser afetados
FEAccess.Parent = LocalPlayer

-- Cria FEAccess para outros jogadores
local function AddFEAccess(player)
    if not player:FindFirstChild("FEAccess") then
        local fe = Instance.new("BoolValue")
        fe.Name = "FEAccess"
        fe.Value = true
        fe.Parent = player
    end
end

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then AddFEAccess(plr) end
end

Players.PlayerAdded:Connect(AddFEAccess)

-- Helper FE
local function CanAffectTarget(target)
    return LocalPlayer:FindFirstChild("IsPaidPanel") and LocalPlayer.IsPaidPanel.Value
       and target:FindFirstChild("FEAccess") and target.FEAccess.Value
end

-- Função auxiliar para enviar comando no chat
local function SendCommand(msg)
    local tcs = game:GetService("TextChatService")
    if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = tcs.TextChannels.RBXGeneral
        if channel then channel:SendAsync(msg) end
    else
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
    end
end

-- Criar Window
local Window = WindUI:CreateWindow({
    Title = "Nick Admin",
    Author = "Nick",
    Folder = "NickHub",
    NewElements = true,
    Transparent = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Nick Admin",
        Icon = "monitor",
        CornerRadius = UDim.new(1,0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#e7ff2f"))
    }
})

-- Aba Funções
local FuncoesTab = Window:Tab({ Title = "Funções", Icon = "hammer" })
local ComandosSection = FuncoesTab:Section({ Title = "Comandos", Icon = "album" })

-- Dropdown de jogadores
local playerNames = {}
for _, player in pairs(Players:GetPlayers()) do
    table.insert(playerNames, player.Name)
end

local SelectedPlayer
Players.PlayerAdded:Connect(function(player)
    table.insert(playerNames, player.Name)
end)

ComandosSection:Dropdown({
    Title = "Jogadores",
    Values = playerNames,
    Callback = function(value)
        SelectedPlayer = Players:FindFirstChild(value)
    end
})

-------------------------
-- FUNÇÕES DO PAINEL (COM FE)
-------------------------

local frozenPlayers = {}
local JailedPlayers = {}

local function Verificar()
    for _, plr in pairs(Players:GetPlayers()) do
        local backpack = plr:FindFirstChildOfClass("Backpack")
        local scripts = plr:FindFirstChildOfClass("PlayerScripts")
        if backpack or scripts then
            SendCommand("Nick_Hub")
        end
    end
end

local function Bring(target)
    if target and CanAffectTarget(target) then
        local char = getCharacter(target)
        local myChar = getCharacter(LocalPlayer)
        if char and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            char:MoveTo(myChar.HumanoidRootPart.Position + Vector3.new(0, 2, 0))
        end
    end
end

local function Freeze(target)
    if target and CanAffectTarget(target) then
        local char = getCharacter(target)
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Anchored = true end
        end
        frozenPlayers[target] = true
    end
end

local function Unfreeze(target)
    if target and CanAffectTarget(target) then
        local char = getCharacter(target)
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Anchored = false end
        end
        frozenPlayers[target] = nil
    end
end

local function Fling(target)
    if target and CanAffectTarget(target) then
        local char = getCharacter(target)
        if char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new(math.random(-500,500), 500, math.random(-500,500))
        end
    end
end

local function Kick(target)
    if target and CanAffectTarget(target) then
        target:Kick("Você foi kickado pelo Nick Hub🤍")
    end
end

local function Kill(target)
    if target and CanAffectTarget(target) then
        local char = getCharacter(target)
        if char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").Health = 0
        end
    end
end

local function KillPlus(target)
    if target and CanAffectTarget(target) then
        local char = getCharacter(target)
        if char:FindFirstChildOfClass("Humanoid") then
            for i = 1, 5 do
                char:FindFirstChildOfClass("Humanoid").Health = 0
                task.wait(0.3)
            end
            local explosion = Instance.new("Explosion", workspace)
            explosion.Position = char:FindFirstChild("HumanoidRootPart").Position
            explosion.BlastRadius = 6
            explosion.BlastPressure = 999999
        end
    end
end

local function makePart(props)
    local p = Instance.new("Part")
    for k,v in pairs(props) do if k~="Parent" then p[k]=v end end
    if props.Parent then p.Parent = props.Parent end
    return p
end

local function JailPlayerInternal(player)
    if player and CanAffectTarget(player) then
        if not player.Character then return end
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if JailedPlayers[player] then return end

        local size,height,wallT,edgeT = 7,7,0.5,0.18
        local center = hrp.Position + Vector3.new(0,2,0)

        local model = Instance.new("Model", workspace)
        model.Name = "Jail_"..player.Name

        local floor = makePart{Size=Vector3.new(size,wallT,size),Position=center+Vector3.new(0,-height/2+wallT/2,0),
            Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
        local ceiling = makePart{Size=Vector3.new(size,wallT,size),Position=center+Vector3.new(0,height/2-wallT/2,0),
            Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}

        local front = makePart{Size=Vector3.new(size,height,wallT),Position=center+Vector3.new(0,0,size/2-wallT/2),
            Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
        local back = makePart{Size=Vector3.new(size,height,wallT),Position=center+Vector3.new(0,0,-size/2+wallT/2),
            Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
        local right = makePart{Size=Vector3.new(wallT,height,size),Position=center+Vector3.new(size/2-wallT/2,0,0),
            Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
        local left = makePart{Size=Vector3.new(wallT,height,size),Position=center+Vector3.new(-size/2+wallT/2,0,0),
            Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}

        local cornerOffsets = {
            Vector3.new( size/2-edgeT/2,0, size/2-edgeT/2),
            Vector3.new(-size/2+edgeT/2,0, size/2-edgeT/2),
            Vector3.new( size/2-edgeT/2,0,-size/2+edgeT/2),
            Vector3.new(-size/2+edgeT/2,0,-size/2+edgeT/2),
        }
        for _, off in ipairs(cornerOffsets) do
            local p = makePart{Size=Vector3.new(edgeT,height,edgeT),Position=center+off,
                Anchored=true,CanCollide=true,Material=Enum.Material.Neon,BrickColor=BrickColor.new("Really black"),Parent=model}
            p.Transparency = 0
            local tween = TweenService:Create(p, TweenInfo.new(1.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.3})
            tween:Play()
        end

        hrp.CFrame = CFrame.new(center.X, floor.Position.Y + wallT/2 + 2, center.Z)
        JailedPlayers[player] = model
    end
end

local function UnjailPlayerInternal(player)
    if player and CanAffectTarget(player) then
        if JailedPlayers[player] then
            JailedPlayers[player]:Destroy()
            JailedPlayers[player] = nil
        end
    end
end

---------------------
-- BOTÕES DO PAINEL
---------------------

local actions = {
    {Title="Verificar",Func=function() Verificar() end},
    {Title="Bring",Func=function() if SelectedPlayer then Bring(SelectedPlayer) end end},
    {Title="Freeze",Func=function() if SelectedPlayer then Freeze(SelectedPlayer) end end},
    {Title="UnFreeze",Func=function() if SelectedPlayer then Unfreeze(SelectedPlayer) end end},
    {Title="Fling",Func=function() if SelectedPlayer then Fling(SelectedPlayer) end end},
    {Title="Kick",Func=function() if SelectedPlayer then Kick(SelectedPlayer) end end},
    {Title="Kill",Func=function() if SelectedPlayer then Kill(SelectedPlayer) end end},
    {Title="KillPlus",Func=function() if SelectedPlayer then KillPlus(SelectedPlayer) end end},
    {Title="Jail",Func=function() if SelectedPlayer then JailPlayerInternal(SelectedPlayer) end end},
    {Title="Unjail",Func=function() if SelectedPlayer then UnjailPlayerInternal(SelectedPlayer) end end},
}

for _, info in pairs(actions) do
    ComandosSection:Button({
        Title = info.Title,
        Desc = "Executa o comando " .. info.Title,
        Callback = info.Func
    })
end

---------------------
-- CHAT
---------------------

local ChatSection = FuncoesTab:Section({ Title = "Chat", Icon = "bird" })
local ChatMessage = ""

ChatSection:Input({
    Title = "Mensagem",
    Placeholder = "Digite a mensagem...",
    Type = "Input",
    Callback = function(msg) ChatMessage = msg end
})

ChatSection:Button({
    Title = "Enviar Chat",
    Desc = "Envia a mensagem digitada para o jogador selecionado",
    Callback = function()
        if not SelectedPlayer or ChatMessage == "" then return end
        SendCommand(";chat " .. SelectedPlayer.Name .. " " .. ChatMessage)
    end
})
