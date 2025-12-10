-- Infinite Yield–Style Command Bar with Dynamic Suggestion List

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local FlySpeed = 50
local flying = false
local flyConn
local ESPEnabled = false
local flingEnabled = false
local maxSuggestionHeight = 200 -- maximum height in pixels

-- Command List
local commands = {
    ";fly", ";unfly", ";speed <number>", ";jump <number>",
    ";noclip", ";clip", ";god", ";ungod",
    ";invisible", ";visible", ";kill <player>", ";sit",
    ";freeze", ";unfreeze", ";tp <player>", ";bring <player>",
    ";esp", ";fling <player>"
}

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InfiniteYieldCommandBar"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

-- Command Bar
local Bar = Instance.new("Frame")
Bar.Size = UDim2.new(0,400,0,40)
Bar.Position = UDim2.new(0.5,0,1,-50)
Bar.AnchorPoint = Vector2.new(0.5,1)
Bar.BackgroundColor3 = Color3.fromRGB(30,30,30)
Bar.BackgroundTransparency = 0.1
Bar.BorderSizePixel = 0
Bar.ClipsDescendants = true
Bar.Parent = ScreenGui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0,12)
barCorner.Parent = Bar

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1,-10,1,-10)
TextBox.Position = UDim2.new(0,5,0,5)
TextBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
TextBox.TextColor3 = Color3.fromRGB(255,255,255)
TextBox.PlaceholderText = ";command"
TextBox.ClearTextOnFocus = false
TextBox.Text = ""
TextBox.Font = Enum.Font.SourceSans
TextBox.TextScaled = true
TextBox.Parent = Bar

local txtCorner = Instance.new("UICorner")
txtCorner.CornerRadius = UDim.new(0,12)
txtCorner.Parent = TextBox

-- Suggestion Frame
local SuggestionFrame = Instance.new("ScrollingFrame")
SuggestionFrame.Size = UDim2.new(0,400,0,150)
SuggestionFrame.Position = UDim2.new(0.5,0,1,-200)
SuggestionFrame.AnchorPoint = Vector2.new(0.5,0)
SuggestionFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
SuggestionFrame.BorderSizePixel = 0
SuggestionFrame.ScrollBarThickness = 6
SuggestionFrame.Visible = false
SuggestionFrame.Parent = ScreenGui

local suggestionCorner = Instance.new("UICorner")
suggestionCorner.CornerRadius = UDim.new(0,12)
suggestionCorner.Parent = SuggestionFrame

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0,4)
UIList.Parent = SuggestionFrame

local selectedIndex = 0
local suggestionLabels = {}

-- Filter commands: start with or contain typed letters
local function filterCommands(filter)
    local filtered = {}
    local f = filter:lower():gsub("^;","") -- remove leading ;
    for _,cmd in ipairs(commands) do
        if cmd:lower():find(f) then
            table.insert(filtered,cmd)
        end
    end
    return filtered
end

-- Update suggestions dynamically with resizing
local function updateSuggestions(filter)
    SuggestionFrame:ClearAllChildren()
    suggestionLabels = {}
    UIList.Parent = SuggestionFrame
    local filtered = filterCommands(filter)

    if #filtered > 0 then
        for i,cmd in ipairs(filtered) do
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,-10,0,30)
            label.BackgroundColor3 = Color3.fromRGB(40,40,40)
            label.Text = cmd
            label.TextScaled = true
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextColor3 = Color3.fromRGB(0,255,0)
            label.Parent = SuggestionFrame
            local labelCorner = Instance.new("UICorner")
            labelCorner.CornerRadius = UDim.new(0,8)
            labelCorner.Parent = label

            label.MouseEnter:Connect(function()
                label.BackgroundColor3 = Color3.fromRGB(60,60,60)
            end)
            label.MouseLeave:Connect(function()
                if selectedIndex ~= i then
                    label.BackgroundColor3 = Color3.fromRGB(40,40,40)
                end
            end)

            label.MouseButton1Click:Connect(function()
                TextBox.Text = cmd
                SuggestionFrame.Visible = false
            end)
            table.insert(suggestionLabels,label)
        end
    else
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,-10,0,30)
        label.BackgroundColor3 = Color3.fromRGB(40,40,40)
        label.Text = "No matching commands"
        label.TextColor3 = Color3.fromRGB(255,0,0)
        label.TextScaled = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = SuggestionFrame
        local labelCorner = Instance.new("UICorner")
        labelCorner.CornerRadius = UDim.new(0,8)
        labelCorner.Parent = label
        table.insert(suggestionLabels,label)
    end

    -- Dynamic resizing
    local totalHeight = #suggestionLabels * 34 -- label height + padding
    SuggestionFrame.Size = UDim2.new(0,400,0,math.min(totalHeight,maxSuggestionHeight))

    selectedIndex = 0
    SuggestionFrame.Visible = #suggestionLabels > 0
end

