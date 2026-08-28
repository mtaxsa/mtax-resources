---- Developer by git@camargo2019

local _MTAX = rawget(_G, "mtaxGuiCompat")

if type(_MTAX) ~= "table" or _MTAX.Ready ~= true then
    if type(outputDebugString) == "function" then
        outputDebugString("[mtax_guicompat] widgets.lua: core.lua is not loaded, so no widget " ..
                          "function was defined. Put core.lua first in client_files.", 2)
    end
    return
end

if _MTAX.WidgetsReady == true then
    outputDebugString("[mtax_guicompat] widgets.lua: already loaded in this VM; nothing was " ..
                      "redefined. widgets.lua must appear exactly once in client_files.", 2)
    return
end

local NIsElement         = _MTAX.Natives.IsElement
local NGetElementType    = _MTAX.Natives.GetElementType
local NDestroyElement    = _MTAX.Natives.DestroyElement
local NDxCreateTexture   = _MTAX.Natives.DxCreateTexture
local NDxGetMaterialSize = _MTAX.Natives.DxGetMaterialSize

local Floor, Min, Max, Abs = math.floor, math.min, math.max, math.abs
local Rep, Format = string.rep, string.format
local Insert, Remove, Sort = table.insert, table.remove, table.sort

local PAD      = 4
local BORDER   = 1
local SCROLL_W = 14
local GRIP     = 6

local VALID_VALIGN = { top = true, center = true, bottom = true }
local VALID_HALIGN = { left = true, center = true, right = true }

local HORZ_FORMAT_TO_ALIGN = {
    LeftAligned = { "left", false },
    HorzCentred = { "center", false },
    RightAligned = { "right", false },
    WordWrapLeftAligned = { "left", true },
    WordWrapCentred = { "center", true },
    WordWrapRightAligned = { "right", true },
}

local ALIGN_TO_HORZ_FORMAT = {
    ["left|false"] = "LeftAligned",
    ["center|false"] = "HorzCentred",
    ["right|false"] = "RightAligned",
    ["left|true"] = "WordWrapLeftAligned",
    ["center|true"] = "WordWrapCentred",
    ["right|true"] = "WordWrapRightAligned",
}

local VERT_FORMAT_TO_ALIGN = { TopAligned = "top", VertCentred = "center", BottomAligned = "bottom" }
local ALIGN_TO_VERT_FORMAT = { top = "TopAligned", center = "VertCentred", bottom = "BottomAligned" }

--- Shared metrics

function _MTAX:LineH(Widget)
    return self:FontHeight(Widget.Font)
end

function _MTAX:RowH(Widget)
    return Floor(self:FontHeight(Widget.Font) + 4)
end

function _MTAX:TitleH(Widget)
    return Max(20, Floor(self:FontHeight(Widget.Font) + 8))
end

function _MTAX:Ct(Widget, Base)
    return self:WithAlpha(Base, Widget.EffectiveAlpha)
end

function _MTAX:TextColour(Widget)
    if not Widget.EffectiveEnabled then
        return self:Ct(Widget, self.Theme.TextDisabled)
    end

    if Widget.TextColor then
        return self:Ct(Widget, Widget.TextColor)
    end

    return self:Ct(Widget, self.Theme.Text)
end

--- Change notifications

function _MTAX:NoteTextChanged(Widget, OldText)
    if Widget.Text == OldText then
        return
    end

    if Widget.Type == "gui-edit" or Widget.Type == "gui-memo" then
        self:Fire("onClientGUIChanged", Widget)
    end
end

function _MTAX:NoteMoved(Widget)
    self:Fire("onClientGUIMove", Widget)
end

function _MTAX:NoteSized(Widget)
    self:Fire("onClientGUISize", Widget)
end

function _MTAX:StopInteracting(Widget)
    if self.Focused ~= nil and self:IsUnder(self.Focused, Widget) then
        self:Blur()
    end

    if self.Popup ~= nil and self:IsUnder(self.Popup, Widget) then
        local Class = self.Classes[self.Popup.Type]

        if Class and Class.ClosePopup then
            Class.ClosePopup(self, self.Popup)
        end
    end

    self:DropInteraction(Widget)
end

--- Cegui properties

function _MTAX:CeguiBool(Value)
    if type(Value) ~= "string" then
        return self:Truthy(Value)
    end

    local Lower = Value:lower()
    return Lower == "true" or Lower == "1" or Lower == "yes"
end

function _MTAX:BoolStr(Value)
    return Value and "True" or "False"
end

function _MTAX:ParseColour(Value)
    if type(Value) ~= "string" then
        return nil
    end

    local Hex = Value:match("^%s*(%x%x%x%x%x%x%x%x)%s*$")

    if not Hex then
        Hex = Value:match("tl:(%x%x%x%x%x%x%x%x)")
    end

    if not Hex then
        return nil
    end

    return tonumber(Hex, 16)
end

function _MTAX:ColourStr(Value)
    return Format("%08X", Floor(Value) % 0x100000000)
end

function _MTAX:Prop(Name, Get, Set)
    self.Props[Name] = { Get = Get, Set = Set }
end

_MTAX.Props = {}

_MTAX:Prop("Visible",
    function(self, Widget) return self:BoolStr(Widget.Visible) end,
    function(self, Widget, Value)
        Widget.Visible = self:CeguiBool(Value)

        if not Widget.Visible then
            self:StopInteracting(Widget)
        end

        self:MarkDirty()
        return true
    end)

_MTAX:Prop("Disabled",
    function(self, Widget) return self:BoolStr(not Widget.Enabled) end,
    function(self, Widget, Value)
        Widget.Enabled = not self:CeguiBool(Value)

        if not Widget.Enabled then
            self:StopInteracting(Widget)
        end

        self:MarkDirty()
        return true
    end)

_MTAX:Prop("Alpha",
    function(self, Widget) return Format("%.6f", Widget.Alpha) end,
    function(self, Widget, Value)
        local Alpha = self:Num(Value, nil)

        if Alpha == nil then
            return false
        end

        Widget.Alpha = self:Clamp(Alpha, 0, 1)
        self:MarkDirty()
        return true
    end)

_MTAX:Prop("InheritsAlpha",
    function(self, Widget) return self:BoolStr(Widget.InheritsAlpha) end,
    function(self, Widget, Value)
        Widget.InheritsAlpha = self:CeguiBool(Value)
        self:MarkDirty()
        return true
    end)

_MTAX:Prop("ClippedByParent",
    function(self, Widget) return self:BoolStr(Widget.ClippedByParent) end,
    function(self, Widget, Value)
        Widget.ClippedByParent = self:CeguiBool(Value)
        self:MarkDirty()
        return true
    end)

_MTAX:Prop("MousePassThroughEnabled",
    function(self, Widget) return self:BoolStr(Widget.MousePassThrough) end,
    function(self, Widget, Value)
        Widget.MousePassThrough = self:CeguiBool(Value)
        return true
    end)

_MTAX:Prop("AlwaysOnTop",
    function(self, Widget) return self:BoolStr(Widget.AlwaysOnTop == true) end,
    function(self, Widget, Value)
        Widget.AlwaysOnTop = self:CeguiBool(Value)

        if Widget.AlwaysOnTop then
            self:BringToFront(Widget)
        end

        return true
    end)

_MTAX:Prop("Text",
    function(self, Widget)
        local Class = self.Classes[Widget.Type]
        return (Class and Class.GetText) and Class.GetText(self, Widget) or Widget.Text
    end,
    function(self, Widget, Value)
        local Text = self:Str(Value, "")
        local Old = Widget.Text
        local Class = self.Classes[Widget.Type]

        if Class and Class.SetText then
            Class.SetText(self, Widget, Text)
        else
            Widget.Text = Text
        end

        Widget.WrapDirty, Widget.CaretDirty = true, true
        self:NoteTextChanged(Widget, Old)
        return true
    end)

_MTAX:Prop("Font",
    function(self, Widget) return type(Widget.Font) == "string" and Widget.Font or "" end,
    function(self, Widget, Value)
        if type(Value) ~= "string" then
            return false
        end

        if not self.GuiFonts[Value] and not self.DxFonts[Value] then
            return false
        end

        Widget.Font = Value
        Widget.WrapDirty, Widget.CaretDirty = true, true
        self:MarkDirty()
        return true
    end)

_MTAX:Prop("NormalTextColour",
    function(self, Widget) return self:ColourStr(Widget.TextColor or self.Theme.Text) end,
    function(self, Widget, Value)
        local Colour = self:ParseColour(Value)

        if Colour == nil then
            return false
        end

        Widget.TextColor = Colour
        return true
    end)

_MTAX:Prop("ID",
    function(self, Widget) return tostring(Widget.Props.ID or "0") end,
    function(self, Widget, Value)
        Widget.Props.ID = self:Str(Value, "0")
        return true
    end)

_MTAX:Prop("DragMovingEnabled",
    function(self, Widget) return self:BoolStr(Widget.Movable == true) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-window" then
            return false
        end

        Widget.Movable = self:CeguiBool(Value)
        return true
    end)

_MTAX:Prop("SizingEnabled",
    function(self, Widget) return self:BoolStr(Widget.Sizable == true) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-window" then
            return false
        end

        Widget.Sizable = self:CeguiBool(Value)
        return true
    end)

_MTAX:Prop("TitlebarEnabled",
    function(self, Widget) return self:BoolStr(Widget.TitleBar ~= false) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-window" then
            return false
        end

        Widget.TitleBar = self:CeguiBool(Value)
        self:MarkDirty()
        return true
    end)

_MTAX:Prop("CloseButtonEnabled",
    function(self, Widget) return self:BoolStr(Widget.CloseButton ~= false) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-window" then
            return false
        end

        Widget.CloseButton = self:CeguiBool(Value)
        return true
    end)

_MTAX:Prop("MaskText",
    function(self, Widget) return self:BoolStr(Widget.Masked == true) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-edit" then
            return false
        end

        Widget.Masked = self:CeguiBool(Value)
        Widget.CaretDirty = true
        return true
    end)

_MTAX:Prop("MaskCodepoint",
    function(self, Widget) return tostring(Widget.MaskCodepoint or 42) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-edit" then
            return false
        end

        local Codepoint = self:Num(Value, nil)

        if Codepoint == nil then
            return false
        end

        Widget.MaskCodepoint = Floor(Codepoint)

        local Ok, Char = pcall(utf8.char, Widget.MaskCodepoint)

        Widget.MaskChar = (Ok and Char) or "*"
        Widget.CaretDirty = true
        return true
    end)

_MTAX:Prop("MaxTextLength",
    function(self, Widget) return tostring(Widget.MaxLength or 0) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-edit" and Widget.Type ~= "gui-memo" then
            return false
        end

        local Length = self:Num(Value, nil)

        if Length == nil then
            return false
        end

        Widget.MaxLength = Max(0, Floor(Length))
        return true
    end)

_MTAX.Props["MaxEditTextLength"] = _MTAX.Props["MaxTextLength"]

_MTAX:Prop("ReadOnly",
    function(self, Widget) return self:BoolStr(Widget.ReadOnly == true) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-edit" and Widget.Type ~= "gui-memo" then
            return false
        end

        Widget.ReadOnly = self:CeguiBool(Value)
        return true
    end)

_MTAX:Prop("Selected",
    function(self, Widget) return self:BoolStr(Widget.Selected == true) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-checkbox" and Widget.Type ~= "gui-radiobutton" then
            return false
        end

        local Class = self.Classes[Widget.Type]
        Class.SetSelected(self, Widget, self:CeguiBool(Value))
        return true
    end)

_MTAX:Prop("CurrentProgress",
    function(self, Widget) return Format("%.6f", (Widget.Progress or 0) / 100) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-progressbar" then
            return false
        end

        local Progress = self:Num(Value, nil)

        if Progress == nil then
            return false
        end

        Widget.Progress = self:Clamp(Progress * 100, 0, 100)
        return true
    end)

_MTAX:Prop("WordWrap",
    function(self, Widget) return self:BoolStr(Widget.Wrap == true) end,
    function(self, Widget, Value)
        Widget.Wrap = self:CeguiBool(Value)
        Widget.WrapDirty = true
        return true
    end)

_MTAX:Prop("HorzFormatting",
    function(self, Widget)
        return ALIGN_TO_HORZ_FORMAT[(Widget.AlignX or "left") .. "|" .. tostring(Widget.Wrap == true)]
            or "LeftAligned"
    end,
    function(self, Widget, Value)
        local Mapped = HORZ_FORMAT_TO_ALIGN[self:Str(Value, "")]

        if not Mapped then
            return false
        end

        Widget.AlignX, Widget.Wrap = Mapped[1], Mapped[2]
        Widget.WrapDirty = true
        return true
    end)

_MTAX:Prop("VertFormatting",
    function(self, Widget) return ALIGN_TO_VERT_FORMAT[Widget.AlignY or "top"] or "TopAligned" end,
    function(self, Widget, Value)
        local Mapped = VERT_FORMAT_TO_ALIGN[self:Str(Value, "")]

        if not Mapped then
            return false
        end

        Widget.AlignY = Mapped
        return true
    end)

_MTAX:Prop("SortSettingEnabled",
    function(self, Widget) return self:BoolStr(Widget.SortingEnabled == true) end,
    function(self, Widget, Value)
        if Widget.Type ~= "gui-gridlist" then
            return false
        end

        Widget.SortingEnabled = self:CeguiBool(Value)
        return true
    end)

_MTAX.Props["SortList"] = _MTAX.Props["SortSettingEnabled"]

