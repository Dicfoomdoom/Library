local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Animation presets
local Animate = {
	EaseDirection = {
		In = Enum.EasingDirection.In,
		Out = Enum.EasingDirection.Out,
		InOut = Enum.EasingDirection.InOut
	},
	EaseStyle = {
		Linear = Enum.EasingStyle.Linear,
		Elastic = Enum.EasingStyle.Elastic,
		Bounce = Enum.EasingStyle.Bounce,
		Sine = Enum.EasingStyle.Sine,
		Quad = Enum.EasingStyle.Quad,
		Quart = Enum.EasingStyle.Quart,
		Quint = Enum.EasingStyle.Quint
	}
}

-- Utility function to create TweenInfo
local function createTweenInfo(duration, easingStyle, easingDirection, repeatCount, reversing, delay)
	return TweenInfo.new(
		duration or 0.3,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out,
		repeatCount or 0,
		reversing or false,
		delay or 0
	)
end

-- Utility function for smooth animations
local function tween(instance, properties, tweenInfo)
	local tween = TweenService:Create(instance, tweenInfo or createTweenInfo(0.3), properties)
	tween:Play()
	return tween
end

-- Create rounded corner
local function createCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
end

-- Create padding
local function createPadding(instance, padding)
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingLeft = UDim.new(0, padding or 10)
	uiPadding.PaddingRight = UDim.new(0, padding or 10)
	uiPadding.PaddingTop = UDim.new(0, padding or 10)
	uiPadding.PaddingBottom = UDim.new(0, padding or 10)
	uiPadding.Parent = instance
	return uiPadding
end

-- Create stroke
local function createStroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(100, 100, 100)
	stroke.Thickness = thickness or 1
	stroke.Parent = instance
	return stroke
end

-- Library object
local Library = {}

-- Window metatable
local Window = {}
Window.__index = Window

-- Tab metatable
local Tab = {}
Tab.__index = Tab

-- Group metatable
local Group = {}
Group.__index = Group

-- Create Window
function Library:CreateWindow(name, theme)
	theme = theme or {
		Background = Color3.fromRGB(20, 20, 25),
		Foreground = Color3.fromRGB(28, 28, 33),
		Accent = Color3.fromRGB(85, 140, 255),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(180, 180, 180),
		Border = Color3.fromRGB(40, 40, 45),
		SectionBackground = Color3.fromRGB(25, 25, 30)
	}
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name or "UI Library"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 500, 0, 400)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = theme.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	createCorner(mainFrame, 10)
	createStroke(mainFrame, theme.Border or theme.Accent, 1.5)
	
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.BackgroundColor3 = theme.Foreground
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = titleBar
	
	-- Round only top corners
	local topOnlyCorner = Instance.new("UICorner")
	topOnlyCorner.CornerRadius = UDim.new(0, 10)
	topOnlyCorner.Parent = titleBar
	
	local titleText = Instance.new("TextLabel")
	titleText.Name = "Title"
	titleText.Size = UDim2.new(1, -20, 1, 0)
	titleText.Position = UDim2.new(0, 10, 0, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = name or "UI Library"
	titleText.TextColor3 = theme.Text
	titleText.TextSize = 18
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Parent = titleBar
	
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, 0, 1, -40)
	contentFrame.Position = UDim2.new(0, 0, 0, 40)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 6
	contentFrame.ScrollBarImageColor3 = theme.Accent
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.Parent = mainFrame
	
	local contentList = Instance.new("UIListLayout")
	contentList.Padding = UDim.new(0, 8)
	contentList.FillDirection = Enum.FillDirection.Vertical
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Parent = contentFrame
	
	createPadding(contentFrame, 12)
	
	-- Make window draggable
	local dragging
	local dragInput
	local dragStart
	local startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		tween(mainFrame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, createTweenInfo(0))
	end
	
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	titleBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	
	local window = {
		ScreenGui = screenGui,
		MainFrame = mainFrame,
		Content = contentFrame,
		Theme = theme,
		Tabs = {}
	}
	
	function window:UpdateCanvasSize()
		local contentSize = contentList.AbsoluteContentSize
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize.Y + 24)
	end
	
	contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		window:UpdateCanvasSize()
	end)
	
	return setmetatable(window, Window)
end