-- Update suggestions when typing
TextBox:GetPropertyChangedSignal("Text"):Connect(function()
    local text = TextBox.Text
    if text:sub(1,1) == ";" then
        updateSuggestions(text)
    else
        SuggestionFrame.Visible = false
    end
end)

-- Keyboard navigation
UIS.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if SuggestionFrame.Visible then
        if input.KeyCode == Enum.KeyCode.Down then
            selectedIndex = math.min(selectedIndex+1,#suggestionLabels)
            for i,label in ipairs(suggestionLabels) do
                label.BackgroundColor3 = (i==selectedIndex) and Color3.fromRGB(60,60,60) or Color3.fromRGB(40,40,40)
            end
            if suggestionLabels[selectedIndex] then
                SuggestionFrame.CanvasPosition = Vector2.new(0,suggestionLabels[selectedIndex].Position.Y.Offset-30)
            end
        elseif input.KeyCode == Enum.KeyCode.Up then
            selectedIndex = math.max(selectedIndex-1,1)
            for i,label in ipairs(suggestionLabels) do
                label.BackgroundColor3 = (i==selectedIndex) and Color3.fromRGB(60,60,60) or Color3.fromRGB(40,40,40)
            end
            if suggestionLabels[selectedIndex] then
                SuggestionFrame.CanvasPosition = Vector2.new(0,suggestionLabels[selectedIndex].Position.Y.Offset-30)
            end
        elseif input.KeyCode == Enum.KeyCode.Return then
            if selectedIndex>0 and suggestionLabels[selectedIndex] then
                TextBox.Text = suggestionLabels[selectedIndex].Text
                SuggestionFrame.Visible = false
            else
                TextBox:ReleaseFocus()
            end
        end
    end
end)

-- Fly function
local function fly()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    flying = true
    hum.PlatformStand = true
    flyConn = RunService.RenderStepped:Connect(function()
        local vel = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then vel += Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel -= Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel -= Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel += Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel -= Vector3.new(0,1,0) end
        hrp.Velocity = vel.Magnitude>0 and vel.Unit*FlySpeed or Vector3.new(0,0,0)
    end)
end

local function unfly()
    flying = false
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    if flyConn then flyConn:Disconnect() end
end

-- Toggle ESP
local function toggleESP()
    ESPEnabled = not ESPEnabled
end

-- Run command
local function runCommand(msg)
    local args = string.split(msg," ")
    local cmd = args[1]:lower()
    table.remove(args,1)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if cmd == ";fly" then fly()
    elseif cmd == ";unfly" then unfly()
    elseif cmd == ";speed" and hum then hum.WalkSpeed = tonumber(args[1]) or 16
    elseif cmd == ";jump" and hum then hum.JumpPower = tonumber(args[1]) or 50
    elseif cmd == ";noclip" and char then for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    elseif cmd == ";clip" and char then for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end
    elseif cmd == ";god" and hum then hum.Health = math.huge
    elseif cmd == ";ungod" and hum then hum.Health = 100
    elseif cmd == ";invisible" and char then for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.Transparency=1 end end
    elseif cmd == ";visible" and char then for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.Transparency=0 end end
    elseif cmd == ";kill" then local target = Players:FindFirstChild(args[1]); if target and target.Character and target.Character:FindFirstChildOfClass("Humanoid") then target.Character:FindFirstChildOfClass("Humanoid").Health = 0 end
    elseif cmd == ";sit" and hum then hum.Sit = true
    elseif cmd == ";freeze" and hum then hum.PlatformStand = true
    elseif cmd == ";unfreeze" and hum then hum.PlatformStand = false
    elseif cmd == ";tp" and hrp then local target = Players:FindFirstChild(args[1]); if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0) end
    elseif cmd == ";bring" and hrp then local target = Players:FindFirstChild(args[1]); if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then target.Character.HumanoidRootPart.CFrame = hrp.CFrame + Vector3.new(0,5,0) end
    elseif cmd == ";esp" then toggleESP()
    elseif cmd == ";fling" then local target = Players:FindFirstChild(args[1]); if target and target.Character and hrp then flingEnabled = not flingEnabled; if flingEnabled then local conn; conn = RunService.RenderStepped:Connect(function() if not flingEnabled then conn:Disconnect() return end; target.Character.HumanoidRootPart.Velocity = (target.Character.HumanoidRootPart.Position-hrp.Position).Unit*100 end) end end
    end
end

-- Execute on Enter
TextBox.FocusLost:Connect(function(enter)
    if enter then
        runCommand(TextBox.Text)
        TextBox.Text = ""
        SuggestionFrame.Visible = false
    end
end)

-- Toggle GUI
UIS.InputBegan:Connect(function(key)
    if key.KeyCode == Enum.KeyCode.F4 then
        Bar.Visible = not Bar.Visible
        SuggestionFrame.Visible = Bar.Visible and TextBox.Text:sub(1,1)==";"
    end
end)