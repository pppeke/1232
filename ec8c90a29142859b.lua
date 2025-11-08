local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
local newcframe = CFrame.new
local localplayer = LocalPlayer

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false -- Forces AddToggle to AddCheckbox
Library.ShowToggleFrameInKeybinds = true -- Make toggle keybinds work inside the keybinds UI (aka adds a toggle to the UI). Good for mobile users (Default value = true)

local Window = Library:CreateWindow({
	-- Set Center to true if you want the menu to appear in the center
	-- Set AutoShow to true if you want the menu to appear when it is created
	-- Set Resizable to true if you want to have in-game resizable Window
	-- Set MobileButtonsSide to "Left" or "Right" if you want the ui toggle & lock buttons to be on the left or right side of the window
	-- Set ShowCustomCursor to false if you don't want to use the Linoria cursor
	-- NotifySide = Changes the side of the notifications (Left, Right) (Default value = Left)
	-- Position and Size are also valid options here
	-- but you do not need to define them unless you are changing them :)

	Title = "Gucciframes",
	Footer = "paid Gucciframes.  discord.gg/Gucciframes",
	Icon = "rbxassetid://6550202405",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

-- CALLBACK NOTE:
-- Passing in callback functions via the initial element parameters (i.e. Callback = function(Value)...) works
-- HOWEVER, using Toggles/Options.INDEX:OnChanged(function(Value) ... ) is the RECOMMENDED way to do this.
-- I strongly recommend decoupling UI code from logic code. i.e. Create your UI elements FIRST, and THEN setup :OnChanged functions later.


-- Tabs
local Tabs = {
Main = Window:AddTab('Main'),
Dahood = Window:AddTab('Dahood'),
Visuals = Window:AddTab('Visuals'),
Misc = Window:AddTab('Misc'),
Desync = Window:AddTab('Desync'),
['UI Settings'] = Window:AddTab('UI Settings'),
}
--// Legit Settings
getgenv().LegitSettings = {
    SilentAim = {
        Enabled = false,
        Prediction = 0
    }
}

--// Silent Aim FOV
getgenv().SilentAimFOV = {
    Enabled = false,
    Radius = 100
}

--// Orbit Settings
getgenv().OrbitSettings = {
    Enabled = false,
    Radius = 10,
    Speed = 1,
    HeightOffset = 2,
    TeleportBack = false,
    OriginalPosition = nil,
    OrbitBall = {
        Enabled = true,
        Size = 0.5,
        Color = Color3.fromRGB(255, 0, 0)
    }
}

--// Target & Lock Variables
getgenv().CurrentTarget = nil
getgenv().LockOnTarget = false

--// Crosshair Settings
getgenv().crosshair = {
    enabled = true,
    mode = "mouse",
    radius = 11,
    width = 1.5,
    length = 10,
    color = Color3.fromRGB(199, 110, 255),
    spin = true,
    spin_speed = 150,
    spin_max = 340,
    spin_style = Enum.EasingStyle.Sine,
    resize = true,
    resize_speed = 150,
    resize_min = 5,
    resize_max = 22
}

--// Target Visuals
getgenv().target_visuals = {
    enabled = true,
    box = true,
    tracer = true,
    name = true,
    color = Color3.fromRGB(255, 255, 255),
    hitcharms = true,
    coom = false
}

--// Player ESP
getgenv().player_esp = {
    enabled = true,
    box = true,
    name = true,
    tool = true,
    color = Color3.fromRGB(255, 0, 0)
}

--// Silent Aim Whitelist
getgenv().SilentAimWhitelist = getgenv().SilentAimWhitelist or {}

--// Utility Functions
local function isWhitelisted(p)
    return getgenv().SilentAimWhitelist[p.UserId] == true
end

local function monitorTargetHealth()
    local target = getgenv().CurrentTarget
    if not target then return end

    local humanoid = target.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.HealthChanged:Connect(function(health)
            if health <= 0 then
                getgenv().CurrentTarget = nil
            end
        end)
    end
end

--// Get Silent Aim Target
local function GetSilentAimTarget()
    if getgenv().LockOnTarget and getgenv().CurrentTarget and getgenv().CurrentTarget.Parent then
        return getgenv().CurrentTarget
    end

    local closest, shortestDistance = nil, math.huge
    local mouse = game:GetService("UserInputService"):GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and not isWhitelisted(player) then
            local head = player.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude

                if (not getgenv().SilentAimFOV.Enabled) or (distance <= getgenv().SilentAimFOV.Radius) then
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closest = head
                    end
                end
            end
        end
    end

    if not getgenv().LockOnTarget then
        if getgenv().CurrentTarget ~= closest and getgenv().target_visuals.hitcharms then
            getgenv().CurrentTarget = closest
            task.spawn(monitorTargetHealth)
        else
            getgenv().CurrentTarget = closest
        end
    end

    return closest
end

--// GUI Setup
local SilentAimTab = Window:NewTab("Silent Aim")
local SilentAimSection = SilentAimTab:NewSection("Silent Aim Settings")

SilentAimSection:NewToggle("Enabled", "Toggle Silent Aim", function(state)
    getgenv().LegitSettings.SilentAim.Enabled = state
end)

SilentAimSection:NewSlider("Prediction", "Bullet prediction (studs)", 30, 0, function(value)
    getgenv().LegitSettings.SilentAim.Prediction = value
end)

--// Whitelist Dropdown
local whitelistOptions = {}

local function refresh()
    whitelistOptions = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(whitelistOptions, player.Name .. " (" .. player.UserId .. ")")
        end
    end
    return whitelistOptions
end

SilentAimSection:NewDropdown("Whitelist", "Select players to EXCLUDE from aim", refresh(), function(selected)
    getgenv().SilentAimWhitelist = {}
    for _, value in ipairs(selected) do
        local id = tonumber(value:match("%((%d+)%)$"))
        if id then
            getgenv().SilentAimWhitelist[id] = true
        end
    end
end, true)

Players.PlayerAdded:Connect(function(p)
    getgenv().SilentAimWhitelist[p.UserId] = nil
end)

Players.PlayerRemoving:Connect(function(p)
    getgenv().SilentAimWhitelist[p.UserId] = nil
end)



local function tweenCFrame(part, goalCFrame, duration)
local startCFrame = part.CFrame
local elapsed = 0

return coroutine.wrap(function()
while elapsed < duration do
local alpha = elapsed / duration
part.CFrame = startCFrame:Lerp(goalCFrame, alpha)
elapsed = elapsed + RunService.RenderStepped:Wait()
end
part.CFrame = goalCFrame
end)()
end

local Movement = Tabs.Misc:AddLeftGroupbox('Movement')

getgenv().lastHealth = {}
getgenv().lastHitTick = 0
getgenv().hitCooldown = 0.1
local function HitCharmEffect(character)
if not character or not character.Parent then return end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if not rootPart then return end

local charmClone = Instance.new("Model")
charmClone.Name = character.Name .. "_HitCharm"
charmClone.Parent = workspace

for _, part in ipairs(character:GetChildren()) do
if part:IsA("BasePart") then
local partClone = Instance.new(part.ClassName)
partClone.Size = part.Size
partClone.CFrame = part.CFrame
partClone.Anchored = true
partClone.CanCollide = false
partClone.Material = Enum.Material.Plastic
partClone.Color = getgenv().target_visuals.color
partClone.Transparency = 0
partClone.Parent = charmClone
end
end

-- Fade out tween
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
for _, part in ipairs(charmClone:GetChildren()) do
if part:IsA("BasePart") then
game:GetService("TweenService"):Create(part, tweenInfo, {Transparency = 1}):Play()
end
end

-- Cleanup
game:GetService("Debris"):AddItem(charmClone, 2)
end

local function CoomEffect(character)
if not character or not character.Parent then return end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if not rootPart then return end

local attachment = Instance.new("Attachment")
attachment.Name = "CoomAttachment"
attachment.Parent = rootPart

local Foam = Instance.new("ParticleEmitter")
Foam.Name = "Foam"
Foam.LightInfluence = 0.5
Foam.Lifetime = NumberRange.new(1, 1)
Foam.SpreadAngle = Vector2.new(360, -360)
Foam.VelocitySpread = 360
Foam.Squash = NumberSequence.new(1)
Foam.Speed = NumberRange.new(20, 20)
Foam.Brightness = 2.5
Foam.Size = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0),
NumberSequenceKeypoint.new(0.1016692, 0.6508875, 0.6508875),
NumberSequenceKeypoint.new(0.6494689, 1.4201183, 0.4127519),
NumberSequenceKeypoint.new(1, 0)
})
Foam.Enabled = false
Foam.Acceleration = Vector3.new(0, -66.04029846191406, 0)
Foam.Rate = 100
Foam.Texture = "rbxassetid://8297030850"
Foam.Rotation = NumberRange.new(-90, -90)
Foam.Orientation = Enum.ParticleOrientation.VelocityParallel
Foam.Parent = attachment

-- Enable the particle emitter briefly
Foam.Enabled = true
task.delay(1, function()
Foam.Enabled = false
game:GetService("Debris"):AddItem(attachment, 0)
end)
end

local function CoomEffect(character)
if not character or not character.Parent then return end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if not rootPart then return end

local attachment = Instance.new("Attachment")
attachment.Name = "CoomAttachment"
attachment.Parent = rootPart

local Foam = Instance.new("ParticleEmitter")
Foam.Name = "Foam"
Foam.LightInfluence = 0.5
Foam.Lifetime = NumberRange.new(1, 1)
Foam.SpreadAngle = Vector2.new(360, -360)
Foam.VelocitySpread = 360
Foam.Squash = NumberSequence.new(1)
Foam.Speed = NumberRange.new(20, 20)
Foam.Brightness = 2.5
Foam.Size = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0),
NumberSequenceKeypoint.new(0.1016692, 0.6508875, 0.6508875),
NumberSequenceKeypoint.new(0.6494689, 1.4201183, 0.4127519),
NumberSequenceKeypoint.new(1, 0)
})
Foam.Enabled = false
Foam.Acceleration = Vector3.new(0, -66.04029846191406, 0)
Foam.Rate = 100
Foam.Texture = "rbxassetid://8297030850"
Foam.Rotation = NumberRange.new(-90, -90)
Foam.Orientation = Enum.ParticleOrientation.VelocityParallel
Foam.Parent = attachment

-- Enable the particle emitter briefly
Foam.Enabled = true
task.delay(1, function()
Foam.Enabled = false
game:GetService("Debris"):AddItem(attachment, 0)
end)
end

local function monitorTargetHealth()
if not (getgenv().target_visuals.hitcharms or getgenv().target_visuals.coom) or not getgenv().CurrentTarget then return end

local target = getgenv().CurrentTarget
local character = target and target.Parent
if not character then return end

local humanoid = character:FindFirstChildOfClass("Humanoid")
if not humanoid then return end

-- Initialize last health if not set
getgenv().lastHealth[character] = getgenv().lastHealth[character] or humanoid.Health

-- Disconnect previous connection if it exists
if getgenv().currentHealthConnection then
getgenv().currentHealthConnection:Disconnect()
getgenv().currentHealthConnection = nil
end

-- Connect to HealthChanged event
getgenv().currentHealthConnection = humanoid.HealthChanged:Connect(function(newHealth)
if not (getgenv().target_visuals.hitcharms or getgenv().target_visuals.coom) or not getgenv().CurrentTarget then
-- Disconnect if both hit charms and coom are disabled or target is lost
if getgenv().currentHealthConnection then
getgenv().currentHealthConnection:Disconnect()
getgenv().currentHealthConnection = nil
end
return
end

local currentTick = tick()
if newHealth < getgenv().lastHealth[character] and currentTick - getgenv().lastHitTick >= getgenv().hitCooldown then
-- Health decreased and cooldown has passed, trigger effects
if getgenv().target_visuals.hitcharms then
HitCharmEffect(character)
end
if getgenv().target_visuals.coom then
CoomEffect(character)
end
getgenv().lastHitTick = currentTick
end

getgenv().lastHealth[character] = newHealth

-- Clean up if target is dead or invalid
if newHealth <= 0 or not character.Parent or not getgenv().CurrentTarget then
getgenv().lastHealth[character] = nil
if getgenv().currentHealthConnection then
getgenv().currentHealthConnection:Disconnect()
getgenv().currentHealthConnection = nil
end
end
end)
end

-- Metatable Hook
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
if LegitSettings.SilentAim.Enabled and (key == "Hit" or key == "Target") then
local target = GetSilentAimTarget()
if target and target.Parent and target.Parent:FindFirstChild("HumanoidRootPart") then
local predictedPos = target.Position + (target.Parent.HumanoidRootPart.Velocity * LegitSettings.SilentAim.Prediction)
return key == "Hit" and CFrame.new(predictedPos) or target
end
end
return oldIndex(self, key)
end)

