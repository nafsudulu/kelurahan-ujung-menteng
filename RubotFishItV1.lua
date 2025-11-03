-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Remote Functions & Events
local RFChargeFishingRod = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
local RFRequestFishingMinigameStarted = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/RequestFishingMinigameStarted"]
local REFishingCompleted = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingCompleted"]
local REFishCaught = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/FishCaught"]
local REFishingStopped = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingStopped"]
local REEquipToolFromHotbar = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
local REReplicateTextEffect = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"]
local REPlayFishingEffect = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/PlayFishingEffect"]
local RFCancelFishingInputs = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"]
local REUnequipToolFromHotbar = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/UnequipToolFromHotbar"] -- RemoteEvent 

local Players = game:GetService("Players")
local localPlayerName = Players.LocalPlayer.Name

local Teleports = {
    ["Hallow Island"] = CFrame.new(2104.79, 83.03, 3295.20, 2104.79, 81.03, 3295.20, -0.18, 0.00, -0.98, -0.00, 1.00, 0.00),
    ["Isoteric Isle"] = CFrame.new(3205.28, -1300.85, 1438.47, 3205.28, -1302.85, 1438.47, 0.49, 0.00, -0.87, -0.00, 1.00, -0.00),
    ["Fisherman Island"] = CFrame.new(74.03, 10.53, 2705.23, 74.03, 9.53, 2705.23, 1.00, -0.00, -0.00, 0.00, 1.00, 0.00),
    ["Kohana"] = CFrame.new(-661.68, 4.05, 714.14, -661.68, 3.05, 714.14, 1.00, 0.00, -0.00, -0.00, 1.00, -0.00),
    ["Kohana Volcano"] = CFrame.new(-541.52, 18.32, 121.67, -541.52, 17.32, 121.67, 1.00, -0.00, -0.00, 0.00, 1.00, 0.00),
    ["Ancient Jungle"] = CFrame.new(1275.10, 4.91, -334.75, 1275.10, 3.91, -334.75, 1.00, 0.00, -0.00, -0.00, 1.00, -0.00),
    ["Coral Reefs"] = CFrame.new(-3181.39, 3.52, 2104.35, -3181.39, 2.52, 2104.35, 1.00, -0.00, -0.00, 0.00, 1.00, 0.00),
    ["Treasure Room"] = CFrame.new(-3581.60, -278.07, -1589.65, -3581.60, -279.07, -1589.65, 1.00, 0.00, -0.00, -0.00, 1.00, -0.00),
    ["Sisyphus Statue"] = CFrame.new(-3729.25, -134.07, -885.64, -3729.25, -135.07, -885.64, 1.00, -0.00, -0.00, 0.00, 1.00, 0.00)
}

-- Auto Fishing Module
local AutoFishing = {
    Enabled = false,
    BaitBitten = false,
    FishCaught = false,
    SuccessThrow = false,
    FishStopped = false,
    
    Settings = {
        BiteDelayMin = 1,
        BiteDelayMax = 2.5,
        CompletionDelay = 0.5,
        MaxCompletionAttempts = 5,
        BaitWaitTimeout = 5,
        ThrowRetryDelay = 1
    },
    
    Stats = {
        TotalFishCaught = 0,
        TotalCycles = 0,
        StartTime = 0
    }
}

-- Utility Functions
local function getRandomFloat(min, max)
    return min + (math.random() * (max - min))
end

local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

-- Fishing Logic
local baitBittenConnection, successThrowConnection, fishCaughtConnection, fishingStoppedConnection

