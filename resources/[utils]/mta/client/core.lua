---- Developer by git@camargo2019

---@alias Widget table
---@alias Clip number[]

local SHIM = "mtax_guicompat"
local VERSION = "1.0.0"

local function Bail(Reason)
    if type(outputDebugString) == "function" then
        outputDebugString("[" .. SHIM .. "] NOT LOADED: " .. Reason, 2)
    end
end

if type(guiCreateWindow) == "function" then
    Bail("guiCreateWindow already exists as a global. This MTAX build appears to provide a real " ..
         "GUI, so the emulation layer stands down. Remove " .. SHIM .. " from client_files.")
    return
end

if type(rawget(_G, "mtaxGuiCompat")) == "table" then
    Bail("already loaded in this VM (mtaxGuiCompat exists). core.lua must appear exactly once " ..
         "in client_files.")
    return
end

if type(rawget(_G, "mtaxGuiCompat")) ~= "nil" then
    Bail("the global 'mtaxGuiCompat' is taken by something that is not this shim.")
    return
end

local REQUIRED = {
    "outputDebugString", "getTickCount",
    "createElement", "destroyElement", "isElement", "getElementID",
    "getElementType", "setElementParent", "getRootElement", "getResourceRootElement",
    "getThisResource", "getResourceName",
    "addEvent", "addEventHandler", "removeEventHandler", "triggerEvent",
    "getScreenSize", "isCursorShowing", "getCursorPosition", "getKeyState",
    "dxDrawRectangle", "dxDrawText", "dxDrawImage", "dxDrawImageSection",
    "dxGetTextWidth", "dxGetFontHeight", "dxCreateFont", "dxCreateTexture",
    "dxGetMaterialSize",
}

local Missing = nil

for Index = 1, #REQUIRED do
    if type(rawget(_G, REQUIRED[Index])) ~= "function" then
        Missing = (Missing and (Missing .. ", ") or "") .. REQUIRED[Index]
    end
end

if Missing then
    Bail("this VM is missing the MTAX function(s) the shim is built on: " .. Missing ..
         ". The shim is CLIENT-ONLY; make sure it is listed in client_files and never in " ..
         "server_files or shared_files.")
    return
end

local RESERVED = {
    "guiCreateFont", "guiSetInputEnabled", "guiGetInputEnabled",
    "guiSetInputMode", "guiGetInputMode", "guiGetCursorType",
    "guiSetVisible", "guiGetVisible", "guiSetEnabled", "guiGetEnabled",
    "guiSetAlpha", "guiGetAlpha", "guiSetPosition", "guiGetPosition",
    "guiSetSize", "guiGetSize", "guiSetText", "guiGetText",
    "guiSetFont", "guiGetFont", "guiBringToFront", "guiMoveToBack",
    "guiSetProperty", "guiGetProperty", "guiGetProperties", "guiFocus", "guiBlur",
    "guiCreateWindow", "guiWindowSetMovable", "guiWindowSetSizable",
    "guiWindowIsMovable", "guiWindowIsSizable",
    "guiCreateLabel", "guiLabelSetColor", "guiLabelGetColor",
    "guiLabelSetVerticalAlign", "guiLabelSetHorizontalAlign",
    "guiLabelGetTextExtent", "guiLabelGetFontHeight",
    "guiCreateButton",
    "guiCreateStaticImage", "guiStaticImageLoadImage", "guiStaticImageGetNativeSize",
    "guiCreateEdit", "guiEditSetCaretIndex", "guiEditGetCaretIndex",
    "guiEditSetCaratIndex", "guiEditSetMasked", "guiEditIsMasked",
    "guiEditSetMaxLength", "guiEditGetMaxLength", "guiEditSetReadOnly",
    "guiEditIsReadOnly",
    "guiCreateMemo", "guiMemoSetCaretIndex", "guiMemoGetCaretIndex",
    "guiMemoSetCaratIndex", "guiMemoSetReadOnly", "guiMemoIsReadOnly",
    "guiMemoSetVerticalScrollPosition", "guiMemoGetVerticalScrollPosition",
    "guiCreateCheckBox", "guiCheckBoxSetSelected", "guiCheckBoxGetSelected",
    "guiCreateRadioButton", "guiRadioButtonSetSelected", "guiRadioButtonGetSelected",
    "guiCreateProgressBar", "guiProgressBarSetProgress", "guiProgressBarGetProgress",
    "guiCreateScrollBar", "guiScrollBarSetScrollPosition", "guiScrollBarGetScrollPosition",
    "guiCreateScrollPane", "guiScrollPaneSetScrollBars",
    "guiScrollPaneSetHorizontalScrollPosition", "guiScrollPaneGetHorizontalScrollPosition",
    "guiScrollPaneSetVerticalScrollPosition", "guiScrollPaneGetVerticalScrollPosition",
    "guiCreateGridList", "guiGridListSetSortingEnabled", "guiGridListIsSortingEnabled",
    "guiGridListAddColumn", "guiGridListRemoveColumn", "guiGridListSetColumnWidth",
    "guiGridListGetColumnWidth", "guiGridListSetColumnTitle", "guiGridListGetColumnTitle",
    "guiGridListSetScrollBars", "guiGridListGetRowCount", "guiGridListGetColumnCount",
    "guiGridListAddRow", "guiGridListInsertRowAfter", "guiGridListRemoveRow",
    "guiGridListAutoSizeColumn", "guiGridListClear", "guiGridListSetItemText",
    "guiGridListGetItemText", "guiGridListSetItemData", "guiGridListGetItemData",
    "guiGridListSetItemColor", "guiGridListGetItemColor", "guiGridListSetSelectionMode",
    "guiGridListGetSelectionMode", "guiGridListGetSelectedItem", "guiGridListGetSelectedItems",
    "guiGridListGetSelectedCount", "guiGridListSetSelectedItem",
    "guiGridListSetHorizontalScrollPosition", "guiGridListGetHorizontalScrollPosition",
    "guiGridListSetVerticalScrollPosition", "guiGridListGetVerticalScrollPosition",
    "guiCreateComboBox", "guiComboBoxAddItem", "guiComboBoxRemoveItem", "guiComboBoxClear",
    "guiComboBoxGetSelected", "guiComboBoxSetSelected", "guiComboBoxGetItemText",
    "guiComboBoxSetItemText", "guiComboBoxGetItemCount", "guiComboBoxSetOpen",
    "guiComboBoxIsOpen",
    "guiCreateTabPanel", "guiCreateTab", "guiGetSelectedTab", "guiSetSelectedTab",
    "guiDeleteTab",
    "guiCreateBrowser", "guiGetBrowser",
}

local Taken = nil

for Index = 1, #RESERVED do
    if rawget(_G, RESERVED[Index]) ~= nil then
        Taken = (Taken and (Taken .. ", ") or "") .. RESERVED[Index]
    end
end

if Taken then
    Bail("refusing to define anything because these globals already exist: " .. Taken ..
         ". The shim never shadows a real MTAX global.")
    return
end