setreadonly(mt, true)

-- Visuals Tab
local Rapidfire = Tabs.Dahood:AddLeftGroupbox('Da hood rage')
 Rapidfire:AddToggle('RapidFire', {
    Text = 'Rapidfire',
    Default = false,
    Callback = function(Value)
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            for _, connection in ipairs(getconnections(tool.Activated)) do
                local func = connection.Function
                for i = 1, debug.getinfo(func).nups do
                    local upvalue = debug.getupvalue(func, i)
                    if type(upvalue) == "number" then
                        debug.setupvalue(func, i, Value and 0.0000001 or upvalue)
                    end
                end
            end
        end
    end
})
local RageBox = Tabs.Main:AddLeftGroupbox("Rage")

RageBox:AddToggle('SilentAim', {
Text = 'Enable Silent Aim',
Default = false,
Callback = function(Value)
LegitSettings.SilentAim.Enabled = Value

-- If Silent Aim is enabled AND either LockOnTarget or Hit Charms are active
if Value and getgenv().target_visuals.hitcharms then
-- Start monitoring the current target if it exists
if getgenv().CurrentTarget then
task.spawn(monitorTargetHealth)
end
end
end
})

RageBox:AddToggle('LockOnTargetToggle', {
Text = 'Sticky aim',
Default = false,
Tooltip = 'Freezes the current silent aim target until disabled',
Callback = function(Value)
getgenv().LockOnTarget = Value
if Value and getgenv().target_visuals.hitcharms then
task.spawn(monitorTargetHealth)
else
getgenv().CurrentTarget = nil
if getgenv().currentHealthConnection then
getgenv().currentHealthConnection:Disconnect()
getgenv().currentHealthConnection = nil
end
end
end
})

RageBox:AddLabel("Sticky Aim Keybind"):AddKeyPicker("KeyPicker", {
    Default = "C", -- Default key
    SyncToggleState = true, -- Syncs with parent toggle if you want
    Mode = "Toggle", -- Toggle mode
    Text = "Sticky Aim", -- UI text
    NoUI = false,

    Callback = function(Value)
        -- Toggle sticky aim
        Toggles.LockOnTargetToggle:SetValue(Value)
        getgenv().LockOnTarget = Value

        if not Value then
            -- Reset target + disconnect health listener if sticky aim is turned off
            getgenv().CurrentTarget = nil
            if getgenv().currentHealthConnection then
                getgenv().currentHealthConnection:Disconnect()
                getgenv().currentHealthConnection = nil
            end
        end
    end,

    ChangedCallback = function(New)
        -- Fires when the keybind itself is changed
        getgenv().StickyAimKey = New
    end,
})


-- Fires when keybind is clicked (only in Toggle mode)
Options.KeyPicker:OnClick(function()
    print("", Options.KeyPicker:GetState())
end)

-- Fires when the keybind is reassigned
Options.KeyPicker:OnChanged(function()
    print("", Options.KeyPicker.Value)
end)

-- Background task for monitoring Hold mode or Always mode
task.spawn(function()
    while true do
        task.wait(1)

        local state = Options.KeyPicker:GetState()
        if state and getgenv().LockOnTarget then
            print("Sticky Aim keybind is being held down (active)")
            -- you could call your aim logic here instead of just printing
        end

        if Library.Unloaded then
            break
        end
    end
end)

-- Example: sets keybind to C, mode Toggle
Options.KeyPicker:SetValue({ "C", "Toggle" })


RageBox:AddSlider('SilentAimPrediction', {
Text = 'Prediction',
Min = 0,
Max = 1,
Default = 0.2,
Rounding = 2,
Callback = function(Value) LegitSettings.SilentAim.Prediction = Value end
})

-- Table to store whitelisted UserIds
local whitelist = {}

-- Helper function to update whitelist from selected names
local function updateWhitelist(selectedNames)
whitelist = {}
for _, name in ipairs(selectedNames) do
local plr = Players:FindFirstChild(name)
if plr then
whitelist[plr.UserId] = true
end
end
end

local whitelistDropdown = RageBox:AddDropdown('WhitelistPlayers', {
Text = 'Whitelist Players',
Values = {}, -- empty initially, will fill below
Multi = true,
Default = {},
Tooltip = 'Players who will NOT be targeted by Silent Aim or LockOnTarget',
Callback = function(selected)
updateWhitelist(selected)
print("Whitelist updated:", selected)
end
})

local function refreshWhitelistDropdown()
local playerNames = {}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= Players.LocalPlayer then
table.insert(playerNames, plr.Name)
end
end
whitelistDropdown:SetValues(playerNames) -- works now because whitelistDropdown is the dropdown instance
end

refreshWhitelistDropdown()

Players.PlayerAdded:Connect(refreshWhitelistDropdown)

refreshWhitelistDropdown()

-- Refresh dropdown whenever players join or leave
Players.PlayerAdded:Connect(function(plr)
refreshWhitelistDropdown()
end)
Players.PlayerRemoving:Connect(function(plr)
refreshWhitelistDropdown()
end)

-- Now, wherever you select target, check whitelist before locking on:
-- Example (pseudo):
function isWhitelisted(player)
return whitelist[player.UserId] == true
end

local UserInputService = game:GetService("UserInputService")

local function simulateClick()
UserInputService.InputBegan:Fire(Enum.UserInputType.MouseButton1, true)
end
RageBox:AddToggle('Autoshoot', {
Text = 'Autoshoot',
Default = false,
Callback = function(Value)
getgenv().AutoShootEnabled = Value

if Value then
task.spawn(function()
while getgenv().AutoShootEnabled do
local player = game.Players.LocalPlayer
local character = player.Character
local tool = character and character:FindFirstChildOfClass("Tool")
local target = getgenv().CurrentTarget

-- Check all conditions
local hasForceField = target and target.Parent and target.Parent:FindFirstChildWhichIsA("ForceField")
if LegitSettings.SilentAim.Enabled
and tool
and target
and target.Parent
and not hasForceField then
tool:Activate() -- Safely trigger the tool
end
task.wait(0.2)
end
end)
end
end
})

RageBox:AddToggle('OrbitToggle', {
Text = 'Orbit Target',
Default = false,
Tooltip = 'Makes your character orbit around the silent aim target',
Callback = function(Value)
getgenv().OrbitSettings.Enabled = Value
if not Value then
-- Reset character movement and teleport back if enabled
local character = LocalPlayer.Character
if character and character:FindFirstChild("HumanoidRootPart") then
local hrp = character.HumanoidRootPart
local humanoid = character:FindFirstChildOfClass("Humanoid")
hrp.Velocity = Vector3.new(0, 0, 0)
hrp.Anchored = false
if humanoid then
humanoid.PlatformStand = false
humanoid.WalkSpeed = 16
end
-- Teleport back to original position if enabled
if getgenv().OrbitSettings.TeleportBack and getgenv().OrbitSettings.OriginalPosition then
hrp.CFrame = CFrame.new(getgenv().OrbitSettings.OriginalPosition)
getgenv().OrbitSettings.OriginalPosition = nil -- Clear saved position
end
end
end
end
})

RageBox:AddSlider('OrbitRadius', {
Text = 'Orbit Radius',
Min = 5,
Max = 20,
Default = 10,
Rounding = 1,
Callback = function(Value)
getgenv().OrbitSettings.Radius = Value
end
})

RageBox:AddSlider('OrbitSpeed', {
Text = 'Orbit Speed',
Min = 0.5,
Max = 60,
Default = 1,
Rounding = 1,
Callback = function(Value)
getgenv().OrbitSettings.Speed = Value
end
})

RageBox:AddSlider('OrbitHeightOffset', {
Text = 'Orbit Height Offset',
Min = 0,
Max = 5,
Default = 2,
Rounding = 1,
Callback = function(Value)
getgenv().OrbitSettings.HeightOffset = Value
end
})
RageBox:AddToggle('TeleportBackToggle', {
Text = 'Teleport Back',
Default = false,
Tooltip = 'Teleports back to your original position when orbit is disabled',
Callback = function(Value)
getgenv().OrbitSettings.TeleportBack = Value
end
})
RageBox:AddLabel("Orbit Keybind"):AddKeyPicker("OrbitKeyPicker", {
    Default = "V", -- Default orbit key
    SyncToggleState = false,
    Mode = "Toggle",
    Text = "Orbit Target",

    Callback = function(Value)
        -- This fires whenever the toggle state changes (true/false)
        getgenv().OrbitSettings.Enabled = Value
        Toggles.OrbitToggle:SetValue(Value)

        if not Value then
            -- Reset character when orbiting is disabled
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local hrp = character:FindFirstChild("HumanoidRootPart")

                if humanoid then
                    humanoid.PlatformStand = false
                    humanoid.WalkSpeed = 16
                end

                -- Teleport back if option is enabled
                if getgenv().OrbitSettings.TeleportBack 
                   and getgenv().OrbitSettings.OriginalPosition 
                   and hrp then
                    hrp.CFrame = CFrame.new(getgenv().OrbitSettings.OriginalPosition)
                    getgenv().OrbitSettings.OriginalPosition = nil
                end
            end
        end
    end,

    ChangedCallback = function(New)
        -- Store the new key if you need it later
        getgenv().OrbitSettings.Key = New
    end,
})


-- Fires when you click the keybind (in Toggle mode)
Options.OrbitKeyPicker:OnClick(function()
    local newState = not getgenv().OrbitSettings.Enabled
    getgenv().OrbitSettings.Enabled = newState
    Toggles.OrbitToggle:SetValue(newState)

    if not newState then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")

            if humanoid then
                humanoid.PlatformStand = false
                humanoid.WalkSpeed = 16
            end

            if getgenv().OrbitSettings.TeleportBack and getgenv().OrbitSettings.OriginalPosition and hrp then
                hrp.CFrame = CFrame.new(getgenv().OrbitSettings.OriginalPosition)
                getgenv().OrbitSettings.OriginalPosition = nil
            end
        end
    end

end)

-- Example: set orbit key to V, mode Toggle
Options.OrbitKeyPicker:SetValue({ "V", "Toggle" })



local VisualBox = Tabs.Visuals:AddLeftGroupbox('Misc')
local VisualBox23 = Tabs.Misc:AddLeftGroupbox('Misc')

local NoclipConnection = nil
local Clip = true -- starts clipped
VisualBox23:AddToggle('NoClip', {
Text = 'NoClip',
Default = false,
Tooltip = 'Toggle noclip on/off',
Callback = function(Value)

if Value then
-- Enable noclip
Clip = false
if NoclipConnection then NoclipConnection:Disconnect() end

NoclipConnection = game:GetService('RunService').Stepped:Connect(function()
if Clip == false and game.Players.LocalPlayer.Character then
for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
if part:IsA('BasePart') and part.CanCollide and part.Name ~= floatName then
part.CanCollide = false
end
end
end
end)
else
-- Disable noclip
Clip = true
if NoclipConnection then
NoclipConnection:Disconnect()
NoclipConnection = nil
end

-- Optional: restore collisions when toggling off
if game.Players.LocalPlayer.Character then
for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
if part:IsA('BasePart') then
part.CanCollide = true
end
end
end
end
end
})

-- Spinbot UI and Logic
VisualBox23:AddToggle('spinbot', {
Text = 'Spinbot',
Default = false,
Tooltip = 'Toggle spinbot on/off',
Callback = function(Value)
getgenv().SpinbotEnabled = Value -- Sync toggle state with global variable
end
})

VisualBox23:AddSlider('spinbot_speed', {
Text = 'Spinbot Speed',
Default = 600,
Min = 0,
Max = 1000,
Rounding = 0,
Tooltip = 'Adjust spinbot rotation speed (degrees per second)',
Callback = function(Value)
getgenv().SpinbotSpeed = Value -- Update speed when slider changes
end
})

VisualBox23:AddToggle('Anti Fling', {
Text = 'Anti Fling',
Default = false,
Tooltip = 'Toggle anti fling on/off',
Callback = function(ToggleState)
local Connection

if ToggleState then
Connection = RunService.Stepped:Connect(function()
-- Disable collisions for other players' HumanoidRootPart
for _, CoPlayer in pairs(Players:GetChildren()) do
if CoPlayer ~= Player and CoPlayer.Character then
local RootPart = CoPlayer.Character:FindFirstChild("HumanoidRootPart")
if RootPart and RootPart:IsA("BasePart") then
RootPart.CanCollide = false
end
end
end

-- Destroy accessory parts
for _, Accessory in pairs(workspace:GetChildren()) do
if Accessory:IsA("Accessory") then
local Part = Accessory:FindFirstChildWhichIsA("Part")
if Part then
Part:Destroy()
end
end
end
end)
else
-- Disconnect the connection when toggle is off
if Connection then
Connection:Disconnect()
end
end
end
})

getgenv().SpinbotEnabled = false