-- Window:AddTab
function Window:AddTab(name)
	name = name or "Tab"
	
	-- Create tabs container if it doesn't exist
	local tabsContainer = self.Content:FindFirstChild("TabsContainer")
	if not tabsContainer then
		tabsContainer = Instance.new("Frame")
		tabsContainer.Name = "TabsContainer"
		tabsContainer.Size = UDim2.new(1, 0, 0, 0)
		tabsContainer.BackgroundTransparency = 1
		tabsContainer.AutomaticSize = Enum.AutomaticSize.Y
		tabsContainer.LayoutOrder = 0
		tabsContainer.Parent = self.Content
		
		local tabsContainerList = Instance.new("UIListLayout")
		tabsContainerList.FillDirection = Enum.FillDirection.Vertical
		tabsContainerList.Padding = UDim.new(0, 8)
		tabsContainerList.SortOrder = Enum.SortOrder.LayoutOrder
		tabsContainerList.Parent = tabsContainer
	end
	
	-- Create tabs bar if it doesn't exist (only for first tab)
	local tabsBar = tabsContainer:FindFirstChild("TabsBar")
	if not tabsBar then
		tabsBar = Instance.new("Frame")
		tabsBar.Name = "TabsBar"
		tabsBar.Size = UDim2.new(1, 0, 0, 40)
		tabsBar.BackgroundTransparency = 1
		tabsBar.LayoutOrder = 1
		tabsBar.Parent = tabsContainer
		
		local tabsList = Instance.new("UIListLayout")
		tabsList.FillDirection = Enum.FillDirection.Horizontal
		tabsList.Padding = UDim.new(0, 4)
		tabsList.SortOrder = Enum.SortOrder.LayoutOrder
		tabsList.Parent = tabsBar
	end
	
	-- Create tabs content if it doesn't exist
	local tabsContent = tabsContainer:FindFirstChild("TabsContent")
	if not tabsContent then
		tabsContent = Instance.new("Frame")
		tabsContent.Name = "TabsContent"
		tabsContent.Size = UDim2.new(1, 0, 0, 0)
		tabsContent.BackgroundTransparency = 1
		tabsContent.AutomaticSize = Enum.AutomaticSize.Y
		tabsContent.LayoutOrder = 2
		tabsContent.Parent = tabsContainer
		
		local tabsContentList = Instance.new("UIListLayout")
		tabsContentList.FillDirection = Enum.FillDirection.Vertical
		tabsContentList.Padding = UDim.new(0, 6)
		tabsContentList.SortOrder = Enum.SortOrder.LayoutOrder
		tabsContentList.Parent = tabsContent
	end
	
	-- Create tab button
	local tabButton = Instance.new("TextButton")
	tabButton.Name = name
	local tabCount = #tabsBar:GetChildren()
	if tabCount > 0 then
		tabCount = tabCount - 1 -- Exclude UIListLayout
	end
	tabButton.Size = UDim2.new(1 / (tabCount + 1), -4, 0, 36)
	tabButton.BackgroundColor3 = tabCount == 0 and self.Theme.Accent or self.Theme.Foreground
	tabButton.BorderSizePixel = 0
	tabButton.Text = name
	tabButton.TextColor3 = tabCount == 0 and Color3.fromRGB(255, 255, 255) or self.Theme.TextSecondary
	tabButton.TextSize = 14
	tabButton.Font = Enum.Font.Gotham
	tabButton.LayoutOrder = tabCount + 1
	tabButton.Parent = tabsBar
	
	createCorner(tabButton, 6)
	
	-- Update all tab button sizes
	for _, btn in ipairs(tabsBar:GetChildren()) do
		if btn:IsA("TextButton") then
			local totalTabs = #tabsBar:GetChildren() - 1
			btn.Size = UDim2.new(1 / totalTabs, -4, 0, 36)
		end
	end
	
	-- Create tab content
	local tabContent = Instance.new("Frame")
	tabContent.Name = "TabContent"
	tabContent.Size = UDim2.new(1, 0, 0, 0)
	tabContent.BackgroundTransparency = 1
	tabContent.AutomaticSize = Enum.AutomaticSize.Y
	tabContent.Visible = tabCount == 0
	tabContent.Parent = tabsContent
	
	local tabContentList = Instance.new("UIListLayout")
	tabContentList.FillDirection = Enum.FillDirection.Vertical
	tabContentList.Padding = UDim.new(0, 8)
	tabContentList.SortOrder = Enum.SortOrder.LayoutOrder
	tabContentList.Parent = tabContent
	
	-- Tab switching logic
	local currentTabButton = tabCount == 0 and tabButton or nil
	
	tabButton.MouseButton1Click:Connect(function()
		if currentTabButton == tabButton then return end
		
		-- Update all tab buttons
		for _, btn in ipairs(tabsBar:GetChildren()) do
			if btn:IsA("TextButton") then
				if btn == tabButton then
					tween(btn, {BackgroundColor3 = self.Theme.Accent}, createTweenInfo(0.2))
					tween(btn, {TextColor3 = Color3.fromRGB(255, 255, 255)}, createTweenInfo(0.2))
				else
					tween(btn, {BackgroundColor3 = self.Theme.Foreground}, createTweenInfo(0.2))
					tween(btn, {TextColor3 = self.Theme.TextSecondary}, createTweenInfo(0.2))
				end
			end
		end
		
		-- Update all tab contents
		for _, content in ipairs(tabsContent:GetChildren()) do
			if content:IsA("Frame") and content.Name == "TabContent" then
				if content == tabContent then
					content.Visible = true
					tween(content, {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, tabContentList.AbsoluteContentSize.Y)
					}, createTweenInfo(0.2))
				else
					content.Visible = false
				end
			end
		end
		
		currentTabButton = tabButton
	end)
	
	local tab = {
		Button = tabButton,
		Content = tabContent,
		Name = name,
		Groups = {},
		Theme = self.Theme,
		Window = self
	}
	
	table.insert(self.Tabs, tab)
	
	return setmetatable(tab, Tab)
