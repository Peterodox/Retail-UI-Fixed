--Add quality color tint to equipment icon border

local _, addon = ...

local GetInventoryItemQuality = GetInventoryItemQuality
local GetInventoryItemLink = GetInventoryItemLink
local GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo

local USE_QUALITY_COLOR = true
local USE_ITEM_LEVEL = true

local PaperDollEquipmentSlotID = {
    [1] = true,     --HEADSLOT
    [2] = true,     --NECKSLOT
    [3] = true,     --SHOULDERSLOT
    [4] = true,     --SHIRTSLOT
    [5] = true,     --CHESTSLOT
    [6] = true,     --WAISTSLOT
    [7] = true,     --LEGSSLOT
    [8] = true,     --FEETSLOT
    [9] = true,     --WRISTSLOT
    [10]= true,     --HANDSSLOT
    [11]= true,     --FINGER0SLOT
    [12]= true,     --FINGER1SLOT
    [13]= true,     --TRINKET0SLOT
    [14]= true,     --TRINKET1SLOT
    [15]= true,     --BACKSLOT
    [16]= true,     --MAINHANDSLOT
    [17]= true,     --SECONDARYHANDSLOT
    [18]= true,     --RANGEDSLOT
    [19]= true,     --TABARDSLOT
}

local PaperDollButtonTexts = {}

local function SetItemButtonQuality_Base(button, quality, itemIDOrLink, suppressOverlays, isBound)
    local color = quality and quality > 1 and BAG_ITEM_QUALITY_COLORS[quality]
    if color then
        button.IconBorder:SetTexture([[Interface\Common\WhiteIconFrame]])
        button.IconBorder:SetVertexColor(color.r, color.g, color.b)
        button.IconBorder:Show()
    else
        button.IconBorder:Hide()
    end
end

if PaperDollItemSlotButton_Update then
    hooksecurefunc("PaperDollItemSlotButton_Update", function(button)
        local slotID = button:GetID()
        if not (slotID and PaperDollEquipmentSlotID[slotID]) then return end

        if button.IconBorder then
            if USE_QUALITY_COLOR then
                local quality = GetInventoryItemQuality("player", slotID)
                SetItemButtonQuality_Base(button, quality)
            else
                button.IconBorder:Hide()
            end
        end

        if USE_ITEM_LEVEL then
            if USE_QUALITY_COLOR then
                local link = GetInventoryItemLink("player", slotID)
                if link then
                    if not PaperDollButtonTexts[slotID] then
                        local fs = button:CreateFontString(nil, "OVERLAY", "Game10Font_o1")
                        fs:SetJustifyH("CENTER")
                        fs:SetJustifyV("BOTTOM");
                        fs:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
                        PaperDollButtonTexts[slotID] = fs
                    end
                    local level = GetDetailedItemLevelInfo(link)
                    PaperDollButtonTexts[slotID]:SetText(level)
                    PaperDollButtonTexts[slotID]:Show()
                    return
                end
            end
            if PaperDollButtonTexts[slotID] then
                PaperDollButtonTexts[slotID]:Hide()
            end
        end
    end)
end

local function PaperDoll_QualityBorder(state)
    USE_QUALITY_COLOR = state
end
addon.CallbackRegistry:Register("SettingChanged.PaperDoll_QualityBorder", PaperDoll_QualityBorder)

local function PaperDoll_ItemLevel(state)
    USE_ITEM_LEVEL = state
end
addon.CallbackRegistry:Register("SettingChanged.PaperDoll_ItemLevel", PaperDoll_ItemLevel)

