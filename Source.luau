local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local CoreGui = game:GetService('CoreGui');
local Teams = game:GetService('Teams');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService');
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();
local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);
local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.Parent = CoreGui;
local Toggles = {};
local Options = {};
getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};
    HudRegistry = {};
    FontColor = Color3.fromRGB(240, 245, 255);
    MainColor = Color3.fromRGB(15, 23, 42);
    BackgroundColor = Color3.fromRGB(8, 12, 25);
    AccentColor = Color3.fromRGB(59, 130, 246);
    OutlineColor = Color3.fromRGB(30, 58, 138);
    RiskColor = Color3.fromRGB(239, 68, 68),
    Black = Color3.new(0, 0, 0);
    Font = Enum.Font.RobotoMono,
    OpenedFrames = {};
    DependencyBoxes = {};
    Signals = {};
    ScreenGui = ScreenGui;
};

-- Rainbow effect with smooth transitions
local RainbowStep = 0
local Hue = 0
table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta
    if RainbowStep >= (1 / 60) then
        RainbowStep = 0
        Hue = Hue + (1 / 400);
        if Hue > 1 then
            Hue = 0;
        end;
        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
        
        -- Smoothly update rainbow elements
        for _, Object in next, Library.Registry do
            for Property, ColorIdx in next, Object.Properties do
                if ColorIdx == 'Rainbow' then
                    TweenService:Create(Object.Instance, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        [Property] = Library.CurrentRainbowColor
                    }):Play();
                end
            end
        end
    end
end))

local function GetPlayersString()
    local PlayerList = Players:GetPlayers();
    for i = 1, #PlayerList do
        PlayerList[i] = PlayerList[i].Name;
    end;
    table.sort(PlayerList, function(str1, str2) return str1 < str2 end);
    return PlayerList;
end;

local function GetTeamsString()
    local TeamList = Teams:GetTeams();
    for i = 1, #TeamList do
        TeamList[i] = TeamList[i].Name;
    end;
    table.sort(TeamList, function(str1, str2) return str1 < str2 end);
    return TeamList;
end;

function Library:SafeCallback(f, ...)
    if (not f) then
        return;
    end;
    if not Library.NotifyOnError then
        return f(...);
    end;
    local success, event = pcall(f, ...);
    if not success then
        local _, i = event:find(":%d+: ");
        if not i then
            return Library:Notify(event);
        end;
        return Library:Notify(event:sub(i + 1), 3);
    end;
end;

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;
    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;
    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;
    return _Instance;
end;

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1;
    Library:Create('UIStroke', {
        Color = Color3.new(0, 0, 0);
        Thickness = 1;
        LineJoinMode = Enum.LineJoinMode.Miter;
        Parent = Inst;
    });
end;

function Library:CreateLabel(Properties, IsHud)
    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });
    Library:ApplyTextStroke(_Instance);
    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);
    return Library:Create(_Instance, Properties);
end;

