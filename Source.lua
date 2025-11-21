-- NexusUI Library v2.0 (Ultra Stable)
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

-- Default configurations with fallback values
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

-- Enhanced deep merge function with type checking
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

-- Ultra-safe property access with comprehensive fallbacks
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

-- Advanced validation system
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

-- Safe string to KeyCode conversion
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

-- Safe instance creation with error handling
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

-- Main constructor with comprehensive validation
function NexusUI.new(config)
    -- Validate input
    if config and type(config) ~= "table" then
        warn("NexusUI: Config must be a table or nil")
        config = {}
    end
    
    config = config or {}
    
    -- Safe key conversion
    local toggleKey = stringToKeyCode(config.ToggleKey)
    
    -- Safe config processing
    local keySystemConfig = config.KeySystem or {Enabled = false}
    local keySettings = keySystemConfig.KeySettings or {}
    
    -- Deep merge with validation
    local mergedColors = deepMerge(NexusUI.DefaultColors, config.Colors or {})
    
    -- Create instance with all safety measures
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
    
    -- Initialize with error handling
    local success, err = pcall(function()
        self:Initialize()
    end)
    
    if not success then
        warn("NexusUI: Initialization failed: " .. tostring(err))
        -- Return minimal functional instance
        self.Destroyed = true
    else
        self.Initialized = true
    end
    
    return self
end

-- Safe initialization
function NexusUI:Initialize()
    if self.Destroyed then 
        warn("NexusUI: Cannot initialize destroyed instance")
        return 
    end
    
    -- Create UI components with error handling
    local success, err = pcall(function()
        self:CreateBlurEffect()
        self:CreateMainUI()
        self:SetupEventHandlers()
        
        if self.KeySystem.Enabled and not self.KeySystem.KeyValidated then
            self:ShowKeySystem()
        else
            self:ShowMainUI()
        end
    end)
    
    if not success then
        warn("NexusUI: UI creation failed: " .. tostring(err))
        self.Destroyed = true
    end
end

-- Safe file operations
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
        end
    end
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

-- Safe HTTP requests
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
        end
    end
end

-- Key validation with comprehensive checks
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

