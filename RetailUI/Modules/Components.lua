local _, addon = ...
local GetDBBool = addon.GetDBBool

local function Gryphons_Update()
	if GetDBBool("Components_Gryphons") then
		MainMenuBarLeftEndCap:Show()
		MainMenuBarRightEndCap:Show()
	else
		MainMenuBarLeftEndCap:Hide()
		MainMenuBarRightEndCap:Hide()
	end
end

local function Update_KeyRing()
	if GetDBBool("Components_Bags") then
		KeyRingButton:Show()
	else
		KeyRingButton:Hide()
	end
end
hooksecurefunc("MainMenuBar_UpdateKeyRing", Update_KeyRing)

local function Bags_Update()
	if GetDBBool("Components_Bags") then
		MainMenuBarBackpackButton:Show()
		for i = 0, 3 do
			_G["CharacterBag" .. i .. "Slot"]:Show()
		end
	else
		MainMenuBarBackpackButton:Hide()
		for i = 0, 3 do
			_G["CharacterBag" .. i .. "Slot"]:Hide()
		end
	end
	Update_KeyRing()
end

local function BagSpaceText_Update()
	if GetDBBool("Components_BagSpaceText") then
		BagSpaceDisplay:Show()
	else
		BagSpaceDisplay:Hide()
	end
end

local function MicroMenu_Update(value, userInput)
	--if true then return end
	if GetDBBool("Components_MicroMenu") then

		MainMenuBarPerformanceBarFrame:Show()
		if userInput then

			UpdateMicroButtons()
		end
	else
		CharacterMicroButton:ClearAllPoints();
		CharacterMicroButton:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 16, -16);
		MainMenuBarPerformanceBarFrame:Hide()
	end
end

local function MicroAndBagsBackground_Update()
	if GetDBBool("Components_MicroAndBagsBackground") then
		RetailUIMicroButtonAndBagBar:Show()
	else
		RetailUIMicroButtonAndBagBar:Hide()
	end
end

RetailUI.Gryphons_Update = Gryphons_Update
RetailUI.Bags_Update = Bags_Update
RetailUI.BagSpaceText_Update = BagSpaceText_Update
RetailUI.MicroMenu_Update = MicroMenu_Update
RetailUI.MicroAndBagsBackground_Update = MicroAndBagsBackground_Update


addon.CallbackRegistry:Register("SettingChanged.Components_Gryphons", Gryphons_Update)
addon.CallbackRegistry:Register("SettingChanged.Components_Bags", Bags_Update)
addon.CallbackRegistry:Register("SettingChanged.Components_BagSpaceText", BagSpaceText_Update)
addon.CallbackRegistry:Register("SettingChanged.Components_MicroMenu", MicroMenu_Update)
addon.CallbackRegistry:Register("SettingChanged.Components_MicroAndBagsBackground", MicroAndBagsBackground_Update)