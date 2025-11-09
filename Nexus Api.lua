-- NexusMenu.lua
-- by Senior Lua Dev (Колин)
-- Дизайн: SKETCH [beta] for Grand Theft Auto V

local MenuAPI = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local guiParent = player:WaitForChild("PlayerGui") or Instance.new("PlayerGui")
guiParent.Name = "PlayerGui"

-- Цвета SKETCH
local COLORS = {
    Background = Color3.fromRGB(15, 15, 15),
    Accent = Color3.fromRGB(255, 50, 50),
    Text = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(30, 30, 30),
    Hover = Color3.fromRGB(25, 25, 25),
    Active = Color3.fromRGB(255, 70, 70),
    SectionBackground = Color3.fromRGB(20, 20, 20),
}

-- Шрифты
local FONT = Enum.Font.SourceSansBold
local FONTSIZE = 14

-- Создание фрейма
local function createFrame(parent, name, size, pos, color, borderSize, cornerRadius)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = pos
    frame.BackgroundColor3 = color or COLORS.Background
    frame.BorderSizePixel = borderSize or 0
    frame.BorderColor3 = COLORS.Border
    frame.Parent = parent

    if cornerRadius then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, cornerRadius)
        corner.Parent = frame
    end

    return frame
end

-- Создание текстовой метки
local function createTextLabel(parent, name, text, size, pos, color, fontSize, font)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Text = text
    label.TextColor3 = color or COLORS.Text
    label.TextSize = fontSize or FONTSIZE
    label.Font = font or FONT
    label.BackgroundTransparency = 1
    label.Position = pos
    label.Size = size
    label.Parent = parent
    return label
end

-- Создание кнопки
local function createButton(parent, name, size, pos, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = pos
    button.BackgroundColor3 = COLORS.Background
    button.BorderColor3 = COLORS.Border
    button.BorderSizePixel = 1
    button.Text = name
    button.TextColor3 = COLORS.Text
    button.TextSize = FONTSIZE
    button.Font = FONT
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button

    local hover = false

    button.MouseEnter:Connect(function()
        hover = true
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLORS.Hover,
            BorderColor3 = COLORS.Accent
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        hover = false
        TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLORS.Background,
            BorderColor3 = COLORS.Border
        }):Play()
    end)

    button.MouseButton1Click:Connect(callback)

    return button
end

-- Создание переключателя
local function createToggle(parent, name, value, flag, callback)
    local toggle = Instance.new("Frame")
    toggle.Name = name
    toggle.Size = UDim2.new(1, 0, 0, 25)
    toggle.BackgroundColor3 = COLORS.Background
    toggle.BorderSizePixel = 1
    toggle.BorderColor3 = COLORS.Border
    toggle.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = toggle

    local nameLabel = createTextLabel(toggle, "NameLabel", name, UDim2.new(0.7, 0, 1, 0), UDim2.new(0, 5, 0, 0), COLORS.Text, FONTSIZE, FONT)

    local switch = Instance.new("Frame")
    switch.Name = "Switch"
    switch.Size = UDim2.new(0, 40, 0, 20)
    switch.Position = UDim2.new(1, -45, 0, 2.5)
    switch.BackgroundColor3 = value and COLORS.Accent or Color3.fromRGB(60, 60, 60)
    switch.BorderSizePixel = 1
    switch.BorderColor3 = COLORS.Border
    switch.Parent = toggle

    local cornerSwitch = Instance.new("UICorner")
    cornerSwitch.CornerRadius = UDim.new(0, 10)
    cornerSwitch.Parent = switch

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 16, 0, 16)
    indicator.Position = UDim2.new(value and 0.5 or 0, 2, 0, 2)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BorderSizePixel = 0
    indicator.Parent = switch

    local cornerIndicator = Instance.new("UICorner")
    cornerIndicator.CornerRadius = UDim.new(0, 8)
    cornerIndicator.Parent = indicator

    local function updateToggle(newValue)
        value = newValue
        switch.BackgroundColor3 = value and COLORS.Accent or Color3.fromRGB(60, 60, 60)
        indicator.Position = UDim2.new(value and 0.5 or 0, 2, 0, 2)
        callback(value)
    end

    switch.MouseButton1Click:Connect(function()
        updateToggle(not value)
    end)

    return {
        Set = function(newValue)
            updateToggle(newValue)
        end,
        Get = function()
            return value
        end,
        Flag = flag,
    }
