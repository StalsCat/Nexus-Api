-- NexusUI Library v2.1 (Ultra Stable - Fixed Edition)
-- By StalsCat, ZestyKJScripts
-- Fixed by Assistant

local NexusUI = {}
NexusUI.__index = NexusUI

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- Default configurations
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

-- Utility functions
local function deepMerge(defaultTable, userTable)
    if type(userTable) ~= "table" then 
        return table.clone(defaultTable)
    end
    
    local result = table.clone(defaultTable)
    
    for key, value in pairs(userTable) do
        if value ~= nil then
            if type(value) == "table" and type(result[key]) == "table" then
                result[key] = deepMerge(result[key], value)
            else
                result[key] = value
            end
        end
    end
    return result
end

local function safeGetColor(colors, colorName, fallback)
    if not colors or type(colors) ~= "table" then
        return fallback or Color3.fromRGB(255, 255, 255)
    end
    
    local color = colors[colorName]
    if not color or typeof(color) ~= "Color3" then
        return fallback or NexusUI.DefaultColors[colorName] or Color3.fromRGB(255, 255, 255)
    end
    
    return color
end

local function validateConfig(config, configType)
    if config == nil then
        return false, configType .. " configuration is nil"
    end
    
    if type(config) ~= "table" then
        return false, configType .. " configuration must be a table, got " .. type(config)
    end
    
    if configType == "section" then
        if not config.Name then
            return false, "Section name is required"
        end
        if type(config.Name) ~= "string" then
            return false, "Section name must be a string, got " .. type(config.Name)
        end
        if config.Name == "" then
            return false, "Section name cannot be empty"
        end
        
    elseif configType == "tab" then
        if not config.Name then
            return false, "Tab name is required"
        end
        if type(config.Name) ~= "string" then
            return false, "Tab name must be a string, got " .. type(config.Name)
        end
        if config.Name == "" then
            return false, "Tab name cannot be empty"
        end
        
    elseif configType == "button" then
        if not config.Name then
            return false, "Button name is required"
        end
        if type(config.Name) ~= "string" then
            return false, "Button name must be a string, got " .. type(config.Name)
        end
        if config.Name == "" then
            return false, "Button name cannot be empty"
        end
        if config.Callback and type(config.Callback) ~= "function" then
            return false, "Button callback must be a function"
        end
        
    elseif configType == "toggle" then
        if not config.Name then
            return false, "Toggle name is required"
        end
        if type(config.Name) ~= "string" then
            return false, "Toggle name must be a string, got " .. type(config.Name)
        end
        if config.Name == "" then
            return false, "Toggle name cannot be empty"
        end
        if config.Callback and type(config.Callback) ~= "function" then
            return false, "Toggle callback must be a function"
        end
        
    elseif configType == "label" then
        if not config.Text then
            return false, "Label text is required"
        end
        if type(config.Text) ~= "string" then
            return false, "Label text must be a string, got " .. type(config.Text)
        end
        if config.Text == "" then
            return false, "Label text cannot be empty"
        end
    end
    
    return true
end

local function stringToKeyCode(keyString)
    if keyString == nil then
        return Enum.KeyCode.Insert
    end
    
    if type(keyString) == "string" then
        local success, keyCode = pcall(function()
            return Enum.KeyCode[keyString]
        end)
        if success and keyCode then
            return keyCode
        end
    end
    
    if typeof(keyString) == "EnumItem" and keyString.EnumType == Enum.KeyCode then
        return keyString
    end
    
    return Enum.KeyCode.Insert
end

local function safeCreateInstance(className, properties)
    local success, instance = pcall(function()
        local inst = Instance.new(className)
        if properties then
            for property, value in pairs(properties) do
                pcall(function()
                    inst[property] = value
                end)
            end
        end
        return inst
    end)
    
    if success then
        return instance
    else
        warn("NexusUI: Failed to create instance of type " .. className .. ": " .. tostring(instance))
        return nil
    end
end

