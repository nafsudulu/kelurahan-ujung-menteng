-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")

local RFChargeFishingRod = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"] -- RemoteFunction 
local RFRequestFishingMinigameStarted = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/RequestFishingMinigameStarted"] -- RemoteFunction 
local REFishingCompleted = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingCompleted"] -- RemoteEvent 
local REFishCaught = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/FishCaught"] -- RemoteEvent
local REFishingStopped = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingStopped"] -- RemoteEvent 
local REEquipToolFromHotbar = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"] -- RemoteEvent 
local REBaitCastVisual = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/BaitCastVisual"] -- RemoteEvent 
local REReplicateTextEffect = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/ReplicateTextEffect"] -- RemoteEvent 
local REPlayFishingEffect = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RE/PlayFishingEffect"] -- RemoteEvent 
local RFCancelFishingInputs = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"] -- RemoteFunction 
local Players = game:GetService("Players")

local AutoFishing = {
    Enabled = false,
    SuccessThrow = false,
    BiteDelay = 1.5,
    CompleteDelay = 0.35
}

local successThrowConnection
local function initConnection()
    if successThrowConnection then successThrowConnection:Disconnect() end

    successThrowConnection = REPlayFishingEffect.OnClientEvent:Connect(function(player, data)
        if player == game.Players.LocalPlayer then
            AutoFishing.SuccessThrow = true
        end
    end)
end

local function getRandomFloat(min, max)
    return min + (math.random() * (max - min))
end

WindUI:SetNotificationLower(true)
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
    Title = "Rubot - Fish It",
    Icon = "skull",
    Author = "dsc.gg/rubot-script",
    Folder = "RubotHub",
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

Window:SetToggleKey(Enum.KeyCode.RightShift)


local TeleportPlace = {
    ["Ancient Jungle"] = CFrame.new(1275.1, 3.9, -334.8) * CFrame.Angles(-0.00, 0.00, 0.00),
    ["Fisherman Island"] = CFrame.new(74.0, 9.5, 2705.2) * CFrame.Angles(-0.00, 0.00, 0.00),
    ["Coral Reefs"] = CFrame.new(-3181.4, 2.5, 2104.4) * CFrame.Angles(-0.00, 0.00, 0.00),
    ["Crater Island"] = CFrame.new(998.0, 2.9, 5151.2) * CFrame.Angles(-0.00, 0.00, 0.00),
    ["Crystal Falls"] = CFrame.new(-2027.0, -440.0, 7428.3) * CFrame.Angles(-0.00, 0.00, 0.00),
    ["Esoteric Isle"] = CFrame.new(3255.7, -1301.5, 1371.8) * CFrame.Angles(-0.00, 0.00, 0.00),
    ["Hallow Island"] = CFrame.new(2103.2, 81.0, 3294.6) * CFrame.Angles(0.00, -1.85, -0.00),
    ["Kohana"] = CFrame.new(-661.7, 3.0, 714.1) * CFrame.Angles(0.00, 0.00, 0.00),
    ["Kohana Volcano"] = CFrame.new(-541.5, 17.3, 121.7) * CFrame.Angles(-0.00, 0.00, -0.00),
    ["Sacred Temple"] = CFrame.new(1451.4, -22.1, -635.7) * CFrame.Angles(-0.00, 0.00, -0.00),
    ["Sisyphus Statue"] = CFrame.new(-3729.2, -135.1, -885.6) * CFrame.Angles(-0.00, 0.00, 0.00),
    ["Treasure Room"] = CFrame.new(-3581.6, -279.1, -1589.7) * CFrame.Angles(-0.00, 0.00, 0.00),
    ["Tropical Island"] = CFrame.new(-2152.6, 2.3, 3671.7) * CFrame.Angles(-0.00, 0.00, -0.00),
    ["Underground Cellar"] = CFrame.new(2135.4, -91.2, -699.3) * CFrame.Angles(0.00, 0.00, 0.00),
    ["Weather Machine"] = CFrame.new(-1523.2, 8.5, 1772.0) * CFrame.Angles(0.00, 0.00, 0.00)
}

local islandNames = {}
for name, _ in pairs(TeleportPlace) do
    table.insert(islandNames, name)
end
table.sort(islandNames)

local function SafeTeleport(cframe)
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character then
        return false, "Character not found"
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return false, "HumanoidRootPart not found"
    end
    
    -- Set CFrame
    humanoidRootPart.CFrame = cframe
    return true, "Teleport successful"
end

