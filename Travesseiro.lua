--[[
Nick Hub - WindUI Panel (Full Functional with Whitelist & New Jail)
]]

-- Whitelist
local AllowedPlayers = {
    ["Foortataq"] = true,
    ["victor2014de"] = true,
    ["Bakugo_Master4"] = true,

    ["matheuzinho_games2"] = true,
    ["foo"] = true,
}

-- Checar whitelist
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not AllowedPlayers[LocalPlayer.Name] then
    return -- jogador não autorizado, encerra o script
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

-- Serviços
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local function getCharacter(plr)
    return plr and plr.Character or plr.CharacterAdded:Wait()
end

-- Função auxiliar: enviar comando no chat
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
local FuncoesTab = Window:Tab({
    Title = "Funções",
    Icon = "hammer"
})
local ComandosSection = FuncoesTab:Section({
    Title = "Comandos",
    Icon = "album"
})

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
-- FUNÇÕES DO PAINEL --
-------------------------

local frozenPlayers = {}
local JailedPlayers = {}

-- Funções padrões
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
    local char = getCharacter(target)
    local myChar = getCharacter(LocalPlayer)
    if char and myChar and myChar:FindFirstChild("HumanoidRootPart") then
        char:MoveTo(myChar.HumanoidRootPart.Position + Vector3.new(0, 2, 0))
    end
end

local function Freeze(target)
    local char = getCharacter(target)
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.Anchored = true
            end
        end
        frozenPlayers[target] = true
    end
end

local function Unfreeze(target)
    local char = getCharacter(target)
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.Anchored = false
            end
        end
        frozenPlayers[target] = nil
    end
end

local function Fling(target)
    local char = getCharacter(target)
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        hrp.Velocity = Vector3.new(math.random(-500,500), 500, math.random(-500,500))
    end
end

local function Kick(target)
    target:Kick("Você foi kickado pelo Nick Hub🤍")
end

local function Kill(target)
    local char = getCharacter(target)
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").Health = 0
    end
end

local function KillPlus(target)
    local char = getCharacter(target)
    if char and char:FindFirstChildOfClass("Humanoid") then
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

-- Função helper para criar partes
local function makePart(props)
    local p = Instance.new("Part")
    for k,v in pairs(props) do
        if k ~= "Parent" then
            p[k] = v
        end
    end
    if props.Parent then p.Parent = props.Parent end
    return p
end

-- Jail / Unjail nova
local function JailPlayerInternal(player)
    if not player or not player.Character then return end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if JailedPlayers[player] then return end

    local size, height, wallT, edgeT = 7, 7, 0.5, 0.18
    local center = hrp.Position + Vector3.new(0,2,0)

    local model = Instance.new("Model")
    model.Name = "Jail_"..player.Name
    model.Parent = workspace

    local floor = makePart{Size=Vector3.new(size,wallT,size),Position=center+Vector3.new(0,-height/2+wallT/2,0),Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
    local ceiling = makePart{Size=Vector3.new(size,wallT,size),Position=center+Vector3.new(0,height/2-wallT/2,0),Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}

    local front = makePart{Size=Vector3.new(size,height,wallT),Position=center+Vector3.new(0,0,size/2-wallT/2),Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
    local back = makePart{Size=Vector3.new(size,height,wallT),Position=center+Vector3.new(0,0,-size/2+wallT/2),Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
    local right = makePart{Size=Vector3.new(wallT,height,size),Position=center+Vector3.new(size/2-wallT/2,0,0),Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
    local left = makePart{Size=Vector3.new(wallT,height,size),Position=center+Vector3.new(-size/2+wallT/2,0,0),Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}

    local cornerOffsets = {
        Vector3.new( size/2-edgeT/2,0, size/2-edgeT/2),
        Vector3.new(-size/2+edgeT/2,0, size/2-edgeT/2),
        Vector3.new( size/2-edgeT/2,0,-size/2+edgeT/2),
        Vector3.new(-size/2+edgeT/2,0,-size/2+edgeT/2),
    }
    for _, off in ipairs(cornerOffsets) do
        local p = makePart{Size=Vector3.new(edgeT,height,edgeT),Position=center+off,Anchored=true,CanCollide=true,Material=Enum.Material.Neon,BrickColor=BrickColor.new("Really black"),Parent=model}
        p.Transparency = 0
        local tween = TweenService:Create(p, TweenInfo.new(1.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.3})
        tween:Play()
    end

    hrp.CFrame = CFrame.new(center.X, floor.Position.Y + wallT/2 + 2, center.Z)
    JailedPlayers[player] = model
end

local function UnjailPlayerInternal(player)
    if JailedPlayers[player] then
        JailedPlayers[player]:Destroy()
        JailedPlayers[player] = nil
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

-- Chat Section
local ChatSection = FuncoesTab:Section({
    Title = "Chat",
    Icon = "bird"
})

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
