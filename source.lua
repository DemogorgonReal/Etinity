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

local Util = {}

function Util.Tween(obj, props, duration, style, direction)
    style     = style     or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local t   = TweenService:Create(obj, TweenInfo.new(duration or 0.3, style, direction), props)
    t:Play()
    return t
end

function Util.Make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

function Util.Corner(radius, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

function Util.HueGradient(parent)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0,   0)),
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,   255, 0)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,   255, 255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,   0,   255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0,   255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0,   0)),
    }
    g.Parent = parent
    return g
end

function Util.AccentGradient(parent)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(66,  183, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(181, 249, 255)),
    }
    g.Parent = parent
    return g
end

function Util.Color3ToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5))
end

function Util.HexToColor3(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

-- Безопасный твин: пропускает только реальные свойства объекта
function Util.SafeTween(obj, props, duration, style, direction)
    local safe = {}
    for k, v in pairs(props) do
        local ok = pcall(function() return obj[k] end)
        if ok then safe[k] = v end
    end
    if next(safe) then
        Util.Tween(obj, safe, duration, style, direction)
    end
end

-- Плавное появление группы объектов (только нужные свойства)
function Util.FadeIn(descendants, duration)
    for _, obj in ipairs(descendants) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            Util.Tween(obj, {TextTransparency = 0}, duration or 0.25)
        end
        if obj:IsA("ImageLabel") then
            Util.Tween(obj, {ImageTransparency = 0}, duration or 0.25)
        end
    end
end

function Util.FadeOut(descendants, duration)
    for _, obj in ipairs(descendants) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            Util.Tween(obj, {TextTransparency = 1}, duration or 0.2)
        end
        if obj:IsA("ImageLabel") then
            Util.Tween(obj, {ImageTransparency = 1}, duration or 0.2)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- КОНСТАНТЫ ДИЗАЙНА
-- ═══════════════════════════════════════════════════════════════

local C = {
    BG          = Color3.fromRGB(2,   2,   2),
    Container   = Color3.fromRGB(11,  11,  11),
    Button      = Color3.fromRGB(0,   0,   0),
    ButtonHover = Color3.fromRGB(20,  20,  20),
    Text        = Color3.fromRGB(188, 188, 188),
    TextDim     = Color3.fromRGB(108, 108, 108),
    TextSection = Color3.fromRGB(49,  49,  49),
    White       = Color3.fromRGB(255, 255, 255),
    Accent1     = Color3.fromRGB(66,  183, 255),
    Accent2     = Color3.fromRGB(181, 249, 255),
    TabActive   = Color3.fromRGB(83,  203, 255),
    Divider     = Color3.fromRGB(29,  29,  29),
    CloseRed    = Color3.fromRGB(180, 50,  50),
}

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION (отдельный ScreenGui, глобальный)
-- ═══════════════════════════════════════════════════════════════

local NotifGui = Util.Make("ScreenGui", {
    Name          = "EtinityNotifications",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn  = false,
}, LocalPlayer:WaitForChild("PlayerGui"))

local NotifQueue   = {}
local NotifShowing = false

local function ProcessNotifQueue()
    if #NotifQueue == 0 then
        NotifShowing = false
        return
    end
    NotifShowing = true
    local data = table.remove(NotifQueue, 1)

    -- Контейнер уведомления
    local nc = Util.Make("Frame", {
        BackgroundColor3      = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.3,
        BorderSizePixel       = 0,
        Position              = UDim2.new(1.05, 0, 0.015, 0),
        Size                  = UDim2.new(0, 250, 0, 70),
        ZIndex                = 50,
    }, NotifGui)
    Util.Corner(15, nc)

    -- Акцентная полоска сверху
    local bar = Util.Make("Frame", {
        BackgroundColor3 = C.Accent1,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 0),
        Size             = UDim2.new(1, 0, 0, 2),
        ZIndex           = 51,
    }, nc)
    Util.Corner(99, bar)
    Util.AccentGradient(bar)

    Util.Make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 10, 0.085, 0),
        Size                   = UDim2.new(0, 210, 0, 20),
        Font                   = Enum.Font.ArialBold,
        Text                   = data.title,
        TextColor3             = C.White,
        TextSize               = 18,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 51,
    }, nc)

    Util.Make("Frame", {
        BackgroundColor3 = C.White,
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.457, 0),
        Size             = UDim2.new(1, 0, 0, 2),
        ZIndex           = 51,
    }, nc)

    Util.Make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 12, 0.485, 0),
        Size                   = UDim2.new(0, 226, 0, 36),
        Font                   = Enum.Font.ArialBold,
        Text                   = data.subtitle,
        TextColor3             = C.Text,
        TextSize               = 12,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextYAlignment         = Enum.TextYAlignment.Top,
        TextWrapped            = true,
        ZIndex                 = 51,
    }, nc)

    local closeBtn = Util.Make("TextButton", {
        BackgroundColor3       = Color3.fromRGB(11,11,11),
        BackgroundTransparency = 0.6,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.884, 0, 0.084, 0),
        Size                   = UDim2.new(0, 20, 0, 20),
        Font                   = Enum.Font.FredokaOne,
        Text                   = "X",
        TextColor3             = Color3.fromRGB(189,189,189),
        TextSize               = 16,
        ZIndex                 = 52,
    }, nc)
    Util.Corner(99, closeBtn)

    local dismissed = false
    local targetPos = UDim2.new(0.807, 0, 0.015, 0)

    local function Dismiss()
        if dismissed then return end
        dismissed = true
        Util.Tween(nc, {Position = UDim2.new(1.05, 0, 0.015, 0), BackgroundTransparency = 0.8}, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.4, function()
            nc:Destroy()
            task.delay(0.2, ProcessNotifQueue)
        end)
    end

    closeBtn.MouseButton1Click:Connect(Dismiss)
    closeBtn.MouseEnter:Connect(function() Util.Tween(closeBtn, {BackgroundTransparency = 0.2}, 0.1) end)
    closeBtn.MouseLeave:Connect(function() Util.Tween(closeBtn, {BackgroundTransparency = 0.6}, 0.1) end)

    Util.Tween(nc, {Position = targetPos, BackgroundTransparency = 0.3}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.delay(data.duration or 4, Dismiss)
end

-- ═══════════════════════════════════════════════════════════════
-- COLOR PICKER (переиспользуемая функция)
-- ═══════════════════════════════════════════════════════════════

local function CreateColorPicker(screenGui, labelText, defaultColor, colorPreviewBtn, onChanged)
    local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
    local pH, pS, pV   = Color3.toHSV(currentColor)
    local pickerOpen   = false
    local svDrag       = false
    local hueDrag      = false

    -- Панель пикера
    local panel = Util.Make("Frame", {
        BackgroundColor3       = Color3.fromRGB(18, 18, 18),
        BackgroundTransparency = 0,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 220, 0, 232),
        Visible                = false,
        ZIndex                 = 200,
        ClipsDescendants       = false,
    }, screenGui)
    Util.Corner(14, panel)

    -- Заголовок
    Util.Make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 12, 0, 6),
        Size                   = UDim2.new(1, -40, 0, 24),
        Font                   = Enum.Font.ArialBold,
        Text                   = labelText,
        TextColor3             = C.Text,
        TextSize               = 14,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 201,
    }, panel)

    -- Кнопка закрытия
    local closeBtn = Util.Make("TextButton", {
        BackgroundColor3 = Color3.fromRGB(11,11,11),
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -26, 0, 5),
        Size             = UDim2.new(0, 20, 0, 20),
        Font             = Enum.Font.FredokaOne,
        Text             = "X",
        TextColor3       = Color3.fromRGB(189,189,189),
        TextSize         = 14,
        ZIndex           = 201,
    }, panel)
    Util.Corner(99, closeBtn)

    -- SV-поле (Saturation + Value)
    local svField = Util.Make("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 10, 0, 34),
        Size             = UDim2.new(1, -20, 0, 130),
        ZIndex           = 201,
        ClipsDescendants = true,
    }, panel)
    Util.Corner(6, svField)

    -- Белый градиент слева направо (saturation)
    local svWhite = Util.Make("Frame", {
        BackgroundColor3 = C.White,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 202,
    }, svField)
    Util.Corner(6, svWhite)
    local svWhiteGrad = Instance.new("UIGradient")
    svWhiteGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
    }
    svWhiteGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    }
    svWhiteGrad.Parent = svWhite

    -- Чёрный градиент снизу (value)
    local svBlack = Util.Make("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 1, 0),
        ZIndex           = 203,
    }, svField)
    Util.Corner(6, svBlack)
    local svBlackGrad = Instance.new("UIGradient")
    svBlackGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
    }
    svBlackGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    }
    svBlackGrad.Rotation = 90
    svBlackGrad.Parent = svBlack

    -- Кликабельный оверлей поверх SV
    local svClick = Util.Make("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        Text                   = "",
        ZIndex                 = 205,
    }, svField)

    -- Курсор SV
    local svCursor = Util.Make("Frame", {
        BackgroundColor3 = C.White,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(pS, 0, 1 - pV, 0),
        Size             = UDim2.new(0, 12, 0, 12),
        ZIndex           = 206,
    }, svField)
    Util.Corner(99, svCursor)

    -- Обводка курсора
    Util.Make("Frame", {
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = UDim2.new(1, 2, 1, 2),
        ZIndex           = 205,
    }, svCursor)
    Util.Corner(99, svCursor:FindFirstChildOfClass("Frame"))

    -- Hue-слайдер
    local hueTrack = Util.Make("Frame", {
        BackgroundColor3 = C.White,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 10, 0, 174),
        Size             = UDim2.new(1, -20, 0, 12),
        ZIndex           = 201,
    }, panel)
    Util.Corner(99, hueTrack)
    Util.HueGradient(hueTrack)

    local hueClick = Util.Make("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        Text                   = "",
        ZIndex                 = 203,
    }, hueTrack)

    local hueCursor = Util.Make("Frame", {
        BackgroundColor3 = C.White,
        BorderSizePixel  = 2,
        BorderColor3     = Color3.fromRGB(0,0,0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(pH, 0, 0.5, 0),
        Size             = UDim2.new(0, 14, 0, 18),
        ZIndex           = 204,
    }, hueTrack)
    Util.Corner(4, hueCursor)

    -- Превью цвета
    local preview = Util.Make("Frame", {
        BackgroundColor3 = currentColor,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 10, 0, 196),
        Size             = UDim2.new(0, 80, 0, 26),
        ZIndex           = 201,
    }, panel)
    Util.Corner(6, preview)

    -- HEX-поле
    local hexBox = Util.Make("TextBox", {
        BackgroundColor3 = Color3.fromRGB(11,11,11),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 98, 0, 196),
        Size             = UDim2.new(1, -108, 0, 26),
        Font             = Enum.Font.ArialBold,
        Text             = Util.Color3ToHex(currentColor),
        TextColor3       = C.Text,
        TextSize         = 11,
        ZIndex           = 201,
        ClearTextOnFocus = false,
        PlaceholderText  = "#FFFFFF",
    }, panel)
    Util.Corner(6, hexBox)

    -- ── Внутренняя логика ──────────────────────────────────────

    local function GetColor()
        return Color3.fromHSV(pH, pS, pV)
    end

    local function UpdateUI()
        local pureHue = Color3.fromHSV(pH, 1, 1)
        local color   = GetColor()

        svField.BackgroundColor3  = pureHue
        svCursor.Position         = UDim2.new(pS, 0, 1 - pV, 0)
        hueCursor.Position        = UDim2.new(pH, 0, 0.5, 0)
        preview.BackgroundColor3  = color
        hexBox.Text               = Util.Color3ToHex(color)
        colorPreviewBtn.BackgroundColor3 = color

        currentColor = color
        if onChanged then onChanged(color) end
    end

    local function HandleSV(input)
        local rel = svField.AbsolutePosition
        local sz  = svField.AbsoluteSize
        pS = math.clamp((input.Position.X - rel.X) / sz.X, 0, 1)
        pV = 1 - math.clamp((input.Position.Y - rel.Y) / sz.Y, 0, 1)
        UpdateUI()
    end

    local function HandleHue(input)
        local rel = hueTrack.AbsolutePosition
        local sz  = hueTrack.AbsoluteSize
        pH = math.clamp((input.Position.X - rel.X) / sz.X, 0, 1)
        UpdateUI()
    end

    svClick.MouseButton1Down:Connect(function()
        svDrag = true
    end)
    svClick.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = true
            HandleSV(i)
        end
    end)

    hueClick.MouseButton1Down:Connect(function()
        hueDrag = true
    end)
    hueClick.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDrag = true
            HandleHue(i)
        end
    end)

    local inputChangedConn = UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if svDrag  then HandleSV(i)  end
        if hueDrag then HandleHue(i) end
    end)

    local inputEndedConn = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag  = false
            hueDrag = false
        end
    end)

    hexBox.FocusLost:Connect(function()
        local col = Util.HexToColor3(hexBox.Text)
        if col then
            pH, pS, pV = Color3.toHSV(col)
            UpdateUI()
        else
            hexBox.Text = Util.Color3ToHex(currentColor)
        end
    end)

    -- ── Открытие / закрытие ──────────────────────────────────

    local function Open()
        pickerOpen = true
        -- Восстанавливаем текущий цвет
        pH, pS, pV = Color3.toHSV(currentColor)

        -- Позиционируем
        local btnAbs = colorPreviewBtn.AbsolutePosition
        local vp     = workspace.CurrentCamera.ViewportSize
        local px     = math.clamp(btnAbs.X - 230, 0, vp.X - 225)
        local py     = math.clamp(btnAbs.Y - 245, 0, vp.Y - 238)

        panel.Position             = UDim2.new(0, px, 0, py)
        panel.BackgroundTransparency = 1
        panel.Visible              = true

        Util.Tween(panel, {BackgroundTransparency = 0}, 0.2)
        UpdateUI()
    end

    local function Close()
        pickerOpen = false
        Util.Tween(panel, {BackgroundTransparency = 1}, 0.18)
        task.delay(0.2, function()
            panel.Visible = false
        end)
    end

    closeBtn.MouseButton1Click:Connect(Close)

    -- Закрытие при клике вне
    local outsideConn
    outsideConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not pickerOpen then return end
        task.defer(function()
            local mp = UserInputService:GetMouseLocation()

            local function Inside(f)
                return mp.X >= f.AbsolutePosition.X
                   and mp.X <= f.AbsolutePosition.X + f.AbsoluteSize.X
                   and mp.Y >= f.AbsolutePosition.Y
                   and mp.Y <= f.AbsolutePosition.Y + f.AbsoluteSize.Y
            end

            if not Inside(panel) and not Inside(colorPreviewBtn) then
                Close()
            end
        end)
    end)

    -- API
    return {
        Open  = Open,
        Close = Close,
        IsOpen = function() return pickerOpen end,
        GetValue = function() return currentColor end,
        SetValue = function(color)
            currentColor = color
            colorPreviewBtn.BackgroundColor3 = color
            pH, pS, pV = Color3.toHSV(color)
            if onChanged then onChanged(color) end
        end,
        Toggle = function()
            if pickerOpen then Close() else Open() end
        end,
    }