end

-- Tab:AddLeftGroup
function Tab:AddLeftGroup(name)
	name = name or "Group"
	
	-- Check if there's already a left group on this row
	local lastLeftGroup = nil
	local lastRightGroup = nil
	
	for _, group in ipairs(self.Groups) do
		if group.Side == "Left" then
			lastLeftGroup = group
		elseif group.Side == "Right" then
			lastRightGroup = group
		end
	end
	
	local groupFrame = Instance.new("Frame")
	groupFrame.Name = name
	groupFrame.Size = UDim2.new(0.485, 0, 0, 0)
	groupFrame.BackgroundColor3 = self.Theme.SectionBackground or self.Theme.Foreground
	groupFrame.BorderSizePixel = 0
	groupFrame.AutomaticSize = Enum.AutomaticSize.Y
	groupFrame.LayoutOrder = #self.Groups + 1
	groupFrame.Parent = self.Content
	
	createCorner(groupFrame, 6)
	createPadding(groupFrame, 10)
	
	-- Add subtle border
	local groupStroke = createStroke(groupFrame, self.Theme.Border or Color3.fromRGB(40, 40, 45), 1)
	
	local groupTitle = Instance.new("TextLabel")
	groupTitle.Name = "Title"
	groupTitle.Size = UDim2.new(1, 0, 0, 24)
	groupTitle.BackgroundTransparency = 1
	groupTitle.Text = name
	groupTitle.TextColor3 = self.Theme.Text
	groupTitle.TextSize = 14
	groupTitle.Font = Enum.Font.GothamSemibold
	groupTitle.TextXAlignment = Enum.TextXAlignment.Left
	groupTitle.Parent = groupFrame
	
	local groupContent = Instance.new("Frame")
	groupContent.Name = "Content"
	groupContent.Size = UDim2.new(1, 0, 0, 0)
	groupContent.Position = UDim2.new(0, 0, 0, 28)
	groupContent.BackgroundTransparency = 1
	groupContent.BorderSizePixel = 0
	groupContent.AutomaticSize = Enum.AutomaticSize.Y
	groupContent.Parent = groupFrame
	
	local contentList = Instance.new("UIListLayout")
	contentList.Padding = UDim.new(0, 6)
	contentList.FillDirection = Enum.FillDirection.Vertical
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Parent = groupContent
	
	local group = {
		Frame = groupFrame,
		Content = groupContent,
		Title = groupTitle,
		Side = "Left",
		Theme = self.Theme
	}
	
	table.insert(self.Groups, group)
	
	return setmetatable(group, Group)
end

