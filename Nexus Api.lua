-- NexusUI Library v2.0
-- Модульная библиотека для создания современных UI интерфейсов

local NexusUI = {}
NexusUI.__index = NexusUI

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Default Configuration
NexusUI.DefaultConfig = {
    WindowSize = UDim2.new(0, 750, 0, 500),
    CornerRadius = UDim.new(0, 10),
    AnimationDuration = 0.3,
    BlurAmount = 5,
    ToggleKey = Enum.KeyCode.Insert
}

-- Default Color Scheme
NexusUI.DefaultColors = {
    Primary = Color3.fromRGB(140, 100, 220),
    PrimaryDark = Color3.fromRGB(110, 80, 190),
    Secondary = Color3.fromRGB(40, 180, 220),
    Background = Color3.fromRGB(20, 20, 25),
    Surface = Color3.fromRGB(30, 30, 38),
    SurfaceLight = Color3.fromRGB(45, 45, 55),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 190),
    Success = Color3.fromRGB(76, 175, 80),
    Warning = Color3.fromRGB(255, 193, 7),
    Error = Color3.fromRGB(244, 67, 54)
}

-- Create new NexusUI instance
function NexusUI.new(config)
    config = config or {}
    
    -- Initialize Key System
    local keySystemConfig = config.KeySystem or {Enabled = false}
    local keySettings = keySystemConfig.KeySettings or {}
    
    local self = setmetatable({
        Config = {
            WindowSize = config.WindowSize or NexusUI.DefaultConfig.WindowSize,
            CornerRadius = config.CornerRadius or NexusUI.DefaultConfig.CornerRadius,
            AnimationDuration = config.AnimationDuration or NexusUI.DefaultConfig.AnimationDuration,
            BlurAmount = config.BlurAmount or NexusUI.DefaultConfig.BlurAmount,
            ToggleKey = config.ToggleKey or NexusUI.DefaultConfig.ToggleKey
        },
        Colors = config.Colors or NexusUI.DefaultColors,
        KeySystem = {
            Enabled = keySystemConfig.Enabled or false,
            KeySettings = {
                Title = keySettings.Title or "Key System",
                Subtitle = keySettings.Subtitle or "Enter your key",
                Note = keySettings.Note or "No method of obtaining the key is provided",
                FileName = keySettings.FileName or "Key",
                SaveKey = keySettings.SaveKey or false,
                GrabKeyFromSite = keySettings.GrabKeyFromSite or false,
                Key = keySettings.Key or {"DemoKey-1234-5678-9012"},
                KeysFromSite = keySettings.KeysFromSite or nil
            },
            CurrentKey = nil,
            KeyValidated = false
        },
        Elements = {},
        Tabs = {},
        CurrentTab = nil,
        Enabled = false,
        InputConnection = nil
    }, NexusUI)
    
    -- Load saved key if SaveKey is enabled
    if self.KeySystem.Enabled and self.KeySystem.KeySettings.SaveKey then
        self:LoadSavedKey()
    end
    
    -- Get keys from site if enabled
    if self.KeySystem.Enabled and self.KeySystem.KeySettings.GrabKeyFromSite then
        self:GetKeysFromSite()
    end
    
    self:Initialize()
    return self
end

-- Initialize the UI
function NexusUI:Initialize()
    self:CreateBlurEffect()
    self:CreateMainUI()
    self:SetupEventHandlers()
    
    if self.KeySystem.Enabled and not self.KeySystem.KeyValidated then
        self:ShowKeySystem()
    else
        self:ShowMainUI()
    end
    
    print("=== NEXUS UI LIBRARY ===")
    print("Version: 2.0")
    print("Key System:", self.KeySystem.Enabled and "ENABLED" or "DISABLED")
    print("Toggle Key:", self.Config.ToggleKey.Name)
    print("========================")
end

-- Key System Functions
function NexusUI:LoadSavedKey()
    if not self.KeySystem.KeySettings.SaveKey then return end
    
    local success, savedKey = pcall(function()
        if readfile then
            return readfile(self.KeySystem.KeySettings.FileName .. ".txt")
        end
        return nil
    end)
    
    if success and savedKey then
        if self:ValidateKey(savedKey) then
            self.KeySystem.CurrentKey = savedKey
            self.KeySystem.KeyValidated = true
            print("✅ Loaded valid key from save file")
        end
    end
end

function NexusUI:SaveKeyToFile(key)
    if not self.KeySystem.KeySettings.SaveKey then return end
    
    local success = pcall(function()
        if writefile then
            writefile(self.KeySystem.KeySettings.FileName .. ".txt", key)
            return true
        end
        return false
    end)
    
    return success
end