_MTAX:Prop("RowCount",
    function(self, Widget) return Widget.Type == "gui-gridlist" and tostring(#Widget.Rows) or "0" end,
    nil)

_MTAX:Prop("AbsoluteWidth", function(self, Widget) return Format("%.6f", Widget.W) end, nil)
_MTAX:Prop("AbsoluteHeight", function(self, Widget) return Format("%.6f", Widget.H) end, nil)
_MTAX:Prop("AbsoluteXPosition", function(self, Widget) return Format("%.6f", Widget.X) end, nil)
_MTAX:Prop("AbsoluteYPosition", function(self, Widget) return Format("%.6f", Widget.Y) end, nil)

--- Window

function _MTAX:WindowCloseRect(Widget)
    if Widget.TitleBar == false or Widget.CloseButton == false then
        return nil
    end

    local Height = self:TitleH(Widget)
    local Size = Height - 8

    if Size <= 0 or Widget.AW < Size + 8 then
        return nil
    end

    return Widget.AX + Widget.AW - Size - 4, Widget.AY + 4, Size, Size
end

function _MTAX:WindowGrip(Widget, X, Y)
    if not Widget.Sizable then
        return nil
    end

    local X1, Y1 = Widget.AX, Widget.AY
    local X2, Y2 = Widget.AX + Widget.AW, Widget.AY + Widget.AH

    if not self:PointIn(X, Y, X1 - GRIP, Y1 - GRIP, X2 + GRIP, Y2 + GRIP) then
        return nil
    end

    local Left = X <= X1 + GRIP
    local Right = X >= X2 - GRIP
    local Top = Y <= Y1 + GRIP
    local Bottom = Y >= Y2 - GRIP

    if Left and Top then return "size-nw" end
    if Right and Top then return "size-ne" end
    if Left and Bottom then return "size-sw" end
    if Right and Bottom then return "size-se" end
    if Left then return "size-w" end
    if Right then return "size-e" end
    if Top then return "size-n" end
    if Bottom then return "size-s" end

    return nil
end

_MTAX:Class("gui-window", {
    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme
        local X, Y, Width, Height = Widget.AX, Widget.AY, Widget.AW, Widget.AH

        self:FillRect(X, Y, Width, Height, self:Ct(Widget, Theme.WindowBody), Clip)

        local TitleHeight = Widget.TitleBar ~= false and self:TitleH(Widget) or 0

        if TitleHeight > 0 then
            self:FillRect(X, Y, Width, TitleHeight, self:Ct(Widget, Theme.WindowTitle), Clip)

            local BX, BY, BW, BH = self:WindowCloseRect(Widget)
            local TextRight = BX and (BX - 4) or (X + Width - PAD)

            self:DrawText(Widget.Text, X + PAD + 2, Y, TextRight, Y + TitleHeight,
                          self:Ct(Widget, Theme.WindowTitleText), Widget.Font, "left", "center", false, Clip)

            if BX then
                local Hovered = self.Hovered == Widget
                    and self:PointIn(self.CursorX, self.CursorY, BX, BY, BX + BW, BY + BH)

                self:FillRect(BX, BY, BW, BH,
                              self:Ct(Widget, Hovered and Theme.CloseHover or Theme.CloseNormal), Clip)

                local CX, CY = BX + BW / 2, BY + BH / 2
                local Size = Max(2, Floor(BW * 0.28))

                self:FillRect(CX - Size, CY - 1, Size * 2, 2, self:Ct(Widget, Theme.CloseGlyph), Clip)
                self:FillRect(CX - 1, CY - Size, 2, Size * 2, self:Ct(Widget, Theme.CloseGlyph), Clip)
            end
        end

        self:FrameRect(X, Y, Width, Height, BORDER, self:Ct(Widget, Theme.WindowBorder), Clip)

        if Widget.Sizable then
            local Colour = self:Ct(Widget, Theme.Grip)

            for Index = 1, 3 do
                self:FillRect(X + Width - 3 - Index * 4, Y + Height - 4, 3, 3, Colour, Clip)
                self:FillRect(X + Width - 4, Y + Height - 3 - Index * 4, 3, 3, Colour, Clip)
            end
        end
    end,

    OnMouseDown = function(self, Widget, Button, X, Y)
        if Button ~= "left" then
            return
        end

        local BX, BY, BW, BH = self:WindowCloseRect(Widget)

        if BX and self:PointIn(X, Y, BX, BY, BX + BW, BY + BH) then
            self:Unsupported("window close button",
                "MTA's onClientGUIClose is never fired, so the X does nothing there either. " ..
                "Hide the window from your own handler.")

            Widget.ClosePressed = true
            return
        end

        local Grip = self:WindowGrip(Widget, X, Y)

        if Grip then
            self:Capture(Widget, Grip)
            Widget.DragX, Widget.DragY = X, Y
            Widget.DragW, Widget.DragH = Widget.W, Widget.H
            Widget.DragOX, Widget.DragOY = Widget.X, Widget.Y
            self.LogicalCursor = self.CursorTypeNames[Grip] or "default"
            return
        end

        local TitleHeight = Widget.TitleBar ~= false and self:TitleH(Widget) or 0

        if Widget.Movable and TitleHeight > 0 and Y < Widget.AY + TitleHeight then
            self:Capture(Widget, "move")
            Widget.DragX, Widget.DragY = X - Widget.AX, Y - Widget.AY
            self.LogicalCursor = "sizing_move"
        end
    end,

    OnDrag = function(self, Widget, X, Y)
        local Mode = self.CaptureMode

        if Mode == "move" then
            local PX, PY = self:ParentBox(Widget)
            local NX, NY = X - Widget.DragX - PX, Y - Widget.DragY - PY

            if NX ~= Widget.X or NY ~= Widget.Y then
                Widget.X, Widget.Y = NX, NY
                self:MarkDirty()
                self:NoteMoved(Widget)
            end

            return
        end

        if Mode == nil or Mode:sub(1, 5) ~= "size-" then
            return
        end

        local DX, DY = X - Widget.DragX, Y - Widget.DragY
        local NX, NY = Widget.DragOX, Widget.DragOY
        local NW, NH = Widget.DragW, Widget.DragH
        local Edge = Mode:sub(6)

        if Edge:find("e") then NW = Widget.DragW + DX end
        if Edge:find("s") then NH = Widget.DragH + DY end
        if Edge:find("w") then NW = Widget.DragW - DX; NX = Widget.DragOX + DX end
        if Edge:find("n") then NH = Widget.DragH - DY; NY = Widget.DragOY + DY end

        local MinW, MinH = 40, Max(24, self:TitleH(Widget) + 8)

        if NW < MinW then
            if Edge:find("w") then
                NX = NX - (MinW - NW)
            end

            NW = MinW
        end

        if NH < MinH then
            if Edge:find("n") then
                NY = NY - (MinH - NH)
            end

            NH = MinH
        end

        local Moved = (NX ~= Widget.X or NY ~= Widget.Y)
        local Sized = (NW ~= Widget.W or NH ~= Widget.H)

        Widget.X, Widget.Y, Widget.W, Widget.H = NX, NY, NW, NH

        if Moved or Sized then
            self:MarkDirty()
        end

        if Moved then
            self:NoteMoved(Widget)
        end

        if Sized then
            Widget.WrapDirty = true
            self:NoteSized(Widget)
        end
    end,

    OnDragEnd = function(self)
        self.LogicalCursor = "default"
    end,

    OnMouseUp = function(self, Widget)
        Widget.ClosePressed = nil
    end,

    OnEnter = function(self, Widget) end,

    OnLeave = function(self)
        self.LogicalCursor = "default"
    end,
})

--- Label

_MTAX:Class("gui-label", {
    Draw = function(self, Widget)
        self:DrawText(Widget.Text, Widget.AX, Widget.AY, Widget.AX + Widget.AW, Widget.AY + Widget.AH,
                      self:TextColour(Widget), Widget.Font, Widget.AlignX or "left",
                      Widget.AlignY or "top", Widget.Wrap == true, self:Clip(Widget))
    end,
})

--- Button

_MTAX:Class("gui-button", {
    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme
        local Background

        if not Widget.EffectiveEnabled then
            Background = Theme.ButtonDisabled
        elseif self.Pressed == Widget and self.Hovered == Widget then
            Background = Theme.ButtonPushed
        elseif self.Hovered == Widget then
            Background = Theme.ButtonHover
        else
            Background = Theme.ButtonNormal
        end

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, self:Ct(Widget, Background), Clip)
        self:FrameRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, BORDER,
                       self:Ct(Widget, Theme.ButtonBorder), Clip)
        self:DrawText(Widget.Text, Widget.AX + PAD, Widget.AY, Widget.AX + Widget.AW - PAD,
                      Widget.AY + Widget.AH, self:TextColour(Widget), Widget.Font,
                      "center", "center", false, Clip)
    end,
})

--- Static image

function _MTAX:LoadTexture(Widget, Path)
    if type(Path) ~= "string" or Path == "" then
        return false
    end

    local Ok, Texture = pcall(NDxCreateTexture, Path)

    if not Ok or Texture == false or Texture == nil or not NIsElement(Texture) then
        return false
    end

    if Widget.Texture ~= nil and NIsElement(Widget.Texture) then
        NDestroyElement(Widget.Texture)
    end

    Widget.Texture = Texture
    Widget.Path = Path
    return true
end

_MTAX:Class("gui-staticimage", {
    Draw = function(self, Widget)
        if Widget.Texture == nil then
            return
        end

        self:DrawImage(Widget.AX, Widget.AY, Widget.AW, Widget.AH, Widget.Texture,
                       self:WithAlpha(self:Argb(255, 255, 255, 255), Widget.EffectiveAlpha),
                       self:Clip(Widget))
    end,

    Dispose = function(self, Widget)
        if Widget.Texture ~= nil and NIsElement(Widget.Texture) then
            NDestroyElement(Widget.Texture)
        end

        Widget.Texture = nil
    end,
})

--- Edit

function _MTAX:EditVisibleText(Widget)
    if Widget.Masked then
        return Rep(Widget.MaskChar or "*", self:ULen(Widget.Text))
    end

    return Widget.Text
end

function _MTAX:EditReflow(Widget)
    if not Widget.CaretDirty then
        return
    end

    Widget.CaretDirty = false

    local Visible = self:EditVisibleText(Widget)
    local Length = self:ULen(Visible)

    if Widget.Caret > Length then Widget.Caret = Length end
    if Widget.Caret < 0 then Widget.Caret = 0 end

    local View = Widget.AW - PAD * 2 - BORDER * 2

    if View <= 0 then
        Widget.ScrollChar = 1
        return
    end

    local First = Widget.ScrollChar or 1

    if First > Widget.Caret + 1 then First = Widget.Caret + 1 end
    if First < 1 then First = 1 end

    local Guard = 0

    while First <= Widget.Caret and Guard <= Length do
        if self:TextWidth(self:USub(Visible, First, Widget.Caret), Widget.Font) <= View then
            break
        end

        First = First + 1
        Guard = Guard + 1
    end

    while First > 1 and self:TextWidth(self:USub(Visible, First - 1, Length), Widget.Font) <= View do
        First = First - 1
    end

    Widget.ScrollChar = First
    Widget.VisibleText = Visible
end

function _MTAX:EditInsert(Widget, Text)
    if Widget.ReadOnly then
        return
    end

    if type(Text) ~= "string" or Text == "" then
        return
    end

    Text = Text:gsub("[\r\n]", " ")

    local Old = Widget.Text
    local Length = self:ULen(Widget.Text)
    local Added = self:ULen(Text)

    if Widget.MaxLength and Widget.MaxLength > 0 then
        local Room = Widget.MaxLength - Length

        if Room <= 0 then
            return
        end

        if Added > Room then
            Text = self:USub(Text, 1, Room)
            Added = Room
        end
    end

    Widget.Text = self:USub(Widget.Text, 1, Widget.Caret) .. Text ..
                  self:USub(Widget.Text, Widget.Caret + 1, Length)
    Widget.Caret = Widget.Caret + Added
    Widget.CaretDirty = true

    self:NoteTextChanged(Widget, Old)
end

function _MTAX:EditBackspace(Widget)
    if Widget.ReadOnly or Widget.Caret <= 0 then
        return
    end

    local Old = Widget.Text
    local Length = self:ULen(Widget.Text)

    Widget.Text = self:USub(Widget.Text, 1, Widget.Caret - 1) ..
                  self:USub(Widget.Text, Widget.Caret + 1, Length)
    Widget.Caret = Widget.Caret - 1
    Widget.CaretDirty = true

    self:NoteTextChanged(Widget, Old)
end

function _MTAX:EditDelete(Widget)
    if Widget.ReadOnly then
        return
    end

    local Length = self:ULen(Widget.Text)

    if Widget.Caret >= Length then
        return
    end

    local Old = Widget.Text

    Widget.Text = self:USub(Widget.Text, 1, Widget.Caret) ..
                  self:USub(Widget.Text, Widget.Caret + 2, Length)
    Widget.CaretDirty = true

    self:NoteTextChanged(Widget, Old)
end

function _MTAX:CaretVisible()
    return (Floor(self:Tick() / 500) % 2) == 0
end

_MTAX:Class("gui-edit", {
    Reflow = function(self, Widget)
        self:EditReflow(Widget)
    end,

    Draw = function(self, Widget)
        self:EditReflow(Widget)

        local Clip = self:Clip(Widget)
        local Theme = self.Theme

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, self:Ct(Widget, Theme.FieldBg), Clip)
        self:FrameRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, BORDER,
                       self:Ct(Widget, (self.Focused == Widget) and Theme.FieldBorderFocus or Theme.FieldBorder),
                       Clip)

        local Inner = self:InnerClip(Widget, PAD, BORDER, PAD, BORDER)
        local Visible = Widget.VisibleText or self:EditVisibleText(Widget)
        local First = Widget.ScrollChar or 1
        local Shown = self:USub(Visible, First)
        local TextX = Widget.AX + PAD
        local TextY1, TextY2 = Widget.AY + BORDER, Widget.AY + Widget.AH - BORDER

        self:DrawText(Shown, TextX, TextY1, Widget.AX + Widget.AW - PAD, TextY2,
                      self:TextColour(Widget), Widget.Font, "left", "center", false, Inner)

        if self.Focused == Widget and Widget.EffectiveEnabled and not Widget.ReadOnly
           and self:CaretVisible() then
            local CX = TextX + self:TextWidth(self:USub(Visible, First, Widget.Caret), Widget.Font)
            local Height = self:FontHeight(Widget.Font)

            self:FillRect(CX, Widget.AY + (Widget.AH - Height) / 2, 1, Height,
                          self:Ct(Widget, Theme.Caret), Inner)
        end
    end,

    SetText = function(self, Widget, Text)
        Widget.Text = Text:gsub("[\r\n]", " ")

        if Widget.MaxLength and Widget.MaxLength > 0 and self:ULen(Widget.Text) > Widget.MaxLength then
            Widget.Text = self:USub(Widget.Text, 1, Widget.MaxLength)
        end

        Widget.Caret = self:ULen(Widget.Text)
        Widget.CaretDirty = true
    end,

    OnMouseDown = function(self, Widget, Button, X, Y)
        if Button ~= "left" then
            return
        end

        self:EditReflow(Widget)

        local Visible = Widget.VisibleText or self:EditVisibleText(Widget)
        local First = Widget.ScrollChar or 1
        local Length = self:ULen(Visible)
        local RelX = X - (Widget.AX + PAD)
        local Best, BestDistance = First - 1, math.huge

        for Index = First - 1, Length do
            local Distance = Abs(self:TextWidth(self:USub(Visible, First, Index), Widget.Font) - RelX)

            if Distance < BestDistance then
                Best, BestDistance = Index, Distance
            else
                break
            end
        end

        Widget.Caret = self:Clamp(Best, 0, Length)
        Widget.CaretDirty = true
    end,

    OnDoubleClick = function(self)
        self:Unsupported("edit double-click word select",
            "CEGUI selects the word under the cursor; MTAX exposes no text selection primitives")
    end,

    OnKey = function(self, Widget, Key)
        local Length = self:ULen(Widget.Text)

        if Key == "arrow_l" then
            if self:ShiftHeld() then
                self:Unsupported("shift+arrow selection in an edit box",
                    "there is no selection model; the caret moves without selecting")
            end

            Widget.Caret = Max(0, Widget.Caret - 1)
            Widget.CaretDirty = true
        elseif Key == "arrow_r" then
            Widget.Caret = Min(Length, Widget.Caret + 1)
            Widget.CaretDirty = true
        elseif Key == "home" then
            Widget.Caret = 0
            Widget.CaretDirty = true
        elseif Key == "end" then
            Widget.Caret = Length
            Widget.CaretDirty = true
        elseif Key == "backspace" then
            self:EditBackspace(Widget)
        elseif Key == "delete" then
            self:EditDelete(Widget)
        elseif Key == "enter" or Key == "num_enter" then
            self:Fire("onClientGUIAccepted", Widget)
        elseif Key == "c" and self:CtrlHeld() then
            self:Unsupported("Ctrl+C in an edit box",
                "no selection exists, so the WHOLE field is copied instead of a selection")
            self:SetClipboard(Widget.Text)
        elseif Key == "x" and self:CtrlHeld() then
            self:Unsupported("Ctrl+X in an edit box",
                "no selection exists, so the WHOLE field is cut instead of a selection")

            if not Widget.ReadOnly then
                self:SetClipboard(Widget.Text)

                local Old = Widget.Text

                Widget.Text, Widget.Caret, Widget.CaretDirty = "", 0, true
                self:NoteTextChanged(Widget, Old)
            end
        elseif Key == "a" and self:CtrlHeld() then
            self:Unsupported("Ctrl+A in an edit box", "there is no selection to make")
        end
    end,

    OnCharacter = function(self, Widget, Character)
        if self:CtrlHeld() then
            return
        end

        self:EditInsert(Widget, Character)
    end,

    OnPaste = function(self, Widget, Text)
        self:EditInsert(Widget, Text)
    end,
})

