local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

local library = {}
library.windows = {}
library.currentWindow = nil

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ImGuiStyleGUI"
ScreenGui.Parent = PlayerGui

-- === Создание окна ===
function library:CreateWindow(name)
    local WindowData = {}
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = name
    MainFrame.Size = UDim2.new(0, 500, 0, 300)
    MainFrame.Position = UDim2.new(0, 100, 0, 100)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = name
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextScaled = true
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.Parent = TopBar
    
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "Content"
    ContentFrame.Size = UDim2.new(1, 0, 1, -30)
    ContentFrame.Position = UDim2.new(0, 0, 0, 30)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 5
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.Parent = MainFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = ContentFrame
    
    MainFrame.Parent = ScreenGui
    WindowData.Frame = MainFrame
    WindowData.ContentFrame = ContentFrame
    WindowData.UIListLayout = UIListLayout
    library.windows[name] = WindowData
    library.currentWindow = WindowData
    
    return WindowData
end

-- === Создание вкладки ===
function library:CreateTab(tabName)
    local TabData = {}
    
    local TabButton = Instance.new("TextButton")
    TabButton.Name = tabName
    TabButton.Size = UDim2.new(0, 100, 0, 30)
    TabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TabButton.Text = tabName
    TabButton.TextColor3 = Color3.fromRGB(200, 200, 220)
    TabButton.Font = Enum.Font.SourceSans
    TabButton.TextScaled = true
    TabButton.BorderSizePixel = 0
    
    local TabContent = Instance.new("Frame")
    TabContent.Name = tabName .. "Content"
    TabContent.Size = UDim2.new(1, -10, 1, -40)
    TabContent.Position = UDim2.new(0, 5, 0, 35)
    TabContent.BackgroundTransparency = 1
    TabContent.Visible = false
    TabContent.Parent = library.currentWindow.ContentFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = TabContent
    
    TabButton.Parent = library.currentWindow.ContentFrame
    TabData.Button = TabButton
    TabData.Frame = TabContent
    TabData.UIListLayout = UIListLayout
    
    -- Переключение вкладки
    TabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(library.currentWindow.ContentFrame:GetChildren()) do
            if tab:IsA("Frame") and tab.Name:find("Content") then
                tab.Visible = false
            end
        end
        TabContent.Visible = true
    end)
    
    return TabData
end

-- === Создание слайдера ===
function library:CreateSlider(tab, name, min, max, default, callback)
    local SliderData = {}
    local currentValue = default
    
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = name .. "Slider"
    SliderFrame.Size = UDim2.new(1, -20, 0, 40)
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = tab.Frame
    
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Name = "Label"
    SliderLabel.Size = UDim2.new(0, 100, 0, 20)
    SliderLabel.Position = UDim2.new(0, 0, 0, 0)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = name
    SliderLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    SliderLabel.TextScaled = true
    SliderLabel.Font = Enum.Font.SourceSans
    SliderLabel.Parent = SliderFrame
    
    local SliderValueLabel = Instance.new("TextLabel")
    SliderValueLabel.Name = "ValueLabel"
    SliderValueLabel.Size = UDim2.new(0, 50, 0, 20)
    SliderValueLabel.Position = UDim2.new(1, -50, 0, 0)
    SliderValueLabel.BackgroundTransparency = 1
    SliderValueLabel.Text = tostring(currentValue)
    SliderValueLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    SliderValueLabel.TextScaled = true
    SliderValueLabel.Font = Enum.Font.SourceSans
    SliderValueLabel.Parent = SliderFrame
    
    local SliderBar = Instance.new("Frame")
    SliderBar.Name = "SliderBar"
    SliderBar.Size = UDim2.new(1, -160, 0, 10)
    SliderBar.Position = UDim2.new(0, 100, 0, 25)
    SliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    SliderBar.BorderSizePixel = 0
    SliderBar.Parent = SliderFrame
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Name = "SliderFill"
    SliderFill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBar
    
    local SliderButton = Instance.new("TextButton")
    SliderButton.Name = "SliderButton"
    SliderButton.Size = UDim2.new(0, 10, 1, 2)
    SliderButton.Position = UDim2.new((currentValue - min) / (max - min), -5, 0, -1)
    SliderButton.BackgroundColor3 = Color3.fromRGB(200, 200, 220)
    SliderButton.BorderSizePixel = 0
    SliderButton.Text = ""
    SliderButton.Parent = SliderBar
    
    -- Обновление слайдера
    local function updateSlider(mouseX)
        local relativeX = math.clamp(mouseX - SliderBar.AbsolutePosition.X, 0, SliderBar.AbsoluteSize.X)
        local percent = relativeX / SliderBar.AbsoluteSize.X
        local value = math.floor(min + (max - min) * percent)
        currentValue = value
        
        SliderValueLabel.Text = tostring(value)
        SliderFill.Size = UDim2.new(percent, 0, 1, 0)
        SliderButton.Position = UDim2.new(percent, -5, 0, -1)
        
        if callback then
            callback(value)
        end
    end
    
    -- Обработка мыши
    SliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input.Position.X)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    SliderData.Frame = SliderFrame
    SliderData.Value = currentValue
    return SliderData
