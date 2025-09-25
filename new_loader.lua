--[[
How to use:
    --> Look at the Config below
    --> Change "false" to "true" for whatever you want
    --> Mess with the numbers (less = more crazy)
    --> Run the script and enjoy!
]]

local Config = {
    -- Gun Mods
    InfiniteAmmo = false,
    InfiniteClips = false,
    ModifyFireRate = false,
    FireRateSpeed = 100,
    ModifyReloadSpeed = false,
    ReloadSpeed = 100,
    ModifySpreadValue = false,
    SpreadPercentage = 100,
    ModifyRecoilValue = false,
    RecoilPercentage = 100,
    InfiniteDamage = true,
    Automatic = false,
    DisableJamming = false,
    ModifyEquipSpeed = false,
    EquipSpeed = 100,
    -- Misc
    SemiGodmode = false, -- Lets you shoot while dead
    InstaInteract = false,
    InfiniteZoom = false,
    NotificationType = 1, -- 1 = default, 2 = modern, 3 = minimal
    HitboxExpander = false,
    HitboxBodyPart = "Head", -- Head, Torso, LeftArm, RightArm, LeftLeg, RightLeg
    HitboxSize = 2, -- dont put this too up or it maybe glitches
    -- Anti-Aim / Desync
    AntiAim = {
        VelocityDesync = {
            Enabled = false,
            Range = 10,
            Type = "Easy", -- Options: "Easy", "Medium", "Hard", "Jitter", "Spiral", "Circle", "FigureEight", "PingPong", "Perlin", "Sway"
            ToggleKey = Enum.KeyCode.X,
            Visuals = {
                Count = 8, -- number of dummy markers
                Trail = true, -- keep a history of positions to form a trail
                MaxHistory = 60, -- how many frames to keep in history
                Color = Color3.fromRGB(0, 255, 255),
                TransparencyStart = 0.2,
                TransparencyEnd = 0.8,
                Material = Enum.Material.ForceField,
                --[[
            Common materials:
              Enum.Material.Plastic, Enum.Material.SmoothPlastic, Enum.Material.Metal,
              Enum.Material.Neon, Enum.Material.Glass, Enum.Material.ForceField,
              Enum.Material.Wood, Enum.Material.Granite, Enum.Material.Marble,
              Enum.Material.Concrete, Enum.Material.Fabric, Enum.Material.Sandstone
            ]]
                Size = Vector3.new(2, 2, 1),
                VisualStyle = "Box" -- Options: "Box" (default), "Sphere", "Cylinder", "Billboard", "Beam"

            }
        }
    },
    -- China hat for visuals (only you can see it)
    ChinaHat = {
        enabled = false,
        hatColor = Color3.fromRGB(255, 105, 180),
        lightColor = Color3.fromRGB(255, 105, 180),
        lightBrightness = 2,
        lightRange = 15,
        scale = Vector3.new(1.7, 1.1, 1.7),
        rotationSpeed = Vector3.new(0, math.rad(120), 0),
        floatAmplitude = 0.2,
        floatSpeed = 2.5,
        pulseSpeed = 3,
        swayAmplitude = 0.1,
        swaySpeed = 1.5
    },
    -- Backpack Explorer
    OpGui = false -- Backpack explorer to duplicate guns
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local OldWeaponValues = {}

local function GetAllTools(LocalToolsOnly)
    local Result = {}
    local sources = {}
    
    if not LocalToolsOnly then
        table.insert(sources, game.Lighting)
    end
    table.insert(sources, LocalPlayer.Backpack)
    
    if LocalPlayer.Character then
        table.insert(sources, LocalPlayer.Character)
    end
    
    for _, container in ipairs(sources) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    table.insert(Result, item)
                end
            end
        end
    end
    
    return Result
end

local function GetPercentage(DefaultValue, NewValue)
    if not DefaultValue or not NewValue then return DefaultValue or 1 end
    NewValue = math.max(0, math.min(1000, NewValue))
    return DefaultValue * (NewValue / 100)
end

local function ModWeapon(Weapon)
    if not Weapon or not Weapon:IsA("Tool") then return end
    
    local Module = Weapon:FindFirstChildOfClass("ModuleScript")
    if not Module or Module.Name ~= "Setting" then return end
    
    local success, moduleData = pcall(function()
        return require(Module)
    end)
    
    if not success or type(moduleData) ~= "table" then
        return
    end
    
    local OldConfig = OldWeaponValues[Weapon.Name]
    if not OldConfig then return end
    
    if Config.InfiniteAmmo or Config.InfiniteClips then
        local gunScript = Weapon:FindFirstChild("GunScript_Local")
        if gunScript and type(getsenv) == "function" then
            local okEnv, env = pcall(getsenv, gunScript)
            if okEnv and type(env) == "table" and env.Reload then
                local function safeSetup(idx, val)
                    if type(debug) == "table" and type(debug.setupvalue) == "function" then
                        pcall(function()
                            debug.setupvalue(env.Reload, idx, val)
                        end)
                    end
                end
                if Config.InfiniteClips then
                    safeSetup(3, 9e17)
                end
                if Config.InfiniteAmmo then
                    safeSetup(5, 9e17)
                end
            end
        end
    end
    
    moduleData.LimitedAmmoEnabled = false
    -- Fallback for obfuscation: boost any ammo/clip numeric fields massively
    if Config.InfiniteAmmo or Config.InfiniteClips then
        for k, v in pairs(moduleData) do
            local nk = tostring(k):lower()
            if type(v) == "number" and (string.find(nk, "ammo", 1, true) or string.find(nk, "clip", 1, true)) then
                moduleData[k] = 9e9
            end
        end
    end
    
    if Config.ModifyFireRate and OldConfig.FireRate then
        moduleData.FireRate = GetPercentage(OldConfig.FireRate, Config.FireRateSpeed)
    end
    
    if Config.ModifyReloadSpeed and OldConfig.ReloadTime then
        moduleData.ReloadTime = GetPercentage(OldConfig.ReloadTime, Config.ReloadSpeed)
    end
    
    if Config.ModifySpreadValue then
        if OldConfig.SpreadXY and moduleData.SpreadXY then
            moduleData.SpreadXY = GetPercentage(OldConfig.SpreadXY, Config.SpreadPercentage)
        end
        if OldConfig.SpreadYX and moduleData.SpreadYX then
            moduleData.SpreadYX = GetPercentage(OldConfig.SpreadYX, Config.SpreadPercentage)
        end
        if OldConfig.Spread and moduleData.Spread then
            moduleData.Spread = GetPercentage(OldConfig.Spread, Config.SpreadPercentage)
        end
        if OldConfig.SpreadX and moduleData.SpreadX then
            moduleData.SpreadX = GetPercentage(OldConfig.SpreadX, Config.SpreadPercentage)
        end
        if OldConfig.SpreadY and moduleData.SpreadY then
            moduleData.SpreadY = GetPercentage(OldConfig.SpreadY, Config.SpreadPercentage)
        end
    end
    
    if Config.ModifyRecoilValue and OldConfig.Recoil then
        moduleData.Recoil = GetPercentage(OldConfig.Recoil, Config.RecoilPercentage)
    end
    
    if Config.InfiniteDamage then
        moduleData.BaseDamage = math.huge
    end
    
    if Config.Automatic then
        moduleData.Auto = true
    end
    
    if Config.DisableJamming then
        moduleData.JamChance = 0
    end
    
    if Config.ModifyEquipSpeed and OldConfig.EquipTime then
        moduleData.EquipTime = GetPercentage(OldConfig.EquipTime, Config.EquipSpeed)
    end
end

local function SaveOriginalValues()
    for _, Weapon in ipairs(GetAllTools()) do
        if Weapon:IsA("Tool") then
            local Module = Weapon:FindFirstChildOfClass("ModuleScript")
            
            if Module and Module.Name == "Setting" then
                local success, moduleData = pcall(function()
                    return require(Module)
                end)
                
                if success and type(moduleData) == "table" and not OldWeaponValues[Weapon.Name] then
                    OldWeaponValues[Weapon.Name] = {}
                    
                    for Index, Value in pairs(moduleData) do
                        OldWeaponValues[Weapon.Name][Index] = Value
                    end
                end
            end
        end
    end
end

local function ModAllWeapons()
    for _, Weapon in ipairs(GetAllTools(true)) do
        ModWeapon(Weapon)
    end
end

-- Custom Notification System
local function CreateNotification(title, text, duration)
    if Config.NotificationType == 1 then
        -- Default notification
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Button1 = "OK"
        })
    elseif Config.NotificationType == 2 then
        -- Modern notification
        local ScreenGui = Instance.new("ScreenGui")
        local Frame = Instance.new("Frame")
        local TitleLabel = Instance.new("TextLabel")
        local TextLabel = Instance.new("TextLabel")
        local UICorner = Instance.new("UICorner")
        local UIGradient = Instance.new("UIGradient")
        
        ScreenGui.Name = "CustomNotification"
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        Frame.Parent = ScreenGui
        Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        Frame.BorderSizePixel = 0
        Frame.Position = UDim2.new(1, 20, 0, 50)
        Frame.Size = UDim2.new(0, 350, 0, 80)
        Frame.BackgroundTransparency = 0.1
        
        UICorner.CornerRadius = UDim.new(0, 12)
        UICorner.Parent = Frame
        
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(139, 69, 19)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(160, 82, 45))
        }
        UIGradient.Rotation = 45
        UIGradient.Parent = Frame
        
        TitleLabel.Parent = Frame
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Position = UDim2.new(0, 15, 0, 8)
        TitleLabel.Size = UDim2.new(1, -30, 0, 25)
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.Text = title
        TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLabel.TextSize = 16
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        TextLabel.Parent = Frame
        TextLabel.BackgroundTransparency = 1
        TextLabel.Position = UDim2.new(0, 15, 0, 35)
        TextLabel.Size = UDim2.new(1, -30, 0, 35)
        TextLabel.Font = Enum.Font.Gotham
        TextLabel.Text = text
        TextLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        TextLabel.TextSize = 13
        TextLabel.TextWrapped = true
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextYAlignment = Enum.TextYAlignment.Top
        
        Frame:TweenPosition(UDim2.new(1, -370, 0, 50), "Out", "Quart", 0.5, true)
        
        wait(duration or 3)
        
        Frame:TweenPosition(UDim2.new(1, 20, 0, 50), "In", "Quart", 0.3, true)
        wait(0.3)
        ScreenGui:Destroy()
    elseif Config.NotificationType == 3 then
        -- Minimal notification
        local ScreenGui = Instance.new("ScreenGui")
        local Frame = Instance.new("Frame")
        local TextLabel = Instance.new("TextLabel")
        local UICorner = Instance.new("UICorner")
        
        ScreenGui.Name = "MinimalNotification"
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        Frame.Parent = ScreenGui
        Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Frame.BorderSizePixel = 0
        Frame.Position = UDim2.new(0.5, -150, 0, 20)
        Frame.Size = UDim2.new(0, 300, 0, 40)
        Frame.BackgroundTransparency = 0.3
        
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Frame
        
        TextLabel.Parent = Frame
        TextLabel.BackgroundTransparency = 1
        TextLabel.Position = UDim2.new(0, 0, 0, 0)
        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.Font = Enum.Font.Gotham
        TextLabel.Text = title .. " - " .. text
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextSize = 14
        TextLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        Frame:TweenPosition(UDim2.new(0.5, -150, 0, 20), "Out", "Quart", 0.3, true)
        
        wait(duration or 2)
        
        Frame:TweenPosition(UDim2.new(0.5, -150, 0, -60), "In", "Quart", 0.3, true)
        wait(0.3)
        ScreenGui:Destroy()
    end