-- Main constructor
function NexusUI.new(config)
    config = config or {}
    
    local toggleKey = stringToKeyCode(config.ToggleKey)
    
    local keySystemConfig = config.KeySystem or {Enabled = false}
    local keySettings = keySystemConfig.KeySettings or {}
    
    local mergedColors = deepMerge(NexusUI.DefaultColors, config.Colors or {})
    
    local self = setmetatable({
        Config = {
            WindowSize = typeof(config.WindowSize) == "UDim2" and config.WindowSize or NexusUI.DefaultConfig.WindowSize,
            CornerRadius = typeof(config.CornerRadius) == "UDim" and config.CornerRadius or NexusUI.DefaultConfig.CornerRadius,
            AnimationDuration = type(config.AnimationDuration) == "number" and math.max(0.1, config.AnimationDuration) or NexusUI.DefaultConfig.AnimationDuration,
            BlurAmount = type(config.BlurAmount) == "number" and math.max(0, config.BlurAmount) or NexusUI.DefaultConfig.BlurAmount,
            ToggleKey = toggleKey
        },
        Colors = mergedColors,
        KeySystem = {
            Enabled = type(keySystemConfig.Enabled) == "boolean" and keySystemConfig.Enabled or false,
            KeySettings = {
                Title = type(keySettings.Title) == "string" and keySettings.Title or "Key System",
                Subtitle = type(keySettings.Subtitle) == "string" and keySettings.Subtitle or "Enter your key",
                Note = type(keySettings.Note) == "string" and keySettings.Note or "No method of obtaining the key is provided",
                FileName = type(keySettings.FileName) == "string" and keySettings.FileName or "Key",
                SaveKey = type(keySettings.SaveKey) == "boolean" and keySettings.SaveKey or false,
                GrabKeyFromSite = type(keySettings.GrabKeyFromSite) == "boolean" and keySettings.GrabKeyFromSite or false,
                Key = type(keySettings.Key) == "table" and keySettings.Key or {"DemoKey-1234-5678-9012"},
                KeysFromSite = keySettings.KeysFromSite
            },
            CurrentKey = nil,
            KeyValidated = false
        },
        Elements = {},
        Tabs = {},
        CurrentTab = nil,
        Enabled = false,
        InputConnection = nil,
        Destroyed = false,
        Initialized = false
    }, NexusUI)
    
    local success, err = pcall(function()
        self:Initialize()
    end)
    
    if not success then
        warn("NexusUI: Initialization failed: " .. tostring(err))
        self.Destroyed = true
    else
        self.Initialized = true
    end
    
    return self
end

-- Key System Implementation
function NexusUI:LoadSavedKey()
    if not self.KeySystem.KeySettings.SaveKey then return end
    
    local success, savedKey = pcall(function()
        if readfile and type(readfile) == "function" then
            local fileName = self.KeySystem.KeySettings.FileName .. ".txt"
            if isfile and isfile(fileName) then
                return readfile(fileName)
            end
        end
        return nil
    end)
    
    if success and savedKey and type(savedKey) == "string" then
        if self:ValidateKey(savedKey) then
            self.KeySystem.CurrentKey = savedKey
            self.KeySystem.KeyValidated = true
            return true
        end
    end
    return false
end