local function initializeConnections()
    if baitBittenConnection then baitBittenConnection:Disconnect() end
    if successThrowConnection then successThrowConnection:Disconnect() end
    if fishCaughtConnection then fishCaughtConnection:Disconnect() end
    if fishingStoppedConnection then fishingStoppedConnection:Disconnect() end
    
    baitBittenConnection = REReplicateTextEffect.OnClientEvent:Connect(function(data)
        if data and data.Container then     
            local containerPath = data.Container:GetFullName()
            if string.find(containerPath, localPlayerName) then
                AutoFishing.BaitBitten = true
            end
        end
    end)

    successThrowConnection = REPlayFishingEffect.OnClientEvent:Connect(function(player, data)
        if player == game.Players.LocalPlayer then
            AutoFishing.SuccessThrow = true
        end
    end)

    fishCaughtConnection = REFishCaught.OnClientEvent:Connect(function()
        AutoFishing.FishCaught = true
        AutoFishing.BaitBitten = false
        AutoFishing.Stats.TotalFishCaught = AutoFishing.Stats.TotalFishCaught + 1
    end)

    fishingStoppedConnection = REFishingStopped.OnClientEvent:Connect(function()
        AutoFishing.FishStopped = true
    end)
end

local function startAutoFishing()
    if AutoFishing.Enabled then return end
    
    AutoFishing.Enabled = true
    AutoFishing.Stats.StartTime = os.time()
    
    REEquipToolFromHotbar:FireServer(1)
    task.wait(1)
    
    initializeConnections()
    
    task.spawn(function()
        while AutoFishing.Enabled do
            AutoFishing.SuccessThrow = false
            AutoFishing.BaitBitten = false
            AutoFishing.FishCaught = false
            AutoFishing.FishStopped = false
            
            AutoFishing.Stats.TotalCycles = AutoFishing.Stats.TotalCycles + 1
            
            while AutoFishing.Enabled and not AutoFishing.SuccessThrow and not AutoFishing.FishCaught do
                RFChargeFishingRod:InvokeServer(workspace:GetServerTimeNow())
                task.wait(0.16)
                RFRequestFishingMinigameStarted:InvokeServer(-1.233184814453125, 0.5, workspace:GetServerTimeNow())
                task.wait(AutoFishing.Settings.ThrowRetryDelay)
            end
            
            if AutoFishing.Enabled and AutoFishing.SuccessThrow and not AutoFishing.FishCaught then
                local baitWaitTime = 0
                
                while AutoFishing.Enabled and not AutoFishing.BaitBitten and not AutoFishing.FishCaught and baitWaitTime < AutoFishing.Settings.BaitWaitTimeout do
                    task.wait(0.5)
                    baitWaitTime = baitWaitTime + 0.5
                end
                
                if AutoFishing.Enabled and AutoFishing.BaitBitten and not AutoFishing.FishCaught then
                    local biteDelay = getRandomFloat(AutoFishing.Settings.BiteDelayMin, AutoFishing.Settings.BiteDelayMax)
                    task.wait(biteDelay)
                    
                    local attempts = 0
                    while AutoFishing.Enabled and not AutoFishing.FishCaught and attempts < AutoFishing.Settings.MaxCompletionAttempts do
                        attempts = attempts + 1
                        REFishingCompleted:FireServer()
                        task.wait(AutoFishing.Settings.CompletionDelay)
                    end
                end
            end
            
            if AutoFishing.Enabled then
                RFCancelFishingInputs:InvokeServer()
                task.wait(0.1)
            end
        end
    end)
end

local function stopAutoFishing()
    AutoFishing.Enabled = false
    if baitBittenConnection then baitBittenConnection:Disconnect() end
    if successThrowConnection then successThrowConnection:Disconnect() end
    if fishCaughtConnection then fishCaughtConnection:Disconnect() end
    if fishingStoppedConnection then fishingStoppedConnection:Disconnect() end
end