function NexusUI:GetKeysFromSite()
    if not self.KeySystem.KeySettings.GrabKeyFromSite then return end
    
    local siteUrl = self.KeySystem.KeySettings.KeysFromSite
    if not siteUrl then return end
    
    local success, keysData = pcall(function()
        if syn and syn.request then
            local response = syn.request({
                Url = siteUrl,
                Method = "GET"
            })
            return response.Body
        elseif request then
            local response = request({
                Url = siteUrl,
                Method = "GET"
            })
            return response.Body
        end
        return nil
    end)
    
    if success and keysData then
        -- Parse keys from site (assuming one key per line)
        local keys = {}
        for key in string.gmatch(keysData, "[^\r\n]+") do
            if key and key ~= "" then
                table.insert(keys, key)
            end
        end
        
        if #keys > 0 then
            self.KeySystem.KeySettings.Key = keys
            print("✅ Loaded " .. #keys .. " keys from site")
        end
    end
end

function NexusUI:ValidateKey(inputKey)
    if not inputKey or type(inputKey) ~= "string" then return false end
    
    inputKey = string.upper(inputKey:gsub("%s+", ""))
    
    -- Check against local keys
    for _, validKey in ipairs(self.KeySystem.KeySettings.Key) do
        if string.upper(validKey:gsub("%s+", "")) == inputKey then
            return true
        end
    end
    
    return false
end

-- Create blur effect
function NexusUI:CreateBlurEffect()
    self.BlurEffect = Instance.new("BlurEffect")
    self.BlurEffect.Size = 0
    self.BlurEffect.Parent = game:GetService("Lighting")
end

-- Create main UI container
function NexusUI:CreateMainUI()
    -- Remove old UI if exists
    pcall(function()
        local oldUI = CoreGui:FindFirstChild("NexusUIModern")
        if oldUI then
            oldUI:Destroy()
        end
    end)
    
    -- Main ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "NexusUIModern"
    self.ScreenGui.Parent = CoreGui
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Enabled = false
    
    -- Main Window
    self.MainWindow = Instance.new("Frame")
    self.MainWindow.Name = "MainWindow"
    self.MainWindow.Size = self.Config.WindowSize
    self.MainWindow.Position = UDim2.new(0.5, -self.Config.WindowSize.X.Offset/2, 0.5, -self.Config.WindowSize.Y.Offset/2)
    self.MainWindow.BackgroundColor3 = self.Colors.Background
    self.MainWindow.BackgroundTransparency = 1
    self.MainWindow.Visible = false
    self.MainWindow.Parent = self.ScreenGui
    
    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = self.Config.CornerRadius
    WindowCorner.Parent = self.MainWindow
    
    local WindowStroke = Instance.new("UIStroke")
    WindowStroke.Color = self.Colors.SurfaceLight
    WindowStroke.Thickness = 1
    WindowStroke.Parent = self.MainWindow
    
    -- Top Bar
    self.TopBar = Instance.new("Frame")
    self.TopBar.Name = "TopBar"
    self.TopBar.Size = UDim2.new(1, 0, 0, 40)
    self.TopBar.BackgroundColor3 = self.Colors.Surface
    self.TopBar.Parent = self.MainWindow
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = self.TopBar
    
    self.TitleLabel = Instance.new("TextLabel")
    self.TitleLabel.Name = "TitleLabel"
    self.TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
    self.TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    self.TitleLabel.BackgroundTransparency = 1
    self.TitleLabel.Text = "NEXUS UI"
    self.TitleLabel.TextColor3 = self.Colors.TextPrimary
    self.TitleLabel.TextSize = 16
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = self.TopBar
    
    self.CloseButton = Instance.new("ImageButton")
    self.CloseButton.Name = "CloseButton"
    self.CloseButton.Size = UDim2.new(0, 25, 0, 25)
    self.CloseButton.Position = UDim2.new(1, -35, 0.5, -12.5)
    self.CloseButton.BackgroundColor3 = self.Colors.Error
    self.CloseButton.Parent = self.TopBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = self.CloseButton
    
    local CloseIcon = Instance.new("ImageLabel")
    CloseIcon.Name = "CloseIcon"
    CloseIcon.Size = UDim2.new(0.5, 0, 0.5, 0)
    CloseIcon.Position = UDim2.new(0.25, 0, 0.25, 0)
    CloseIcon.BackgroundTransparency = 1
    CloseIcon.Image = "rbxassetid://3926305904"
    CloseIcon.ImageRectOffset = Vector2.new(284, 4)
    CloseIcon.ImageRectSize = Vector2.new(24, 24)
    CloseIcon.ImageColor3 = self.Colors.TextPrimary
    CloseIcon.Parent = self.CloseButton
    
    -- Main Content Area
    self.MainContent = Instance.new("Frame")
    self.MainContent.Name = "MainContent"
    self.MainContent.Size = UDim2.new(1, 0, 1, -40)
    self.MainContent.Position = UDim2.new(0, 0, 0, 40)
    self.MainContent.BackgroundTransparency = 1
    self.MainContent.Parent = self.MainWindow
    
    -- Sidebar Navigation
    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Name = "Sidebar"
    self.Sidebar.Size = UDim2.new(0, 200, 1, 0)
    self.Sidebar.BackgroundColor3 = self.Colors.Surface
    self.Sidebar.Parent = self.MainContent
    
    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 10)
    SidebarCorner.Parent = self.Sidebar
    
    -- Navigation List
    self.NavigationList = Instance.new("ScrollingFrame")
    self.NavigationList.Name = "NavigationList"
    self.NavigationList.Size = UDim2.new(1, -20, 1, -100)
    self.NavigationList.Position = UDim2.new(0, 10, 0, 10)
    self.NavigationList.BackgroundTransparency = 1
    self.NavigationList.ScrollBarThickness = 4
    self.NavigationList.ScrollBarImageColor3 = self.Colors.SurfaceLight
    self.NavigationList.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.NavigationList.Parent = self.Sidebar
    
    self.NavigationLayout = Instance.new("UIListLayout")
    self.NavigationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.NavigationLayout.Padding = UDim.new(0, 6)
    self.NavigationLayout.Parent = self.NavigationList
    
    -- Profile Section
    self.ProfileSection = Instance.new("Frame")
    self.ProfileSection.Name = "ProfileSection"
    self.ProfileSection.Size = UDim2.new(1, -20, 0, 80)
    self.ProfileSection.Position = UDim2.new(0, 10, 1, -90)
    self.ProfileSection.BackgroundColor3 = self.Colors.SurfaceLight
    self.ProfileSection.Parent = self.Sidebar
    
    local ProfileCorner = Instance.new("UICorner")
    ProfileCorner.CornerRadius = self.Config.CornerRadius
    ProfileCorner.Parent = self.ProfileSection
    
    local AvatarFrame = Instance.new("Frame")
    AvatarFrame.Name = "AvatarFrame"
    AvatarFrame.Size = UDim2.new(0, 50, 0, 50)
    AvatarFrame.Position = UDim2.new(0, 10, 0.5, -25)
    AvatarFrame.BackgroundColor3 = self.Colors.Surface
    AvatarFrame.Parent = self.ProfileSection
    
    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = AvatarFrame
    
    local AvatarStroke = Instance.new("UIStroke")
    AvatarStroke.Color = self.Colors.Primary
    AvatarStroke.Thickness = 2
    AvatarStroke.Parent = AvatarFrame
    
    self.AvatarImage = Instance.new("ImageLabel")
    self.AvatarImage.Name = "AvatarImage"
    self.AvatarImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    self.AvatarImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    self.AvatarImage.BackgroundTransparency = 1
    self.AvatarImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    self.AvatarImage.Parent = AvatarFrame
    
    self.UsernameLabel = Instance.new("TextLabel")
    self.UsernameLabel.Name = "UsernameLabel"
    self.UsernameLabel.Size = UDim2.new(1, -70, 0, 20)
    self.UsernameLabel.Position = UDim2.new(0, 65, 0, 20)
    self.UsernameLabel.BackgroundTransparency = 1
    self.UsernameLabel.Text = Players.LocalPlayer.Name or "Player"
    self.UsernameLabel.TextColor3 = self.Colors.TextPrimary
    self.UsernameLabel.TextSize = 14
    self.UsernameLabel.Font = Enum.Font.GothamBold
    self.UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.UsernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    self.UsernameLabel.Parent = self.ProfileSection
    
    self.WelcomeLabel = Instance.new("TextLabel")
    self.WelcomeLabel.Name = "WelcomeLabel"
    self.WelcomeLabel.Size = UDim2.new(1, -70, 0, 16)
    self.WelcomeLabel.Position = UDim2.new(0, 65, 0, 42)
    self.WelcomeLabel.BackgroundTransparency = 1
    self.WelcomeLabel.Text = "Добро пожаловать!"
    self.WelcomeLabel.TextColor3 = self.Colors.TextSecondary
    self.WelcomeLabel.TextSize = 12
    self.WelcomeLabel.Font = Enum.Font.Gotham
    self.WelcomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.WelcomeLabel.Parent = self.ProfileSection
    
    -- Content Pages
    self.ContentPages = Instance.new("Frame")
    self.ContentPages.Name = "ContentPages"
    self.ContentPages.Size = UDim2.new(1, -200, 1, 0)
    self.ContentPages.Position = UDim2.new(0, 200, 0, 0)
    self.ContentPages.BackgroundTransparency = 1
    self.ContentPages.Parent = self.MainContent
    
    -- Create Key System UI
    self:CreateKeySystem()
    
    -- Dragging variables
    self.dragging = false
    self.dragInput = nil
    self.dragStart = nil
    self.startPos = nil