function NexusUI:SaveKeyToFile(key)
    if not self.KeySystem.KeySettings.SaveKey then return false end
    if not key or type(key) ~= "string" then return false end
    
    local success = pcall(function()
        if writefile and type(writefile) == "function" then
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
    if not siteUrl or type(siteUrl) ~= "string" then return end
    
    local success, keysData = pcall(function()
        if syn and syn.request then
            local response = syn.request({
                Url = siteUrl,
                Method = "GET",
                Timeout = 10
            })
            if response.Success then
                return response.Body
            end
        elseif request then
            local response = request({
                Url = siteUrl,
                Method = "GET"
            })
            if response.Success then
                return response.Body
            end
        end
        return nil
    end)
    
    if success and keysData and type(keysData) == "string" then
        local keys = {}
        for key in string.gmatch(keysData, "[^\r\n]+") do
            if key and key ~= "" and type(key) == "string" then
                table.insert(keys, key)
            end
        end
        
        if #keys > 0 then
            self.KeySystem.KeySettings.Key = keys
            return true
        end
    end
    return false
end

function NexusUI:ValidateKey(inputKey)
    if not inputKey or type(inputKey) ~= "string" then return false end
    
    inputKey = string.upper(inputKey:gsub("%s+", ""))

    local validKeys = self.KeySystem.KeySettings.Key
    if not validKeys or type(validKeys) ~= "table" then return false end

    for _, validKey in ipairs(validKeys) do
        if type(validKey) == "string" and string.upper(validKey:gsub("%s+", "")) == inputKey then
            return true
        end
    end
    
    return false
end

-- UI Creation
function NexusUI:Initialize()
    if self.Destroyed then return end
    
    local success, err = pcall(function()
        self:CreateBlurEffect()
        self:CreateMainUI()
        self:SetupEventHandlers()
        
        if self.KeySystem.Enabled then
            if self:LoadSavedKey() then
                self:ShowMainUI()
            else
                self:ShowKeySystem()
            end
        else
            self:ShowMainUI()
        end
    end)
    
    if not success then
        warn("NexusUI: UI creation failed: " .. tostring(err))
        self.Destroyed = true
    end
end

function NexusUI:CreateBlurEffect()
    if self.Destroyed then return end
    
    pcall(function()
        if self.BlurEffect and self.BlurEffect.Parent then
            self.BlurEffect:Destroy()
        end
        
        self.BlurEffect = safeCreateInstance("BlurEffect", {
            Size = 0,
            Parent = game:GetService("Lighting")
        })
    end)
end

function NexusUI:CreateMainUI()
    if self.Destroyed then return end
    
    local success, err = pcall(function()
        pcall(function()
            local oldUI = CoreGui:FindFirstChild("NexusUIModern")
            if oldUI then
                oldUI:Destroy()
            end
        end)
        
        self.ScreenGui = safeCreateInstance("ScreenGui", {
            Name = "NexusUIModern",
            Parent = CoreGui,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
            Enabled = false
        })
        
        if not self.ScreenGui then
            error("Failed to create ScreenGui")
        end
        
        self.MainWindow = safeCreateInstance("Frame", {
            Name = "MainWindow",
            Size = self.Config.WindowSize,
            Position = UDim2.new(0.5, -self.Config.WindowSize.X.Offset/2, 0.5, -self.Config.WindowSize.Y.Offset/2),
            BackgroundColor3 = safeGetColor(self.Colors, "Background"),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = self.ScreenGui
        })
        
        if not self.MainWindow then
            error("Failed to create MainWindow")
        end
        
        safeCreateInstance("UICorner", {
            CornerRadius = self.Config.CornerRadius,
            Parent = self.MainWindow
        })
        
        safeCreateInstance("UIStroke", {
            Color = safeGetColor(self.Colors, "SurfaceLight"),
            Thickness = 1,
            Parent = self.MainWindow
        })
        
        self.TopBar = safeCreateInstance("Frame", {
            Name = "TopBar",
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = safeGetColor(self.Colors, "Surface"),
            Parent = self.MainWindow
        })
        
        safeCreateInstance("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = self.TopBar
        })
        
        self.TitleLabel = safeCreateInstance("TextLabel", {
            Name = "TitleLabel",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0, 15, 0, 0),
            BackgroundTransparency = 1,
            Text = "NEXUS UI",
            TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.TopBar
        })
        
        self.CloseButton = safeCreateInstance("ImageButton", {
            Name = "CloseButton",
            Size = UDim2.new(0, 25, 0, 25),
            Position = UDim2.new(1, -35, 0.5, -12.5),
            BackgroundColor3 = safeGetColor(self.Colors, "Error"),
            Parent = self.TopBar
        })
        
        safeCreateInstance("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = self.CloseButton
        })
        
        safeCreateInstance("ImageLabel", {
            Name = "CloseIcon",
            Size = UDim2.new(0.5, 0, 0.5, 0),
            Position = UDim2.new(0.25, 0, 0.25, 0),
            BackgroundTransparency = 1,
            Image = "rbxassetid://3926305904",
            ImageRectOffset = Vector2.new(284, 4),
            ImageRectSize = Vector2.new(24, 24),
            ImageColor3 = safeGetColor(self.Colors, "TextPrimary"),
            Parent = self.CloseButton
        })

        self.MainContent = safeCreateInstance("Frame", {
            Name = "MainContent",
            Size = UDim2.new(1, 0, 1, -40),
            Position = UDim2.new(0, 0, 0, 40),
            BackgroundTransparency = 1,
            Parent = self.MainWindow
        })

        self.Sidebar = safeCreateInstance("Frame", {
            Name = "Sidebar",
            Size = UDim2.new(0, 200, 1, 0),
            BackgroundColor3 = safeGetColor(self.Colors, "Surface"),
            Parent = self.MainContent
        })
        
        safeCreateInstance("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = self.Sidebar
        })

        self.NavigationList = safeCreateInstance("ScrollingFrame", {
            Name = "NavigationList",
            Size = UDim2.new(1, -20, 1, -100),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = safeGetColor(self.Colors, "SurfaceLight"),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = self.Sidebar
        })
        
        self.NavigationLayout = safeCreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = self.NavigationList
        })

        self.ProfileSection = safeCreateInstance("Frame", {
            Name = "ProfileSection",
            Size = UDim2.new(1, -20, 0, 80),
            Position = UDim2.new(0, 10, 1, -90),
            BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight"),
            Parent = self.Sidebar
        })
        
        safeCreateInstance("UICorner", {
            CornerRadius = self.Config.CornerRadius,
            Parent = self.ProfileSection
        })
        
        local AvatarFrame = safeCreateInstance("Frame", {
            Name = "AvatarFrame",
            Size = UDim2.new(0, 50, 0, 50),
            Position = UDim2.new(0, 10, 0.5, -25),
            BackgroundColor3 = safeGetColor(self.Colors, "Surface"),
            Parent = self.ProfileSection
        })
        
        safeCreateInstance("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = AvatarFrame
        })
        
        safeCreateInstance("UIStroke", {
            Color = safeGetColor(self.Colors, "Primary"),
            Thickness = 2,
            Parent = AvatarFrame
        })
        
        self.AvatarImage = safeCreateInstance("ImageLabel", {
            Name = "AvatarImage",
            Size = UDim2.new(0.8, 0, 0.8, 0),
            Position = UDim2.new(0.1, 0, 0.1, 0),
            BackgroundTransparency = 1,
            Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
            Parent = AvatarFrame
        })
        
        self.UsernameLabel = safeCreateInstance("TextLabel", {
            Name = "UsernameLabel",
            Size = UDim2.new(1, -70, 0, 20),
            Position = UDim2.new(0, 65, 0, 20),
            BackgroundTransparency = 1,
            Text = Players.LocalPlayer and Players.LocalPlayer.Name or "Player",
            TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = self.ProfileSection
        })
        
        self.WelcomeLabel = safeCreateInstance("TextLabel", {
            Name = "WelcomeLabel",
            Size = UDim2.new(1, -70, 0, 16),
            Position = UDim2.new(0, 65, 0, 42),
            BackgroundTransparency = 1,
            Text = "Добро пожаловать!",
            TextColor3 = safeGetColor(self.Colors, "TextSecondary"),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.ProfileSection
        })
        
        self.ContentPages = safeCreateInstance("Frame", {
            Name = "ContentPages",
            Size = UDim2.new(1, -200, 1, 0),
            Position = UDim2.new(0, 200, 0, 0),
            BackgroundTransparency = 1,
            Parent = self.MainContent
        })

        self:CreateKeySystem()
        
        self.dragging = false
        self.dragInput = nil
        self.dragStart = nil
        self.startPos = nil
    end)
    
    if not success then
        warn("NexusUI: Main UI creation failed: " .. tostring(err))
        self.Destroyed = true
    end