end

-- Show notification
CreateNotification("bloodz.lol", "Script loaded successfully!", 4)

-- Additional Features
if Config.SemiGodmode then
    local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

if humanoid then
    humanoid.HealthChanged:Connect(function(health)
        if health <= 15 then
            local startTime = tick()
            while tick() - startTime < 10 do
                humanoid.Health = 100
                task.wait(0.1)
            end
        end
    end)
end

end

if Config.InstaInteract then
    for i,v in pairs(game:GetService("Workspace"):GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            v["HoldDuration"] = 0
        end
    end
    game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(v)
        v["HoldDuration"] = 0
    end)
end

if Config.InfiniteZoom then
    local plr = game:GetService("Players").LocalPlayer
    if plr then
        plr.CameraMaxZoomDistance = math.huge
    end
end

-- Hitbox Expander
if Config.HitboxExpander then
    local scaleFactor = Config.HitboxSize
    local localPlayer = game.Players.LocalPlayer
    local bodyPart = Config.HitboxBodyPart
    
    local function resizeBodyPart(player)
        player.CharacterAdded:Connect(function(character)
            local part = character:WaitForChild(bodyPart, 5)
            if part and part:IsA("BasePart") then
                part.Size = part.Size * scaleFactor
            end
        end)
    end
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            resizeBodyPart(player)
            if player.Character then
                local part = player.Character:FindFirstChild(bodyPart)
                if part and part:IsA("BasePart") then
                    part.Size = part.Size * scaleFactor
                end
            end
        end
    end
    
    game.Players.PlayerAdded:Connect(function(player)
        if player ~= localPlayer then
            resizeBodyPart(player)
        end
    end)