end

-- Create Key System UI
function NexusUI:CreateKeySystem()
    self.KeySystemUI = Instance.new("Frame")
    self.KeySystemUI.Name = "KeySystem"
    self.KeySystemUI.Size = UDim2.new(0, 450, 0, 400)
    self.KeySystemUI.Position = UDim2.new(0.5, -225, 0.5, -200)
    self.KeySystemUI.BackgroundColor3 = self.Colors.Background
    self.KeySystemUI.BackgroundTransparency = 1
    self.KeySystemUI.Visible = false
    self.KeySystemUI.Parent = self.ScreenGui
    
    local KeySystemCorner = Instance.new("UICorner")
    KeySystemCorner.CornerRadius = self.Config.CornerRadius
    KeySystemCorner.Parent = self.KeySystemUI
    
    local KeySystemStroke = Instance.new("UIStroke")
    KeySystemStroke.Color = self.Colors.SurfaceLight
    KeySystemStroke.Thickness = 1
    KeySystemStroke.Parent = self.KeySystemUI
    
    -- Title Section
    local KeyTitle = Instance.new("TextLabel")
    KeyTitle.Name = "KeyTitle"
    KeyTitle.Size = UDim2.new(1, 0, 0, 80)
    KeyTitle.Position = UDim2.new(0, 0, 0, 0)
    KeyTitle.BackgroundColor3 = self.Colors.Surface
    KeyTitle.Text = self.KeySystem.KeySettings.Title
    KeyTitle.TextColor3 = self.Colors.TextPrimary
    KeyTitle.TextSize = 24
    KeyTitle.Font = Enum.Font.GothamBold
    KeyTitle.Parent = self.KeySystemUI
    
    local KeyTitleCorner = Instance.new("UICorner")
    KeyTitleCorner.CornerRadius = UDim.new(0, 10)
    KeyTitleCorner.Parent = KeyTitle
    
    -- Subtitle
    local KeySubtitle = Instance.new("TextLabel")
    KeySubtitle.Name = "KeySubtitle"
    KeySubtitle.Size = UDim2.new(1, -40, 0, 30)
    KeySubtitle.Position = UDim2.new(0, 20, 0, 90)
    KeySubtitle.BackgroundTransparency = 1
    KeySubtitle.Text = self.KeySystem.KeySettings.Subtitle
    KeySubtitle.TextColor3 = self.Colors.TextSecondary
    KeySubtitle.TextSize = 16
    KeySubtitle.Font = Enum.Font.Gotham
    KeySubtitle.TextXAlignment = Enum.TextXAlignment.Left
    KeySubtitle.Parent = self.KeySystemUI
    
    -- Key Input
    self.KeyInput = Instance.new("TextBox")
    self.KeyInput.Name = "KeyInput"
    self.KeyInput.Size = UDim2.new(1, -40, 0, 45)
    self.KeyInput.Position = UDim2.new(0, 20, 0, 130)
    self.KeyInput.BackgroundColor3 = self.Colors.SurfaceLight
    self.KeyInput.TextColor3 = self.Colors.TextPrimary
    self.KeyInput.Text = ""
    self.KeyInput.PlaceholderText = "Введите ваш ключ..."
    self.KeyInput.PlaceholderColor3 = self.Colors.TextSecondary
    self.KeyInput.TextSize = 16
    self.KeyInput.Font = Enum.Font.Gotham
    self.KeyInput.Parent = self.KeySystemUI
    
    local KeyInputCorner = Instance.new("UICorner")
    KeyInputCorner.CornerRadius = self.Config.CornerRadius
    KeyInputCorner.Parent = self.KeyInput
    
    -- Submit Button
    self.KeySubmit = Instance.new("TextButton")
    self.KeySubmit.Name = "KeySubmit"
    self.KeySubmit.Size = UDim2.new(1, -40, 0, 45)
    self.KeySubmit.Position = UDim2.new(0, 20, 0, 190)
    self.KeySubmit.BackgroundColor3 = self.Colors.Primary
    self.KeySubmit.TextColor3 = self.Colors.TextPrimary
    self.KeySubmit.Text = "АКТИВИРОВАТЬ"
    self.KeySubmit.TextSize = 16
    self.KeySubmit.Font = Enum.Font.GothamBold
    self.KeySubmit.Parent = self.KeySystemUI
    
    local KeySubmitCorner = Instance.new("UICorner")
    KeySubmitCorner.CornerRadius = self.Config.CornerRadius
    KeySubmitCorner.Parent = self.KeySubmit
    
    -- Note Section
    local KeyNote = Instance.new("TextLabel")
    KeyNote.Name = "KeyNote"
    KeyNote.Size = UDim2.new(1, -40, 0, 60)
    KeyNote.Position = UDim2.new(0, 20, 0, 250)
    KeyNote.BackgroundTransparency = 1
    KeyNote.Text = self.KeySystem.KeySettings.Note
    KeyNote.TextColor3 = self.Colors.TextSecondary
    KeyNote.TextSize = 12
    KeyNote.Font = Enum.Font.Gotham
    KeyNote.TextWrapped = true
    KeyNote.Parent = self.KeySystemUI
    
    -- Message Label
    self.KeyMessage = Instance.new("TextLabel")
    self.KeyMessage.Name = "KeyMessage"
    self.KeyMessage.Size = UDim2.new(1, -40, 0, 40)
    self.KeyMessage.Position = UDim2.new(0, 20, 0, 320)
    self.KeyMessage.BackgroundTransparency = 1
    self.KeyMessage.Text = "Введите ключ для доступа к интерфейсу"
    self.KeyMessage.TextColor3 = self.Colors.TextSecondary
    self.KeyMessage.TextSize = 14
    self.KeyMessage.Font = Enum.Font.Gotham
    self.KeyMessage.TextWrapped = true
    self.KeyMessage.Parent = self.KeySystemUI