end

function NexusUI:CreateKeySystem()
    if self.Destroyed or not self.Colors then return end
    
    local success, err = pcall(function()
        self.KeySystemUI = safeCreateInstance("Frame", {
            Name = "KeySystem",
            Size = UDim2.new(0, 450, 0, 400),
            Position = UDim2.new(0.5, -225, 0.5, -200),
            BackgroundColor3 = safeGetColor(self.Colors, "Background"),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = self.ScreenGui
        })
        
        if not self.KeySystemUI then return end
        
        safeCreateInstance("UICorner", {
            CornerRadius = self.Config.CornerRadius,
            Parent = self.KeySystemUI
        })
        
        safeCreateInstance("UIStroke", {
            Color = safeGetColor(self.Colors, "SurfaceLight"),
            Thickness = 1,
            Parent = self.KeySystemUI
        })
        
        local KeyTitle = safeCreateInstance("TextLabel", {
            Name = "KeyTitle",
            Size = UDim2.new(1, 0, 0, 80),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = safeGetColor(self.Colors, "Surface"),
            Text = self.KeySystem.KeySettings.Title,
            TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
            TextSize = 24,
            Font = Enum.Font.GothamBold,
            Parent = self.KeySystemUI
        })
        
        safeCreateInstance("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = KeyTitle
        })
        
        local KeySubtitle = safeCreateInstance("TextLabel", {
            Name = "KeySubtitle",
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0, 20, 0, 90),
            BackgroundTransparency = 1,
            Text = self.KeySystem.KeySettings.Subtitle,
            TextColor3 = safeGetColor(self.Colors, "TextSecondary"),
            TextSize = 16,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.KeySystemUI
        })
        
        self.KeyInput = safeCreateInstance("TextBox", {
            Name = "KeyInput",
            Size = UDim2.new(1, -40, 0, 45),
            Position = UDim2.new(0, 20, 0, 130),
            BackgroundColor3 = safeGetColor(self.Colors, "Surface"),
            TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
            Text = "",
            PlaceholderText = "Введите ключ...",
            PlaceholderColor3 = safeGetColor(self.Colors, "TextSecondary"),
            TextSize = 14,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.KeySystemUI
        })
        
        safeCreateInstance("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = self.KeyInput
        })
        
        safeCreateInstance("UIStroke", {
            Color = safeGetColor(self.Colors, "SurfaceLight"),
            Thickness = 1,
            Parent = self.KeyInput
        })
        
        self.KeySubmit = safeCreateInstance("TextButton", {
            Name = "KeySubmit",
            Size = UDim2.new(1, -40, 0, 45),
            Position = UDim2.new(0, 20, 0, 190),
            BackgroundColor3 = safeGetColor(self.Colors, "Primary"),
            TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
            Text = "ПРОВЕРИТЬ КЛЮЧ",
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = self.KeySystemUI
        })
        
        safeCreateInstance("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = self.KeySubmit
        })
        
        local KeyNote = safeCreateInstance("TextLabel", {
            Name = "KeyNote",
            Size = UDim2.new(1, -40, 0, 40),
            Position = UDim2.new(0, 20, 1, -50),
            BackgroundTransparency = 1,
            Text = self.KeySystem.KeySettings.Note,
            TextColor3 = safeGetColor(self.Colors, "TextSecondary"),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            Parent = self.KeySystemUI
        })
        
        self.KeyStatus = safeCreateInstance("TextLabel", {
            Name = "KeyStatus",
            Size = UDim2.new(1, -40, 0, 20),
            Position = UDim2.new(0, 20, 0, 245),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = safeGetColor(self.Colors, "TextSecondary"),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.KeySystemUI
        })
    end)
    
    if not success then
        warn("NexusUI: Key system creation failed: " .. tostring(err))
    end
