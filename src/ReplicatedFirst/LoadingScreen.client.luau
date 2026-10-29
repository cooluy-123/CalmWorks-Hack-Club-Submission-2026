local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
player:SetAttribute("CalmWorksLoadingComplete", false)
local playerGui = player:WaitForChild("PlayerGui")

local loadingScreen = Instance.new("ScreenGui")
loadingScreen.Name = "CalmWorksLoadingScreen"
loadingScreen.ResetOnSpawn = false
loadingScreen.IgnoreGuiInset = true
loadingScreen.DisplayOrder = 999
loadingScreen.Parent = playerGui

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.BackgroundColor3 = Color3.fromRGB(0, 20, 40)
textLabel.Font = Enum.Font.DenkOne
textLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
textLabel.Text = "Loading"
textLabel.TextSize = 32
textLabel.TextTransparency = 1
textLabel.BackgroundTransparency = 0
textLabel.Parent = loadingScreen

local loadingRing = Instance.new("ImageLabel")
loadingRing.Size = UDim2.new(0, 256, 0, 256)
loadingRing.BackgroundTransparency = 1
loadingRing.Image = "rbxassetid://4965945816"
loadingRing.AnchorPoint = Vector2.new(0.5, 0.5)
loadingRing.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingRing.ImageTransparency = 1
loadingRing.Parent = loadingScreen

-- Remove the default loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- Initiate and start fade-in tweens
local fadeTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1)
local fadeTween1 = TweenService:Create(textLabel, fadeTweenInfo, { TextTransparency = 0 })
local fadeTween2 = TweenService:Create(loadingRing, fadeTweenInfo, { ImageTransparency = 0 })
local fadeTween3 = TweenService:Create(textLabel, fadeTweenInfo, { TextTransparency = 1 })
local fadeTween4 = TweenService:Create(loadingRing, fadeTweenInfo, { ImageTransparency = 1 })
local fadeTween5 = TweenService:Create(textLabel, fadeTweenInfo, { BackgroundTransparency = 1 })
fadeTween1:Play()
fadeTween2:Play()

-- Initiate and start rotation tween
local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
local tween = TweenService:Create(loadingRing, tweenInfo, { Rotation = 360 })
tween:Play()

task.wait(3) -- Force screen to appear for a minimum number of seconds

if not game:IsLoaded() then
    game.Loaded:Wait()
end

fadeTween3:Play()
fadeTween4:Play()
fadeTween5:Play()
task.wait(5)
tween:Cancel()
loadingScreen:Destroy()
player:SetAttribute("CalmWorksLoadingComplete", true)