-- Tab:AddRightGroup
function Tab:AddRightGroup(name)
	name = name or "Group"
	
	-- Find the last left group to position on same row
	local lastLeftGroup = nil
	for i = #self.Groups, 1, -1 do
		if self.Groups[i].Side == "Left" then
			lastLeftGroup = self.Groups[i]
			break
		end
	end
	
	local groupFrame = Instance.new("Frame")
	groupFrame.Name = name
	groupFrame.Size = UDim2.new(0.485, -4, 0, 0)
	groupFrame.Position = UDim2.new(0.515, 4, 0, 0)
	groupFrame.BackgroundColor3 = self.Theme.SectionBackground or self.Theme.Foreground
	groupFrame.BorderSizePixel = 0
	groupFrame.AutomaticSize = Enum.AutomaticSize.Y
	
	if lastLeftGroup then
		groupFrame.LayoutOrder = lastLeftGroup.Frame.LayoutOrder
	else
		groupFrame.LayoutOrder = #self.Groups + 1
		groupFrame.Position = UDim2.new(0, 0, 0, 0)
		groupFrame.Size = UDim2.new(1, 0, 0, 0)
	end
	
	groupFrame.Parent = self.Content
	
	createCorner(groupFrame, 6)
	createPadding(groupFrame, 10)
	
	-- Add subtle border
	local groupStroke = createStroke(groupFrame, self.Theme.Border or Color3.fromRGB(40, 40, 45), 1)
	
	local groupTitle = Instance.new("TextLabel")
	groupTitle.Name = "Title"
	groupTitle.Size = UDim2.new(1, 0, 0, 24)
	groupTitle.BackgroundTransparency = 1
	groupTitle.Text = name
	groupTitle.TextColor3 = self.Theme.Text
	groupTitle.TextSize = 14
	groupTitle.Font = Enum.Font.GothamSemibold
	groupTitle.TextXAlignment = Enum.TextXAlignment.Left
	groupTitle.Parent = groupFrame
	
	local groupContent = Instance.new("Frame")
	groupContent.Name = "Content"
	groupContent.Size = UDim2.new(1, 0, 0, 0)
	groupContent.Position = UDim2.new(0, 0, 0, 28)
	groupContent.BackgroundTransparency = 1
	groupContent.BorderSizePixel = 0
	groupContent.AutomaticSize = Enum.AutomaticSize.Y
	groupContent.Parent = groupFrame
	
	local contentList = Instance.new("UIListLayout")
	contentList.Padding = UDim.new(0, 6)
	contentList.FillDirection = Enum.FillDirection.Vertical
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Parent = groupContent
	
	local group = {
		Frame = groupFrame,
		Content = groupContent,
		Title = groupTitle,
		Side = "Right",
		Theme = self.Theme
	}
	
	table.insert(self.Groups, group)
	
	return setmetatable(group, Group)
end