end

function NexusUI:SetupEventHandlers()
    if self.Destroyed then return end
    
    local function safeConnectEvent(object, event, callback)
        if object and object.Parent then
            pcall(function()
                object[event]:Connect(callback)
            end)
        end
    end
    
    safeConnectEvent(self.KeySubmit, "MouseButton1Click", function()
        self:OnKeySubmit()
    end)
    
    safeConnectEvent(self.KeyInput, "FocusLost", function(enterPressed)
        if enterPressed then
            self:OnKeySubmit()
        end
    end)
    
    safeConnectEvent(self.TopBar, "InputBegan", function(input)
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
    
    safeConnectEvent(self.TopBar, "InputChanged", function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and self.dragging then
            local delta = input.Position - self.dragStart
            self.MainWindow.Position = UDim2.new(
                self.startPos.X.Scale, self.startPos.X.Offset + delta.X,
                self.startPos.Y.Scale, self.startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    safeConnectEvent(self.CloseButton, "MouseButton1Click", function()
        self:HideMainUI()
    end)
    
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
    
    if Players.LocalPlayer then
        Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
            if not parent then
                self:Destroy()
            end
        end)
    end
end

function NexusUI:SafeTween(object, tweenInfo, properties)
    if self.Destroyed then return nil end
    if not object or not object.Parent then return nil end
    if not tweenInfo or type(tweenInfo) ~= "TweenInfo" then return nil end
    if not properties or type(properties) ~= "table" then return nil end
    
    local success, tween = pcall(function()
        local validProperties = {}
        for property, value in pairs(properties) do
            if object[property] ~= nil then
                validProperties[property] = value
            end
        end
        
        if next(validProperties) == nil then
            return nil
        end
        
        local tween = TweenService:Create(object, tweenInfo, validProperties)
        tween:Play()
        return tween
    end)
    
    if success then
        return tween
    else
        warn("NexusUI: Tween creation failed for " .. tostring(object))
        return nil
    end
end

-- Tab Management
function NexusUI:CreateTab(tabConfig)
    if self.Destroyed then return nil end
    
    local isValid, errorMsg = validateConfig(tabConfig, "tab")
    if not isValid then
        warn("NexusUI: " .. errorMsg)
        return nil
    end
    
    local tabName = tabConfig.Name
    
    if not self.NavigationList or not self.NavigationList.Parent then
        warn("NexusUI: NavigationList is not available")
        return nil
    end
    
    if not self.ContentPages or not self.ContentPages.Parent then
        warn("NexusUI: ContentPages is not available")
        return nil
    end
    
    local navButton = self:CreateNavButton(tabConfig)
    local contentPage = self:CreateContentPage(tabConfig)
    
    if not navButton or not contentPage then
        warn("NexusUI: Failed to create tab elements")
        return nil
    end
    
    self.Tabs[tabName] = {
        Button = navButton,
        Page = contentPage,
        Elements = {}
    }
    
    navButton.MouseButton1Click:Connect(function()
        self:SelectTab(tabName)
    end)
    
    if not self.CurrentTab then
        self:SelectTab(tabName)
    end
    
    local tabAPI = {}
    
    function tabAPI.AddButton(buttonConfig)
        if self.Destroyed then return nil end
        local isValid = validateConfig(buttonConfig, "button")
        if not isValid then return nil end
        return self:AddButtonToTab(tabName, buttonConfig)
    end
    
    function tabAPI.AddToggle(toggleConfig)
        if self.Destroyed then return nil end
        local isValid = validateConfig(toggleConfig, "toggle")
        if not isValid then return nil end
        return self:AddToggleToTab(tabName, toggleConfig)
    end
    
    function tabAPI.AddSection(sectionConfig)
        if self.Destroyed then return nil end
        local isValid = validateConfig(sectionConfig, "section")
        if not isValid then return nil end
        return self:AddSectionToTab(tabName, sectionConfig)
    end
    
    function tabAPI.AddLabel(labelConfig)
        if self.Destroyed then return nil end
        local isValid = validateConfig(labelConfig, "label")
        if not isValid then return nil end
        return self:AddLabelToTab(tabName, labelConfig)
    end
    
    return tabAPI
end

function NexusUI:CreateNavButton(navConfig)
    local button = safeCreateInstance("TextButton", {
        Name = navConfig.Name .. "Nav",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight"),
        Text = "",
        Parent = self.NavigationList
    })
    
    if not button then return nil end
    
    safeCreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = button
    })
    
    safeCreateInstance("UIStroke", {
        Color = safeGetColor(self.Colors, "Primary"),
        Thickness = 1,
        Parent = button
    })
    
    local buttonText = safeCreateInstance("TextLabel", {
        Name = "ButtonText",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = navConfig.Name,
        TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = button
    })
    
    button.MouseEnter:Connect(function()
        self:SafeTween(button, TweenInfo.new(0.2), {
            BackgroundColor3 = safeGetColor(self.Colors, "Primary")
        })
    end)
    
    button.MouseLeave:Connect(function()
        self:SafeTween(button, TweenInfo.new(0.2), {
            BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")
        })
    end)
    
    return button