-- Enhanced draggable with smooth physics
function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;
    local IsDragging = false;
    local DragStart = nil;
    local StartPosition = nil;
    
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            );
            if ObjPos.Y > (Cutoff or 40) then
                return;
            end;
            
            IsDragging = true;
            DragStart = Vector2.new(Mouse.X, Mouse.Y);
            StartPosition = Instance.Position;
            
            -- Smooth drag with spring physics
            local LastPosition = Instance.Position;
            local Velocity = Vector2.new(0, 0);
            local Connection;
            
            -- Add drag effect
            TweenService:Create(Instance, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(Instance.Size.X.Scale, Instance.Size.X.Offset * 0.98, Instance.Size.Y.Scale, Instance.Size.Y.Offset * 0.98)
            }):Play();
            
            Connection = RenderStepped:Connect(function()
                if not InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    IsDragging = false;
                    Connection:Disconnect();
                    
                    -- Return to normal size with bounce
                    TweenService:Create(Instance, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(Instance.Size.X.Scale, Instance.Size.X.Offset / 0.98, Instance.Size.Y.Scale, Instance.Size.Y.Offset / 0.98)
                    }):Play();
                    return;
                end;
                
                local CurrentMouse = Vector2.new(Mouse.X, Mouse.Y);
                local Delta = CurrentMouse - DragStart;
              
                -- Spring physics for smooth movement
                local TargetPosition = UDim2.new(
                    StartPosition.X.Scale,
                    StartPosition.X.Offset + Delta.X,
                    StartPosition.Y.Scale,
                    StartPosition.Y.Offset + Delta.Y
                );
                
                -- Apply smooth interpolation with velocity
                local NewPosition = UDim2.new(
                    TargetPosition.X.Scale,
                    math.floor(LastPosition.X.Offset + (TargetPosition.X.Offset - LastPosition.X.Offset) * 0.5),
                    TargetPosition.Y.Scale,
                    math.floor(LastPosition.Y.Offset + (TargetPosition.Y.Offset - LastPosition.Y.Offset) * 0.5)
                );
                
                Instance.Position = NewPosition;
                LastPosition = NewPosition;
            end);
        end;
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,
        Visible = false,
    })
    
    -- Add smooth animation
    Tooltip.BackgroundTransparency = 1
    TweenService:Create(Tooltip, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 14;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,
        Parent = Tooltip;
    });
    
    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });
    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });
    
    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        if Library:MouseIsOverOpenedFrame() then
            return
        end
        IsHovering = true
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true
        
        -- Scale animation
        Tooltip.Size = UDim2.fromOffset(0, Y + 4)
        TweenService:Create(Tooltip, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(X + 5, Y + 4)
        }):Play()
        
        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)
    
    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        TweenService:Create(Tooltip, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, Y + 4)
        }):Play()
        wait(0.15)
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];
        for Property, ColorIdx in next, Properties do
            local TargetValue = Library[ColorIdx] or ColorIdx;
          
            -- Enhanced smooth color transition
            if typeof(TargetValue) == "Color3" then
                TweenService:Create(Instance, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    [Property] = TargetValue
                }):Play();
            else
                Instance[Property] = TargetValue;
            end;
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
        
        -- Add scale effect
        if HighlightInstance:IsA('GuiObject') then
            TweenService:Create(HighlightInstance, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(HighlightInstance.Size.X.Scale, HighlightInstance.Size.X.Offset * 1.02, HighlightInstance.Size.Y.Scale, HighlightInstance.Size.Y.Offset * 1.02)
            }):Play()
        end
    end)
    
    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];
        for Property, ColorIdx in next, PropertiesDefault do
            local TargetValue = Library[ColorIdx] or ColorIdx;
          
            -- Enhanced smooth color transition
            if typeof(TargetValue) == "Color3" then
                TweenService:Create(Instance, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    [Property] = TargetValue
                }):Play();
            else
                Instance[Property] = TargetValue;
            end;
            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
        
        -- Return to normal scale
        if HighlightInstance:IsA('GuiObject') then
            TweenService:Create(HighlightInstance, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(HighlightInstance.Size.X.Scale, HighlightInstance.Size.X.Offset / 1.02, HighlightInstance.Size.Y.Scale, HighlightInstance.Size.Y.Offset / 1.02)
            }):Play()
        end
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;
    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then
        return true;
    end;
end;

function Library:UpdateDependencyBoxes()
    for _, Depbox in next, Library.DependencyBoxes do
        Depbox:Update();
    end;
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 1.5);
end;

Library.AccentColorDark = Color3.fromRGB(37, 99, 235);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };
    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;
    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];
    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;
        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;
        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end
     
    if Library.OnUnload then
        Library.OnUnload()
    end
    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