end

-- === Создание переключателя ===
function library:CreateToggle(tab, name, default, callback)
    local ToggleData = {}
    local state = default or false
    
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Name = name .. "Toggle"
    ToggleFrame.Size = UDim2.new(1, -20, 0, 30)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = tab.Frame
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 50, 0, 20)
    ToggleButton.Position = UDim2.new(1, -50, 0, 5)
    ToggleButton.BackgroundColor3 = state and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
    ToggleButton.Text = state and "ON" or "OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextScaled = true
    ToggleButton.Font = Enum.Font.SourceSans
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = ToggleFrame
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Name = "Label"
    ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 0, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = name
    ToggleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    ToggleLabel.TextScaled = true
    ToggleLabel.Font = Enum.Font.SourceSans
    ToggleLabel.Parent = ToggleFrame
    
    ToggleButton.MouseButton1Click:Connect(function()
        state = not state
        ToggleButton.BackgroundColor3 = state and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(100, 100, 100)
        ToggleButton.Text = state and "ON" or "OFF"
        if callback then
            callback(state)
        end
    end)
    
    ToggleData.Frame = ToggleFrame
    ToggleData.State = state
    return ToggleData
end

-- === Создание кнопки ===
function library:CreateButton(tab, name, callback)
    local ButtonData = {}
    
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Button"
    Button.Size = UDim2.new(1, -20, 0, 30)
    Button.Position = UDim2.new(0, 10, 0, 0)
    Button.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(220, 220, 220)
    Button.TextScaled = true
    Button.Font = Enum.Font.SourceSans
    Button.BorderSizePixel = 0
    Button.Parent = tab.Frame
    
    Button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)
    
    ButtonData.Button = Button
    return ButtonData
end

-- === Создание поля ввода ===
function library:CreateInput(tab, name, placeholder, callback)
    local InputData = {}
    
    local InputFrame = Instance.new("Frame")
    InputFrame.Name = name .. "Input"
    InputFrame.Size = UDim2.new(1, -20, 0, 30)
    InputFrame.BackgroundTransparency = 1
    InputFrame.BorderSizePixel = 0
    InputFrame.Parent = tab.Frame
    
    local InputBox = Instance.new("TextBox")
    InputBox.Name = "InputBox"
    InputBox.Size = UDim2.new(1, -110, 0, 25)
    InputBox.Position = UDim2.new(0, 100, 0, 2.5)
    InputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    InputBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    InputBox.PlaceholderText = placeholder
    InputBox.TextScaled = true
    InputBox.Font = Enum.Font.SourceSans
    InputBox.BorderSizePixel = 0
    InputBox.Parent = InputFrame
    
    local InputLabel = Instance.new("TextLabel")
    InputLabel.Name = "Label"
    InputLabel.Size = UDim2.new(0, 90, 1, 0)
    InputLabel.Position = UDim2.new(0, 0, 0, 0)
    InputLabel.BackgroundTransparency = 1
    InputLabel.Text = name
    InputLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    InputLabel.TextScaled = true
    InputLabel.Font = Enum.Font.SourceSans
    InputLabel.Parent = InputFrame
    
    InputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and callback then
            callback(InputBox.Text)
        end
    end)
    
    InputData.Frame = InputFrame
    InputData.TextBox = InputBox
    return InputData
end

return library