-- Group:AddToggle
function Group:AddToggle(name, callback)
	name = name or "Toggle"
	callback = callback or function() end
	
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Name = name
	toggleFrame.Size = UDim2.new(1, 0, 0, 32)
	toggleFrame.BackgroundTransparency = 1
	toggleFrame.LayoutOrder = 1
	toggleFrame.Parent = self.Content
	
	local toggleLabel = Instance.new("TextLabel")
	toggleLabel.Name = "Label"
	toggleLabel.Size = UDim2.new(1, -50, 0, 32)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Text = name
	toggleLabel.TextColor3 = self.Theme.Text
	toggleLabel.TextSize = 14
	toggleLabel.Font = Enum.Font.Gotham
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.Parent = toggleFrame
	
	local toggleBackground = Instance.new("Frame")
	toggleBackground.Name = "Toggle"
	toggleBackground.Size = UDim2.new(0, 50, 0, 28)
	toggleBackground.Position = UDim2.new(1, -50, 0, 2)
	toggleBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	toggleBackground.BorderSizePixel = 0
	toggleBackground.Parent = toggleFrame
	
	createCorner(toggleBackground, 14)
	
	local toggleButton = Instance.new("Frame")
	toggleButton.Name = "Button"
	toggleButton.Size = UDim2.new(0, 22, 0, 22)
	toggleButton.Position = UDim2.new(0, 3, 0.5, -11)
	toggleButton.AnchorPoint = Vector2.new(0, 0.5)
	toggleButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	toggleButton.BorderSizePixel = 0
	toggleButton.Parent = toggleBackground
	
	createCorner(toggleButton, 11)
	
	local isToggled = false
	local toggleObject = {}
	
	local function toggleFunc()
		isToggled = not isToggled
		
		if isToggled then
			tween(toggleButton, {Position = UDim2.new(1, -25, 0.5, -11)}, createTweenInfo(0.2, Animate.EaseStyle.Quad))
			tween(toggleButton, {BackgroundColor3 = self.Theme.Accent}, createTweenInfo(0.2))
			tween(toggleBackground, {BackgroundColor3 = Color3.fromRGB(self.Theme.Accent.R * 255 * 0.3, self.Theme.Accent.G * 255 * 0.3, self.Theme.Accent.B * 255 * 0.3)}, createTweenInfo(0.2))
		else
			tween(toggleButton, {Position = UDim2.new(0, 3, 0.5, -11)}, createTweenInfo(0.2, Animate.EaseStyle.Quad))
			tween(toggleButton, {BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, createTweenInfo(0.2))
			tween(toggleBackground, {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}, createTweenInfo(0.2))
		end
		
		toggleObject.Value = isToggled
		callback(isToggled)
	end
	
	toggleObject.Frame = toggleFrame
	toggleObject.Value = isToggled
	toggleObject.Toggle = function()
		toggleFunc()
	end
	toggleObject.Set = function(value)
		if isToggled ~= value then
			toggleFunc()
		end
	end
	
	return toggleObject
end

-- Group:AddSlider
function Group:AddSlider(name, min, max, default, callback)
	min = min or 0
	max = max or 100
	default = default or min
	callback = callback or function() end
	
	local sliderFrame = Instance.new("Frame")
	sliderFrame.Name = name or "Slider"
	sliderFrame.Size = UDim2.new(1, 0, 0, 60)
	sliderFrame.BackgroundTransparency = 1
	sliderFrame.LayoutOrder = 1
	sliderFrame.Parent = self.Content
	
	local sliderLabel = Instance.new("TextLabel")
	sliderLabel.Name = "Label"
	sliderLabel.Size = UDim2.new(1, -60, 0, 20)
	sliderLabel.BackgroundTransparency = 1
	sliderLabel.Text = name or "Slider"
	sliderLabel.TextColor3 = self.Theme.Text
	sliderLabel.TextSize = 14
	sliderLabel.Font = Enum.Font.Gotham
	sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
	sliderLabel.Parent = sliderFrame
	
	local sliderValueLabel = Instance.new("TextLabel")
	sliderValueLabel.Name = "ValueLabel"
	sliderValueLabel.Size = UDim2.new(0, 60, 0, 20)
	sliderValueLabel.Position = UDim2.new(1, -60, 0, 0)
	sliderValueLabel.BackgroundTransparency = 1
	sliderValueLabel.Text = tostring(default)
	sliderValueLabel.TextColor3 = self.Theme.Accent
	sliderValueLabel.TextSize = 14
	sliderValueLabel.Font = Enum.Font.GothamBold
	sliderValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	sliderValueLabel.Parent = sliderFrame
	
	local sliderBackground = Instance.new("Frame")
	sliderBackground.Name = "Background"
	sliderBackground.Size = UDim2.new(1, 0, 0, 6)
	sliderBackground.Position = UDim2.new(0, 0, 0, 28)
	sliderBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	sliderBackground.BorderSizePixel = 0
	sliderBackground.Parent = sliderFrame
	
	createCorner(sliderBackground, 3)
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "Fill"
	local fillPercent = (default - min) / (max - min)
	sliderFill.Size = UDim2.new(fillPercent, 0, 1, 0)
	sliderFill.Position = UDim2.new(0, 0, 0, 0)
	sliderFill.BackgroundColor3 = self.Theme.Accent
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBackground
	
	createCorner(sliderFill, 3)
	
	local sliderButton = Instance.new("TextButton")
	sliderButton.Name = "Button"
	sliderButton.Size = UDim2.new(0, 18, 0, 18)
	sliderButton.Position = UDim2.new(fillPercent, -9, 0.5, -9)
	sliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderButton.BorderSizePixel = 0
	sliderButton.Text = ""
	sliderButton.ZIndex = 2
	sliderButton.Parent = sliderFrame
	
	createCorner(sliderButton, 9)
	createStroke(sliderButton, Color3.fromRGB(200, 200, 200), 1)
	
	local dragging = false
	local currentValue = default
	local slider = {}
	
	local function updateValue(value)
		currentValue = math.clamp(value, min, max)
		local percent = (currentValue - min) / (max - min)
		
		slider.Value = currentValue
		sliderValueLabel.Text = tostring(math.floor(currentValue))
		
		tween(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, createTweenInfo(0.1))
		tween(sliderButton, {Position = UDim2.new(percent, -9, 0.5, -9)}, createTweenInfo(0.1))
		
		callback(currentValue)
	end
	
	slider.Frame = sliderFrame
	slider.Value = currentValue
	slider.Update = updateValue
	
	sliderButton.MouseButton1Down:Connect(function()
		dragging = true
		tween(sliderButton, {Size = UDim2.new(0, 22, 0, 22)}, createTweenInfo(0.1))
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if dragging then
				dragging = false
				tween(sliderButton, {Size = UDim2.new(0, 18, 0, 18)}, createTweenInfo(0.1))
			end
		end
	end)
	
	sliderBackground.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mouseX = input.Position.X
			local sliderX = sliderBackground.AbsolutePosition.X
			local sliderSize = sliderBackground.AbsoluteSize.X
			local percent = math.clamp((mouseX - sliderX) / sliderSize, 0, 1)
			local value = min + (max - min) * percent
			updateValue(value)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mouseX = input.Position.X
			local sliderX = sliderBackground.AbsolutePosition.X
			local sliderSize = sliderBackground.AbsoluteSize.X
			local percent = math.clamp((mouseX - sliderX) / sliderSize, 0, 1)
			local value = min + (max - min) * percent
			updateValue(value)
		end
	end)
	
	return slider