end

-- Integrated Backpack Explorer GUI
if Config.OpGui then
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local function createBackpackExplorer()
        -- Destroy existing GUI if it exists
        if PlayerGui:FindFirstChild("BronxBackpackGui") then
            PlayerGui.BronxBackpackGui:Destroy()
        end
        
        -- Create main GUI
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "BronxBackpackGui"
        ScreenGui.Parent = PlayerGui
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.ResetOnSpawn = false
        
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Parent = ScreenGui
        MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        MainFrame.BorderSizePixel = 0
        MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
        MainFrame.Size = UDim2.new(0, 600, 0, 400)
        MainFrame.Active = true
        MainFrame.Draggable = true
        MainFrame.ClipsDescendants = true
        
        local MainCorner = Instance.new("UICorner")
        MainCorner.CornerRadius = UDim.new(0, 12)
        MainCorner.Parent = MainFrame
        
        local MainGradient = Instance.new("UIGradient")
        MainGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(25, 25, 30)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(10, 10, 15))
        }
        MainGradient.Rotation = 135
        MainGradient.Parent = MainFrame
        
        local MainStroke = Instance.new("UIStroke")
        MainStroke.Color = Color3.fromRGB(139, 69, 19)
        MainStroke.Thickness = 2
        MainStroke.Parent = MainFrame
        
        -- Title bar
        local TitleBar = Instance.new("Frame")
        TitleBar.Name = "TitleBar"
        TitleBar.Size = UDim2.new(1, 0, 0, 50)
        TitleBar.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
        TitleBar.BorderSizePixel = 0
        TitleBar.Parent = MainFrame
        TitleBar.ClipsDescendants = true
        
        local TitleCorner = Instance.new("UICorner")
        TitleCorner.CornerRadius = UDim.new(0, 12)
        TitleCorner.Parent = TitleBar
        
        local TitleGradient = Instance.new("UIGradient")
        TitleGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(160, 80, 30)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(120, 60, 15))
        }
        TitleGradient.Rotation = 90
        TitleGradient.Parent = TitleBar
        
        local Title = Instance.new("TextLabel")
        Title.BackgroundTransparency = 1
        Title.Size = UDim2.new(1, -120, 1, 0)
        Title.Position = UDim2.fromOffset(15, 0)
        Title.Font = Enum.Font.GothamBold
        Title.Text = "bloodz.lol | Backpack Explorer"
        Title.TextColor3 = Color3.new(1,1,1)
        Title.TextSize = 18
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = TitleBar
        
        local BtnClose = Instance.new("TextButton")
        BtnClose.Size = UDim2.fromOffset(35, 30)
        BtnClose.Position = UDim2.new(1, -45, 0, 10)
        BtnClose.Text = "X"
        BtnClose.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        BtnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
        BtnClose.BorderSizePixel = 0
        BtnClose.Font = Enum.Font.GothamBold
        BtnClose.TextSize = 16
        BtnClose.Parent = TitleBar
        
        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 6)
        CloseCorner.Parent = BtnClose
        
        local BtnMin = Instance.new("TextButton")
        BtnMin.Size = UDim2.fromOffset(35, 30)
        BtnMin.Position = UDim2.new(1, -85, 0, 10)
        BtnMin.Text = "_"
        BtnMin.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        BtnMin.TextColor3 = Color3.fromRGB(255, 255, 255)
        BtnMin.BorderSizePixel = 0
        BtnMin.Font = Enum.Font.GothamBold
        BtnMin.TextSize = 16
        BtnMin.Parent = TitleBar
        
        local MinCorner = Instance.new("UICorner")
        MinCorner.CornerRadius = UDim.new(0, 6)
        MinCorner.Parent = BtnMin
        
        -- Toolbar
        local ToolBar = Instance.new("Frame")
        ToolBar.Name = "ToolBar"
        ToolBar.Size = UDim2.new(1, -20, 0, 40)
        ToolBar.Position = UDim2.fromOffset(10, 60)
        ToolBar.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
        ToolBar.BorderSizePixel = 0
        ToolBar.Parent = MainFrame
        
        local ToolCorner = Instance.new("UICorner")
        ToolCorner.CornerRadius = UDim.new(0, 8)
        ToolCorner.Parent = ToolBar
        
        local ToolLayout = Instance.new("UIListLayout")
        ToolLayout.FillDirection = Enum.FillDirection.Horizontal
        ToolLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ToolLayout.Padding = UDim.new(0, 10)
        ToolLayout.Parent = ToolBar
        
        local function makeToolBtn(text, layoutOrder)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.fromOffset(100, 30)
            btn.BackgroundColor3 = Color3.fromRGB(139, 69, 19)
            btn.BorderSizePixel = 0
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Text = text
            btn.LayoutOrder = layoutOrder
            btn.Parent = ToolBar
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn
            
            return btn
        end
        
        local BtnRefresh = makeToolBtn("Refresh", 1)
        local BtnDuplicate = makeToolBtn("Duplicate", 2)
        local BtnExpandAll = makeToolBtn("Expand All", 3)
        local BtnCollapseAll = makeToolBtn("Collapse All", 4)
        
        -- Search section
        local SearchFrame = Instance.new("Frame")
        SearchFrame.Name = "SearchFrame"
        SearchFrame.Size = UDim2.new(1, -20, 0, 35)
        SearchFrame.Position = UDim2.fromOffset(10, 110)
        SearchFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
        SearchFrame.BorderSizePixel = 0
        SearchFrame.Parent = MainFrame
        
        local SearchCorner = Instance.new("UICorner")
        SearchCorner.CornerRadius = UDim.new(0, 8)
        SearchCorner.Parent = SearchFrame
        
        local SearchBox = Instance.new("TextBox")
        SearchBox.PlaceholderText = "Search backpack items..."
        SearchBox.ClearTextOnFocus = false
        SearchBox.Text = ""
        SearchBox.Font = Enum.Font.Gotham
        SearchBox.TextSize = 14
        SearchBox.TextColor3 = Color3.new(1,1,1)
        SearchBox.PlaceholderColor3 = Color3.fromRGB(180,180,180)
        SearchBox.BackgroundTransparency = 1
        SearchBox.Size = UDim2.new(1, -120, 1, -6)
        SearchBox.Position = UDim2.fromOffset(10, 3)
        SearchBox.Parent = SearchFrame
        
        local SearchCount = Instance.new("TextLabel")
        SearchCount.BackgroundTransparency = 1
        SearchCount.Text = "0 results"
        SearchCount.Font = Enum.Font.Gotham
        SearchCount.TextSize = 12
        SearchCount.TextColor3 = Color3.fromRGB(220,220,220)
        SearchCount.Size = UDim2.fromOffset(100, 35)
        SearchCount.Position = UDim2.new(1, -110, 0, 0)
        SearchCount.Parent = SearchFrame
        
        -- List area
        local List = Instance.new("ScrollingFrame")
        List.Name = "List"
        List.Size = UDim2.new(1, -20, 1, -200)
        List.Position = UDim2.fromOffset(10, 155)
        List.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        List.BorderSizePixel = 0
        List.ScrollBarThickness = 8
        List.AutomaticCanvasSize = Enum.AutomaticSize.Y
        List.CanvasSize = UDim2.new()
        List.Parent = MainFrame
        List.ClipsDescendants = true
        
        local ListCorner = Instance.new("UICorner")
        ListCorner.CornerRadius = UDim.new(0, 8)
        ListCorner.Parent = List
        
        local UIL = Instance.new("UIListLayout")
        UIL.SortOrder = Enum.SortOrder.LayoutOrder
        UIL.Parent = List
        
        -- Status bar
        local StatusBar = Instance.new("TextLabel")
        StatusBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        StatusBar.BorderSizePixel = 0
        StatusBar.TextColor3 = Color3.fromRGB(220, 220, 220)
        StatusBar.TextXAlignment = Enum.TextXAlignment.Left
        StatusBar.Font = Enum.Font.Gotham
        StatusBar.TextSize = 12
        StatusBar.Text = "Ready - Press RightShift to minimize, RightControl to close"
        StatusBar.Size = UDim2.new(1, -20, 0, 25)
        StatusBar.Position = UDim2.new(0, 10, 1, -35)
        StatusBar.Parent = MainFrame
        
        local StatusCorner = Instance.new("UICorner")
        StatusCorner.CornerRadius = UDim.new(0, 6)
        StatusCorner.Parent = StatusBar
        
        -- Variables for explorer functionality
        local display = {}
        local nodeByInst = {}
        local selected = nil
        local isMinimized = false
        local normalSize = MainFrame.Size
        local minimizedSize = UDim2.new(0, 400, 0, 50)
        
        local function setStatus(msg)
            StatusBar.Text = msg or "Ready"
        end
        
        local function isScript(inst)
            return inst and inst:IsA("LuaSourceContainer")
        end
        
        local function isContainer(inst)
            if not inst then return false end
            if inst.Name == "Backpack" then return true end
            return inst:IsA("Folder") or inst:IsA("Model") or inst:IsA("Tool") or inst:IsA("HopperBin")
        end
        
        local function isAllowed(inst)
            return isContainer(inst) or isScript(inst)
        end
        
        local function hasPotentialChildren(inst)
            if not inst then return false end
            if inst.Name == "Backpack" then return true end
            for _, c in ipairs(inst:GetChildren()) do
                if isAllowed(c) then return true end
            end
            return false
        end
        
        local function clearDisplay()
            for _, n in ipairs(display) do
                if n.row then n.row:Destroy() end
            end
            display = {}
            nodeByInst = {}
            selected = nil
        end
        
        local expandNode, collapseNode
        
        local function createRow(node)
            local row = Instance.new("Frame")
            row.BackgroundColor3 = Color3.fromRGB(30,30,30)
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, -8, 0, 25)
            row.LayoutOrder = #List:GetChildren()
            row.Parent = List
            row.ClipsDescendants = true
            
            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 4)
            rowCorner.Parent = row
            
            local arrow = Instance.new("TextButton")
            arrow.BackgroundTransparency = 1
            arrow.TextColor3 = Color3.fromRGB(200,200,200)
            arrow.Font = Enum.Font.Code
            arrow.TextSize = 14
            arrow.Size = UDim2.fromOffset(20, 25)
            arrow.Position = UDim2.fromOffset(6 + node.depth*14, 0)
            arrow.Text = hasPotentialChildren(node.inst) and (node.expanded and "▼" or "▶") or "•"
            arrow.AutoButtonColor = true
            arrow.Parent = row
            
            local nameBtn = Instance.new("TextButton")
            nameBtn.BackgroundTransparency = 1
            nameBtn.TextColor3 = isScript(node.inst) and Color3.fromRGB(230, 230, 255) or Color3.new(1,1,1)
            nameBtn.Font = Enum.Font.Code
            nameBtn.TextXAlignment = Enum.TextXAlignment.Left
            nameBtn.TextSize = 13
            nameBtn.AutoButtonColor = true
            nameBtn.Size = UDim2.new(1, - (30 + node.depth*14), 1, 0)
            nameBtn.Position = UDim2.fromOffset(30 + node.depth*14, 0)
            nameBtn.Text = string.format("%s  <%s>", node.inst.Name, node.inst.ClassName)
            nameBtn.Parent = row
            
            local function selectRow()
                selected = node.inst
                for _, c in ipairs(List:GetChildren()) do
                    if c:IsA("Frame") then c.BackgroundColor3 = Color3.fromRGB(30,30,30) end
                end
                row.BackgroundColor3 = Color3.fromRGB(55,55,90)
                setStatus("Selected: " .. node.inst.Name)
            end
            
            nameBtn.MouseButton1Click:Connect(selectRow)
            arrow.MouseButton1Click:Connect(function()
                if arrow.Text == "•" then return end
                node.expanded = not node.expanded
                arrow.Text = node.expanded and "▼" or "▶"
                if node.expanded then expandNode(node) else collapseNode(node) end
            end)
            
            node.row = row
            node.arrow = arrow
            node.nameBtn = nameBtn
        end
        
        expandNode = function(node)
            local idx = table.find(display, node) or #display
            local children = {}
            -- Get all children
            for _, c in ipairs(node.inst:GetChildren()) do
                if isAllowed(c) then table.insert(children, c) end
            end
            -- order: containers first, then scripts/tools
            local containers, items = {}, {}
            for _, c in ipairs(children) do
                if isContainer(c) and not (c:IsA("Tool") or c:IsA("HopperBin")) then 
                    table.insert(containers, c) 
                else 
                    table.insert(items, c) 
                end
            end
            table.sort(containers, function(a,b) return a.Name:lower() < b.Name:lower() end)
            table.sort(items, function(a,b) return a.Name:lower() < b.Name:lower() end)
            local ordered = {}
            for _, c in ipairs(containers) do table.insert(ordered, c) end
            for _, c in ipairs(items) do table.insert(ordered, c) end
            local insertAt = idx + 1
            for _, inst in ipairs(ordered) do
                local childNode = {inst = inst, depth = node.depth + 1, expanded = false}
                table.insert(display, insertAt, childNode)
                nodeByInst[inst] = childNode
                insertAt = insertAt + 1
                createRow(childNode)
            end
        end
        
        collapseNode = function(node)
            local myDepth = node.depth
            local idx = table.find(display, node)
            if idx then
                local i = idx + 1
                while i <= #display do
                    local d = display[i]
                    if d.depth <= myDepth then break end
                    if d.row then d.row:Destroy() end
                    nodeByInst[d.inst] = nil
                    table.remove(display, i)
                end
            end
        end
        
        local function expandAll()
            for i = 1, #display do
                local n = display[i]
                if n and n.inst and isContainer(n.inst) and not n.expanded then
                    n.expanded = true
                    if n.arrow then n.arrow.Text = "▼" end
                    expandNode(n)
                end
            end
        end
        
        local function collapseAll()
            for i = #display, 1, -1 do
                local n = display[i]
                if n and n.depth > 0 then
                    n.expanded = false
                    collapseNode(n)
                    if n.arrow then n.arrow.Text = hasPotentialChildren(n.inst) and "▶" or "•" end
                end
            end
        end
        
        local function buildTop()
            for _, c in ipairs(List:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            selected = nil
            display = {}
            nodeByInst = {}
            
            if LocalPlayer then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local node = {inst = backpack, depth = 0, expanded = false}
                    table.insert(display, node)
                    nodeByInst[backpack] = node
                    createRow(node)
                end
            end
            
            setStatus("Ready")
            SearchCount.Text = "0 results"
        end
        
        local searchToken = 0
        local function addResultRow(inst, label)
            local row = Instance.new("TextButton")
            row.BackgroundColor3 = Color3.fromRGB(30,30,30)
            row.BorderSizePixel = 0
            row.TextColor3 = Color3.new(1,1,1)
            row.AutoButtonColor = true
            row.Font = Enum.Font.Code
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.TextSize = 13
            row.Size = UDim2.new(1, -8, 0, 25)
            row.Text = label .. string.format("  <%s>", inst.ClassName)
            row.Parent = List
            row.MouseButton1Click:Connect(function()
                selected = inst
                for _, c in ipairs(List:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30,30,30) end end
                row.BackgroundColor3 = Color3.fromRGB(55,55,90)
                setStatus("Selected: " .. inst.Name)
            end)
            
            local resultCorner = Instance.new("UICorner")
            resultCorner.CornerRadius = UDim.new(0, 4)
            resultCorner.Parent = row
        end
        
        local function search(query)
            searchToken = searchToken + 1
            local token = searchToken
            for _, c in ipairs(List:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
            local q = string.lower(query)
            local count, processed = 0, 0
            local MAX_RESULTS = 400
            coroutine.wrap(function()
                local plr = LocalPlayer
                if not plr then return end
                local backpack = plr:FindFirstChild("Backpack")
                if backpack then
                    local stack = {{backpack, {"Backpack"}}}
                    while #stack > 0 do
                        if token ~= searchToken then return end
                        local item = table.remove(stack)
                        local root, path = item[1], item[2]
                        for _, c in ipairs(root:GetChildren()) do
                            if isAllowed(c) then
                                if string.lower(c.Name):find(q, 1, true) then
                                    count = count + 1
                                    addResultRow(c, table.concat({table.unpack(path), c.Name}, " > "))
                                    if count >= MAX_RESULTS then SearchCount.Text = tostring(count).." results" return end
                                end
                                if isContainer(c) then
                                    table.insert(stack, {c, {table.unpack(path), c.Name}})
                                end
                            end
                            processed = processed + 1
                            if processed % 250 == 0 then task.wait() end
                        end
                    end
                end
                SearchCount.Text = tostring(count).." results"
            end)()
        end
        
        local function duplicateSelected()
            if not selected then return end
            local owner = selected:FindFirstAncestorOfClass("Player")
            if owner ~= LocalPlayer then return end
            local ok, err = pcall(function()
                local clone = selected:Clone()
                clone.Parent = selected.Parent
                clone.Name = selected.Name .. "_copy"
            end)
            setStatus(ok and "Duplicated: " .. selected.Name or ("Duplicate failed: "..tostring(err)))
            if ok and SearchBox.Text == "" then buildTop() end
        end
        
        -- Button Events
        BtnRefresh.MouseButton1Click:Connect(function()
            if SearchBox.Text ~= "" then search(SearchBox.Text) else buildTop() end
        end)
        
        BtnDuplicate.MouseButton1Click:Connect(duplicateSelected)
        BtnExpandAll.MouseButton1Click:Connect(function() expandAll() setStatus("Expanded all") end)
        BtnCollapseAll.MouseButton1Click:Connect(function() collapseAll() setStatus("Collapsed all") end)
        
        -- Window controls
        local function setMinimized(min)
            isMinimized = min
            if min then
                MainFrame:TweenSize(minimizedSize, "In", "Quart", 0.3, true)
                BtnMin.Text = "▲"
                ToolBar.Visible = false
                SearchFrame.Visible = false
                List.Visible = false
                StatusBar.Visible = false
            else
                MainFrame:TweenSize(normalSize, "Out", "Quart", 0.3, true)
                wait(0.3)
                BtnMin.Text = "_"
                ToolBar.Visible = true
                SearchFrame.Visible = true
                List.Visible = true
                StatusBar.Visible = true
            end
        end
        
        BtnMin.MouseButton1Click:Connect(function()
            setMinimized(not isMinimized)
        end)
        
        BtnClose.MouseButton1Click:Connect(function()
            ScreenGui:Destroy()
        end)
        
        -- Search functionality
        local debounceFlag = false
        local function onSearchChanged()
            local text = SearchBox.Text
            if text == "" then buildTop() else search(text) end
        end
        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            if debounceFlag then return end
            debounceFlag = true
            task.delay(0.15, function()
                debounceFlag = false
                onSearchChanged()
            end)
        end)
        
        -- Keyboard Controls
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not ScreenGui.Parent then return end
            
            if input.KeyCode == Enum.KeyCode.RightShift then
                setMinimized(not isMinimized)
            elseif input.KeyCode == Enum.KeyCode.RightControl then
                ScreenGui:Destroy()
            elseif input.KeyCode == Enum.KeyCode.F5 then
                BtnRefresh:Activate()
            elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    duplicateSelected()
                elseif UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    BtnExpandAll:Activate()
                elseif UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    BtnCollapseAll:Activate()
                end
            end
        end)
        
        -- Button hover effects
        local function addHoverEffect(button, normalColor, hoverColor)
            button.MouseEnter:Connect(function()
                button.BackgroundColor3 = hoverColor
            end)
            button.MouseLeave:Connect(function()
                button.BackgroundColor3 = normalColor
            end)
        end
        
        addHoverEffect(BtnClose, Color3.fromRGB(220, 50, 50), Color3.fromRGB(255, 70, 70))
        addHoverEffect(BtnMin, Color3.fromRGB(100, 100, 100), Color3.fromRGB(130, 130, 130))
        addHoverEffect(BtnRefresh, Color3.fromRGB(139, 69, 19), Color3.fromRGB(160, 80, 25))
        addHoverEffect(BtnDuplicate, Color3.fromRGB(139, 69, 19), Color3.fromRGB(160, 80, 25))
        addHoverEffect(BtnExpandAll, Color3.fromRGB(139, 69, 19), Color3.fromRGB(160, 80, 25))
        addHoverEffect(BtnCollapseAll, Color3.fromRGB(139, 69, 19), Color3.fromRGB(160, 80, 25))
        
        -- Watch Backpack for changes
        local function rebuild()
            if SearchBox.Text == "" then buildTop() else search(SearchBox.Text) end
        end
        
        local function watchBackpack(plr)
            if not plr or plr ~= LocalPlayer then return end
            local backpack = plr:FindFirstChild("Backpack")
            if backpack then
                backpack.ChildAdded:Connect(function() task.delay(0.1, rebuild) end)
                backpack.ChildRemoved:Connect(function() task.delay(0.1, rebuild) end)
            end
            plr.CharacterAdded:Connect(function()
                task.wait(0.5)
                local newBackpack = plr:FindFirstChild("Backpack")
                if newBackpack then
                    newBackpack.ChildAdded:Connect(function() task.delay(0.1, rebuild) end)
                    newBackpack.ChildRemoved:Connect(function() task.delay(0.1, rebuild) end)
                end
                rebuild()
            end)
        end
        
        if LocalPlayer then watchBackpack(LocalPlayer) end
        
        -- Add entrance animation
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        MainFrame:TweenSizeAndPosition(
            normalSize,
            UDim2.new(0.5, -300, 0.5, -200),
            "Out",
            "Back",
            0.5,
            true
        )
        
        -- Initialize
        buildTop()
        setStatus("Backpack Explorer loaded! Use RightShift to minimize, RightControl to close")
    end
    
    -- Create GUI initially
    createBackpackExplorer()
    
    -- Recreate GUI when player spawns
    LocalPlayer.CharacterAdded:Connect(function()
        wait(3)
        createBackpackExplorer()
    end)
    
    -- Global function to toggle GUI
    getgenv().toggleBronxBackpack = function()
        local gui = PlayerGui:FindFirstChild("BronxBackpackGui")
        if gui then
            gui:Destroy()
        else
            createBackpackExplorer()
        end
    end