end

-- Key System Management
function NexusUI:ShowKeySystem()
    if not self.ScreenGui then return end
    
    self.ScreenGui.Enabled = true
    self.KeySystemUI.Visible = true
    self.KeySystemUI.BackgroundTransparency = 1
    
    TweenService:Create(self.KeySystemUI, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    TweenService:Create(self.BlurEffect, TweenInfo.new(0.5), {Size = self.Config.BlurAmount}):Play()
    
    -- Show available keys in console for debugging
    if self.KeySystem.KeySettings.Key then
        print("=== NEXUS KEY SYSTEM ===")
        print("Доступные ключи:")
        for i, key in ipairs(self.KeySystem.KeySettings.Key) do
            print(key)
        end
        print("========================")
    end
end

function NexusUI:HideKeySystem()
    if not self.KeySystemUI then return end
    
    TweenService:Create(self.KeySystemUI, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    wait(0.3)
    self.KeySystemUI.Visible = false
end

function NexusUI:OnKeySubmit()
    local key = self.KeyInput.Text
    
    if self:ValidateKey(key) then
        self.KeySystem.CurrentKey = key
        self.KeySystem.KeyValidated = true
        self.KeyMessage.Text = "✅ Ключ принят! Загрузка..."
        self.KeyMessage.TextColor3 = self.Colors.Success
        
        -- Save key if enabled
        if self.KeySystem.KeySettings.SaveKey then
            self:SaveKeyToFile(key)
        end
        
        TweenService:Create(self.KeySubmit, TweenInfo.new(0.3), {BackgroundColor3 = self.Colors.Success}):Play()
        
        wait(1.5)
        self:HideKeySystem()
        self:ShowMainUI()
    else
        self.KeyMessage.Text = "❌ Неверный ключ! Попробуйте снова."
        self.KeyMessage.TextColor3 = self.Colors.Error
        
        TweenService:Create(self.KeySubmit, TweenInfo.new(0.3), {BackgroundColor3 = self.Colors.Error}):Play()
        wait(1)
        TweenService:Create(self.KeySubmit, TweenInfo.new(0.3), {BackgroundColor3 = self.Colors.Primary}):Play()
    end
end

-- Setup event handlers
function NexusUI:SetupEventHandlers()
    -- Key system events
    if self.KeySubmit then
        self.KeySubmit.MouseButton1Click:Connect(function()
            self:OnKeySubmit()
        end)
    end
    
    -- Dragging events
    if self.TopBar then
        self.TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.dragging = true
                self.dragStart = input.Position
                self.startPos = self.MainWindow.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        self.dragging = false
                    end
                end)
            end
        end)
        
        self.TopBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                self.dragInput = input
            end
        end)
    end
    
    UserInputService.InputChanged:Connect(function(input)
        if input == self.dragInput and self.dragging and self.MainWindow then
            self:UpdateInput(input)
        end
    end)
    
    -- Close button
    if self.CloseButton then
        self.CloseButton.MouseButton1Click:Connect(function()
            self:HideMainUI()
        end)
    end
    
    -- Toggle UI with key
    self.InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == self.Config.ToggleKey then
            if not self.Enabled then
                if self.KeySystem.Enabled and not self.KeySystem.KeyValidated then
                    self:ShowKeySystem()
                else
                    self:ShowMainUI()
                end
            else
                self:HideMainUI()
            end
        end
    end)
    
    -- Auto cleanup
    Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:Destroy()
        end
    end)