-- Function to set up spinbot logic for the character
local function setupSpinbot(character)
if not (character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) then
return
end

local connection
connection = RunService.RenderStepped:Connect(function(delta)
if not (character and character.Parent and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid")) then
connection:Disconnect() -- Clean up if character is gone
return
end

if getgenv().SpinbotEnabled and not getgenv().OrbitSettings.Enabled then -- Avoid conflict with Orbit
character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(getgenv().SpinbotSpeed * delta), 0)
character.Humanoid.AutoRotate = false
else
character.Humanoid.AutoRotate = true
end
end)
end

-- Handle character loading and respawning
LocalPlayer.CharacterAdded:Connect(setupSpinbot)
if LocalPlayer.Character then
setupSpinbot(LocalPlayer.Character)
end

-- Global variables for customization
getgenv().StompToggle = false
getgenv().StompInterval = 0.1 -- Default interval in seconds
getgenv().StompKeybind = Enum.KeyCode.F -- Default keybind

-- Task to handle Stomp firing
task.spawn(function()
    while true do
        task.wait(getgenv().StompInterval)
        if getgenv().StompToggle then
            MainEvent:FireServer("Stomp")
        end
    end
end)



local StompGroup = Tabs.Misc:AddLeftGroupbox('Stomp')

-- Add a toggle to enable/disable Stomp
StompGroup:AddToggle('StompToggle', {
    Text = 'Enable Stomp',
    Default = false,
    Callback = function(Value)
        getgenv().StompToggle = Value
    end
})


-- Add a slider to adjust the fire interval
StompGroup:AddSlider('StompIntervalSlider', {
    Text = 'Stomp Interval (seconds)',
    Default = 0.1,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        getgenv().StompInterval = Value
        print("Stomp interval set to: " .. Value .. " seconds")
    end
})

-- Add a keybind to toggle Stomp
StompGroup:AddLabel('Stomp Keybind'):AddKeyPicker('StompKeyPicker', {
    Default = 'F',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Stomp Toggle Key',
    NoUI = false,
    Callback = function(Value)
        getgenv().StompToggle = Value
        Toggles.StompToggle:SetValue(Value) -- Sync with toggle
        if Value then
            print("Stomp toggled on via keybind")
        else
            print("Stomp toggled off via keybind")
        end
    end,
    ChangedCallback = function(New)
        if New:sub(1,2) == "MB" then
            getgenv().StompKeybind = Enum.UserInputType["MouseButton" .. New:sub(3)]
        else
            getgenv().StompKeybind = Enum.KeyCode[New]
        end
        print("Stomp keybind changed to: " .. New)
    end
})

-- Set initial keybind value
Options.StompKeyPicker:SetValue({"F", "Toggle"})
local PlayerESPBox = Tabs.Visuals:AddLeftGroupbox('Esp')
VisualBox:AddToggle('EnableCrosshair', {
Text = 'Enable Crosshair',
Default = false,
Callback = function(Value) crosshair.enabled = Value end
})

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Get the local player
local player = Players.LocalPlayer

-- Store the model to allow cleanup
local attachedModel = nil


VisualBox:AddToggle('Dickesp', {
    Text = 'Dick esp',
    Default = false,
    Callback = function(enabled)
        local function attachPartsWithHighlight(character)
            if not enabled then
                -- Clean up existing model if toggle is disabled
                if attachedModel then
                    attachedModel:Destroy()
                    attachedModel = nil
                end
                return
            end
            if not character then return end -- Ensure character exists

            local pelvis = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
            if not pelvis then return end

            -- Create model for attached parts
            attachedModel = Instance.new("Model")
            attachedModel.Name = "AttachedParts"
            attachedModel.Parent = Workspace
            attachedModel.PrimaryPart = pelvis

            local parts = {}

            -- Small Ball
            local ball1 = Instance.new("Part")
            ball1.Shape = Enum.PartType.Ball
            ball1.Size = Vector3.new(0.5, 0.5, 0.5)
            ball1.Color = Color3.fromRGB(255, 255, 255)
            ball1.Material = Enum.Material.Neon
            ball1.CanCollide = false
            ball1.Anchored = false
            ball1.CFrame = pelvis.CFrame * CFrame.new(0.2, -0.6, -0.7)
            ball1.Parent = attachedModel
            table.insert(parts, ball1)

            -- Stick
            local stick = Instance.new("Part")
            stick.Size = Vector3.new(0.3, 0.3, 7)
            stick.Color = Color3.fromRGB(255, 255, 255)
            stick.Material = Enum.Material.Neon
            stick.CanCollide = false
            stick.Anchored = false
            stick.CFrame = pelvis.CFrame * CFrame.new(0.07, -0.6, -4.1)
            stick.Parent = attachedModel
            table.insert(parts, stick)

            -- Tall Ball
            local ball2 = Instance.new("Part")
            ball2.Shape = Enum.PartType.Ball
            ball2.Size = Vector3.new(0.5, 4.5, 0.5)
            ball2.Color = Color3.fromRGB(255, 255, 255)
            ball2.Material = Enum.Material.Neon
            ball2.CanCollide = false
            ball2.Anchored = false
            ball2.CFrame = pelvis.CFrame * CFrame.new(-0.1, -0.6, -0.7)
            ball2.Parent = attachedModel
            table.insert(parts, ball2)

            -- Weld parts
            for _, part in pairs(parts) do
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = pelvis
                weld.Part1 = part
                weld.Parent = part
            end

            -- Highlight
            local highlight = Instance.new("Highlight")
            highlight.Parent = attachedModel
            highlight.Adornee = attachedModel
            highlight.FillColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 0
        end

        -- Attach immediately if character exists
        if player.Character then
            attachPartsWithHighlight(player.Character)
        end

        -- Attach on respawn
        player.CharacterAdded:Connect(attachPartsWithHighlight)
    end
})

VisualBox:AddToggle('EnableCrosshair', {
Text = 'sigma lighting🥴',
Default = false,
Callback = function(enabled)
local function clearEffects()
for _, v in ipairs(Lighting:GetChildren()) do
if v:IsA("BlurEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Sky") then
v:Destroy()
end
end
for _, obj in ipairs(Workspace:GetDescendants()) do
local h = obj:FindFirstChild("rtx_highlight")
if h then h:Destroy() end
if obj:IsA("BasePart") then
local light = obj:FindFirstChild("RTX_Light")
if light then light:Destroy() end
end
end
end

if enabled then
clearEffects()

Lighting.Technology = Enum.Technology.Future
Lighting.ClockTime =  0
Lighting.Brightness = 2.2
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.8
Lighting.EnvironmentSpecularScale = 1
Lighting.Ambient = Color3.fromRGB(65, 65, 65)
Lighting.OutdoorAmbient = Color3.fromRGB(110, 110, 110)
Lighting.FogColor = Color3.fromRGB(150, 170, 210)
Lighting.FogStart = 0
Lighting.FogEnd = 700
Lighting.ColorShift_Top = Color3.fromRGB(20, 20, 20)
Lighting.ColorShift_Bottom = Color3.fromRGB(10, 10, 10)

local sky = Instance.new("Sky")
sky.Name = "RTX_Sky"
sky.SkyboxBk = "rbxassetid://160405144"
sky.SkyboxDn = "rbxassetid://160405144"
sky.SkyboxFt = "rbxassetid://160405144"
sky.SkyboxLf = "rbxassetid://160405144"
sky.SkyboxRt = "rbxassetid://160405144"
sky.SkyboxUp = "rbxassetid://160405144"
sky.MoonAngularSize = 10
sky.SunAngularSize = 12
sky.StarCount = 2500
sky.CelestialBodiesShown = true
sky.Parent = Lighting

local sun = Instance.new("SunRaysEffect", Lighting)
sun.Intensity = 0
sun.Spread = 0.2

local bloom = Instance.new("BloomEffect", Lighting)
bloom.Intensity = 0
bloom.Threshold = 1
bloom.Size = 60

local cc = Instance.new("ColorCorrectionEffect", Lighting)
cc.Contrast = 0.08
cc.Saturation = 0.05
cc.Brightness = 0.01
cc.TintColor = Color3.fromRGB(225, 235, 255)

local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0

local dof = Instance.new("DepthOfFieldEffect", Lighting)
dof.InFocusRadius = 160
dof.FocusDistance = 75
dof.NearIntensity = 0.1
dof.FarIntensity = 0.2

TweenService:Create(sun, TweenInfo.new(1), {Intensity = 0.1}):Play()
TweenService:Create(bloom, TweenInfo.new(1), {Intensity = 0.4}):Play()
TweenService:Create(cc, TweenInfo.new(1), {
Contrast = 0.08,
Saturation = 0.05,
Brightness = 0.01,
TintColor = Color3.fromRGB(225, 235, 255)
}):Play()
TweenService:Create(blur, TweenInfo.new(1), {Size = 1}):Play()

local function addHighlight(part)
if part:IsA("BasePart") and not part:FindFirstChild("rtx_highlight") then
local h = Instance.new("Highlight")
h.Name = "rtx_highlight"
h.Adornee = part
h.DepthMode = Enum.HighlightDepthMode.Occluded
h.FillTransparency = 1
h.OutlineTransparency = 0.9
h.OutlineColor = Color3.fromRGB(0, 0, 0)
h.Parent = part
end
end

local function addLampLight(part)
if part:IsA("BasePart") and not part:FindFirstChild("RTX_Light") then
local name = part.Name:lower()
if name:find("lamp") or name:find("light") or name:find("bulb") or name:find("neon") then
local light = Instance.new("PointLight")
light.Name = "RTX_Light"
light.Brightness = 2.8
light.Range = 20
light.Color = Color3.fromRGB(255, 235, 210)
light.Shadows = true
light.Parent = part
end
end
end

for _, obj in ipairs(Workspace:GetDescendants()) do
addHighlight(obj)
addLampLight(obj)
end

Workspace.DescendantAdded:Connect(function(obj)
task.defer(function()
addHighlight(obj)
addLampLight(obj)
end)
end)
else
clearEffects()
end
end
})

VisualBox:AddDropdown('CrosshairMode', {
Text = 'Crosshair Mode',
Default = 2,
Values = {'Center', 'Mouse', 'Target'},
Callback = function(Value)
local map = {
['Center'] = 'center',
['Mouse'] = 'mouse',
['Target'] = 'target'
}
crosshair.mode = map[Value]
end
})

local VisualBox2 = Tabs.Visuals:AddRightGroupbox('Target Visuals')

VisualBox2:AddToggle('HitCharms', {
Text = 'Hit Charms',
Default = true,
Tooltip = 'Creates a neon clone of the target when hit',
Callback = function(Value)
getgenv().target_visuals.hitcharms = Value
if Value and getgenv().CurrentTarget then
-- Start monitoring health if a target exists
task.spawn(monitorTargetHealth)
else
-- Disconnect health monitoring if disabled
if getgenv().currentHealthConnection then
getgenv().currentHealthConnection:Disconnect()
getgenv().currentHealthConnection = nil
end
end
end
})

VisualBox2:AddToggle('CoomEffect', {
Text = 'cum Effect',
Default = false,
Tooltip = 'Applies a particle effect to the target when hit',
Callback = function(Value)
getgenv().target_visuals.coom = Value
if Value and getgenv().CurrentTarget then
-- Start monitoring health if a target exists
task.spawn(monitorTargetHealth)
else
-- Disconnect health monitoring if disabled and hit charms is also disabled
if not getgenv().target_visuals.hitcharms and getgenv().currentHealthConnection then
getgenv().currentHealthConnection:Disconnect()
getgenv().currentHealthConnection = nil
end
end
end
})

VisualBox2:AddToggle('TargetVisuals', {
Text = 'Enable Target Visuals',
Default = true,
Callback = function(Value) target_visuals.enabled = Value end
})
VisualBox2:AddToggle('ShowBox', {
Text = 'Show Box',
Default = true,
Callback = function(Value) target_visuals.box = Value end
})
VisualBox2:AddToggle('ShowTracer', {
Text = 'Show Tracer',
Default = true,
Callback = function(Value) target_visuals.tracer = Value end
})
VisualBox2:AddToggle('ShowName', {
Text = 'Show Name',
Default = true,
Callback = function(Value) target_visuals.name = Value end
})



PlayerESPBox:AddToggle('PlayerESPEnabled', {
Text = 'Enable Player ESP',
Default = true,
Callback = function(Value) player_esp.enabled = Value end
})

PlayerESPBox:AddToggle('PlayerBoxESP', {
Text = 'Box',
Default = true,
Callback = function(Value) player_esp.box = Value end
})

PlayerESPBox:AddToggle('PlayerNameESP', {
Text = 'Name',
Default = true,
Callback = function(Value) player_esp.name = Value end
})

PlayerESPBox:AddToggle('PlayerToolESP', {
Text = 'Tool',
Default = true,
Callback = function(Value) player_esp.tool = Value end
})

