local shared = odh_shared_plugins

local my_own_section = shared.AddSection("FAKE BOMB JUMP")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- Variables
local ScreenGui = nil
local MainFrame = nil
local CircleButton = nil
local dragging = false
local dragStart
local startPos
local onCooldown = false
local COOLDOWN_TIME = 24
local pluginEnabled = false
local bombEquipped = false
local cooldownCoroutine = nil

-- Credits
my_own_section:AddLabel("Credits: @Kenzie")
my_own_section:AddParagraph("Fake Bomb Jump", "Get fake bomb and hold it. Press again to place and jump. 24s cooldown. Drag to move button.")

-- Function to create GUI
function CreateGUI()
    if ScreenGui then ScreenGui:Destroy() end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FakeBombGUI"
    ScreenGui.Parent = game:GetService("CoreGui")

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 70, 0, 70)
    MainFrame.Position = UDim2.new(0, 20, 0, 20)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.Parent = ScreenGui

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0.3, 0) -- Squircle shape
    FrameCorner.Parent = MainFrame

    CircleButton = Instance.new("TextButton")
    CircleButton.Size = UDim2.new(0, 50, 0, 50)
    CircleButton.Position = UDim2.new(0, 10, 0, 10)
    CircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    CircleButton.Text = "GET"
    CircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CircleButton.Font = Enum.Font.GothamBold
    CircleButton.TextSize = 12
    CircleButton.Parent = MainFrame

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0.3, 0) -- Squircle shape
    UICorner.Parent = CircleButton
    
    return ScreenGui
end

-- Function to animate button press
function AnimateButtonPress()
    if not CircleButton then return end
    
    -- Shrink animation
    local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local shrinkTween = TweenService:Create(CircleButton, tweenInfo, {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(0, 15, 0, 15)
    })
    
    shrinkTween:Play()
    
    -- Wait and grow back
    wait(0.0)
    
    local growTween = TweenService:Create(CircleButton, tweenInfo, {
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 10, 0, 10)
    })
    
    growTween:Play()
end

-- Function to get center position based on shiftlock
function GetCenterPosition()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local Character = LocalPlayer.Character
        local HumanoidRootPart = Character.HumanoidRootPart
        
        local Camera = workspace.CurrentCamera
        local CameraDirection = Camera.CFrame.LookVector
        
        local Position = HumanoidRootPart.Position + (CameraDirection * 5)
        
        local LookVector = CameraDirection
        local RightVector = Vector3.new(0, 1, 0):Cross(LookVector)
        local UpVector = LookVector:Cross(RightVector)
        
        return CFrame.new(
            Position.X, Position.Y, Position.Z,
            RightVector.X, UpVector.X, LookVector.X,
            RightVector.Y, UpVector.Y, LookVector.Y,
            RightVector.Z, UpVector.Z, LookVector.Z
        )
    end
    return nil
end

-- Function to make character jump
function MakeCharacterJump()
    local Character = LocalPlayer.Character
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

-- Function to reset cooldown
function ResetCooldown()
    onCooldown = false
    bombEquipped = false
    if CircleButton and pluginEnabled then
        CircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        CircleButton.Text = "GET"
        CircleButton.Active = true
    end
    if cooldownCoroutine then
        coroutine.close(cooldownCoroutine)
        cooldownCoroutine = nil
    end
end

-- Function to start cooldown
function StartCooldown()
    onCooldown = true
    bombEquipped = false
    
    CircleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    CircleButton.Text = tostring(COOLDOWN_TIME)
    CircleButton.Active = false
    
    cooldownCoroutine = coroutine.create(function()
        for i = COOLDOWN_TIME - 1, 0, -1 do
            if onCooldown and pluginEnabled then
                CircleButton.Text = tostring(i)
                wait(1)
            else
                break
            end
        end
        
        if onCooldown and pluginEnabled then
            ResetCooldown()
        end
    end)
    
    coroutine.resume(cooldownCoroutine)
end