-- Create Green-Black Gradient Theme
WindUI:AddTheme({
    Name = "GreenDark",
    
    Accent = WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#166534"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#22c55e"), Transparency = 0 },
    }, { Rotation = 90 }),
    
    Background = Color3.fromHex("#0a0a0a"),
    BackgroundTransparency = 0,
    Outline = Color3.fromHex("#166534"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#4b5563"),
    Button = Color3.fromHex("#166534"),
    Icon = Color3.fromHex("#22c55e"),
    
    Hover = Color3.fromHex("#22c55e"),
    
    WindowBackground = Color3.fromHex("#0a0a0a"),
    WindowShadow = Color3.fromHex("#000000"),
    
    DialogBackground = Color3.fromHex("#0a0a0a"),
    DialogBackgroundTransparency = 0,
    DialogTitle = Color3.fromHex("#ffffff"),
    DialogContent = Color3.fromHex("#e5e5e5"),
    DialogIcon = Color3.fromHex("#22c55e"),
    
    WindowTopbarButtonIcon = Color3.fromHex("#22c55e"),
    WindowTopbarTitle = Color3.fromHex("#ffffff"),
    WindowTopbarAuthor = Color3.fromHex("#22c55e"),
    WindowTopbarIcon = Color3.fromHex("#22c55e"),
    
    TabBackground = Color3.fromHex("#ffffff"),
    TabTitle = Color3.fromHex("#ffffff"),
    TabIcon = Color3.fromHex("#22c55e"),
    
    ElementBackground = Color3.fromHex("#ffffff"),
    ElementTitle = Color3.fromHex("#ffffff"),
    ElementDesc = Color3.fromHex("#a3a3a3"),
    ElementIcon = Color3.fromHex("#22c55e"),
    
    PopupBackground = Color3.fromHex("#0a0a0a"),
    PopupBackgroundTransparency = 0,
    PopupTitle = Color3.fromHex("#ffffff"),
    PopupContent = Color3.fromHex("#e5e5e5"),
    PopupIcon = Color3.fromHex("#22c55e"),
})

WindUI:SetTheme("GreenDark")

-- Create Window with OpenButton
local Window = WindUI:CreateWindow({
    Title = "Fish It",
    Icon = "skull",
    Author = "Rubot",
    Folder = "RubotHub",
    Size = UDim2.fromOffset(500, 450),
    Theme = "GreenDark"
})