local function startAutoFishing()
    print("Auto Fishing Started")
    AutoFishing.Enabled = true

    initConnection()
    
    REEquipToolFromHotbar:FireServer(1)
    task.wait(0.3)

    task.spawn(function()
        while AutoFishing.Enabled do
            AutoFishing.SuccessThrow = false
            print("Charging fishing rod...")
            RFChargeFishingRod:InvokeServer(workspace:GetServerTimeNow())
            task.wait(0.16)
            print("Requesting fishing minigame...")
            RFRequestFishingMinigameStarted:InvokeServer(-1.233184814453125, getRandomFloat(0.5, 0.99), workspace:GetServerTimeNow())
            if AutoFishing.SuccessThrow then
                print("Nunggu detik")
                task.wait(getRandomFloat(AutoFishing.BiteDelay, AutoFishing.BiteDelay + 0.2))
                print("Fishing Complete")
                REFishingCompleted:FireServer()
                task.wait(getRandomFloat(AutoFishing.CompleteDelay, AutoFishing.CompleteDelay + 0.1))
                print("Canceling")
                RFCancelFishingInputs:InvokeServer()
                task.wait(0.05)
            else
                print("Gagal melempar umpan, mencoba lagi...")
            end
        end
    end)
end

local function stopAutoFishing()
    print("Auto Fishing Stopped")
    AutoFishing.Enabled = false
    RFCancelFishingInputs:InvokeServer()
    task.wait(0.3)
    if successThrowConnection then
        successThrowConnection:Disconnect()
    end
end

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "activity"
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

-- WindUI:Notify({
--     Title = "Notification Title",
--     Content = "Notification Content example!",
--     Duration = 3, -- 3 seconds
--     Icon = "bird",
-- })

local AutoFishSection = MainTab:Section({ 
    Title = "Auto Fishing",
    TextTransparency = 0.05,
    TextXAlignment = "Left",
    TextSize = 17, -- Default Size
    Opened = true,
})

AutoFishSection:Toggle({
    Title = "Instant Fishing",
    Desc = "Fishing without animation",
    Value = false,
    Callback = function(state)
        if state then
            startAutoFishing()
            WindUI:Notify({
                Title = "Instant Fishing Started",
                Content = "Fishing automation enabled",
                Duration = 3
            })
        else
            stopAutoFishing()
            WindUI:Notify({
                Title = "Instant Fishing Stopped",
                Content = "Fishing automation disabled",
                Duration = 3
            })
        end
    end
})

local BiteDelayInput = AutoFishSection:Input({
    Title = "Bite Delay",
    Desc = "delay after bait is bitten",
    Value = 1.5,
    Type = "Input", -- or "Textarea"
    Placeholder = "Input Number",
    Callback = function(input)
        print("text entered: " .. input)
        AutoFishing.BiteDelay = tonumber(input) or 1.5
    end
})

local CompleteDelayInput = AutoFishSection:Input({
    Title = "Complete Delay",
    Desc = "delay after fishing completed",
    Value = 0.35,
    Type = "Input", -- or "Textarea"
    Placeholder = "Input Number",
    Callback = function(input)
        print("text entered: " .. input)
        AutoFishing.CompleteDelay = tonumber(input) or 0.35
    end
})

AutoFishSection:Button({
    Title = "Cancel Fishing",
    Justify = "Left", -- align items in the center (Center or Between or Left or Right)
    Color = Color3.fromHex("#22c55e"),
    IconAlign = "Right", -- Left or Right of the text
    Icon = "mouse-pointer-click", -- removing icon
    Callback = function()
        print("Cancel Fishing Button Clicked")
    end
})

MainTab:Divider()

local TeleportSection = MainTab:Section({ 
    Title = "Teleportation",
    TextTransparency = 0.05,
    TextXAlignment = "Left",
    TextSize = 17, -- Default Size
    Opened = true,
})

local TeleportDropdown = TeleportSection:Dropdown({
    Title = "Teleport to Island",
    Desc = "Select an island to teleport",
    Values = {}, -- Kita akan isi ini dengan keys dari TeleportPlace
    Value = nil, -- Bisa diset ke nil atau default value
    Callback = function(option)
        if TeleportPlace[option] then
            print("Selected: " .. option)
        end
    end
})

TeleportDropdown:Refresh(islandNames)
if #islandNames > 0 then
    TeleportDropdown:Select(islandNames[1])
end

TeleportSection:Button({
    Title = "Teleport Now",
    Justify = "Left", -- align items in the center (Center or Between or Left or Right)
    Color = Color3.fromHex("#22c55e"),
    IconAlign = "Right", -- Left or Right of the text
    Icon = "mouse-pointer-click", -- removing icon
    Callback = function()
        SafeTeleport(TeleportPlace[TeleportDropdown.Value])
    end
})