-- Function to get fake bomb (equip it)
function GetFakeBomb()
    if onCooldown or not pluginEnabled or bombEquipped then
        return
    end
    
    -- Get fake bomb tool
    local argsGet = {"FakeBomb"}
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("ReplicateToy"):InvokeServer(unpack(argsGet))
    end)
    
    wait(0.1)
    
    -- Check if we got the bomb
    local FakeBomb = LocalPlayer.Character:FindFirstChild("FakeBomb")
    if FakeBomb then
        bombEquipped = true
        CircleButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
        CircleButton.Text = "PLACE"
        shared.Notify("Bomb equipped! Press again to place and jump.", 2)
    end
end

-- Function to place bomb and jump
function PlaceBombAndJump()
    if not bombEquipped or not pluginEnabled then
        return
    end
    
    local FakeBomb = LocalPlayer.Character:FindFirstChild("FakeBomb")
    if FakeBomb and FakeBomb:FindFirstChild("Remote") then
        local centerCFrame = GetCenterPosition()
        if centerCFrame then
            local argsPlace = {
                centerCFrame,
                50
            }
            
            pcall(function()
                FakeBomb.Remote:FireServer(unpack(argsPlace))
            end)
            
            MakeCharacterJump()
            StartCooldown()
        end
    else
        -- Bomb was lost somehow, reset state
        bombEquipped = false
        CircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        CircleButton.Text = "GET"
    end
end

-- Main button action
function OnButtonClick()
    if dragging or onCooldown or not pluginEnabled then
        return
    end
    
    if not bombEquipped then
        GetFakeBomb()
    else
        PlaceBombAndJump()
    end
end

-- Setup drag system
function SetupDragSystem()
    if not MainFrame or not CircleButton then return end
    
    -- Simple click event
    CircleButton.MouseButton1Click:Connect(function()
        AnimateButtonPress()
        OnButtonClick()
    end)

    -- Drag system for Android/Mobile
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    MainFrame.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            if dragStart then
                local delta = (input.Position - dragStart).Magnitude
                if delta > 10 then
                    dragging = true
                    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (input.Position.X - dragStart.X), startPos.Y.Scale, startPos.Y.Offset + (input.Position.Y - dragStart.Y))
                end
            end
        end
    end)

    MainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragStart = nil
        end
    end)

    -- Button hover effects (for desktop only)
    if UserInputService.MouseEnabled then
        CircleButton.MouseEnter:Connect(function()
            if not onCooldown and pluginEnabled then
                if bombEquipped then
                    CircleButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
                else
                    CircleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 255)
                end
            end
        end)

        CircleButton.MouseLeave:Connect(function()
            if not onCooldown and pluginEnabled then
                if bombEquipped then
                    CircleButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
                else
                    CircleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                end
            end
        end)
    end
end

-- Monitor character death to reset cooldown
function MonitorCharacterDeath()
    LocalPlayer.CharacterAdded:Connect(function(character)
        -- Reset cooldown when character respawns (meaning they died)
        ResetCooldown()
        
        -- Wait for humanoid
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            ResetCooldown()
        end)
    end)
    
    -- Also set up for current character if it exists
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                ResetCooldown()
            end)
        end
    end
end

-- Toggle for enabling/disabling the feature
my_own_section:AddToggle("Enable Fake Bomb Jump", function(bool)
    pluginEnabled = bool
    if bool then
        CreateGUI()
        SetupDragSystem()
        MonitorCharacterDeath()
        shared.Notify("Fake Bomb Jump enabled! Look for the blue squircle button.", 3)
    else
        if ScreenGui then
            ScreenGui:Destroy()
            ScreenGui = nil
        end
        ResetCooldown()
        shared.Notify("Fake Bomb Jump disabled!", 2)
    end
end)

-- Reset position button
my_own_section:AddButton("Reset Button Position", function()
    if MainFrame and pluginEnabled then
        MainFrame.Position = UDim2.new(0, 20, 0, 20)
        shared.Notify("Button position reset!", 1)
    else
        shared.Notify("Enable the feature first!", 2)
    end
end)

-- Keybind for quick activation
my_own_section:AddKeybind("Quick Fake Bomb", "F", function()
    if pluginEnabled and not onCooldown then
        AnimateButtonPress()
        OnButtonClick()
    end
end)

print("Fake Bomb Jump Plugin Loaded!")
print("Credits: @Kenzie")