end

function NexusUI:CreateContentPage(pageConfig)
    local page = safeCreateInstance("ScrollingFrame", {
        Name = pageConfig.Name .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = safeGetColor(self.Colors, "SurfaceLight"),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = self.ContentPages
    })
    
    if not page then return nil end
    
    local pageLayout = safeCreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = page
    })
    
    safeCreateInstance("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = page
    })
    
    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 10)
    end)
    
    return page
end

function NexusUI:SelectTab(tabName)
    if not self.Tabs[tabName] then return end
    
    for name, tab in pairs(self.Tabs) do
        tab.Page.Visible = (name == tabName)
        if tab.Button then
            local targetColor = name == tabName and safeGetColor(self.Colors, "Primary") or safeGetColor(self.Colors, "SurfaceLight")
            self:SafeTween(tab.Button, TweenInfo.new(0.2), {
                BackgroundColor3 = targetColor
            })
        end
    end
    
    self.CurrentTab = tabName
end

-- Section Management
function NexusUI:AddSectionToTab(tabName, sectionConfig)
    if self.Destroyed then return nil end
    
    if not self.Tabs[tabName] then 
        warn("NexusUI: Tab not found: " .. tostring(tabName))
        return nil
    end
    
    local isValid, errorMsg = validateConfig(sectionConfig, "section")
    if not isValid then
        warn("NexusUI: " .. errorMsg)
        return nil
    end
    
    local tab = self.Tabs[tabName]
    
    local section = safeCreateInstance("Frame", {
        Name = sectionConfig.Name .. "Section",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = safeGetColor(self.Colors, "Surface"),
        BackgroundTransparency = 0,
        Parent = tab.Page
    })
    
    safeCreateInstance("UICorner", {
        CornerRadius = self.Config.CornerRadius,
        Parent = section
    })
    
    safeCreateInstance("UIStroke", {
        Color = safeGetColor(self.Colors, "SurfaceLight"),
        Thickness = 1,
        Parent = section
    })
    
    safeCreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 15, 0, 12),
        BackgroundTransparency = 1,
        Text = sectionConfig.Name,
        TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    local content = safeCreateInstance("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 15, 0, 40),
        BackgroundTransparency = 1,
        Parent = section
    })
    
    local contentLayout = safeCreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = content
    })
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.Size = UDim2.new(1, -20, 0, contentLayout.AbsoluteContentSize.Y)
        section.Size = UDim2.new(1, 0, 0, 55 + contentLayout.AbsoluteContentSize.Y)
    end)
    
    table.insert(tab.Elements, {
        Type = "Section",
        Object = section,
        Content = content
    })
    
    local sectionAPI = {}
    
    function sectionAPI.AddButton(buttonConfig)
        if self.Destroyed then return nil end
        local isValid = validateConfig(buttonConfig, "button")
        if not isValid then return nil end
        return self:CreateButton(content, buttonConfig)
    end
    
    function sectionAPI.AddToggle(toggleConfig)
        if self.Destroyed then return nil end
        local isValid = validateConfig(toggleConfig, "toggle")
        if not isValid then return nil end
        return self:CreateToggle(content, toggleConfig)
    end
    
    function sectionAPI.AddLabel(labelConfig)
        if self.Destroyed then return nil end
        local isValid = validateConfig(labelConfig, "label")
        if not isValid then return nil end
        return self:CreateLabel(content, labelConfig)
    end
    
    return sectionAPI
