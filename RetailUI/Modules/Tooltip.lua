local _, addon = ...
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
local UnitName = UnitName
local UnitClass = UnitClass
local GetClassColor = GetClassColor


local function Tooltip_SetUnitAura(self, unit, auraIndex, filter)
    if not (unit and auraIndex) then return end

    local aura = GetAuraDataByIndex(unit, auraIndex, filter)
    local spellID = aura and (aura.spellId or aura.spellID)
    if not spellID then return end

    self:AddLine(" ")

    local _, sourceClassID, sourceName
    if aura.sourceUnit then
        _, sourceClassID = UnitClass(aura.sourceUnit)
        sourceName = UnitName(aura.sourceUnit)
    end

    if sourceClassID and sourceName then
        local _, _, _, hexColor = GetClassColor(sourceClassID)
        self:AddDoubleLine("ID: |cffffffff" .. spellID, "|r|c" .. hexColor .. sourceName .. "|r", 1, 0.82, 0, 1, 1, 1)
    else
        self:AddLine("ID: |cffffffff" .. spellID.."|r", 1, 0.82, 0)
    end

    self:Show()
end

do  --Self: Add SpellID to Player Buffs/Debuffs
    local IS_GAMETOOLTIP_HOOKED = false
    local SHOW_SPELL_ID = false

    local function Tooltip_SetSelfAura(self, unit, auraIndex, filter)
        if not SHOW_SPELL_ID then return end
        Tooltip_SetUnitAura(self, unit, auraIndex, filter)
    end

    local function ShowSpellIDOnTooltip(state, userInput)
        if state then
            SHOW_SPELL_ID = true
            if not IS_GAMETOOLTIP_HOOKED then
                IS_GAMETOOLTIP_HOOKED = true
                hooksecurefunc(GameTooltip, "SetUnitAura", Tooltip_SetSelfAura)
            end
        else
            SHOW_SPELL_ID = false
        end
    end

    addon.CallbackRegistry:Register("SettingChanged.Tooltip_SelfAuraSpellID", ShowSpellIDOnTooltip)
end

do  --Target: Add SpellID to Target Buffs/Debuffs
    local IS_GAMETOOLTIP_HOOKED = false
    local SHOW_SPELL_ID = false

    local function Tooltip_SetTargetAura(self, unit, auraIndex, filter)
        if not SHOW_SPELL_ID then return end
        Tooltip_SetUnitAura(self, unit, auraIndex, filter)
    end

    local function ShowSpellIDOnTooltip(state, userInput)
        if state then
            SHOW_SPELL_ID = true
            if not IS_GAMETOOLTIP_HOOKED then
                IS_GAMETOOLTIP_HOOKED = true
                hooksecurefunc(GameTooltip, "SetUnitBuff", Tooltip_SetTargetAura)
                hooksecurefunc(GameTooltip, "SetUnitDebuff", Tooltip_SetTargetAura)
            end
        else
            SHOW_SPELL_ID = false
        end
    end

    addon.CallbackRegistry:Register("SettingChanged.Tooltip_TargetAuraSpellID", ShowSpellIDOnTooltip)
end