end

-- Создание слайдера
local function createSlider(parent, name, min, max, default, flag, callback)
    local slider = Instance.new("Frame")
    slider.Name = name
    slider.Size = UDim2.new(1, 0, 0, 30)
    slider.BackgroundColor3 = COLORS.Background
    slider.BorderSizePixel = 1
    slider.BorderColor3 = COLORS.Border
    slider.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = slider

    local nameLabel = createTextLabel(slider, "NameLabel", name, UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 5, 0, 0), COLORS.Text, FONTSIZE, FONT)

    local valueLabel = createTextLabel(slider, "ValueLabel", tostring(default), UDim2.new(0.1, 0, 1, 0), UDim2.new(0.9, -40, 0, 0), COLORS.Text, FONTSIZE, FONT)

    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(0.7, 0, 0, 10)
    bar.Position = UDim2.new(0.1, 0, 0.5, -5)
    bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bar.BorderSizePixel = 0
    bar.Parent = slider

    local cornerBar = Instance.new("UICorner")
    cornerBar.CornerRadius = UDim.new(0, 5)
    cornerBar.Parent = bar

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local cornerFill = Instance.new("UICorner")
    cornerFill.CornerRadius = UDim.new(0, 5)
    cornerFill.Parent = fill

    local handle = Instance.new("Frame")
    handle.Name = "Handle"
    handle.Size = UDim2.new(0, 10, 0, 10)
    handle.BackgroundColor3 = COLORS.Text
    handle.BorderSizePixel = 1
    handle.BorderColor3 = COLORS.Border
    handle.Parent = bar

    local cornerHandle = Instance.new("UICorner")
    cornerHandle.CornerRadius = UDim.new(0, 5)
    cornerHandle.Parent = handle

    local currentValue = default

    local function updateValue(newValue)
        currentValue = math.clamp(newValue, min, max)
        local percent = (currentValue - min) / (max - min)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        handle.Position = UDim2.new(percent - 0.05, 0, 0, 0)
        valueLabel.Text = tostring(math.floor(currentValue))
        callback(currentValue)
    end

    updateValue(default)

    local dragging = false
    handle.MouseButton1Down:Connect(function()
        dragging = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local x = input.Position.X - bar.AbsolutePosition.X
            local percent = math.clamp(x / bar.AbsoluteSize.X, 0, 1)
            updateValue(min + percent * (max - min))
        end
    end)

    return {
        Set = function(newValue)
            updateValue(newValue)
        end,
        Get = function()
            return currentValue
        end,
        Flag = flag,
    }
end

-- Создание привязки клавиши
local function createKeyBind(parent, name, defaultKey, flag, callback)
    local keybind = Instance.new("Frame")
    keybind.Name = name
    keybind.Size = UDim2.new(1, 0, 0, 25)
    keybind.BackgroundColor3 = COLORS.Background
    keybind.BorderSizePixel = 1
    keybind.BorderColor3 = COLORS.Border
    keybind.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = keybind

    local nameLabel = createTextLabel(keybind, "NameLabel", name, UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 5, 0, 0), COLORS.Text, FONTSIZE, FONT)

    local keyLabel = createTextLabel(keybind, "KeyLabel", defaultKey.Name, UDim2.new(0.1, 0, 1, 0), UDim2.new(0.9, -40, 0, 0), COLORS.Text, FONTSIZE, FONT)

    local currentKey = defaultKey
    local waitingForKey = false

    local function updateKey(newKey)
        currentKey = newKey
        keyLabel.Text = newKey.Name
        callback(newKey)
    end

    keybind.MouseButton1Click:Connect(function()
        if not waitingForKey then
            waitingForKey = true
            keyLabel.Text = "Press Key..."
            keyLabel.TextColor3 = COLORS.Accent
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if waitingForKey and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                updateKey(input.KeyCode)
                waitingForKey = false
                keyLabel.TextColor3 = COLORS.Text
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                updateKey(Enum.KeyCode.MouseButton1)
                waitingForKey = false
                keyLabel.TextColor3 = COLORS.Text
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                updateKey(Enum.KeyCode.MouseButton2)
                waitingForKey = false
                keyLabel.TextColor3 = COLORS.Text
            end
        end
    end)

    return {
        Set = function(newKey)
            updateKey(newKey)
        end,
        Get = function()
            return currentKey
        end,
        Flag = flag,
    }