end

-- Group:AddButton
function Group:AddButton(name, callback)
	name = name or "Button"
	callback = callback or function() end
	
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 36)
	button.BackgroundColor3 = self.Theme.Accent
	button.BorderSizePixel = 0
	button.Text = name
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Font = Enum.Font.Gotham
	button.LayoutOrder = 1
	button.Parent = self.Content
	
	createCorner(button, 6)
	
	local hoverTween
	local originalColor = button.BackgroundColor3
	
	button.MouseEnter:Connect(function()
		if hoverTween then hoverTween:Cancel() end
		hoverTween = tween(button, {
			BackgroundColor3 = Color3.fromRGB(
				math.min(255, originalColor.R * 255 + 30),
				math.min(255, originalColor.G * 255 + 30),
				math.min(255, originalColor.B * 255 + 30)
			)
		}, createTweenInfo(0.2))
	end)
	
	button.MouseLeave:Connect(function()
		if hoverTween then hoverTween:Cancel() end
		hoverTween = tween(button, {BackgroundColor3 = originalColor}, createTweenInfo(0.2))
	end)
	
	button.MouseButton1Click:Connect(function()
		tween(button, {
			Size = UDim2.new(0.98, 0, 0, 36)
		}, createTweenInfo(0.1, Animate.EaseStyle.Quad, Animate.EaseDirection.Out)).Completed:Connect(function()
			tween(button, {
				Size = UDim2.new(1, 0, 0, 36)
			}, createTweenInfo(0.1, Animate.EaseStyle.Quad, Animate.EaseDirection.Out))
		end)
		
		callback()
	end)
	
	return button
end

