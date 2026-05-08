-- ═══════════════════════════════════════════════════════════════
-- Etinity UI Library | source.lua
-- ═══════════════════════════════════════════════════════════════

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- УТИЛИТЫ
-- ═══════════════════════════════════════════════════════════════

local function Tween(obj, props, t, s, d)
    local ok, err = pcall(function()
        TweenService:Create(obj,
            TweenInfo.new(t or 0.25, s or Enum.EasingStyle.Quart, d or Enum.EasingDirection.Out),
            props):Play()
    end)
end

local function New(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do
        o[k] = v
    end
    if parent then o.Parent = parent end
    return o
end

local function Corner(radius, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function AccentGradient(parent)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(66, 183, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(181, 249, 255)),
    }
    g.Parent = parent
    return g
end

local function ColorToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5))
end

local function HexToColor(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

-- ═══════════════════════════════════════════════════════════════
-- ЦВЕТА (из оригинального прототипа)
-- ═══════════════════════════════════════════════════════════════

local BG    = Color3.fromRGB(2, 2, 2)
local CON   = Color3.fromRGB(11, 11, 11)
local BTN   = Color3.fromRGB(0, 0, 0)
local WHT   = Color3.fromRGB(255, 255, 255)
local TXT   = Color3.fromRGB(188, 188, 188)
local TXTS  = Color3.fromRGB(49, 49, 49)
local TXTD  = Color3.fromRGB(108, 108, 108)
local ACC   = Color3.fromRGB(83, 203, 255)
local ACC1  = Color3.fromRGB(66, 183, 255)
local ACC2  = Color3.fromRGB(181, 249, 255)
local DIVC  = Color3.fromRGB(29, 29, 29)
local CLOSEC = Color3.fromRGB(180, 50, 50)

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════

local NotifGui = New("ScreenGui", {
    Name = "EtinityNotif",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false,
}, LocalPlayer:WaitForChild("PlayerGui"))

local notifQueue   = {}
local notifRunning = false

local function runNotifQueue()
    if #notifQueue == 0 then
        notifRunning = false
        return
    end
    notifRunning = true
    local d = table.remove(notifQueue, 1)

    -- Контейнер уведомления
    local nc = New("Frame", {
        BackgroundColor3      = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.300,
        BorderSizePixel       = 0,
        Position              = UDim2.new(1.05, 0, 0.015, 0),
        Size                  = UDim2.new(0, 250, 0, 70),
        ZIndex                = 50,
    }, NotifGui)
    Corner(15, nc)

    -- Акцентная полоска
    local bar = New("Frame", {
        BackgroundColor3 = ACC1,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 0),
        Size             = UDim2.new(1, 0, 0, 2),
        ZIndex           = 51,
    }, nc)
    Corner(99, bar)
    AccentGradient(bar)

    -- Заголовок
    New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0.0857, 0),
        Size                   = UDim2.new(1, 0, 0, 20),
        Font                   = Enum.Font.ArialBold,
        Text                   = d.title,
        TextColor3             = WHT,
        TextSize               = 18,
        ZIndex                 = 51,
    }, nc)

    -- Разделитель
    New("Frame", {
        BackgroundColor3       = WHT,
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0.457, 0),
        Size                   = UDim2.new(1, 0, 0, 2),
        ZIndex                 = 51,
    }, nc)

    -- Подзаголовок
    local subLbl = New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0.485, 0),
        Size                   = UDim2.new(1, 0, 0, 36),
        Font                   = Enum.Font.ArialBold,
        Text                   = d.subtitle,
        TextColor3             = TXT,
        TextSize               = 12,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextYAlignment         = Enum.TextYAlignment.Top,
        TextWrapped            = true,
        ZIndex                 = 51,
    }, nc)
    New("UIPadding", {
        PaddingLeft = UDim.new(0.05, 0),
        PaddingTop  = UDim.new(0.1, 0),
    }, subLbl)

    -- Кнопка закрыть
    local closeNBtn = New("TextButton", {
        BackgroundColor3       = CON,
        BackgroundTransparency = 0.600,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.884, 0, 0.084, 0),
        Size                   = UDim2.new(0, 20, 0, 20),
        Font                   = Enum.Font.FredokaOne,
        Text                   = "X",
        TextColor3             = Color3.fromRGB(189, 189, 189),
        TextSize               = 16,
        ZIndex                 = 52,
    }, nc)
    Corner(99, closeNBtn)

    local gone = false
    local targetPos = UDim2.new(0.807, 0, 0.015, 0)

    local function dismiss()
        if gone then return end
        gone = true
        Tween(nc, {
            Position              = UDim2.new(1.05, 0, 0.015, 0),
            BackgroundTransparency = 0.9,
        }, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.4, function()
            nc:Destroy()
            task.delay(0.2, runNotifQueue)
        end)
    end

    closeNBtn.MouseButton1Click:Connect(dismiss)
    closeNBtn.MouseEnter:Connect(function()
        Tween(closeNBtn, {BackgroundTransparency = 0.2}, 0.1)
    end)
    closeNBtn.MouseLeave:Connect(function()
        Tween(closeNBtn, {BackgroundTransparency = 0.6}, 0.1)
    end)

    Tween(nc, {Position = targetPos}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(d.dur or 4, dismiss)
end

-- ═══════════════════════════════════════════════════════════════
-- COLOR PICKER
-- ═══════════════════════════════════════════════════════════════

local function MakeColorPicker(screenGui, labelText, initColor, previewBtn, onChange)
    local pH, pS, pV = Color3.toHSV(initColor)
    local curColor   = initColor
    local isOpen     = false
    local svDrag     = false
    local hueDrag    = false

    -- Панель
    local panel = New("Frame", {
        BackgroundColor3       = Color3.fromRGB(2, 2, 2),
        BackgroundTransparency = 0.100,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 166, 0, 230),
        Visible                = false,
        ZIndex                 = 200,
    }, screenGui)
    Corner(15, panel)

    -- Заголовок пикера
    New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 30),
        Font                   = Enum.Font.ArialBold,
        Text                   = labelText,
        TextColor3             = TXT,
        TextSize               = 14,
        ZIndex                 = 201,
    }, panel)

    -- Кнопка закрыть пикер
    local cpClose = New("TextButton", {
        BackgroundColor3 = CON,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.828, 0, 0.030, 0),
        Size             = UDim2.new(0, 20, 0, 20),
        Font             = Enum.Font.FredokaOne,
        Text             = "X",
        TextColor3       = Color3.fromRGB(189, 189, 189),
        TextSize         = 16,
        ZIndex           = 201,
    }, panel)
    Corner(99, cpClose)

    -- SV поле (основное цветовое поле)
    local svField = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.042, 0, 0.130, 0),
        Size             = UDim2.new(0, 151, 0, 115),
        ZIndex           = 201,
        ClipsDescendants = true,
    }, panel)
    Corner(6, svField)

    -- Белый градиент (насыщенность — слева направо: белый → прозрачный)
    local svWhite = New("Frame", {
        BackgroundColor3 = WHT,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 202,
    }, svField)
    Corner(6, svWhite)
    local gW = Instance.new("UIGradient")
    gW.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    }
    gW.Parent = svWhite

    -- Чёрный градиент (яркость — снизу: чёрный → прозрачный)
    local svBlack = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 203,
    }, svField)
    Corner(6, svBlack)
    local gB = Instance.new("UIGradient")
    gB.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    }
    gB.Rotation = 90
    gB.Parent = svBlack

    -- Кликабельный оверлей SV
    local svHit = New("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        Text                   = "",
        ZIndex                 = 205,
    }, svField)

    -- Курсор SV
    local svCur = New("TextButton", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(pS, 0, 1 - pV, 0),
        Size             = UDim2.new(0, 10, 0, 10),
        Text             = "",
        ZIndex           = 206,
    }, svField)
    Corner(99, svCur)

    -- Hue слайдер
    local hueBar = New("Frame", {
        BackgroundColor3 = WHT,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.042, 0, 0.695, 0),
        Size             = UDim2.new(0, 151, 0, 12),
        ZIndex           = 201,
    }, panel)
    Corner(99, hueBar)

    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0,   0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,   255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,   255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,   0,   255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0,   255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0,   0)),
    }
    hueGrad.Parent = hueBar

    local hueHit = New("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        Text                   = "",
        ZIndex                 = 203,
    }, hueBar)

    -- Курсор Hue
    local hueCur = New("Frame", {
        BackgroundColor3 = WHT,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(pH, 0, 0.5, 0),
        Size             = UDim2.new(0, 10, 0, 16),
        ZIndex           = 204,
    }, hueBar)
    Corner(4, hueCur)

    -- Превью цвета
    local cpPreview = New("Frame", {
        BackgroundColor3 = curColor,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.042, 0, 0.800, 0),
        Size             = UDim2.new(0, 90, 0, 24),
        ZIndex           = 201,
    }, panel)
    Corner(6, cpPreview)

    -- HEX поле
    local hexBox = New("TextBox", {
        BackgroundColor3 = CON,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.042, 0, 0.800, 0),
        Size             = UDim2.new(0, 90, 0, 24),
        Font             = Enum.Font.ArialBold,
        Text             = ColorToHex(curColor),
        TextColor3       = TXT,
        TextSize         = 11,
        ZIndex           = 201,
        ClearTextOnFocus = false,
        PlaceholderText  = "#FFFFFF",
    }, panel)
    Corner(6, hexBox)

    -- Правильно расположим превью и hex рядом
    cpPreview.Position = UDim2.new(0.042, 0, 0.810, 0)
    cpPreview.Size     = UDim2.new(0, 60, 0, 24)
    hexBox.Position    = UDim2.new(0.042, 0, 0.810, 0)
    hexBox.Size        = UDim2.new(0, 60, 0, 24)
    -- Рядом
    cpPreview.Position = UDim2.new(0, 7, 0, 190)
    cpPreview.Size     = UDim2.new(0, 55, 0, 24)
    hexBox.Position    = UDim2.new(0, 68, 0, 190)
    hexBox.Size        = UDim2.new(0, 84, 0, 24)

    -- ── Логика ──────────────────────────────────────────────

    local function refreshUI()
        local pureHue = Color3.fromHSV(pH, 1, 1)
        curColor = Color3.fromHSV(pH, pS, pV)

        svField.BackgroundColor3  = pureHue
        svCur.Position            = UDim2.new(pS, 0, 1 - pV, 0)
        hueCur.Position           = UDim2.new(pH, 0, 0.5, 0)
        cpPreview.BackgroundColor3 = curColor
        hexBox.Text               = ColorToHex(curColor)
        previewBtn.BackgroundColor3 = curColor

        if onChange then onChange(curColor) end
    end

    local function handleSV(inp)
        local p = svField.AbsolutePosition
        local s = svField.AbsoluteSize
        pS = math.clamp((inp.Position.X - p.X) / s.X, 0, 1)
        pV = 1 - math.clamp((inp.Position.Y - p.Y) / s.Y, 0, 1)
        refreshUI()
    end

    local function handleHue(inp)
        local p = hueBar.AbsolutePosition
        local s = hueBar.AbsoluteSize
        pH = math.clamp((inp.Position.X - p.X) / s.X, 0, 1)
        refreshUI()
    end

    svHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = true
            handleSV(i)
        end
    end)
    svCur.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = true
        end
    end)

    hueHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDrag = true
            handleHue(i)
        end
    end)
    hueCur.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDrag = true
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if svDrag  then handleSV(i)  end
        if hueDrag then handleHue(i) end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag  = false
            hueDrag = false
        end
    end)

    hexBox.FocusLost:Connect(function()
        local c = HexToColor(hexBox.Text)
        if c then
            pH, pS, pV = Color3.toHSV(c)
            refreshUI()
        else
            hexBox.Text = ColorToHex(curColor)
        end
    end)

    local function closePicker()
        isOpen = false
        Tween(panel, {BackgroundTransparency = 1}, 0.18)
        task.delay(0.2, function()
            panel.Visible = false
            panel.BackgroundTransparency = 0.1
        end)
    end

    local function openPicker()
        isOpen = true
        pH, pS, pV = Color3.toHSV(curColor)

        local vp  = workspace.CurrentCamera.ViewportSize
        local bap = previewBtn.AbsolutePosition
        local px  = math.clamp(bap.X - 170, 0, vp.X - 170)
        local py  = math.clamp(bap.Y - 240, 0, vp.Y - 235)

        panel.Position             = UDim2.new(0, px, 0, py)
        panel.BackgroundTransparency = 1
        panel.Visible              = true
        Tween(panel, {BackgroundTransparency = 0.1}, 0.2)
        refreshUI()
    end

    cpClose.MouseButton1Click:Connect(closePicker)

    UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 or not isOpen then return end
        task.defer(function()
            local mp = UserInputService:GetMouseLocation()
            local function inside(f)
                local p, s = f.AbsolutePosition, f.AbsoluteSize
                return mp.X >= p.X and mp.X <= p.X + s.X
                   and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
            end
            if not inside(panel) and not inside(previewBtn) then
                closePicker()
            end
        end)
    end)

    return {
        Toggle   = function() if isOpen then closePicker() else openPicker() end end,
        GetValue = function() return curColor end,
        SetValue = function(c)
            curColor = c
            previewBtn.BackgroundColor3 = c
            if onChange then onChange(c) end
        end,
    }