PlayerESPBox:AddLabel('Color'):AddColorPicker('PlayerESPColor', {
Default = Color3.fromRGB(255, 0, 0),
Callback = function(Value) player_esp.color = Value end
})

-- Drawings
local runservice = game:GetService('RunService')
local input = game:GetService('UserInputService')
local camera = workspace.CurrentCamera

local drawings = {
crosshair = {},
text = {
Drawing.new("Text"),
Drawing.new("Text")
},
target = {
box = Drawing.new("Square"),
tracer = Drawing.new("Line"),
name = Drawing.new("Text")
},
players = {}
}



for i = 1, 2 do drawings.crosshair[i] = Drawing.new("Line") end

local function solve(angle, radius)
return Vector2.new(
math.sin(math.rad(angle)) * radius,
math.cos(math.rad(angle)) * radius
)
end

local function SetupPlayerESP(player)
if player == LocalPlayer or isWhitelisted(player) then return end

-- Initialize drawing objects for this player
drawings.players[player] = {
box = Drawing.new("Square"),
name = Drawing.new("Text"),
tool = Drawing.new("Text")
}

local esp = drawings.players[player]
esp.box.Thickness = 1
esp.box.Filled = false
esp.box.Color = player_esp.color
esp.box.Visible = false

esp.name.Size = 13
esp.name.Font = 2
esp.name.Outline = true
esp.name.Color = player_esp.color
esp.name.Visible = false

esp.tool.Size = 12
esp.tool.Font = 2
esp.tool.Outline = true
esp.tool.Color = player_esp.color
esp.tool.Visible = false
end

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
SetupPlayerESP(player)
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
SetupPlayerESP(player)
end)

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
if drawings.players[player] then
for _, drawing in pairs(drawings.players[player]) do
drawing:Remove()
end
drawings.players[player] = nil
end
end)

-- Render Loop
runservice.PostSimulation:Connect(function()
local tick_now = tick()

-- Orbit Logic
if (getgenv().OrbitSettings.Enabled or getgenv().OrbitSettings.SpoofOrbit) and LegitSettings.SilentAim.Enabled then
local target = GetSilentAimTarget()
if target and target.Parent then
local targetHrp = target.Parent:FindFirstChild("HumanoidRootPart")
local playerChar = LocalPlayer.Character
if targetHrp and playerChar and playerChar:FindFirstChild("HumanoidRootPart") then
local playerHrp = playerChar.HumanoidRootPart
local humanoid = playerChar:FindFirstChildOfClass("Humanoid")
local MainEvent = game:GetService("ReplicatedStorage"):FindFirstChild("MainEvent")

-- Calculate orbit position
local time = tick() * getgenv().OrbitSettings.Speed
local offset = Vector3.new(
math.cos(time) * getgenv().OrbitSettings.Radius,
getgenv().OrbitSettings.HeightOffset,
math.sin(time) * getgenv().OrbitSettings.Radius
)
local targetPos = targetHrp.Position
local orbitPos = targetPos + offset

-- Check for collisions using Raycast to avoid terrain/objects
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {playerChar, target.Parent}
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local rayResult = workspace:Raycast(targetPos, orbitPos - targetPos, rayParams)
if rayResult then
orbitPos = rayResult.Position + (orbitPos - targetPos).Unit * 0.5
end

if getgenv().OrbitSettings.SpoofOrbit then
-- Spoof Orbit: Send fake position to server without moving client
if MainEvent then
local success, err = pcall(function()
MainEvent:FireServer("UpdatePosition", {
Position = orbitPos,
Anchored = false
})
end)
if not success then
Library:Notify("Spoof Orbit failed: MainEvent error (" .. tostring(err) .. ")", 5)
end
else
Library:Notify("Spoof Orbit failed: MainEvent not found", 5)
getgenv().OrbitSettings.SpoofOrbit = false
Toggles.SpoofOrbitToggle:SetValue(false)
end
else
-- Regular Orbit: Move client-side character
if getgenv().OrbitSettings.Enabled then
if getgenv().OrbitSettings.TeleportBack and not getgenv().OrbitSettings.OriginalPosition then
getgenv().OrbitSettings.OriginalPosition = playerHrp.Position
end
local currentCFrame = playerHrp.CFrame
local targetCFrame = CFrame.new(orbitPos, targetPos)
playerHrp.CFrame = currentCFrame:Lerp(targetCFrame, 0.1)
playerHrp.Velocity = Vector3.new(0, 0, 0)
if humanoid then
humanoid.PlatformStand = true
humanoid.WalkSpeed = 0
end
end
end

-- Orbiting Ball Visual
if getgenv().OrbitSettings.OrbitBall.Enabled then
local orbitBall = workspace:FindFirstChild("OrbitBall_" .. LocalPlayer.Name)
if not orbitBall then
orbitBall = Instance.new("Part")
orbitBall.Name = "OrbitBall_" .. LocalPlayer.Name
orbitBall.Shape = Enum.PartType.Ball
orbitBall.Size = Vector3.new(
getgenv().OrbitSettings.OrbitBall.Size,
getgenv().OrbitSettings.OrbitBall.Size,
getgenv().OrbitSettings.OrbitBall.Size
)
orbitBall.BrickColor = BrickColor.new(getgenv().OrbitSettings.OrbitBall.Color)
orbitBall.Material = Enum.Material.Neon
orbitBall.CanCollide = false
orbitBall.Anchored = true
orbitBall.Parent = workspace
end
-- Update ball position based on OrbitBall.Mode
local ballOffset = Vector3.new(
math.cos(time) * getgenv().OrbitSettings.Radius,
getgenv().OrbitSettings.HeightOffset,
math.sin(time) * getgenv().OrbitSettings.Radius
)
local ballBasePos = getgenv().OrbitSettings.OrbitBall.Mode == "Target" and targetHrp.Position or playerHrp.Position
orbitBall.CFrame = CFrame.new(ballBasePos + ballOffset)
else
-- Remove orbiting ball if disabled
local orbitBall = workspace:FindFirstChild("OrbitBall_" .. LocalPlayer.Name)
if orbitBall then
orbitBall:Destroy()
end
end
else
-- Disable orbit if target or player character is invalid
getgenv().OrbitSettings.Enabled = false
getgenv().OrbitSettings.SpoofOrbit = false
Toggles.OrbitToggle:SetValue(false)
Toggles.SpoofOrbitToggle:SetValue(false)
if playerChar and playerChar:FindFirstChildOfClass("Humanoid") then
local humanoid = playerChar:FindFirstChildOfClass("Humanoid")
humanoid.PlatformStand = false
humanoid.WalkSpeed = 16
if getgenv().OrbitSettings.TeleportBack and getgenv().OrbitSettings.OriginalPosition then
local playerHrp = playerChar.HumanoidRootPart
playerHrp.CFrame = CFrame.new(getgenv().OrbitSettings.OriginalPosition)
getgenv().OrbitSettings.OriginalPosition = nil
end
-- Remove orbiting ball
local orbitBall = workspace:FindFirstChild("OrbitBall_" .. LocalPlayer.Name)
if orbitBall then
orbitBall:Destroy()
end
end
end
else
-- Disable orbit if no valid target
getgenv().OrbitSettings.Enabled = false
getgenv().OrbitSettings.SpoofOrbit = false
Toggles.OrbitToggle:SetValue(false)
Toggles.SpoofOrbitToggle:SetValue(false)
if playerChar and playerChar:FindFirstChildOfClass("Humanoid") then
local humanoid = playerChar:FindFirstChildOfClass("Humanoid")
humanoid.PlatformStand = false
humanoid.WalkSpeed = 16
if getgenv().OrbitSettings.TeleportBack and getgenv().OrbitSettings.OriginalPosition then
local playerHrp = playerChar.HumanoidRootPart
playerHrp.CFrame = CFrame.new(getgenv().OrbitSettings.OriginalPosition)
getgenv().OrbitSettings.OriginalPosition = nil
end
-- Remove orbiting ball
local orbitBall = workspace:FindFirstChild("OrbitBall_" .. LocalPlayer.Name)
if orbitBall then
orbitBall:Destroy()
end
end
end
elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
-- Reset humanoid state when orbit is disabled
local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if humanoid then
humanoid.PlatformStand = false
humanoid.WalkSpeed = 16
if getgenv().OrbitSettings.TeleportBack and getgenv().OrbitSettings.OriginalPosition then
local playerHrp = LocalPlayer.Character.HumanoidRootPart
playerHrp.CFrame = CFrame.new(getgenv().OrbitSettings.OriginalPosition)
getgenv().OrbitSettings.OriginalPosition = nil
end
-- Remove orbiting ball
local orbitBall = workspace:FindFirstChild("OrbitBall_" .. LocalPlayer.Name)
if orbitBall then
orbitBall:Destroy()
end
end
-- Reset server position if spoof orbit was active
if getgenv().OrbitSettings.SpoofOrbit then
getgenv().OrbitSettings.SpoofOrbit = false
Toggles.SpoofOrbitToggle:SetValue(false)
local MainEvent = game:GetService("ReplicatedStorage"):FindFirstChild("MainEvent")
local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if MainEvent and hrp then
local success, err = pcall(function()
MainEvent:FireServer("UpdatePosition", {
Position = hrp.Position,
Anchored = false
})
end)
if not success then
Library:Notify("Failed to reset server position: " .. tostring(err), 5)
end
else
Library:Notify("Failed to reset server position: MainEvent or HRP not found", 5)
end
-- Disable client freeze
getgenv().OrbitSettings.FreezeClient = false
if _G.FreezeConnection then
_G.FreezeConnection:Disconnect()
_G.FreezeConnection = nil
end
end
end


for _, d in pairs(drawings.target) do d.Visible = false end
if target_visuals.enabled and LegitSettings.SilentAim.Enabled then
local t = GetSilentAimTarget()
if t and t.Parent then
local hrp = t.Parent:FindFirstChild("HumanoidRootPart")
local head = t.Parent:FindFirstChild("Head")
if hrp and head then
local hPos, hOn = camera:WorldToViewportPoint(head.Position)
local rPos, rOn = camera:WorldToViewportPoint(hrp.Position)
local sizeY = (camera:WorldToViewportPoint(hrp.Position + Vector3.new(2, 3, 0)).Y -
camera:WorldToViewportPoint(hrp.Position - Vector3.new(2, 3, 0)).Y)

if hOn and rOn then
if target_visuals.box then
drawings.target.box.Visible = true
drawings.target.box.Position = Vector2.new(rPos.X - sizeY * 0.3, rPos.Y - sizeY / 2)
drawings.target.box.Size = Vector2.new(sizeY * 0.6, sizeY)
drawings.target.box.Color = target_visuals.color
drawings.target.box.Thickness = 1
end

if target_visuals.tracer then
drawings.target.tracer.Visible = true
drawings.target.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
drawings.target.tracer.To = Vector2.new(rPos.X, rPos.Y)
drawings.target.tracer.Color = target_visuals.color
drawings.target.tracer.Thickness = 1.5
end

if target_visuals.name then
drawings.target.name.Visible = true
drawings.target.name.Text = t.Parent.Name
drawings.target.name.Position = Vector2.new(hPos.X - drawings.target.name.TextBounds.X / 2, hPos.Y - 20)
drawings.target.name.Color = target_visuals.color
drawings.target.name.Size = 13
drawings.target.name.Outline = true
end
end
end
end
end

-- Clear all player ESP drawings
for _, playerDrawings in pairs(drawings.players) do
for _, drawing in pairs(playerDrawings) do
drawing.Visible = false
end
end

-- General Player ESP
if player_esp.enabled then
for _, player in ipairs(Players:GetPlayers()) do
if player == LocalPlayer or isWhitelisted(player) then continue end
local esp = drawings.players[player]
if not esp then continue end

local character = player.Character
if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Head") and character:FindFirstChildOfClass("Humanoid") and character.Humanoid.Health > 0 then
local hrp = character.HumanoidRootPart
local head = character.Head
local hPos, hOn = camera:WorldToViewportPoint(head.Position)
local rPos, rOn = camera:WorldToViewportPoint(hrp.Position)
local sizeY = (camera:WorldToViewportPoint(hrp.Position + Vector3.new(2, 3, 0)).Y -
camera:WorldToViewportPoint(hrp.Position - Vector3.new(2, 3, 0)).Y)

if hOn and rOn then
if player_esp.box then
esp.box.Visible = true
esp.box.Position = Vector2.new(rPos.X - sizeY * 0.3, rPos.Y - sizeY / 2)
esp.box.Size = Vector2.new(sizeY * 0.6, sizeY)
esp.box.Color = player_esp.color
end

if player_esp.name then
esp.name.Visible = true
esp.name.Text = player.Name
esp.name.Position = Vector2.new(hPos.X - esp.name.TextBounds.X / 2, hPos.Y - 20)
esp.name.Color = player_esp.color
end

if player_esp.tool then
local tool = character:FindFirstChildOfClass("Tool")
esp.tool.Text = tool and tool.Name or "No Tool"
esp.tool.Position = Vector2.new(hPos.X - esp.tool.TextBounds.X / 2, hPos.Y + sizeY / 2 + 5) -- below the box
esp.tool.Color = player_esp.color
esp.tool.Visible = true
end
end
end
end
end
end)
-- Available Sound IDs
local soundOptions = {
["Bubble"] = "rbxassetid://6534947588",
["Lazer"] = "rbxassetid://130791043",
["Disco"] = "rbxassetid://1347140027",
["Pop"] = "rbxassetid://198598793",
["Rust"] = "rbxassetid://1255040462",
["Sans"] = "rbxassetid://3188795283",
["Fart"] = "rbxassetid://130833677",
["Big"] = "rbxassetid://5332005053",
["Vine"] = "rbxassetid://5332680810",
["UwU"] = "rbxassetid://8679659744",
["Bruh"] = "rbxassetid://4578740568",
["Skeet"] = "rbxassetid://5633695679",
["Neverlose"] = "rbxassetid://6534948092",
["Fatality"] = "rbxassetid://6534947869",
["Bonk"] = "rbxassetid://5766898159",
["Minecraft"] = "rbxassetid://5869422451",
["Gamesense"] = "rbxassetid://4817809188",
["RIFK7"] = "rbxassetid://9102080552",
["Bamboo"] = "rbxassetid://3769434519",
["Crowbar"] = "rbxassetid://546410481",
["Weeb"] = "rbxassetid://6442965016",
["Beep"] = "rbxassetid://8177256015",
["Bambi"] = "rbxassetid://8437253821",
["Stone"] = "rbxassetid://3581383408",
["Old Fatality"] = "rbxassetid://6607142036",
["Click"] = "rbxassetid://8053704437",
["Ding"] = "rbxassetid://7149516994",
["Snow"] = "rbxassetid://6455527632",
["Laser"] = "rbxassetid://7837461331",
["Mario"] = "rbxassetid://2815207981",
["Steve"] = "rbxassetid://4965083997",
["Call of Duty"] = "rbxassetid://5952120301",
["Bat"] = "rbxassetid://3333907347",
["TF2 Critical"] = "rbxassetid://296102734",
["Saber"] = "rbxassetid://8415678813",
["Baimware"] = "rbxassetid://3124331820",
["Osu"] = "rbxassetid://7149255551",
["TF2"] = "rbxassetid://2868331684",
["Slime"] = "rbxassetid://6916371803",
["Among Us"] = "rbxassetid://5700183626",
["One"] = "rbxassetid://7380502345",
["Bone Breaking"] = "rbxassetid://8029615457"
}