end

local function ConnectEvents(container)
    if container then
        container.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                wait(0.1)
                SaveOriginalValues()
                ModWeapon(child)
            end
        end)
    end
end

if not LocalPlayer.Character then 
    LocalPlayer.CharacterAdded:Wait()
end

SaveOriginalValues()
ConnectEvents(LocalPlayer.Character)
ConnectEvents(LocalPlayer.Backpack)

LocalPlayer.CharacterAdded:Connect(function(Character)
    wait(1)
    SaveOriginalValues()
    ConnectEvents(Character)
    ModAllWeapons()
end)

ModAllWeapons()

-- Anti-Aim Desync Code
local AntiAimController = {}
AntiAimController.Functions = {}

-- utilities
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local hrp = getHRP()
LocalPlayer.CharacterAdded:Connect(function(char)
    hrp = char:WaitForChild("HumanoidRootPart")
end)

--// Desync types (offset on top of the fake position)
local function applyType(typeName, basePos, timeOffset)
    local t = tick() + (timeOffset or 0)
    local key = string.lower(typeName or "easy")

    -- Legacy aliases
    if key == "ghost" then key = "easy" end
    if key == "gravity" then key = "medium" end
    if key == "lightning" then key = "jitter" end

    if key == "easy" then
        -- smooth wavy motion
        return basePos + Vector3.new(
            math.sin(t * 0.5) * 8,
            math.cos(t * 0.7) * 3,
            math.sin(t * 0.3) * 8
        )
    elseif key == "medium" then
        -- moderate vertical variation
        return basePos + Vector3.new(0, math.sin(t * 2) * 20, 0)
    elseif key == "hard" then
        -- larger and faster offsets
        local amp = 18
        return basePos + Vector3.new(
            math.sin(t * 3) * amp,
            math.cos(t * 2.3) * (amp * 0.6),
            math.sin(t * 2.7) * (amp * 0.9)
        )
    elseif key == "jitter" then
        -- occasional random jumps
        if math.random() < 0.08 then
            return basePos + Vector3.new(
                math.random(-22, 22),
                math.random(6, 18),
                math.random(-22, 22)
            )
        end
        return basePos
    elseif key == "spiral" then
        -- helical trajectory
        local radius = 10
        return basePos + Vector3.new(
            math.cos(t * 2) * radius,
            math.sin(t * 3) * 4,
            math.sin(t * 2) * radius
        )
    elseif key == "circle" then
        local r = 12
        return basePos + Vector3.new(
            math.cos(t * 2) * r,
            0,
            math.sin(t * 2) * r
        )
    elseif key == "figureeight" then
        local r = 10
        return basePos + Vector3.new(
            math.sin(t * 2) * r,
            math.sin(t * 4) * 3,
            math.sin(t * 2) * r * math.cos(t * 2)
        )
    elseif key == "pingpong" then
        local r = 16
        local s = (math.floor(t) % 2 == 0) and 1 or -1
        return basePos + Vector3.new(s * r, 0, 0)
    elseif key == "perlin" then
        -- simple pseudo-perlin via phased sin/cos
        return basePos + Vector3.new(
            math.sin(t * 1.7 + 1.1) * 13,
            math.sin(t * 2.3 + 0.6) * 7,
            math.cos(t * 1.9 + 2.2) * 13
        )
    elseif key == "sway" then
        -- gentle sway with variable acceleration
        local amp = 14
        return basePos + Vector3.new(
            math.sin(t * 1.2) * amp,
            math.sin(t * 0.9) * (amp * 0.25),
            math.cos(t * 1.1) * (amp * 0.8)
        )
    end

    return basePos
