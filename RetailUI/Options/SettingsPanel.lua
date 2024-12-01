local _, addon = ...
local L = addon.L
local GetDBBool = addon.GetDBBool
local SetDBValue = addon.SetDBValue

local TEXT_SPACING = 4
local WIDGET_SPACING = 8
local SECTOR_SPACING = 26
local HEADER_FIRST_WIDGET_GAP = 12
local FRAME_BORDER_PADDING = 20
local BORDER_MAINFRAME_PADDING = 16
local USE_VERTICAL_LAYOUT = false

local CHECKBOX_TEXT_GAP = 4
local CHECKBOX_VISUAL_SIZE = 20
local CHECKBOX_EFFECTIVE_SIZE = 24
local CHECKBOX_HITRECT_OFFSET_Y = 0.5* (CHECKBOX_VISUAL_SIZE - CHECKBOX_EFFECTIVE_SIZE)
local CHECKBOX_HIGHLIGHT_EXTENT = 4

local MainFrame


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
                {type = "Checkbox", name = L["Tooltip Show Self Aura Spell ID"], tooltip = L["Tooltip Show Self Aura Spell ID Tooltip"], dbKey = "Tooltip_SelfAuraSpellID"},
                {type = "Checkbox", name = L["Tooltip Show Target Aura Spell ID"], tooltip = L["Tooltip Show Target Aura Spell ID Tooltip"], dbKey = "Tooltip_TargetAuraSpellID"},
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

local OptionContainer = CreateFrame("Frame", nil, UIParent)
OptionContainer:Hide()

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


local ObjectPool = {}
do
    ObjectPool.pools = {}

    function ObjectPool:ReleaseAll()
        for type, pool in pairs(self.pools) do
            for _, obj in ipairs(pool) do
                obj:Hide()
                obj:ClearAllPoints()
                obj.inuse = nil
            end
        end
    end

    function ObjectPool:AcquireObjectByType(type)
        if not self.pools[type] then
            self.pools[type] = {}
        end

        for _, obj in ipairs(self.pools[type]) do
            if not obj.inuse then
                obj.inuse = true
                return obj
            end
        end
    end

    function ObjectPool:AddObjectToPool(obj, type)
        table.insert(self.pools[type], obj)
    end


    local InitTextFrame
    do
        local Methods = {
            "SetText", "SetTextColor", "SetFont", "SetFontObject", "SetJustifyH", "SetJustifyV",
            "GetHeight", "GetWidth", "GetWrappedWidth",
        }

        function InitTextFrame(self)
            for _, method in ipairs(Methods) do
                self[method] = function(_, ...)
                    return self.FontString[method](self.FontString, ...)
                end
            end
        end
    end

    function ObjectPool:AcquireFontString(parent, fontObject)
        local type = "FontString"
        local obj = self:AcquireObjectByType(type)
        if not obj then
            obj = CreateFrame("Frame", nil, OptionContainer)
            obj:SetSize(8, 8)
            local fs = obj:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetPoint("TOPLEFT", obj, "TOPLEFT", 0, 0)
            obj.FontString = fs
            InitTextFrame(obj)
            self:AddObjectToPool(obj, type)
        end
        fontObject = fontObject or "GameFontNormal"
        obj:SetFontObject(fontObject)
        obj:SetParent(parent)
        obj.inuse = true
        obj:Show()
        return obj
    end

    function ObjectPool:AcquireCheckbox(parent)
        local type = "Checkbox"
        local obj = self:AcquireObjectByType(type)
        if not obj then
            obj = CreateFrame("CheckButton", nil, OptionContainer, "RetailUISettingsCheckboxTemplate")
            self:AddObjectToPool(obj, type)
            obj:SetSize(CHECKBOX_VISUAL_SIZE, CHECKBOX_VISUAL_SIZE)
            obj.Text = obj:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            obj.Text:SetPoint("LEFT", obj, "RIGHT", CHECKBOX_TEXT_GAP, 0)
        end
        obj:SetParent(parent)
        obj.inuse = true
        obj:Show()
        return obj
    end
end