-- Configure OpenButton
Window:EditOpenButton({
    Title = "Rubot",
    Icon = "skull",
    CornerRadius = UDim.new(0, 12),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("#166534"), 
        Color3.fromHex("#22c55e")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

-- Set toggle key
Window:SetToggleKey(Enum.KeyCode.RightShift)

-- Create Tabs
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "activity"
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

-- Main Tab Sections
local AutoFishSection = MainTab:Section({
    Title = "Auto Fishing"
})

local StatsSection = MainTab:Section({
    Title = "Statistics"
})

-- Settings Tab Sections  
local TimingSection = SettingsTab:Section({
    Title = "Timing"
})

local AttemptSection = SettingsTab:Section({
    Title = "Attempts"
})

-- Control Elements
local AutoFishToggle = AutoFishSection:Toggle({
    Title = "Auto Fishing",
    Value = false,
    Callback = function(state)
        if state then
            startAutoFishing()
            WindUI:Notify({
                Title = "Auto Fishing Started",
                Content = "Fishing automation enabled",
                Duration = 3
            })
        else
            stopAutoFishing()
            WindUI:Notify({
                Title = "Auto Fishing Stopped", 
                Content = "Fishing automation disabled",
                Duration = 3
            })
        end
    end
})

local EquipRodToggle = AutoFishSection:Toggle({
    Title = "Equip Rod",
    Value = false,
    Callback = function(state)
        if state then
            REEquipToolFromHotbar:FireServer(1)
            WindUI:Notify({
                Title = "Fishing Rod Equipped",
                Duration = 2
            })
        else
            REUnequipToolFromHotbar:FireServer()
            WindUI:Notify({
                Title = "Fishing Rod Unequipped",
                Duration = 2
            })
        end
    end
})

AutoFishSection:Button({
    Title = "Cancel Fishing",
    Icon = "mouse-pointer-click",
    Callback = function()
        RFCancelFishingInputs:InvokeServer()
        WindUI:Notify({
            Title = "Fishing Cancelled",
            Duration = 2
        })
    end
})

local DropDownLocation = AutoFishSection:Dropdown({
    Title = "Teleport",
    Desc = "Teleporting to different fishing areas",
    Values = { "Hallow Island", "Isoteric Isle", "Fisherman Island", "Kohana", "Kohana Volcano", "Ancient Jungle", "Coral Reefs", "Treasure Room", "Sisyphus Statue"},
    Value = "Hallow Island",
    Callback = function(option)
        print("Category selected: " .. option)
    end
})

AutoFishSection:Button({
    Title = "Teleport Now",
    Icon = "mouse-pointer-click",
    Callback = function()
        local selectedLocation = DropDownLocation.Value
        local targetCFrame = Teleports[selectedLocation]
        if targetCFrame and Players.LocalPlayer.Character then
            local humanoidRootPart = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = targetCFrame
                WindUI:Notify({
                    Title = "Teleported to " .. selectedLocation,
                    Duration = 2
                })
            end
        else
            WindUI:Notify({
                Title = "Teleport Failed",
                Content = "Location not available",
                Duration = 2
            })
        end
    end
})

-- Statistics Elements
local FishCount = StatsSection:Paragraph({
    Title = "Fish Caught",
    Desc = "0",
    Icon = "fish"
})

local SessionTime = StatsSection:Paragraph({
    Title = "Session Time",
    Desc = "00:00",
    Icon = "clock"
})

local Cycles = StatsSection:Paragraph({
    Title = "Cycles",
    Desc = "0",
    Icon = "repeat"
})

-- Update statistics
task.spawn(function()
    while true do
        if AutoFishing.Enabled then
            local sessionTime = os.time() - AutoFishing.Stats.StartTime
            FishCount:SetDesc(tostring(AutoFishing.Stats.TotalFishCaught))
            SessionTime:SetDesc(formatTime(sessionTime))
            Cycles:SetDesc(tostring(AutoFishing.Stats.TotalCycles))
        end
        task.wait(1)
    end
end)

-- Timing Settings
TimingSection:Slider({
    Title = "Bite Delay Min",
    Icon = "clock",
    Value = {
        Min = 0.5,
        Max = 3,
        Default = AutoFishing.Settings.BiteDelayMin
    },
    Step = 0.1,
    Callback = function(value)
        AutoFishing.Settings.BiteDelayMin = value
    end
})

TimingSection:Slider({
    Title = "Bite Delay Max", 
    Icon = "clock",
    Value = {
        Min = 1,
        Max = 5,
        Default = AutoFishing.Settings.BiteDelayMax
    },
    Step = 0.1,
    Callback = function(value)
        AutoFishing.Settings.BiteDelayMax = value
    end
})

TimingSection:Slider({
    Title = "Completion Delay",
    Icon = "timer",
    Value = {
        Min = 0.1,
        Max = 1,
        Default = AutoFishing.Settings.CompletionDelay
    },
    Step = 0.1,
    Callback = function(value)
        AutoFishing.Settings.CompletionDelay = value
    end
})

-- Attempt Settings
AttemptSection:Slider({
    Title = "Max Attempts",
    Icon = "target",
    Value = {
        Min = 1,
        Max = 10,
        Default = AutoFishing.Settings.MaxCompletionAttempts
    },
    Step = 1,
    Callback = function(value)
        AutoFishing.Settings.MaxCompletionAttempts = value
    end
})

AttemptSection:Slider({
    Title = "Bait Timeout",
    Icon = "hourglass",
    Value = {
        Min = 2,
        Max = 15,
        Default = AutoFishing.Settings.BaitWaitTimeout
    },
    Step = 1,
    Callback = function(value)
        AutoFishing.Settings.BaitWaitTimeout = value
    end
})

-- Reset Statistics Button
StatsSection:Button({
    Title = "Reset Stats",
    Icon = "refresh-cw",
    Callback = function()
        AutoFishing.Stats.TotalFishCaught = 0
        AutoFishing.Stats.TotalCycles = 0
        AutoFishing.Stats.StartTime = os.time()
        WindUI:Notify({
            Title = "Statistics Reset",
            Duration = 2
        })
    end
})

-- Initialize and Open Window
Window:Open()

WindUI:Notify({
    Title = "Fishing System Ready",
    Content = "Press RightShift to open/close",
    Duration = 5
})