--[[
Nick Hub - WindUI Panel (Full Functional with Whitelist Sync FE System + Auto Player Dropdown)
]]

-- Whitelist
local AllowedPlayers = {
	["Foortataq"] = true,
	["Bakugo_Master4"] = true,
	["Kilozord"] = true,
	["victor2014de"] = true,
	["Juninho_3114"] = true,  
	["MeliodaGamer42"] = true,  
	["ESTOQUE333E"] = true,  
	["IAIAOAOAUASIIS"] = true,  
	["eusouluizcria"] = true,

    ["CHIPAIO2"] = true,
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Bloqueia quem não está na whitelist
if not AllowedPlayers[LocalPlayer.Name] then
	return
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

local TweenService = game:GetService("TweenService")

-- Helper
local function getCharacter(plr)
	return plr and (plr.Character or plr.CharacterAdded:Wait())
end

-- FE Sync System
local function AddSyncValues(player)
	local feTag = Instance.new("BoolValue")
	feTag.Name = "NickFEUser"
	feTag.Value = AllowedPlayers[player.Name] or false
	feTag.Parent = player
end

for _, plr in ipairs(Players:GetPlayers()) do
	AddSyncValues(plr)
end

Players.PlayerAdded:Connect(AddSyncValues)

-- Função pra verificar se pode afetar
local function CanAffectTarget(target)
	if not target or not target:IsDescendantOf(Players) then return false end
	local lpTag = LocalPlayer:FindFirstChild("NickFEUser")
	local tgTag = target:FindFirstChild("NickFEUser")
	if not lpTag or not tgTag then return false end
	return lpTag.Value and tgTag.Value
end

-- Chat helper
local function SendCommand(msg)
	local tcs = game:GetService("TextChatService")
	if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
		local channel = tcs.TextChannels.RBXGeneral
		if channel then channel:SendAsync(msg) end
	else
		game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
	end
end

-- WindUI
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

-- Aba principal
local Tab = Window:Tab({ Title = "Funções", Icon = "hammer" })
local Section = Tab:Section({ Title = "Comandos", Icon = "album" })

-- Dropdown dinâmico de jogadores
local playerNames = {}
for _, plr in ipairs(Players:GetPlayers()) do
	table.insert(playerNames, plr.Name)
end

local SelectedPlayer
local playerDropdown

local function UpdateDropdown()
	playerNames = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		table.insert(playerNames, plr.Name)
	end
	if playerDropdown then
		playerDropdown:SetValues(playerNames)
	end
end

Players.PlayerAdded:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(UpdateDropdown)

playerDropdown = Section:Dropdown({
	Title = "Jogadores",
	Values = playerNames,
	Callback = function(value)
		SelectedPlayer = Players:FindFirstChild(value)
	end
})

-- Funções sincronizadas (FE)
local frozenPlayers, JailedPlayers = {}, {}

local function Bring(target)
	if not CanAffectTarget(target) then return end
	local char = getCharacter(target)
	local myChar = getCharacter(LocalPlayer)
	if char and myChar and myChar:FindFirstChild("HumanoidRootPart") then
		char:MoveTo(myChar.HumanoidRootPart.Position + Vector3.new(0, 2, 0))
	end
end

local function Freeze(target)
	if not CanAffectTarget(target) then return end
	local char = getCharacter(target)
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	frozenPlayers[target] = true
end

local function Unfreeze(target)
	if not CanAffectTarget(target) then return end
	local char = getCharacter(target)
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	frozenPlayers[target] = nil
end

local function Fling(target)
	if not CanAffectTarget(target) then return end
	local char = getCharacter(target)
	if char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.Velocity = Vector3.new(math.random(-500,500), 500, math.random(-500,500))
	end
end

local function Kick(target)
	if not CanAffectTarget(target) then return end
	target:Kick("Você foi kickado pelo Nick Hub 🤍")
end

local function Kill(target)
	if not CanAffectTarget(target) then return end
	local char = getCharacter(target)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = 0 end
end

local function JailPlayerInternal(player)
	if not CanAffectTarget(player) then return end
	if not player.Character or JailedPlayers[player] then return end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local size,height,wallT,edgeT = 7,7,0.5,0.18  
	local center = hrp.Position + Vector3.new(0,2,0)  
	local model = Instance.new("Model", workspace)
	model.Name = "Jail_"..player.Name

	local function makePart(props)
		local p = Instance.new("Part")
		for k,v in pairs(props) do if k~="Parent" then p[k]=v end end
		p.Parent = props.Parent
		return p
	end

	local floor = makePart{Size=Vector3.new(size,wallT,size),Position=center+Vector3.new(0,-height/2+wallT/2,0),
	Anchored=true,CanCollide=true,Transparency=0.55,Material=Enum.Material.SmoothPlastic,BrickColor=BrickColor.new("Really black"),Parent=model}
	
	local ceiling = floor:Clone()
	ceiling.Position = center+Vector3.new(0,height/2-wallT/2,0)
	ceiling.Parent = model

	local sides = {"X","Z"}
	for _, axis in ipairs(sides) do
		for sign = -1,1,2 do
			local part = makePart{
				Size = Vector3.new((axis=="X") and wallT or size, height, (axis=="Z") and wallT or size),
				Position = center + Vector3.new(
					(axis=="X") and (sign*(size/2-wallT/2)) or 0,
					0,
					(axis=="Z") and (sign*(size/2-wallT/2)) or 0
				),
				Anchored = true, CanCollide = true, Transparency = 0.55,
				Material = Enum.Material.SmoothPlastic, BrickColor = BrickColor.new("Really black"),
				Parent = model
			}
		end
	end

	hrp.CFrame = CFrame.new(center)
	JailedPlayers[player] = model
end

local function UnjailPlayerInternal(player)
	if CanAffectTarget(player) and JailedPlayers[player] then
		JailedPlayers[player]:Destroy()
		JailedPlayers[player] = nil
	end
end

-- Botões
local actions = {
	{Title="Bring",Func=function() if SelectedPlayer then Bring(SelectedPlayer) end end},
	{Title="Freeze",Func=function() if SelectedPlayer then Freeze(SelectedPlayer) end end},
	{Title="UnFreeze",Func=function() if SelectedPlayer then Unfreeze(SelectedPlayer) end end},
	{Title="Fling",Func=function() if SelectedPlayer then Fling(SelectedPlayer) end end},
	{Title="Kick",Func=function() if SelectedPlayer then Kick(SelectedPlayer) end end},
	{Title="Kill",Func=function() if SelectedPlayer then Kill(SelectedPlayer) end end},
	{Title="Jail",Func=function() if SelectedPlayer then JailPlayerInternal(SelectedPlayer) end end},
	{Title="Unjail",Func=function() if SelectedPlayer then UnjailPlayerInternal(SelectedPlayer) end end},
}

for _, info in ipairs(actions) do
	Section:Button({
		Title = info.Title,
		Desc = "Executa o comando " .. info.Title,
		Callback = info.Func
	})
end

-- Chat
local ChatSection = Tab:Section({ Title = "Chat", Icon = "bird" })
local ChatMessage = ""

ChatSection:Input({
	Title = "Mensagem",
	Placeholder = "Digite a mensagem...",
	Type = "Input",
	Callback = function(msg) ChatMessage = msg end
})

ChatSection:Button({
	Title = "Enviar Chat",
	Desc = "Envia mensagem via FE Sync",
	Callback = function()
		if not SelectedPlayer or ChatMessage == "" or not CanAffectTarget(SelectedPlayer) then return end
		SendCommand(";chat " .. SelectedPlayer.Name .. " " .. ChatMessage)
	end
})