end

-- ═══════════════════════════════════════════════════════════════
-- ГЛАВНАЯ БИБЛИОТЕКА
-- ═══════════════════════════════════════════════════════════════

local Library = {}
Library.__index = Library

function Library:Notify(title, subtitle, duration)
    table.insert(NotifQueue, {title = title or "", subtitle = subtitle or "", duration = duration or 4})
    if not NotifShowing then
        ProcessNotifQueue()
    end
end

function Library:CreateWindow(options)
    options = options or {}
    local winTitle    = options.Title    or "Etinity"
    local winSubtitle = options.Subtitle or "V1.0"
    local winIcon     = options.Icon     or "rbxassetid://130210005937854"

    -- ── ScreenGui ──────────────────────────────────────────────
    local ScreenGui = Util.Make("ScreenGui", {
        Name            = "EtinityLibrary",
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn    = false,
    }, LocalPlayer:WaitForChild("PlayerGui"))

    -- ── MainContainer ──────────────────────────────────────────
    local Main = Util.Make("Frame", {
        Name                   = "MainContainer",
        BackgroundColor3       = C.BG,
        BackgroundTransparency = 0.1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.205, 0, 0.218, 0),
        Size                   = UDim2.new(0, 805, 0, 483),
        ClipsDescendants       = false,
    }, ScreenGui)
    Util.Corner(15, Main)

    -- ── Icon ───────────────────────────────────────────────────
    local IconImg = Util.Make("ImageLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 28, 0, 14),
        Size                   = UDim2.new(0, 36, 0, 36),
        Image                  = winIcon,
        ZIndex                 = 2,
    }, Main)
    Util.AccentGradient(IconImg)

    -- ── Title ──────────────────────────────────────────────────
    local TitleLbl = Util.Make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 70, 0, 18),
        Size                   = UDim2.new(0, 140, 0, 27),
        Font                   = Enum.Font.ArialBold,
        Text                   = winTitle,
        TextColor3             = C.White,
        TextSize               = 20,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 2,
    }, Main)
    Util.AccentGradient(TitleLbl)

    -- ── Subtitle ───────────────────────────────────────────────
    Util.Make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 72, 0, 44),
        Size                   = UDim2.new(0, 100, 0, 16),
        Font                   = Enum.Font.ArialBold,
        Text                   = winSubtitle,
        TextColor3             = C.TextDim,
        TextSize               = 10,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 2,
    }, Main)

    -- ── Divider ────────────────────────────────────────────────
    local divider = Util.Make("Frame", {
        BackgroundColor3 = C.White,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 64),
        Size             = UDim2.new(1, 0, 0, 2),
        ZIndex           = 2,
    }, Main)
    Util.AccentGradient(divider)

    -- ── Close Button ───────────────────────────────────────────
    local CloseBtn = Util.Make("TextButton", {
        BackgroundColor3 = C.Container,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -50, 0, 14),
        Size             = UDim2.new(0, 36, 0, 36),
        Font             = Enum.Font.FredokaOne,
        Text             = "X",
        TextColor3       = Color3.fromRGB(189,189,189),
        TextSize         = 16,
        ZIndex           = 3,
    }, Main)
    Util.Corner(99, CloseBtn)

    -- ── Settings Button ────────────────────────────────────────
    local SettingsBtn = Util.Make("TextButton", {
        BackgroundColor3 = C.Container,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -92, 0, 14),
        Size             = UDim2.new(0, 36, 0, 36),
        Font             = Enum.Font.FredokaOne,
        Text             = "",
        ZIndex           = 3,
    }, Main)
    Util.Corner(99, SettingsBtn)

    local SettingsIcon = Util.Make("ImageLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 6, 0, 6),
        Size                   = UDim2.new(0, 23, 0, 23),
        Image                  = "rbxassetid://7059346373",
        ImageColor3            = Color3.fromRGB(189,189,189),
        ZIndex                 = 4,
    }, SettingsBtn)

    -- ── Tabs Container ─────────────────────────────────────────
    local TabsOuter = Util.Make("Frame", {
        BackgroundColor3       = C.Container,
        BackgroundTransparency = 0.3,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 160, 0, 14),
        Size                   = UDim2.new(1, -310, 0, 36),
        ClipsDescendants       = true,
        ZIndex                 = 2,
    }, Main)
    Util.Corner(20, TabsOuter)

    local TabsScroll = Util.Make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness     = 0,
        ScrollingDirection     = Enum.ScrollingDirection.X,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        ClipsDescendants       = true,
        ZIndex                 = 2,
    }, TabsOuter)

    local TabsLayout = Util.Make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0, 0),
    }, TabsScroll)

    -- ── Content Area ───────────────────────────────────────────
    local ContentArea = Util.Make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0, 66),
        Size                   = UDim2.new(1, 0, 1, -66),
        ClipsDescendants       = true,
        ZIndex                 = 1,
    }, Main)

    -- ── Settings Panel ─────────────────────────────────────────
    local SettingsPanel = Util.Make("Frame", {
        BackgroundColor3       = C.BG,
        BackgroundTransparency = 0.1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 261, 0, 483),
        Visible                = false,
        ZIndex                 = 10,
        ClipsDescendants       = true,
    }, ScreenGui)
    Util.Corner(15, SettingsPanel)

    local SettingsInner = Util.Make("Frame", {
        BackgroundColor3       = C.Container,
        BackgroundTransparency = 0.2,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 12, 0, 11),
        Size                   = UDim2.new(1, -24, 1, -22),
        ZIndex                 = 11,
    }, SettingsPanel)
    Util.Corner(15, SettingsInner)

    Util.Make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 36),
        Font                   = Enum.Font.ArialBold,
        Text                   = "Settings",
        TextColor3             = C.Text,
        TextSize               = 18,
        ZIndex                 = 12,
    }, SettingsInner)

    local SettingsScroll = Util.Make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0, 0, 0, 40),
        Size                   = UDim2.new(1, 0, 1, -40),
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = C.Accent1,
        ZIndex                 = 12,
    }, SettingsInner)

    local SettingsLayout = Util.Make("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
    }, SettingsScroll)

    Util.Make("UIPadding", {
        PaddingTop    = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft   = UDim.new(0, 6),
        PaddingRight  = UDim.new(0, 6),
    }, SettingsScroll)

    local function UpdateSettingsCanvas()
        task.defer(function()
            SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, SettingsLayout.AbsoluteContentSize.Y + 8)
        end)
    end

    -- ── Dragging ───────────────────────────────────────────────
    local dragging, dragStart, startPos = false, nil, nil

    local DragZone = Util.Make("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(1, 0, 0, 64),
        ZIndex                 = 2,
    }, Main)

    DragZone.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos  = Main.Position
        end
    end)
    DragZone.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local function SyncSettingsPos()
        SettingsPanel.Position = UDim2.new(0,
            Main.AbsolutePosition.X + Main.AbsoluteSize.X + 8,
            0,
            Main.AbsolutePosition.Y)
    end

    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                      startPos.Y.Scale, startPos.Y.Offset + d.Y)
            if SettingsPanel.Visible then SyncSettingsPos() end
        end
    end)

    -- ── Close Logic ────────────────────────────────────────────
    CloseBtn.MouseButton1Click:Connect(function()
        Util.Tween(Main, {
            Size                   = UDim2.new(0, 805, 0, 0),
            BackgroundTransparency = 1,
        }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.35, function()
            ScreenGui:Destroy()
        end)
    end)
    CloseBtn.MouseEnter:Connect(function()
        Util.Tween(CloseBtn, {BackgroundColor3 = C.CloseRed, TextColor3 = C.White}, 0.15)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Util.Tween(CloseBtn, {BackgroundColor3 = C.Container, TextColor3 = Color3.fromRGB(189,189,189)}, 0.15)
    end)

    -- ── Settings Open/Close ────────────────────────────────────
    local settingsOpen = false

    local function OpenSettings()
        settingsOpen = true
        SyncSettingsPos()
        SettingsPanel.Size    = UDim2.new(0, 0, 0, 483)
        SettingsPanel.Visible = true
        Util.Tween(SettingsPanel, {Size = UDim2.new(0, 261, 0, 483)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Util.Tween(SettingsIcon, {Rotation = 90}, 0.3)
    end

    local function CloseSettings()
        settingsOpen = false
        Util.Tween(SettingsPanel, {Size = UDim2.new(0, 0, 0, 483)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        Util.Tween(SettingsIcon, {Rotation = 0}, 0.25)
        task.delay(0.27, function() SettingsPanel.Visible = false end)
    end

    SettingsBtn.MouseButton1Click:Connect(function()
        if settingsOpen then CloseSettings() else OpenSettings() end
    end)
    SettingsBtn.MouseEnter:Connect(function()
        Util.Tween(SettingsBtn, {BackgroundColor3 = Color3.fromRGB(25,25,25)}, 0.15)
        if not settingsOpen then Util.Tween(SettingsIcon, {Rotation = 30}, 0.2) end
    end)
    SettingsBtn.MouseLeave:Connect(function()
        Util.Tween(SettingsBtn, {BackgroundColor3 = C.Container}, 0.15)
        if not settingsOpen then Util.Tween(SettingsIcon, {Rotation = 0}, 0.2) end
    end)

    -- ═══════════════════════════════════════════════════════════
    -- WINDOW OBJECT
    -- ═══════════════════════════════════════════════════════════

    local Window = {}  -- просто таблица, без метатаблиц-циклов
    Window._tabs        = {}
    Window._currentTab  = nil
    Window._settingsIdx = 0

    -- ── Tab Selection ──────────────────────────────────────────
    local function SelectTab(tabData)
        if Window._currentTab == tabData then return end

        -- Скрываем предыдущий
        if Window._currentTab then
            local prev = Window._currentTab
            -- Анимируем индикатор
            Util.Tween(prev._indicator, {BackgroundTransparency = 1}, 0.2)
            Util.Tween(prev._button, {BackgroundTransparency = 1}, 0.2)
            -- Скрываем контент
            Util.FadeOut(prev._scroll:GetDescendants(), 0.15)
            task.delay(0.18, function()
                prev._indicator.Visible = false
                prev._scroll.Visible    = false
            end)
        end

        Window._currentTab = tabData

        -- Активируем кнопку
        Util.Tween(tabData._button, {BackgroundTransparency = 0}, 0.2)
        tabData._indicator.Visible = true
        Util.Tween(tabData._indicator, {BackgroundTransparency = 0.1}, 0.2)

        -- Показываем контент
        tabData._scroll.Visible = true
        Util.FadeIn(tabData._scroll:GetDescendants(), 0.2)
    end

    -- ── AddTab ─────────────────────────────────────────────────
    function Window:AddTab(name)
        local tabData = {}

        -- Кнопка таба
        local tabBtn = Util.Make("TextButton", {
            BackgroundColor3       = C.TabActive,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(0, 103, 1, 0),
            Font                   = Enum.Font.ArialBold,
            Text                   = name,
            TextColor3             = C.White,
            TextSize               = 14,
            ZIndex                 = 3,
            LayoutOrder            = #Window._tabs + 1,
        }, TabsScroll)
        Util.Corner(20, tabBtn)

        -- Индикатор (полоска снизу)
        local indicator = Util.Make("Frame", {
            BackgroundColor3       = C.TabActive,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0.135, 0, 1, 2),
            Size                   = UDim2.new(0, 75, 0, 2),
            Visible                = false,
            ZIndex                 = 4,
        }, tabBtn)
        Util.Corner(99, indicator)
        Util.AccentGradient(indicator)

        tabData._button    = tabBtn
        tabData._indicator = indicator

        -- Обновляем CanvasSize
        task.defer(function()
            TabsScroll.CanvasSize = UDim2.new(0, TabsLayout.AbsoluteContentSize.X, 0, 0)
        end)

        -- ScrollingFrame для секций этого таба
        local scroll = Util.Make("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0, 13, 0, 8),
            Size                   = UDim2.new(1, -26, 1, -16),
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = C.Accent1,
            Visible                = false,
            ZIndex                 = 2,
        }, ContentArea)

        local scrollLayout = Util.Make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 10),
        }, scroll)

        local function UpdateScrollCanvas()
            task.defer(function()
                scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 16)
            end)
        end

        tabData._scroll        = scroll
        tabData._scrollLayout  = scrollLayout
        tabData._sectionCount  = 0

        -- Hover
        tabBtn.MouseEnter:Connect(function()
            if Window._currentTab ~= tabData then
                Util.Tween(tabBtn, {BackgroundTransparency = 0.7}, 0.15)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._currentTab ~= tabData then
                Util.Tween(tabBtn, {BackgroundTransparency = 1}, 0.15)
            end
        end)
        tabBtn.MouseButton1Click:Connect(function()
            SelectTab(tabData)
        end)

        table.insert(Window._tabs, tabData)
        if #Window._tabs == 1 then
            SelectTab(tabData)
        end

        -- ── AddSection ─────────────────────────────────────────
        function tabData:AddSection(sectionName)
            tabData._sectionCount = tabData._sectionCount + 1

            local Section      = {}
            Section._elemCount = 0

            -- Фрейм секции
            local secFrame = Util.Make("Frame", {
                BackgroundColor3       = C.Container,
                BackgroundTransparency = 0.1,
                BorderSizePixel        = 0,
                Size                   = UDim2.new(1, 0, 0, 50),
                LayoutOrder            = tabData._sectionCount,
                ZIndex                 = 3,
            }, scroll)
            Util.Corner(15, secFrame)

            -- Заголовок секции
            Util.Make("TextLabel", {
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.new(0, 15, 0, 6),
                Size                   = UDim2.new(0, 200, 0, 22),
                Font                   = Enum.Font.ArialBold,
                Text                   = sectionName,
                TextColor3             = C.TextSection,
                TextSize               = 20,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ZIndex                 = 4,
            }, secFrame)

            -- Layout элементов внутри секции
            local elemLayout = Util.Make("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 0),
            }, secFrame)

            Util.Make("UIPadding", {
                PaddingTop    = UDim.new(0, 34),
                PaddingBottom = UDim.new(0, 8),
            }, secFrame)

            local function ResizeSection()
                task.defer(function()
                    local h = elemLayout.AbsoluteContentSize.Y
                    secFrame.Size = UDim2.new(1, 0, 0, h + 42)
                    UpdateScrollCanvas()
                end)
            end

            -- ── ЭЛЕМЕНТЫ ──────────────────────────────────────

            -- Общая функция создания строки элемента
            local function MakeRow(height)
                Section._elemCount = Section._elemCount + 1
                local row = Util.Make("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Size                   = UDim2.new(1, 0, 0, height or 30),
                    LayoutOrder            = Section._elemCount,
                    ZIndex                 = 4,
                }, secFrame)
                return row
            end

            local function MakeLabel(parent, text, posX, width)
                return Util.Make("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0, posX or 15, 0, 0),
                    Size                   = UDim2.new(0, width or 200, 1, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = text,
                    TextColor3             = C.Text,
                    TextSize               = 14,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 5,
                }, parent)
            end

            -- ── Toggle ──────────────────────────────────────
            function Section:AddToggle(label, default, callback)
                local state = (default == true)
                local row   = MakeRow(30)
                MakeLabel(row, label)

                local toggleBtn = Util.Make("TextButton", {
                    BackgroundColor3 = state and C.White or C.Button,
                    BorderSizePixel  = 0,
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, -15, 0.5, 0),
                    Size             = UDim2.new(0, 20, 0, 20),
                    Text             = "",
                    ZIndex           = 5,
                }, row)
                Util.Corner(4, toggleBtn)

                local checkIcon = Util.Make("ImageLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0.05, 0, 0.05, 0),
                    Size                   = UDim2.new(0, 17, 0, 17),
                    Image                  = "rbxassetid://13753318181",
                    Visible                = state,
                    ZIndex                 = 6,
                }, toggleBtn)

                local function Refresh(animated)
                    local d = animated and 0.18 or 0
                    Util.Tween(toggleBtn, {BackgroundColor3 = state and C.White or C.Button}, d)
                    checkIcon.Visible = state
                end

                toggleBtn.MouseButton1Click:Connect(function()
                    state = not state
                    Refresh(true)
                    Util.Tween(toggleBtn, {Size = UDim2.new(0, 17, 0, 17)}, 0.07, Enum.EasingStyle.Quad)
                    task.delay(0.07, function()
                        Util.Tween(toggleBtn, {Size = UDim2.new(0, 20, 0, 20)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end)
                    if callback then callback(state) end
                end)
                toggleBtn.MouseEnter:Connect(function() Util.Tween(toggleBtn, {BackgroundTransparency = 0.15}, 0.1) end)
                toggleBtn.MouseLeave:Connect(function() Util.Tween(toggleBtn, {BackgroundTransparency = 0},    0.1) end)

                ResizeSection()
                return {
                    GetValue = function()    return state end,
                    SetValue = function(_, v)
                        state = v
                        Refresh(true)
                        if callback then callback(state) end
                    end,
                }
            end

            -- ── Button ──────────────────────────────────────
            function Section:AddButton(label, btnText, callback)
                local row = MakeRow(30)
                MakeLabel(row, label)

                local btn = Util.Make("TextButton", {
                    BackgroundColor3 = C.Button,
                    BorderSizePixel  = 0,
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, -15, 0.5, 0),
                    Size             = UDim2.new(0, 90, 0, 22),
                    Font             = Enum.Font.ArialBold,
                    Text             = btnText or "Click",
                    TextColor3       = C.White,
                    TextSize         = 13,
                    ZIndex           = 5,
                }, row)
                Util.Corner(99, btn)

                btn.MouseButton1Click:Connect(function()
                    Util.Tween(btn, {BackgroundColor3 = C.Accent1, Size = UDim2.new(0, 84, 0, 20)}, 0.08)
                    task.delay(0.15, function()
                        Util.Tween(btn, {BackgroundColor3 = C.Button, Size = UDim2.new(0, 90, 0, 22)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end)
                    if callback then callback() end
                end)
                btn.MouseEnter:Connect(function() Util.Tween(btn, {BackgroundColor3 = C.ButtonHover}, 0.12) end)
                btn.MouseLeave:Connect(function() Util.Tween(btn, {BackgroundColor3 = C.Button},      0.12) end)

                ResizeSection()
                return {}
            end

            -- ── Slider ──────────────────────────────────────
            function Section:AddSlider(label, minVal, maxVal, default, callback)
                minVal  = minVal  or 0
                maxVal  = maxVal  or 100
                local value   = math.clamp(default or minVal, minVal, maxVal)
                local slDrag  = false
                local row     = MakeRow(38)

                MakeLabel(row, label, 15, 120)

                -- Метки
                Util.Make("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0, 135, 0, 0),
                    Size                   = UDim2.new(0, 40, 0.7, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = tostring(minVal),
                    TextColor3             = C.TextDim,
                    TextSize               = 11,
                    TextXAlignment         = Enum.TextXAlignment.Right,
                    ZIndex                 = 5,
                }, row)
                Util.Make("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    AnchorPoint            = Vector2.new(1, 0),
                    Position               = UDim2.new(1, -10, 0, 0),
                    Size                   = UDim2.new(0, 40, 0.7, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = tostring(maxVal),
                    TextColor3             = C.TextDim,
                    TextSize               = 11,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 5,
                }, row)

                -- Track
                local track = Util.Make("Frame", {
                    BackgroundColor3       = C.White,
                    BackgroundTransparency = 0.7,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0, 178, 0.5, -3),
                    Size                   = UDim2.new(1, -198, 0, 6),
                    ZIndex                 = 5,
                }, row)
                Util.Corner(99, track)

                -- Fill
                local fill = Util.Make("Frame", {
                    BackgroundColor3 = C.Accent1,
                    BorderSizePixel  = 0,
                    Size             = UDim2.new(0, 0, 1, 0),
                    ZIndex           = 6,
                }, track)
                Util.Corner(99, fill)
                Util.AccentGradient(fill)

                -- Thumb
                local thumb = Util.Make("TextButton", {
                    BackgroundColor3 = C.White,
                    BorderSizePixel  = 0,
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = UDim2.new(0, 0, 0.5, 0),
                    Size             = UDim2.new(0, 13, 0, 13),
                    Text             = "",
                    ZIndex           = 7,
                }, track)
                Util.Corner(99, thumb)

                -- Значение над thumb
                local valLbl = Util.Make("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    AnchorPoint            = Vector2.new(0.5, 1),
                    Position               = UDim2.new(0.5, 0, 0, -1),
                    Size                   = UDim2.new(0, 36, 0, 14),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = tostring(value),
                    TextColor3             = C.Accent1,
                    TextSize               = 10,
                    ZIndex                 = 8,
                }, thumb)

                local function SetValue(val)
                    val   = math.clamp(math.floor(val + 0.5), minVal, maxVal)
                    value = val
                    local pct = (val - minVal) / (maxVal - minVal)
                    local tw  = track.AbsoluteSize.X
                    thumb.Position = UDim2.new(0, pct * tw, 0.5, 0)
                    fill.Size      = UDim2.new(0, pct * tw, 1, 0)
                    valLbl.Text    = tostring(val)
                    if callback then callback(val) end
                end

                local function HandleInput(input)
                    local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                    SetValue(minVal + (maxVal - minVal) * rel)
                end

                thumb.MouseButton1Down:Connect(function()
                    slDrag = true
                    Util.Tween(thumb, {Size = UDim2.new(0, 16, 0, 16)}, 0.1, Enum.EasingStyle.Back)
                end)
                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        slDrag = true
                        HandleInput(i)
                        Util.Tween(thumb, {Size = UDim2.new(0, 16, 0, 16)}, 0.1, Enum.EasingStyle.Back)
                    end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 and slDrag then
                        slDrag = false
                        Util.Tween(thumb, {Size = UDim2.new(0, 13, 0, 13)}, 0.12, Enum.EasingStyle.Back)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if slDrag and i.UserInputType == Enum.UserInputType.MouseMovement then
                        HandleInput(i)
                    end
                end)

                task.defer(function() SetValue(value) end)
                ResizeSection()

                return {
                    GetValue = function()    return value end,
                    SetValue = function(_, v) SetValue(v) end,
                }
            end

            -- ── Dropdown ────────────────────────────────────
            function Section:AddDropdown(label, values, default, callback)
                local selected = default or (values[1] or "")
                local dropOpen = false
                local row      = MakeRow(30)

                MakeLabel(row, label)

                local dropBtn = Util.Make("TextButton", {
                    BackgroundColor3 = C.Button,
                    BorderSizePixel  = 0,
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, -15, 0.5, 0),
                    Size             = UDim2.new(0, 150, 0, 22),
                    Text             = "",
                    ZIndex           = 5,
                }, row)
                Util.Corner(99, dropBtn)

                local valLbl = Util.Make("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0, 10, 0, 0),
                    Size                   = UDim2.new(0, 110, 1, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = selected,
                    TextColor3             = C.White,
                    TextSize               = 12,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 6,
                }, dropBtn)

                local arrow = Util.Make("ImageLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    AnchorPoint            = Vector2.new(1, 0.5),
                    Position               = UDim2.new(1, -4, 0.5, 0),
                    Size                   = UDim2.new(0, 18, 0, 18),
                    Image                  = "rbxassetid://127928339372741",
                    ZIndex                 = 6,
                }, dropBtn)

                -- Список (крепим к ScreenGui)
                local dropList = Util.Make("ScrollingFrame", {
                    BackgroundColor3       = Color3.fromRGB(14,14,14),
                    BackgroundTransparency = 0,
                    BorderSizePixel        = 0,
                    Size                   = UDim2.new(0, 150, 0, 0),
                    Visible                = false,
                    ScrollBarThickness     = 2,
                    ScrollBarImageColor3   = C.Accent1,
                    CanvasSize             = UDim2.new(0, 0, 0, 0),
                    ZIndex                 = 100,
                    ClipsDescendants       = true,
                }, ScreenGui)
                Util.Corner(8, dropList)

                local listLayout = Util.Make("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding   = UDim.new(0, 2),
                }, dropList)
                Util.Make("UIPadding", {
                    PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3),
                    PaddingLeft = UDim.new(0,3), PaddingRight = UDim.new(0,3),
                }, dropList)

                local itemMap = {}
                local ITEM_H  = 24

                for i, val in ipairs(values) do
                    local isSel = (val == selected)
                    local item  = Util.Make("TextButton", {
                        BackgroundColor3 = isSel and C.Accent1 or Color3.fromRGB(22,22,22),
                        BorderSizePixel  = 0,
                        Size             = UDim2.new(1, 0, 0, ITEM_H),
                        Font             = Enum.Font.ArialBold,
                        Text             = val,
                        TextColor3       = isSel and C.White or C.Text,
                        TextSize         = 12,
                        LayoutOrder      = i,
                        ZIndex           = 101,
                    }, dropList)
                    Util.Corner(5, item)
                    itemMap[val] = item
                end

                local maxH = math.min(#values, 5) * (ITEM_H + 2) + 6
                dropList.CanvasSize = UDim2.new(0, 0, 0, #values * (ITEM_H + 2) + 6)

                local function UpdateDropPos()
                    local abs = dropBtn.AbsolutePosition
                    local sz  = dropBtn.AbsoluteSize
                    dropList.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
                end

                local function OpenDrop()
                    dropOpen = true
                    UpdateDropPos()
                    dropList.Visible = true
                    dropList.Size    = UDim2.new(0, 150, 0, 0)
                    Util.Tween(dropList, {Size = UDim2.new(0, 150, 0, maxH)}, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    Util.Tween(arrow, {Rotation = 180}, 0.22)
                end

                local function CloseDrop()
                    dropOpen = false
                    Util.Tween(dropList, {Size = UDim2.new(0, 150, 0, 0)}, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                    Util.Tween(arrow, {Rotation = 0}, 0.18)
                    task.delay(0.2, function() dropList.Visible = false end)
                end

                dropBtn.MouseButton1Click:Connect(function()
                    if dropOpen then CloseDrop() else OpenDrop() end
                end)
                dropBtn.MouseEnter:Connect(function() Util.Tween(dropBtn, {BackgroundColor3 = C.ButtonHover}, 0.12) end)
                dropBtn.MouseLeave:Connect(function() Util.Tween(dropBtn, {BackgroundColor3 = C.Button},      0.12) end)

                for val, item in pairs(itemMap) do
                    local v, it = val, item
                    it.MouseButton1Click:Connect(function()
                        if itemMap[selected] then
                            Util.Tween(itemMap[selected], {BackgroundColor3 = Color3.fromRGB(22,22,22)}, 0.12)
                            itemMap[selected].TextColor3 = C.Text
                        end
                        selected     = v
                        valLbl.Text  = v
                        Util.Tween(it, {BackgroundColor3 = C.Accent1}, 0.12)
                        it.TextColor3 = C.White
                        task.delay(0.12, CloseDrop)
                        if callback then callback(v) end
                    end)
                    it.MouseEnter:Connect(function()
                        if v ~= selected then Util.Tween(it, {BackgroundColor3 = Color3.fromRGB(35,35,35)}, 0.1) end
                    end)
                    it.MouseLeave:Connect(function()
                        if v ~= selected then Util.Tween(it, {BackgroundColor3 = Color3.fromRGB(22,22,22)}, 0.1) end
                    end)
                end

                -- Клик вне
                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not dropOpen then return end
                    task.defer(function()
                        local mp = UserInputService:GetMouseLocation()
                        local function In(f)
                            return mp.X >= f.AbsolutePosition.X and mp.X <= f.AbsolutePosition.X + f.AbsoluteSize.X
                               and mp.Y >= f.AbsolutePosition.Y and mp.Y <= f.AbsolutePosition.Y + f.AbsoluteSize.Y
                        end
                        if not In(dropList) and not In(dropBtn) then CloseDrop() end
                    end)
                end)

                ResizeSection()
                return {
                    GetValue = function() return selected end,
                    SetValue = function(_, v)
                        if not itemMap[v] then return end
                        if itemMap[selected] then
                            itemMap[selected].BackgroundColor3 = Color3.fromRGB(22,22,22)
                            itemMap[selected].TextColor3 = C.Text
                        end
                        selected = v
                        valLbl.Text = v
                        itemMap[v].BackgroundColor3 = C.Accent1
                        itemMap[v].TextColor3 = C.White
                        if callback then callback(v) end
                    end,
                }
            end

            -- ── MultiDropdown ────────────────────────────────
            function Section:AddMultiDropdown(label, values, defaults, callback)
                local selected = {}
                if defaults then
                    for _, v in ipairs(defaults) do selected[v] = true end
                end
                local dropOpen = false
                local row      = MakeRow(30)

                MakeLabel(row, label)

                local function SelText()
                    local parts = {}
                    for v in pairs(selected) do table.insert(parts, v) end
                    if #parts == 0 then return "None"
                    elseif #parts > 2 then return #parts .. " selected"
                    else return table.concat(parts, ", ") end
                end

                local dropBtn = Util.Make("TextButton", {
                    BackgroundColor3 = C.Button,
                    BorderSizePixel  = 0,
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, -15, 0.5, 0),
                    Size             = UDim2.new(0, 150, 0, 22),
                    Text             = "",
                    ZIndex           = 5,
                }, row)
                Util.Corner(99, dropBtn)

                local valLbl = Util.Make("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0, 10, 0, 0),
                    Size                   = UDim2.new(0, 108, 1, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = SelText(),
                    TextColor3             = C.White,
                    TextSize               = 11,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 6,
                }, dropBtn)

                local arrow = Util.Make("ImageLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    AnchorPoint            = Vector2.new(1, 0.5),
                    Position               = UDim2.new(1, -4, 0.5, 0),
                    Size                   = UDim2.new(0, 18, 0, 18),
                    Image                  = "rbxassetid://127928339372741",
                    ZIndex                 = 6,
                }, dropBtn)

                local dropList = Util.Make("ScrollingFrame", {
                    BackgroundColor3   = Color3.fromRGB(14,14,14),
                    BackgroundTransparency = 0,
                    BorderSizePixel    = 0,
                    Size               = UDim2.new(0, 150, 0, 0),
                    Visible            = false,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = C.Accent1,
                    CanvasSize         = UDim2.new(0, 0, 0, 0),
                    ZIndex             = 100,
                    ClipsDescendants   = true,
                }, ScreenGui)
                Util.Corner(8, dropList)

                Util.Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,2)}, dropList)
                Util.Make("UIPadding", {PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,3),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3)}, dropList)

                local ITEM_H = 26
                local maxH   = math.min(#values, 5) * (ITEM_H + 2) + 6
                dropList.CanvasSize = UDim2.new(0, 0, 0, #values * (ITEM_H + 2) + 6)

                for i, val in ipairs(values) do
                    local isSel = selected[val] == true

                    local itemFrame = Util.Make("Frame", {
                        BackgroundColor3 = isSel and C.Accent1 or Color3.fromRGB(22,22,22),
                        BorderSizePixel  = 0,
                        Size             = UDim2.new(1, 0, 0, ITEM_H),
                        LayoutOrder      = i,
                        ZIndex           = 101,
                    }, dropList)
                    Util.Corner(5, itemFrame)

                    local itemLbl = Util.Make("TextLabel", {
                        BackgroundTransparency = 1,
                        BorderSizePixel        = 0,
                        Position               = UDim2.new(0, 8, 0, 0),
                        Size                   = UDim2.new(1, -32, 1, 0),
                        Font                   = Enum.Font.ArialBold,
                        Text                   = val,
                        TextColor3             = isSel and C.White or C.Text,
                        TextSize               = 12,
                        TextXAlignment         = Enum.TextXAlignment.Left,
                        ZIndex                 = 102,
                    }, itemFrame)

                    local checkImg = Util.Make("ImageLabel", {
                        BackgroundTransparency = 1,
                        BorderSizePixel        = 0,
                        AnchorPoint            = Vector2.new(1, 0.5),
                        Position               = UDim2.new(1, -4, 0.5, 0),
                        Size                   = UDim2.new(0, 16, 0, 16),
                        Image                  = "rbxassetid://13753318181",
                        Visible                = isSel,
                        ZIndex                 = 103,
                    }, itemFrame)

                    local itemBtn = Util.Make("TextButton", {
                        BackgroundTransparency = 1,
                        BorderSizePixel        = 0,
                        Size                   = UDim2.new(1, 0, 1, 0),
                        Text                   = "",
                        ZIndex                 = 104,
                    }, itemFrame)

                    local v  = val
                    local fr = itemFrame
                    local lb = itemLbl
                    local ci = checkImg

                    itemBtn.MouseButton1Click:Connect(function()
                        selected[v] = not selected[v]
                        local on = selected[v]
                        Util.Tween(fr, {BackgroundColor3 = on and C.Accent1 or Color3.fromRGB(22,22,22)}, 0.12)
                        lb.TextColor3 = on and C.White or C.Text
                        ci.Visible    = on
                        valLbl.Text   = SelText()
                        if callback then
                            local list = {}
                            for sv in pairs(selected) do table.insert(list, sv) end
                            callback(list)
                        end
                    end)
                    itemBtn.MouseEnter:Connect(function()
                        if not selected[v] then Util.Tween(fr, {BackgroundColor3 = Color3.fromRGB(35,35,35)}, 0.1) end
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        if not selected[v] then Util.Tween(fr, {BackgroundColor3 = Color3.fromRGB(22,22,22)}, 0.1) end
                    end)
                end

                local function UpdateDropPos()
                    local abs = dropBtn.AbsolutePosition
                    local sz  = dropBtn.AbsoluteSize
                    dropList.Position = UDim2.new(0, abs.X, 0, abs.Y + sz.Y + 4)
                end

                local function OpenDrop()
                    dropOpen = true; UpdateDropPos()
                    dropList.Visible = true; dropList.Size = UDim2.new(0, 150, 0, 0)
                    Util.Tween(dropList, {Size = UDim2.new(0, 150, 0, maxH)}, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    Util.Tween(arrow, {Rotation = 180}, 0.22)
                end
                local function CloseDrop()
                    dropOpen = false
                    Util.Tween(dropList, {Size = UDim2.new(0, 150, 0, 0)}, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                    Util.Tween(arrow, {Rotation = 0}, 0.18)
                    task.delay(0.2, function() dropList.Visible = false end)
                end

                dropBtn.MouseButton1Click:Connect(function()
                    if dropOpen then CloseDrop() else OpenDrop() end
                end)
                dropBtn.MouseEnter:Connect(function() Util.Tween(dropBtn, {BackgroundColor3 = C.ButtonHover}, 0.12) end)
                dropBtn.MouseLeave:Connect(function() Util.Tween(dropBtn, {BackgroundColor3 = C.Button},      0.12) end)

                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not dropOpen then return end
                    task.defer(function()
                        local mp = UserInputService:GetMouseLocation()
                        local function In(f)
                            return mp.X >= f.AbsolutePosition.X and mp.X <= f.AbsolutePosition.X + f.AbsoluteSize.X
                               and mp.Y >= f.AbsolutePosition.Y and mp.Y <= f.AbsolutePosition.Y + f.AbsoluteSize.Y
                        end
                        if not In(dropList) and not In(dropBtn) then CloseDrop() end
                    end)
                end)

                ResizeSection()
                return {
                    GetValue = function()
                        local list = {}
                        for v in pairs(selected) do table.insert(list, v) end
                        return list
                    end,
                }
            end

            -- ── ColorPicker ──────────────────────────────────
            function Section:AddColorPicker(label, defaultColor, callback)
                local curColor = defaultColor or Color3.fromRGB(255, 255, 255)
                local row      = MakeRow(30)
                MakeLabel(row, label)

                local previewBtn = Util.Make("TextButton", {
                    BackgroundColor3 = curColor,
                    BorderSizePixel  = 0,
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, -15, 0.5, 0),
                    Size             = UDim2.new(0, 22, 0, 22),
                    Text             = "",
                    ZIndex           = 5,
                }, row)
                Util.Corner(5, previewBtn)

                -- Обводка
                local outline = Util.Make("Frame", {
                    BackgroundColor3       = C.White,
                    BackgroundTransparency = 0.6,
                    BorderSizePixel        = 0,
                    AnchorPoint            = Vector2.new(0.5, 0.5),
                    Position               = UDim2.new(0.5, 0, 0.5, 0),
                    Size                   = UDim2.new(1, 4, 1, 4),
                    ZIndex                 = 4,
                }, previewBtn)
                Util.Corner(6, outline)

                local picker = CreateColorPicker(ScreenGui, label, curColor, previewBtn, function(col)
                    curColor = col
                    if callback then callback(col) end
                end)

                previewBtn.MouseButton1Click:Connect(function()
                    picker.Toggle()
                end)
                previewBtn.MouseEnter:Connect(function()
                    Util.Tween(outline, {BackgroundTransparency = 0.3}, 0.12)
                end)
                previewBtn.MouseLeave:Connect(function()
                    Util.Tween(outline, {BackgroundTransparency = 0.6}, 0.12)
                end)

                ResizeSection()
                return {
                    GetValue = function()    return curColor end,
                    SetValue = function(_, col) picker.SetValue(col) end,
                }
            end

            -- ── Divider ──────────────────────────────────────
            function Section:AddDivider()
                local wrapper = MakeRow(12)
                local div = Util.Make("Frame", {
                    BackgroundColor3       = C.Divider,
                    BackgroundTransparency = 0.2,
                    BorderSizePixel        = 0,
                    AnchorPoint            = Vector2.new(0, 0.5),
                    Position               = UDim2.new(0, 10, 0.5, 0),
                    Size                   = UDim2.new(1, -20, 0, 1),
                    ZIndex                 = 5,
                }, wrapper)
                Util.Corner(99, div)
                ResizeSection()
                return {}
            end

            -- ── Label ────────────────────────────────────────
            function Section:AddLabel(text)
                local row = MakeRow(24)
                local lbl = Util.Make("TextLabel", {
                    BackgroundTransparency = 1,
                    BorderSizePixel        = 0,
                    Position               = UDim2.new(0, 15, 0, 0),
                    Size                   = UDim2.new(1, -20, 1, 0),
                    Font                   = Enum.Font.ArialBold,
                    Text                   = text,
                    TextColor3             = C.TextDim,
                    TextSize               = 13,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    TextWrapped            = true,
                    ZIndex                 = 5,
                }, row)
                ResizeSection()
                return {
                    SetText = function(_, t) lbl.Text = t end,
                }
            end

            return Section
        end -- AddSection

        return tabData
    end -- AddTab

    -- ═══════════════════════════════════════════════════════════
    -- SETTINGS API
    -- ═══════════════════════════════════════════════════════════

    local settingsElemCount = 0

    local function SettingsRow(height)
        settingsElemCount = settingsElemCount + 1
        local row = Util.Make("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Size                   = UDim2.new(1, 0, 0, height or 30),
            LayoutOrder            = settingsElemCount,
            ZIndex                 = 12,
        }, SettingsScroll)
        return row
    end

    function Window:AddSettingsToggle(label, default, callback)
        local state = (default == true)
        local row   = SettingsRow(30)

        Util.Make("TextLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0, 10, 0, 0),
            Size                   = UDim2.new(0.7, 0, 1, 0),
            Font                   = Enum.Font.ArialBold,
            Text                   = label,
            TextColor3             = C.Text,
            TextSize               = 14,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
        }, row)

        local toggleBtn = Util.Make("TextButton", {
            BackgroundColor3 = state and C.White or C.Button,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -8, 0.5, 0),
            Size             = UDim2.new(0, 20, 0, 20),
            Text             = "",
            ZIndex           = 13,
        }, row)
        Util.Corner(4, toggleBtn)

        local checkIcon = Util.Make("ImageLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0.05, 0, 0.05, 0),
            Size                   = UDim2.new(0, 17, 0, 17),
            Image                  = "rbxassetid://13753318181",
            Visible                = state,
            ZIndex                 = 14,
        }, toggleBtn)

        local function Refresh(anim)
            Util.Tween(toggleBtn, {BackgroundColor3 = state and C.White or C.Button}, anim and 0.18 or 0)
            checkIcon.Visible = state
        end

        toggleBtn.MouseButton1Click:Connect(function()
            state = not state
            Refresh(true)
            Util.Tween(toggleBtn, {Size = UDim2.new(0,17,0,17)}, 0.07)
            task.delay(0.07, function()
                Util.Tween(toggleBtn, {Size = UDim2.new(0,20,0,20)}, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end)
            if callback then callback(state) end
        end)

        UpdateSettingsCanvas()
        return {
            GetValue = function()    return state end,
            SetValue = function(_, v) state = v; Refresh(true) end,
        }
    end

    function Window:AddSettingsButton(text, callback)
        local row = SettingsRow(34)
        local btn = Util.Make("TextButton", {
            BackgroundColor3 = C.Button,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.new(0.5, 0, 0.5, 0),
            Size             = UDim2.new(0.85, 0, 0, 26),
            Font             = Enum.Font.ArialBold,
            Text             = text,
            TextColor3       = C.White,
            TextSize         = 13,
            ZIndex           = 13,
        }, row)
        Util.Corner(99, btn)

        btn.MouseButton1Click:Connect(function()
            Util.Tween(btn, {BackgroundColor3 = C.Accent1}, 0.08)
            task.delay(0.2, function() Util.Tween(btn, {BackgroundColor3 = C.Button}, 0.15) end)
            if callback then callback() end
        end)
        btn.MouseEnter:Connect(function() Util.Tween(btn, {BackgroundColor3 = C.ButtonHover}, 0.12) end)
        btn.MouseLeave:Connect(function() Util.Tween(btn, {BackgroundColor3 = C.Button},      0.12) end)

        UpdateSettingsCanvas()
        return {}
    end

    function Window:AddSettingsDivider()
        local row = SettingsRow(12)
        local div = Util.Make("Frame", {
            BackgroundColor3       = C.Divider,
            BackgroundTransparency = 0.2,
            BorderSizePixel        = 0,
            AnchorPoint            = Vector2.new(0, 0.5),
            Position               = UDim2.new(0, 6, 0.5, 0),
            Size                   = UDim2.new(1, -12, 0, 1),
            ZIndex                 = 13,
        }, row)
        Util.Corner(99, div)
        UpdateSettingsCanvas()
        return {}
    end

    function Window:AddSettingsColorPicker(label, defaultColor, callback)
        local curColor = defaultColor or Color3.fromRGB(255, 255, 255)
        local row      = SettingsRow(30)

        Util.Make("TextLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            Position               = UDim2.new(0, 10, 0, 0),
            Size                   = UDim2.new(0.7, 0, 1, 0),
            Font                   = Enum.Font.ArialBold,
            Text                   = label,
            TextColor3             = C.Text,
            TextSize               = 14,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
        }, row)

        local previewBtn = Util.Make("TextButton", {
            BackgroundColor3 = curColor,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -8, 0.5, 0),
            Size             = UDim2.new(0, 22, 0, 22),
            Text             = "",
            ZIndex           = 13,
        }, row)
        Util.Corner(5, previewBtn)

        local picker = CreateColorPicker(ScreenGui, label, curColor, previewBtn, function(col)
            curColor = col
            if callback then callback(col) end
        end)

        previewBtn.MouseButton1Click:Connect(function()
            picker.Toggle()
        end)

        UpdateSettingsCanvas()
        return {
            GetValue = function()    return curColor end,
            SetValue = function(_, col) picker.SetValue(col) end,
        }
    end

    -- ── Начальная анимация ─────────────────────────────────────
    Main.Size = UDim2.new(0, 805, 0, 0)

    task.defer(function()
        Util.Tween(Main, {Size = UDim2.new(0, 805, 0, 483)}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    return Window
end

return Library