end

-- Element Creation
function NexusUI:CreateButton(parent, buttonConfig)
    local button = safeCreateInstance("TextButton", {
        Name = buttonConfig.Name .. "Button",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = safeGetColor(self.Colors, "Primary"),
        Text = "",
        Parent = parent
    })
    
    safeCreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = button
    })
    
    local buttonText = safeCreateInstance("TextLabel", {
        Name = "ButtonText",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = buttonConfig.Name,
        TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = button
    })
    
    button.MouseButton1Click:Connect(function()
        if buttonConfig.Callback then
            pcall(buttonConfig.Callback)
        end
    end)
    
    button.MouseEnter:Connect(function()
        self:SafeTween(button, TweenInfo.new(0.2), {
            BackgroundColor3 = safeGetColor(self.Colors, "PrimaryDark")
        })
    end)
    
    button.MouseLeave:Connect(function()
        self:SafeTween(button, TweenInfo.new(0.2), {
            BackgroundColor3 = safeGetColor(self.Colors, "Primary")
        })
    end)
    
    return button
end

function NexusUI:CreateToggle(parent, toggleConfig)
    local toggleFrame = safeCreateInstance("Frame", {
        Name = toggleConfig.Name .. "Toggle",
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local toggleButton = safeCreateInstance("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -35, 0, 0),
        BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight"),
        Text = "",
        Parent = toggleFrame
    })
    
    safeCreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = toggleButton
    })
    
    local toggleIndicator = safeCreateInstance("Frame", {
        Name = "ToggleIndicator",
        Size = UDim2.new(0, 15, 0, 15),
        Position = UDim2.new(0.5, -7.5, 0.5, -7.5),
        BackgroundColor3 = safeGetColor(self.Colors, "TextPrimary"),
        Parent = toggleButton
    })
    
    safeCreateInstance("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = toggleIndicator
    })
    
    local toggleLabel = safeCreateInstance("TextLabel", {
        Name = "ToggleLabel",
        Size = UDim2.new(1, -45, 1, 0),
        BackgroundTransparency = 1,
        Text = toggleConfig.Name,
        TextColor3 = safeGetColor(self.Colors, "TextPrimary"),
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggleFrame
    })
    
    local state = toggleConfig.Default or false
    toggleIndicator.Visible = state
    
    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        toggleIndicator.Visible = state
        
        if state then
            self:SafeTween(toggleButton, TweenInfo.new(0.2), {
                BackgroundColor3 = safeGetColor(self.Colors, "Primary")
            })
        else
            self:SafeTween(toggleButton, TweenInfo.new(0.2), {
                BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")
            })
        end
        
        if toggleConfig.Callback then
            pcall(toggleConfig.Callback, state)
        end
    end)
    
    return {
        SetState = function(newState)
            state = newState
            toggleIndicator.Visible = state
            if state then
                self:SafeTween(toggleButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = safeGetColor(self.Colors, "Primary")
                })
            else
                self:SafeTween(toggleButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight")
                })
            end
        end,
        GetState = function()
            return state
        end
    }
end

function NexusUI:CreateLabel(parent, labelConfig)
    local label = safeCreateInstance("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = labelConfig.Text,
        TextColor3 = safeGetColor(self.Colors, "TextSecondary"),
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = parent
    })
    
    return label
end

function NexusUI:AddButtonToTab(tabName, buttonConfig)
    if not self.Tabs[tabName] then return nil end
    return self:CreateButton(self.Tabs[tabName].Page, buttonConfig)
end

function NexusUI:AddToggleToTab(tabName, toggleConfig)
    if not self.Tabs[tabName] then return nil end
    return self:CreateToggle(self.Tabs[tabName].Page, toggleConfig)