--- Memo

function _MTAX:MemoWrap(Widget)
    if not Widget.WrapDirty and Widget.Lines then
        return Widget.Lines
    end

    Widget.WrapDirty = false

    local View = Widget.AW - PAD * 2 - SCROLL_W - BORDER * 2
    local Lines = {}
    local Starts = {}
    local Consumed = 0

    if View <= 8 then
        Widget.Lines, Widget.LineStarts = { Widget.Text }, { 0 }
        return Widget.Lines
    end

    for Hard in (Widget.Text .. "\n"):gmatch("([^\n]*)\n") do
        local HardLength = self:ULen(Hard)

        if HardLength == 0 then
            Lines[#Lines + 1] = ""
            Starts[#Starts + 1] = Consumed
        else
            local Position = 1

            while Position <= HardLength do
                local Remaining = HardLength - Position + 1
                local Fit

                if self:TextWidth(self:USub(Hard, Position, HardLength), Widget.Font) <= View then
                    Fit = Remaining
                else
                    local Low, High = 1, Remaining

                    while Low < High do
                        local Mid = (Low + High + 1) // 2

                        if self:TextWidth(self:USub(Hard, Position, Position + Mid - 1), Widget.Font) <= View then
                            Low = Mid
                        else
                            High = Mid - 1
                        end
                    end

                    Fit = Max(1, Low)
                end

                if Position + Fit - 1 < HardLength then
                    local Slice = self:USub(Hard, Position, Position + Fit - 1)
                    local LastSpace = nil

                    for Index = self:ULen(Slice), 1, -1 do
                        if self:USub(Slice, Index, Index) == " " then
                            LastSpace = Index
                            break
                        end
                    end

                    if LastSpace and LastSpace > 1 then
                        Fit = LastSpace
                    end
                end

                Lines[#Lines + 1] = self:USub(Hard, Position, Position + Fit - 1)
                Starts[#Starts + 1] = Consumed + Position - 1
                Position = Position + Fit
            end
        end

        Consumed = Consumed + HardLength + 1
    end

    if #Lines == 0 then
        Lines[1] = ""
        Starts[1] = 0
    end

    Widget.Lines, Widget.LineStarts = Lines, Starts
    return Lines
end

function _MTAX:MemoVisibleLines(Widget)
    local Height = self:LineH(Widget)

    if Height <= 0 then
        return 1
    end

    return Max(1, Floor((Widget.AH - BORDER * 2) / Height))
end

function _MTAX:MemoMaxScroll(Widget)
    return Max(0, #self:MemoWrap(Widget) - self:MemoVisibleLines(Widget))
end

function _MTAX:MemoClampScroll(Widget)
    Widget.ScrollLine = self:Clamp(Floor(Widget.ScrollLine or 0), 0, self:MemoMaxScroll(Widget))
end

function _MTAX:MemoCaretLine(Widget)
    local Lines, Starts = self:MemoWrap(Widget), Widget.LineStarts

    for Index = #Lines, 1, -1 do
        if Widget.Caret >= Starts[Index] then
            return Index, Widget.Caret - Starts[Index]
        end
    end

    return 1, Widget.Caret
end

function _MTAX:MemoInsert(Widget, Text)
    if Widget.ReadOnly then
        return
    end

    if type(Text) ~= "string" or Text == "" then
        return
    end

    local Old = Widget.Text
    local Length = self:ULen(Widget.Text)
    local Added = self:ULen(Text)

    if Widget.MaxLength and Widget.MaxLength > 0 then
        local Room = Widget.MaxLength - Length

        if Room <= 0 then
            return
        end

        if Added > Room then
            Text = self:USub(Text, 1, Room)
            Added = Room
        end
    end

    Widget.Text = self:USub(Widget.Text, 1, Widget.Caret) .. Text ..
                  self:USub(Widget.Text, Widget.Caret + 1, Length)
    Widget.Caret = Widget.Caret + Added
    Widget.WrapDirty = true

    self:NoteTextChanged(Widget, Old)
end

_MTAX:Class("gui-memo", {
    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, self:Ct(Widget, Theme.FieldBg), Clip)
        self:FrameRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, BORDER,
                       self:Ct(Widget, (self.Focused == Widget) and Theme.FieldBorderFocus or Theme.FieldBorder),
                       Clip)

        local Lines = self:MemoWrap(Widget)

        self:MemoClampScroll(Widget)

        local LineHeight = self:LineH(Widget)
        local VisibleCount = self:MemoVisibleLines(Widget)
        local Inner = self:InnerClip(Widget, BORDER, BORDER, SCROLL_W + BORDER, BORDER)
        local X1 = Widget.AX + PAD
        local X2 = Widget.AX + Widget.AW - SCROLL_W - PAD
        local Colour = self:TextColour(Widget)
        local CaretLine, CaretColumn = self:MemoCaretLine(Widget)

        for Index = 1, VisibleCount do
            local LineIndex = Widget.ScrollLine + Index
            local Line = Lines[LineIndex]

            if Line == nil then
                break
            end

            local LineY = Widget.AY + BORDER + (Index - 1) * LineHeight

            self:DrawText(Line, X1, LineY, X2, LineY + LineHeight, Colour, Widget.Font,
                          "left", "top", false, Inner)

            if self.Focused == Widget and Widget.EffectiveEnabled and not Widget.ReadOnly
               and LineIndex == CaretLine and self:CaretVisible() then
                local CX = X1 + self:TextWidth(self:USub(Line, 1, CaretColumn), Widget.Font)
                self:FillRect(CX, LineY, 1, LineHeight, self:Ct(Widget, Theme.Caret), Inner)
            end
        end

        local ScrollX = Widget.AX + Widget.AW - SCROLL_W - BORDER
        local ScrollY = Widget.AY + BORDER
        local ScrollH = Widget.AH - BORDER * 2

        self:FillRect(ScrollX, ScrollY, SCROLL_W, ScrollH, self:Ct(Widget, Theme.ScrollTrack), Clip)

        local Total = #Lines

        if Total > VisibleCount then
            local ThumbH = Max(16, ScrollH * VisibleCount / Total)
            local Range = ScrollH - ThumbH
            local MaxScroll = self:MemoMaxScroll(Widget)
            local ThumbY = ScrollY + (MaxScroll > 0 and (Widget.ScrollLine / MaxScroll * Range) or 0)

            self:FillRect(ScrollX + 1, ThumbY, SCROLL_W - 2, ThumbH,
                          self:Ct(Widget, Theme.ScrollThumb), Clip)
        end
    end,

    SetText = function(self, Widget, Text)
        Widget.Text = Text

        if Widget.MaxLength and Widget.MaxLength > 0 and self:ULen(Widget.Text) > Widget.MaxLength then
            Widget.Text = self:USub(Widget.Text, 1, Widget.MaxLength)
        end

        Widget.Caret = self:ULen(Widget.Text)
        Widget.WrapDirty = true
    end,

    OnWheel = function(self, Widget, Delta)
        local Before = Widget.ScrollLine or 0

        Widget.ScrollLine = Before + Delta * 3
        self:MemoClampScroll(Widget)

        return Widget.ScrollLine ~= Before
    end,

    OnMouseDown = function(self, Widget, Button, X, Y)
        if Button ~= "left" then
            return
        end

        local Lines = self:MemoWrap(Widget)
        local LineHeight = self:LineH(Widget)
        local ScrollX = Widget.AX + Widget.AW - SCROLL_W - BORDER

        if X >= ScrollX then
            local VisibleCount = self:MemoVisibleLines(Widget)
            local Middle = Widget.AY + Widget.AH / 2

            Widget.ScrollLine = (Widget.ScrollLine or 0) + (Y < Middle and -VisibleCount or VisibleCount)
            self:MemoClampScroll(Widget)
            self:Fire("onClientGUIScroll", Widget)
            return
        end

        local LineIndex = (Widget.ScrollLine or 0) + Floor((Y - Widget.AY - BORDER) / LineHeight) + 1

        LineIndex = self:Clamp(LineIndex, 1, #Lines)

        local Line = Lines[LineIndex]
        local RelX = X - (Widget.AX + PAD)
        local Best, BestDistance = 0, math.huge

        for Index = 0, self:ULen(Line) do
            local Distance = Abs(self:TextWidth(self:USub(Line, 1, Index), Widget.Font) - RelX)

            if Distance < BestDistance then
                Best, BestDistance = Index, Distance
            else
                break
            end
        end

        Widget.Caret = self:Clamp((Widget.LineStarts[LineIndex] or 0) + Best, 0, self:ULen(Widget.Text))
    end,

    OnKey = function(self, Widget, Key)
        local Length = self:ULen(Widget.Text)

        if Key == "arrow_l" then
            Widget.Caret = Max(0, Widget.Caret - 1)
        elseif Key == "arrow_r" then
            Widget.Caret = Min(Length, Widget.Caret + 1)
        elseif Key == "arrow_u" or Key == "arrow_d" then
            local LineIndex, Column = self:MemoCaretLine(Widget)
            local Target = LineIndex + (Key == "arrow_u" and -1 or 1)
            local Lines = self:MemoWrap(Widget)

            Target = self:Clamp(Target, 1, #Lines)
            Widget.Caret = self:Clamp((Widget.LineStarts[Target] or 0) +
                                      Min(Column, self:ULen(Lines[Target])), 0, Length)
        elseif Key == "home" then
            local LineIndex = self:MemoCaretLine(Widget)
            Widget.Caret = Widget.LineStarts[LineIndex] or 0
        elseif Key == "end" then
            local LineIndex = self:MemoCaretLine(Widget)
            local Lines = self:MemoWrap(Widget)

            Widget.Caret = self:Clamp((Widget.LineStarts[LineIndex] or 0) +
                                      self:ULen(Lines[LineIndex] or ""), 0, Length)
        elseif Key == "pgup" then
            Widget.ScrollLine = (Widget.ScrollLine or 0) - self:MemoVisibleLines(Widget)
            self:MemoClampScroll(Widget)
        elseif Key == "pgdn" then
            Widget.ScrollLine = (Widget.ScrollLine or 0) + self:MemoVisibleLines(Widget)
            self:MemoClampScroll(Widget)
        elseif Key == "backspace" then
            if not Widget.ReadOnly and Widget.Caret > 0 then
                local Old = Widget.Text

                Widget.Text = self:USub(Widget.Text, 1, Widget.Caret - 1) ..
                              self:USub(Widget.Text, Widget.Caret + 1, Length)
                Widget.Caret = Widget.Caret - 1
                Widget.WrapDirty = true

                self:NoteTextChanged(Widget, Old)
            end
        elseif Key == "delete" then
            if not Widget.ReadOnly and Widget.Caret < Length then
                local Old = Widget.Text

                Widget.Text = self:USub(Widget.Text, 1, Widget.Caret) ..
                              self:USub(Widget.Text, Widget.Caret + 2, Length)
                Widget.WrapDirty = true

                self:NoteTextChanged(Widget, Old)
            end
        elseif Key == "enter" or Key == "num_enter" then
            self:MemoInsert(Widget, "\n")
        elseif Key == "c" and self:CtrlHeld() then
            self:Unsupported("Ctrl+C in a memo", "no selection exists, so the WHOLE memo is copied")
            self:SetClipboard(Widget.Text)
        end

        local LineIndex = self:MemoCaretLine(Widget)
        local VisibleCount = self:MemoVisibleLines(Widget)

        if LineIndex <= (Widget.ScrollLine or 0) then
            Widget.ScrollLine = LineIndex - 1
        end

        if LineIndex > (Widget.ScrollLine or 0) + VisibleCount then
            Widget.ScrollLine = LineIndex - VisibleCount
        end

        self:MemoClampScroll(Widget)
    end,

    OnCharacter = function(self, Widget, Character)
        if self:CtrlHeld() then
            return
        end

        self:MemoInsert(Widget, Character)
    end,

    OnPaste = function(self, Widget, Text)
        self:MemoInsert(Widget, Text)
    end,
})

--- Checkbox

function _MTAX:BoxSize(Widget)
    return Min(16, Max(10, Floor(self:FontHeight(Widget.Font))))
end

_MTAX:Class("gui-checkbox", {
    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme
        local Size = self:BoxSize(Widget)
        local BX = Widget.AX
        local BY = Widget.AY + (Widget.AH - Size) / 2

        self:FillRect(BX, BY, Size, Size, self:Ct(Widget, Theme.FieldBg), Clip)
        self:FrameRect(BX, BY, Size, Size, BORDER,
                       self:Ct(Widget, self.Hovered == Widget and Theme.FieldBorderFocus or Theme.FieldBorder),
                       Clip)

        if Widget.Selected then
            self:FillRect(BX + 3, BY + 3, Size - 6, Size - 6,
                          self:Ct(Widget, Widget.EffectiveEnabled and Theme.Check or Theme.TextDisabled),
                          Clip)
        end

        self:DrawText(Widget.Text, BX + Size + 5, Widget.AY, Widget.AX + Widget.AW,
                      Widget.AY + Widget.AH, self:TextColour(Widget), Widget.Font,
                      "left", "center", false, Clip)
    end,

    SetSelected = function(self, Widget, State)
        Widget.Selected = State and true or false
    end,

    OnMouseUp = function(self, Widget, Button, X, Y, Over)
        if Button ~= "left" or not Over then
            return
        end

        Widget.Selected = not Widget.Selected
    end,
})

--- Radio button

function _MTAX:RadioSelect(Widget, State)
    if not State then
        Widget.Selected = false
        return
    end

    Widget.Selected = true

    local List = self:SiblingList(Widget)

    for Index = 1, #List do
        local Sibling = List[Index]

        if Sibling ~= Widget and Sibling.Type == "gui-radiobutton"
           and Sibling.GroupId == Widget.GroupId then
            Sibling.Selected = false
        end
    end
end

_MTAX:Class("gui-radiobutton", {
    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme
        local Size = self:BoxSize(Widget)
        local BX = Widget.AX
        local BY = Widget.AY + (Widget.AH - Size) / 2

        self:FillRect(BX, BY, Size, Size, self:Ct(Widget, Theme.FieldBg), Clip)
        self:FrameRect(BX, BY, Size, Size, BORDER,
                       self:Ct(Widget, self.Hovered == Widget and Theme.FieldBorderFocus or Theme.FieldBorder),
                       Clip)

        if Widget.Selected then
            local Inset = Floor(Size / 4)

            self:FillRect(BX + Inset, BY + Inset, Size - Inset * 2, Size - Inset * 2,
                          self:Ct(Widget, Widget.EffectiveEnabled and Theme.Check or Theme.TextDisabled),
                          Clip)
        end

        self:DrawText(Widget.Text, BX + Size + 5, Widget.AY, Widget.AX + Widget.AW,
                      Widget.AY + Widget.AH, self:TextColour(Widget), Widget.Font,
                      "left", "center", false, Clip)
    end,

    SetSelected = function(self, Widget, State)
        self:RadioSelect(Widget, State)
    end,

    OnMouseUp = function(self, Widget, Button, X, Y, Over)
        if Button ~= "left" or not Over then
            return
        end

        self:RadioSelect(Widget, true)
    end,
})

--- Progress bar

_MTAX:Class("gui-progressbar", {
    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, self:Ct(Widget, Theme.ProgressBg), Clip)

        local Progress = self:Clamp(Widget.Progress or 0, 0, 100) / 100

        if Progress > 0 then
            self:FillRect(Widget.AX + BORDER, Widget.AY + BORDER,
                          (Widget.AW - BORDER * 2) * Progress, Widget.AH - BORDER * 2,
                          self:Ct(Widget, Theme.ProgressFill), Clip)
        end

        self:FrameRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, BORDER,
                       self:Ct(Widget, Theme.FieldBorder), Clip)
    end,
})

--- Scrollbar

function _MTAX:ScrollbarGeometry(Widget)
    local Horizontal = Widget.Horizontal == true
    local TrackLength = Horizontal and Widget.AW or Widget.AH
    local ThumbLength = Max(16, TrackLength * 0.25)
    local Range = Max(0, TrackLength - ThumbLength)
    local Position = self:Clamp(Widget.Position or 0, 0, 100) / 100

    return Horizontal, TrackLength, ThumbLength, Range, Range * Position
end

_MTAX:Class("gui-scrollbar", {
    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, self:Ct(Widget, Theme.ScrollTrack), Clip)

        local Horizontal, _, ThumbLength, _, Offset = self:ScrollbarGeometry(Widget)
        local Hot = (self.Hovered == Widget or self.Captured == Widget)
        local Colour = self:Ct(Widget, Hot and Theme.ScrollThumbHover or Theme.ScrollThumb)

        if Horizontal then
            self:FillRect(Widget.AX + Offset, Widget.AY + 1, ThumbLength, Widget.AH - 2, Colour, Clip)
        else
            self:FillRect(Widget.AX + 1, Widget.AY + Offset, Widget.AW - 2, ThumbLength, Colour, Clip)
        end

        self:FrameRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, BORDER,
                       self:Ct(Widget, Theme.PanelBorder), Clip)
    end,

    OnMouseDown = function(self, Widget, Button, X, Y)
        if Button ~= "left" then
            return
        end

        local Horizontal, _, ThumbLength, _, Offset = self:ScrollbarGeometry(Widget)
        local Local = Horizontal and (X - Widget.AX) or (Y - Widget.AY)

        if Local >= Offset and Local < Offset + ThumbLength then
            self:Capture(Widget, "thumb")
            Widget.GrabOffset = Local - Offset
        else
            local Step = (Local < Offset) and -10 or 10
            local Before = Widget.Position or 0

            Widget.Position = self:Clamp(Before + Step, 0, 100)

            if Widget.Position ~= Before then
                self:Fire("onClientGUIScroll", Widget)
            end
        end
    end,

    OnDrag = function(self, Widget, X, Y)
        if self.CaptureMode ~= "thumb" then
            return
        end

        local Horizontal, _, _, Range = self:ScrollbarGeometry(Widget)

        if Range <= 0 then
            return
        end

        local Local = (Horizontal and (X - Widget.AX) or (Y - Widget.AY)) - (Widget.GrabOffset or 0)
        local Before = Widget.Position or 0

        Widget.Position = self:Clamp(Local / Range * 100, 0, 100)

        if Widget.Position ~= Before then
            self:Fire("onClientGUIScroll", Widget)
        end
    end,

    OnWheel = function(self, Widget, Delta)
        local Before = Widget.Position or 0

        Widget.Position = self:Clamp(Before + Delta * 5, 0, 100)
        return Widget.Position ~= Before
    end,
})

--- Scroll pane

function _MTAX:PaneContentExtent(Widget)
    local MaxX, MaxY = 0, 0
    local Children = Widget.Children

    for Index = 1, #Children do
        local Child = Children[Index]
        local Right = Child.X + Child.W
        local Bottom = Child.Y + Child.H

        if Right > MaxX then MaxX = Right end
        if Bottom > MaxY then MaxY = Bottom end
    end

    return MaxX, MaxY
end

function _MTAX:PaneViewSize(Widget)
    local ViewW = Widget.AW - (Widget.VBar and SCROLL_W or 0)
    local ViewH = Widget.AH - (Widget.HBar and SCROLL_W or 0)

    return Max(0, ViewW), Max(0, ViewH)
end

_MTAX:Class("gui-scrollpane", {
    ChildArea = function(self, Widget)
        local ContentW, ContentH = self:PaneContentExtent(Widget)
        local ViewW, ViewH = self:PaneViewSize(Widget)
        local OffsetX = Max(0, ContentW - ViewW) * self:Clamp(Widget.ScrollX or 0, 0, 1)
        local OffsetY = Max(0, ContentH - ViewH) * self:Clamp(Widget.ScrollY or 0, 0, 1)

        return Widget.AX - OffsetX, Widget.AY - OffsetY, ViewW, ViewH
    end,

    ClipArea = function(self, Widget)
        local ViewW, ViewH = self:PaneViewSize(Widget)
        return Widget.AX, Widget.AY, Widget.AX + ViewW, Widget.AY + ViewH
    end,

    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, self:Ct(Widget, Theme.PanelBg), Clip)
        self:FrameRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, BORDER,
                       self:Ct(Widget, Theme.PanelBorder), Clip)
    end,

    DrawAfter = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme
        local ContentW, ContentH = self:PaneContentExtent(Widget)
        local ViewW, ViewH = self:PaneViewSize(Widget)

        if Widget.VBar then
            local ScrollX = Widget.AX + Widget.AW - SCROLL_W

            self:FillRect(ScrollX, Widget.AY, SCROLL_W, ViewH, self:Ct(Widget, Theme.ScrollTrack), Clip)

            if ContentH > ViewH and ContentH > 0 then
                local ThumbH = Max(16, ViewH * ViewH / ContentH)

                self:FillRect(ScrollX + 1, Widget.AY + (ViewH - ThumbH) * self:Clamp(Widget.ScrollY or 0, 0, 1),
                              SCROLL_W - 2, ThumbH, self:Ct(Widget, Theme.ScrollThumb), Clip)
            end
        end

        if Widget.HBar then
            local ScrollY = Widget.AY + Widget.AH - SCROLL_W

            self:FillRect(Widget.AX, ScrollY, ViewW, SCROLL_W, self:Ct(Widget, Theme.ScrollTrack), Clip)

            if ContentW > ViewW and ContentW > 0 then
                local ThumbW = Max(16, ViewW * ViewW / ContentW)

                self:FillRect(Widget.AX + (ViewW - ThumbW) * self:Clamp(Widget.ScrollX or 0, 0, 1),
                              ScrollY + 1, ThumbW, SCROLL_W - 2, self:Ct(Widget, Theme.ScrollThumb), Clip)
            end
        end
    end,

    OnWheel = function(self, Widget, Delta)
        local _, ContentH = self:PaneContentExtent(Widget)
        local _, ViewH = self:PaneViewSize(Widget)
        local Span = Max(1, ContentH - ViewH)
        local Before = Widget.ScrollY or 0

        Widget.ScrollY = self:Clamp(Before + Delta * (self:LineH(Widget) * 3 / Span), 0, 1)

        if Widget.ScrollY ~= Before then
            self:MarkDirty()
            return true
        end

        return false
    end,
})

