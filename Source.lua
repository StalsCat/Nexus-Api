-- NexusUI Library v1.3 (Stable)
-- By StalsCat, ZestyKJScripts
local NexusUI = {}
NexusUI.__index = NexusUI

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

NexusUI.DefaultConfig = {
    WindowSize = UDim2.new(0, 750, 0, 500),
    CornerRadius = UDim.new(0, 10),
    AnimationDuration = 0.3,
    BlurAmount = 5,
    ToggleKey = Enum.KeyCode.Insert
}

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

-- Deep merge function for tables
local function deepMerge(defaultTable, userTable)
    if type(userTable) ~= "table" then return defaultTable end
    
    local result = {}
    for key, value in pairs(defaultTable) do
        if userTable[key] ~= nil then
            if type(value) == "table" and type(userTable[key]) == "table" then
                result[key] = deepMerge(value, userTable[key])
            else
                result[key] = userTable[key]
            end
        else
            result[key] = value
        end
    end
    return result
end

-- Safe property access with fallback
local function safeGetColor(colors, colorName, fallback)
    if not colors or type(colors) ~= "table" then
        return fallback or Color3.fromRGB(255, 255, 255)
    end
    return colors[colorName] or fallback or Color3.fromRGB(255, 255, 255)
end

-- Improved validation function
local function validateConfig(config, configType)
    if not config or type(config) ~= "table" then
        return false, "Config must be a table"
    end
    
    if configType == "section" then
        if not config.Name or type(config.Name) ~= "string" then
            return false, "Section name is required and must be a string"
        end
    elseif configType == "tab" then
        if not config.Name or type(config.Name) ~= "string" then
            return false, "Tab name is required and must be a string"
        end
    elseif configType == "button" then
        if not config.Name or type(config.Name) ~= "string" then
            return false, "Button name is required and must be a string"
        end
    elseif configType == "toggle" then
        if not config.Name or type(config.Name) ~= "string" then
            return false, "Toggle name is required and must be a string"
        end
    elseif configType == "label" then
        if not config.Text or type(config.Text) ~= "string" then
            return false, "Label text is required and must be a string"
        end
    end
    
    return true
end

local function stringToKeyCode(keyString)
    if type(keyString) == "string" then
        local success, keyCode = pcall(function()
            return Enum.KeyCode[keyString]
        end)
        if success and keyCode then
            return keyCode
        end
    end
    return keyString or Enum.KeyCode.Insert
end

function NexusUI.new(config)
    config = config or {}
    
    if config.ToggleKey and type(config.ToggleKey) == "string" then
        config.ToggleKey = stringToKeyCode(config.ToggleKey)
    end
    
    local keySystemConfig = config.KeySystem or {Enabled = false}
    local keySettings = keySystemConfig.KeySettings or {}
    
    -- Deep merge colors to prevent nil values
    local mergedColors = deepMerge(NexusUI.DefaultColors, config.Colors or {})
    
    local self = setmetatable({
        Config = {
            WindowSize = config.WindowSize or NexusUI.DefaultConfig.WindowSize,
            CornerRadius = config.CornerRadius or NexusUI.DefaultConfig.CornerRadius,
            AnimationDuration = config.AnimationDuration or NexusUI.DefaultConfig.AnimationDuration,
            BlurAmount = config.BlurAmount or NexusUI.DefaultConfig.BlurAmount,
            ToggleKey = config.ToggleKey or NexusUI.DefaultConfig.ToggleKey
        },
        Colors = mergedColors,
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
        InputConnection = nil,
        Destroyed = false
    }, NexusUI)
    
    -- Validate critical properties
    if not self.Colors then
        self.Colors = NexusUI.DefaultColors
    end
    
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
    if self.Destroyed then return end
    
    self:CreateBlurEffect()
    self:CreateMainUI()
    self:SetupEventHandlers()
    
    if self.KeySystem.Enabled and not self.KeySystem.KeyValidated then
        self:ShowKeySystem()
    else
        self:ShowMainUI()
    end
end

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
        end
    end
end

function NexusUI:SaveKeyToFile(key)
    if not self.KeySystem.KeySettings.SaveKey then return false end
    
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
        local keys = {}
        for key in string.gmatch(keysData, "[^\r\n]+") do
            if key and key ~= "" then
                table.insert(keys, key)
            end
        end
        
        if #keys > 0 then
            self.KeySystem.KeySettings.Key = keys
        end
    end
end

function NexusUI:ValidateKey(inputKey)
    if not inputKey or type(inputKey) ~= "string" then return false end
    
    inputKey = string.upper(inputKey:gsub("%s+", ""))

    for _, validKey in ipairs(self.KeySystem.KeySettings.Key) do
        if string.upper(validKey:gsub("%s+", "")) == inputKey then
            return true
        end
    end
    
    return false