end

-- Update input for dragging
function NexusUI:UpdateInput(input)
    if not self.MainWindow or not self.MainWindow.Parent then return end
    local delta = input.Position - self.dragStart
    self.MainWindow.Position = UDim2.new(
        self.startPos.X.Scale, 
        self.startPos.X.Offset + delta.X, 
        self.startPos.Y.Scale, 
        self.startPos.Y.Offset + delta.Y
    )
end

-- UI visibility management
function NexusUI:ShowMainUI()
    if not self.ScreenGui or not self.ScreenGui.Parent then return end
    
    -- Load player avatar
    pcall(function()
        local userId = Players.LocalPlayer.UserId
        self.AvatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
    end)
    
    self.ScreenGui.Enabled = true
    self.MainWindow.Visible = true
    
    -- Blur background
    self:SafeTween(self.BlurEffect, TweenInfo.new(0.5), {Size = self.Config.BlurAmount})
    
    -- Animate window appearance
    self.MainWindow.BackgroundTransparency = 1
    self:SafeTween(self.MainWindow, TweenInfo.new(self.Config.AnimationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        Size = self.Config.WindowSize
    })
    
    -- Select first tab if available
    if self.CurrentTab and self.Tabs[self.CurrentTab] then
        self:SelectTab(self.CurrentTab)
    elseif next(self.Tabs) then
        for tabName, _ in pairs(self.Tabs) do
            self:SelectTab(tabName)
            break
        end
    end
    
    self.Enabled = true
end

function NexusUI:HideMainUI()
    if not self.ScreenGui then return end
    
    -- Animate window disappearance
    self:SafeTween(self.MainWindow, TweenInfo.new(self.Config.AnimationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0)
    })
    
    -- Remove blur
    self:SafeTween(self.BlurEffect, TweenInfo.new(0.3), {Size = 0})
    
    wait(self.Config.AnimationDuration)
    self.MainWindow.Visible = false
    self.ScreenGui.Enabled = false
    self.Enabled = false
end

-- Safe tween function
function NexusUI:SafeTween(object, tweenInfo, properties)
    if object and object.Parent then
        local tween = TweenService:Create(object, tweenInfo, properties)
        tween:Play()
        return tween
    end
    return nil
end