function _MTAX:PaneScrollSet(Element, Amount, Field)
    local Widget = self:ResolveTyped(Element, "gui-scrollpane")

    if not Widget then
        return false
    end

    local Value = self:Num(Amount, nil)

    if Value == nil then
        return false
    end

    Widget[Field] = self:Clamp(Value / 100, 0, 1)
    self:MarkDirty()
    return true
end

function _MTAX:PaneScrollGet(Element, Field)
    local Widget = self:ResolveTyped(Element, "gui-scrollpane")

    if not Widget then
        return false
    end

    return (Widget[Field] or 0) * 100
end

--- Grid list

function _MTAX:GlHeaderH(Widget)
    return Floor(self:FontHeight(Widget.Font) + 6)
end

function _MTAX:GlRowH(Widget)
    return self:RowH(Widget)
end

function _MTAX:GlViewRect(Widget)
    local HeaderH = self:GlHeaderH(Widget)
    local X1 = Widget.AX + BORDER
    local Y1 = Widget.AY + BORDER + HeaderH
    local X2 = Widget.AX + Widget.AW - BORDER - (Widget.VBar and SCROLL_W or 0)
    local Y2 = Widget.AY + Widget.AH - BORDER - (Widget.HBar and SCROLL_W or 0)

    return X1, Y1, X2, Y2
end

function _MTAX:GlVisibleRows(Widget)
    local _, Y1, _, Y2 = self:GlViewRect(Widget)
    local RowHeight = self:GlRowH(Widget)

    if RowHeight <= 0 then
        return 1
    end

    return Max(1, Floor((Y2 - Y1) / RowHeight))
end