end

function NexusUI:CreateBlurEffect()
    if self.Destroyed then return end
    
    pcall(function()
        if self.BlurEffect then
            self.BlurEffect:Destroy()
        end
        
        self.BlurEffect = Instance.new("BlurEffect")
        self.BlurEffect.Size = 0
        self.BlurEffect.Parent = game:GetService("Lighting")
    end)
end

function NexusUI:CreateMainUI()
    if self.Destroyed or not self.Colors then return end
    
    -- Safe cleanup of old UI
    pcall(function()
        local oldUI = CoreGui:FindFirstChild("NexusUIModern")
        if oldUI then
            oldUI:Destroy()
        end
    end)
    
    -- Create ScreenGui with validation
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "NexusUIModern"
    self.ScreenGui.Parent = CoreGui
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Enabled = false
    
    -- Create MainWindow with safe color access
    self.MainWindow = Instance.new("Frame")
    self.MainWindow.Name = "MainWindow"
    self.MainWindow.Size = self.Config.WindowSize
    self.MainWindow.Position = UDim2.new(0.5, -self.Config.WindowSize.X.Offset/2, 0.5, -self.Config.WindowSize.Y.Offset/2)
    self.MainWindow.BackgroundColor3 = safeGetColor(self.Colors, "Background")
    self.MainWindow.BackgroundTransparency = 1
    self.MainWindow.Visible = false
    self.MainWindow.Parent = self.ScreenGui
    
    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = self.Config.CornerRadius
    WindowCorner.Parent = self.MainWindow
    
    local WindowStroke = Instance.new("UIStroke")
    WindowStroke.Color = safeGetColor(self.Colors, "SurfaceLight")
    WindowStroke.Thickness = 1
    WindowStroke.Parent = self.MainWindow
    
    -- TopBar with safe colors
    self.TopBar = Instance.new("Frame")
    self.TopBar.Name = "TopBar"
    self.TopBar.Size = UDim2.new(1, 0, 0, 40)
    self.TopBar.BackgroundColor3 = safeGetColor(self.Colors, "Surface")
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
    self.TitleLabel.TextColor3 = safeGetColor(self.Colors, "TextPrimary")
    self.TitleLabel.TextSize = 16
    self.TitleLabel.Font = Enum.Font.GothamBold
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.TitleLabel.Parent = self.TopBar
    
    self.CloseButton = Instance.new("ImageButton")
    self.CloseButton.Name = "CloseButton"
    self.CloseButton.Size = UDim2.new(0, 25, 0, 25)
    self.CloseButton.Position = UDim2.new(1, -35, 0.5, -12.5)
    self.CloseButton.BackgroundColor3 = safeGetColor(self.Colors, "Error")
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
    CloseIcon.ImageColor3 = safeGetColor(self.Colors, "TextPrimary")
    CloseIcon.Parent = self.CloseButton

    self.MainContent = Instance.new("Frame")
    self.MainContent.Name = "MainContent"
    self.MainContent.Size = UDim2.new(1, 0, 1, -40)
    self.MainContent.Position = UDim2.new(0, 0, 0, 40)
    self.MainContent.BackgroundTransparency = 1
    self.MainContent.Parent = self.MainWindow

    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Name = "Sidebar"
    self.Sidebar.Size = UDim2.new(0, 200, 1, 0)
    self.Sidebar.BackgroundColor3 = safeGetColor(self.Colors, "Surface")
    self.Sidebar.Parent = self.MainContent
    
    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 10)
    SidebarCorner.Parent = self.Sidebar

    self.NavigationList = Instance.new("ScrollingFrame")
    self.NavigationList.Name = "NavigationList"
    self.NavigationList.Size = UDim2.new(1, -20, 1, -100)
    self.NavigationList.Position = UDim2.new(0, 10, 0, 10)
    self.NavigationList.BackgroundTransparency = 1
    self.NavigationList.ScrollBarThickness = 4
    self.NavigationList.ScrollBarImageColor3 = safeGetColor(self.Colors, "SurfaceLight")
    self.NavigationList.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.NavigationList.Parent = self.Sidebar
    
    self.NavigationLayout = Instance.new("UIListLayout")
    self.NavigationLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.NavigationLayout.Padding = UDim.new(0, 6)
    self.NavigationLayout.Parent = self.NavigationList

    self.ProfileSection = Instance.new("Frame")
    self.ProfileSection.Name = "ProfileSection"
    self.ProfileSection.Size = UDim2.new(1, -20, 0, 80)
    self.ProfileSection.Position = UDim2.new(0, 10, 1, -90)
    self.ProfileSection.BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")
    self.ProfileSection.Parent = self.Sidebar
    
    local ProfileCorner = Instance.new("UICorner")
    ProfileCorner.CornerRadius = self.Config.CornerRadius
    ProfileCorner.Parent = self.ProfileSection
    
    local AvatarFrame = Instance.new("Frame")
    AvatarFrame.Name = "AvatarFrame"
    AvatarFrame.Size = UDim2.new(0, 50, 0, 50)
    AvatarFrame.Position = UDim2.new(0, 10, 0.5, -25)
    AvatarFrame.BackgroundColor3 = safeGetColor(self.Colors, "Surface")
    AvatarFrame.Parent = self.ProfileSection
    
    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = AvatarFrame
    
    local AvatarStroke = Instance.new("UIStroke")
    AvatarStroke.Color = safeGetColor(self.Colors, "Primary")
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
    self.UsernameLabel.TextColor3 = safeGetColor(self.Colors, "TextPrimary")
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
    self.WelcomeLabel.TextColor3 = safeGetColor(self.Colors, "TextSecondary")
    self.WelcomeLabel.TextSize = 12
    self.WelcomeLabel.Font = Enum.Font.Gotham
    self.WelcomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.WelcomeLabel.Parent = self.ProfileSection
    
    self.ContentPages = Instance.new("Frame")
    self.ContentPages.Name = "ContentPages"
    self.ContentPages.Size = UDim2.new(1, -200, 1, 0)
    self.ContentPages.Position = UDim2.new(0, 200, 0, 0)
    self.ContentPages.BackgroundTransparency = 1
    self.ContentPages.Parent = self.MainContent

    self:CreateKeySystem()
   
    self.dragging = false
    self.dragInput = nil
    self.dragStart = nil
    self.startPos = nil