-- Tab management
function NexusUI:CreateTab(tabConfig)
    if not tabConfig or type(tabConfig) ~= "table" then
        warn("NexusUI: Invalid tab configuration")
        return nil
    end
    
    local tabName = tabConfig.Name
    if not tabName or type(tabName) ~= "string" then
        warn("NexusUI: Tab name is required and must be a string")
        return nil
    end
    
    -- Create navigation button
    local navButton = self:CreateNavButton(tabConfig)
    local contentPage = self:CreateContentPage(tabConfig)
    
    if not navButton or not contentPage then
        warn("NexusUI: Failed to create tab elements for " .. tabName)
        return nil
    end
    
    -- Store tab data
    self.Tabs[tabName] = {
        Button = navButton,
        Page = contentPage,
        Elements = {}
    }
    
    -- Set click handler
    navButton.MouseButton1Click:Connect(function()
        self:SelectTab(tabName)
    end)
    
    -- Select first tab automatically
    if not self.CurrentTab then
        self.CurrentTab = tabName
    end
    
    -- Update navigation list size
    if self.NavigationLayout then
        self.NavigationLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if self.NavigationList then
                self.NavigationList.CanvasSize = UDim2.new(0, 0, 0, self.NavigationLayout.AbsoluteContentSize.Y)
            end
        end)
    end
    
    -- Create tab API object
    local tabAPI = {}
    
    function tabAPI.AddButton(buttonConfig)
        if not buttonConfig or type(buttonConfig) ~= "table" then
            warn("NexusUI: Invalid button configuration")
            return nil
        end
        return self:AddButtonToTab(tabName, buttonConfig)
    end
    
    function tabAPI.AddToggle(toggleConfig)
        if not toggleConfig or type(toggleConfig) ~= "table" then
            warn("NexusUI: Invalid toggle configuration")
            return nil
        end
        return self:AddToggleToTab(tabName, toggleConfig)
    end
    
    function tabAPI.AddSection(sectionConfig)
        if not sectionConfig or type(sectionConfig) ~= "table" then
            warn("NexusUI: Invalid section configuration")
            return nil
        end
        return self:AddSectionToTab(tabName, sectionConfig)
    end
    
    function tabAPI.AddLabel(labelConfig)
        if not labelConfig or type(labelConfig) ~= "table" then
            warn("NexusUI: Invalid label configuration")
            return nil
        end
        return self:AddLabelToTab(tabName, labelConfig)
    end
    
    -- Placeholder methods for future features
    function tabAPI.AddColorPicker(colorConfig)
        warn("NexusUI: ColorPicker not implemented in this version")
        return nil
    end
    
    function tabAPI.AddDropdown(dropdownConfig)
        warn("NexusUI: Dropdown not implemented in this version")
        return nil
    end
    
    return tabAPI
end

function NexusUI:SelectTab(tabName)
    if not self.Tabs[tabName] then return end
    
    -- Deselect all buttons
    for name, tabData in pairs(self.Tabs) do
        if tabData.Button and tabData.Button.Parent then
            tabData.Button:SetAttribute("Selected", false)
            self:SafeTween(tabData.Button, TweenInfo.new(0.2), {BackgroundColor3 = self.Colors.SurfaceLight})
            if tabData.Button:FindFirstChild("Highlight") then
                self:SafeTween(tabData.Button.Highlight, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            end
            if tabData.Button:FindFirstChild("Label") then
                self:SafeTween(tabData.Button.Label, TweenInfo.new(0.2), {TextColor3 = self.Colors.TextSecondary})
            end
            if tabData.Button:FindFirstChild("Icon") then
                self:SafeTween(tabData.Button.Icon, TweenInfo.new(0.2), {ImageColor3 = self.Colors.TextSecondary})
            end
        end
    end
    
    -- Hide all pages
    for name, tabData in pairs(self.Tabs) do
        if tabData.Page and tabData.Page.Parent then
            tabData.Page.Visible = false
        end
    end
    
    -- Select current button and show page
    local currentTab = self.Tabs[tabName]
    currentTab.Button:SetAttribute("Selected", true)
    self:SafeTween(currentTab.Button, TweenInfo.new(0.2), {BackgroundColor3 = self.Colors.Primary})
    if currentTab.Button:FindFirstChild("Highlight") then
        self:SafeTween(currentTab.Button.Highlight, TweenInfo.new(0.2), {BackgroundTransparency = 0})
    end
    if currentTab.Button:FindFirstChild("Label") then
        self:SafeTween(currentTab.Button.Label, TweenInfo.new(0.2), {TextColor3 = self.Colors.TextPrimary})
    end
    if currentTab.Button:FindFirstChild("Icon") then
        self:SafeTween(currentTab.Button.Icon, TweenInfo.new(0.2), {ImageColor3 = self.Colors.TextPrimary})
    end
    
    currentTab.Page.Visible = true
    self.CurrentTab = tabName
end

-- UI element creation functions
function NexusUI:CreateNavButton(navConfig)
    if not navConfig or not navConfig.Name or not self.NavigationList then
        return nil
    end
    
    local button = Instance.new("TextButton")
    button.Name = navConfig.Name .. "Nav"
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = self.Colors.SurfaceLight
    button.Text = ""
    button.Parent = self.NavigationList
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self.Config.CornerRadius
    corner.Parent = button
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 12, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = navConfig.Icon or "rbxassetid://3926305904"
    icon.ImageColor3 = self.Colors.TextSecondary
    icon.Parent = button
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -45, 1, 0)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = navConfig.Name
    label.TextColor3 = self.Colors.TextSecondary
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button
    
    local highlight = Instance.new("Frame")
    highlight.Name = "Highlight"
    highlight.Size = UDim2.new(0, 3, 0.6, 0)
    highlight.Position = UDim2.new(0, 0, 0.2, 0)
    highlight.BackgroundColor3 = self.Colors.Primary
    highlight.BackgroundTransparency = 1
    highlight.Parent = button
    
    local highlightCorner = Instance.new("UICorner")
    highlightCorner.CornerRadius = UDim.new(1, 0)
    highlightCorner.Parent = highlight
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        if not button:GetAttribute("Selected") then
            self:SafeTween(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Colors.SurfaceLight})
            self:SafeTween(label, TweenInfo.new(0.2), {TextColor3 = self.Colors.TextPrimary})
            self:SafeTween(icon, TweenInfo.new(0.2), {ImageColor3 = self.Colors.TextPrimary})
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not button:GetAttribute("Selected") then
            self:SafeTween(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Colors.SurfaceLight})
            self:SafeTween(label, TweenInfo.new(0.2), {TextColor3 = self.Colors.TextSecondary})
            self:SafeTween(icon, TweenInfo.new(0.2), {ImageColor3 = self.Colors.TextSecondary})
        end
    end)
    
    return button