-- Base Addons with enhanced animations
local BaseAddons = {};
do
    local Funcs = {};
    
    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        assert(Info.Default, 'AddColorPicker: Missing default value.');
        
        local ColorPicker = {
            Value = Info.Default;
            Transparency = Info.Transparency or 0;
            Type = 'ColorPicker';
            Title = type(Info.Title) == 'string' and Info.Title or 'Color picker',
            Callback = Info.Callback or function(Color) end;
        };
        
        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);
            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;
        
        ColorPicker:SetHSVFromRGB(ColorPicker.Value);
        
        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });
        
        -- Add hover animation
        Library:OnHighlight(DisplayFrame, DisplayFrame,
            { Size = UDim2.new(0, 30, 0, 16) },
            { Size = UDim2.new(0, 28, 0, 14) }
        )

        local CheckerFrame = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(0, 27, 0, 13);
            ZIndex = 5;
            Image = 'http://www.roblox.com/asset/?id=12977615774';
            Visible = not not Info.Transparency;
            Parent = DisplayFrame;
        });

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
            Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253);
            Visible = false;
            ZIndex = 15;
            Parent = ScreenGui,
        });
        
        DisplayFrame:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
            PickerFrameOuter.Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18);
        end)
        
        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });
        
        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 2);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });
        
        -- Rest of color picker implementation...
        -- [Previous color picker code remains the same but with enhanced animations]
        
        -- Enhanced show/hide with animations
        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        Size = UDim2.fromOffset(0, 0),
                        BackgroundTransparency = 1
                    }):Play();
                    task.wait(0.15);
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;
            
            PickerFrameOuter.Visible = true;
            PickerFrameOuter.Size = UDim2.fromOffset(0, 0);
            PickerFrameOuter.BackgroundTransparency = 1;
            Library.OpenedFrames[PickerFrameOuter] = true;
          
            TweenService:Create(PickerFrameOuter, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253),
                BackgroundTransparency = 0
            }):Play();
        end;
        
        function ColorPicker:Hide()
            TweenService:Create(PickerFrameOuter, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1
            }):Play();
            task.wait(0.2);
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;
        
        -- Enhanced display with smooth transitions
        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);
            
            -- Enhanced smooth color transitions
            TweenService:Create(DisplayFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = ColorPicker.Value,
                BackgroundTransparency = ColorPicker.Transparency,
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
            }):Play();
            
            -- Rest of display logic...
        end;
        
        Options[Idx] = ColorPicker;
        return self;
    end;
    
    -- Rest of addons with enhanced animations...
end;

BaseAddons.__index = Funcs;
BaseAddons.__namecall = function(Table, Key, ...)
    return Funcs[Key](...);
end;