local NOutputDebugString      = outputDebugString
local NGetTickCount           = getTickCount
local NCreateElement          = createElement
local NDestroyElement         = destroyElement
local NIsElement              = isElement
local NGetElementID           = getElementID
local NGetElementType         = getElementType
local NSetElementParent       = setElementParent
local NGetRootElement         = getRootElement
local NGetResourceRootElement = getResourceRootElement
local NGetThisResource        = getThisResource
local NGetResourceName        = getResourceName
local NAddEvent               = addEvent
local NAddEventHandler        = addEventHandler
local NRemoveEventHandler     = removeEventHandler
local NTriggerEvent           = triggerEvent
local NGetScreenSize          = getScreenSize
local NIsCursorShowing        = isCursorShowing
local NGetCursorPosition      = getCursorPosition
local NGetKeyState            = getKeyState
local NDxDrawRectangle        = dxDrawRectangle
local NDxDrawText             = dxDrawText
local NDxDrawImage            = dxDrawImage
local NDxDrawImageSection     = dxDrawImageSection
local NDxGetTextWidth         = dxGetTextWidth
local NDxGetFontHeight        = dxGetFontHeight
local NDxCreateFont           = dxCreateFont
local NDxCreateTexture        = dxCreateTexture
local NDxGetMaterialSize      = dxGetMaterialSize
local NSetClipboard           = type(setClipboard) == "function" and setClipboard or nil
local NFileExists             = type(fileExists) == "function" and fileExists or nil

local Floor, Min, Max, Abs = math.floor, math.min, math.max, math.abs
local Sub, Remove = string.sub, table.remove
local Utf8 = utf8

local ID_PREFIX = "mtaxgui#"
local CLICK_TOLERANCE = 6
local FONT_PX_PER_UNIT = 1.75

local GUI_EVENTS = {
    "onClientGUIClick",
    "onClientGUIDoubleClick",
    "onClientGUIMouseDown",
    "onClientGUIMouseUp",
    "onClientGUIScroll",
    "onClientGUIChanged",
    "onClientGUIAccepted",
    "onClientGUITabSwitched",
    "onClientGUIComboBoxAccepted",
    "onClientGUIMove",
    "onClientGUISize",
    "onClientGUIFocus",
    "onClientGUIBlur",
    "onClientMouseEnter",
    "onClientMouseLeave",
    "onClientMouseMove",
}

local VALID_INPUT_MODES = {
    allow_binds = true,
    no_binds = true,
    no_binds_when_editing = true,
}

local INPUT_MODE_WARNING =
    "guiSetInputMode / guiSetInputEnabled cannot do on MTAX what they do on MTA. MTA suppresses " ..
    "key binds while a GUI edit box has focus; MTAX dispatches every key to bindKey and " ..
    "onClientKey before any Lua handler can object, and cancelEvent on onClientKey is IGNORED. " ..
    "The shim only records the mode so guiGetInputMode round-trips. Typing into a shim edit box " ..
    "WILL still trigger the player's binds. If you need the game to stop responding, call " ..
    "toggleAllControls(false) yourself while the panel is open."

local _MTAX = {}

_MTAX.__index = _MTAX

function _MTAX:New()
    local Instance = setmetatable({}, self)
    return Instance
end

--- Diagnostics