local soundLabels = {}
for name, _ in pairs(soundOptions) do
table.insert(soundLabels, name)
end
getgenv().customSoundId = soundOptions["Laser"]

local function updateShootSound(container)
local shootSound = container:FindFirstChild("Shoot", true)
if shootSound and shootSound:IsA("Sound") then
shootSound.SoundId = getgenv().customSoundId
end
end

local function applySoundEverywhere()
if LocalPlayer.Character then
updateShootSound(LocalPlayer.Character)
end

local backpack = LocalPlayer:FindFirstChild("Backpack")
if backpack then
for _, tool in ipairs(backpack:GetChildren()) do
updateShootSound(tool)
end
end
end

local Sound = Tabs.Misc:AddLeftGroupbox('hood customs')
Sound:AddDropdown('ShootSoundDropdown', {
Values = soundLabels,
Default = 2,
Text = 'ShootSound Selector',
Tooltip = 'Pick your gun sound effect',
Callback = function(selected)
getgenv().customSoundId = soundOptions[selected]
applySoundEverywhere()
end
})

-- Character respawn hook
LocalPlayer.CharacterAdded:Connect(function(char)
task.wait(1)
updateShootSound(char)
end)

-- Backpack hook
local backpack = LocalPlayer:WaitForChild("Backpack")
backpack.ChildAdded:Connect(function(child)
task.wait(0.5)
updateShootSound(child)
end)

-- Initial + reapply loop
task.wait(1)
applySoundEverywhere()
task.spawn(function()
while task.wait(5) do
applySoundEverywhere()
end
end)

-- Available Sound IDs
local soundOptions2 = {
    ["Bubble"] = "rbxassetid://6534947588",
    ["Lazer"] = "rbxassetid://130791043",
    ["Pick"] = "rbxassetid://1347140027",
    ["Pop"] = "rbxassetid://198598793",
    ["Rust"] = "rbxassetid://1255040462",
    ["Sans"] = "rbxassetid://3188795283",
    ["Fart"] = "rbxassetid://130833677",
    ["Big"] = "rbxassetid://5332005053",
    ["Vine"] = "rbxassetid://5332680810",
    ["UwU"] = "rbxassetid://8679659744",
    ["Bruh"] = "rbxassetid://4578740568",
    ["Skeet"] = "rbxassetid://5633695679",
    ["Neverlose"] = "rbxassetid://6534948092",
    ["Fatality"] = "rbxassetid://6534947869",
    ["Bonk"] = "rbxassetid://5766898159",
    ["Minecraft"] = "rbxassetid://5869422451",
    ["Gamesense"] = "rbxassetid://4817809188",
    ["RIFK7"] = "rbxassetid://9102080552",
    ["Bamboo"] = "rbxassetid://3769434519",
    ["Crowbar"] = "rbxassetid://546410481",
    ["Weeb"] = "rbxassetid://6442965016",
    ["Beep"] = "rbxassetid://8177256015",
    ["Bambi"] = "rbxassetid://8437203821",
    ["Stone"] = "rbxassetid://3581383408",
    ["Old Fatality"] = "rbxassetid://6607142036",
    ["Click"] = "rbxassetid://8053704437",
    ["Ding"] = "rbxassetid://7149516994",
    ["Snow"] = "rbxassetid://6455527632",
    ["Laser"] = "rbxassetid://7837461331",
    ["Mario"] = "rbxassetid://2815207981",
    ["Steve"] = "rbxassetid://4965083997",
    ["Call of Duty"] = "rbxassetid://5952120301",
    ["Bat"] = "rbxassetid://3333907347",
    ["TF2 Critical"] = "rbxassetid://296102734",
    ["Saber"] = "rbxassetid://8415678813",
    ["Baimware"] = "rbxassetid://3124331820",
    ["Osu"] = "rbxassetid://7149255551",
    ["TF2"] = "rbxassetid://2868331684",
    ["Slime"] = "rbxassetid://6916371803",
    ["Among Us"] = "rbxassetid://5700183626",
    ["One"] = "rbxassetid://7380502345"
}

local soundLabels = {}
for name, _ in pairs(soundOptions2) do
    table.insert(soundLabels, name)
end

getgenv().customSoundId = soundOptions["Laser"]

local function updateShootSound(container)
    local shootSound = container:FindFirstChild("ShootSound", true)
    if shootSound and shootSound:IsA("Sound") then
        shootSound.SoundId = getgenv().customSoundId
        shootSound:Stop()
        shootSound:Play()
    end
end

local function applySoundEverywhere()
    if LocalPlayer.Character then
        updateShootSound(LocalPlayer.Character)
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            updateShootSound(tool)
        end
    end
end

-- Character respawn hook
LocalPlayer.CharacterAdded:Connect(function(char)
task.wait(1)
updateShootSound(char)
end)

-- Backpack hook
local backpack = LocalPlayer:WaitForChild("Backpack")
backpack.ChildAdded:Connect(function(child)
task.wait(0.5)
updateShootSound(child)
end)

-- Initial + reapply loop
task.wait(1)
applySoundEverywhere()
task.spawn(function()
while task.wait(5) do
applySoundEverywhere()
end
end)

local Sound = Tabs.Misc:AddLeftGroupbox('Da hood')

Sound:AddDropdown('ShootSoundDropdown', {
    Values = soundLabels,
    Default = 2,
    Text = 'ShootSound Selector',
    Tooltip = 'Pick your gun sound effect',
    Callback = function(selected)
        getgenv().customSoundId = soundOptions2[selected]
        applySoundEverywhere()
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    updateShootSound(char)
end)

local backpack = LocalPlayer:WaitForChild("Backpack")
backpack.ChildAdded:Connect(function(child)
    task.wait(0.5)
    updateShootSound(child)
end)

local users = {
    {UserId = 8208385845, UserName = "amir"},
    {UserId = 22782710, UserName = "cat"},
    {UserId = 1631538060, UserName = "7.xtrnl"},
    {UserId = 1631538061, UserName = "7.xtrnl_unique"}, -- Changed UserId
}

local CopyAppearance = true
local HasHeadLess = true
local HasKorblox = true

local function Morph(UserId, PlayerName)
local appearance = Players:GetCharacterAppearanceAsync(UserId)
local player = Players:FindFirstChild(PlayerName)
if not player or not player.Character then return end

for _, v in pairs(player.Character:GetChildren()) do
if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then
v:Destroy()
end
end
if player.Character.Head:FindFirstChild("face") then
player.Character.Head.face:Destroy()
end
for _, v in pairs(appearance:GetChildren()) do
if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
v.Parent = player.Character
elseif v:IsA("Accessory") then
player.Character.Humanoid:AddAccessory(v)
elseif v.Name == "R15" then
if player.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
local mesh = v:FindFirstChildOfClass("CharacterMesh")
if mesh then
mesh.Parent = player.Character
end
end
end
end
if appearance:FindFirstChild("face") then
appearance.face.Parent = player.Character.Head
else
local face = Instance.new("Decal")
face.Face = Enum.NormalId.Front
face.Name = "face"
face.Texture = "rbxasset://textures/face.png"
face.Transparency = 0
face.Parent = player.Character.Head
end

local parent = player.Character.Parent
player.Character.Parent = nil
player.Character.Parent = parent
end
local Avatar = Tabs.Misc:AddLeftGroupbox('Avatar')

local toggle = Avatar:AddToggle('ForceReset', {
Text = 'Force resets you',
Default = false,
Callback = function(state)
if state then
local player = game.Players.LocalPlayer
local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
if humanoid then
humanoid.RigType = Enum.HumanoidRigType.R6
player.Character:BreakJoints()
end
end
end
})

local dropdown = Avatar:AddDropdown('Char', {
Text = 'Select User to Morph Into',
Default = 'None',
Values = {users[1].UserName, users[2].UserName, users[3].UserName},
Callback = function(selectedUserName)
for _, user in pairs(users) do
if user.UserName == selectedUserName then
if CopyAppearance then
if HasHeadLess then
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
LocalPlayer.Character.Head.MeshId = 6686307858
end
end
if HasKorblox then
local char = LocalPlayer.Character
if char then
char.RightLowerLeg.MeshId = "902942093"
char.RightLowerLeg.Transparency = 1
char.RightUpperLeg.MeshId = "http://www.roblox.com/asset/?id=902942096"
char.RightUpperLeg.TextureID = "http://roblox.com/asset/?id=902843398"
char.RightFoot.MeshId = "902942089"
char.RightFoot.Transparency = 1
end
end
Morph(user.UserId, LocalPlayer.Name)
end
break
end
end
end
})

LocalPlayer.CharacterAdded:Connect(function()
wait(1)
local selectedUserName = dropdown.Value
for _, user in pairs(users) do
if user.UserName == selectedUserName then
if CopyAppearance then
Morph(user.UserId, LocalPlayer.Name)
end
break
end
end
end)

local player = game.Players.LocalPlayer
local TryhardEnabled = false

local function applyTryhardAnimations()
local character = player.Character
if not character then return end
local animate = character:FindFirstChild("Animate")
if not animate then return end

local function setAnim(animName, id)
local anim = animate:FindFirstChild(animName)
if anim and anim:FindFirstChildOfClass("Animation") then
anim:FindFirstChildOfClass("Animation").AnimationId = id
end
end

setAnim("run", "http://www.roblox.com/asset/?id=616163682")
setAnim("jump", "http://www.roblox.com/asset/?id=10921242013")
setAnim("fall", "http://www.roblox.com/asset/?id=707829716")
setAnim("climb", "http://www.roblox.com/asset/?id=5319816685")
setAnim("swim", "http://www.roblox.com/asset/?id=707876443")
setAnim("swimidle", "http://www.roblox.com/asset/?id=707894699")
setAnim("walk", "http://www.roblox.com/asset/?id=616168032")

local idle = animate:FindFirstChild("idle")
if idle then
local anim1 = idle:FindFirstChild("Animation1")
local anim2 = idle:FindFirstChild("Animation2")
if anim1 then anim1.AnimationId = "http://www.roblox.com/asset/?id=3303162274" end
if anim2 then anim2.AnimationId = "http://www.roblox.com/asset/?id=3303162549" end
end
end

local function onCharacterAdded(character)
if TryhardEnabled then
applyTryhardAnimations()
end
end

player.CharacterAdded:Connect(onCharacterAdded)

Avatar:AddToggle("TryhardAnimation", {
Text = "Tryhard Animation",
Default = false,
Tooltip = "Enable custom tryhard animation set",
Callback = function(state)
TryhardEnabled = state
if TryhardEnabled and player.Character then
applyTryhardAnimations()
end
end
})

-- // Variables


local flying = false
local FlyToggleEnabled = false -- UI toggle state
local FlyKey = Enum.KeyCode.F
local speed = 50
local ascendSpeed = 100
local descendSpeed = 1
local TryhardEnabled = false

-- // Functions
local function toggleFly()
flying = not flying
print(flying and "Fly ON" or "Fly OFF")
end

local function applyTryhardAnimations()
-- Your custom animation code here
print("Applying Tryhard animations...")
end

-- // Movement Loop
RunService.RenderStepped:Connect(function()
if not flying then return end

local char = player.Character
if not char then return end
local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end
local cam = workspace.CurrentCamera
if not cam then return end

local move = Vector3.new()
local forward = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z).Unit

if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end

local vertical = -descendSpeed
if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
vertical = ascendSpeed
elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
vertical = -ascendSpeed
end

hrp.AssemblyLinearVelocity = Vector3.new(move.X * speed, vertical, move.Z * speed)
hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector * Vector3.new(1, 0, 1))
end)