end

function NexusUI:AddLabelToTab(tabName, labelConfig)
    if not self.Tabs[tabName] then return nil end
    return self:CreateLabel(self.Tabs[tabName].Page, labelConfig)
end

-- Key System Methods
function NexusUI:ShowKeySystem()
    if self.Destroyed then return end
    if not self.KeySystemUI then return end
    
    self.KeySystemUI.Visible = true
    self.ScreenGui.Enabled = true
    
    self:SafeTween(self.KeySystemUI, TweenInfo.new(self.Config.AnimationDuration), {
        BackgroundTransparency = 0
    })
    
    if self.KeySystem.KeySettings.GrabKeyFromSite then
        self:GetKeysFromSite()
    end
end

function NexusUI:HideKeySystem()
    if self.Destroyed then return end
    if not self.KeySystemUI then return end
    
    self:SafeTween(self.KeySystemUI, TweenInfo.new(self.Config.AnimationDuration), {
        BackgroundTransparency = 1
    })
    
    delay(self.Config.AnimationDuration, function()
        if self.KeySystemUI then
            self.KeySystemUI.Visible = false
        end
    end)
end

function NexusUI:OnKeySubmit()
    if self.Destroyed then return end
    
    local inputKey = self.KeyInput.Text
    if not inputKey or inputKey == "" then
        self.KeyStatus.Text = "Пожалуйста, введите ключ"
        self.KeyStatus.TextColor3 = safeGetColor(self.Colors, "Error")
        return
    end
    
    if self:ValidateKey(inputKey) then
        self.KeySystem.CurrentKey = inputKey
        self.KeySystem.KeyValidated = true
        self.KeyStatus.Text = "Ключ верный! Загрузка..."
        self.KeyStatus.TextColor3 = safeGetColor(self.Colors, "Success")
        
        if self.KeySystem.KeySettings.SaveKey then
            self:SaveKeyToFile(inputKey)
        end
        
        delay(1, function()
            self:HideKeySystem()
            self:ShowMainUI()
        end)
    else
        self.KeyStatus.Text = "Неверный ключ"
        self.KeyStatus.TextColor3 = safeGetColor(self.Colors, "Error")
    end
end

-- Main UI Methods
function NexusUI:ShowMainUI()
    if self.Destroyed then return end
    if not self.ScreenGui or not self.MainWindow then return end
    
    pcall(function()
        if Players.LocalPlayer then
            local userId = Players.LocalPlayer.UserId
            self.AvatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
        end
    end)
    
    self.ScreenGui.Enabled = true
    self.MainWindow.Visible = true
    
    self:SafeTween(self.BlurEffect, TweenInfo.new(0.5), {Size = self.Config.BlurAmount})
    self:SafeTween(self.MainWindow, TweenInfo.new(self.Config.AnimationDuration), {
        BackgroundTransparency = 0,
        Size = self.Config.WindowSize
    })
    
    self.Enabled = true
end

function NexusUI:HideMainUI()
    if self.Destroyed then return end
    
    self:SafeTween(self.MainWindow, TweenInfo.new(self.Config.AnimationDuration), {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0)
    })
    
    self:SafeTween(self.BlurEffect, TweenInfo.new(0.3), {Size = 0})
    
    delay(self.Config.AnimationDuration, function()
        if self.MainWindow then
            self.MainWindow.Visible = false
        end
        if self.ScreenGui then
            self.ScreenGui.Enabled = false
        end
        self.Enabled = false
    end)
end

-- Public API
function NexusUI:SetTitle(title)
    if self.Destroyed then return end
    if not title or type(title) ~= "string" then return end
    if not self.TitleLabel then return end
    
    self.TitleLabel.Text = title
end

function NexusUI:SetWindowSize(size)
    if self.Destroyed then return end
    if not size or typeof(size) ~= "UDim2" then return end
    if not self.MainWindow then return end
    
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

function NexusUI:Destroy()
    if self.Destroyed then return end
    
    self.Destroyed = true
    self.Enabled = false
    
    if self.InputConnection then
        pcall(function() self.InputConnection:Disconnect() end)
        self.InputConnection = nil
    end
    
    local function safeDestroy(obj)
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    
    safeDestroy(self.ScreenGui)
    safeDestroy(self.BlurEffect)
    
    self.Elements = nil
    self.Tabs = nil
    self.Colors = nil
    self.Config = nil
    
    setmetatable(self, {
        __index = function()
            error("NexusUI: Instance has been destroyed")
        end,
        __newindex = function()
            error("NexusUI: Instance has been destroyed")
        end
    })
end

return NexusUI