end

function NexusUI:CreateContentPage(pageConfig)
    if not pageConfig or not pageConfig.Name or not self.ContentPages then
        return nil
    end
    
    local page = Instance.new("ScrollingFrame")
    page.Name = pageConfig.Name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = self.Colors.SurfaceLight
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = self.ContentPages
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = page
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.Parent = page
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if page and page.Parent then
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 30)
        end
    end)
    
    return page
end

function NexusUI:AddSectionToTab(tabName, sectionConfig)
    if not self.Tabs[tabName] then 
        warn("NexusUI: Tab '" .. tostring(tabName) .. "' does not exist")
        return nil
    end
    
    if not sectionConfig or type(sectionConfig) ~= "table" then
        warn("NexusUI: Invalid section configuration")
        return nil
    end
    
    if not sectionConfig.Name or type(sectionConfig.Name) ~= "string" then
        warn("NexusUI: Section name is required and must be a string")
        return nil
    end
    
    local tab = self.Tabs[tabName]
    local section = self:CreateRoundedFrame(tab.Page, UDim2.new(1, 0, 0, 50), nil, self.Colors.Surface)
    section.BackgroundTransparency = 0
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.new(0, 15, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = sectionConfig.Name
    title.TextColor3 = self.Colors.TextPrimary
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = section
    
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 0, 0)
    content.Position = UDim2.new(0, 15, 0, 40)
    content.BackgroundTransparency = 1
    content.Parent = section
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = content
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if content and content.Parent then
            content.Size = UDim2.new(1, -20, 0, contentLayout.AbsoluteContentSize.Y)
            section.Size = UDim2.new(1, 0, 0, 55 + contentLayout.AbsoluteContentSize.Y)
        end
    end)
    
    -- Store section in tab elements
    table.insert(tab.Elements, {
        Type = "Section",
        Object = section,
        Content = content
    })
    
    -- Create section API object
    local sectionAPI = {}
    
    function sectionAPI.AddButton(buttonConfig)
        if not buttonConfig or type(buttonConfig) ~= "table" then
            warn("NexusUI: Invalid button configuration")
            return nil
        end
        return self:AddButtonToSection(content, buttonConfig)
    end
    
    function sectionAPI.AddToggle(toggleConfig)
        if not toggleConfig or type(toggleConfig) ~= "table" then
            warn("NexusUI: Invalid toggle configuration")
            return nil
        end
        return self:AddToggleToSection(content, toggleConfig)
    end
    
    function sectionAPI.AddLabel(labelConfig)
        if not labelConfig or type(labelConfig) ~= "table" then
            warn("NexusUI: Invalid label configuration")
            return nil
        end
        return self:AddLabelToSection(content, labelConfig)
    end
    
    -- Placeholder methods for future features
    function sectionAPI.AddColorPicker(colorConfig)
        warn("NexusUI: ColorPicker not implemented in this version")
        return nil
    end
    
    function sectionAPI.AddDropdown(dropdownConfig)
        warn("NexusUI: Dropdown not implemented in this version")
        return nil
    end
    
    return sectionAPI
end

function NexusUI:AddButtonToTab(tabName, buttonConfig)
    if not self.Tabs[tabName] then return nil end
    
    local tab = self.Tabs[tabName]
    local button = self:CreateButton(tab.Page, buttonConfig)
    
    if button then
        table.insert(tab.Elements, {
            Type = "Button",
            Object = button
        })
    end
    
    return button
end

function NexusUI:AddButtonToSection(sectionContent, buttonConfig)
    local button = self:CreateButton(sectionContent, buttonConfig)
    return button
end

function NexusUI:CreateButton(parent, buttonConfig)
    if not buttonConfig or type(buttonConfig) ~= "table" then
        warn("NexusUI: Invalid button configuration")
        return nil
    end
    
    if not buttonConfig.Name or type(buttonConfig.Name) ~= "string" then
        warn("NexusUI: Button name is required and must be a string")
        return nil
    end
    
    local button = Instance.new("TextButton")
    button.Name = buttonConfig.Name .. "Button"
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = self.Colors.Primary
    button.Text = buttonConfig.Name
    button.TextColor3 = self.Colors.TextPrimary
    button.TextSize = 13
    button.Font = Enum.Font.Gotham
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self.Config.CornerRadius
    corner.Parent = button
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        self:SafeTween(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Colors.PrimaryDark})
    end)
    
    button.MouseLeave:Connect(function()
        self:SafeTween(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Colors.Primary})
    end)
    
    if buttonConfig.Callback and type(buttonConfig.Callback) == "function" then
        button.MouseButton1Click:Connect(function()
            pcall(buttonConfig.Callback)
        end)
    end
    
    return button
end