function OptionContainer:Init()
    self.Init = nil
    self.OptionDB = RUI_SavedVars.Options

    self:SetSize(128, 128)
    self:SetPoint("CENTER", nil, "CENTER", 0, 0)

    self.WidgetHighlight = self:CreateTexture(nil, "BACKGROUND", nil, 1)
    self.WidgetHighlight:SetColorTexture(1, 1, 1, 0.1)
    self.WidgetHighlight:Hide()

    self:Rebuild()
end

function OptionContainer:Rebuild()
    ObjectPool:ReleaseAll()

    local rowSpan
    local maxSpan = 0
    local offsetY = 0
    local scheme = Schematic

    local checkboxFont, showTitle
    if USE_VERTICAL_LAYOUT then
        checkboxFont = "GameFontNormal"
        showTitle = false
    else
        checkboxFont = "GameFontNormalSmall"
        showTitle = true
    end

    local function AddHeight(v, obj, overrideHeight)
        return Round(v + (overrideHeight or obj:GetHeight()))
    end

    local obj

    if showTitle and scheme.title then
        obj = ObjectPool:AcquireFontString(self, "GameFontNormalLarge")
        obj:SetText(scheme.title)
        obj:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -offsetY)
        offsetY = AddHeight(offsetY, obj)
    end

    if showTitle and scheme.subtitle then
        obj = ObjectPool:AcquireFontString(self, "GameFontHighlightSmall")
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

        local sectorWidgets = {}

        if sector.header then
            obj = ObjectPool:AcquireFontString(f, "GameFontHighlight")
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
                widget = ObjectPool:AcquireCheckbox(f)
                widget.Text:SetFontObject(checkboxFont)
                widget.Text:SetText(w.name)
                widget:SetPoint("TOPLEFT", f, "TOPLEFT", offsetX, -y)
                widget:SetScript("OnClick", Checkbox_OnClick)
                y = AddHeight(y, widget, CHECKBOX_EFFECTIVE_SIZE)
                widgetWidth = CHECKBOX_VISUAL_SIZE + CHECKBOX_TEXT_GAP + widget.Text:GetWrappedWidth() + offsetX
                if widgetWidth < 96 then
                    widgetWidth = 96
                end
                if widgetWidth > maxWidth then
                    maxWidth = widgetWidth
                end
            end

            if widget then
                widget.dbKey = w.dbKey
                widget.cvar = w.cvar
                widget.type = w.type
                widget.widgetInfo = w
                table.insert(self.Widgets, widget)
                table.insert(sectorWidgets, widget)
            end
        end

        local sectorWidth = Round(maxWidth)
        local sectorHeight = Round(y)
        f:SetSize(sectorWidth, sectorHeight)
        f.width = sectorWidth
        f.height = sectorHeight

        for _, widget in ipairs(sectorWidgets) do
            widget:SetHitRectInsets(0, -maxWidth + CHECKBOX_EFFECTIVE_SIZE, CHECKBOX_HITRECT_OFFSET_Y, CHECKBOX_HITRECT_OFFSET_Y)
        end

        f:ClearAllPoints()
        if sector.sideBySide and not USE_VERTICAL_LAYOUT then
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

    --Border
    --[[
    if not self.BorderFrame then
        local BorderFrame = CreateFrame("Frame", nil, self)
        self.BorderFrame = BorderFrame
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
        end
    end

    if self.BorderFrame then
        self.BorderFrame:ClearAllPoints()
        self.BorderFrame:SetPoint("TOPLEFT", self, "TOPLEFT", -FRAME_BORDER_PADDING, FRAME_BORDER_PADDING)
        self.BorderFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", FRAME_BORDER_PADDING, -FRAME_BORDER_PADDING)
    end
    --]]

    local parent = MainFrame
    self:SetParent(parent)
    self:ClearAllPoints()
    local extraTopPadding = 16
    local extraBottomPadding = 0
    local padding = BORDER_MAINFRAME_PADDING + FRAME_BORDER_PADDING
    self:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding - extraTopPadding)
    local mainFrameWidth = frameWidth + 2 * padding
    local mainFrameHeight = frameHeight + 2 * padding + extraTopPadding + extraBottomPadding
    parent:SetSize(mainFrameWidth, mainFrameHeight)