end

--// Dummies and history (for trail)
local dummies = {}
local history = {}
local beams = {}
local attachments = {}

local function clearDummies()
    for _, b in ipairs(beams) do
        if b and b.Parent then b:Destroy() end
    end
    table.clear(beams)

    for _, p in ipairs(dummies) do
        if p and p.Parent then p:Destroy() end
    end
    table.clear(dummies)

    table.clear(attachments)
end

local function buildDummies()
    clearDummies()

    local cfg = Config.AntiAim.VelocityDesync
    local vis = cfg.Visuals

    local count = math.max(1, tonumber(vis.Count) or 1)
    for i = 1, count do
        local p
        if (vis.VisualStyle == "Sphere") then
            p = Instance.new("Part")
            p.Shape = Enum.PartType.Ball
        elseif (vis.VisualStyle == "Cylinder") then
            p = Instance.new("Part")
            p.Shape = Enum.PartType.Cylinder
            -- cylinder is tall along Y axis; rotate later if you want it upright to travel direction
        else
            p = Instance.new("Part")
        end

        p.Size = vis.Size or Vector3.new(2, 2, 1)
        p.Anchored = true
        p.CanCollide = false

        local t = (count > 1) and ((i - 1) / (count - 1)) or 0
        p.Transparency = lerp(vis.TransparencyStart or 0.2, vis.TransparencyEnd or 0.8, t)

        p.Color = vis.Color or Color3.fromRGB(0, 255, 255)
        p.Material = vis.Material or Enum.Material.ForceField
        p.Name = (i == 1) and "DesyncVisual" or ("DesyncVisual_" .. i)
        p.Parent = workspace
        dummies[i] = p

        if (vis.VisualStyle == "Billboard") then
            -- Billboard with a simple circular frame
            local bill = Instance.new("BillboardGui")
            bill.Size = UDim2.fromOffset(48, 48)
            bill.AlwaysOnTop = true
            bill.LightInfluence = 0
            bill.MaxDistance = 500
            bill.Parent = p

            local frame = Instance.new("Frame")
            frame.Size = UDim2.fromScale(1, 1)
            frame.BackgroundColor3 = vis.Color or Color3.fromRGB(0, 255, 255)
            frame.BackgroundTransparency = lerp(vis.TransparencyStart or 0.2, vis.TransparencyEnd or 0.8, t)
            frame.BorderSizePixel = 0
            frame.Parent = bill

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(1, 0) -- circle
            uiCorner.Parent = frame

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 255, 255)
            stroke.Thickness = 1.5
            stroke.Transparency = 0
            stroke.Parent = frame
        elseif (vis.VisualStyle == "Beam") then
            -- Create an Attachment per dummy; actual Beams are linked after loop
            local att = Instance.new("Attachment")
            att.Name = "DesyncAttachment"
            att.Parent = p
            attachments[i] = att
        end
    end

    -- If beam style, connect adjacent attachments with Beams
    if (vis.VisualStyle == "Beam" and #attachments >= 2) then
        for i = 1, (#attachments - 1) do
            local a0 = attachments[i]
            local a1 = attachments[i + 1]
            if a0 and a1 then
                local beam = Instance.new("Beam")
                beam.Attachment0 = a0
                beam.Attachment1 = a1
                beam.FaceCamera = true
                beam.Color = ColorSequence.new(vis.Color or Color3.fromRGB(0,255,255))
                beam.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, vis.TransparencyStart or 0.2),
                    NumberSequenceKeypoint.new(1, vis.TransparencyEnd or 0.8)
                })
                beam.Width0 = 0.2
                beam.Width1 = 0.2
                beam.LightInfluence = 0
                beam.Parent = workspace
                beams[#beams + 1] = beam
            end
        end
    end
end

buildDummies()

-- Rebuild if Visuals.Count changes at runtime (simple watcher)
local lastCount = Config.AntiAim.VelocityDesync.Visuals.Count
RunService.Stepped:Connect(function()
    local vis = Config.AntiAim.VelocityDesync.Visuals
    if vis.Count ~= lastCount then
        lastCount = vis.Count
        buildDummies()
    end
end)

--// Desync simulation + visuals (with trail)
AntiAimController.Functions.VelocityDesync = function()
    local cfg = Config.AntiAim.VelocityDesync
    if not cfg.Enabled then return end
    if not hrp then return end

    -- random velocity vector proportional to Range
    local Amount = (cfg.Range or 5) * 1000
    local desyncVel = Vector3.new(
        math.random(-Amount, Amount),
        math.random(-Amount, Amount),
        math.random(-Amount, Amount)
    )

    -- base fake position
    local fakePos = hrp.Position + (desyncVel * 0.001)

    -- apply desync type over the fake position
    fakePos = applyType(cfg.Type, fakePos)

    -- push to history (for trail)
    local vis = cfg.Visuals
    if vis.Trail then
        table.insert(history, 1, fakePos)
        local maxH = math.max(1, tonumber(vis.MaxHistory) or 60)
        while #history > maxH do
            table.remove(history)
        end
    else
        -- no trail: keep only the latest position
        history[1] = fakePos
        for i = 2, #history do history[i] = nil end
    end

    -- place dummy markers along the history
    local count = #dummies
    if count == 0 then return end

    local maxH = math.max(1, tonumber(vis.MaxHistory) or 60)
    local step = math.max(1, math.floor(maxH / count))

    for i = 1, count do
        local p = dummies[i]
        if p then
            local idx = vis.Trail and math.min(1 + (i - 1) * step, #history) or 1
            local pos = history[idx] or fakePos
            -- small extra offset per dummy using the type to better spread visuals
            pos = applyType(cfg.Type, pos, i * 0.05)
            p.CFrame = CFrame.new(pos)
        end
    end
end

-- Toggle by key
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local cfg = Config.AntiAim.VelocityDesync
    if input.KeyCode == (cfg.ToggleKey or Enum.KeyCode.X) then
        cfg.Enabled = not cfg.Enabled
    end
end)

-- Main loop
RunService.Heartbeat:Connect(function()
    AntiAimController.Functions.VelocityDesync()
end)

-- China Hat Code
local function CreateHat(Character)
    local Head = Character:WaitForChild("Head")

    local Cone = Instance.new("Part")
    Cone.Size = Vector3.new(1,1,1)
    Cone.BrickColor = BrickColor.new("Hot pink")
    Cone.Material = Enum.Material.Neon
    Cone.Transparency = 0.2
    Cone.Anchored = false
    Cone.CanCollide = false
    Cone.Color = Config.ChinaHat.hatColor

    local Mesh = Instance.new("SpecialMesh")
    Mesh.MeshType = Enum.MeshType.FileMesh
    Mesh.MeshId = "rbxassetid://1033714"
    Mesh.Scale = Config.ChinaHat.scale
    Mesh.Parent = Cone

    local Weld = Instance.new("Weld")
    Weld.Part0 = Head
    Weld.Part1 = Cone
    local baseC0 = CFrame.new(0,0.9,0)
    Weld.C0 = baseC0
    Weld.Parent = Cone

    local Light = Instance.new("PointLight")
    Light.Color = Config.ChinaHat.lightColor
    Light.Brightness = Config.ChinaHat.lightBrightness
    Light.Range = Config.ChinaHat.lightRange
    Light.Shadows = true
    Light.Parent = Cone

    -- Partículas neon animadas
    local Particle = Instance.new("ParticleEmitter")
    Particle.Color = ColorSequence.new(Config.ChinaHat.hatColor)
    Particle.LightEmission = 1
    Particle.Size = NumberSequence.new(0.25)
    Particle.Rate = 10
    Particle.Lifetime = NumberRange.new(0.5,1)
    Particle.Speed = NumberRange.new(0.3,0.6)
    Particle.Parent = Cone

    -- Trail para efeito de rastro
    local TrailAttachment0 = Instance.new("Attachment", Cone)
    local TrailAttachment1 = Instance.new("Attachment", Cone)
    TrailAttachment1.Position = Vector3.new(0,-0.5,0)
    local Trail = Instance.new("Trail")
    Trail.Attachment0 = TrailAttachment0
    Trail.Attachment1 = TrailAttachment1
    Trail.Color = ColorSequence.new(Config.ChinaHat.hatColor)
    Trail.Lifetime = 0.3
    Trail.LightEmission = 1
    Trail.Parent = Cone

    Cone.Parent = Character

    local time = 0

    RunService.RenderStepped:Connect(function(deltaTime)
        if Config.ChinaHat.enabled and Cone.Parent then
            time = time + deltaTime

            -- Rotação contínua
            Weld.C0 = baseC0
                * CFrame.Angles(
                    0,
                    Config.ChinaHat.rotationSpeed.Y * time,
                    0
                )
                -- flutuação vertical
                * CFrame.new(0, math.sin(time * Config.ChinaHat.floatSpeed) * Config.ChinaHat.floatAmplitude, 0)
                -- balanço lateral
                * CFrame.Angles(
                    math.sin(time * Config.ChinaHat.swaySpeed) * Config.ChinaHat.swayAmplitude,
                    0,
                    0
                )

            -- Brilho pulsante e mudança de cor gradual
            local pulse = 0.5 + math.sin(time * Config.ChinaHat.pulseSpeed) * 0.5
            Light.Brightness = Config.ChinaHat.lightBrightness + pulse
            local hue = (time % 6) / 6
            local dynamicColor = Color3.fromHSV(hue,1,1)
            Light.Color = dynamicColor
            Cone.Color = dynamicColor
            Particle.Color = ColorSequence.new(dynamicColor)
            Trail.Color = ColorSequence.new(dynamicColor)
        end
    end)
end

local function OnCharacterAdded(Character)
    if Config.ChinaHat.enabled then
        Character:WaitForChild("Head")
        CreateHat(Character)
    end
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

if LocalPlayer.Character then
    OnCharacterAdded(LocalPlayer.Character)
end