function NexusUI:AddToggleToTab(tabName, toggleConfig)
    if not self.Tabs[tabName] then return nil end
    
    local tab = self.Tabs[tabName]
    local toggle = self:CreateToggle(tab.Page, toggleConfig)
    
    if toggle then
        table.insert(tab.Elements, {
            Type = "Toggle",
            Object = toggle
        })
    end
    
    return toggle
end

function NexusUI:AddToggleToSection(sectionContent, toggleConfig)
    local toggle = self:CreateToggle(sectionContent, toggleConfig)
    return toggle
end

function NexusUI:CreateToggle(parent, toggleConfig)
    if not toggleConfig or type(toggleConfig) ~= "table" then
        warn("NexusUI: Invalid toggle configuration")
        return nil
    end
    
    if not toggleConfig.Name or type(toggleConfig.Name) ~= "string" then
        warn("NexusUI: Toggle name is required and must be a string")
        return nil
    end
    
    local toggle = Instance.new("Frame")
    toggle.Name = toggleConfig.Name .. "Toggle"
    toggle.Size = UDim2.new(1, 0, 0, 32)
    toggle.BackgroundTransparency = 1
    toggle.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = toggleConfig.Name
    label.TextColor3 = self.Colors.TextPrimary
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 45, 0, 22)
    toggleButton.Position = UDim2.new(1, -45, 0.5, -11)
    toggleButton.BackgroundColor3 = self.Colors.SurfaceLight
    toggleButton.Text = ""
    toggleButton.Parent = toggle
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Name = "ToggleKnob"
    toggleKnob.Size = UDim2.new(0, 18, 0, 18)
    toggleKnob.Position = UDim2.new(0, 2, 0.5, -9)
    toggleKnob.BackgroundColor3 = self.Colors.TextPrimary
    toggleKnob.Parent = toggleButton
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = toggleKnob
    
    local currentValue = toggleConfig.CurrentValue or false
    
    local function updateToggle()
        if currentValue then
            self:SafeTween(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = self.Colors.Primary})
            self:SafeTween(toggleKnob, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9)})
        else
            self:SafeTween(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = self.Colors.SurfaceLight})
            self:SafeTween(toggleKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9)})
        end
    end
    
    toggleButton.MouseButton1Click:Connect(function()
        currentValue = not currentValue
        updateToggle()
        if toggleConfig.Callback and type(toggleConfig.Callback) == "function" then
            pcall(toggleConfig.Callback, currentValue)
        end
    end)
    
    updateToggle()
    
    local toggleObject = {}
    function toggleObject:Set(value)
        if type(value) == "boolean" then
            currentValue = value
            updateToggle()
        end
    end
    
    function toggleObject:Get()
        return currentValue
    end
    
    return toggleObject
end

function NexusUI:AddLabelToTab(tabName, labelConfig)
    if not self.Tabs[tabName] then return nil end
    
    local tab = self.Tabs[tabName]
    local label = self:CreateLabel(tab.Page, labelConfig)
    
    if label then
        table.insert(tab.Elements, {
            Type = "Label",
            Object = label
        })
    end
    
    return label
end

function NexusUI:AddLabelToSection(sectionContent, labelConfig)
    local label = self:CreateLabel(sectionContent, labelConfig)
    return label
end

function NexusUI:CreateLabel(parent, labelConfig)
    if not labelConfig or type(labelConfig) ~= "table" then
        warn("NexusUI: Invalid label configuration")
        return nil
    end
    
    if not labelConfig.Text or type(labelConfig.Text) ~= "string" then
        warn("NexusUI: Label text is required and must be a string")
        return nil
    end
    
    local label = Instance.new("TextLabel")
    label.Name = "Label_" .. labelConfig.Text
    label.Size = UDim2.new(1, 0, 0, labelConfig.Height or 20)
    label.BackgroundTransparency = 1
    label.Text = labelConfig.Text
    label.TextColor3 = labelConfig.Color or self.Colors.TextPrimary
    label.TextSize = labelConfig.TextSize or 13
    label.Font = labelConfig.Font or Enum.Font.Gotham
    label.TextXAlignment = labelConfig.Alignment or Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = parent
    
    return label
end

-- Utility functions
function NexusUI:CreateRoundedFrame(parent, size, position, backgroundColor)
    if not parent then return nil end
    local frame = Instance.new("Frame")
    frame.Size = size or UDim2.new(1, 0, 1, 0)
    frame.Position = position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = backgroundColor or self.Colors.Surface
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self.Config.CornerRadius
    corner.Parent = frame
    
    return frame
end

-- Public API methods
function NexusUI:SetTitle(title)
    if self.TitleLabel and type(title) == "string" then
        self.TitleLabel.Text = title
    end
end

function NexusUI:SetWindowSize(size)
    if self.MainWindow then
        self.Config.WindowSize = size
        self.MainWindow.Size = size
        self.MainWindow.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
    end
end

function NexusUI:Toggle()
    if not self.Enabled then
        self:ShowMainUI()
    else
        self:HideMainUI()
    end
end

function NexusUI:Show()
    self:ShowMainUI()
end

function NexusUI:Hide()
    self:HideMainUI()
end

function NexusUI:Destroy()
    if self.InputConnection then
        self.InputConnection:Disconnect()
        self.InputConnection = nil
    end
    
    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end
    
    if self.BlurEffect then
        self.BlurEffect:Destroy()
        self.BlurEffect = nil
    end
    
    -- Clean up tables
    self.Elements = nil
    self.Tabs = nil
end

return NexusUI