end

function OptionContainer:HighlightWidget(widget)
    self.WidgetHighlight:ClearAllPoints()
    self.WidgetHighlight:Hide()
    if widget then
        self.WidgetHighlight:SetPoint("LEFT", widget, "LEFT", -CHECKBOX_HIGHLIGHT_EXTENT, 0)
        self.WidgetHighlight:SetSize(widget:GetParent().width + 2*CHECKBOX_HIGHLIGHT_EXTENT, CHECKBOX_EFFECTIVE_SIZE)
        self.WidgetHighlight:Show()
    end
end

function OptionContainer:UpdateAllWidgets()
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


RetailUISettingsPanelMixin = {}
do
    function RetailUISettingsPanelMixin:OnLoad()
        MainFrame = self
        table.insert(UISpecialFrames, self:GetName())
        self.OnLoad = nil
        self:SetScript("OnLoad", nil)
        self:SetTitle("Retail UI")
    end

    function RetailUISettingsPanelMixin:SetTitle(title)
        self.NineSlice.Text:SetText(title)
    end

    function RetailUISettingsPanelMixin:OnShow_First()
        self.OnShow_First = nil
        OptionContainer:Init()
        OptionContainer:Show()
        self:SetScript("OnShow", self.OnShow)
        self:OnShow()
    end

    function RetailUISettingsPanelMixin:OnShow()
        OptionContainer:UpdateAllWidgets()
    end

    function RetailUISettingsPanelMixin:OnSlashCommand(forceShow)
        if SettingsPanel and SettingsPanel:IsShown() and self:IsShown() and not forceShow then
            return
        end

        if self:IsVisible() and not forceShow then
            self:Hide()
        else
            if USE_VERTICAL_LAYOUT then
                USE_VERTICAL_LAYOUT = false
                OptionContainer:Rebuild()
                self:ShowBorder(true)
                self:SetParent(UIParent)
                self:ClearAllPoints()
                self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
            self:Show()
        end
    end

    function RetailUISettingsPanelMixin:SetDarkMode(state)
        local a = state and 0.4 or 1
        self.NineSlice:SetCenterColor(a, a, a, 1)
        self.NineSlice:SetBorderColor(a, a, a, 1)
    end

    function RetailUISettingsPanelMixin:ShowBorder(state)
        self.NineSlice:SetShown(state)
        self.ClosePanelButton:SetShown(state)
        self.DragFrame:SetShown(state)
        self.Bg:SetShown(state)
        self:SetClampedToScreen(state);
    end
end

RetailUISettingsCheckboxMixin = {}
do
    function RetailUISettingsCheckboxMixin:OnEnter()
        if self.widgetInfo and self.widgetInfo.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.widgetInfo.name, 1, 1, 1)
            GameTooltip:AddLine(self.widgetInfo.tooltip, 1, 0.82, 0, true)
            GameTooltip:Show()
        end
    
        OptionContainer:HighlightWidget(self)
    end

    function RetailUISettingsCheckboxMixin:OnLeave()
        GameTooltip:Hide()
        OptionContainer:HighlightWidget()
    end
end