end

function NexusUI:CreateKeySystem()
    if self.Destroyed or not self.Colors then return end
    
    self.KeySystemUI = Instance.new("Frame")
    self.KeySystemUI.Name = "KeySystem"
    self.KeySystemUI.Size = UDim2.new(0, 450, 0, 400)
    self.KeySystemUI.Position = UDim2.new(0.5, -225, 0.5, -200)
    self.KeySystemUI.BackgroundColor3 = safeGetColor(self.Colors, "Background")
    self.KeySystemUI.BackgroundTransparency = 1
    self.KeySystemUI.Visible = false
    self.KeySystemUI.Parent = self.ScreenGui
    
    local KeySystemCorner = Instance.new("UICorner")
    KeySystemCorner.CornerRadius = self.Config.CornerRadius
    KeySystemCorner.Parent = self.KeySystemUI
    
    local KeySystemStroke = Instance.new("UIStroke")
    KeySystemStroke.Color = safeGetColor(self.Colors, "SurfaceLight")
    KeySystemStroke.Thickness = 1
    KeySystemStroke.Parent = self.KeySystemUI
   
    local KeyTitle = Instance.new("TextLabel")
    KeyTitle.Name = "KeyTitle"
    KeyTitle.Size = UDim2.new(1, 0, 0, 80)
    KeyTitle.Position = UDim2.new(0, 0, 0, 0)
    KeyTitle.BackgroundColor3 = safeGetColor(self.Colors, "Surface")
    KeyTitle.Text = self.KeySystem.KeySettings.Title
    KeyTitle.TextColor3 = safeGetColor(self.Colors, "TextPrimary")
    KeyTitle.TextSize = 24
    KeyTitle.Font = Enum.Font.GothamBold
    KeyTitle.Parent = self.KeySystemUI
    
    local KeyTitleCorner = Instance.new("UICorner")
    KeyTitleCorner.CornerRadius = UDim.new(0, 10)
    KeyTitleCorner.Parent = KeyTitle
    
    local KeySubtitle = Instance.new("TextLabel")
    KeySubtitle.Name = "KeySubtitle"
    KeySubtitle.Size = UDim2.new(1, -40, 0, 30)
    KeySubtitle.Position = UDim2.new(0, 20, 0, 90)
    KeySubtitle.BackgroundTransparency = 1
    KeySubtitle.Text = self.KeySystem.KeySettings.Subtitle
    KeySubtitle.TextColor3 = safeGetColor(self.Colors, "TextSecondary")
    KeySubtitle.TextSize = 16
    KeySubtitle.Font = Enum.Font.Gotham
    KeySubtitle.TextXAlignment = Enum.TextXAlignment.Left
    KeySubtitle.Parent = self.KeySystemUI
    
    self.KeyInput = Instance.new("TextBox")
    self.KeyInput.Name = "KeyInput"
    self.KeyInput.Size = UDim2.new(1, -40, 0, 45)
    self.KeyInput.Position = UDim2.new(0, 20, 0, 130)
    self.KeyInput.BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")
    self.KeyInput.TextColor3 = safeGetColor(self.Colors, "TextPrimary")
    self.KeyInput.Text = ""
    self.KeyInput.PlaceholderText = "Введите ваш ключ..."
    self.KeyInput.PlaceholderColor3 = safeGetColor(self.Colors, "TextSecondary")
    self.KeyInput.TextSize = 16
    self.KeyInput.Font = Enum.Font.Gotham
    self.KeyInput.Parent = self.KeySystemUI
    
    local KeyInputCorner = Instance.new("UICorner")
    KeyInputCorner.CornerRadius = self.Config.CornerRadius
    KeyInputCorner.Parent = self.KeyInput
    
    self.KeySubmit = Instance.new("TextButton")
    self.KeySubmit.Name = "KeySubmit"
    self.KeySubmit.Size = UDim2.new(1, -40, 0, 45)
    self.KeySubmit.Position = UDim2.new(0, 20, 0, 190)
    self.KeySubmit.BackgroundColor3 = safeGetColor(self.Colors, "Primary")
    self.KeySubmit.TextColor3 = safeGetColor(self.Colors, "TextPrimary")
    self.KeySubmit.Text = "АКТИВИРОВАТЬ"
    self.KeySubmit.TextSize = 16
    self.KeySubmit.Font = Enum.Font.GothamBold
    self.KeySubmit.Parent = self.KeySystemUI
    
    local KeySubmitCorner = Instance.new("UICorner")
    KeySubmitCorner.CornerRadius = self.Config.CornerRadius
    KeySubmitCorner.Parent = self.KeySubmit
    
    local KeyNote = Instance.new("TextLabel")
    KeyNote.Name = "KeyNote"
    KeyNote.Size = UDim2.new(1, -40, 0, 60)
    KeyNote.Position = UDim2.new(0, 20, 0, 250)
    KeyNote.BackgroundTransparency = 1
    KeyNote.Text = self.KeySystem.KeySettings.Note
    KeyNote.TextColor3 = safeGetColor(self.Colors, "TextSecondary")
    KeyNote.TextSize = 12
    KeyNote.Font = Enum.Font.Gotham
    KeyNote.TextWrapped = true
    KeyNote.Parent = self.KeySystemUI
    
    self.KeyMessage = Instance.new("TextLabel")
    self.KeyMessage.Name = "KeyMessage"
    self.KeyMessage.Size = UDim2.new(1, -40, 0, 40)
    self.KeyMessage.Position = UDim2.new(0, 20, 0, 320)
    self.KeyMessage.BackgroundTransparency = 1
    self.KeyMessage.Text = "Введите ключ для доступа к интерфейсу"
    self.KeyMessage.TextColor3 = safeGetColor(self.Colors, "TextSecondary")
    self.KeyMessage.TextSize = 14
    self.KeyMessage.Font = Enum.Font.Gotham
    self.KeyMessage.TextWrapped = true
    self.KeyMessage.Parent = self.KeySystemUI