function _MTAX:Unsupported(What, Why)
    if self.UnsupportedSeen[What] then
        return
    end

    self.UnsupportedSeen[What] = Why or ""
    self.UnsupportedOrder[#self.UnsupportedOrder + 1] = What
    NOutputDebugString("[" .. SHIM .. "] UNSUPPORTED " .. What .. (Why and (": " .. Why) or ""), 2)
end

function _MTAX:WarnOnce(Key, Message)
    if self.WarnedOnce[Key] then
        return
    end

    self.WarnedOnce[Key] = true
    NOutputDebugString("[" .. SHIM .. "] " .. Message, 2)
end

function _MTAX:Info(Message)
    NOutputDebugString("[" .. SHIM .. "] " .. Message, 3)
end

function _MTAX:Report()
    if #self.UnsupportedOrder == 0 then
        self:Info("no unsupported gui* call was reached this session.")
        return
    end

    self:Info("unsupported gui* calls reached this session (" .. #self.UnsupportedOrder .. "):")

    for Index = 1, #self.UnsupportedOrder do
        local Key = self.UnsupportedOrder[Index]
        self:Info("  - " .. Key .. (self.UnsupportedSeen[Key] ~= "" and ("  -- " .. self.UnsupportedSeen[Key]) or ""))
    end
end

--- Argument hygiene

function _MTAX:Num(Value, Default)
    local Number = tonumber(Value)
    if Number == nil or Number ~= Number then
        return Default
    end

    return Number
end

function _MTAX:Truthy(Value)
    if Value == nil or Value == false then
        return false
    end

    return true
end

function _MTAX:Str(Value, Default)
    local Kind = type(Value)

    if Kind == "string" then
        return Value
    end

    if Kind == "number" then
        return tostring(Value)
    end

    return Default
end

function _MTAX:Clamp(Value, Low, High)
    if Value < Low then
        return Low
    end

    if Value > High then
        return High
    end

    return Value
end

--- Utf8

function _MTAX:ULen(Text)
    if type(Text) ~= "string" then
        return 0
    end

    if Utf8 then
        local Ok, Length = pcall(Utf8.len, Text)
        if Ok and type(Length) == "number" then
            return Length
        end
    end

    return #Text
end

function _MTAX:UOffset(Text, Index)
    if not Utf8 then
        return self:Clamp(Index, 1, #Text + 1)
    end

    local Ok, Offset = pcall(Utf8.offset, Text, Index)
    if Ok and type(Offset) == "number" then
        return Offset
    end

    return self:Clamp(Index, 1, #Text + 1)
end

function _MTAX:USub(Text, From, To)
    if type(Text) ~= "string" or Text == "" then
        return ""
    end

    local Length = self:ULen(Text)

    if From < 1 then
        From = 1
    end

    if To == nil or To > Length then
        To = Length
    end

    if From > To then
        return ""
    end

    local Start = self:UOffset(Text, From)
    local Stop = (To >= Length) and (#Text + 1) or self:UOffset(Text, To + 1)

    if type(Start) ~= "number" or type(Stop) ~= "number" then
        return ""
    end

    return Sub(Text, Start, Stop - 1)
end

--- Colour

function _MTAX:Argb(A, R, G, B)
    A = Floor(self:Clamp(self:Num(A, 255), 0, 255))
    R = Floor(self:Clamp(self:Num(R, 255), 0, 255))
    G = Floor(self:Clamp(self:Num(G, 255), 0, 255))
    B = Floor(self:Clamp(self:Num(B, 255), 0, 255))

    return A * 0x1000000 + R * 0x10000 + G * 0x100 + B
end

function _MTAX:WithAlpha(Color, Multiplier)
    if Multiplier >= 0.999 then
        return Color
    end

    if Multiplier <= 0 then
        return Color % 0x1000000
    end

    local Alpha = Floor(Color / 0x1000000) % 256

    return Floor(Alpha * Multiplier + 0.5) * 0x1000000 + (Color % 0x1000000)
end

--- Fonts

function _MTAX:ResolveFont(FontSpec)
    if FontSpec == nil then
        local Font = self.GuiFonts[self.DefaultFont]
        return Font.Dx, Font.Scale
    end

    if type(FontSpec) == "string" then
        local Font = self.GuiFonts[FontSpec]

        if Font then
            return Font.Dx, Font.Scale
        end

        if self.DxFonts[FontSpec] then
            return FontSpec, 1.0
        end

        self:Unsupported("guiSetFont(\"" .. FontSpec .. "\")",
            "not one of MTA's 8 CEGUI GUI font names and not one of MTAX's 10 dx font names; " ..
            "MTAX will silently rasterise it as Tahoma 15px")

        return "default", 1.0
    end

    if NIsElement(FontSpec) then
        return FontSpec, 1.0
    end

    local Font = self.GuiFonts[self.DefaultFont]
    return Font.Dx, Font.Scale
end

function _MTAX:TextWidth(Text, FontSpec)
    local Font, Scale = self:ResolveFont(FontSpec)
    local Ok, Width = pcall(NDxGetTextWidth, Text or "", Scale, Font, false)

    return (Ok and type(Width) == "number") and Width or 0
end

function _MTAX:FontHeight(FontSpec)
    local Key = FontSpec

    if Key == nil then
        Key = "\0default"
    end

    local Cached = self.FontHeightCache[Key]
    if Cached then
        return Cached
    end

    local Font, Scale = self:ResolveFont(FontSpec)
    local Ok, Height = pcall(NDxGetFontHeight, Scale, Font)

    if not (Ok and type(Height) == "number" and Height > 0) then
        return 12
    end

    self.FontHeightCache[Key] = Height
    return Height
end

function _MTAX:FlushFontMetrics()
    for Key in pairs(self.FontHeightCache) do
        self.FontHeightCache[Key] = nil
    end
end

function _MTAX:CreateFont(FilePath, Size)
    if type(FilePath) ~= "string" or FilePath == "" then
        return false
    end

    local Points = self:Num(Size, 9)

    if Points ~= Points or Points <= 0 then
        Points = 9
    end

    local WantedPixels = Points * 4 / 3
    local Unit = Floor(self:Clamp(WantedPixels / FONT_PX_PER_UNIT + 0.5, 5, 150))

    if NFileExists and not NFileExists(FilePath) then
        return false
    end

    local Ok, Element = pcall(NDxCreateFont, FilePath, Unit, false, "cleartype")

    if not Ok or not Element or Element == false or not NIsElement(Element) then
        return false
    end

    self.CustomFonts[#self.CustomFonts + 1] = { Element = Element, Path = FilePath, Size = Points }
    return Element
end

--- Registry

function _MTAX:Define(Name)
    if type(rawget(_G, Name)) ~= "function" then
        return false
    end

    if self.DefinedSet[Name] then
        return false
    end

    self.DefinedSet[Name] = true
    self.DefinedNames[#self.DefinedNames + 1] = Name
    return true
end

function _MTAX:Class(Name, Definition)
    self.Classes[Name] = Definition
    return Definition
end

function _MTAX:Resolve(Value)
    if Value == nil then
        return nil
    end

    local Kind = type(Value)
    if Kind ~= "userdata" and Kind ~= "table" then
        return nil
    end

    local Cached = self.HandleCache[Value]

    if Cached ~= nil then
        if not Cached.Destroyed and NIsElement(Value) then
            return Cached
        end

        self.HandleCache[Value] = nil
    end

    if not NIsElement(Value) then
        return nil
    end

    local Id = NGetElementID(Value)
    if type(Id) ~= "string" then
        return nil
    end

    local Widget = self.WidgetsById[Id]
    if Widget == nil or Widget.Destroyed then
        return nil
    end

    if Widget.Element == nil or Widget.Element ~= Value then
        return nil
    end

    self.HandleCache[Value] = Widget
    return Widget
end

function _MTAX:ResolveTyped(Value, Wanted)
    local Widget = self:Resolve(Value)

    if Widget == nil then
        return nil
    end

    if Wanted ~= nil and Widget.Type ~= Wanted then
        return nil
    end

    return Widget
end

--- Scene graph

function _MTAX:Screen()
    return self.ScreenW, self.ScreenH
end

function _MTAX:Tick()
    return NGetTickCount()
end

function _MTAX:MarkDirty()
    self.LayoutDirty = true
end

function _MTAX:IndexOf(List, Value)
    for Index = 1, #List do
        if List[Index] == Value then
            return Index
        end
    end

    return nil
end

function _MTAX:SiblingList(Widget)
    return Widget.Parent and Widget.Parent.Children or self.TopLevel
end

function _MTAX:NewWidget(TypeName, X, Y, Width, Height, Relative, ParentValue, Init)
    local Parent = ParentValue ~= nil and self:Resolve(ParentValue) or nil

    if ParentValue ~= nil and Parent == nil then
        Parent = nil
    end

    X, Y = self:Num(X, 0), self:Num(Y, 0)
    Width, Height = self:Num(Width, 0), self:Num(Height, 0)

    if self:Truthy(Relative) then
        local ParentW, ParentH = self.ScreenW, self.ScreenH

        if Parent then
            self:Layout()

            local Class = self.Classes[Parent.Type]

            if Class and Class.ChildArea then
                local _, _, AreaW, AreaH = Class.ChildArea(self, Parent)
                ParentW, ParentH = AreaW, AreaH
            else
                ParentW, ParentH = Parent.AW, Parent.AH
            end
        end

        X, Y = X * ParentW, Y * ParentH
        Width, Height = Width * ParentW, Height * ParentH
    end

    self.NextHandleId = self.NextHandleId + 1

    local Id = ID_PREFIX .. self.NextHandleId
    local Element = NCreateElement(TypeName, Id)

    if Element == false or Element == nil or not NIsElement(Element) then
        NOutputDebugString("[" .. SHIM .. "] createElement(\"" .. TypeName ..
                           "\") failed; the widget could not be created.", 1)
        return false
    end

    local Widget = {
        Id = Id,
        Element = Element,
        Type = TypeName,
        Parent = Parent,
        Children = {},
        X = X, Y = Y, W = Width, H = Height,
        Visible = true,
        Enabled = true,
        Alpha = 1.0,
        Text = "",
        Font = self.DefaultFont,
        ClippedByParent = true,
        InheritsAlpha = true,
        MousePassThrough = false,
        Destroyed = false,
        Props = {},
        AX = X, AY = Y, AW = Width, AH = Height,
        CX1 = 0, CY1 = 0, CX2 = self.ScreenW, CY2 = self.ScreenH,
        EffectiveAlpha = 1.0,
        EffectiveEnabled = true,
        EffectiveVisible = true,
    }

    if Init then
        for Key, Value in pairs(Init) do
            Widget[Key] = Value
        end
    end

    self.WidgetsById[Id] = Widget
    self.HandleCache[Element] = Widget

    if Parent then
        Parent.Children[#Parent.Children + 1] = Widget
        NSetElementParent(Element, Parent.Element)
    else
        self.TopLevel[#self.TopLevel + 1] = Widget
    end

    self:MarkDirty()
    return Widget
end

function _MTAX:Unlink(Widget)
    if Widget.Destroyed then
        return
    end

    Widget.Destroyed = true

    local List = self:SiblingList(Widget)
    local At = self:IndexOf(List, Widget)

    if At then
        Remove(List, At)
    end

    Widget.Parent = nil

    for Index = 1, #Widget.Children do
        Widget.Children[Index].Parent = nil
    end

    Widget.Children = {}

    self.WidgetsById[Widget.Id] = nil

    if Widget.Element ~= nil then
        self.HandleCache[Widget.Element] = nil
    end

    Widget.Element = nil

    if self.Focused == Widget then self.Focused = nil end
    if self.Hovered == Widget then self.Hovered = nil end
    if self.Captured == Widget then self.Captured = nil; self.CaptureMode = nil end
    if self.Popup == Widget then self.Popup = nil end

    if self.Pressed == Widget then
        self.Pressed = nil
        self.PressedButton = nil
        self.PressX, self.PressY = nil, nil
    end

    local Class = self.Classes[Widget.Type]

    if Class and Class.Dispose then
        pcall(Class.Dispose, self, Widget)
    end

    self:MarkDirty()
end

function _MTAX:DestroyWidget(Widget)
    if Widget == nil or Widget.Destroyed then
        return false
    end

    local Element = Widget.Element

    if Element ~= nil and NIsElement(Element) then
        NDestroyElement(Element)
    end

    if not Widget.Destroyed then
        self:Unlink(Widget)
    end

    return true
end

--- Layout

function _MTAX:Intersect(AX1, AY1, AX2, AY2, BX1, BY1, BX2, BY2)
    if BX1 > AX1 then AX1 = BX1 end
    if BY1 > AY1 then AY1 = BY1 end
    if BX2 < AX2 then AX2 = BX2 end
    if BY2 < AY2 then AY2 = BY2 end

    return AX1, AY1, AX2, AY2
end

function _MTAX:LayoutNode(Widget, PX, PY, PW, PH, CX1, CY1, CX2, CY2, Alpha, Enabled, Visible)
    Widget.AX = PX + Widget.X
    Widget.AY = PY + Widget.Y
    Widget.AW = Widget.W
    Widget.AH = Widget.H
    Widget.EffectiveAlpha = Widget.InheritsAlpha and (Alpha * Widget.Alpha) or Widget.Alpha
    Widget.EffectiveEnabled = Enabled and Widget.Enabled
    Widget.EffectiveVisible = Visible and Widget.Visible
    Widget.CX1, Widget.CY1, Widget.CX2, Widget.CY2 = CX1, CY1, CX2, CY2

    local Class = self.Classes[Widget.Type]

    if Class and Class.Reflow then
        Class.Reflow(self, Widget)
    end

    local Count = #Widget.Children
    if Count == 0 then
        return
    end

    local KX, KY, KW, KH = Widget.AX, Widget.AY, Widget.AW, Widget.AH

    if Class and Class.ChildArea then
        KX, KY, KW, KH = Class.ChildArea(self, Widget)
    end

    local BX1, BY1 = Widget.AX, Widget.AY
    local BX2, BY2 = Widget.AX + Widget.AW, Widget.AY + Widget.AH

    if Class and Class.ClipArea then
        BX1, BY1, BX2, BY2 = Class.ClipArea(self, Widget)
    end

    local NX1, NY1, NX2, NY2 = self:Intersect(CX1, CY1, CX2, CY2, BX1, BY1, BX2, BY2)
    local ChildVisible = Class and Class.ChildVisible

    for Index = 1, Count do
        local Child = Widget.Children[Index]
        local ChildIsVisible = Widget.EffectiveVisible

        if ChildVisible and not ChildVisible(self, Widget, Child) then
            ChildIsVisible = false
        end

        if Child.ClippedByParent then
            self:LayoutNode(Child, KX, KY, KW, KH, NX1, NY1, NX2, NY2,
                            Widget.EffectiveAlpha, Widget.EffectiveEnabled, ChildIsVisible)
        else
            self:LayoutNode(Child, KX, KY, KW, KH, 0, 0, self.ScreenW, self.ScreenH,
                            Widget.EffectiveAlpha, Widget.EffectiveEnabled, ChildIsVisible)
        end
    end
end

function _MTAX:Layout()
    if not self.LayoutDirty then
        return
    end

    self.LayoutDirty = false

    for Index = 1, #self.TopLevel do
        self:LayoutNode(self.TopLevel[Index], 0, 0, self.ScreenW, self.ScreenH,
                        0, 0, self.ScreenW, self.ScreenH, 1.0, true, true)
    end
end

function _MTAX:ParentBox(Widget)
    self:Layout()

    local Parent = Widget.Parent

    if not Parent then
        return 0, 0, self.ScreenW, self.ScreenH
    end

    local Class = self.Classes[Parent.Type]

    if Class and Class.ChildArea then
        return Class.ChildArea(self, Parent)
    end

    return Parent.AX, Parent.AY, Parent.AW, Parent.AH
end

--- Drawing primitives

function _MTAX:FillRect(X, Y, Width, Height, Color, Clip)
    local X1, Y1, X2, Y2 = X, Y, X + Width, Y + Height

    if Clip then
        X1, Y1, X2, Y2 = self:Intersect(X1, Y1, X2, Y2, Clip[1], Clip[2], Clip[3], Clip[4])
    end

    if X2 <= X1 or Y2 <= Y1 then
        return
    end

    NDxDrawRectangle(X1, Y1, X2 - X1, Y2 - Y1, Color)
end

function _MTAX:FrameRect(X, Y, Width, Height, Thickness, Color, Clip)
    if Width <= 0 or Height <= 0 then
        return
    end

    Thickness = Thickness or 1

    self:FillRect(X, Y, Width, Thickness, Color, Clip)
    self:FillRect(X, Y + Height - Thickness, Width, Thickness, Color, Clip)
    self:FillRect(X, Y + Thickness, Thickness, Height - Thickness * 2, Color, Clip)
    self:FillRect(X + Width - Thickness, Y + Thickness, Thickness, Height - Thickness * 2, Color, Clip)
end

function _MTAX:DrawText(Text, X1, Y1, X2, Y2, Color, FontSpec, AlignX, AlignY, Wrap, Clip)
    if Text == nil or Text == "" then
        return
    end

    local Font, Scale = self:ResolveFont(FontSpec)
    local BX1, BY1, BX2, BY2 = X1, Y1, X2, Y2

    if Clip then
        BX1, BY1, BX2, BY2 = self:Intersect(BX1, BY1, BX2, BY2, Clip[1], Clip[2], Clip[3], Clip[4])
    end

    if BX2 <= BX1 or BY2 <= BY1 then
        return
    end

    NDxDrawText(Text, BX1, BY1, BX2, BY2, Color, Scale, Font,
                AlignX or "left", AlignY or "top", true, Wrap or false, false, false)
end

function _MTAX:MaterialSize(Image)
    local Cached = self.MaterialSizeCache[Image]

    if Cached then
        return Cached[1], Cached[2]
    end

    local Ok, Width, Height = pcall(NDxGetMaterialSize, Image)

    if not Ok or type(Width) ~= "number" or type(Height) ~= "number" or Width <= 0 or Height <= 0 then
        return nil, nil
    end

    self.MaterialSizeCache[Image] = { Width, Height }
    return Width, Height
end

function _MTAX:DrawImage(X, Y, Width, Height, Image, Color, Clip)
    if Image == nil or Width <= 0 or Height <= 0 then
        return
    end

    local X1, Y1, X2, Y2 = X, Y, X + Width, Y + Height
    local CX1, CY1, CX2, CY2 = X1, Y1, X2, Y2

    if Clip then
        CX1, CY1, CX2, CY2 = self:Intersect(CX1, CY1, CX2, CY2, Clip[1], Clip[2], Clip[3], Clip[4])
    end

    if CX2 <= CX1 or CY2 <= CY1 then
        return
    end

    if CX1 == X1 and CY1 == Y1 and CX2 == X2 and CY2 == Y2 then
        NDxDrawImage(X1, Y1, Width, Height, Image, 0, 0, 0, Color)
        return
    end

    local TextureW, TextureH = self:MaterialSize(Image)

    if TextureW == nil then
        NDxDrawImage(CX1, CY1, CX2 - CX1, CY2 - CY1, Image, 0, 0, 0, Color)
        return
    end

    local U = (CX1 - X1) / Width * TextureW
    local V = (CY1 - Y1) / Height * TextureH
    local UW = (CX2 - CX1) / Width * TextureW
    local VH = (CY2 - CY1) / Height * TextureH

    NDxDrawImageSection(CX1, CY1, CX2 - CX1, CY2 - CY1, U, V, UW, VH, Image, 0, 0, 0, Color)
end

function _MTAX:Clip(Widget)
    local Table = Widget.ClipTable

    if Table == nil then
        Table = {}
        Widget.ClipTable = Table
    end

    Table[1], Table[2] = Widget.CX1, Widget.CY1
    Table[3], Table[4] = Widget.CX2, Widget.CY2

    return Table
end

function _MTAX:InnerClip(Widget, InsetLeft, InsetTop, InsetRight, InsetBottom)
    local Table = Widget.InnerTable

    if Table == nil then
        Table = {}
        Widget.InnerTable = Table
    end

    local X1 = Widget.AX + (InsetLeft or 0)
    local Y1 = Widget.AY + (InsetTop or 0)
    local X2 = Widget.AX + Widget.AW - (InsetRight or 0)
    local Y2 = Widget.AY + Widget.AH - (InsetBottom or 0)

    X1, Y1, X2, Y2 = self:Intersect(X1, Y1, X2, Y2, Widget.CX1, Widget.CY1, Widget.CX2, Widget.CY2)

    Table[1], Table[2], Table[3], Table[4] = X1, Y1, X2, Y2
    return Table
end

function _MTAX:MakeClip(X1, Y1, X2, Y2)
    return { X1, Y1, X2, Y2 }
end

--- Render pass

function _MTAX:DrawNode(Widget)
    if not Widget.EffectiveVisible then
        return
    end

    if Widget.CX2 <= Widget.CX1 or Widget.CY2 <= Widget.CY1 then
        return
    end

    local Class = self.Classes[Widget.Type]

    if Class and Class.Draw then
        Class.Draw(self, Widget)
    end

    local Children = Widget.Children

    for Index = 1, #Children do
        self:DrawNode(Children[Index])
    end

    if Class and Class.DrawAfter then
        Class.DrawAfter(self, Widget)
    end
end

function _MTAX:RenderPass()
    local ScreenW, ScreenH = NGetScreenSize()

    if type(ScreenW) == "number" and ScreenW > 0 and (ScreenW ~= self.ScreenW or ScreenH ~= self.ScreenH) then
        self.ScreenW, self.ScreenH = ScreenW, ScreenH
        self:FlushFontMetrics()
        self:MarkDirty()
    end

    if self.CursorX < 0 and NIsCursorShowing() then
        local RelX, RelY = NGetCursorPosition()

        if type(RelX) == "number" and type(RelY) == "number" then
            self.CursorX, self.CursorY = RelX * self.ScreenW, RelY * self.ScreenH
        end
    end

    self:Layout()

    for Index = 1, #self.TopLevel do
        self:DrawNode(self.TopLevel[Index])
    end

    local Popup = self.Popup

    if Popup and not Popup.Destroyed and Popup.EffectiveVisible then
        local Class = self.Classes[Popup.Type]

        if Class and Class.DrawPopup then
            Class.DrawPopup(self, Popup)
        end
    end
end

--- Hit testing

function _MTAX:PointIn(X, Y, X1, Y1, X2, Y2)
    return X >= X1 and X < X2 and Y >= Y1 and Y < Y2
end

function _MTAX:HitIn(Widget, X, Y)
    if not Widget.EffectiveVisible then
        return nil
    end

    if not self:PointIn(X, Y, Widget.CX1, Widget.CY1, Widget.CX2, Widget.CY2) then
        return nil
    end

    local Children = Widget.Children

    for Index = #Children, 1, -1 do
        local Result = self:HitIn(Children[Index], X, Y)

        if Result then
            return Result
        end
    end

    if Widget.MousePassThrough then
        return nil
    end

    local Class = self.Classes[Widget.Type]

    if Class and Class.HitBox then
        local BX1, BY1, BX2, BY2 = Class.HitBox(self, Widget)

        if self:PointIn(X, Y, BX1, BY1, BX2, BY2) then
            return Widget
        end

        return nil
    end

    if self:PointIn(X, Y, Widget.AX, Widget.AY, Widget.AX + Widget.AW, Widget.AY + Widget.AH) then
        return Widget
    end

    return nil
end

function _MTAX:HitTest(X, Y)
    self:Layout()

    local Popup = self.Popup

    if Popup and not Popup.Destroyed and Popup.EffectiveVisible then
        local Class = self.Classes[Popup.Type]

        if Class and Class.HitPopup then
            local Result = Class.HitPopup(self, Popup, X, Y)

            if Result then
                return Result
            end
        end
    end

    for Index = #self.TopLevel, 1, -1 do
        local Result = self:HitIn(self.TopLevel[Index], X, Y)

        if Result then
            return Result
        end
    end

    return nil
end

function _MTAX:EffectivelyEnabled(Widget)
    self:Layout()
    return Widget.EffectiveEnabled == true
end

--- Events

function _MTAX:Fire(EventName, Widget, ...)
    if Widget == nil or Widget.Destroyed or Widget.Element == nil then
        return
    end

    if not NIsElement(Widget.Element) then
        return
    end

    NTriggerEvent(EventName, Widget.Element, ...)
end

--- Focus

function _MTAX:Blur()
    local Old = self.Focused

    if Old == nil then
        return false
    end

    self.Focused = nil

    if not Old.Destroyed then
        local Class = self.Classes[Old.Type]

        if Class and Class.OnBlur then
            Class.OnBlur(self, Old)
        end

        self:Fire("onClientGUIBlur", Old)
    end

    return true
end

function _MTAX:Focus(Widget)
    if Widget == nil or Widget.Destroyed then
        return self:Blur()
    end

    if self.Focused == Widget then
        return true
    end

    self:Blur()
    self.Focused = Widget

    local Class = self.Classes[Widget.Type]

    if Class and Class.OnFocus then
        Class.OnFocus(self, Widget)
    end

    self:Fire("onClientGUIFocus", Widget)
    return true
end

function _MTAX:IsUnder(Node, Root)
    while Node ~= nil do
        if Node == Root then
            return true
        end

        Node = Node.Parent
    end

    return false
end

function _MTAX:DropInteraction(Widget)
    if Widget == nil then
        return
    end

    local Hovered = self.Hovered

    if Hovered ~= nil and self:IsUnder(Hovered, Widget) then
        self.Hovered = nil

        if not Hovered.Destroyed then
            local Class = self.Classes[Hovered.Type]

            if Class and Class.OnLeave then
                Class.OnLeave(self, Hovered)
            end

            self:Fire("onClientMouseLeave", Hovered, self.CursorX, self.CursorY)
        end
    end

    if self.Pressed ~= nil and self:IsUnder(self.Pressed, Widget) then
        self.Pressed = nil
        self.PressedButton = nil
        self.PressX, self.PressY = nil, nil
    end

    local Captured = self.Captured

    if Captured ~= nil and self:IsUnder(Captured, Widget) then
        self.Captured = nil
        self.CaptureMode = nil

        if not Captured.Destroyed then
            local Class = self.Classes[Captured.Type]

            if Class and Class.OnDragEnd then
                Class.OnDragEnd(self, Captured)
            end
        end
    end
end

--- Z-order

function _MTAX:RaiseAlwaysOnTop(List)
    local Pinned = nil

    for Index = 1, #List do
        if List[Index].AlwaysOnTop then
            Pinned = Pinned or {}
            Pinned[#Pinned + 1] = List[Index]
        end
    end

    if Pinned == nil then
        return
    end

    for Index = 1, #Pinned do
        local Widget = Pinned[Index]
        local At = self:IndexOf(List, Widget)

        if At then
            Remove(List, At)
        end

        List[#List + 1] = Widget
    end
end

function _MTAX:BringToFront(Widget)
    if Widget == nil or Widget.Destroyed then
        return false
    end

    local List = self:SiblingList(Widget)
    local At = self:IndexOf(List, Widget)

    if At == nil then
        return false
    end

    if At ~= #List then
        Remove(List, At)
        List[#List + 1] = Widget
    end

    self:RaiseAlwaysOnTop(List)

    if Widget.Parent then
        self:BringToFront(Widget.Parent)
    end

    self:MarkDirty()
    return true
end

function _MTAX:MoveToBack(Widget)
    if Widget == nil or Widget.Destroyed then
        return false
    end

    local List = self:SiblingList(Widget)
    local At = self:IndexOf(List, Widget)

    if At == nil then
        return false
    end

    if At ~= 1 then
        Remove(List, At)
        table.insert(List, 1, Widget)
    end

    self:MarkDirty()
    return true
end

--- Input plumbing

function _MTAX:AddHandler(Name, Element, Handler)
    if NAddEventHandler(Name, Element, Handler) then
        self.Handlers[#self.Handlers + 1] = { Name = Name, Element = Element, Handler = Handler }
        return true
    end

    return false
end

function _MTAX:RemoveAllHandlers()
    for Index = #self.Handlers, 1, -1 do
        local Entry = self.Handlers[Index]
        pcall(NRemoveEventHandler, Entry.Name, Entry.Element, Entry.Handler)
        self.Handlers[Index] = nil
    end
end

function _MTAX:UpdateHover(X, Y)
    local Hit = self:HitTest(X, Y)
    local Old = self.Hovered

    if Hit ~= Old then
        if Old and not Old.Destroyed then
            local Class = self.Classes[Old.Type]

            if Class and Class.OnLeave then
                Class.OnLeave(self, Old)
            end

            self:Fire("onClientMouseLeave", Old, X, Y)
        end

        self.Hovered = Hit

        if Hit then
            local Class = self.Classes[Hit.Type]

            if Class and Class.OnEnter then
                Class.OnEnter(self, Hit)
            end

            self:Fire("onClientMouseEnter", Hit, X, Y)
        end
    end

    if Hit then
        self:Fire("onClientMouseMove", Hit, X, Y)
    end
end

function _MTAX:CursorMove(RelX, RelY, AbsX, AbsY)
    AbsX = self:Num(AbsX, nil)
    AbsY = self:Num(AbsY, nil)

    if AbsX == nil or AbsY == nil then
        local X, Y = self:Num(RelX, nil), self:Num(RelY, nil)

        if X == nil then
            return
        end

        AbsX, AbsY = X * self.ScreenW, Y * self.ScreenH
    end

    self.CursorX, self.CursorY = AbsX, AbsY

    local Captured = self.Captured

    if Captured and not Captured.Destroyed then
        local Class = self.Classes[Captured.Type]

        if Class and Class.OnDrag then
            Class.OnDrag(self, Captured, AbsX, AbsY)
        end

        return
    end

    self:UpdateHover(AbsX, AbsY)
end

function _MTAX:ReleaseCapture()
    local Captured = self.Captured

    if Captured and not Captured.Destroyed then
        local Class = self.Classes[Captured.Type]

        if Class and Class.OnDragEnd then
            Class.OnDragEnd(self, Captured)
        end
    end

    self.Captured = nil
    self.CaptureMode = nil
end

function _MTAX:Capture(Widget, Mode)
    self.Captured = Widget
    self.CaptureMode = Mode
end

function _MTAX:MouseDown(Button, X, Y)
    local Hit = self:HitTest(X, Y)
    local Popup = self.Popup

    if Popup and not Popup.Destroyed then
        local Class = self.Classes[Popup.Type]
        local InPopup = Class and Class.HitPopup and Class.HitPopup(self, Popup, X, Y) or nil

        if InPopup == nil and Hit ~= Popup then
            if Class and Class.ClosePopup then
                Class.ClosePopup(self, Popup)
            end
        end
    end

    self.Pressed = Hit
    self.PressedButton = Button
    self.PressX, self.PressY = X, Y

    if Hit == nil then
        self:Blur()
        return
    end

    if not self:EffectivelyEnabled(Hit) then
        return
    end

    self:Focus(Hit)

    if Button == "left" then
        self:BringToFront(Hit)
    end

    local Class = self.Classes[Hit.Type]

    if Class and Class.OnMouseDown then
        Class.OnMouseDown(self, Hit, Button, X, Y)
    end

    self:Fire("onClientGUIMouseDown", Hit, Button, X, Y)
    self:Fire("onClientGUIClick", Hit, Button, "down", X, Y)
end

function _MTAX:MouseUp(Button, X, Y)
    if self.Captured then
        self:ReleaseCapture()
    end

    local Target = self.Pressed
    local PressX, PressY = self.PressX, self.PressY

    self.Pressed = nil
    self.PressedButton = nil
    self.PressX, self.PressY = nil, nil

    if Target == nil or Target.Destroyed then
        return
    end

    if not self:EffectivelyEnabled(Target) then
        return
    end

    local Over = (self:HitTest(X, Y) == Target)
    local Class = self.Classes[Target.Type]

    if Class and Class.OnMouseUp then
        Class.OnMouseUp(self, Target, Button, X, Y, Over)
    end

    self:Fire("onClientGUIMouseUp", Target, Button, X, Y)

    local Within = PressX == nil
        or (Abs(X - PressX) <= CLICK_TOLERANCE and Abs(Y - PressY) <= CLICK_TOLERANCE)

    if Within then
        self:Fire("onClientGUIClick", Target, Button, "up", X, Y)
    end
end

function _MTAX:Click(Button, State, AbsX, AbsY)
    if type(Button) ~= "string" or type(State) ~= "string" then
        return
    end

    local X, Y = self:Num(AbsX, self.CursorX), self:Num(AbsY, self.CursorY)

    if X < 0 then
        return
    end

    self.CursorX, self.CursorY = X, Y

    if State == "down" then
        self:MouseDown(Button, X, Y)
    elseif State == "up" then
        self:MouseUp(Button, X, Y)
    end
end

function _MTAX:DoubleClick(Button, AbsX, AbsY)
    if type(Button) ~= "string" then
        return
    end

    local X, Y = self:Num(AbsX, self.CursorX), self:Num(AbsY, self.CursorY)

    if X < 0 then
        return
    end

    local Hit = self:HitTest(X, Y)

    if Hit == nil or not self:EffectivelyEnabled(Hit) then
        return
    end

    local Class = self.Classes[Hit.Type]

    if Class and Class.OnDoubleClick then
        Class.OnDoubleClick(self, Hit, Button, X, Y)
    end

    self:Fire("onClientGUIDoubleClick", Hit, Button, "up", X, Y)
end

function _MTAX:RouteWheel(Delta)
    if not NIsCursorShowing() then
        return
    end

    local X, Y = self.CursorX, self.CursorY

    if X < 0 then
        return
    end

    local Popup = self.Popup

    if Popup and not Popup.Destroyed then
        local Class = self.Classes[Popup.Type]

        if Class and Class.HitPopup and Class.HitPopup(self, Popup, X, Y) and Class.OnWheel then
            if Class.OnWheel(self, Popup, Delta) then
                self:Fire("onClientGUIScroll", Popup)
            end

            return
        end
    end

    local Widget = self:HitTest(X, Y)

    while Widget do
        if self:EffectivelyEnabled(Widget) then
            local Class = self.Classes[Widget.Type]

            if Class and Class.OnWheel and Class.OnWheel(self, Widget, Delta) then
                self:Fire("onClientGUIScroll", Widget)
                return
            end
        end

        Widget = Widget.Parent
    end
end

function _MTAX:ShiftHeld()
    return NGetKeyState("lshift") or NGetKeyState("rshift")
end

function _MTAX:CtrlHeld()
    return NGetKeyState("lctrl") or NGetKeyState("rctrl")
end

function _MTAX:Key(Key, Down)
    if type(Key) ~= "string" then
        return
    end

    if Down and Key == "mouse_wheel_up" then
        self:RouteWheel(-1)
        return
    end

    if Down and Key == "mouse_wheel_down" then
        self:RouteWheel(1)
        return
    end

    if Key == "mouse1" or Key == "mouse2" or Key == "mouse3"
       or Key == "mouse4" or Key == "mouse5" then
        return
    end

    if not Down then
        return
    end

    local Focused = self.Focused

    if Focused == nil or Focused.Destroyed then
        return
    end

    if not self:EffectivelyEnabled(Focused) then
        return
    end

    local Class = self.Classes[Focused.Type]

    if Class and Class.OnKey then
        Class.OnKey(self, Focused, Key)
    end
end

function _MTAX:Character(Character)
    if type(Character) ~= "string" or Character == "" then
        return
    end

    local Focused = self.Focused

    if Focused == nil or Focused.Destroyed then
        return
    end

    if not self:EffectivelyEnabled(Focused) then
        return
    end

    local Class = self.Classes[Focused.Type]

    if Class and Class.OnCharacter then
        Class.OnCharacter(self, Focused, Character)
    end
end

function _MTAX:Paste(Text)
    if type(Text) ~= "string" or Text == "" then
        return
    end

    local Focused = self.Focused

    if Focused == nil or Focused.Destroyed then
        return
    end

    if not self:EffectivelyEnabled(Focused) then
        return
    end

    local Class = self.Classes[Focused.Type]

    if Class and Class.OnPaste then
        Class.OnPaste(self, Focused, Text)
    end
end

function _MTAX:SetClipboard(Text)
    if NSetClipboard == nil then
        self:Unsupported("clipboard write", "setClipboard is not available in this MTAX build")
        return false
    end

    local Ok, Result = pcall(NSetClipboard, type(Text) == "string" and Text or "")
    return Ok and Result or false
end

function _MTAX:ElementDestroy(Element)
    local Widget = self:Resolve(Element)

    if Widget then
        self:Unlink(Widget)
    end
end

function _MTAX:ResourceStop(ResourceName, Element)
    local Mine = false

    if type(ResourceName) == "string" then
        Mine = (ResourceName == self.ResourceName)
    elseif self.ResourceRoot ~= nil and NIsElement(self.ResourceRoot) then
        Mine = (Element == self.ResourceRoot)
    end

    if Mine then
        self:Shutdown()
    end
end

--- Lifecycle

function _MTAX:Init()
    self.Name = SHIM
    self.Version = VERSION
    self.Reserved = RESERVED
    self.DefinedNames = {}
    self.DefinedSet = {}
    self.UnsupportedSeen = {}
    self.UnsupportedOrder = {}
    self.WarnedOnce = {}

    self.Classes = {}
    self.TopLevel = {}
    self.WidgetsById = {}
    self.HandleCache = setmetatable({}, { __mode = "k" })
    self.FontHeightCache = setmetatable({}, { __mode = "k" })
    self.MaterialSizeCache = setmetatable({}, { __mode = "k" })
    self.CustomFonts = {}
    self.Handlers = {}
    self.NextHandleId = 0

    self.LayoutDirty = true
    self.ScreenW, self.ScreenH = 800, 600

    local ScreenW, ScreenH = NGetScreenSize()

    if type(ScreenW) == "number" and ScreenW > 0 then
        self.ScreenW, self.ScreenH = ScreenW, ScreenH
    end

    self.CursorX, self.CursorY = -1, -1
    self.Focused = nil
    self.Hovered = nil
    self.Captured = nil
    self.CaptureMode = nil
    self.Pressed = nil
    self.PressedButton = nil
    self.PressX, self.PressY = nil, nil
    self.Popup = nil

    self.InputEnabled = false
    self.InputMode = "allow_binds"
    self.LogicalCursor = "default"
    self.Stopped = false

    self.CursorTypeNames = {
        ["move"]    = "sizing_move",
        ["size-n"]  = "sizing_ns",   ["size-s"]  = "sizing_ns",
        ["size-w"]  = "sizing_ew",   ["size-e"]  = "sizing_ew",
        ["size-nw"] = "sizing_nwse", ["size-se"] = "sizing_nwse",
        ["size-ne"] = "sizing_nesw", ["size-sw"] = "sizing_nesw",
    }

    self.DefaultFont = "default-normal"

    self.GuiFonts = {
        ["default-normal"]     = { Dx = "default",      Scale = 0.80 },
        ["default-small"]      = { Dx = "default",      Scale = 0.62 },
        ["default-bold-small"] = { Dx = "default-bold", Scale = 0.71 },
        ["clear-normal"]       = { Dx = "clear",        Scale = 0.80 },
        ["sans"]               = { Dx = "sans",         Scale = 0.80 },
        ["unifont"]            = { Dx = "unifont",      Scale = 0.80 },
        ["sa-header"]          = { Dx = "pricedown",    Scale = 1.00 },
        ["sa-gothic"]          = { Dx = "bankgothic",   Scale = 1.00 },
    }

    self.DxFonts = {
        ["default"] = true, ["default-bold"] = true, ["clear"] = true, ["arial"] = true,
        ["sans"] = true, ["pricedown"] = true, ["bankgothic"] = true, ["diploma"] = true,
        ["beckett"] = true, ["unifont"] = true,
    }

    self.Theme = {
        WindowFrame      = self:Argb(235,  38,  38,  42),
        WindowBody       = self:Argb(225,  28,  28,  32),
        WindowTitle      = self:Argb(245,  52,  52,  60),
        WindowTitleText  = self:Argb(255, 235, 235, 240),
        WindowBorder     = self:Argb(255,  72,  72,  82),
        CloseNormal      = self:Argb(255, 150,  60,  60),
        CloseHover       = self:Argb(255, 200,  70,  70),
        CloseGlyph       = self:Argb(255, 245, 235, 235),
        Grip             = self:Argb(120, 120, 120, 135),

        Text             = self:Argb(255, 226, 226, 232),
        TextDisabled     = self:Argb(255, 128, 128, 136),

        ButtonNormal     = self:Argb(255,  62,  62,  72),
        ButtonHover      = self:Argb(255,  82,  82,  96),
        ButtonPushed     = self:Argb(255,  44,  44,  52),
        ButtonDisabled   = self:Argb(255,  46,  46,  50),
        ButtonBorder     = self:Argb(255,  96,  96, 110),

        FieldBg          = self:Argb(235,  18,  18,  22),
        FieldBorder      = self:Argb(255,  86,  86,  98),
        FieldBorderFocus = self:Argb(255, 120, 160, 220),
        Caret            = self:Argb(255, 235, 235, 240),

        PanelBg          = self:Argb(210,  26,  26,  30),
        PanelBorder      = self:Argb(255,  70,  70,  80),

        HeaderBg         = self:Argb(255,  46,  46,  54),
        RowAlt           = self:Argb(40,  255, 255, 255),
        RowSelected      = self:Argb(255,  46,  86, 140),
        RowHover         = self:Argb(60,  255, 255, 255),

        ProgressBg       = self:Argb(235,  20,  20,  24),
        ProgressFill     = self:Argb(255,  70, 140, 200),

        ScrollTrack      = self:Argb(200,  22,  22,  26),
        ScrollThumb      = self:Argb(255,  86,  86,  98),
        ScrollThumbHover = self:Argb(255, 116, 116, 132),

        TabStrip         = self:Argb(235,  34,  34,  40),
        TabInactive      = self:Argb(255,  48,  48,  56),
        TabActive        = self:Argb(255,  70,  70,  84),

        Check            = self:Argb(255, 120, 190, 250),
    }

    self.Root = NGetRootElement()
    self.ResourceRoot = NGetResourceRootElement()
    self.Resource = NGetThisResource()
    self.ResourceName = NGetResourceName(self.Resource)

    self.Natives = {
        IsElement = NIsElement,
        GetElementID = NGetElementID,
        GetElementType = NGetElementType,
        CreateElement = NCreateElement,
        DestroyElement = NDestroyElement,
        SetElementParent = NSetElementParent,
        DxCreateTexture = NDxCreateTexture,
        DxGetMaterialSize = NDxGetMaterialSize,
        GetCursorPosition = NGetCursorPosition,
        IsCursorShowing = NIsCursorShowing,
        OutputDebugString = NOutputDebugString,
    }

    --- Register Events
    for Index = 1, #GUI_EVENTS do
        NAddEvent(GUI_EVENTS[Index], true)
    end

    self.GuiEvents = GUI_EVENTS

    --- Add Events
    self:AddHandler("onClientRender", self.Root, function() self:RenderPass() end)
    self:AddHandler("onClientCursorMove", self.Root, function(...) self:CursorMove(...) end)
    self:AddHandler("onClientClick", self.Root, function(...) self:Click(...) end)
    self:AddHandler("onClientDoubleClick", self.Root, function(...) self:DoubleClick(...) end)
    self:AddHandler("onClientKey", self.Root, function(...) self:Key(...) end)
    self:AddHandler("onClientCharacter", self.Root, function(...) self:Character(...) end)
    self:AddHandler("onClientPaste", self.Root, function(...) self:Paste(...) end)
    self:AddHandler("onClientElementDestroy", self.Root, function() local Source = source; self:ElementDestroy(Source) end)
    self:AddHandler("onClientResourceStop", self.Root, function(...) local Source = source; self:ResourceStop(..., Source) end)
end

function _MTAX:Shutdown()
    if self.Stopped then
        return
    end

    self.Stopped = true

    for Index = #self.TopLevel, 1, -1 do
        local Widget = self.TopLevel[Index]

        if Widget and not Widget.Destroyed then
            self:DestroyWidget(Widget)
        end
    end

    for _, Widget in pairs(self.WidgetsById) do
        if not Widget.Destroyed then
            self:Unlink(Widget)
        end
    end

    for Key in pairs(self.WidgetsById) do
        self.WidgetsById[Key] = nil
    end

    for Index = #self.CustomFonts, 1, -1 do
        local Font = self.CustomFonts[Index]

        if Font ~= nil and Font.Element ~= nil and NIsElement(Font.Element) then
            pcall(NDestroyElement, Font.Element)
        end

        self.CustomFonts[Index] = nil
    end

    for Index = #self.TopLevel, 1, -1 do
        self.TopLevel[Index] = nil
    end

    self.Focused, self.Hovered, self.Captured, self.Pressed, self.Popup = nil, nil, nil, nil, nil
    self.CaptureMode, self.PressedButton = nil, nil
    self.PressX, self.PressY = nil, nil

    self:RemoveAllHandlers()
    self:Report()
end

local Main = _MTAX:New()

_G.mtaxGuiCompat = Main

Main:Init()

---@param FilePath string
---@param Size? number
---@return userdata|false
function guiCreateFont(FilePath, Size)
    return Main:CreateFont(FilePath, Size)
end

---@param Enabled boolean
---@return boolean
function guiSetInputEnabled(Enabled)
    Main:WarnOnce("inputmode", INPUT_MODE_WARNING)
    Main:Unsupported("guiSetInputEnabled", "recorded but not enforced; MTAX cannot suppress binds")

    Main.InputEnabled = Main:Truthy(Enabled)
    Main.InputMode = Main.InputEnabled and "no_binds" or "allow_binds"
    return true
end

---@return boolean
function guiGetInputEnabled()
    return Main.InputEnabled
end

---@param Mode string
---@return boolean
function guiSetInputMode(Mode)
    Main:WarnOnce("inputmode", INPUT_MODE_WARNING)
    Main:Unsupported("guiSetInputMode", "recorded but not enforced; MTAX cannot suppress binds")

    if type(Mode) ~= "string" or not VALID_INPUT_MODES[Mode] then
        return false
    end

    Main.InputMode = Mode
    Main.InputEnabled = (Mode ~= "allow_binds")
    return true
end

---@return string
function guiGetInputMode()
    return Main.InputMode
end

---@return string
function guiGetCursorType()
    if not NIsCursorShowing() then
        return "none"
    end

    Main:Unsupported("guiGetCursorType",
        "returns the cursor the shim WOULD show; MTAX has no way to change the drawn cursor image")

    return Main.LogicalCursor or "default"
end

Main:Define("guiCreateFont")
Main:Define("guiSetInputEnabled")
Main:Define("guiGetInputEnabled")
Main:Define("guiSetInputMode")
Main:Define("guiGetInputMode")
Main:Define("guiGetCursorType")

Main.Ready = true

Main:Info("core loaded (v" .. VERSION .. "). This is an EMULATION of MTA's CEGUI GUI, not an equivalent.")