-- // Keybind detection (only works if toggle is ON)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then return end
if FlyToggleEnabled and input.KeyCode == FlyKey then
toggleFly()
end
end)

-- // UI Setup
Movement:AddToggle("FlyToggle", {
Text = "Enable Fly",
Default = false,
Tooltip = "Toggle flight mode",
Callback = function(state)
FlyToggleEnabled = state
if not state then
flying = false -- turn off fly if toggle disabled
end
end
})

Movement:AddLabel('Fly Keybind'):AddKeyPicker('FlyKeyPicker', {
Default = 'F',
SyncToggleState = false,
Mode = 'Toggle',
Text = 'Fly Toggle Key',
NoUI = false,
Callback = function(keyName)
if keyName:sub(1,2) == "MB" then
FlyKey = Enum.UserInputType["MouseButton" .. keyName:sub(3)]
else
FlyKey = Enum.KeyCode[keyName]
end
end
})
-- // NEW Speed Slider
Movement:AddSlider("FlySpeedSlider", {
Text = "Fly Speed",
Default = 50,
Min = 10,
Max = 500,
Rounding = 0,
Compact = false,
Callback = function(value)
speed = value
print("Fly speed set to:", value)
end
})

local danceAnimations = {
    ["None"] = "",
    ["Floss"] = "rbxassetid://10714340543",
    ["Disco"] = "rbxassetid://3333136415",
    ["Happy"] = "rbxassetid://4841405708",
    ["Hero Landing"] = "rbxassetid://5104344710",
    ["Old Town Road"] = "rbxassetid://5937560570",
    ["River Dance"] = "rbxassetid://3333432454",
    ["Shuffle"] = "rbxassetid://4349242221",
    ["Cutesy"] = "rbxassetid://4265725525",
    ["Yungblud Happier Jump"] = "rbxassetid://15609995579",
    ["Fashion"] = "rbxassetid://3333331310",
    ["Baby Dance"] = "rbxassetid://4265725525",
    ["Cha-Cha"] = "rbxassetid://6862001787",
    ["Monkey"] = "rbxassetid://3333499508",
    ["Top Rock"] = "rbxassetid://3361276673",
    ["Around Town"] = "rbxassetid://3303391864",
    ["Fancy Feet"] = "rbxassetid://3333432454",
    ["Hype Dance"] = "rbxassetid://3695333486",
    ["Bodybuilder"] = "rbxassetid://3333387824",
    ["Idol"] = "rbxassetid://4101966434",
    ["Curtsy"] = "rbxassetid://4555816777",
    ["Quiet Waves"] = "rbxassetid://7465981288",
    ["Sleep"] = "rbxassetid://4686925579",
    ["Floss Dance"] = "rbxassetid://5917459365",
    ["Shy"] = "rbxassetid://3337978742",
    ["Godlike"] = "rbxassetid://3337994105",
    ["High Wave"] = "rbxassetid://5915690960",
    ["Cower"] = "rbxassetid://4940563117",
    ["Bored"] = "rbxassetid://5230599789",
    ["Show Dem Wrists - KSI"] = "rbxassetid://7198989668",
    ["Celebrate"] = "rbxassetid://3338097973",
    ["Dash"] = "rbxassetid://582855105",
    ["Beckon"] = "rbxassetid://5230598276",
    ["Haha"] = "rbxassetid://3337966527",
    ["Lasso Turn - Tai Verdes"] = "rbxassetid://7942896991",
    ["Line Dance"] = "rbxassetid://4049037604",
    ["Shrug"] = "rbxassetid://3334392772",
    ["Point2"] = "rbxassetid://3344585679",
    ["Stadium"] = "rbxassetid://3338055167",
    ["Confused"] = "rbxassetid://4940561610",
    ["Side to Side"] = "rbxassetid://3333136415",
    ["Hello"] = "rbxassetid://3344650532",
    ["Dolphin Dance"] = "rbxassetid://5918726674",
    ["Samba"] = "rbxassetid://6869766175",
    ["Break Dance"] = "rbxassetid://5915648917",
    ["Hips Poppin' - Zara Larsson"] = "rbxassetid://6797888062",
    ["Wake Up Call - KSI"] = "rbxassetid://7199000883",
    ["Greatest"] = "rbxassetid://3338042785",
    ["On The Outside - Twenty One"] = "rbxassetid://7422779536",
    ["Boxing Punch - KSI"] = "rbxassetid://7202863182",
    ["Sad"] = "rbxassetid://4841407203",
    ["Flowing Breeze"] = "rbxassetid://7465946930",
    ["Twirl"] = "rbxassetid://3334968680",
    ["Jumping Wave"] = "rbxassetid://4940564896",
    ["HOLIDAY Dance - Lil Nas X"] = "rbxassetid://5937558680",
    ["Take Me Under - Zara Larsson"] = "rbxassetid://6797890377",
    ["Dizzy"] = "rbxassetid://3361426436",
    ["Dancing' Shoes - Twenty One"] = "rbxassetid://7404878500",
    ["Fashionable"] = "rbxassetid://3333331310",
    ["Fast Hands"] = "rbxassetid://4265701731",
    ["Tree"] = "rbxassetid://4049551434",
    ["Agree"] = "rbxassetid://4841397952",
    ["Power Blast"] = "rbxassetid://4841403964",
    ["Swoosh"] = "rbxassetid://3361481910",
    ["Jumping Cheer"] = "rbxassetid://5895324424",
    ["Disagree"] = "rbxassetid://4841401869",
    ["Rodeo Dance - Lil Nas X"] = "rbxassetid://5918728267",
    ["It Ain't My Fault - Zara Larsson"] = "rbxassetid://6797891807",
    ["Rock On"] = "rbxassetid://5915714366",
    ["Block Partier"] = "rbxassetid://6862022283",
    ["Dorky Dance"] = "rbxassetid://4212455378",
    ["Zombie"] = "rbxassetid://4210116953",
    ["AOK - Tai Verdes"] = "rbxassetid://7942885103",
    ["T"] = "rbxassetid://3338010159",
    ["Cobra Arms - Tai Verdes"] = "rbxassetid://7942890105",
    ["Panini Dance - Lil Nas X"] = "rbxassetid://5915713518",
    ["Fishing"] = "rbxassetid://3334832150",
    ["Robot"] = "rbxassetid://3338025566",
    ["Saturday Dance - Twenty One"] = "rbxassetid://7422807549",
    ["Keeping Time"] = "rbxassetid://4555808220",
    ["Air Dance"] = "rbxassetid://4555782893",
    ["Rock Guitar - Royal Blood"] = "rbxassetid://6532134724",
    ["Borock's Rage"] = "rbxassetid://3236842542",
    ["Ud'zal's Summoning"] = "rbxassetid://3303161675",
    ["Y"] = "rbxassetid://4349285876",
    ["Swan Dance"] = "rbxassetid://7465997989",
    ["Louder"] = "rbxassetid://3338083565",
    ["Up and Down - Twenty One"] = "rbxassetid://7422797678",
    ["Swish"] = "rbxassetid://3361481910",
    ["Drummer Moves - Twenty One"] = "rbxassetid://7422527690",
    ["Sneaky"] = "rbxassetid://3334424322",
    ["Heisman Pose"] = "rbxassetid://3695263073",
    ["Jacks"] = "rbxassetid://3338066331",
    ["Cha-Cha 2"] = "rbxassetid://3695322025",
    ["BURBERRY LOLA ATTITUDE - NIMBUS"] = "rbxassetid://10147821284",
    ["BURBERRY LOLA ATTITUDE - GEM"] = "rbxassetid://10147815602",
    ["BURBERRY LOLA ATTITUDE - HYDRO"] = "rbxassetid://10147823318",
    ["BURBERRY LOLA ATTITUDE - BLOOM"] = "rbxassetid://10147817997",
    ["Superhero Reveal"] = "rbxassetid://3695373233",
    ["Air Guitar"] = "rbxassetid://3695300085",
    ["Dismissive Wave"] = "rbxassetid://3333272779",
    ["Country Line Dance - Lil Nas X"] = "rbxassetid://5915712534",
    ["Salute"] = "rbxassetid://3333474484",
    ["Applaud"] = "rbxassetid://5915693819",
    ["Get Out"] = "rbxassetid://3333272779",
    ["Hwaiting (화이팅)"] = "rbxassetid://9527885267",
    ["Annyeong (안녕)"] = "rbxassetid://9527883498",
    ["Bunny Hop"] = "rbxassetid://4641985101",
    ["Sandwich Dance"] = "rbxassetid://4406555273",
    ["Hyperfast 5G Dance Move"] = "rbxassetid://9408617181",
    ["Victory - 24kGoldn"] = "rbxassetid://9178377686",
    ["Tantrum"] = "rbxassetid://5104341999",
    ["Rock Star - Royal Blood"] = "rbxassetid://10714400171",
    ["Drum Solo - Royal Blood"] = "rbxassetid://6532839007",
    ["Drum Master - Royal Blood"] = "rbxassetid://6531483720",
    ["High Hands"] = "rbxassetid://9710985298",
    ["Tilt"] = "rbxassetid://3334538554",
    ["Gashina - SUNMI"] = "rbxassetid://9527886709",
    ["Chicken Dance"] = "rbxassetid://4841399916",
    ["You can't sit with us - Sunmi"] = "rbxassetid://9983520970",
    ["Frosty Flair - Tommy Hilfiger"] = "rbxassetid://10214311282",
    ["Floor Rock Freeze - Tommy Hilfiger"] = "rbxassetid://10214314957",
    ["Boom Boom Clap - George Ezra"] = "rbxassetid://10370346995",
}


local danceNames = {}
for name in pairs(danceAnimations) do
table.insert(danceNames, name)
end

local danceEnabled = false
local currentDanceName = danceNames[1]
local currentDanceId = danceAnimations[currentDanceName]
local danceTrack = nil

local function setupDanceAnimation()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 5)
if not humanoid then
warn("Failed to find Humanoid for dance animation")
return
end

local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
animator = Instance.new("Animator")
animator.Parent = humanoid
end

if danceTrack then
danceTrack:Stop()
danceTrack:Destroy()
danceTrack = nil
end

local danceAnimation = Instance.new("Animation")
danceAnimation.AnimationId = currentDanceId
danceTrack = animator:LoadAnimation(danceAnimation)
danceTrack.Priority = Enum.AnimationPriority.Action
end

local function playDance()
if not danceEnabled then return end

if not danceTrack then
setupDanceAnimation()
end

if danceTrack then
danceTrack:Play()
else
warn("Failed to play dance animation: danceTrack not initialized")
end
end

player.CharacterAdded:Connect(function(character)
if danceEnabled then
task.wait(1)
setupDanceAnimation()
playDance()
end
end)

if player.Character then
setupDanceAnimation()
end

Avatar:AddToggle("EnableDance", {
Text = "Enable Dance",
Default = false,
Tooltip = "Toggles the selected dance animation",
Callback = function(enabled)
danceEnabled = enabled
if enabled then
setupDanceAnimation()
playDance()
else
if danceTrack then
danceTrack:Stop()
end
end
end
})

Avatar:AddDropdown("SelectDance", {
Text = "Select Dance Animation",
Default = danceNames[1],
Values = danceNames,
Tooltip = "Choose a dance animation to play",
Callback = function(selection)
currentDanceName = selection
currentDanceId = danceAnimations[selection]
if danceEnabled then
setupDanceAnimation()
playDance()
end
end
})