end

-- ═══════════════════════════════════════════════════════════════
-- LIBRARY
-- ═══════════════════════════════════════════════════════════════

local Library = {}

function Library:Notify(title, subtitle, duration)
    table.insert(notifQueue, {
        title    = title    or "",
        subtitle = subtitle or "",
        dur      = duration or 4,
    })
    if not notifRunning then runNotifQueue() end
end

function Library:CreateWindow(opts)
    opts = opts or {}
    local winTitle = opts.Title    or "Etinity"
    local winSub   = opts.Subtitle or "V1.0"
    local winIcon  = opts.Icon     or "rbxassetid://130210005937854"

    -- ScreenGui
    local gui = New("ScreenGui", {
        Name            = "EtinityLibrary",
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn    = false,
    }, LocalPlayer:WaitForChild("PlayerGui"))

    -- ── MainContainer ─────────────────────────────────────────
    local main = New("Frame", {
        Name                   = "MainContainer",
        BackgroundColor3       = BG,
        BackgroundTransparency = 0.100,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.205, 0, 0.218, 0),
        Size                   = UDim2.new(0, 805, 0, 483),
    }, gui)
    Corner(15, main)

    -- ── Icon ──────────────────────────────────────────────────
    local ico = New("ImageLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.034, 0, 0.026, 0),
        Size                   = UDim2.new(0, 36, 0, 36),
        Image                  = winIcon,
        ZIndex                 = 2,
    }, main)
    AccentGradient(ico)

    -- ── Title ─────────────────────────────────────────────────
    local titleLbl = New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.070, 0, 0.022, 0),
        Size                   = UDim2.new(0, 108, 0, 27),
        Font                   = Enum.Font.ArialBold,
        Text                   = winTitle,
        TextColor3             = WHT,
        TextSize               = 20,
        ZIndex                 = 2,
    }, main)
    AccentGradient(titleLbl)

    -- ── SubTitle ──────────────────────────────────────────────
    New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.075, 0, 0.078, 0),
        Size                   = UDim2.new(0, 100, 0, 19),
        Font                   = Enum.Font.ArialBold,
        Text                   = winSub,
        TextColor3             = TXTD,
        TextSize               = 10,
        ZIndex                 = 2,
    }, main)

    -- ── Divider ───────────────────────────────────────────────
    local topDiv = New("Frame", {
        BackgroundColor3 = WHT,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.132, 0),
        Size             = UDim2.new(1, 0, 0, 2),
        ZIndex           = 2,
    }, main)
    AccentGradient(topDiv)

    -- ── TabsContainer ─────────────────────────────────────────
    local tabsOuter = New("Frame", {
        BackgroundColor3       = CON,
        BackgroundTransparency = 0.300,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.200, 0, 0.027, 0),
        Size                   = UDim2.new(0, 515, 0, 36),
        ClipsDescendants       = true,
        ZIndex                 = 2,
    }, main)
    Corner(20, tabsOuter)

    local tabsScroll = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness     = 0,
        ScrollingDirection     = Enum.ScrollingDirection.X,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        ClipsDescendants       = true,
        ZIndex                 = 2,
    }, tabsOuter)

    local tabsLayout = New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 0),
    }, tabsScroll)

    -- ── Контентная зона ───────────────────────────────────────
    local contentArea = New("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0.167, 0),
        Size                   = UDim2.new(1, 0, 1, -0.167 * 483),
        ClipsDescendants       = true,
        ZIndex                 = 1,
    }, main)
    -- Используем пиксели для точности
    contentArea.Position = UDim2.new(0, 0, 0, 80)
    contentArea.Size     = UDim2.new(1, 0, 1, -80)

    -- ── Close Button ──────────────────────────────────────────
    local closeBtn = New("TextButton", {
        BackgroundColor3 = CON,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.936, 0, 0.026, 0),
        Size             = UDim2.new(0, 36, 0, 36),
        Font             = Enum.Font.FredokaOne,
        Text             = "X",
        TextColor3       = Color3.fromRGB(189, 189, 189),
        TextSize         = 16,
        ZIndex           = 3,
    }, main)
    Corner(99, closeBtn)

    -- ── Settings Button ───────────────────────────────────────
    local settBtn = New("TextButton", {
        BackgroundColor3 = CON,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.870, 0, 0.026, 0),
        Size             = UDim2.new(0, 36, 0, 36),
        Font             = Enum.Font.FredokaOne,
        Text             = "",
        ZIndex           = 3,
    }, main)
    Corner(99, settBtn)

    local settIco = New("ImageLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.166, 0, 0.166, 0),
        Size                   = UDim2.new(0, 23, 0, 23),
        Image                  = "rbxassetid://7059346373",
        ImageColor3            = Color3.fromRGB(189, 189, 189),
        ZIndex                 = 4,
    }, settBtn)

    -- ── Settings Panel ────────────────────────────────────────
    local settPanel = New("Frame", {
        BackgroundColor3       = BG,
        BackgroundTransparency = 0.100,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 261, 0, 483),
        Visible                = false,
        ZIndex                 = 10,
        ClipsDescendants       = true,
    }, gui)
    Corner(15, settPanel)

    local settInner = New("Frame", {
        BackgroundColor3       = CON,
        BackgroundTransparency = 0.200,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.045, 0, 0.022, 0),
        Size                   = UDim2.new(0, 238, 0, 456),
        ZIndex                 = 11,
    }, settPanel)
    Corner(15, settInner)

    New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 30),
        Font                   = Enum.Font.ArialBold,
        Text                   = "Settings",
        TextColor3             = TXT,
        TextSize               = 18,
        ZIndex                 = 12,
    }, settInner)

    -- Разделитель в настройках
    local settDiv = New("Frame", {
        BackgroundColor3       = DIVC,
        BackgroundTransparency = 0.200,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0, 32),
        Size                   = UDim2.new(1, 0, 0, 2),
        ZIndex                 = 12,
    }, settInner)
    Corner(99, settDiv)

    local settScroll = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0, 38),
        Size                   = UDim2.new(1, 0, 1, -38),
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = ACC1,
        ZIndex                 = 12,
    }, settInner)

    local settListLayout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
    }, settScroll)

    New("UIPadding", {
        PaddingTop    = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft   = UDim.new(0, 8),
        PaddingRight  = UDim.new(0, 8),
    }, settScroll)

    local function updateSettCanvas()
        task.defer(function()
            settScroll.CanvasSize = UDim2.new(0, 0, 0,
                settListLayout.AbsoluteContentSize.Y + 12)
        end)
    end

    -- ── Dragging ──────────────────────────────────────────────
    local dragging, dragStart, dragOrigin = false, nil, nil

    local dragZone = New("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0, 0),
        Size                   = UDim2.new(1, 0, 0, 64),
        ZIndex                 = 2,
    }, main)

    dragZone.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            dragStart  = i.Position
            dragOrigin = main.Position
        end
    end)
    dragZone.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local function syncSettPos()
        settPanel.Position = UDim2.new(0,
            main.AbsolutePosition.X + main.AbsoluteSize.X + 8,
            0,
            main.AbsolutePosition.Y)
    end

    UserInputService.InputChanged:Connect(function(i)
        if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = i.Position - dragStart
        main.Position = UDim2.new(
            dragOrigin.X.Scale, dragOrigin.X.Offset + d.X,
            dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)
        if settPanel.Visible then syncSettPos() end
    end)

    -- ── Close Logic ───────────────────────────────────────────
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {
            Size                   = UDim2.new(0, 805, 0, 0),
            BackgroundTransparency = 1,
        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.35, function() gui:Destroy() end)
    end)
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = CLOSEC, TextColor3 = WHT}, 0.15)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = CON, TextColor3 = Color3.fromRGB(189,189,189)}, 0.15)
    end)

    -- ── Settings Open / Close ─────────────────────────────────
    local settOpen = false

    local function openSett()
        settOpen = true
        syncSettPos()
        settPanel.Size    = UDim2.new(0, 0, 0, 483)
        settPanel.Visible = true
        Tween(settPanel, {Size = UDim2.new(0, 261, 0, 483)},
            0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(settIco, {Rotation = 90}, 0.3)
    end

    local function closeSett()
        settOpen = false
        Tween(settPanel, {Size = UDim2.new(0, 0, 0, 483)},
            0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        Tween(settIco, {Rotation = 0}, 0.25)
        task.delay(0.27, function() settPanel.Visible = false end)
    end

    settBtn.MouseButton1Click:Connect(function()
        if settOpen then closeSett() else openSett() end
    end)
    settBtn.MouseEnter:Connect(function()
        Tween(settBtn, {BackgroundColor3 = Color3.fromRGB(22, 22, 22)}, 0.12)
        if not settOpen then Tween(settIco, {Rotation = 30}, 0.2) end
    end)
    settBtn.MouseLeave:Connect(function()
        Tween(settBtn, {BackgroundColor3 = CON}, 0.12)
        if not settOpen then Tween(settIco, {Rotation = 0}, 0.2) end
    end)

    -- ═══════════════════════════════════════════════════════════
    -- WINDOW (простая таблица, без метатаблиц)
    -- ═══════════════════════════════════════════════════════════

    local Win        = {}
    local allTabs    = {}
    local currentTab = nil
    local tabCount   = 0

    -- ── selectTab ─────────────────────────────────────────────
    local function selectTab(td)
        if currentTab == td then return end

        -- Скрываем предыдущий
        if currentTab then
            Tween(currentTab.btn, {BackgroundTransparency = 1}, 0.2)
            currentTab.ind.Visible    = false
            currentTab.scroll.Visible = false
        end

        currentTab = td

        -- Показываем новый
        Tween(td.btn, {BackgroundTransparency = 0}, 0.2)
        td.ind.Visible    = true
        td.ind.BackgroundTransparency = 0.1
        td.scroll.Visible = true
    end

    -- ── AddTab ────────────────────────────────────────────────
    function Win:AddTab(name)
        tabCount = tabCount + 1

        -- Кнопка таба (точно как в прототипе)
        local tabBtn = New("TextButton", {
            BackgroundColor3       = ACC,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(0, 103, 1, 0),
            Font                   = Enum.Font.ArialBold,
            Text                   = name,
            TextColor3             = WHT,
            TextSize               = 14,
            ZIndex                 = 3,
            LayoutOrder            = tabCount,
        }, tabsScroll)
        Corner(20, tabBtn)

        -- Индикатор (полоска под табом)
        local ind = New("Frame", {
            BackgroundColor3       = ACC,
            BackgroundTransparency = 0.1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0.135, 0, 1.166, 0),
            Size                   = UDim2.new(0, 75, 0, 2),
            Visible                = false,
            ZIndex                 = 4,
        }, tabBtn)
        Corner(99, ind)
        AccentGradient(ind)

        -- Обновляем CanvasSize скролла
        task.defer(function()
            tabsScroll.CanvasSize = UDim2.new(0,
                tabsLayout.AbsoluteContentSize.X, 0, 0)
        end)

        -- ScrollingFrame для секций таба
        local scroll = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0, 13, 0, 8),
            Size                   = UDim2.new(1, -26, 1, -16),
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = ACC1,
            Visible                = false,
            ZIndex                 = 2,
        }, contentArea)

        local scrollLayout = New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 13),
        }, scroll)

        local function updateScrollCanvas()
            task.defer(function()
                scroll.CanvasSize = UDim2.new(0, 0, 0,
                    scrollLayout.AbsoluteContentSize.Y + 16)
            end)
        end

        -- Данные таба
        local td = {
            btn      = tabBtn,
            ind      = ind,
            scroll   = scroll,
            secCount = 0,
        }

        tabBtn.MouseEnter:Connect(function()
            if currentTab ~= td then
                Tween(tabBtn, {BackgroundTransparency = 0.7}, 0.15)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if currentTab ~= td then
                Tween(tabBtn, {BackgroundTransparency = 1}, 0.15)
            end
        end)
        tabBtn.MouseButton1Click:Connect(function()
            selectTab(td)
        end)

        table.insert(allTabs, td)
        if #allTabs == 1 then selectTab(td) end

        -- ── Tab object ────────────────────────────────────────
        local TabObj = {}

        -- ── AddSection ────────────────────────────────────────
        function TabObj:AddSection(secName)
            td.secCount = td.secCount + 1

            local SecObj   = {}
            local elemCount = 0

            -- Фрейм секции (точно как ElementsContainer в прототипе)
            local secFrame = New("Frame", {
                BackgroundColor3       = CON,
                BackgroundTransparency = 0.100,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, 50),
                LayoutOrder            = td.secCount,
                ZIndex                 = 3,
            }, scroll)
            Corner(15, secFrame)

            -- Заголовок секции
            New("TextLabel", {
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0.019, 0, 0.032, 0),
                Size                   = UDim2.new(0, 200, 0, 22),
                Font                   = Enum.Font.ArialBold,
                Text                   = secName,
                TextColor3             = TXTS,
                TextSize               = 20,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 4,
            }, secFrame)

            -- Layout элементов
            local elemListLayout = New("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 0),
            }, secFrame)

            New("UIPadding", {
                PaddingTop    = UDim.new(0, 36),
                PaddingBottom = UDim.new(0, 6),
            }, secFrame)

            local function resizeSec()
                task.defer(function()
                    local h = elemListLayout.AbsoluteContentSize.Y
                    secFrame.Size = UDim2.new(1, 0, 0, h + 42)
                    updateScrollCanvas()
                end)
            end

            -- Фабрика строки элемента (как в прототипе: полная ширина, 30px)
            local function makeRow(height)
                elemCount = elemCount + 1
                return New("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Size                   = UDim2.new(1, 0, 0, height or 30),
                    LayoutOrder            = elemCount,
                    ZIndex                 = 4,
                }, secFrame)
            end

            -- Лейбл названия элемента (позиционирование как в прототипе)
            local function makeElemLabel(parent, text)
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.019, 0, 0, 0),
                    Size                   = UDim2.new(0, 200, 1, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = text,
                    TextColor3             = TXT,
                    TextSize               = 14,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 5,
                }, parent)
            end

            -- ════════════════════════════════════════════════
            -- TOGGLE (как в прототипе)
            -- ════════════════════════════════════════════════
            function SecObj:AddToggle(label, default, callback)
                local state = (default == true)
                local r = makeRow(30)
                makeElemLabel(r, label)

                -- Кнопка тоггла (позиция как в прототипе: 0.961, отступ)
                local tbtn = New("TextButton", {
                    BackgroundColor3 = state and WHT or BTN,
                    BorderSizePixel  = 0,
                    Position         = UDim2.new(0.961, 0, 0.166, 0),
                    Size             = UDim2.new(0, 20, 0, 20),
                    Font             = Enum.Font.SourceSans,
                    Text             = "",
                    TextColor3       = BTN,
                    TextSize         = 14,
                    ZIndex           = 5,
                }, r)

                -- Иконка галочки
                local tick = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.05, 0, 0.05, 0),
                    Size                   = UDim2.new(0, 17, 0, 17),
                    Image                  = state
                        and "rbxassetid://13753318181"
                        or  "rbxassetid://14189590169",
                    Visible                = state,
                    ZIndex                 = 6,
                }, tbtn)

                local function refresh(animated)
                    local dur = animated and 0.18 or 0
                    if state then
                        Tween(tbtn, {BackgroundColor3 = WHT}, dur)
                        tick.Image   = "rbxassetid://13753318181"
                        tick.Visible = true
                    else
                        Tween(tbtn, {BackgroundColor3 = BTN}, dur)
                        tick.Visible = false
                    end
                end

                tbtn.MouseButton1Click:Connect(function()
                    state = not state
                    refresh(true)
                    -- Пружинная анимация
                    Tween(tbtn, {Size = UDim2.new(0, 17, 0, 17)}, 0.07, Enum.EasingStyle.Quad)
                    task.delay(0.07, function()
                        Tween(tbtn, {Size = UDim2.new(0, 20, 0, 20)},
                            0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end)
                    if callback then callback(state) end
                end)

                resizeSec()
                return {
                    GetValue = function() return state end,
                    SetValue = function(_, v)
                        state = v
                        refresh(true)
                        if callback then callback(v) end
                    end,
                }
            end

            -- ════════════════════════════════════════════════
            -- BUTTON (как в прототипе)
            -- ════════════════════════════════════════════════
            function SecObj:AddButton(label, btnText, callback)
                local r = makeRow(30)
                makeElemLabel(r, label)

                local b = New("TextButton", {
                    BackgroundColor3 = BTN,
                    BorderSizePixel  = 0,
                    Position         = UDim2.new(0.871, 0, 0.166, 0),
                    Size             = UDim2.new(0, 90, 0, 20),
                    Font             = Enum.Font.ArialBold,
                    Text             = btnText or "Click",
                    TextColor3       = WHT,
                    TextSize         = 14,
                    ZIndex           = 5,
                }, r)
                Corner(99, b)

                b.MouseButton1Click:Connect(function()
                    Tween(b, {BackgroundColor3 = ACC, Size = UDim2.new(0, 84, 0, 18)}, 0.08)
                    task.delay(0.15, function()
                        Tween(b, {BackgroundColor3 = BTN, Size = UDim2.new(0, 90, 0, 20)},
                            0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end)
                    if callback then callback() end
                end)
                b.MouseEnter:Connect(function()
                    Tween(b, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, 0.12)
                end)
                b.MouseLeave:Connect(function()
                    Tween(b, {BackgroundColor3 = BTN}, 0.12)
                end)

                resizeSec()
                return {}
            end

            -- ════════════════════════════════════════════════
            -- SLIDER (как в прототипе)
            -- ════════════════════════════════════════════════
            function SecObj:AddSlider(label, minVal, maxVal, default, callback)
                minVal  = minVal  or 0
                maxVal  = maxVal  or 100
                local val  = math.clamp(default or minVal, minVal, maxVal)
                local drag = false
                local r    = makeRow(38)

                -- Название слайдера
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.019, 0, -0.033, 0),
                    Size                   = UDim2.new(0, 200, 0, 30),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = label,
                    TextColor3             = TXT,
                    TextSize               = 14,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 5,
                }, r)

                -- Track (как в прототипе: SlideCount)
                local track = New("Frame", {
                    BackgroundColor3       = WHT,
                    BackgroundTransparency = 0.500,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.168, 0, 0.433, 0),
                    Size                   = UDim2.new(0, 593, 0, 5),
                    ZIndex                 = 5,
                }, r)
                Corner(99, track)

                -- Заполнение (акцент)
                local fill = New("Frame", {
                    BackgroundColor3 = ACC,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(0, 0, 1, 0),
                    ZIndex           = 6,
                }, track)
                Corner(99, fill)
                AccentGradient(fill)

                -- Метки min/max (как в прототипе: Count1, Count2)
                New("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(-0.099, 0, -3.2, 0),
                    Size                   = UDim2.new(0, 50, 0, 35),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = tostring(minVal),
                    TextColor3             = TXT,
                    TextSize               = 12,
                    TextXAlignment         = Enum.TextXAlignment.Right,
                    ZIndex                 = 5,
                }, track)

                New("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(1.011, 0, -3.2, 0),
                    Size                   = UDim2.new(0, 35, 0, 35),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = tostring(maxVal),
                    TextColor3             = TXT,
                    TextSize               = 12,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 5,
                }, track)

                -- Кнопка-ползунок (как в прототипе: SliderButton)
                local thumb = New("TextButton", {
                    BackgroundColor3 = ACC,
                    BorderSizePixel  = 0,
                    Position         = UDim2.new(-0.002, 0, -0.633, 0),
                    Size             = UDim2.new(0, 10, 0, 10),
                    Text             = "",
                    ZIndex           = 7,
                }, track)
                Corner(99, thumb)

                -- Текущее значение (над ползунком)
                local valLbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    AnchorPoint            = Vector2.new(0.5, 1),
                    Position               = UDim2.new(0.5, 0, 0, -2),
                    Size                   = UDim2.new(0, 30, 0, 14),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = tostring(val),
                    TextColor3             = WHT,
                    TextSize               = 10,
                    ZIndex                 = 8,
                }, thumb)

                local function setVal(v)
                    v   = math.clamp(math.floor(v + 0.5), minVal, maxVal)
                    val = v
                    local pct = (v - minVal) / (maxVal - minVal)
                    local tw  = track.AbsoluteSize.X
                    local px  = pct * tw - 5
                    thumb.Position = UDim2.new(0, px, -0.633, 0)
                    fill.Size      = UDim2.new(0, math.max(0, px + 5), 1, 0)
                    valLbl.Text    = tostring(v)
                    if callback then callback(v) end
                end

                local function handleInput(inp)
                    local relX = (inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                    setVal(minVal + (maxVal - minVal) * relX)
                end

                thumb.MouseButton1Down:Connect(function()
                    drag = true
                    Tween(thumb, {Size = UDim2.new(0, 13, 0, 13)}, 0.1, Enum.EasingStyle.Back)
                end)

                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        drag = true
                        handleInput(i)
                        Tween(thumb, {Size = UDim2.new(0, 13, 0, 13)}, 0.1, Enum.EasingStyle.Back)
                    end
                end)

                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 and drag then
                        drag = false
                        Tween(thumb, {Size = UDim2.new(0, 10, 0, 10)}, 0.12, Enum.EasingStyle.Back)
                    end
                end)

                UserInputService.InputChanged:Connect(function(i)
                    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                        handleInput(i)
                    end
                end)

                task.defer(function() setVal(val) end)
                resizeSec()

                return {
                    GetValue = function() return val end,
                    SetValue = function(_, v) setVal(v) end,
                }
            end

            -- ════════════════════════════════════════════════
            -- DROPDOWN (как в прототипе)
            -- ════════════════════════════════════════════════
            function SecObj:AddDropdown(label, values, default, callback)
                local sel    = default or (values[1] or "")
                local isOpen = false
                local r      = makeRow(30)
                makeElemLabel(r, label)

                -- Кнопка дропдауна (как в прототипе: DropdownButton)
                local dbtn = New("TextButton", {
                    BackgroundColor3 = BTN,
                    BorderSizePixel  = 0,
                    Position         = UDim2.new(0.794, 0, 0.166, 0),
                    Size             = UDim2.new(0, 150, 0, 20),
                    Font             = Enum.Font.SourceSans,
                    Text             = "",
                    ZIndex           = 5,
                }, r)
                Corner(99, dbtn)

                -- Текущее значение
                local selLbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.019, 0, 0, 0),
                    Size                   = UDim2.new(0, 115, 1, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = sel,
                    TextColor3             = WHT,
                    TextSize               = 12,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 6,
                }, dbtn)

                -- Иконка стрелки
                local arrow = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.826, 0, 0, 0),
                    Size                   = UDim2.new(0, 20, 1, 0),
                    Image                  = "rbxassetid://127928339372741",
                    ZIndex                 = 6,
                }, dbtn)

                -- Список (крепим к gui чтобы не обрезался)
                local ITEM_H = 24
                local maxH   = math.min(#values, 5) * (ITEM_H + 2) + 6

                local dlist = New("ScrollingFrame", {
                    BackgroundColor3       = BTN,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel        = 0,
                    Size                   = UDim2.new(0, 148, 0, 0),
                    Visible                = false,
                    ScrollBarThickness     = 2,
                    ScrollBarImageColor3   = ACC1,
                    CanvasSize             = UDim2.new(0, 0, 0, #values * (ITEM_H + 2) + 6),
                    ZIndex                 = 100,
                    ClipsDescendants       = true,
                }, gui)
                Corner(5, dlist)

                New("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding   = UDim.new(0, 2),
                }, dlist)
                New("UIPadding", {
                    PaddingTop    = UDim.new(0, 3),
                    PaddingBottom = UDim.new(0, 3),
                    PaddingLeft   = UDim.new(0, 3),
                    PaddingRight  = UDim.new(0, 3),
                }, dlist)

                local itemMap = {}
                for i, v in ipairs(values) do
                    local isSel = (v == sel)
                    local it = New("TextButton", {
                        BackgroundColor3 = isSel and ACC or Color3.fromRGB(20, 20, 20),
                        BorderSizePixel  = 0,
                        Size             = UDim2.new(1, 0, 0, ITEM_H),
                        Font             = Enum.Font.ArialBold,
                        Text             = v,
                        TextColor3       = isSel and WHT or TXT,
                        TextSize         = 12,
                        LayoutOrder      = i,
                        ZIndex           = 101,
                    }, dlist)
                    Corner(5, it)
                    itemMap[v] = it
                end

                local function updateDropPos()
                    local ap = dbtn.AbsolutePosition
                    local as = dbtn.AbsoluteSize
                    dlist.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
                end

                local function openDrop()
                    isOpen = true
                    updateDropPos()
                    dlist.Visible = true
                    dlist.Size    = UDim2.new(0, 148, 0, 0)
                    Tween(dlist, {Size = UDim2.new(0, 148, 0, maxH)},
                        0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    Tween(arrow, {Rotation = 180}, 0.22)
                end

                local function closeDrop()
                    isOpen = false
                    Tween(dlist, {Size = UDim2.new(0, 148, 0, 0)},
                        0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                    Tween(arrow, {Rotation = 0}, 0.18)
                    task.delay(0.2, function() dlist.Visible = false end)
                end

                dbtn.MouseButton1Click:Connect(function()
                    if isOpen then closeDrop() else openDrop() end
                end)
                dbtn.MouseEnter:Connect(function()
                    Tween(dbtn, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, 0.12)
                end)
                dbtn.MouseLeave:Connect(function()
                    Tween(dbtn, {BackgroundColor3 = BTN}, 0.12)
                end)

                for v, it in pairs(itemMap) do
                    local vv, ii = v, it
                    ii.MouseButton1Click:Connect(function()
                        if itemMap[sel] then
                            Tween(itemMap[sel], {BackgroundColor3 = Color3.fromRGB(20,20,20)}, 0.12)
                            itemMap[sel].TextColor3 = TXT
                        end
                        sel          = vv
                        selLbl.Text  = vv
                        Tween(ii, {BackgroundColor3 = ACC}, 0.12)
                        ii.TextColor3 = WHT
                        task.delay(0.12, closeDrop)
                        if callback then callback(vv) end
                    end)
                    ii.MouseEnter:Connect(function()
                        if vv ~= sel then
                            Tween(ii, {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}, 0.1)
                        end
                    end)
                    ii.MouseLeave:Connect(function()
                        if vv ~= sel then
                            Tween(ii, {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}, 0.1)
                        end
                    end)
                end

                -- Закрытие при клике вне
                UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 or not isOpen then return end
                    task.defer(function()
                        local mp = UserInputService:GetMouseLocation()
                        local function inside(f)
                            local p, s = f.AbsolutePosition, f.AbsoluteSize
                            return mp.X >= p.X and mp.X <= p.X + s.X
                               and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
                        end
                        if not inside(dlist) and not inside(dbtn) then closeDrop() end
                    end)
                end)

                resizeSec()
                return {
                    GetValue = function() return sel end,
                    SetValue = function(_, v)
                        if not itemMap[v] then return end
                        if itemMap[sel] then
                            itemMap[sel].BackgroundColor3 = Color3.fromRGB(20,20,20)
                            itemMap[sel].TextColor3 = TXT
                        end
                        sel         = v
                        selLbl.Text = v
                        itemMap[v].BackgroundColor3 = ACC
                        itemMap[v].TextColor3 = WHT
                        if callback then callback(v) end
                    end,
                }
            end

            -- ════════════════════════════════════════════════
            -- MULTI DROPDOWN
            -- ════════════════════════════════════════════════
            function SecObj:AddMultiDropdown(label, values, defaults, callback)
                local selected = {}
                if defaults then
                    for _, v in ipairs(defaults) do selected[v] = true end
                end
                local isOpen = false
                local r = makeRow(30)
                makeElemLabel(r, label)

                local function getSelText()
                    local parts = {}
                    for v, on in pairs(selected) do
                        if on then parts[#parts + 1] = v end
                    end
                    if #parts == 0 then return "None" end
                    if #parts > 2  then return #parts .. " selected" end
                    return table.concat(parts, ", ")
                end

                local dbtn = New("TextButton", {
                    BackgroundColor3 = BTN,
                    BorderSizePixel  = 0,
                    Position         = UDim2.new(0.794, 0, 0.166, 0),
                    Size             = UDim2.new(0, 150, 0, 20),
                    Text             = "",
                    ZIndex           = 5,
                }, r)
                Corner(99, dbtn)

                local selLbl = New("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.019, 0, 0, 0),
                    Size                   = UDim2.new(0, 108, 1, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = getSelText(),
                    TextColor3             = WHT,
                    TextSize               = 11,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 6,
                }, dbtn)

                local arrow = New("ImageLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.826, 0, 0, 0),
                    Size                   = UDim2.new(0, 20, 1, 0),
                    Image                  = "rbxassetid://127928339372741",
                    ZIndex                 = 6,
                }, dbtn)

                local ITEM_H = 26
                local maxH   = math.min(#values, 5) * (ITEM_H + 2) + 6

                local dlist = New("ScrollingFrame", {
                    BackgroundColor3       = BTN,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel        = 0,
                    Size                   = UDim2.new(0, 148, 0, 0),
                    Visible                = false,
                    ScrollBarThickness     = 2,
                    ScrollBarImageColor3   = ACC1,
                    CanvasSize             = UDim2.new(0, 0, 0, #values * (ITEM_H + 2) + 6),
                    ZIndex                 = 100,
                    ClipsDescendants       = true,
                }, gui)
                Corner(5, dlist)

                New("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, dlist)
                New("UIPadding", {
                    PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3),
                    PaddingLeft = UDim.new(0,3), PaddingRight = UDim.new(0,3),
                }, dlist)

                for i, v in ipairs(values) do
                    local isOn = selected[v] == true

                    local fr = New("Frame", {
                        BackgroundColor3 = isOn and ACC or Color3.fromRGB(20,20,20),
                        BorderSizePixel  = 0,
                        Size             = UDim2.new(1, 0, 0, ITEM_H),
                        LayoutOrder      = i,
                        ZIndex           = 101,
                    }, dlist)
                    Corner(5, fr)

                    local lb = New("TextLabel", {
                        BackgroundTransparency = 1,
                        BorderSizePixel        = 0,
                        Position               = UDim2.new(0, 8, 0, 0),
                        Size                   = UDim2.new(1, -28, 1, 0),
                        Font                   = Enum.Font.ArialBold,
                        Text                   = v,
                        TextColor3             = isOn and WHT or TXT,
                        TextSize               = 12,
                        TextXAlignment         = Enum.TextXAlignment.Left,
                        ZIndex                 = 102,
                    }, fr)

                    local ci = New("ImageLabel", {
                        BackgroundTransparency = 1,
                        BorderSizePixel        = 0,
                        AnchorPoint            = Vector2.new(1, 0.5),
                        Position               = UDim2.new(1, -4, 0.5, 0),
                        Size                   = UDim2.new(0, 16, 0, 16),
                        Image                  = "rbxassetid://13753318181",
                        Visible                = isOn,
                        ZIndex                 = 103,
                    }, fr)

                    local hit = New("TextButton", {
                        BackgroundTransparency = 1,
                        BorderSizePixel        = 0,
                        Size                   = UDim2.new(1, 0, 1, 0),
                        Text                   = "",
                        ZIndex                 = 104,
                    }, fr)

                    local vv = v
                    local ff, ll, cc = fr, lb, ci

                    hit.MouseButton1Click:Connect(function()
                        selected[vv] = not selected[vv]
                        local now = selected[vv] == true
                        Tween(ff, {BackgroundColor3 = now and ACC or Color3.fromRGB(20,20,20)}, 0.12)
                        ll.TextColor3 = now and WHT or TXT
                        cc.Visible    = now
                        selLbl.Text   = getSelText()
                        if callback then
                            local list = {}
                            for sv, on in pairs(selected) do
                                if on then list[#list + 1] = sv end
                            end
                            callback(list)
                        end
                    end)

                    hit.MouseEnter:Connect(function()
                        if not selected[vv] then
                            Tween(ff, {BackgroundColor3 = Color3.fromRGB(35,35,35)}, 0.1)
                        end
                    end)
                    hit.MouseLeave:Connect(function()
                        if not selected[vv] then
                            Tween(ff, {BackgroundColor3 = Color3.fromRGB(20,20,20)}, 0.1)
                        end
                    end)
                end

                local function updateDropPos()
                    local ap = dbtn.AbsolutePosition
                    local as = dbtn.AbsoluteSize
                    dlist.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 4)
                end

                local function openDrop()
                    isOpen = true
                    updateDropPos()
                    dlist.Visible = true
                    dlist.Size    = UDim2.new(0, 148, 0, 0)
                    Tween(dlist, {Size = UDim2.new(0, 148, 0, maxH)},
                        0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    Tween(arrow, {Rotation = 180}, 0.22)
                end

                local function closeDrop()
                    isOpen = false
                    Tween(dlist, {Size = UDim2.new(0, 148, 0, 0)},
                        0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                    Tween(arrow, {Rotation = 0}, 0.18)
                    task.delay(0.2, function() dlist.Visible = false end)
                end

                dbtn.MouseButton1Click:Connect(function()
                    if isOpen then closeDrop() else openDrop() end
                end)
                dbtn.MouseEnter:Connect(function()
                    Tween(dbtn, {BackgroundColor3 = Color3.fromRGB(20,20,20)}, 0.12)
                end)
                dbtn.MouseLeave:Connect(function()
                    Tween(dbtn, {BackgroundColor3 = BTN}, 0.12)
                end)

                UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 or not isOpen then return end
                    task.defer(function()
                        local mp = UserInputService:GetMouseLocation()
                        local function inside(f)
                            local p, s = f.AbsolutePosition, f.AbsoluteSize
                            return mp.X >= p.X and mp.X <= p.X + s.X
                               and mp.Y >= p.Y and mp.Y <= p.Y + s.Y
                        end
                        if not inside(dlist) and not inside(dbtn) then closeDrop() end
                    end)
                end)

                resizeSec()
                return {
                    GetValue = function()
                        local list = {}
                        for v, on in pairs(selected) do
                            if on then list[#list + 1] = v end
                        end
                        return list
                    end,
                }
            end

            -- ════════════════════════════════════════════════
            -- COLOR PICKER (как в прототипе)
            -- ════════════════════════════════════════════════
            function SecObj:AddColorPicker(label, defColor, callback)
                local cur = defColor or Color3.fromRGB(255, 255, 255)
                local r   = makeRow(30)
                makeElemLabel(r, label)

                -- Кнопка-превью (как ColorButton в прототипе)
                local prevBtn = New("TextButton", {
                    BackgroundColor3 = cur,
                    BorderSizePixel  = 0,
                    Position         = UDim2.new(0.961, 0, 0.166, 0),
                    Size             = UDim2.new(0, 20, 0, 20),
                    Font             = Enum.Font.SourceSans,
                    Text             = "",
                    ZIndex           = 5,
                }, r)

                local picker = MakeColorPicker(gui, label, cur, prevBtn, function(col)
                    cur = col
                    if callback then callback(col) end
                end)

                prevBtn.MouseButton1Click:Connect(function()
                    picker.Toggle()
                end)

                resizeSec()
                return {
                    GetValue = function() return cur end,
                    SetValue = function(_, col) picker.SetValue(col) end,
                }
            end

            -- ════════════════════════════════════════════════
            -- DIVIDER
            -- ════════════════════════════════════════════════
            function SecObj:AddDivider()
                local wr = makeRow(12)
                local d = New("Frame", {
                    BackgroundColor3       = DIVC,
                    BackgroundTransparency = 0.200,
                    BorderSizePixel        = 0,
                    AnchorPoint            = Vector2.new(0, 0.5),
                    Position               = UDim2.new(0, 10, 0.5, 0),
                    Size                   = UDim2.new(1, -20, 0, 1),
                    ZIndex                 = 5,
                }, wr)
                Corner(99, d)
                resizeSec()
                return {}
            end

            -- ════════════════════════════════════════════════
            -- LABEL
            -- ════════════════════════════════════════════════
            function SecObj:AddLabel(text)
                local wr = makeRow(24)
                local lb = New("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.019, 0, 0, 0),
                    Size                   = UDim2.new(1, -20, 1, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = text,
                    TextColor3             = TXTD,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    TextWrapped            = true,
                    ZIndex                 = 5,
                }, wr)
                resizeSec()
                return {
                    SetText = function(_, t) lb.Text = t end,
                }
            end

            return SecObj
        end -- AddSection

        return TabObj
    end -- AddTab

    -- ═══════════════════════════════════════════════════════════
    -- SETTINGS API
    -- ═══════════════════════════════════════════════════════════

    local settElemCount = 0

    local function settRow(h)
        settElemCount = settElemCount + 1
        return New("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1, 0, 0, h or 30),
            LayoutOrder            = settElemCount,
            ZIndex                 = 12,
        }, settScroll)
    end

    -- Тоггл в настройках (как SettingsToggle1 в прототипе)
    function Win:AddSettingsToggle(label, default, callback)
        local state = (default == true)
        local r = settRow(30)

        New("TextLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0.019, 0, 0, 0),
            Size                   = UDim2.new(0, 96, 1, 0),
            Font                   = Enum.Font.ArialBold,
            Text                   = label,
            TextColor3             = TXT,
            TextSize               = 14,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
        }, r)

        local tbtn = New("TextButton", {
            BackgroundColor3 = state and WHT or BTN,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0.873, 0, 0.166, 0),
            Size             = UDim2.new(0, 20, 0, 20),
            Text             = "",
            ZIndex           = 13,
        }, r)

        local tick = New("ImageLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0.05, 0, 0.05, 0),
            Size                   = UDim2.new(0, 17, 0, 17),
            Image                  = "rbxassetid://13753318181",
            Visible                = state,
            ZIndex                 = 14,
        }, tbtn)

        local function refresh(anim)
            Tween(tbtn, {BackgroundColor3 = state and WHT or BTN}, anim and 0.18 or 0)
            tick.Visible = state
        end

        tbtn.MouseButton1Click:Connect(function()
            state = not state
            refresh(true)
            Tween(tbtn, {Size = UDim2.new(0,17,0,17)}, 0.07, Enum.EasingStyle.Quad)
            task.delay(0.07, function()
                Tween(tbtn, {Size = UDim2.new(0,20,0,20)},
                    0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)
            if callback then callback(state) end
        end)

        updateSettCanvas()
        return {
            GetValue = function() return state end,
            SetValue = function(_, v) state = v; refresh(true) end,
        }
    end

    -- Кнопка в настройках (как SettingsButton1 в прототипе)
    function Win:AddSettingsButton(text, callback)
        local r = settRow(34)
        local b = New("TextButton", {
            BackgroundColor3 = BTN,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0.161, 0, 0.1, 0),
            Size             = UDim2.new(0, 160, 0, 25),
            Font             = Enum.Font.ArialBold,
            Text             = text,
            TextColor3       = WHT,
            TextSize         = 14,
            ZIndex           = 13,
        }, r)
        Corner(99, b)

        b.MouseButton1Click:Connect(function()
            Tween(b, {BackgroundColor3 = ACC}, 0.08)
            task.delay(0.2, function()
                Tween(b, {BackgroundColor3 = BTN}, 0.15)
            end)
            if callback then callback() end
        end)
        b.MouseEnter:Connect(function()
            Tween(b, {BackgroundColor3 = Color3.fromRGB(20,20,20)}, 0.12)
        end)
        b.MouseLeave:Connect(function()
            Tween(b, {BackgroundColor3 = BTN}, 0.12)
        end)

        updateSettCanvas()
        return {}
    end

    -- Разделитель в настройках (как SettingsDivider1 в прототипе)
    function Win:AddSettingsDivider()
        local r = settRow(12)
        local d = New("Frame", {
            BackgroundColor3       = DIVC,
            BackgroundTransparency = 0.200,
            BorderSizePixel        = 0,
            AnchorPoint            = Vector2.new(0, 0.5),
            Position               = UDim2.new(0, 0, 0.5, 0),
            Size                   = UDim2.new(1, 0, 0, 2),
            ZIndex                 = 13,
        }, r)
        Corner(99, d)
        updateSettCanvas()
        return {}
    end

    -- Колорпикер в настройках
    function Win:AddSettingsColorPicker(label, defColor, callback)
        local cur = defColor or Color3.fromRGB(255, 255, 255)
        local r   = settRow(30)

        New("TextLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0.019, 0, 0, 0),
            Size                   = UDim2.new(0.7, 0, 1, 0),
            Font                   = Enum.Font.ArialBold,
            Text                   = label,
            TextColor3             = TXT,
            TextSize               = 14,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
        }, r)

        local prevBtn = New("TextButton", {
            BackgroundColor3 = cur,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0.873, 0, 0.166, 0),
            Size             = UDim2.new(0, 20, 0, 20),
            Text             = "",
            ZIndex           = 13,
        }, r)

        local picker = MakeColorPicker(gui, label, cur, prevBtn, function(col)
            cur = col
            if callback then callback(col) end
        end)

        prevBtn.MouseButton1Click:Connect(function()
            picker.Toggle()
        end)

        updateSettCanvas()
        return {
            GetValue = function() return cur end,
            SetValue = function(_, col) picker.SetValue(col) end,
        }
    end

    -- ── Анимация появления окна ───────────────────────────────
    main.Size = UDim2.new(0, 805, 0, 0)
    task.defer(function()
        Tween(main, {Size = UDim2.new(0, 805, 0, 483)},
            0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    return Win
end

return Library