end

-- Создание поля ввода
local function createInputValue(parent, name, defaultValue, flag, callback)
    local input = Instance.new("Frame")
    input.Name = name
    input.Size = UDim2.new(1, 0, 0, 25)
    input.BackgroundColor3 = COLORS.Background
    input.BorderSizePixel = 1
    input.BorderColor3 = COLORS.Border
    input.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = input

    local nameLabel = createTextLabel(input, "NameLabel", name, UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 5, 0, 0), COLORS.Text, FONTSIZE, FONT)

    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.Size = UDim2.new(0.4, 0, 1, 0)
    textBox.Position = UDim2.new(0.6, 0, 0, 0)
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    textBox.TextColor3 = COLORS.Text
    textBox.PlaceholderText = "Enter value"
    textBox.Text = tostring(defaultValue)
    textBox.ClearTextOnFocus = false
    textBox.Parent = input

    local cornerBox = Instance.new("UICorner")
    cornerBox.CornerRadius = UDim.new(0, 5)
    cornerBox.Parent = textBox

    local currentValue = defaultValue

    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newValue = tonumber(textBox.Text) or currentValue
            currentValue = newValue
            textBox.Text = tostring(newValue)
            callback(newValue)
        else
            textBox.Text = tostring(currentValue)
        end
    end)

    return {
        Set = function(newValue)
            currentValue = newValue
            textBox.Text = tostring(newValue)
            callback(newValue)
        end,
        Get = function()
            return currentValue
        end,
        Flag = flag,
    }
end

-- Создание текста
local function createText(parent, text)
    local textObj = createTextLabel(parent, "Text", text, UDim2.new(1, 0, 0, 20), UDim2.new(0, 5, 0, 0), COLORS.Text, FONTSIZE, FONT)
    textObj.TextXAlignment = Enum.TextXAlignment.Left
    return textObj
end

-- Основной класс меню
local Window = {}
Window.__index = Window

function Window.new(name, beta, gameName, toggleKey)
    local self = setmetatable({}, Window)

    self.Name = name
    self.Beta = beta or false
    self.Game = gameName or ""
    self.ToggleKey = toggleKey or Enum.KeyCode.Insert
    self.Tabs = {}
    self.IsOpen = false

    -- Создаем GUI
    self.Gui = Instance.new("ScreenGui")
    self.Gui.Name = "Menu_" .. name
    self.Gui.Parent = guiParent

    self.MainFrame = createFrame(self.Gui, "MainFrame", UDim2.new(0, 500, 0, 400), UDim2.new(0.5, -250, 0.5, -200), COLORS.Background, 1, 10)
    self.MainFrame.Visible = false

    -- Заголовок
    self.TitleBar = createFrame(self.MainFrame, "TitleBar", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), COLORS.Accent, 0, 10)
    local titleText = createTextLabel(self.TitleBar, "TitleText", self.Name .. (self.Beta and " [Beta]" or "") .. (self.Game ~= "" and " for " .. self.Game or ""), UDim2.new(1, 0, 1, 0), UDim2.new(0, 10, 0, 0), Color3.fromRGB(0, 0, 0), 16, FONT)

    -- Кнопка закрытия
    local closeBtn = createButton(self.TitleBar, "Close", UDim2.new(0, 20, 0, 20), UDim2.new(1, -30, 0, 5), function()
        self:IsVisible(false)
    end)
    closeBtn.Text = "X"
    closeBtn.TextSize = 14

    -- Левая панель вкладок
    self.TabPanel = createFrame(self.MainFrame, "TabPanel", UDim2.new(0, 120, 1, -30), UDim2.new(0, 0, 0, 30), Color3.fromRGB(25, 25, 25), 1, 5)

    -- Правая панель контента
    self.ContentPanel = createFrame(self.MainFrame, "ContentPanel", UDim2.new(1, -130, 1, -30), UDim2.new(0, 130, 0, 30), Color3.fromRGB(20, 20, 20), 1, 5)

    -- Обработчик нажатия клавиши
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == self.ToggleKey and not gameProcessed then
            self:IsVisible(not self.IsOpen)
        end
    end)

    return self
end