local laggyEmoteEnabled = false
local laggyCoroutine

Avatar:AddToggle("LaggyEmoteToggle", {
Text = "Laggy Emote",
Default = false,
Tooltip = "Makes the emote animation stutter/lag",
Callback = function(enabled)
laggyEmoteEnabled = enabled

if laggyEmoteEnabled and danceTrack then
if laggyCoroutine then
coroutine.close(laggyCoroutine)
end

laggyCoroutine = coroutine.create(function()
while laggyEmoteEnabled and danceTrack and danceTrack.IsPlaying do
if math.random() < 0.6 then
local rewindTime = 0.1
local newPos = math.max(0, danceTrack.TimePosition - rewindTime)
danceTrack.TimePosition = newPos
end
task.wait(0.1)
end
end)
coroutine.resume(laggyCoroutine)
else
if laggyCoroutine then
coroutine.close(laggyCoroutine)
laggyCoroutine = nil
end
if danceTrack and not danceTrack.IsPlaying then
danceTrack:Play()
end
end
end
})

local Misc = Tabs.Misc:AddLeftGroupbox('Misc')
local Desync = Tabs.Desync:AddLeftGroupbox('Desync')
local config = {
    freeze_delay = 0.5,
    smooth = true
}

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local localPlayer = players.LocalPlayer

-- Function to get HumanoidRootPart safely
local function getHRP()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart", 5)
end

-- Function to set physics sender rate
local setPhysicsSenderRate = (function()
    local fflag = "S2PhysicsSenderRate"
    return function(rate)
        setfflag(fflag, tostring(rate))
    end
end)()

-- Function to set NetworkIsSleeping property
local setSleepingState = (function()
    local property = "NetworkIsSleeping"
    return function(state)
        local rootPart = getHRP()
        if rootPart then
            pcall(function()
                sethiddenproperty(rootPart, property, state)
            end)
        end
    end
end)()

-- Toggle: Desync + FakePos
Desync:AddToggle("DesyncToggle", {
    Text = "Fake Position",
    Default = false,
    Tooltip = "Toggle Fake Position desync",
    Callback = function(enabled)
        if enabled then
            -- Ensure character and HRP exist
            if not getHRP() then
                return
            end

            -- Initial physics sender rate
            setPhysicsSenderRate(32767)

            -- Apply small velocity boost (from new logic)
            for _ = 1, 3 do
                local hrp = getHRP()
                if hrp then
                    pcall(function()
                        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, 1, 0)
                    end)
                end
                runService.Heartbeat:Wait()
            end

            -- Freeze simulation
            local startTime = tick()
            while tick() - startTime < config.freeze_delay do end

            -- Adjust toggle rate based on smooth config
            local toggleRate = config.smooth and 4 or 2
            setPhysicsSenderRate(15)

            -- Heartbeat loop for NetworkIsSleeping flipping
            if not _G.DesyncConn then
                local stepCounter = 1
                _G.DesyncConn = runService.Heartbeat:Connect(function()
                    stepCounter = (stepCounter % toggleRate) + 1
                    local isSleeping = stepCounter % toggleRate ~= 0
                    setSleepingState(isSleeping)
                end)
            end
        else
            -- Turn off and cleanup
            if _G.DesyncConn then
                _G.DesyncConn:Disconnect()
                _G.DesyncConn = nil
            end

            -- Reset NetworkIsSleeping
            setSleepingState(false)
            setPhysicsSenderRate(200) -- Restore default rate
        end
    end
})



--// Config
local Skins = {
    Enabled = true,
    ["DoubleBarrel"] = "Ascension",
    ["Revolver"] = "Ascension",
    ["TacticalShotgun"] = "Ascension",
    ["SMG"] = "Ascension",
    ["Shotgun"] = "Ascension",
    Special = { ["Knife"] = "" }
}

local HandleMap = { DB_HANDLE = "DoubleBarrel", REV_HANDLE = "Revolver" }

getgenv().BulletChanger = getgenv().BulletChanger or {
    Enabled = true,
    DoubleBarrel = "Beta",
    Revolver = "Beta",
    TacticalShotgun = "Beta",
    SMG = "Beta",
    Shotgun = "Beta"
}

local Subscription = { Enabled = true, SubscriptionData = 16, SubscriptionStreak = 53 }

local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

--// Helpers
local function isbasepart(x) return typeof(x) == "Instance" and x:IsA("BasePart") end

local function ensureprimarypart(m)
    if m and m:IsA("Model") then
        if not isbasepart(m.PrimaryPart) then
            m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart")
        end
        return m.PrimaryPart
    end
end

local function prepparts(model)
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
            p.Anchored = false
            p.Massless = true
            p.Transparency = 0
        end
    end
end

local function weldparts(a,b)
    if isbasepart(a) and isbasepart(b) then
        local w = Instance.new("WeldConstraint")
        w.Part0 = a
        w.Part1 = b
        w.Parent = a
        return w
    end
end

local function getwrapskinmodel(weaponname, skinname, timeout)
    timeout = timeout or 5
    local ok, wraps = pcall(function() return ReplicatedStorage:WaitForChild("Wraps", timeout) end)
    if not ok or not wraps then return nil end
    local ok2, folder = pcall(function() return wraps:WaitForChild("["..weaponname.."]", timeout) end)
    if not ok2 or not folder then return nil end
    if not skinname or skinname=="" then return nil end
    local ok3, skinmodel = pcall(function() return folder:WaitForChild(skinname, timeout) end)
    if not ok3 or not skinmodel then return nil end
    return skinmodel
end

local function applymodelonholder(holder, skinmodel)
    if not holder or not skinmodel then return end
    local handle = holder:FindFirstChild("Handle")
    if not isbasepart(handle) then return end
    local clone = skinmodel:Clone()
    local pp = ensureprimarypart(clone)
    if not isbasepart(pp) then return end
    prepparts(clone)
    clone.Parent = holder
    clone:SetPrimaryPartCFrame(handle.CFrame)
    weldparts(handle, pp)
    handle.Transparency = 1
end

local function defer(fn) task.defer(fn) end

--// Skin & Bullet Functions
local function applyskin(tool)
    defer(function()
        if not tool or not tool:IsA("Tool") or not Skins.Enabled then return end
        local weaponname = tool.Name:match("^%[(.+)%]$")
        local skinname = weaponname and Skins[weaponname]
        if skinname and skinname~="" then
            local skinmodel = getwrapskinmodel(weaponname, skinname)
            if skinmodel then applymodelonholder(tool, skinmodel) end
        end
    end)
end

local function applyknifeskin(tool)
    defer(function()
        if not tool or not tool:IsA("Tool") or tool.Name~="[Knife]" or not Skins.Enabled then return end
        local knifeskin = Skins.Special and Skins.Special["Knife"]
        if knifeskin and knifeskin~="" then
            local knives = ReplicatedStorage:FindFirstChild("Knives")
            if knives then
                local skinmodel = knives:FindFirstChild(knifeskin)
                if skinmodel then applymodelonholder(tool, skinmodel) end
            end
        end
    end)
end

local function applyskinhandle(character,hname)
    defer(function()
        local weaponname = HandleMap[hname]
        local skinname = weaponname and Skins[weaponname]
        if not skinname or skinname=="" then return end
        local handlefolder = character:FindFirstChild(hname) or character:WaitForChild(hname,5)
        if not handlefolder then return end
        local skinmodel = getwrapskinmodel(weaponname,skinname)
        if skinmodel then applymodelonholder(handlefolder,skinmodel) end
    end)
end

local function buildbullets()
    local mapping = {
        DoubleBarrel="109d1326878cc594bc1bb42d126250810999782f",
        Revolver="539db315b53f77390c0aa74773158e25bedcdd6e",
        Shotgun="b415a7273aa86cbc2adc445fde5435eb5afababa",
        SMG="005af87725b42ac4ca8103d11af6bf0c7d55f7b3",
        TacticalShotgun="109d1326878cc594bc1bb42d126250810999782f"
    }
    local out={}
    for w,skin in pairs(getgenv().BulletChanger or {}) do
        local code=mapping[w]
        if code and skin~="" then out[code]={Name=skin} end
    end
    return HttpService:JSONEncode(out)
end

local function buildequippedbullets()
    local mapping = {
        DoubleBarrel="109d1326878cc594bc1bb42d126250810999782f",
        Revolver="539db315b53f77390c0aa74773158e25bedcdd6e",
        Shotgun="b415a7273aa86cbc2adc445fde5435eb5afababa",
        SMG="005af87725b42ac4ca8103d11af6bf0c7d55f7b3",
        TacticalShotgun="109d1326878cc594bc1bb42d126250810999782f"
    }
    local equipped={}
    for k,v in pairs(mapping) do equipped["["..k.."]"]=v end
    return HttpService:JSONEncode(equipped)
end

local function applybulletdata(datafolder)
    if not datafolder then return end
    defer(function()
        local subscriptionfolder=datafolder:FindFirstChild("Subscription")
        if subscriptionfolder then
            local s=subscriptionfolder:FindFirstChild("HasSubscription")
            if s and s:IsA("BoolValue") then s.Value=Subscription.Enabled end
            local d=subscriptionfolder:FindFirstChild("SubscriptionData")
            if d and d:IsA("NumberValue") then d.Value=Subscription.SubscriptionData end
            local st=subscriptionfolder:FindFirstChild("SubscriptionStreak")
            if st and st:IsA("NumberValue") then st.Value=Subscription.SubscriptionStreak end
        end
        local inv=datafolder:FindFirstChild("InventoryData")
        local eq=datafolder:FindFirstChild("EquippedBulletBeams")
        if inv then
            local bb=inv:FindFirstChild("BulletBeams")
            if bb and bb:IsA("StringValue") then bb.Value=buildbullets() end
        end
        if eq and eq:IsA("StringValue") then eq.Value=buildequippedbullets() end
    end)
end

local function applybullets(tool)
    defer(function()
        if not tool or not tool:IsA("Tool") or not getgenv().BulletChanger.Enabled then return end
        local weaponname=tool.Name:match("^%[(.+)%]$")
        local desired=(getgenv().BulletChanger or {})[weaponname]
        if desired and desired~="" then
            for _,b in ipairs(tool:GetDescendants()) do
                if b:IsA("Beam") then b.Texture=desired end
            end
        end
    end)
end

-- keep track of processed tools
local processed=setmetatable({}, {__mode="k"})
local function ontooladded(tool)
    if processed[tool] then return end
    processed[tool]=true
    applyskin(tool)
    applyknifeskin(tool)
    applybullets(tool)
end

local function applyhandles(character)
    for h in pairs(HandleMap) do applyskinhandle(character,h) end
end

local function connectcharacter(char)
    -- Ensure Backpack exists
    local Backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:WaitForChild("Backpack",5)
    
    -- Connect tool added in backpack
    Backpack.ChildAdded:Connect(ontooladded)
    
    -- Connect tools added to character and handle skins
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then ontooladded(child)
        elseif HandleMap[child.Name] then applyskinhandle(char,child.Name) end
    end)
    
    applyhandles(char)
    
    for _,t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then ontooladded(t) end
    end
    
    local datafolder=LocalPlayer:FindFirstChild("DataFolder") or LocalPlayer:WaitForChild("DataFolder",5)
    if datafolder then
        applybulletdata(datafolder)
        datafolder.ChildAdded:Connect(function(c)
            if c.Name=="InventoryData" or c.Name=="EquippedBulletBeams" then applybulletdata(datafolder) end
        end)
    end
end

-- Connect existing character or wait for one
if LocalPlayer.Character then
    connectcharacter(LocalPlayer.Character)
else
    LocalPlayer.CharacterAdded:Wait()
    connectcharacter(LocalPlayer.Character)
end

-- Connect future character spawns
LocalPlayer.CharacterAdded:Connect(connectcharacter)

--// UI Integration
RageBox:AddToggle('SkinsToggle', {
    Text = 'Weapon Skins',
    Default = Skins.Enabled,
    Tooltip = 'Enable or disable applying weapon skins',
    Callback = function(Value)
        Skins.Enabled = Value
        if Value then
            local char = LocalPlayer.Character
            if char then
                for _,t in ipairs(LocalPlayer.Backpack:GetChildren()) do ontooladded(t) end
                for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") then ontooladded(t) end end
                applyhandles(char)
            end
        end
    end
})