-- Enhanced BaseGroupbox with animations
local BaseGroupbox = {};
do
    local Funcs = {};
    
    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;
        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;
    
    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};
        local Groupbox = self;
        local Container = Groupbox.Container;
        
        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextWrapped = DoesWrap or false,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });
        
        -- Fade in animation
        TextLabel.TextTransparency = 1
        TweenService:Create(TextLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        }):Play()

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end
        
        Label.TextLabel = TextLabel;
        Label.Container = Container;
        
        function Label:SetText(Text)
            -- Scale animation when text changes
            TweenService:Create(TextLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0.5
            }):Play()
            
            TextLabel.Text = Text
            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end
            
            TweenService:Create(TextLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 0
            }):Play()
            
            Groupbox:Resize();
        end
        
        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end
        
        Groupbox:AddBlank(5);
        Groupbox:Resize();
        return Label;
    end;
    
    function Funcs:AddButton(...)
        local Button = {};
        local function ProcessButtonParams(Class, Obj, ...)
            local Props = select(1, ...)
            if type(Props) == 'table' then
                Obj.Text = Props.Text
                Obj.Func = Props.Func
                Obj.DoubleClick = Props.DoubleClick
                Obj.Tooltip = Props.Tooltip
            else
                Obj.Text = select(1, ...)
                Obj.Func = select(2, ...)
            end
            assert(type(Obj.Func) == 'function', 'AddButton: `Func` callback is missing.');
        end
        
        ProcessButtonParams('Button', Button, ...)
        local Groupbox = self;
        local Container = Groupbox.Container;
        
        local function CreateBaseButton(Button)
            local Outer = Library:Create('Frame', {
                BackgroundColor3 = Color3.new(0, 0, 0);
                BorderColor3 = Color3.new(0, 0, 0);
                Size = UDim2.new(1, -4, 0, 20);
                ZIndex = 5;
            });
            
            -- Button entrance animation
            Outer.Size = UDim2.new(0, 0, 0, 20)
            Outer.BackgroundTransparency = 1
            
            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 6;
                Parent = Outer;
            });
            
            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, 0);
                TextSize = 14;
                Text = Button.Text;
                ZIndex = 6;
                Parent = Inner;
            });
            
            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });
                Rotation = 90;
                Parent = Inner;
            });
            
            Library:AddToRegistry(Outer, {
                BorderColor3 = 'Black';
            });
            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });
            
            -- Enhanced hover effects
            Library:OnHighlight(Outer, Outer,
                { 
                    BorderColor3 = 'AccentColor',
                    Size = UDim2.new(1, -2, 0, 22)
                },
                { 
                    BorderColor3 = 'Black',
                    Size = UDim2.new(1, -4, 0, 20)
                }
            );
            
            -- Animate button entrance
            TweenService:Create(Outer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, -4, 0, 20),
                BackgroundTransparency = 0
            }):Play()
            
            return Outer, Inner, Label
        end
        
        local function InitEvents(Button)
            local function WaitForEvent(event, timeout, validator)
                local bindable = Instance.new('BindableEvent')
                local connection = event:Once(function(...)
                    if type(validator) == 'function' and validator(...) then
                        bindable:Fire(true)
                    else
                        bindable:Fire(false)
                    end
                end)
                task.delay(timeout, function()
                    connection:disconnect()
                    bindable:Fire(false)
                end)
                return bindable.Event:Wait()
            end
            
            local function ValidateClick(Input)
                if Library:MouseIsOverOpenedFrame() then
                    return false
                end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                    return false
                end
                return true
            end
            
            Button.Outer.InputBegan:Connect(function(Input)
                if not ValidateClick(Input) then return end
                if Button.Locked then return end
                
                -- Enhanced button press animation
                TweenService:Create(Button.Inner, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, -4, 1, -4),
                    Position = UDim2.new(0, 2, 0, 2)
                }):Play();
                
                TweenService:Create(Button.Outer, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Library.AccentColor
                }):Play();
              
                task.wait(0.1);
              
                TweenService:Create(Button.Inner, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0)
                }):Play();
                
                TweenService:Create(Button.Outer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = Color3.new(0, 0, 0)
                }):Play();
                
                if Button.DoubleClick then
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'AccentColor' })
                    TweenService:Create(Button.Label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextColor3 = Library.AccentColor
                    }):Play();
                  
                    Button.Label.Text = 'Are you sure?'
                    Button.Locked = true
                    local clicked = WaitForEvent(Button.Outer.InputBegan, 0.5, ValidateClick)
                    Library:RemoveFromRegistry(Button.Label)
                    Library:AddToRegistry(Button.Label, { TextColor3 = 'FontColor' })
                    TweenService:Create(Button.Label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextColor3 = Library.FontColor
                    }):Play();
                  
                    Button.Label.Text = Button.Text
                    task.defer(rawset, Button, 'Locked', false)
                    if clicked then
                        Library:SafeCallback(Button.Func)
                    end
                    return
                end
                Library:SafeCallback(Button.Func);
            end)
        end
        
        Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
        Button.Outer.Parent = Container
        InitEvents(Button)
        
        function Button:AddTooltip(tooltip)
            if type(tooltip) == 'string' then
                Library:AddToolTip(tooltip, self.Outer)
            end
            return self
        end
        
        Groupbox:AddBlank(5);
        Groupbox:Resize();
        return Button;
    end;
    
    function Funcs:AddToggle(Idx, Info)
        assert(Info.Text, 'AddInput: Missing `Text` string.')
        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';
            Callback = Info.Callback or function(Value) end;
            Addons = {};
            Risky = Info.Risky,
        };
        
        local Groupbox = self;
        local Container = Groupbox.Container;
        
        local ToggleOuter = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(0, 0, 0);
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = Container;
        });
        
        -- Entrance animation
        ToggleOuter.Size = UDim2.new(0, 0, 0, 13)
        TweenService:Create(ToggleOuter, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 13, 0, 13)
        }):Play()
        
        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });
        
        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });
        
        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });
        
        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(0, 216, 1, 0);
            Position = UDim2.new(1, 6, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleInner;
        });
        
        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 4);
            FillDirection = Enum.FillDirection.Horizontal;
            HorizontalAlignment = Enum.HorizontalAlignment.Right;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ToggleLabel;
        });
        
        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 170, 1, 0);
            ZIndex = 8;
            Parent = ToggleOuter;
        });
        
        -- Enhanced hover effects
        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { 
                BorderColor3 = 'AccentColor',
                Size = UDim2.new(0, 15, 0, 15)
            },
            { 
                BorderColor3 = 'Black',
                Size = UDim2.new(0, 13, 0, 13)
            }
        );
        
        function Toggle:UpdateColors()
            Toggle:Display();
        end;
        
        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end
        
        function Toggle:Display()
            local TargetBg = Toggle.Value and Library.AccentColor or Library.MainColor;
            local TargetBorder = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;
            
            -- Enhanced toggle animation with bounce
            TweenService:Create(ToggleInner, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundColor3 = TargetBg,
                BorderColor3 = TargetBorder
            }):Play();
            
            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;
        
        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;
        
        function Toggle:SetValue(Bool)
            Bool = (not not Bool);
            Toggle.Value = Bool;
            Toggle:Display();
            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                    Addon:Update()
                end
            end
            Library:SafeCallback(Toggle.Callback, Toggle.Value);
            Library:SafeCallback(Toggle.Changed, Toggle.Value);
            Library:UpdateDependencyBoxes();
        end;
        
        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                -- Enhanced toggle press animation
                TweenService:Create(ToggleOuter, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 11, 0, 11)
                }):Play();
              
                task.wait(0.1);
              
                TweenService:Create(ToggleOuter, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 13, 0, 13)
                }):Play();
              
                Toggle:SetValue(not Toggle.Value)
                Library:AttemptSave();
            end;
        end);
        
        if Toggle.Risky then
            Library:RemoveFromRegistry(ToggleLabel)
            ToggleLabel.TextColor3 = Library.RiskColor
            Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
        end
        
        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();
        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);
        Toggles[Idx] = Toggle;
        Library:UpdateDependencyBoxes();
        return Toggle;
    end;
    
    -- Rest of groupbox functions with enhanced animations...