function Window:IsVisible(visible)
    self.IsOpen = visible
    self.MainFrame.Visible = visible
end

function Window:CreateTab(name)
    local tab = {
        Name = name,
        Sections = {},
        Index = #self.Tabs + 1,
    }

    -- Создаем кнопку вкладки
    local tabButton = createButton(self.TabPanel, name, UDim2.new(1, -2, 0, 30), UDim2.new(0, 1, 0, 30 * (#self.Tabs)), function()
        self:ShowTab(tab)
    end)
    tabButton.Text = name

    table.insert(self.Tabs, tab)

    -- Создаем контейнер для секций
    local sectionContainer = createFrame(self.ContentPanel, "SectionContainer_" .. name, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(20, 20, 20), 0, 5)
    sectionContainer.Visible = false

    tab.SectionContainer = sectionContainer

    if #self.Tabs == 1 then
        self:ShowTab(tab)
    end

    return {
        CreateSection = function(sectionName)
            if #tab.Sections >= 4 then
                warn("Maximum 4 sections per tab!")
                return nil
            end

            -- Убедимся, что sectionName — строка
            if type(sectionName) ~= "string" then
                sectionName = tostring(sectionName) or "Unnamed Section"
            end

            local section = {
                Name = sectionName,
                Elements = {},
                Index = #tab.Sections + 1,
            }

            local sectionFrame = createFrame(sectionContainer, "Section_" .. sectionName, UDim2.new(1, -10, 0, 80), UDim2.new(0, 5, 0, 5 + 85 * (#tab.Sections)), COLORS.SectionBackground, 1, 5)

            local sectionTitle = createTextLabel(sectionFrame, "SectionTitle", sectionName, UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, 0), COLORS.Text, 14, FONT)
            sectionTitle.TextXAlignment = Enum.TextXAlignment.Left

            -- Размещаем элементы внутри секции
            local elementY = 25
            local elementSpacing = 5

            section.AddElement = function(elementFrame)
                elementFrame.Position = UDim2.new(0, 5, 0, elementY)
                elementY = elementY + elementFrame.Size.Y.Offset + elementSpacing
                sectionFrame.Size = UDim2.new(1, -10, 0, elementY - elementSpacing + 5)
            end

            section.CreateButton = function(data)
                local btn = createButton(sectionFrame, data.Name, UDim2.new(1, -10, 0, 25), UDim2.new(0, 5, 0, elementY), data.Callback)
                section.AddElement(btn)
                table.insert(section.Elements, { Type = "Button", Object = btn })
                return btn
            end

            section.CreateToggle = function(data)
                local tog = createToggle(sectionFrame, data.Name, data.CurrentValue, data.Flag, data.Callback)
                section.AddElement(tog)
                table.insert(section.Elements, { Type = "Toggle", Object = tog })
                return tog
            end

            section.CreateSlider = function(data)
                local sld = createSlider(sectionFrame, data.Name, data.Min, data.Max, data.Default, data.Flag, data.Callback)
                section.AddElement(sld)
                table.insert(section.Elements, { Type = "Slider", Object = sld })
                return sld
            end

            section.CreateInputValue = function(data)
                local inp = createInputValue(sectionFrame, data.Name, data.DefaultValue, data.Flag, data.Callback)
                section.AddElement(inp)
                table.insert(section.Elements, { Type = "InputValue", Object = inp })
                return inp
            end

            section.CreateKeyBind = function(data)
                local kb = createKeyBind(sectionFrame, data.Name, data.Default, data.Flag, data.Callback)
                section.AddElement(kb)
                table.insert(section.Elements, { Type = "KeyBind", Object = kb })
                return kb
            end

            section.CreateText = function(data)
                local txt = createText(sectionFrame, data.Text)
                section.AddElement(txt)
                table.insert(section.Elements, { Type = "Text", Object = txt })
                return txt
            end

            table.insert(tab.Sections, section)

            return section
        end
    }
end

function Window:ShowTab(tab)
    for _, t in ipairs(self.Tabs) do
        t.SectionContainer.Visible = false
    end
    tab.SectionContainer.Visible = true
end

-- Функция создания окна
function MenuAPI.CreateWindow(config)
    local window = Window.new(config.Name, config.Beta, config.Game, config.ToggleKey)
    return window
end

return MenuAPI