RageBox:AddDropdown('WeaponSkinDropdown', {
    Values = { "Ascension", "Beta", "Default", "Void Dragon", "Hallows", "Heartbringer"},
    Default = "Ascension",
    Multi = false,
    Text = 'Weapon Skin',
    Tooltip = 'Choose skin for all weapons',
    Callback = function(Value)
        for weapon,_ in pairs(Skins) do
            if type(Skins[weapon]) == "string" then
                Skins[weapon] = Value
            elseif type(Skins[weapon]) == "table" then
                for sub,_ in pairs(Skins[weapon]) do
                    Skins[weapon][sub] = Value
                end
            end
        end
        local char = LocalPlayer.Character
        if Skins.Enabled and char then
            for _,t in ipairs(LocalPlayer.Backpack:GetChildren()) do ontooladded(t) end
            for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") then ontooladded(t) end end
            applyhandles(char)
        end
        print("Applied global skin:", Value)
    end
})

RageBox:AddToggle('BulletChangerToggle', {
    Text = 'Bullet Changer',
    Default = getgenv().BulletChanger.Enabled,
    Tooltip = 'Enable or disable bullet textures',
    Callback = function(Value)
        getgenv().BulletChanger.Enabled = Value
        local df = LocalPlayer:FindFirstChild("DataFolder")
        if df then applybulletdata(df) end
    end
})

RageBox:AddDropdown('BulletChangerDropdown', {
    Values = { "Beta", "Default", "Custom", "Lightning", "Hallows", "Kitty", "Kirumi", "Rainbow"  },
    Default = "Beta",
    Multi = false,
    Text = 'Bullet Texture',
    Tooltip = 'Choose texture for bullets',
    Callback = function(Value)
        for weapon,_ in pairs(getgenv().BulletChanger) do
            if weapon ~= "Enabled" then
                getgenv().BulletChanger[weapon] = Value
            end
        end
        local df = LocalPlayer:FindFirstChild("DataFolder")
        if df then applybulletdata(df) end
        local char = LocalPlayer.Character
        if char then
            for _,t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") then applybullets(t) end
            end
        end
        for _,t in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if t:IsA("Tool") then applybullets(t) end
        end
        print("Bullet texture set to:", Value)
    end
})

Misc:AddToggle("ReallySkinnyNaN", {
Text = "Get Really Skinny (FE)",
Default = false,
Tooltip = "This is for trolling",
Callback = function(value)
if value then
game.ReplicatedStorage.MainEvent:FireServer("ChangeMuscleInformation", "NaN")
end
end
})

Misc:AddToggle("ReallySkinnyNormal", {
Text = "normal weight",
Default = false,
Tooltip = "",
Callback = function(value)
if value then
game.ReplicatedStorage.MainEvent:FireServer("ChangeMuscleInformation", "100")
end
end
})

Misc:AddToggle("Chatspy", {
Text = "Chatspy",
Default = false,
Tooltip = "see the chat",
Callback = function(state)
game:GetService("TextChatService").ChatWindowConfiguration.Enabled = state
end
})

Movement:AddToggle('Speed', {
Text = 'WalkSpeed',
Default = false,
Callback = function(Value)
if Value then
local AkaliNotif = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/Dynissimo/main/Scripts/AkaliNotif.lua"))();
local Notify = AkaliNotif.Notify;

Notify({
Description = "Loaded speed";
Title = "!";
Duration = 15;
});

getgenv().Speed = true
getgenv().FakeMacro = false

loadstring(game:HttpGet("https://raw.githubusercontent.com/Allvideo/nukermode/main/Kit%20tools.txt"))()
else
getgenv().Speed = false
end
end
})

Desync:AddToggle('OrbitBallToggle', {
Text = 'Orbit Ball Visual',
Default = false,
Tooltip = 'Shows a line orbiting to visualize the orbit path',
Callback = function(Value)
getgenv().OrbitSettings.OrbitBall.Enabled = Value
if not Value then
local orbitLine = workspace:FindFirstChild("OrbitLine_" .. LocalPlayer.Name)
if orbitLine then
orbitLine:Destroy()
end
end
end
})

Desync:AddSlider('OrbitBallSize', {
Text = 'Orbit Ball Size',
Min = 0.1,
Max = 2,
Default = 0.5,
Rounding = 1,
Callback = function(Value)
getgenv().LegitSettings.SilentAim.Size = Value
local orbitBall = workspace:FindFirstChild("OrbitBall_" .. LocalPlayer.Name)
if orbitBall then
orbitBall.Size = Vector3.new(Value, Value, Value)
end
end
})

Desync:AddDropdown('OrbitBallMode', {
Text = 'Orbit Ball Mode',
Default = 'Player',
Values = {'Player', 'Target'},
Tooltip = 'Choose whether the orbiting ball follows your character or the target',
Callback = function(Value)
getgenv().OrbitSettings.OrbitBall.Mode = Value
end
})
-- Variables for Smooth Teleport-Walk CFrame Speed Hack
local cframeTeleportEnabled = false
local cframeTeleportDistance = 10 -- Default teleport distance per step (studs)
local cframeTeleportKey = Enum.KeyCode.T -- Default key
local teleportInterval = 0.033 -- Time between teleports (~30Hz for smoothness)
local lastTeleport = 0 -- Timestamp of last teleport
local tweenInfo = TweenInfo.new(0.03, Enum.EasingStyle.Linear) -- Smooth tween duration

-- Function to get safe target position with collision check
local function getSafeTargetPosition(currentPos, direction, distance)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local rayResult = workspace:Raycast(currentPos, direction * distance, rayParams)
    if rayResult then
        -- Stop just before collision
        return rayResult.Position - (direction * 0.1) -- Small offset
    else
        -- No collision, move full distance
        return currentPos + (direction * distance)
    end
end

-- Function to handle smooth teleport-walk movement
local function setupCFrameTeleport()
    local character = LocalPlayer.Character
    if not (character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")) then
        return
    end

    local hrp = character.HumanoidRootPart
    local camera = workspace.CurrentCamera
    local mainEvent = game:GetService("ReplicatedStorage"):FindFirstChild("MainEvent")

    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not cframeTeleportEnabled then
            connection:Disconnect()
            return
        end

        if not (character and character.Parent and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChildOfClass("Humanoid")) then
            connection:Disconnect()
            return
        end

        -- Check if enough time has passed for the next teleport
        local currentTime = tick()
        if currentTime - lastTeleport < teleportInterval then
            return
        end

        -- Get movement direction from input
        local moveDirection = Vector3.new()
        local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
        local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - right
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            local targetPos = getSafeTargetPosition(hrp.Position, moveDirection, cframeTeleportDistance)
            local targetCFrame = CFrame.new(targetPos, targetPos + Vector3.new(moveDirection.X, 0, moveDirection.Z))

            -- Smoothly tween to the target position
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
            tween:Play()
            lastTeleport = currentTime

            -- Update server position to reduce anti-cheat flags
            if mainEvent then
                pcall(function()
                    mainEvent:FireServer("UpdatePosition", {
                        Position = targetPos,
                        Anchored = false
                    })
                end)
            end
        end
    end)
end

-- Add Smooth Teleport-Walk CFrame Speed Hack to Movement Groupbox
Movement:AddToggle('CFrameTeleportToggle', {
    Text = 'cframe walk',
    Default = false,
    Tooltip = 'Smooth teleport-based movement with collision detection',
    Callback = function(Value)
        cframeTeleportEnabled = Value
        if Value then
            setupCFrameTeleport()
        end
    end
})

Movement:AddSlider('CFrameTeleportSlider', {
    Text = 'cframe speed',
    Default = 10,
    Min = 2,
    Max = 20,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        cframeTeleportDistance = Value
    end
})

Movement:AddLabel('Teleport Speed Keybind'):AddKeyPicker('CFrameTeleportKeyPicker', {
    Default = 'T',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Teleport Speed Toggle',
    NoUI = false,
    Callback = function(Value)
        cframeTeleportEnabled = Value
        Toggles.CFrameTeleportToggle:SetValue(Value) -- Sync with toggle
        if Value then
            setupCFrameTeleport()
        end
    end,
    ChangedCallback = function(New)
        if New:sub(1,2) == "MB" then
            cframeTeleportKey = Enum.UserInputType["MouseButton" .. New:sub(3)]
        else
            cframeTeleportKey = Enum.KeyCode[New]
        end
    end
})

-- Set initial keybind value
Options.CFrameTeleportKeyPicker:SetValue({ "T", "Toggle" })

-- Handle character respawn to reapply speed hack if enabled
LocalPlayer.CharacterAdded:Connect(function(character)
    if cframeTeleportEnabled then
        task.wait(1) -- Wait for character to fully load
        setupCFrameTeleport()
    end
end)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Desync Config
local desync = {
    enabled = false,
    mode = nil, -- "Void" or "Void Spam"
    keybind = Enum.KeyCode.V
}
local lastToggleTime = 0
local toggleVoid = false
local voidSpamInterval = 0.2

--// Helper: Create invisible part
local function createPart(size: Vector3, parent)
    local part = Instance.new("Part")
    part.Size = size
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = parent
    return part
end

-- Camera setback part
local desync_setback = createPart(Vector3.new(2,2,1), Workspace)

-- Tracer system
local tracerPart1 = createPart(Vector3.new(1,1,1), Workspace)
local tracerPart2 = createPart(Vector3.new(1,1,1), Workspace)

local attachment1 = Instance.new("Attachment", tracerPart1)
local attachment2 = Instance.new("Attachment", tracerPart2)

local beam = Instance.new("Beam")
beam.Attachment0 = attachment1
beam.Attachment1 = attachment2
beam.FaceCamera = true
beam.Width0 = 0.1
beam.Width1 = 0.1
beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
beam.Enabled = false
beam.Parent = tracerPart1

--// Core Desync Logic
local function handleDesync()
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local oldPosition = rootPart.CFrame
    local targetPos

    if desync.mode == "Void" then
        targetPos = Vector3.new(
            rootPart.Position.X + math.random(-444444, 444444),
            rootPart.Position.Y + math.random(-444444, 444444),
            rootPart.Position.Z + math.random(-44444, 44444)
        )
    elseif desync.mode == "Void Spam" then
        local currentTime = tick()
        if currentTime - lastToggleTime >= voidSpamInterval then
            toggleVoid = not toggleVoid
            lastToggleTime = currentTime
        end
        targetPos = toggleVoid and Vector3.new(rootPart.Position.X, 10000000000000000000, rootPart.Position.Z) or rootPart.Position
    end

    if targetPos then
        -- Teleport server-side root
        rootPart.CFrame = CFrame.new(targetPos)

        -- Lock camera to setback
        Workspace.CurrentCamera.CameraSubject = desync_setback
        desync_setback.CFrame = oldPosition

        -- Update tracer positions
        tracerPart1.CFrame = oldPosition
        tracerPart2.CFrame = CFrame.new(targetPos)

        -- Snap back locally
        RunService.RenderStepped:Wait()
        rootPart.CFrame = oldPosition
    end
end

-- Heartbeat loop
RunService.Heartbeat:Connect(function()
    if desync.enabled and desync.mode then
        beam.Enabled = true
        handleDesync()
    else
        beam.Enabled = false
        Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or Workspace.CurrentCamera.CameraSubject
    end
end)

--// UI Integration (example with toggle + keybind)
Desync:AddToggle('DesyncToggle', {
    Text = 'Desync',
    Default = desync.enabled,
    Tooltip = 'Toggle desync effect for server-client position mismatch',
    Callback = function(Value)
        desync.enabled = Value
        if not Value then
            desync.mode = nil
            beam.Enabled = false
            Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or Workspace.CurrentCamera.CameraSubject
        end
    end
})

Desync:AddLabel("Desync Mode Keybind"):AddKeyPicker('DesyncKeybind', {
    Text = 'Desync Mode Keybind',
    Default = desync.keybind.Name,
    SyncToggleState = true,
    Mode = "Toggle",
    NoUI = false,
    Tooltip = 'Select key to toggle desync mode (Void or Void Spam)',
    Callback = function(Value)
        if Value then
            local modeOptions = {"Void", "Void Spam"}
            local selectedMode = modeOptions[2] -- default selection (can later add dropdown)
            desync.enabled = true
            desync.mode = selectedMode
            beam.Enabled = true
            Toggles.DesyncToggle:SetValue(true)
        else
            desync.enabled = false
            desync.mode = nil
            beam.Enabled = false
            Toggles.DesyncToggle:SetValue(false)
            Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or Workspace.CurrentCamera.CameraSubject
        end
    end,
    ChangedCallback = function(New)
        desync.keybind = New
    end
})

Library:SetWatermarkVisibility(true)
Library:SetWatermark('ghosted')

Library.KeybindFrame.Visible = true

Library:OnUnload(function()
print('Unloaded!')
for _, playerDrawings in pairs(drawings.players) do
for _, drawing in pairs(playerDrawings) do
drawing:Remove()
end
end
drawings.players = {}
Library.Unloaded = true
end)



-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place") -- if the game has multiple places inside of it (for example: DOORS)
-- you can use this to save configs for those places separately
-- The path in this script would be: MyScriptHub/specific-game/settings/specific-place
-- [ This is optional ]

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs["UI Settings"])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
