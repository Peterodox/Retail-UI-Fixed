local _, addon = ...
local L = addon.L
local GetDBBool = addon.GetDBBool
local SetDBValue = addon.SetDBValue

local Schematic = {
    title = L["Retail UI Options"],
    subtitle = L["Retail UI Options Desc"],

    sectors = {
        {
            header = nil,
            sideBySide = true,
            widgets = {
                {type = "Checkbox", name = L["Tidy Icons"], tooltip = L["Tidy Icons Tooltip"], dbKey = "TidyIcons"},
                {type = "Checkbox", name = L["Dark Theme"], tooltip = L["Dark Theme Tooltip"], dbKey = "DarkTheme"},
                {type = "Checkbox", name = L["Show XP Text"], tooltip = L["Show XP Text Tooltip"], cvar = "xpBarText"},
            },
        },

        {
            header = L["Enhancements"],
            sideBySide = true,
            widgets = {
                {type = "Checkbox", name = L["Tooltip Show Self Aura Spell ID"], dbKey = "Tooltip_SelfAuraSpellID"},
                {type = "Checkbox", name = L["Tooltip Show Target Aura Spell ID"], dbKey = "Tooltip_TargetAuraSpellID"},
                {type = "Checkbox", name = L["PaperDoll Item Level"], dbKey = "PaperDoll_QualityBorder"},
                {type = "Checkbox", name = L["PaperDoll Quality Color"], dbKey = "PaperDoll_ItemLevel"},
            },
        },

        {
            header = L["Keybind Text"],
            sideBySide = true,
            widgets = {
                {type = "Checkbox", name = L["Primary Bar"], dbKey = "KeybindText_PrimaryBar"},
                {type = "Checkbox", name = L["Bottom Left Bar"], dbKey = "KeybindText_BottomLeftBar"},
                {type = "Checkbox", name = L["Bottom Right Bar"], dbKey = "KeybindText_BottomRightBar"},
                {type = "Checkbox", name = L["Right Bar"], dbKey = "KeybindText_RightBar"},
                {type = "Checkbox", name = L["Right Bar 2"], dbKey = "KeybindText_RightBar2"},
            },
        },

        {
            header = L["Components"],
            sideBySide = true,
            widgets = {
                {type = "Checkbox", name = L["Gryphons"], dbKey = "Components_Gryphons"},
                {type = "Checkbox", name = L["Bags"], dbKey = "Components_Bags"},
                    {type = "Checkbox", name = L["Bag Space Text"], dbKey = "Components_BagSpaceText"},
                {type = "Checkbox", name = L["Micro Menu"], dbKey = "Components_MicroMenu"},
                {type = "Checkbox", name = L["Micro Bags Background"], dbKey = "Components_MicroAndBagsBackground"},
            },
        },
    },
}

local SettingsFrame = CreateFrame("Frame", nil, UIParent)
SettingsFrame:Hide()

local floor = math.floor
local function Round(n)
    return floor(n + 0.5)
end

local function CreateBackground(f)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.5)
    bg:SetAllPoints(true)
    return bg
end

local function Checkbox_OnClick(self)
    if self.dbKey or self.cvar then
        local enabled = self:GetChecked()
        if self.dbKey then
            SetDBValue(self.dbKey, enabled, true)
        else
            C_CVar.SetCVar(self.cvar, (enabled and 1) or 0)
        end
    end
end

local function Shared_OnEnter(self)
    if self.widgetInfo and self.widgetInfo.tooltip then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.widgetInfo.name, 1, 1, 1)
        GameTooltip:AddLine(self.widgetInfo.tooltip, 1, 0.82, 0, true)
        GameTooltip:Show()
    end
end

local function Shared_OnLeave(self)
    GameTooltip:Hide()
end