do  --Create an entrance to settings in Blizzard addon settings window
    local AddOnCategoryFrameMixin = {};

    function AddOnCategoryFrameMixin:OnLoad()
        self:Hide()

        self.scrollRange = 0;
        self.scrollable = false;
        self.scrollBaseOffset = 60;

        local textFromY = 22;
        local Text = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
        Text:SetJustifyH("LEFT")
        Text:SetJustifyV("TOP")
        Text:SetPoint("TOPLEFT", self, "TOPLEFT", 7, -textFromY)
        Text:SetText("Retail UI")

        local Divider = self:CreateTexture(nil, "OVERLAY");
        Divider:SetPoint("BOTTOMLEFT", Text, "BOTTOMLEFT", 11, -9);
        Divider:SetAtlas("Options_HorizontalDivider", true);

        local headerHeight = Round(textFromY + Text:GetHeight() + 10)

        local ScrollFrame = CreateFrame("Frame", nil, self)
        self.ScrollFrame = ScrollFrame;
        ScrollFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -headerHeight)
        ScrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0);
        ScrollFrame:SetClipsChildren(true);

        self:SetScript("OnShow", self.OnShow);
        self:SetScript("OnMouseWheel", self.OnMouseWheel);

        local ScrollBar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar");
        local barOffsetY = 4;
        local barOffsetX = -12;
        ScrollBar:SetPoint("TOPRIGHT", self, "TOPRIGHT", barOffsetX, -headerHeight -barOffsetY)
        ScrollBar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", barOffsetX, barOffsetY + 1)
        self.ScrollBar = ScrollBar

        local CategoryFrame = self;
        function ScrollBar:SetScrollPercentage(scrollPercentage, fromMouseWheel)
            ScrollControllerMixin.SetScrollPercentage(self, scrollPercentage);
	        self:Update();
            if not fromMouseWheel then
                CategoryFrame:SetScrollPercentage(scrollPercentage);
            end
        end
    end

    function AddOnCategoryFrameMixin:OnMouseWheel(delta)
        if self.scrollable then
            if delta > 0 and self.scrollOffset > 0 then
                self:SetScrollOffset(self.scrollOffset - 2*(WIDGET_SPACING + CHECKBOX_EFFECTIVE_SIZE), true)
            elseif delta < 0 and self.scrollOffset < self.scrollRange then
                self:SetScrollOffset(self.scrollOffset + 2*(WIDGET_SPACING + CHECKBOX_EFFECTIVE_SIZE), true)
            end
        end
    end

    function AddOnCategoryFrameMixin:SetScrollOffset(offset, fromMouseWheel)
        if offset > self.scrollRange then
            offset = self.scrollRange
        elseif offset < 0 then
            offset = 0
        end
        self.scrollOffset = offset;
        MainFrame:SetPoint("TOPLEFT", self.ScrollFrame, "TOPLEFT", 0, offset + self.scrollBaseOffset);

        if self.scrollable then
            self.ScrollBar:SetScrollPercentage(offset/self.scrollRange, fromMouseWheel)
        end
    end

    function AddOnCategoryFrameMixin:SetScrollPercentage(scrollPercentage)
        local offset = self.scrollRange * scrollPercentage;
        MainFrame:SetPoint("TOPLEFT", self.ScrollFrame, "TOPLEFT", 0, offset + self.scrollBaseOffset);
    end

    function AddOnCategoryFrameMixin:OnShow()
        MainFrame:SetParent(self.ScrollFrame)
        if not USE_VERTICAL_LAYOUT then
            USE_VERTICAL_LAYOUT = true
            OptionContainer:Rebuild()
            MainFrame:ShowBorder(false)
        end
        MainFrame:ClearAllPoints()
        MainFrame:SetPoint("TOPLEFT", self.ScrollFrame, "TOPLEFT", 0, 0)
        MainFrame:Hide()
        MainFrame:Show()

        local frameHeight = MainFrame:GetHeight();
        local scrollRange = frameHeight - self.ScrollFrame:GetHeight()
        self.scrollable = scrollRange > 0 or false;
        self.scrollRange = self.scrollable and scrollRange or 0
        self.scrollOffset = self.scrollOffset or 0;
        self:SetScrollOffset(self.scrollOffset, true)
        self.ScrollFrame:SetClipsChildren(self.scrollable)
        self.ScrollBar:SetShown(self.scrollable)

        if self.scrollable then
            self.ScrollBar:SetVisibleExtentPercentage(frameHeight/(frameHeight + scrollRange));
        end
    end

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local f = CreateFrame("Frame")
        f:SetSize(8, 8)

        Mixin(f, AddOnCategoryFrameMixin)
        f:OnLoad()

        local category = Settings.RegisterCanvasLayoutCategory(f, "Retail UI")
        Settings.RegisterAddOnCategory(category)
    end
end