-- Group:AddDropdown
function Group:AddDropdown(name, options, callback)
	name = name or "Dropdown"
	options = options or {}
	callback = callback or function() end
	
	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.Name = name
	dropdownFrame.Size = UDim2.new(1, 0, 0, 36)
	dropdownFrame.BackgroundTransparency = 1
	dropdownFrame.LayoutOrder = 1
	dropdownFrame.Parent = self.Content
	
	local dropdownButton = Instance.new("TextButton")
	dropdownButton.Name = "Button"
	dropdownButton.Size = UDim2.new(1, 0, 0, 36)
	dropdownButton.BackgroundColor3 = self.Theme.Foreground
	dropdownButton.BorderSizePixel = 0
	dropdownButton.Text = name
	dropdownButton.TextColor3 = self.Theme.Text
	dropdownButton.TextSize = 14
	dropdownButton.Font = Enum.Font.Gotham
	dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
	dropdownButton.Parent = dropdownFrame
	
	createCorner(dropdownButton, 6)
	createPadding(dropdownButton, 10)
	
	local dropdownIcon = Instance.new("TextLabel")
	dropdownIcon.Name = "Icon"
	dropdownIcon.Size = UDim2.new(0, 20, 0, 20)
	dropdownIcon.Position = UDim2.new(1, -30, 0.5, -10)
	dropdownIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	dropdownIcon.BackgroundTransparency = 1
	dropdownIcon.Text = "▼"
	dropdownIcon.TextColor3 = self.Theme.Accent
	dropdownIcon.TextSize = 12
	dropdownIcon.Font = Enum.Font.GothamBold
	dropdownIcon.Parent = dropdownButton
	
	local optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "Options"
	optionsFrame.Size = UDim2.new(1, 0, 0, 0)
	optionsFrame.Position = UDim2.new(0, 0, 0, 40)
	optionsFrame.BackgroundColor3 = self.Theme.Foreground
	optionsFrame.BorderSizePixel = 0
	optionsFrame.ClipsDescendants = true
	optionsFrame.Visible = false
	optionsFrame.Parent = dropdownFrame
	
	createCorner(optionsFrame, 6)
	
	local optionsList = Instance.new("UIListLayout")
	optionsList.Padding = UDim.new(0, 2)
	optionsList.FillDirection = Enum.FillDirection.Vertical
	optionsList.SortOrder = Enum.SortOrder.LayoutOrder
	optionsList.Parent = optionsFrame
	
	createPadding(optionsFrame, 4)
	
	local isOpen = false
	local selectedOption = nil
	local dropdown = {}
	
	local function toggleDropdown()
		isOpen = not isOpen
		
		if isOpen then
			optionsFrame.Visible = true
			local optionCount = #options
			local totalHeight = (optionCount * 32) + 8
			tween(optionsFrame, {Size = UDim2.new(1, 0, 0, totalHeight)}, createTweenInfo(0.2, Animate.EaseStyle.Quad))
			tween(dropdownIcon, {Rotation = 180}, createTweenInfo(0.2))
		else
			tween(optionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, createTweenInfo(0.2, Animate.EaseStyle.Quad)).Completed:Connect(function()
				optionsFrame.Visible = false
			end)
			tween(dropdownIcon, {Rotation = 0}, createTweenInfo(0.2))
		end
	end
	
	dropdownButton.MouseButton1Click:Connect(toggleDropdown)
	
	dropdown.Frame = dropdownFrame
	dropdown.Open = toggleDropdown
	dropdown.Selected = selectedOption
	dropdown.Value = selectedOption
	
	for i, option in ipairs(options) do
		local optionButton = Instance.new("TextButton")
		optionButton.Name = option
		optionButton.Size = UDim2.new(1, 0, 0, 32)
		optionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		optionButton.BorderSizePixel = 0
		optionButton.Text = option
		optionButton.TextColor3 = self.Theme.TextSecondary
		optionButton.TextSize = 13
		optionButton.Font = Enum.Font.Gotham
		optionButton.TextXAlignment = Enum.TextXAlignment.Left
		optionButton.LayoutOrder = i
		optionButton.Parent = optionsFrame
		
		createCorner(optionButton, 4)
		createPadding(optionButton, 8)
		
		optionButton.MouseEnter:Connect(function()
			tween(optionButton, {BackgroundColor3 = self.Theme.Accent}, createTweenInfo(0.15))
			tween(optionButton, {TextColor3 = Color3.fromRGB(255, 255, 255)}, createTweenInfo(0.15))
		end)
		
		optionButton.MouseLeave:Connect(function()
			if selectedOption ~= option then
				tween(optionButton, {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}, createTweenInfo(0.15))
				tween(optionButton, {TextColor3 = self.Theme.TextSecondary}, createTweenInfo(0.15))
			end
		end)
		
		optionButton.MouseButton1Click:Connect(function()
			selectedOption = option
			dropdownButton.Text = option
			toggleDropdown()
			dropdown.Selected = selectedOption
			dropdown.Value = selectedOption
			callback(option)
			
			for _, btn in ipairs(optionsFrame:GetChildren()) do
				if btn:IsA("TextButton") then
					if btn == optionButton then
						tween(btn, {BackgroundColor3 = self.Theme.Accent}, createTweenInfo(0.15))
						tween(btn, {TextColor3 = Color3.fromRGB(255, 255, 255)}, createTweenInfo(0.15))
					else
						tween(btn, {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}, createTweenInfo(0.15))
						tween(btn, {TextColor3 = self.Theme.TextSecondary}, createTweenInfo(0.15))
					end
				end
			end
		end)
	end
	
	return dropdown