function SettingsFrame:Init()
    local TEXT_SPACING = 4
    local WIDGET_SPACING = 8
    local SECTOR_SPACING = 26
    local HEADER_FIRST_WIDGET_GAP = 12
    local FRAME_BORDER_PADDING = 20
    local BORDER_MAINFRAME_PADDING = 16

    self.Init = nil
    self.OptionDB = RUI_SavedVars.Options

    self:SetSize(128, 128)
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local rowSpan
    local maxSpan = 0
    local offsetY = 0
    local scheme = Schematic

    local function AddHeight(v, obj)
        return Round(v + obj:GetHeight())
    end

    local obj

    if scheme.title then
        obj = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        obj:SetText(scheme.title)
        obj:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY)
        offsetY = AddHeight(offsetY, obj)
    end

    if scheme.subtitle then
        obj = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        obj:SetText(scheme.subtitle)
        offsetY = offsetY + TEXT_SPACING
        obj:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY)
        offsetY = AddHeight(offsetY, obj)
    end

    self.Sectors = {}
    self.Widgets = {}

    for i, sector in ipairs(scheme.sectors) do
        local f = CreateFrame("Frame", nil, self)
        f:SetSize(128, 128)
        f:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
        self.Sectors[i] = f

        local maxWidth = 0
        local widgetWidth = 0
        local y = 0
        local offsetX = 0

        if sector.header then
            obj = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            obj:SetText(sector.header)
            obj:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y)
            y = AddHeight(y, obj)
            y = y + HEADER_FIRST_WIDGET_GAP
        end

        for j, w in ipairs(sector.widgets) do
            offsetX = 0
            local widget

            if w.type == "Checkbox" then
                if j ~= 1 then
                    y = y + WIDGET_SPACING
                end
                widget = CreateFrame("CheckButton", nil, f, "InterfaceOptionsCheckButtonTemplate")
                widget.Text:SetText(w.name)
                widget:SetPoint("TOPLEFT", f, "TOPLEFT", offsetX, -y)
                widget:SetScript("OnClick", Checkbox_OnClick)
                y = AddHeight(y, widget)
                widgetWidth = (widget.Button and widget.Button:GetWidth() or 28) + widget.Text:GetWrappedWidth() + offsetX
                if widgetWidth > maxWidth then
                    maxWidth = widgetWidth
                end
            end

            if widget then
                widget.dbKey = w.dbKey
                widget.cvar = w.cvar
                widget.type = w.type
                widget.widgetInfo = w
                widget:SetScript("OnEnter", Shared_OnEnter)
                widget:SetScript("OnLeave", Shared_OnLeave)
                table.insert(self.Widgets, widget)
            end
        end

        local sectorWidth = Round(maxWidth)
        local sectorHeight = Round(y)
        f:SetSize(sectorWidth, sectorHeight)
        f.width = sectorWidth
        f.height = sectorHeight

        f:ClearAllPoints()
        if sector.sideBySide then
            f.sideBySide = true

            if rowSpan and rowSpan ~= 0 then
                rowSpan = rowSpan + SECTOR_SPACING
            else
                rowSpan = 0
            end

            if self.Sectors[i - 1] and self.Sectors[i - 1].sideBySide then
                f:SetPoint("TOPLEFT", self.Sectors[i - 1], "TOPRIGHT", SECTOR_SPACING, 0)
            else
                offsetY = offsetY + SECTOR_SPACING
                f:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY)
            end

            rowSpan = rowSpan + sectorWidth
            if rowSpan > maxSpan then
                maxSpan = rowSpan
            end
        else
            --Calculate the max height of previous side-by-side sectors
            local n = i - 1
            local maxRowHeight = 0
            while (self.Sectors[n] and self.Sectors[n].sideBySide) do
                if self.Sectors[n].height > maxRowHeight then
                    maxRowHeight = self.Sectors[n].height
                end
                n = n - 1
            end

            rowSpan = 0
            offsetY = offsetY + maxRowHeight + SECTOR_SPACING
            f:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY)
            offsetY = offsetY + sectorHeight

            if sectorWidth > maxSpan then
                maxSpan = sectorWidth
            end
        end
    end

    local n = #scheme.sectors - 1
    local maxRowHeight = 0
    while (self.Sectors[n] and self.Sectors[n].sideBySide) do
        if self.Sectors[n].height > maxRowHeight then
            maxRowHeight = self.Sectors[n].height
        end
        n = n - 1
    end
    offsetY = offsetY + maxRowHeight

    local frameWidth = maxSpan
    local frameHeight = offsetY
    self:SetSize(frameWidth, frameHeight)

    --debug
    --[[
    CreateBackground(self)
    for _, f in ipairs(self.Sectors) do
        CreateBackground(f)
    end
    --]]


    --Border
    local BorderFrame = CreateFrame("Frame", nil, self)
    BorderFrame:SetUsingParentLevel(true)

    if BackdropTemplateMixin and BackdropTemplateMixin.SetBackdrop then
        Mixin(BorderFrame, BackdropTemplateMixin)
        BorderFrame:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {left = 5, right = 5, top = 5, bottom = 5},
        })
        BorderFrame:SetBackdropBorderColor(.6, .6, .6, 1)
        BorderFrame:SetPoint("TOPLEFT", self, "TOPLEFT", -FRAME_BORDER_PADDING, FRAME_BORDER_PADDING)
        BorderFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", FRAME_BORDER_PADDING, -FRAME_BORDER_PADDING)
    end

    local parent = RUIOptionsFrame--RUIOptionsFramePanelContainer
    if parent then
        self:SetParent(parent)
        self:ClearAllPoints()
        local extraTopPadding = 16
        local extraBottomPadding = 24
        local padding = BORDER_MAINFRAME_PADDING + FRAME_BORDER_PADDING
        self:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding - extraTopPadding)
        local mainFrameWidth = frameWidth + 2 * padding
        local mainFrameHeight = frameHeight + 2 * padding + extraTopPadding + extraBottomPadding
        parent:SetSize(mainFrameWidth, mainFrameHeight)
    end
end

function SettingsFrame:OnShow()
    if self.Init then
        self:Init()
    end
    self:UpdateAllWidgets()
end
SettingsFrame:SetScript("OnShow", SettingsFrame.OnShow)

function SettingsFrame:UpdateAllWidgets()
    if self.Widgets and self.OptionDB then
        local dbValue
        for _, widget in ipairs(self.Widgets) do
            if widget.dbKey or widget.cvar then
                if widget.dbKey then
                    dbValue = GetDBBool(widget.dbKey)
                else
                    dbValue = C_CVar.GetCVar(widget.cvar)
                end

                if dbValue ~= nil then
                    if widget.type == "Checkbox" then
                        if widget.cvar then
                            dbValue = C_CVar.GetCVarBool(widget.cvar)
                        end
                        widget:SetChecked(dbValue)
                    end
                end
            end
        end
    end
end

C_Timer.After(1, function()
    SettingsFrame:SetParent(RUIOptionsFrame)
    SettingsFrame:Show()
end)