end

function NexusUI:ShowKeySystem()
    if self.Destroyed or not self.ScreenGui or not self.KeySystemUI then return end
    
    self.ScreenGui.Enabled = true
    self.KeySystemUI.Visible = true
    self.KeySystemUI.BackgroundTransparency = 1
    
    self:SafeTween(self.KeySystemUI, TweenInfo.new(0.5), {BackgroundTransparency = 0})
    self:SafeTween(self.BlurEffect, TweenInfo.new(0.5), {Size = self.Config.BlurAmount})
    
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
    if self.Destroyed or not self.KeySystemUI then return end
    
    self:SafeTween(self.KeySystemUI, TweenInfo.new(0.3), {BackgroundTransparency = 1})
    wait(0.3)
    self.KeySystemUI.Visible = false
end

function NexusUI:OnKeySubmit()
    if self.Destroyed then return end
    
    local key = self.KeyInput.Text
    
    if self:ValidateKey(key) then
        self.KeySystem.CurrentKey = key
        self.KeySystem.KeyValidated = true
        self.KeyMessage.Text = "✅ Ключ принят! Загрузка..."
        self.KeyMessage.TextColor3 = safeGetColor(self.Colors, "Success")
        
        if self.KeySystem.KeySettings.SaveKey then
            self:SaveKeyToFile(key)
        end
        
        self:SafeTween(self.KeySubmit, TweenInfo.new(0.3), {BackgroundColor3 = safeGetColor(self.Colors, "Success")})
        
        wait(1.5)
        self:HideKeySystem()
        self:ShowMainUI()
    else
        self.KeyMessage.Text = "❌ Неверный ключ! Попробуйте снова."
        self.KeyMessage.TextColor3 = safeGetColor(self.Colors, "Error")
        
        self:SafeTween(self.KeySubmit, TweenInfo.new(0.3), {BackgroundColor3 = safeGetColor(self.Colors, "Error")})
        wait(1)
        self:SafeTween(self.KeySubmit, TweenInfo.new(0.3), {BackgroundColor3 = safeGetColor(self.Colors, "Primary")})
    end