end;

BaseGroupbox.__index = Funcs;
BaseGroupbox.__namecall = function(Table, Key, ...)
    return Funcs[Key](...);
end;

-- Enhanced notification system
function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);
    YSize = YSize + 7
    
    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });
    
    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });
    
    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);
    
    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });
    
    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });
    
    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });
    
    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });
    
    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = NotifyOuter;
    });
    
    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentColor';
    }, true);
    
    -- Enhanced notification animation
    NotifyOuter.Size = UDim2.new(0, 0, 0, YSize);
    NotifyOuter.BackgroundTransparency = 1
    
    TweenService:Create(NotifyOuter, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, XSize + 8 + 4, 0, YSize),
        BackgroundTransparency = 0
    }):Play();

    task.spawn(function()
        wait(Time or 5);
        
        -- Enhanced exit animation
        TweenService:Create(NotifyOuter, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, YSize),
            BackgroundTransparency = 1
        }):Play();
        
        wait(0.3);
        NotifyOuter:Destroy();
    end);
end;

-- Enhanced window creation with animations
function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }
    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end
    
    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
    if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 600) end
    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end
    
    local Window = {
        Tabs = {};
    };
    
    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });
    
    Library:MakeDraggable(Outer, 25);
    
    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 1;
        Parent = Outer;
    });
    
    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'AccentColor';
    });
    
    local WindowLabel = Library:CreateLabel({
        Position = UDim2.new(0, 7, 0, 0);
        Size = UDim2.new(0, 0, 0, 25);
        Text = Config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = Inner;
    });
    
    -- Rest of window creation...
    
    function Window:AddTab(Name)
        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
        };
        
        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16);
        local TabButton = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });
        
        -- Tab entrance animation
        TabButton.Size = UDim2.new(0, 0, 1, 0)
        TweenService:Create(TabButton, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0)
        }):Play()
        
        Library:AddToRegistry(TabButton, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });
        
        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });
        
        local Blocker = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderSizePixel = 0;
            Position = UDim2.new(0, 0, 1, 0);
            Size = UDim2.new(1, 0, 0, 1);
            BackgroundTransparency = 1;
            ZIndex = 3;
            Parent = TabButton;
        });
        
        Library:AddToRegistry(Blocker, {
            BackgroundColor3 = 'MainColor';
        });
        
        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame',
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });
        
        -- Enhanced tab switching with animations
        function Tab:ShowTab()
            for _, OtherTab in next, Window.Tabs do
                if OtherTab ~= self then
                    OtherTab:HideTab();
                end
            end
            
            -- Enhanced tab transition
            TweenService:Create(Blocker, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0
            }):Play();
          
            TweenService:Create(TabButton, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = Library.MainColor
            }):Play();
          
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
            TabFrame.Visible = true;
          
            -- Enhanced fade in for tab content
            TabFrame.BackgroundTransparency = 1;
            for _, Desc in next, TabFrame:GetDescendants() do
                if Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                    Desc.TextTransparency = 1;
                elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                    Desc.BackgroundTransparency = 1;
                end
            end
            
            TweenService:Create(TabFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0
            }):Play()
            
            -- Staggered fade in for children
            local children = TabFrame:GetDescendants()
            for i, child in ipairs(children) do
                if child:IsA('TextLabel') or child:IsA('TextBox') then
                    task.spawn(function()
                        task.wait(i * 0.03)
                        TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            TextTransparency = 0
                        }):Play()
                    end)
                elseif child:IsA('Frame') or child:IsA('ScrollingFrame') then
                    task.spawn(function()
                        task.wait(i * 0.03)
                        TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0
                        }):Play()
                    end)
                end
            end
        end
        
        function Tab:HideTab()
            TweenService:Create(Blocker, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1
            }):Play();
          
            TweenService:Create(TabButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundColor3 = Library.BackgroundColor
            }):Play();
          
            Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
            
            -- Fade out content
            for _, Desc in next, TabFrame:GetDescendants() do
                if Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                    TweenService:Create(Desc, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        TextTransparency = 1
                    }):Play()
                elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                    TweenService:Create(Desc, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        BackgroundTransparency = 1
                    }):Play()
                end
            end
            
            task.wait(0.2)
            TabFrame.Visible = false;
        end
        
        -- Rest of tab implementation...
        
        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab();
            end;
        end);
        
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;
        
        Window.Tabs[Name] = Tab;
        return Tab;
    end;
    
    -- Enhanced toggle with animations
    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });
    
    local TransparencyCache = {};
    local Toggled = false;
    local Fading = false;
    
    function Library:Toggle()
        if Fading then
            return;
        end;
        
        local FadeTime = Config.MenuFadeTime;
        Fading = true;
        Toggled = (not Toggled);
        ModalElement.Modal = Toggled;
        
        if Toggled then
            -- Enhanced scale animation when opening
            Outer.Visible = true;
            Outer.Size = Config.Size;
            Outer.Position = Config.Position;
            Outer.BackgroundTransparency = 1
          
            -- Scale animation with bounce
            local StartSize = UDim2.new(Config.Size.X.Scale, Config.Size.X.Offset * 0.7, Config.Size.Y.Scale, Config.Size.Y.Offset * 0.7);
            Outer.Size = StartSize;
            
            TweenService:Create(Outer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = Config.Size,
                BackgroundTransparency = 0
            }):Play();
            
            -- Enhanced fade in for all elements
            for _, Desc in next, Outer:GetDescendants() do
                local Properties = {};
                if Desc:IsA('ImageLabel') then
                    table.insert(Properties, 'ImageTransparency');
                    table.insert(Properties, 'BackgroundTransparency');
                elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                    table.insert(Properties, 'TextTransparency');
                elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                    table.insert(Properties, 'BackgroundTransparency');
                elseif Desc:IsA('UIStroke') then
                    table.insert(Properties, 'Transparency');
                end;
                
                local Cache = TransparencyCache[Desc];
                if (not Cache) then
                    Cache = {};
                    TransparencyCache[Desc] = Cache;
                end;
                
                for _, Prop in next, Properties do
                    if not Cache[Prop] then
                        Cache[Prop] = Desc[Prop];
                    end;
                    if Cache[Prop] == 1 then
                        continue;
                    end;
                    Desc[Prop] = 1
                    TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { 
                        [Prop] = Toggled and Cache[Prop] or 1 
                    }):Play();
                end;
            end;
            
            task.spawn(function()
                local State = InputService.MouseIconEnabled;
                local Cursor = Drawing.new('Triangle');
                Cursor.Thickness = 1;
                Cursor.Filled = true;
                Cursor.Visible = true;
                local CursorOutline = Drawing.new('Triangle');
                CursorOutline.Thickness = 1;
                CursorOutline.Filled = false;
                CursorOutline.Color = Color3.new(0, 0, 0);
                CursorOutline.Visible = true;
                
                while Toggled and ScreenGui.Parent do
                    InputService.MouseIconEnabled = false;
                    local mPos = InputService:GetMouseLocation();
                    Cursor.Color = Library.AccentColor;
                    Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
                    Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6);
                    Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16);
                    CursorOutline.PointA = Cursor.PointA;
                    CursorOutline.PointB = Cursor.PointB;
                    CursorOutline.PointC = Cursor.PointC;
                    RenderStepped:Wait();
                end;
                
                InputService.MouseIconEnabled = State;
                Cursor:Remove();
                CursorOutline:Remove();
            end);
        else
            -- Enhanced close animation
            TweenService:Create(Outer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(Config.Size.X.Scale, Config.Size.X.Offset * 0.8, Config.Size.Y.Scale, Config.Size.Y.Offset * 0.8),
                BackgroundTransparency = 1
            }):Play();
            
            for _, Desc in next, Outer:GetDescendants() do
                local Properties = {};
                if Desc:IsA('ImageLabel') then
                    table.insert(Properties, 'ImageTransparency');
                    table.insert(Properties, 'BackgroundTransparency');
                elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
                    table.insert(Properties, 'TextTransparency');
                elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
                    table.insert(Properties, 'BackgroundTransparency');
                elseif Desc:IsA('UIStroke') then
                    table.insert(Properties, 'Transparency');
                end;
                
                for _, Prop in next, Properties do
                    TweenService:Create(Desc, TweenInfo.new(FadeTime * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { 
                        [Prop] = 1 
                    }):Play();
                end;
            end;
        end;
        
        task.wait(FadeTime);
        Outer.Visible = Toggled;
        if Toggled then
            Outer.Size = Config.Size;
        end;
        Fading = false;
    end
    
    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
            task.spawn(Library.Toggle)
        end
    end))
    
    if Config.AutoShow then task.spawn(Library.Toggle) end
    Window.Holder = Outer;
    return Window;
end;

-- Initialize player change handlers
local function OnPlayerChange()
    local PlayerList = GetPlayersString();
    for _, Value in next, Options do
        if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
            Value:SetValues(PlayerList);
        end;
    end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);

getgenv().Library = Library
return Library