-- UI Creation with comprehensive error handling
function NexusUI:CreateBlurEffect()
    if self.Destroyed then return end
    
    pcall(function()
        -- Clean up existing effect
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
    if not self.Colors then 
        warn("NexusUI: Colors table is missing")
        return 
    end
    
    local success, err = pcall(function()
        -- Safe cleanup
        pcall(function()
            local oldUI = CoreGui:FindFirstChild("NexusUIModern")
            if oldUI then
                oldUI:Destroy()
            end
        end)
        
        -- Create main ScreenGui
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
        
        -- Create main window
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
        
        -- Add window styling
        safeCreateInstance("UICorner", {
            CornerRadius = self.Config.CornerRadius,
            Parent = self.MainWindow
        })
        
        safeCreateInstance("UIStroke", {
            Color = safeGetColor(self.Colors, "SurfaceLight"),
            Thickness = 1,
            Parent = self.MainWindow
        })
        
        -- Create top bar
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

        -- Main content area
        self.MainContent = safeCreateInstance("Frame", {
            Name = "MainContent",
            Size = UDim2.new(1, 0, 1, -40),
            Position = UDim2.new(0, 0, 0, 40),
            BackgroundTransparency = 1,
            Parent = self.MainWindow
        })

        -- Sidebar
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

        -- Navigation
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

        -- Profile section
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
        
        -- Content pages
        self.ContentPages = safeCreateInstance("Frame", {
            Name = "ContentPages",
            Size = UDim2.new(1, -200, 1, 0),
            Position = UDim2.new(0, 200, 0, 0),
            BackgroundTransparency = 1,
            Parent = self.MainContent
        })

        -- Key system UI
        self:CreateKeySystem()
        
        -- Drag system
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

-- Key system UI creation
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
        
        -- Key system components...
        safeCreateInstance("TextLabel", {
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
        
        -- ... (other key system elements)
    end)
    
    if not success then
        warn("NexusUI: Key system creation failed: " .. tostring(err))
    end
end

-- Event handling with comprehensive safety
function NexusUI:SetupEventHandlers()
    if self.Destroyed then return end
    
    -- Safe event connections
    local function safeConnectEvent(object, event, callback)
        if object and object.Parent then
            pcall(function()
                object[event]:Connect(callback)
            end)
        end
    end
    
    -- Key system events
    safeConnectEvent(self.KeySubmit, "MouseButton1Click", function()
        self:OnKeySubmit()
    end)
    
    -- Drag events
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
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self.dragInput = input
        end
    end)
    
    -- Close button
    safeConnectEvent(self.CloseButton, "MouseButton1Click", function()
        self:HideMainUI()
    end)
    
    -- Input handling
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
    
    -- Player cleanup
    if Players.LocalPlayer then
        Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
            if not parent then
                self:Destroy()
            end
        end)
    end
end

-- Ultra-safe tweening system
function NexusUI:SafeTween(object, tweenInfo, properties)
    if self.Destroyed then return nil end
    if not object or not object.Parent then return nil end
    if not tweenInfo or type(tweenInfo) ~= "TweenInfo" then return nil end
    if not properties or type(properties) ~= "table" then return nil end
    
    local success, tween = pcall(function()
        -- Validate properties
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

-- Tab management with maximum safety
function NexusUI:CreateTab(tabConfig)
    if self.Destroyed then 
        warn("NexusUI: Cannot create tab on destroyed instance")
        return nil 
    end
    
    local isValid, errorMsg = validateConfig(tabConfig, "tab")
    if not isValid then
        warn("NexusUI: " .. errorMsg)
        return nil
    end
    
    local tabName = tabConfig.Name
    
    -- Validate UI structure
    if not self.NavigationList or not self.NavigationList.Parent then
        warn("NexusUI: NavigationList is not available")
        return nil
    end
    
    if not self.ContentPages or not self.ContentPages.Parent then
        warn("NexusUI: ContentPages is not available")
        return nil
    end
    
    -- Create tab elements
    local navButton = self:CreateNavButton(tabConfig)
    local contentPage = self:CreateContentPage(tabConfig)
    
    if not navButton or not contentPage then
        warn("NexusUI: Failed to create tab elements")
        return nil
    end
    
    -- Store tab data
    self.Tabs[tabName] = {
        Button = navButton,
        Page = contentPage,
        Elements = {}
    }
    
    -- Set up tab selection
    safeConnectEvent(navButton, "MouseButton1Click", function()
        self:SelectTab(tabName)
    end)
    
    -- Auto-select first tab
    if not self.CurrentTab then
        self.CurrentTab = tabName
    end
    
    -- Create tab API
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

-- Safe section creation (the previously problematic function)
function NexusUI:AddSectionToTab(tabName, sectionConfig)
    if self.Destroyed then return nil end
    
    -- Validate inputs
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
    
    -- Create section container
    local section = self:CreateRoundedFrame(tab.Page, UDim2.new(1, 0, 0, 50), nil, safeGetColor(self.Colors, "Surface"))
    if not section then
        warn("NexusUI: Failed to create section frame")
        return nil
    end
    
    section.BackgroundTransparency = 0
    
    -- Section title
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
    
    -- Section content area
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
    
    -- Dynamic sizing
    safeConnectEvent(contentLayout, "AbsoluteContentSize", function()
        if content and content.Parent then
            content.Size = UDim2.new(1, -20, 0, contentLayout.AbsoluteContentSize.Y)
            section.Size = UDim2.new(1, 0, 0, 55 + contentLayout.AbsoluteContentSize.Y)
        end
    end)
    
    -- Store section
    table.insert(tab.Elements, {
        Type = "Section",
        Object = section,
        Content = content
    })
    
    -- Section API
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

-- Safe UI element creation functions
function NexusUI:CreateNavButton(navConfig)
    if not navConfig or not navConfig.Name then return nil end
    
    local button = safeCreateInstance("TextButton", {
        Name = navConfig.Name .. "Nav",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = safeGetColor(self.Colors, "SurfaceLight"),
        Text = "",
        Parent = self.NavigationList
    })
    
    if not button then return nil end
    
    -- Add button styling and functionality...
    return button
end

function NexusUI:CreateContentPage(pageConfig)
    if not pageConfig or not pageConfig.Name then return nil end
    
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
    
    -- Add page layout...
    return page
end

-- Safe rounded frame creation
function NexusUI:CreateRoundedFrame(parent, size, position, backgroundColor)
    if not parent then return nil end
    
    local frame = safeCreateInstance("Frame", {
        Size = size or UDim2.new(1, 0, 1, 0),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = backgroundColor or safeGetColor(self.Colors, "Surface"),
        Parent = parent
    })
    
    if frame then
        safeCreateInstance("UICorner", {
            CornerRadius = self.Config.CornerRadius,
            Parent = frame
        })
    end
    
    return frame
end

-- Public API methods with safety
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

-- Enhanced destruction with comprehensive cleanup
function NexusUI:Destroy()
    if self.Destroyed then return end
    
    self.Destroyed = true
    self.Enabled = false
    
    -- Disconnect events
    if self.InputConnection then
        pcall(function() self.InputConnection:Disconnect() end)
        self.InputConnection = nil
    end
    
    -- Clean up UI elements
    local function safeDestroy(obj)
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    
    safeDestroy(self.ScreenGui)
    safeDestroy(self.BlurEffect)
    
    -- Clear tables
    self.Elements = nil
    self.Tabs = nil
    self.Colors = nil
    self.Config = nil
    
    -- Prevent any further use
    setmetatable(self, {
        __index = function()
            error("NexusUI: Instance has been destroyed")
        end,
        __newindex = function()
            error("NexusUI: Instance has been destroyed")
        end
    })
end

-- Show/hide methods with safety
function NexusUI:ShowMainUI()
    if self.Destroyed then return end
    if not self.ScreenGui or not self.MainWindow then return end
    
    -- Safe avatar loading
    pcall(function()
        if Players.LocalPlayer then
            local userId = Players.LocalPlayer.UserId
            self.AvatarImage.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
        end
    end)
    
    self.ScreenGui.Enabled = true
    self.MainWindow.Visible = true
    
    -- Safe animations
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

-- Key system methods
function NexusUI:ShowKeySystem()
    if self.Destroyed then return end
    -- Implementation...
end

function NexusUI:HideKeySystem()
    if self.Destroyed then return end
    -- Implementation...
end

function NexusUI:OnKeySubmit()
    if self.Destroyed then return end
    -- Implementation...
end

-- Selection methods
function NexusUI:SelectTab(tabName)
    if self.Destroyed then return end
    if not self.Tabs[tabName] then return end
    -- Implementation...
end

-- Element creation methods (buttons, toggles, labels)
function NexusUI:CreateButton(parent, buttonConfig)
    if self.Destroyed then return nil end
    -- Implementation with safety...
    return nil -- placeholder
end

function NexusUI:CreateToggle(parent, toggleConfig)
    if self.Destroyed then return nil end
    -- Implementation with safety...
    return nil -- placeholder
end

function NexusUI:CreateLabel(parent, labelConfig)
    if self.Destroyed then return nil end
    -- Implementation with safety...
    return nil -- placeholder
end

function NexusUI:AddButtonToTab(tabName, buttonConfig)
    if self.Destroyed then return nil end
    -- Implementation...
    return nil -- placeholder
end

function NexusUI:AddToggleToTab(tabName, toggleConfig)
    if self.Destroyed then return nil end
    -- Implementation...
    return nil -- placeholder
end

function NexusUI:AddLabelToTab(tabName, labelConfig)
    if self.Destroyed then return nil end
    -- Implementation...
    return nil -- placeholder
end

-- Input handling
function NexusUI:UpdateInput(input)
    if self.Destroyed then return end
    if not self.MainWindow or not self.dragging then return end
    -- Implementation...
end

return NexusUI