function _MTAX:GlMaxScroll(Widget)
    return Max(0, #Widget.Rows - self:GlVisibleRows(Widget))
end

function _MTAX:GlClampScroll(Widget)
    Widget.ScrollRow = self:Clamp(Floor(Widget.ScrollRow or 0), 0, self:GlMaxScroll(Widget))
end

function _MTAX:GlColumnPixels(Widget)
    local Out = Widget.ColumnPixels

    if Out == nil then
        Out = {}
        Widget.ColumnPixels = Out
    end

    local X1 = self:GlViewRect(Widget)
    local CX = X1 - (Widget.ScrollPixelX or 0)
    local Count = #Widget.Columns

    for Index = 1, Count do
        local Width = Widget.Columns[Index].Width * Widget.AW
        local Slot = Out[Index]

        if Slot == nil then
            Slot = {}
            Out[Index] = Slot
        end

        Slot.X, Slot.W = CX, Width
        CX = CX + Width
    end

    for Index = #Out, Count + 1, -1 do
        Out[Index] = nil
    end

    return Out
end

function _MTAX:GlCell(Widget, Row, Column, Create)
    local Entry = Widget.Rows[Row]

    if Entry == nil then
        return nil
    end

    if Column == nil or Column < 1 or Column > #Widget.Columns then
        return nil
    end

    local Cell = Entry.Cells[Column]

    if Cell == nil and Create then
        Cell = { Text = "", Data = nil, Colour = nil }
        Entry.Cells[Column] = Cell
    end

    return Cell
end

function _MTAX:GlClearSelection(Widget)
    for Index = #Widget.Selection, 1, -1 do
        Widget.Selection[Index] = nil
    end
end

function _MTAX:GlSelectedIndex(Widget, Row)
    for Index = 1, #Widget.Selection do
        if Widget.Selection[Index].Row == Row then
            return Index
        end
    end

    return nil
end

function _MTAX:GlSelect(Widget, Row, Column, Additive)
    if not Additive or Widget.SelectionMode == 0 then
        self:GlClearSelection(Widget)
        Widget.Selection[1] = { Row = Row, Col = Column }
        return
    end

    local At = self:GlSelectedIndex(Widget, Row)

    if At ~= nil then
        Remove(Widget.Selection, At)
        return
    end

    Widget.Selection[#Widget.Selection + 1] = { Row = Row, Col = Column }
end

function _MTAX:GlSortBy(Widget, ColumnIndex)
    if not Widget.SortingEnabled then
        return
    end

    if Widget.SortColumn == ColumnIndex then
        Widget.SortAscending = not Widget.SortAscending
    else
        Widget.SortColumn = ColumnIndex
        Widget.SortAscending = true
    end

    local Ascending = Widget.SortAscending
    local Decorated = {}

    for Index = 1, #Widget.Rows do
        Decorated[Index] = { Row = Widget.Rows[Index], Index = Index }
    end

    Sort(Decorated, function(A, B)
        local CellA = A.Row.Cells[ColumnIndex]
        local CellB = B.Row.Cells[ColumnIndex]
        local TextA = CellA and CellA.Text or ""
        local TextB = CellB and CellB.Text or ""
        local NumberA = (CellA and CellA.Number) and tonumber(TextA) or nil
        local NumberB = (CellB and CellB.Number) and tonumber(TextB) or nil
        local LessThan

        if NumberA ~= nil and NumberB ~= nil then
            if NumberA == NumberB then
                return A.Index < B.Index
            end

            LessThan = NumberA < NumberB
        else
            if TextA == TextB then
                return A.Index < B.Index
            end

            LessThan = TextA < TextB
        end

        if Ascending then
            return LessThan
        end

        return not LessThan
    end)

    local NewRows = {}

    for Index = 1, #Decorated do
        NewRows[Index] = Decorated[Index].Row
    end

    Widget.Rows = NewRows
    self:GlClearSelection(Widget)
end

_MTAX:Class("gui-gridlist", {
    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, self:Ct(Widget, Theme.PanelBg), Clip)

        local HeaderH = self:GlHeaderH(Widget)
        local X1, Y1, X2, Y2 = self:GlViewRect(Widget)
        local Columns = self:GlColumnPixels(Widget)
        local HeaderClip = self:InnerClip(Widget, BORDER, BORDER,
                                          BORDER + (Widget.VBar and SCROLL_W or 0),
                                          Widget.AH - BORDER - HeaderH)

        self:FillRect(Widget.AX + BORDER, Widget.AY + BORDER, Widget.AW - BORDER * 2, HeaderH,
                      self:Ct(Widget, Theme.HeaderBg), Clip)

        for Index = 1, #Columns do
            local Column = Columns[Index]

            self:DrawText(Widget.Columns[Index].Title, Column.X + PAD, Widget.AY + BORDER,
                          Column.X + Column.W - PAD, Widget.AY + BORDER + HeaderH,
                          self:Ct(Widget, Theme.Text), Widget.Font, "left", "center", false, HeaderClip)

            if Index > 1 then
                self:FillRect(Column.X, Widget.AY + BORDER, 1, HeaderH,
                              self:Ct(Widget, Theme.PanelBorder), HeaderClip)
            end
        end

        self:GlClampScroll(Widget)

        local RowHeight = self:GlRowH(Widget)
        local VisibleCount = self:GlVisibleRows(Widget)
        local BodyClip = Widget.BodyTable

        if BodyClip == nil then
            BodyClip = {}
            Widget.BodyTable = BodyClip
        end

        BodyClip[1], BodyClip[2], BodyClip[3], BodyClip[4] =
            self:Intersect(X1, Y1, X2, Y2, Widget.CX1, Widget.CY1, Widget.CX2, Widget.CY2)

        for Index = 1, VisibleCount do
            local RowIndex = Widget.ScrollRow + Index
            local Row = Widget.Rows[RowIndex]

            if Row == nil then
                break
            end

            local RowY = Y1 + (Index - 1) * RowHeight
            local Selected = false

            for SelectionIndex = 1, #Widget.Selection do
                if Widget.Selection[SelectionIndex].Row == RowIndex then
                    Selected = true
                    break
                end
            end

            if Selected then
                self:FillRect(X1, RowY, X2 - X1, RowHeight, self:Ct(Widget, Theme.RowSelected), BodyClip)
            elseif RowIndex % 2 == 0 then
                self:FillRect(X1, RowY, X2 - X1, RowHeight, self:Ct(Widget, Theme.RowAlt), BodyClip)
            end

            for ColumnIndex = 1, #Columns do
                local Cell = Row.Cells[ColumnIndex]

                if Cell then
                    local Colour = Cell.Colour and self:Ct(Widget, Cell.Colour) or self:TextColour(Widget)

                    self:DrawText(Cell.Text, Columns[ColumnIndex].X + PAD, RowY,
                                  Columns[ColumnIndex].X + Columns[ColumnIndex].W - PAD, RowY + RowHeight,
                                  Colour, Widget.Font, "left", "center", false, BodyClip)
                end
            end
        end

        if Widget.VBar then
            local ScrollX = Widget.AX + Widget.AW - BORDER - SCROLL_W

            self:FillRect(ScrollX, Y1, SCROLL_W, Y2 - Y1, self:Ct(Widget, Theme.ScrollTrack), Clip)

            local Total = #Widget.Rows

            if Total > VisibleCount and Total > 0 then
                local ThumbH = Max(16, (Y2 - Y1) * VisibleCount / Total)
                local MaxScroll = self:GlMaxScroll(Widget)
                local Offset = MaxScroll > 0 and ((Y2 - Y1 - ThumbH) * Widget.ScrollRow / MaxScroll) or 0

                self:FillRect(ScrollX + 1, Y1 + Offset, SCROLL_W - 2, ThumbH,
                              self:Ct(Widget, Theme.ScrollThumb), Clip)
            end
        end

        if Widget.HBar then
            local ScrollY = Widget.AY + Widget.AH - BORDER - SCROLL_W
            self:FillRect(X1, ScrollY, X2 - X1, SCROLL_W, self:Ct(Widget, Theme.ScrollTrack), Clip)
        end

        self:FrameRect(Widget.AX, Widget.AY, Widget.AW, Widget.AH, BORDER,
                       self:Ct(Widget, Theme.PanelBorder), Clip)
    end,

    OnMouseDown = function(self, Widget, Button, X, Y)
        if Button ~= "left" then
            return
        end

        local HeaderH = self:GlHeaderH(Widget)
        local _, Y1, _, Y2 = self:GlViewRect(Widget)

        if Y < Widget.AY + BORDER + HeaderH then
            if not Widget.SortingEnabled then
                return
            end

            local Columns = self:GlColumnPixels(Widget)

            for Index = 1, #Columns do
                if X >= Columns[Index].X and X < Columns[Index].X + Columns[Index].W then
                    self:GlSortBy(Widget, Index)
                    return
                end
            end

            return
        end

        if Widget.VBar and X >= Widget.AX + Widget.AW - BORDER - SCROLL_W then
            local VisibleCount = self:GlVisibleRows(Widget)
            local Middle = (Y1 + Y2) / 2

            Widget.ScrollRow = (Widget.ScrollRow or 0) + (Y < Middle and -VisibleCount or VisibleCount)
            self:GlClampScroll(Widget)
            self:Fire("onClientGUIScroll", Widget)
            return
        end

        if Y < Y1 or Y >= Y2 then
            return
        end

        local RowHeight = self:GlRowH(Widget)
        local RowIndex = (Widget.ScrollRow or 0) + Floor((Y - Y1) / RowHeight) + 1

        if Widget.Rows[RowIndex] == nil then
            self:GlClearSelection(Widget)
            return
        end

        local Columns = self:GlColumnPixels(Widget)
        local ColumnIndex = 1

        for Index = 1, #Columns do
            if X >= Columns[Index].X and X < Columns[Index].X + Columns[Index].W then
                ColumnIndex = Index
                break
            end
        end

        self:GlSelect(Widget, RowIndex, ColumnIndex, Widget.SelectionMode == 1 and self:CtrlHeld())
    end,

    OnWheel = function(self, Widget, Delta)
        local Before = Widget.ScrollRow or 0

        Widget.ScrollRow = Before + Delta * 3
        self:GlClampScroll(Widget)

        return Widget.ScrollRow ~= Before
    end,

    Dispose = function(self, Widget)
        Widget.Rows, Widget.Columns, Widget.Selection = {}, {}, {}
    end,
})

--- Combo box

function _MTAX:CbStripH(Widget)
    return Floor(self:FontHeight(Widget.Font) + 8)
end

function _MTAX:CbListRect(Widget)
    local Top = Widget.AY + self:CbStripH(Widget)
    local RowHeight = self:RowH(Widget)
    local RowsHeight = #Widget.Items * RowHeight
    local Available = Max(RowHeight, Widget.AH - self:CbStripH(Widget))
    local Height = Min(RowsHeight, Available)
    local _, ScreenH = self:Screen()

    if Top + Height > ScreenH then
        Height = Max(RowHeight, ScreenH - Top)
    end

    if Top >= ScreenH then
        Height = 0
    end

    return Widget.AX, Top, Widget.AW, Height
end

function _MTAX:CbClose(Widget)
    if self.Popup == Widget then
        self.Popup = nil
    end

    Widget.Open = false
end

function _MTAX:CbSetDisplay(Widget, Text)
    Widget.Display = Text
    Widget.Text = Text
end

function _MTAX:CbSyncDisplay(Widget)
    local Item = (Widget.Selected >= 0) and Widget.Items[Widget.Selected + 1] or nil
    self:CbSetDisplay(Widget, Item or Widget.Caption)
end

_MTAX:Class("gui-combobox", {
    HitBox = function(self, Widget)
        return Widget.AX, Widget.AY, Widget.AX + Widget.AW, Widget.AY + self:CbStripH(Widget)
    end,

    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme
        local StripH = self:CbStripH(Widget)

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, StripH, self:Ct(Widget, Theme.FieldBg), Clip)
        self:FrameRect(Widget.AX, Widget.AY, Widget.AW, StripH, BORDER,
                       self:Ct(Widget, (self.Focused == Widget) and Theme.FieldBorderFocus or Theme.FieldBorder),
                       Clip)

        local Label = Widget.Display or Widget.Caption

        self:DrawText(Label, Widget.AX + PAD, Widget.AY, Widget.AX + Widget.AW - StripH,
                      Widget.AY + StripH, self:TextColour(Widget), Widget.Font,
                      "left", "center", false, Clip)

        local ArrowX = Widget.AX + Widget.AW - StripH / 2
        local ArrowY = Widget.AY + StripH / 2

        for Index = 0, 3 do
            self:FillRect(ArrowX - 4 + Index, ArrowY - 2 + Index, (4 - Index) * 2, 1,
                          self:TextColour(Widget), Clip)
        end
    end,

    DrawPopup = function(self, Widget)
        local ListX, ListY, ListW, ListH = self:CbListRect(Widget)
        local ScreenW, ScreenH = self:Screen()
        local Theme = self.Theme
        local Clip = Widget.PopupTable

        if Clip == nil then
            Clip = {}
            Widget.PopupTable = Clip
        end

        Clip[1], Clip[2], Clip[3], Clip[4] = 0, 0, ScreenW, ScreenH

        self:FillRect(ListX, ListY, ListW, ListH, self:Ct(Widget, Theme.PanelBg), Clip)
        self:FrameRect(ListX, ListY, ListW, ListH, BORDER, self:Ct(Widget, Theme.PanelBorder), Clip)

        local RowHeight = self:RowH(Widget)
        local VisibleCount = Max(1, Floor(ListH / RowHeight))
        local ListClip = Widget.ListTable

        if ListClip == nil then
            ListClip = {}
            Widget.ListTable = ListClip
        end

        ListClip[1], ListClip[2], ListClip[3], ListClip[4] =
            self:Intersect(ListX, ListY, ListX + ListW, ListY + ListH, 0, 0, ScreenW, ScreenH)

        for Index = 1, VisibleCount do
            local ItemIndex = (Widget.ListScroll or 0) + Index
            local Item = Widget.Items[ItemIndex]

            if Item == nil then
                break
            end

            local RowY = ListY + (Index - 1) * RowHeight

            if ItemIndex - 1 == Widget.Selected then
                self:FillRect(ListX + 1, RowY, ListW - 2, RowHeight,
                              self:Ct(Widget, Theme.RowSelected), ListClip)
            elseif self.CursorY >= RowY and self.CursorY < RowY + RowHeight
                   and self.CursorX >= ListX and self.CursorX < ListX + ListW then
                self:FillRect(ListX + 1, RowY, ListW - 2, RowHeight,
                              self:Ct(Widget, Theme.RowHover), ListClip)
            end

            self:DrawText(Item, ListX + PAD, RowY, ListX + ListW - PAD, RowY + RowHeight,
                          self:TextColour(Widget), Widget.Font, "left", "center", false, ListClip)
        end
    end,

    HitPopup = function(self, Widget, X, Y)
        if not Widget.Open then
            return nil
        end

        local ListX, ListY, ListW, ListH = self:CbListRect(Widget)

        if self:PointIn(X, Y, ListX, ListY, ListX + ListW, ListY + ListH) then
            return Widget
        end

        return nil
    end,

    ClosePopup = function(self, Widget)
        self:CbClose(Widget)
    end,

    SetText = function(self, Widget, Text)
        self:CbSetDisplay(Widget, Text)
    end,

    GetText = function(self, Widget)
        return Widget.Display or Widget.Caption
    end,

    OnWheel = function(self, Widget, Delta)
        if not Widget.Open then
            return false
        end

        local Before = Widget.ListScroll or 0
        local _, _, _, ListH = self:CbListRect(Widget)
        local VisibleCount = Max(1, Floor(ListH / self:RowH(Widget)))

        Widget.ListScroll = self:Clamp(Before + Delta, 0, Max(0, #Widget.Items - VisibleCount))
        return Widget.ListScroll ~= Before
    end,

    OnMouseDown = function(self, Widget, Button, X, Y)
        if Button ~= "left" then
            return
        end

        if Widget.Open then
            local ListX, ListY, ListW, ListH = self:CbListRect(Widget)

            if self:PointIn(X, Y, ListX, ListY, ListX + ListW, ListY + ListH) then
                local ItemIndex = (Widget.ListScroll or 0) + Floor((Y - ListY) / self:RowH(Widget)) + 1

                if Widget.Items[ItemIndex] then
                    Widget.Selected = ItemIndex - 1
                    self:CbSyncDisplay(Widget)
                    self:CbClose(Widget)
                    self:Fire("onClientGUIComboBoxAccepted", Widget)
                end

                return
            end

            self:CbClose(Widget)
            return
        end

        local Previous = self.Popup

        if Previous and Previous ~= Widget and not Previous.Destroyed then
            local Class = self.Classes[Previous.Type]

            if Class and Class.ClosePopup then
                Class.ClosePopup(self, Previous)
            end
        end

        Widget.Open = true
        Widget.ListScroll = 0
        self.Popup = Widget
    end,

    Dispose = function(self, Widget)
        if self.Popup == Widget then
            self.Popup = nil
        end
    end,
})

--- Tab panel and tab

function _MTAX:TpStripH(Widget)
    return Floor(self:FontHeight(Widget.Font) + 10)
end

function _MTAX:TpTabRects(Widget)
    local Out = {}
    local X = Widget.AX
    local Height = self:TpStripH(Widget)

    for Index = 1, #Widget.Children do
        local Tab = Widget.Children[Index]

        if Tab.Type == "gui-tab" then
            local Width = self:TextWidth(Tab.Text, Widget.Font) + PAD * 4

            Out[#Out + 1] = { X = X, W = Width, H = Height, Tab = Tab }
            X = X + Width
        end
    end

    return Out
end

_MTAX:Class("gui-tabpanel", {
    ChildArea = function(self, Widget)
        local StripH = self:TpStripH(Widget)
        return Widget.AX, Widget.AY + StripH, Widget.AW, Max(0, Widget.AH - StripH)
    end,

    ClipArea = function(self, Widget)
        local StripH = self:TpStripH(Widget)
        return Widget.AX, Widget.AY + StripH, Widget.AX + Widget.AW, Widget.AY + Widget.AH
    end,

    ChildVisible = function(self, Widget, Child)
        if Child.Type ~= "gui-tab" then
            return true
        end

        return Widget.Selected == Child
    end,

    Reflow = function(self, Widget)
        local StripH = self:TpStripH(Widget)
        local ContentW, ContentH = Widget.AW, Max(0, Widget.AH - StripH)
        local FirstTab = nil

        for Index = 1, #Widget.Children do
            local Tab = Widget.Children[Index]

            if Tab.Type == "gui-tab" then
                Tab.X, Tab.Y, Tab.W, Tab.H = 0, 0, ContentW, ContentH

                if FirstTab == nil then
                    FirstTab = Tab
                end
            end
        end

        if Widget.Selected == nil or Widget.Selected.Destroyed or Widget.Selected.Parent ~= Widget then
            Widget.Selected = FirstTab
        end
    end,

    Draw = function(self, Widget)
        local Clip = self:Clip(Widget)
        local Theme = self.Theme
        local StripH = self:TpStripH(Widget)

        self:FillRect(Widget.AX, Widget.AY, Widget.AW, StripH, self:Ct(Widget, Theme.TabStrip), Clip)
        self:FillRect(Widget.AX, Widget.AY + StripH, Widget.AW, Widget.AH - StripH,
                      self:Ct(Widget, Theme.PanelBg), Clip)

        local Rects = self:TpTabRects(Widget)

        for Index = 1, #Rects do
            local Rect = Rects[Index]
            local Active = (Rect.Tab == Widget.Selected)

            self:FillRect(Rect.X, Widget.AY, Rect.W, StripH,
                          self:Ct(Widget, Active and Theme.TabActive or Theme.TabInactive), Clip)
            self:FrameRect(Rect.X, Widget.AY, Rect.W, StripH, BORDER,
                           self:Ct(Widget, Theme.PanelBorder), Clip)
            self:DrawText(Rect.Tab.Text, Rect.X + PAD, Widget.AY, Rect.X + Rect.W - PAD,
                          Widget.AY + StripH, self:TextColour(Widget), Widget.Font,
                          "center", "center", false, Clip)
        end

        self:FrameRect(Widget.AX, Widget.AY + StripH, Widget.AW, Widget.AH - StripH, BORDER,
                       self:Ct(Widget, Theme.PanelBorder), Clip)
    end,

    OnMouseDown = function(self, Widget, Button, X, Y)
        if Button ~= "left" then
            return
        end

        if Y >= Widget.AY + self:TpStripH(Widget) then
            return
        end

        local Rects = self:TpTabRects(Widget)

        for Index = 1, #Rects do
            local Rect = Rects[Index]

            if X >= Rect.X and X < Rect.X + Rect.W then
                if Widget.Selected ~= Rect.Tab then
                    Widget.Selected = Rect.Tab
                    self:MarkDirty()
                    self:Fire("onClientGUITabSwitched", Widget)
                end

                return
            end
        end
    end,
})

_MTAX:Class("gui-tab", {
    Draw = function(self, Widget) end,
})

--- Generic exports

---@param Element userdata
---@param State boolean
---@return boolean
function guiSetVisible(Element, State)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    Widget.Visible = _MTAX:Truthy(State)

    if not Widget.Visible then
        _MTAX:StopInteracting(Widget)
    end

    _MTAX:MarkDirty()
    return true
end

---@param Element userdata
---@return boolean
function guiGetVisible(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    return Widget.Visible
end

---@param Element userdata
---@param Enabled boolean
---@return boolean
function guiSetEnabled(Element, Enabled)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    Widget.Enabled = _MTAX:Truthy(Enabled)

    if not Widget.Enabled then
        _MTAX:StopInteracting(Widget)
    end

    _MTAX:MarkDirty()
    return true
end

---@param Element userdata
---@return boolean
function guiGetEnabled(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    return Widget.Enabled
end

---@param Element userdata
---@param Alpha number
---@return boolean
function guiSetAlpha(Element, Alpha)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Alpha, nil)

    if Value == nil then
        return false
    end

    Widget.Alpha = _MTAX:Clamp(Value, 0, 1)
    _MTAX:MarkDirty()
    return true
end

---@param Element userdata
---@param EffectiveAlpha? boolean
---@return number|false
function guiGetAlpha(Element, EffectiveAlpha)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    if _MTAX:Truthy(EffectiveAlpha) then
        _MTAX:Layout()
        return Widget.EffectiveAlpha
    end

    return Widget.Alpha
end

---@param Element userdata
---@param X number
---@param Y number
---@param Relative? boolean
---@return boolean
function guiSetPosition(Element, X, Y, Relative)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    local NX, NY = _MTAX:Num(X, nil), _MTAX:Num(Y, nil)

    if NX == nil or NY == nil then
        return false
    end

    if _MTAX:Truthy(Relative) then
        local _, _, ParentW, ParentH = _MTAX:ParentBox(Widget)
        NX, NY = NX * ParentW, NY * ParentH
    end

    if Widget.X == NX and Widget.Y == NY then
        return true
    end

    Widget.X, Widget.Y = NX, NY
    _MTAX:MarkDirty()
    _MTAX:NoteMoved(Widget)
    return true
end

---@param Element userdata
---@param Relative? boolean
---@return number|false X
---@return number? Y
function guiGetPosition(Element, Relative)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    if _MTAX:Truthy(Relative) then
        local _, _, ParentW, ParentH = _MTAX:ParentBox(Widget)

        if ParentW == 0 or ParentH == 0 then
            return 0, 0
        end

        return Widget.X / ParentW, Widget.Y / ParentH
    end

    return Widget.X, Widget.Y
end

---@param Element userdata
---@param Width number
---@param Height number
---@param Relative? boolean
---@return boolean
function guiSetSize(Element, Width, Height, Relative)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    local NW, NH = _MTAX:Num(Width, nil), _MTAX:Num(Height, nil)

    if NW == nil or NH == nil then
        return false
    end

    if _MTAX:Truthy(Relative) then
        local _, _, ParentW, ParentH = _MTAX:ParentBox(Widget)
        NW, NH = NW * ParentW, NH * ParentH
    end

    if NW < 0 then NW = 0 end
    if NH < 0 then NH = 0 end

    if Widget.W == NW and Widget.H == NH then
        return true
    end

    Widget.W, Widget.H = NW, NH
    Widget.WrapDirty, Widget.CaretDirty = true, true
    _MTAX:MarkDirty()
    _MTAX:NoteSized(Widget)
    return true
end

---@param Element userdata
---@param Relative? boolean
---@return number|false Width
---@return number? Height
function guiGetSize(Element, Relative)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    if _MTAX:Truthy(Relative) then
        local _, _, ParentW, ParentH = _MTAX:ParentBox(Widget)

        if ParentW == 0 or ParentH == 0 then
            return 0, 0
        end

        return Widget.W / ParentW, Widget.H / ParentH
    end

    return Widget.W, Widget.H
end

---@param Element userdata
---@param Text string
---@return boolean
function guiSetText(Element, Text)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    local Value = _MTAX:Str(Text, nil)

    if Value == nil then
        return false
    end

    local Class = _MTAX.Classes[Widget.Type]
    local Old = Widget.Text

    if Class and Class.SetText then
        Class.SetText(_MTAX, Widget, Value)
    else
        Widget.Text = Value
    end

    Widget.WrapDirty, Widget.CaretDirty = true, true
    _MTAX:NoteTextChanged(Widget, Old)
    return true
end

---@param Element userdata
---@return string|false
function guiGetText(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    local Class = _MTAX.Classes[Widget.Type]

    if Class and Class.GetText then
        return Class.GetText(_MTAX, Widget)
    end

    return Widget.Text
end

---@param Element userdata
---@param Font string|userdata
---@return boolean
function guiSetFont(Element, Font)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    if type(Font) == "string" then
        if not _MTAX.GuiFonts[Font] and not _MTAX.DxFonts[Font] then
            _MTAX:Unsupported("guiSetFont(\"" .. Font .. "\")",
                "unknown font name; MTA would have failed here too")
            return false
        end

        Widget.Font = Font
    elseif NIsElement(Font) then
        if NGetElementType(Font) ~= "dx-font" then
            _MTAX:Unsupported("guiSetFont(<element>)",
                "the element is not a dx-font. MTA wants a gui-font element and the shim wants " ..
                "the dxCreateFont element guiCreateFont returns; anything else is refused.")
            return false
        end

        Widget.Font = Font
    else
        return false
    end

    Widget.WrapDirty, Widget.CaretDirty = true, true
    _MTAX:MarkDirty()
    return true
end

---@param Element userdata
---@return string|false Name
---@return userdata|false? Font
function guiGetFont(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    if type(Widget.Font) == "string" then
        return Widget.Font, false
    end

    return "", Widget.Font
end

---@param Element userdata
---@return boolean
function guiBringToFront(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    return _MTAX:BringToFront(Widget)
end

---@param Element userdata
---@return boolean
function guiMoveToBack(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    return _MTAX:MoveToBack(Widget)
end

---@param Element userdata
---@return boolean
function guiFocus(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    if not Widget.Enabled or not Widget.Visible then
        return false
    end

    return _MTAX:Focus(Widget)
end

---@param Element userdata
---@return boolean
function guiBlur(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    if _MTAX.Focused ~= Widget then
        return false
    end

    return _MTAX:Blur()
end

---@param Element userdata
---@param Property string
---@param Value string
---@return boolean
function guiSetProperty(Element, Property, Value)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    local Name = _MTAX:Str(Property, nil)

    if Name == nil then
        return false
    end

    local Entry = _MTAX.Props[Name]

    if Entry == nil then
        _MTAX:Unsupported("guiSetProperty(\"" .. Name .. "\")",
            "not in the shim's CEGUI property allowlist; returning false")
        return false
    end

    if Entry.Set == nil then
        _MTAX:Unsupported("guiSetProperty(\"" .. Name .. "\")",
            "read-only in the shim; CEGUI would not accept a write here either")
        return false
    end

    local Ok, Result = pcall(Entry.Set, _MTAX, Widget, Value)

    if not Ok then
        return false
    end

    return Result ~= false
end

---@param Element userdata
---@param Property string
---@return string|false
function guiGetProperty(Element, Property)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    local Name = _MTAX:Str(Property, nil)

    if Name == nil then
        return false
    end

    local Entry = _MTAX.Props[Name]

    if Entry == nil then
        _MTAX:Unsupported("guiGetProperty(\"" .. Name .. "\")",
            "not in the shim's CEGUI property allowlist; returning false")
        return false
    end

    local Ok, Result = pcall(Entry.Get, _MTAX, Widget)

    if not Ok or Result == nil then
        return false
    end

    return tostring(Result)
end

---@param Element userdata
---@return table<string, string>|false
function guiGetProperties(Element)
    local Widget = _MTAX:Resolve(Element)

    if not Widget then
        return false
    end

    _MTAX:Unsupported("guiGetProperties",
        "returns only the shim's allowlist, not CEGUI's full property set")

    local Out = {}
    local Names = {}

    for Name in pairs(_MTAX.Props) do
        Names[#Names + 1] = Name
    end

    Sort(Names)

    for Index = 1, #Names do
        local Ok, Value = pcall(_MTAX.Props[Names[Index]].Get, _MTAX, Widget)

        if Ok and Value ~= nil then
            Out[Names[Index]] = tostring(Value)
        end
    end

    return Out
end

--- Window exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param TitleBarText string
---@param Relative? boolean
---@return userdata|false
function guiCreateWindow(X, Y, Width, Height, TitleBarText, Relative)
    local Widget = _MTAX:NewWidget("gui-window", X, Y, Width, Height, Relative, nil, {
        Text = _MTAX:Str(TitleBarText, ""),
        Movable = true,
        Sizable = true,
        TitleBar = true,
        CloseButton = true,
        Font = "default-bold-small",
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param Status boolean
---@return boolean
function guiWindowSetMovable(Element, Status)
    local Widget = _MTAX:ResolveTyped(Element, "gui-window")

    if not Widget then
        return false
    end

    Widget.Movable = _MTAX:Truthy(Status)
    return true
end

---@param Element userdata
---@param Status boolean
---@return boolean
function guiWindowSetSizable(Element, Status)
    local Widget = _MTAX:ResolveTyped(Element, "gui-window")

    if not Widget then
        return false
    end

    Widget.Sizable = _MTAX:Truthy(Status)
    return true
end

---@param Element userdata
---@return boolean
function guiWindowIsMovable(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-window")

    if not Widget then
        return false
    end

    return Widget.Movable == true
end

---@param Element userdata
---@return boolean
function guiWindowIsSizable(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-window")

    if not Widget then
        return false
    end

    return Widget.Sizable == true
end

--- Label exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Text string
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateLabel(X, Y, Width, Height, Text, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-label", X, Y, Width, Height, Relative, Parent, {
        Text = _MTAX:Str(Text, ""),
        AlignX = "left",
        AlignY = "top",
        Wrap = false,
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param R number
---@param G number
---@param B number
---@return boolean
function guiLabelSetColor(Element, R, G, B)
    local Widget = _MTAX:ResolveTyped(Element, "gui-label")

    if not Widget then
        return false
    end

    local Red, Green, Blue = _MTAX:Num(R, nil), _MTAX:Num(G, nil), _MTAX:Num(B, nil)

    if Red == nil or Green == nil or Blue == nil then
        return false
    end

    Widget.TextColor = _MTAX:Argb(255, Red, Green, Blue)
    return true
end

---@param Element userdata
---@return number|false R
---@return number? G
---@return number? B
function guiLabelGetColor(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-label")

    if not Widget then
        return false
    end

    local Colour = Widget.TextColor

    if Colour == nil then
        _MTAX:Unsupported("guiLabelGetColor on a label with no explicit colour",
            "answers the shim's theme colour; MTA answers the player's CEGUI skin colour, " ..
            "which MTAX cannot read")

        Colour = _MTAX.Theme.Text
    end

    return Floor(Colour / 0x10000) % 256, Floor(Colour / 0x100) % 256, Colour % 256
end

---@param Element userdata
---@param Align string
---@return boolean
function guiLabelSetVerticalAlign(Element, Align)
    local Widget = _MTAX:ResolveTyped(Element, "gui-label")

    if not Widget then
        return false
    end

    local Value = _MTAX:Str(Align, "")

    if not VALID_VALIGN[Value] then
        return false
    end

    Widget.AlignY = Value
    return true
end

---@param Element userdata
---@param Align string
---@param WordWrap? boolean
---@return boolean
function guiLabelSetHorizontalAlign(Element, Align, WordWrap)
    local Widget = _MTAX:ResolveTyped(Element, "gui-label")

    if not Widget then
        return false
    end

    local Value = _MTAX:Str(Align, "")

    if not VALID_HALIGN[Value] then
        return false
    end

    Widget.AlignX = Value
    Widget.Wrap = _MTAX:Truthy(WordWrap)
    Widget.WrapDirty = true
    return true
end

---@param Element userdata
---@return number|false
function guiLabelGetTextExtent(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-label")

    if not Widget then
        return false
    end

    return _MTAX:TextWidth(Widget.Text, Widget.Font)
end

---@param Element userdata
---@return number|false
function guiLabelGetFontHeight(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-label")

    if not Widget then
        return false
    end

    return _MTAX:FontHeight(Widget.Font)
end

--- Button exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Text string
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateButton(X, Y, Width, Height, Text, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-button", X, Y, Width, Height, Relative, Parent, {
        Text = _MTAX:Str(Text, ""),
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

--- Static image exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Path string
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateStaticImage(X, Y, Width, Height, Path, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-staticimage", X, Y, Width, Height, Relative, Parent, {})

    if not Widget then
        return false
    end

    if not _MTAX:LoadTexture(Widget, Path) then
        _MTAX:DestroyWidget(Widget)
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param FileName string
---@return boolean
function guiStaticImageLoadImage(Element, FileName)
    local Widget = _MTAX:ResolveTyped(Element, "gui-staticimage")

    if not Widget then
        return false
    end

    return _MTAX:LoadTexture(Widget, FileName) and true or false
end

---@param Element userdata
---@return number|false Width
---@return number? Height
function guiStaticImageGetNativeSize(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-staticimage")

    if not Widget or Widget.Texture == nil then
        return false
    end

    local Ok, Width, Height = pcall(NDxGetMaterialSize, Widget.Texture)

    if not Ok or type(Width) ~= "number" then
        return false
    end

    return Width, Height
end

--- Edit exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Text string
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateEdit(X, Y, Width, Height, Text, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-edit", X, Y, Width, Height, Relative, Parent, {
        Text = "",
        Caret = 0,
        Masked = false,
        MaskChar = "*",
        MaskCodepoint = 42,
        MaxLength = 0,
        ReadOnly = false,
        ScrollChar = 1,
        CaretDirty = true,
    })

    if not Widget then
        return false
    end

    local Value = _MTAX:Str(Text, "")

    Widget.Text = Value:gsub("[\r\n]", " ")
    Widget.Caret = _MTAX:ULen(Widget.Text)
    return Widget.Element
end

---@param Element userdata
---@param Index number
---@return boolean
function guiEditSetCaretIndex(Element, Index)
    local Widget = _MTAX:ResolveTyped(Element, "gui-edit")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Index, nil)

    if Value == nil then
        return false
    end

    Widget.Caret = _MTAX:Clamp(Floor(Value), 0, _MTAX:ULen(Widget.Text))
    Widget.CaretDirty = true
    return true
end

---@param Element userdata
---@param Index number
---@return boolean
function guiEditSetCaratIndex(Element, Index)
    return guiEditSetCaretIndex(Element, Index)
end

---@param Element userdata
---@return number|false
function guiEditGetCaretIndex(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-edit")

    if not Widget then
        return false
    end

    return Widget.Caret
end

---@param Element userdata
---@param Status boolean
---@return boolean
function guiEditSetMasked(Element, Status)
    local Widget = _MTAX:ResolveTyped(Element, "gui-edit")

    if not Widget then
        return false
    end

    Widget.Masked = _MTAX:Truthy(Status)
    Widget.CaretDirty = true
    return true
end

---@param Element userdata
---@return boolean
function guiEditIsMasked(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-edit")

    if not Widget then
        return false
    end

    return Widget.Masked == true
end

---@param Element userdata
---@param Length number
---@return boolean
function guiEditSetMaxLength(Element, Length)
    local Widget = _MTAX:ResolveTyped(Element, "gui-edit")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Length, nil)

    if Value == nil then
        return false
    end

    Widget.MaxLength = Max(0, Floor(Value))

    if Widget.MaxLength > 0 and _MTAX:ULen(Widget.Text) > Widget.MaxLength then
        local Old = Widget.Text

        Widget.Text = _MTAX:USub(Widget.Text, 1, Widget.MaxLength)
        Widget.Caret = Min(Widget.Caret, Widget.MaxLength)
        Widget.CaretDirty = true

        _MTAX:NoteTextChanged(Widget, Old)
    end

    return true
end

---@param Element userdata
---@return number|false
function guiEditGetMaxLength(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-edit")

    if not Widget then
        return false
    end

    return Widget.MaxLength or 0
end

---@param Element userdata
---@param Status boolean
---@return boolean
function guiEditSetReadOnly(Element, Status)
    local Widget = _MTAX:ResolveTyped(Element, "gui-edit")

    if not Widget then
        return false
    end

    Widget.ReadOnly = _MTAX:Truthy(Status)
    return true
end

---@param Element userdata
---@return boolean
function guiEditIsReadOnly(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-edit")

    if not Widget then
        return false
    end

    return Widget.ReadOnly == true
end

--- Memo exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Text string
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateMemo(X, Y, Width, Height, Text, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-memo", X, Y, Width, Height, Relative, Parent, {
        Text = _MTAX:Str(Text, ""),
        Caret = 0,
        ReadOnly = false,
        ScrollLine = 0,
        MaxLength = 0,
        WrapDirty = true,
    })

    if not Widget then
        return false
    end

    Widget.Caret = _MTAX:ULen(Widget.Text)
    return Widget.Element
end

---@param Element userdata
---@param Index number
---@return boolean
function guiMemoSetCaretIndex(Element, Index)
    local Widget = _MTAX:ResolveTyped(Element, "gui-memo")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Index, nil)

    if Value == nil then
        return false
    end

    Widget.Caret = _MTAX:Clamp(Floor(Value), 0, _MTAX:ULen(Widget.Text))
    return true
end

---@param Element userdata
---@param Index number
---@return boolean
function guiMemoSetCaratIndex(Element, Index)
    return guiMemoSetCaretIndex(Element, Index)
end

---@param Element userdata
---@return number|false
function guiMemoGetCaretIndex(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-memo")

    if not Widget then
        return false
    end

    return Widget.Caret
end

---@param Element userdata
---@param Status boolean
---@return boolean
function guiMemoSetReadOnly(Element, Status)
    local Widget = _MTAX:ResolveTyped(Element, "gui-memo")

    if not Widget then
        return false
    end

    Widget.ReadOnly = _MTAX:Truthy(Status)
    return true
end

---@param Element userdata
---@return boolean
function guiMemoIsReadOnly(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-memo")

    if not Widget then
        return false
    end

    return Widget.ReadOnly == true
end

---@param Element userdata
---@param Position number
---@return boolean
function guiMemoSetVerticalScrollPosition(Element, Position)
    local Widget = _MTAX:ResolveTyped(Element, "gui-memo")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Position, nil)

    if Value == nil then
        return false
    end

    Widget.ScrollLine = Floor(_MTAX:Clamp(Value / 100, 0, 1) * _MTAX:MemoMaxScroll(Widget) + 0.5)
    _MTAX:MemoClampScroll(Widget)
    return true
end

---@param Element userdata
---@return number|false
function guiMemoGetVerticalScrollPosition(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-memo")

    if not Widget then
        return false
    end

    local MaxScroll = _MTAX:MemoMaxScroll(Widget)

    if MaxScroll <= 0 then
        return 0
    end

    return (Widget.ScrollLine or 0) / MaxScroll * 100
end

--- Checkbox exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Text string
---@param Selected boolean
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateCheckBox(X, Y, Width, Height, Text, Selected, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-checkbox", X, Y, Width, Height, Relative, Parent, {
        Text = _MTAX:Str(Text, ""),
        Selected = _MTAX:Truthy(Selected),
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param State boolean
---@return boolean
function guiCheckBoxSetSelected(Element, State)
    local Widget = _MTAX:ResolveTyped(Element, "gui-checkbox")

    if not Widget then
        return false
    end

    Widget.Selected = _MTAX:Truthy(State)
    return true
end

---@param Element userdata
---@return boolean
function guiCheckBoxGetSelected(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-checkbox")

    if not Widget then
        return false
    end

    return Widget.Selected == true
end

--- Radio button exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Text string
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateRadioButton(X, Y, Width, Height, Text, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-radiobutton", X, Y, Width, Height, Relative, Parent, {
        Text = _MTAX:Str(Text, ""),
        Selected = false,
        GroupId = 0,
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param State boolean
---@return boolean
function guiRadioButtonSetSelected(Element, State)
    local Widget = _MTAX:ResolveTyped(Element, "gui-radiobutton")

    if not Widget then
        return false
    end

    _MTAX:RadioSelect(Widget, _MTAX:Truthy(State))
    return true
end

---@param Element userdata
---@return boolean
function guiRadioButtonGetSelected(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-radiobutton")

    if not Widget then
        return false
    end

    return Widget.Selected == true
end

--- Progress bar exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateProgressBar(X, Y, Width, Height, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-progressbar", X, Y, Width, Height, Relative, Parent, {
        Progress = 0,
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param Progress number
---@return boolean
function guiProgressBarSetProgress(Element, Progress)
    local Widget = _MTAX:ResolveTyped(Element, "gui-progressbar")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Progress, nil)

    if Value == nil then
        return false
    end

    Widget.Progress = _MTAX:Clamp(Value, 0, 100)
    return true
end

---@param Element userdata
---@return number|false
function guiProgressBarGetProgress(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-progressbar")

    if not Widget then
        return false
    end

    return Widget.Progress or 0
end

--- Scrollbar exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Horizontal boolean
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateScrollBar(X, Y, Width, Height, Horizontal, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-scrollbar", X, Y, Width, Height, Relative, Parent, {
        Horizontal = _MTAX:Truthy(Horizontal),
        Position = 0,
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param Amount number
---@return boolean
function guiScrollBarSetScrollPosition(Element, Amount)
    local Widget = _MTAX:ResolveTyped(Element, "gui-scrollbar")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Amount, nil)

    if Value == nil then
        return false
    end

    Widget.Position = _MTAX:Clamp(Value, 0, 100)
    return true
end

---@param Element userdata
---@return number|false
function guiScrollBarGetScrollPosition(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-scrollbar")

    if not Widget then
        return false
    end

    return Widget.Position or 0
end

--- Scroll pane exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateScrollPane(X, Y, Width, Height, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-scrollpane", X, Y, Width, Height, Relative, Parent, {
        ScrollX = 0,
        ScrollY = 0,
        HBar = true,
        VBar = true,
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param Horizontal boolean
---@param Vertical boolean
---@return boolean
function guiScrollPaneSetScrollBars(Element, Horizontal, Vertical)
    local Widget = _MTAX:ResolveTyped(Element, "gui-scrollpane")

    if not Widget then
        return false
    end

    Widget.HBar = _MTAX:Truthy(Horizontal)
    Widget.VBar = _MTAX:Truthy(Vertical)
    _MTAX:MarkDirty()
    return true
end

---@param Element userdata
---@param Amount number
---@return boolean
function guiScrollPaneSetHorizontalScrollPosition(Element, Amount)
    return _MTAX:PaneScrollSet(Element, Amount, "ScrollX")
end

---@param Element userdata
---@return number|false
function guiScrollPaneGetHorizontalScrollPosition(Element)
    return _MTAX:PaneScrollGet(Element, "ScrollX")
end

---@param Element userdata
---@param Amount number
---@return boolean
function guiScrollPaneSetVerticalScrollPosition(Element, Amount)
    return _MTAX:PaneScrollSet(Element, Amount, "ScrollY")
end

---@param Element userdata
---@return number|false
function guiScrollPaneGetVerticalScrollPosition(Element)
    return _MTAX:PaneScrollGet(Element, "ScrollY")
end

--- Grid list exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateGridList(X, Y, Width, Height, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-gridlist", X, Y, Width, Height, Relative, Parent, {
        Columns = {},
        Rows = {},
        Selection = {},
        SelectionMode = 0,
        SortingEnabled = true,
        SortColumn = nil,
        SortAscending = true,
        ScrollRow = 0,
        ScrollPixelX = 0,
        HBar = false,
        VBar = true,
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Element userdata
---@param Enabled boolean
---@return boolean
function guiGridListSetSortingEnabled(Element, Enabled)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    Widget.SortingEnabled = _MTAX:Truthy(Enabled)
    return true
end

---@param Element userdata
---@return boolean
function guiGridListIsSortingEnabled(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    return Widget.SortingEnabled == true
end

---@param Element userdata
---@param Title string
---@param Width number
---@return number|false ColumnIndex
function guiGridListAddColumn(Element, Title, Width)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Width, nil)

    if Value == nil then
        return false
    end

    Widget.Columns[#Widget.Columns + 1] = { Title = _MTAX:Str(Title, ""), Width = Max(0, Value) }
    return #Widget.Columns
end

---@param Element userdata
---@param ColumnIndex number
---@return boolean
function guiGridListRemoveColumn(Element, ColumnIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ColumnIndex, nil)

    if Index == nil then
        return false
    end

    Index = Floor(Index)

    if Widget.Columns[Index] == nil then
        return false
    end

    local Count = #Widget.Columns

    Remove(Widget.Columns, Index)

    for RowIndex = 1, #Widget.Rows do
        local Cells = Widget.Rows[RowIndex].Cells

        for Column = Index, Count - 1 do
            Cells[Column] = Cells[Column + 1]
        end

        Cells[Count] = nil
    end

    _MTAX:GlClearSelection(Widget)
    return true
end

---@param Element userdata
---@param ColumnIndex number
---@param Width number
---@param Relative? boolean
---@return boolean
function guiGridListSetColumnWidth(Element, ColumnIndex, Width, Relative)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Index, Value = _MTAX:Num(ColumnIndex, nil), _MTAX:Num(Width, nil)

    if Index == nil or Value == nil then
        return false
    end

    local Column = Widget.Columns[Floor(Index)]

    if Column == nil then
        return false
    end

    if _MTAX:Truthy(Relative) then
        Column.Width = Max(0, Value)
    else
        Column.Width = (Widget.W > 0) and Max(0, Value / Widget.W) or 0
    end

    return true
end

---@param Element userdata
---@param ColumnIndex number
---@param Relative? boolean
---@return number|false
function guiGridListGetColumnWidth(Element, ColumnIndex, Relative)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ColumnIndex, nil)

    if Index == nil then
        return false
    end

    local Column = Widget.Columns[Floor(Index)]

    if Column == nil then
        return false
    end

    if _MTAX:Truthy(Relative) then
        return Column.Width
    end

    return Column.Width * Widget.W
end

---@param Element userdata
---@param ColumnIndex number
---@param Title string
---@return boolean
function guiGridListSetColumnTitle(Element, ColumnIndex, Title)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ColumnIndex, nil)

    if Index == nil then
        return false
    end

    local Column = Widget.Columns[Floor(Index)]

    if Column == nil then
        return false
    end

    Column.Title = _MTAX:Str(Title, "")
    return true
end

---@param Element userdata
---@param ColumnIndex number
---@return string|false
function guiGridListGetColumnTitle(Element, ColumnIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ColumnIndex, nil)

    if Index == nil then
        return false
    end

    local Column = Widget.Columns[Floor(Index)]

    if Column == nil then
        return false
    end

    return Column.Title
end

---@param Element userdata
---@param HorizontalBar boolean
---@param VerticalBar boolean
---@return boolean
function guiGridListSetScrollBars(Element, HorizontalBar, VerticalBar)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    Widget.HBar = _MTAX:Truthy(HorizontalBar)
    Widget.VBar = _MTAX:Truthy(VerticalBar)
    return true
end

---@param Element userdata
---@return number|false
function guiGridListGetRowCount(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    return #Widget.Rows
end

---@param Element userdata
---@return number|false
function guiGridListGetColumnCount(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    return #Widget.Columns
end

---@param Element userdata
---@return number|false RowIndex
function guiGridListAddRow(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    Widget.Rows[#Widget.Rows + 1] = { Cells = {} }
    return #Widget.Rows - 1
end

---@param Element userdata
---@param RowIndex number
---@return number|false
function guiGridListInsertRowAfter(Element, RowIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(RowIndex, nil)

    if Index == nil then
        return false
    end

    local At = Floor(Index) + 2

    if At < 1 then At = 1 end
    if At > #Widget.Rows + 1 then At = #Widget.Rows + 1 end

    Insert(Widget.Rows, At, { Cells = {} })
    return At - 1
end

---@param Element userdata
---@param RowIndex number
---@return boolean
function guiGridListRemoveRow(Element, RowIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(RowIndex, nil)

    if Index == nil then
        return false
    end

    local At = Floor(Index) + 1

    if Widget.Rows[At] == nil then
        return false
    end

    Remove(Widget.Rows, At)

    for SelectionIndex = #Widget.Selection, 1, -1 do
        local Selection = Widget.Selection[SelectionIndex]

        if Selection.Row == At then
            Remove(Widget.Selection, SelectionIndex)
        elseif Selection.Row > At then
            Selection.Row = Selection.Row - 1
        end
    end

    _MTAX:GlClampScroll(Widget)
    return true
end

---@param Element userdata
---@param ColumnIndex number
---@return boolean
function guiGridListAutoSizeColumn(Element, ColumnIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ColumnIndex, nil)

    if Index == nil then
        return false
    end

    Index = Floor(Index)

    local Column = Widget.Columns[Index]

    if Column == nil then
        return false
    end

    local Widest = _MTAX:TextWidth(Column.Title, Widget.Font)

    for RowIndex = 1, #Widget.Rows do
        local Cell = Widget.Rows[RowIndex].Cells[Index]

        if Cell then
            local CellWidth = _MTAX:TextWidth(Cell.Text, Widget.Font)

            if CellWidth > Widest then
                Widest = CellWidth
            end
        end
    end

    Column.Width = (Widget.W > 0) and ((Widest + PAD * 3) / Widget.W) or 0
    return true
end

---@param Element userdata
---@return boolean
function guiGridListClear(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    for Index = #Widget.Rows, 1, -1 do
        Widget.Rows[Index] = nil
    end

    _MTAX:GlClearSelection(Widget)
    Widget.ScrollRow = 0
    return true
end

---@param Element userdata
---@param RowIndex number
---@param ColumnIndex number
---@param Text string
---@param Section? boolean
---@param Number? boolean
---@return boolean
function guiGridListSetItemText(Element, RowIndex, ColumnIndex, Text, Section, Number)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Row, Column = _MTAX:Num(RowIndex, nil), _MTAX:Num(ColumnIndex, nil)

    if Row == nil or Column == nil then
        return false
    end

    local Cell = _MTAX:GlCell(Widget, Floor(Row) + 1, Floor(Column), true)

    if Cell == nil then
        return false
    end

    Cell.Text = _MTAX:Str(Text, "")
    Cell.Section = _MTAX:Truthy(Section)
    Cell.Number = _MTAX:Truthy(Number)
    return true
end

---@param Element userdata
---@param RowIndex number
---@param ColumnIndex number
---@return string|false
function guiGridListGetItemText(Element, RowIndex, ColumnIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Row, Column = _MTAX:Num(RowIndex, nil), _MTAX:Num(ColumnIndex, nil)

    if Row == nil or Column == nil then
        return false
    end

    local Cell = _MTAX:GlCell(Widget, Floor(Row) + 1, Floor(Column), false)

    if Cell == nil then
        return ""
    end

    return Cell.Text
end

---@param Element userdata
---@param RowIndex number
---@param ColumnIndex number
---@param Data any
---@return boolean
function guiGridListSetItemData(Element, RowIndex, ColumnIndex, Data)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Row, Column = _MTAX:Num(RowIndex, nil), _MTAX:Num(ColumnIndex, nil)

    if Row == nil or Column == nil then
        return false
    end

    local Cell = _MTAX:GlCell(Widget, Floor(Row) + 1, Floor(Column), true)

    if Cell == nil then
        return false
    end

    Cell.Data = Data
    return true
end

---@param Element userdata
---@param RowIndex number
---@param ColumnIndex number
---@return any
function guiGridListGetItemData(Element, RowIndex, ColumnIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Row, Column = _MTAX:Num(RowIndex, nil), _MTAX:Num(ColumnIndex, nil)

    if Row == nil or Column == nil then
        return false
    end

    local Cell = _MTAX:GlCell(Widget, Floor(Row) + 1, Floor(Column), false)

    if Cell == nil or Cell.Data == nil then
        return false
    end

    return Cell.Data
end

---@param Element userdata
---@param RowIndex number
---@param ColumnIndex number
---@param R number
---@param G number
---@param B number
---@param A? number
---@return boolean
function guiGridListSetItemColor(Element, RowIndex, ColumnIndex, R, G, B, A)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Row, Column = _MTAX:Num(RowIndex, nil), _MTAX:Num(ColumnIndex, nil)

    if Row == nil or Column == nil then
        return false
    end

    local Red, Green, Blue = _MTAX:Num(R, nil), _MTAX:Num(G, nil), _MTAX:Num(B, nil)

    if Red == nil or Green == nil or Blue == nil then
        return false
    end

    local Cell = _MTAX:GlCell(Widget, Floor(Row) + 1, Floor(Column), true)

    if Cell == nil then
        return false
    end

    Cell.Colour = _MTAX:Argb(_MTAX:Num(A, 255), Red, Green, Blue)
    return true
end

---@param Element userdata
---@param RowIndex number
---@param ColumnIndex number
---@return number|false R
---@return number? G
---@return number? B
---@return number? A
function guiGridListGetItemColor(Element, RowIndex, ColumnIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Row, Column = _MTAX:Num(RowIndex, nil), _MTAX:Num(ColumnIndex, nil)

    if Row == nil or Column == nil then
        return false
    end

    local Cell = _MTAX:GlCell(Widget, Floor(Row) + 1, Floor(Column), false)
    local Colour = (Cell and Cell.Colour) or _MTAX.Theme.Text

    return Floor(Colour / 0x10000) % 256, Floor(Colour / 0x100) % 256, Colour % 256,
           Floor(Colour / 0x1000000) % 256
end

---@param Element userdata
---@param Mode number
---@return boolean
function guiGridListSetSelectionMode(Element, Mode)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Mode, nil)

    if Value == nil then
        return false
    end

    Value = Floor(Value)

    if Value ~= 0 and Value ~= 1 then
        _MTAX:Unsupported("guiGridListSetSelectionMode(" .. Value .. ")",
            "only mode 0 (single row) and mode 1 (multi row) are emulated; column, cell and " ..
            "nominated modes fall back to mode 0")

        Widget.SelectionMode = 0
    else
        Widget.SelectionMode = Value
    end

    _MTAX:GlClearSelection(Widget)
    return true
end

---@param Element userdata
---@return number|false
function guiGridListGetSelectionMode(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    return Widget.SelectionMode or 0
end

---@param Element userdata
---@return number|false RowIndex
---@return number? ColumnIndex
function guiGridListGetSelectedItem(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Selection = Widget.Selection[1]

    if Selection == nil then
        return -1, -1
    end

    return Selection.Row - 1, Selection.Col
end

---@param Element userdata
---@return { row: number, column: number }[]|false
function guiGridListGetSelectedItems(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Out = {}

    for Index = 1, #Widget.Selection do
        Out[Index] = { row = Widget.Selection[Index].Row - 1, column = Widget.Selection[Index].Col - 1 }
    end

    return Out
end

---@param Element userdata
---@return number|false
function guiGridListGetSelectedCount(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    return #Widget.Selection
end

---@param Element userdata
---@param RowIndex number
---@param ColumnIndex number
---@return boolean
function guiGridListSetSelectedItem(Element, RowIndex, ColumnIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Row, Column = _MTAX:Num(RowIndex, nil), _MTAX:Num(ColumnIndex, nil)

    if Row == nil or Column == nil then
        return false
    end

    Row, Column = Floor(Row) + 1, Floor(Column)

    if Row < 1 then
        _MTAX:GlClearSelection(Widget)
        return true
    end

    if Widget.Rows[Row] == nil then
        return false
    end

    _MTAX:GlSelect(Widget, Row, Max(1, Column), false)

    local VisibleCount = _MTAX:GlVisibleRows(Widget)

    if Row - 1 < (Widget.ScrollRow or 0) then
        Widget.ScrollRow = Row - 1
    end

    if Row > (Widget.ScrollRow or 0) + VisibleCount then
        Widget.ScrollRow = Row - VisibleCount
    end

    _MTAX:GlClampScroll(Widget)
    return true
end

---@param Element userdata
---@param Position number
---@return boolean
function guiGridListSetHorizontalScrollPosition(Element, Position)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Position, nil)

    if Value == nil then
        return false
    end

    local Total = 0

    for Index = 1, #Widget.Columns do
        Total = Total + Widget.Columns[Index].Width * Widget.W
    end

    local X1, _, X2 = _MTAX:GlViewRect(Widget)

    Widget.ScrollPixelX = Max(0, Total - (X2 - X1)) * _MTAX:Clamp(Value / 100, 0, 1)
    return true
end

---@param Element userdata
---@return number|false
function guiGridListGetHorizontalScrollPosition(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Total = 0

    for Index = 1, #Widget.Columns do
        Total = Total + Widget.Columns[Index].Width * Widget.W
    end

    local X1, _, X2 = _MTAX:GlViewRect(Widget)
    local Span = Max(0, Total - (X2 - X1))

    if Span <= 0 then
        return 0
    end

    return _MTAX:Clamp((Widget.ScrollPixelX or 0) / Span, 0, 1) * 100
end

---@param Element userdata
---@param Position number
---@return boolean
function guiGridListSetVerticalScrollPosition(Element, Position)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local Value = _MTAX:Num(Position, nil)

    if Value == nil then
        return false
    end

    Widget.ScrollRow = Floor(_MTAX:Clamp(Value / 100, 0, 1) * _MTAX:GlMaxScroll(Widget) + 0.5)
    _MTAX:GlClampScroll(Widget)
    return true
end

---@param Element userdata
---@return number|false
function guiGridListGetVerticalScrollPosition(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-gridlist")

    if not Widget then
        return false
    end

    local MaxScroll = _MTAX:GlMaxScroll(Widget)

    if MaxScroll <= 0 then
        return 0
    end

    return (Widget.ScrollRow or 0) / MaxScroll * 100
end

--- Combo box exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Caption string
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateComboBox(X, Y, Width, Height, Caption, Relative, Parent)
    local Value = _MTAX:Str(Caption, "")
    local Widget = _MTAX:NewWidget("gui-combobox", X, Y, Width, Height, Relative, Parent, {
        Items = {},
        Selected = -1,
        Caption = Value,
        Display = Value,
        Open = false,
        ListScroll = 0,
    })

    if not Widget then
        return false
    end

    _MTAX:CbSetDisplay(Widget, Widget.Caption)
    return Widget.Element
end

---@param Element userdata
---@param Value string
---@return number|false ItemId
function guiComboBoxAddItem(Element, Value)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    Widget.Items[#Widget.Items + 1] = _MTAX:Str(Value, "")
    return #Widget.Items - 1
end

---@param Element userdata
---@param ItemId number
---@return boolean
function guiComboBoxRemoveItem(Element, ItemId)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ItemId, nil)

    if Index == nil then
        return false
    end

    Index = Floor(Index) + 1

    if Widget.Items[Index] == nil then
        return false
    end

    Remove(Widget.Items, Index)

    if Widget.Selected == Index - 1 then
        Widget.Selected = -1
    elseif Widget.Selected > Index - 1 then
        Widget.Selected = Widget.Selected - 1
    end

    _MTAX:CbSyncDisplay(Widget)
    return true
end

---@param Element userdata
---@return boolean
function guiComboBoxClear(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    for Index = #Widget.Items, 1, -1 do
        Widget.Items[Index] = nil
    end

    Widget.Selected = -1
    Widget.ListScroll = 0

    _MTAX:CbSyncDisplay(Widget)
    return true
end

---@param Element userdata
---@return number|false
function guiComboBoxGetSelected(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    return Widget.Selected
end

---@param Element userdata
---@param ItemIndex number
---@return boolean
function guiComboBoxSetSelected(Element, ItemIndex)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ItemIndex, nil)

    if Index == nil then
        return false
    end

    Index = Floor(Index)

    if Index == -1 then
        Widget.Selected = -1
        _MTAX:CbSyncDisplay(Widget)
        return true
    end

    if Widget.Items[Index + 1] == nil then
        return false
    end

    Widget.Selected = Index
    _MTAX:CbSyncDisplay(Widget)
    return true
end

---@param Element userdata
---@param ItemId number
---@return string|false
function guiComboBoxGetItemText(Element, ItemId)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ItemId, nil)

    if Index == nil then
        return false
    end

    Index = Floor(Index)

    if Index == -1 then
        return Widget.Display or Widget.Caption
    end

    local Text = Widget.Items[Index + 1]

    if Text == nil then
        return false
    end

    return Text
end

---@param Element userdata
---@param ItemId number
---@param Text string
---@return boolean
function guiComboBoxSetItemText(Element, ItemId, Text)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    local Index = _MTAX:Num(ItemId, nil)

    if Index == nil then
        return false
    end

    Index = Floor(Index)

    if Widget.Items[Index + 1] == nil then
        return false
    end

    Widget.Items[Index + 1] = _MTAX:Str(Text, "")

    if Widget.Selected == Index then
        _MTAX:CbSyncDisplay(Widget)
    end

    return true
end

---@param Element userdata
---@return number|false
function guiComboBoxGetItemCount(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    return #Widget.Items
end

---@param Element userdata
---@param State boolean
---@return boolean
function guiComboBoxSetOpen(Element, State)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    if _MTAX:Truthy(State) then
        local Previous = _MTAX.Popup

        if Previous and Previous ~= Widget and not Previous.Destroyed then
            local Class = _MTAX.Classes[Previous.Type]

            if Class and Class.ClosePopup then
                Class.ClosePopup(_MTAX, Previous)
            end
        end

        Widget.Open = true
        Widget.ListScroll = 0
        _MTAX.Popup = Widget
    else
        _MTAX:CbClose(Widget)
    end

    return true
end

---@param Element userdata
---@return boolean
function guiComboBoxIsOpen(Element)
    local Widget = _MTAX:ResolveTyped(Element, "gui-combobox")

    if not Widget then
        return false
    end

    return Widget.Open == true
end

--- Tab panel exports

---@param X number
---@param Y number
---@param Width number
---@param Height number
---@param Relative? boolean
---@param Parent? userdata
---@return userdata|false
function guiCreateTabPanel(X, Y, Width, Height, Relative, Parent)
    local Widget = _MTAX:NewWidget("gui-tabpanel", X, Y, Width, Height, Relative, Parent, {
        Selected = nil,
        Font = "default-bold-small",
    })

    if not Widget then
        return false
    end

    return Widget.Element
end

---@param Text string
---@param Parent userdata
---@return userdata|false
function guiCreateTab(Text, Parent)
    local Panel = _MTAX:ResolveTyped(Parent, "gui-tabpanel")

    if not Panel then
        return false
    end

    local Widget = _MTAX:NewWidget("gui-tab", 0, 0, 0, 0, false, Panel.Element, {
        Text = _MTAX:Str(Text, ""),
    })

    if not Widget then
        return false
    end

    if Panel.Selected == nil then
        Panel.Selected = Widget
    end

    _MTAX:MarkDirty()
    return Widget.Element
end

---@param TabPanel userdata
---@return userdata|false
function guiGetSelectedTab(TabPanel)
    local Panel = _MTAX:ResolveTyped(TabPanel, "gui-tabpanel")

    if not Panel then
        return false
    end

    if Panel.Selected == nil or Panel.Selected.Destroyed then
        return false
    end

    return Panel.Selected.Element
end

---@param TabPanel userdata
---@param Tab userdata
---@return boolean
function guiSetSelectedTab(TabPanel, Tab)
    local Panel = _MTAX:ResolveTyped(TabPanel, "gui-tabpanel")

    if not Panel then
        return false
    end

    local Target = _MTAX:ResolveTyped(Tab, "gui-tab")

    if not Target or Target.Parent ~= Panel then
        return false
    end

    if Panel.Selected == Target then
        return true
    end

    Panel.Selected = Target
    _MTAX:MarkDirty()
    _MTAX:Fire("onClientGUITabSwitched", Panel)
    return true
end

---@param TabToDelete userdata
---@param TabPanel userdata
---@return boolean
function guiDeleteTab(TabToDelete, TabPanel)
    local Target = _MTAX:ResolveTyped(TabToDelete, "gui-tab")

    if not Target then
        return false
    end

    local Panel = _MTAX:ResolveTyped(TabPanel, "gui-tabpanel")

    if not Panel or Target.Parent ~= Panel then
        return false
    end

    local WasSelected = (Panel.Selected == Target)

    _MTAX:DestroyWidget(Target)

    if WasSelected then
        Panel.Selected = nil

        for Index = 1, #Panel.Children do
            if Panel.Children[Index].Type == "gui-tab" then
                Panel.Selected = Panel.Children[Index]
                break
            end
        end

        _MTAX:MarkDirty()
        _MTAX:Fire("onClientGUITabSwitched", Panel)
    end

    return true
end

--- Browser exports

---@return false
function guiCreateBrowser()
    _MTAX:Unsupported("guiCreateBrowser",
        "not reproducible. Rewrite to NUI (ui_page + registerNuiCallback) or DUI " ..
        "(createDui + dxDrawImage). Returns false, as MTA does on failure.")

    return false
end

---@return false
function guiGetBrowser()
    _MTAX:Unsupported("guiGetBrowser", "guiCreateBrowser is not emulated, so there is never a browser")
    return false
end

for Index = 1, #_MTAX.Reserved do
    _MTAX:Define(_MTAX.Reserved[Index])
end

_MTAX.WidgetsReady = true

_MTAX:Info("widgets loaded: " .. #_MTAX.DefinedNames .. " gui* functions defined.")