end

-- Group:AddTextBox
function Group:AddTextBox(name, placeholder, callback)
	name = name or "TextBox"
	placeholder = placeholder or "Enter text..."
	callback = callback or function() end
	
	local textBoxFrame = Instance.new("Frame")
	textBoxFrame.Name = name
	textBoxFrame.Size = UDim2.new(1, 0, 0, 36)
	textBoxFrame.BackgroundTransparency = 1
	textBoxFrame.LayoutOrder = 1
	textBoxFrame.Parent = self.Content
	
	local textBoxLabel = Instance.new("TextLabel")
	textBoxLabel.Name = "Label"
	textBoxLabel.Size = UDim2.new(1, 0, 0, 18)
	textBoxLabel.BackgroundTransparency = 1
	textBoxLabel.Text = name
	textBoxLabel.TextColor3 = self.Theme.Text
	textBoxLabel.TextSize = 13
	textBoxLabel.Font = Enum.Font.Gotham
	textBoxLabel.TextXAlignment = Enum.TextXAlignment.Left
	textBoxLabel.Parent = textBoxFrame
	
	local textBox = Instance.new("TextBox")
	textBox.Name = "TextBox"
	textBox.Size = UDim2.new(1, 0, 0, 32)
	textBox.Position = UDim2.new(0, 0, 0, 20)
	textBox.BackgroundColor3 = self.Theme.Foreground
	textBox.BorderSizePixel = 0
	textBox.Text = ""
	textBox.PlaceholderText = placeholder
	textBox.TextColor3 = self.Theme.Text
	textBox.PlaceholderColor3 = self.Theme.TextSecondary
	textBox.TextSize = 14
	textBox.Font = Enum.Font.Gotham
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.TextYAlignment = Enum.TextYAlignment.Center
	textBox.ClearTextOnFocus = false
	textBox.Parent = textBoxFrame
	
	createCorner(textBox, 6)
	createPadding(textBox, 8)
	
	local textBoxStroke = createStroke(textBox, self.Theme.Border or Color3.fromRGB(40, 40, 45), 1)
	
	-- Focus animations
	textBox.Focused:Connect(function()
		tween(textBoxStroke, {Color = self.Theme.Accent, Thickness = 2}, createTweenInfo(0.2))
		tween(textBox, {BackgroundColor3 = Color3.fromRGB(
			math.min(255, self.Theme.Foreground.R * 255 + 5),
			math.min(255, self.Theme.Foreground.G * 255 + 5),
			math.min(255, self.Theme.Foreground.B * 255 + 5)
		)}, createTweenInfo(0.2))
	end)
	
	local textBoxObject = {}
	
	textBox.FocusLost:Connect(function(enterPressed)
		tween(textBoxStroke, {Color = self.Theme.Border or Color3.fromRGB(40, 40, 45), Thickness = 1}, createTweenInfo(0.2))
		tween(textBox, {BackgroundColor3 = self.Theme.Foreground}, createTweenInfo(0.2))
		textBoxObject.Value = textBox.Text
		callback(textBox.Text, enterPressed)
	end)
	
	textBoxObject.Frame = textBoxFrame
	textBoxObject.TextBox = textBox
	textBoxObject.Value = textBox.Text
	textBoxObject.SetText = function(text)
		textBox.Text = text
		textBoxObject.Value = text
	end
	
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		textBoxObject.Value = textBox.Text
	end)
	
	return textBoxObject
end

-- Group:AddLabel
function Group:AddLabel(text, size)
	text = text or "Label"
	size = size or 14
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, size + 4)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = self.Theme.TextSecondary
	label.TextSize = size
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.LayoutOrder = 1
	label.Parent = self.Content
	
	local labelObject = {}
	labelObject.Frame = label
	labelObject.Text = text
	labelObject.SetText = function(newText)
		label.Text = newText
		labelObject.Text = newText
	end
	
	return labelObject
end

return Library