end

function NexusUI:SetupEventHandlers()
    if self.Destroyed then return end
    
    -- Safe event connection with pcall
    if self.KeySubmit then
        pcall(function()
            self.KeySubmit.MouseButton1Click:Connect(function()
                self:OnKeySubmit()
            end)
        end)
    end

    if self.TopBar then
        pcall(function()
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
        end)
    end
    
    pcall(function()
        UserInputService.InputChanged:Connect(function(input)
            if input == self.dragInput and self.dragging and self.MainWindow then
                self:UpdateInput(input)
            end
        end)
    end)

    if self.CloseButton then
        pcall(function()
            self.CloseButton.MouseButton1Click:Connect(function()
                self:HideMainUI()
            end)
        end)
    end

    pcall(function()
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
    end)
    
    pcall(function()
        Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
            if not parent then
                self:Destroy()
            end
        end)
    end)
end

function NexusUI:UpdateInput(input)
    if self.Destroyed or not self.MainWindow or not self.MainWindow.Parent then return end
    local delta = input.Position - self.dragStart
    self.MainWindow.Position = UDim2.new(
        self.startPos.X.Scale, 
        self.startPos.X.Offset + delta.X, 
        self.startPos.Y.Scale, 
        self.startPos.Y.Offset + delta.Y
    )
end

function NexusUI:ShowMainUI()
    if self.Destroyed or not self.ScreenGui or not self.ScreenGui.Parent or not self.MainWindow then return end
    
    pcall(function()
        local userId = Players.LocalPlayer.UserId
        self.AvatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
    end)
    
    self.ScreenGui.Enabled = true
    self.MainWindow.Visible = true
    
    self:SafeTween(self.BlurEffect, TweenInfo.new(0.5), {Size = self.Config.BlurAmount})
    
    self.MainWindow.BackgroundTransparency = 1
    self:SafeTween(self.MainWindow, TweenInfo.new(self.Config.AnimationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        Size = self.Config.WindowSize
    })
    
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
    if self.Destroyed or not self.ScreenGui then return end
    
    self:SafeTween(self.MainWindow, TweenInfo.new(self.Config.AnimationDuration, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0)
    })
    
    self:SafeTween(self.BlurEffect, TweenInfo.new(0.3), {Size = 0})
    
    wait(self.Config.AnimationDuration)
    if self.MainWindow then
        self.MainWindow.Visible = false
    end
    self.ScreenGui.Enabled = false
    self.Enabled = false
end

-- Improved SafeTween with comprehensive checks
function NexusUI:SafeTween(object, tweenInfo, properties)
    if self.Destroyed or not object or not object.Parent then 
        return nil 
    end
    
    local success, tween = pcall(function()
        local tween = TweenService:Create(object, tweenInfo, properties)
        tween:Play()
        return tween
    end)
    
    if not success then
        warn("NexusUI: Failed to create tween for object " .. tostring(object))
        return nil
    end
    
    return tween
end

-- Tab management with validation
function NexusUI:CreateTab(tabConfig)
    if self.Destroyed then return nil end
    
    local isValid, errorMsg = validateConfig(tabConfig, "tab")
    if not isValid then
        warn("NexusUI: " .. errorMsg)
        return nil
    end
    
    local tabName = tabConfig.Name
    
    -- Validate parent containers exist
    if not self.NavigationList or not self.ContentPages then
        warn("NexusUI: Required parent containers not found")
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
    pcall(function()
        navButton.MouseButton1Click:Connect(function()
            self:SelectTab(tabName)
        end)
    end)
    
    -- Select first tab automatically
    if not self.CurrentTab then
        self.CurrentTab = tabName
    end
    
    -- Update navigation list size
    if self.NavigationLayout then
        pcall(function()
            self.NavigationLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if self.NavigationList and self.NavigationList.Parent then
                    self.NavigationList.CanvasSize = UDim2.new(0, 0, 0, self.NavigationLayout.AbsoluteContentSize.Y)
                end
            end)
        end)
    end
    
    -- Create tab API object
    local tabAPI = {}
    
    function tabAPI.AddButton(buttonConfig)
        if self.Destroyed then return nil end
        local isValid, errorMsg = validateConfig(buttonConfig, "button")
        if not isValid then
            warn("NexusUI: " .. errorMsg)
            return nil
        end
        return self:AddButtonToTab(tabName, buttonConfig)
    end
    
    function tabAPI.AddToggle(toggleConfig)
        if self.Destroyed then return nil end
        local isValid, errorMsg = validateConfig(toggleConfig, "toggle")
        if not isValid then
            warn("NexusUI: " .. errorMsg)
            return nil
        end
        return self:AddToggleToTab(tabName, toggleConfig)
    end
    
    function tabAPI.AddSection(sectionConfig)
        if self.Destroyed then return nil end
        return self:AddSectionToTab(tabName, sectionConfig)
    end
    
    function tabAPI.AddLabel(labelConfig)
        if self.Destroyed then return nil end
        local isValid, errorMsg = validateConfig(labelConfig, "label")
        if not isValid then
            warn("NexusUI: " .. errorMsg)
            return nil
        end
        return self:AddLabelToTab(tabName, labelConfig)
    end
    
    return tabAPI
end

function NexusUI:SelectTab(tabName)
    if self.Destroyed or not self.Tabs[tabName] then return end
    
    -- Deselect all buttons
    for name, tabData in pairs(self.Tabs) do
        if tabData.Button and tabData.Button.Parent then
            tabData.Button:SetAttribute("Selected", false)
            self:SafeTween(tabData.Button, TweenInfo.new(0.2), {BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")})
            if tabData.Button:FindFirstChild("Highlight") then
                self:SafeTween(tabData.Button.Highlight, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            end
            if tabData.Button:FindFirstChild("Label") then
                self:SafeTween(tabData.Button.Label, TweenInfo.new(0.2), {TextColor3 = safeGetColor(self.Colors, "TextSecondary")})
            end
            if tabData.Button:FindFirstChild("Icon") then
                self:SafeTween(tabData.Button.Icon, TweenInfo.new(0.2), {ImageColor3 = safeGetColor(self.Colors, "TextSecondary")})
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
    self:SafeTween(currentTab.Button, TweenInfo.new(0.2), {BackgroundColor3 = safeGetColor(self.Colors, "Primary")})
    if currentTab.Button:FindFirstChild("Highlight") then
        self:SafeTween(currentTab.Button.Highlight, TweenInfo.new(0.2), {BackgroundTransparency = 0})
    end
    if currentTab.Button:FindFirstChild("Label") then
        self:SafeTween(currentTab.Button.Label, TweenInfo.new(0.2), {TextColor3 = safeGetColor(self.Colors, "TextPrimary")})
    end
    if currentTab.Button:FindFirstChild("Icon") then
        self:SafeTween(currentTab.Button.Icon, TweenInfo.new(0.2), {ImageColor3 = safeGetColor(self.Colors, "TextPrimary")})
    end
    
    if currentTab.Page then
        currentTab.Page.Visible = true
    end
    self.CurrentTab = tabName
end

-- UI element creation functions with safety
function NexusUI:CreateNavButton(navConfig)
    if self.Destroyed or not navConfig or not navConfig.Name or not self.NavigationList then
        return nil
    end
    
    local button = Instance.new("TextButton")
    button.Name = navConfig.Name .. "Nav"
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")
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
    icon.ImageColor3 = safeGetColor(self.Colors, "TextSecondary")
    icon.Parent = button
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -45, 1, 0)
    label.Position = UDim2.new(0, 40, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = navConfig.Name
    label.TextColor3 = safeGetColor(self.Colors, "TextSecondary")
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = button
    
    local highlight = Instance.new("Frame")
    highlight.Name = "Highlight"
    highlight.Size = UDim2.new(0, 3, 0.6, 0)
    highlight.Position = UDim2.new(0, 0, 0.2, 0)
    highlight.BackgroundColor3 = safeGetColor(self.Colors, "Primary")
    highlight.BackgroundTransparency = 1
    highlight.Parent = button
    
    local highlightCorner = Instance.new("UICorner")
    highlightCorner.CornerRadius = UDim.new(1, 0)
    highlightCorner.Parent = highlight
    
    -- Hover effects with safety
    pcall(function()
        button.MouseEnter:Connect(function()
            if not button:GetAttribute("Selected") then
                self:SafeTween(button, TweenInfo.new(0.2), {BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")})
                self:SafeTween(label, TweenInfo.new(0.2), {TextColor3 = safeGetColor(self.Colors, "TextPrimary")})
                self:SafeTween(icon, TweenInfo.new(0.2), {ImageColor3 = safeGetColor(self.Colors, "TextPrimary")})
            end
        end)
        
        button.MouseLeave:Connect(function()
            if not button:GetAttribute("Selected") then
                self:SafeTween(button, TweenInfo.new(0.2), {BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")})
                self:SafeTween(label, TweenInfo.new(0.2), {TextColor3 = safeGetColor(self.Colors, "TextSecondary")})
                self:SafeTween(icon, TweenInfo.new(0.2), {ImageColor3 = safeGetColor(self.Colors, "TextSecondary")})
            end
        end)
    end)
    
    return button
end

function NexusUI:CreateContentPage(pageConfig)
    if self.Destroyed or not pageConfig or not pageConfig.Name or not self.ContentPages then
        return nil
    end
    
    local page = Instance.new("ScrollingFrame")
    page.Name = pageConfig.Name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = safeGetColor(self.Colors, "SurfaceLight")
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
    
    pcall(function()
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if page and page.Parent then
                page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 30)
            end
        end)
    end)
    
    return page
end

-- FIXED SECTION CREATION FUNCTION
function NexusUI:AddSectionToTab(tabName, sectionConfig)
    if self.Destroyed then 
        warn("NexusUI: Library is destroyed")
        return nil 
    end
    
    if not self.Tabs[tabName] then 
        warn("NexusUI: Tab '" .. tostring(tabName) .. "' does not exist")
        return nil
    end
    
    local isValid, errorMsg = validateConfig(sectionConfig, "section")
    if not isValid then
        warn("NexusUI: " .. errorMsg)
        return nil
    end
    
    local tab = self.Tabs[tabName]
    
    -- Create section with safe error handling
    local section = self:CreateRoundedFrame(tab.Page, UDim2.new(1, 0, 0, 50), nil, safeGetColor(self.Colors, "Surface"))
    if not section then
        warn("NexusUI: Failed to create section frame")
        return nil
    end
    
    section.BackgroundTransparency = 0
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.new(0, 15, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = tostring(sectionConfig.Name)
    title.TextColor3 = safeGetColor(self.Colors, "TextPrimary")
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
    
    pcall(function()
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if content and content.Parent then
                content.Size = UDim2.new(1, -20, 0, contentLayout.AbsoluteContentSize.Y)
                section.Size = UDim2.new(1, 0, 0, 55 + contentLayout.AbsoluteContentSize.Y)
            end
        end)
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
        if self.Destroyed then return nil end
        local isValid, errorMsg = validateConfig(buttonConfig, "button")
        if not isValid then
            warn("NexusUI: " .. errorMsg)
            return nil
        end
        return self:CreateButton(content, buttonConfig)
    end
    
    function sectionAPI.AddToggle(toggleConfig)
        if self.Destroyed then return nil end
        local isValid, errorMsg = validateConfig(toggleConfig, "toggle")
        if not isValid then
            warn("NexusUI: " .. errorMsg)
            return nil
        end
        return self:CreateToggle(content, toggleConfig)
    end
    
    function sectionAPI.AddLabel(labelConfig)
        if self.Destroyed then return nil end
        local isValid, errorMsg = validateConfig(labelConfig, "label")
        if not isValid then
            warn("NexusUI: " .. errorMsg)
            return nil
        end
        return self:CreateLabel(content, labelConfig)
    end
    
    return sectionAPI
end

function NexusUI:AddButtonToTab(tabName, buttonConfig)
    if self.Destroyed or not self.Tabs[tabName] then return nil end
    
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

function NexusUI:CreateButton(parent, buttonConfig)
    if self.Destroyed or not buttonConfig or type(buttonConfig) ~= "table" then
        warn("NexusUI: Invalid button configuration")
        return nil
    end
    
    local isValid, errorMsg = validateConfig(buttonConfig, "button")
    if not isValid then
        warn("NexusUI: " .. errorMsg)
        return nil
    end
    
    local button = Instance.new("TextButton")
    button.Name = buttonConfig.Name .. "Button"
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = safeGetColor(self.Colors, "Primary")
    button.Text = buttonConfig.Name
    button.TextColor3 = safeGetColor(self.Colors, "TextPrimary")
    button.TextSize = 13
    button.Font = Enum.Font.Gotham
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self.Config.CornerRadius
    corner.Parent = button
    
    -- Hover effects
    pcall(function()
        button.MouseEnter:Connect(function()
            self:SafeTween(button, TweenInfo.new(0.2), {BackgroundColor3 = safeGetColor(self.Colors, "PrimaryDark")})
        end)
        
        button.MouseLeave:Connect(function()
            self:SafeTween(button, TweenInfo.new(0.2), {BackgroundColor3 = safeGetColor(self.Colors, "Primary")})
        end)
    end)
    
    if buttonConfig.Callback and type(buttonConfig.Callback) == "function" then
        pcall(function()
            button.MouseButton1Click:Connect(function()
                pcall(buttonConfig.Callback)
            end)
        end)
    end
    
    return button
end

function NexusUI:AddToggleToTab(tabName, toggleConfig)
    if self.Destroyed or not self.Tabs[tabName] then return nil end
    
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

function NexusUI:CreateToggle(parent, toggleConfig)
    if self.Destroyed or not toggleConfig or type(toggleConfig) ~= "table" then
        warn("NexusUI: Invalid toggle configuration")
        return nil
    end
    
    local isValid, errorMsg = validateConfig(toggleConfig, "toggle")
    if not isValid then
        warn("NexusUI: " .. errorMsg)
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
    label.TextColor3 = safeGetColor(self.Colors, "TextPrimary")
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 45, 0, 22)
    toggleButton.Position = UDim2.new(1, -45, 0.5, -11)
    toggleButton.BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")
    toggleButton.Text = ""
    toggleButton.Parent = toggle
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleButton
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Name = "ToggleKnob"
    toggleKnob.Size = UDim2.new(0, 18, 0, 18)
    toggleKnob.Position = UDim2.new(0, 2, 0.5, -9)
    toggleKnob.BackgroundColor3 = safeGetColor(self.Colors, "TextPrimary")
    toggleKnob.Parent = toggleButton
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = toggleKnob
    
    local currentValue = toggleConfig.CurrentValue or false
    
    local function updateToggle()
        if currentValue then
            self:SafeTween(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = safeGetColor(self.Colors, "Primary")})
            self:SafeTween(toggleKnob, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9)})
        else
            self:SafeTween(toggleButton, TweenInfo.new(0.2), {BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")})
            self:SafeTween(toggleKnob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9)})
        end
    end
    
    pcall(function()
        toggleButton.MouseButton1Click:Connect(function()
            currentValue = not currentValue
            updateToggle()
            if toggleConfig.Callback and type(toggleConfig.Callback) == "function" then
                pcall(toggleConfig.Callback, currentValue)
            end
        end)
    end)
    
    updateToggle()
    
    local toggleObject = {}
    function toggleObject:Set(value)
        if self.Destroyed then return end
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
    if self.Destroyed or not self.Tabs[tabName] then return nil end
    
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

function NexusUI:CreateLabel(parent, labelConfig)
    if self.Destroyed or not labelConfig or type(labelConfig) ~= "table" then
        warn("NexusUI: Invalid label configuration")
        return nil
    end
    
    local isValid, errorMsg = validateConfig(labelConfig, "label")
    if not isValid then
        warn("NexusUI: " .. errorMsg)
        return nil
    end
    
    local label = Instance.new("TextLabel")
    label.Name = "Label_" .. labelConfig.Text
    label.Size = UDim2.new(1, 0, 0, labelConfig.Height or 20)
    label.BackgroundTransparency = 1
    label.Text = labelConfig.Text
    label.TextColor3 = labelConfig.Color or safeGetColor(self.Colors, "TextPrimary")
    label.TextSize = labelConfig.TextSize or 13
    label.Font = labelConfig.Font or Enum.Font.Gotham
    label.TextXAlignment = labelConfig.Alignment or Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.Parent = parent
    
    return label
end

function NexusUI:CreateRoundedFrame(parent, size, position, backgroundColor)
    if self.Destroyed or not parent then return nil end
    local frame = Instance.new("Frame")
    frame.Size = size or UDim2.new(1, 0, 1, 0)
    frame.Position = position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = backgroundColor or safeGetColor(self.Colors, "Surface")
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self.Config.CornerRadius
    corner.Parent = frame
    
    return frame
end

function NexusUI:SetTitle(title)
    if self.Destroyed or not self.TitleLabel or type(title) ~= "string" then return end
    self.TitleLabel.Text = title
end

function NexusUI:SetWindowSize(size)
    if self.Destroyed or not self.MainWindow then return end
    self.Config.WindowSize = size
    self.MainWindow.Size = size
    self.MainWindow.Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
end

function NexusUI:Toggle()
    if self.Destroyed then return end
    if not self.Enabled then
        self:ShowMainUI()
    else
        self:HideMainUI()
    end
end

function NexusUI:Show()
    if self.Destroyed then return end
    self:ShowMainUI()
end

function NexusUI:Hide()
    if self.Destroyed then return end
    self:HideMainUI()
end

-- Improved Destroy method with comprehensive cleanup
function NexusUI:Destroy()
    if self.Destroyed then return end
    
    self.Destroyed = true
    self.Enabled = false
    
    -- Disconnect input connection
    if self.InputConnection then
        self.InputConnection:Disconnect()
        self.InputConnection = nil
    end
    
    -- Clean up UI elements safely
    pcall(function()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
            self.ScreenGui = nil
        end
    end)
    
    pcall(function()
        if self.BlurEffect then
            self.BlurEffect:Destroy()
            self.BlurEffect = nil
        end
    end)
    
    -- Clean up tables
    self.Elements = nil
    self.Tabs = nil
    self.Colors = nil
    self.Config = nil
end

return NexusUI
