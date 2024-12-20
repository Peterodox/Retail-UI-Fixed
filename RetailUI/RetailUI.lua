local _, addon = ...
local GetDBBool = addon.GetDBBool
local _G = _G

--------------------==≡≡[ CHAT WELCOME MESSAGE ]≡≡==-----------------------------------

--[[
local icon = "ShipMissionIcon-Bonus-MapBadge"
local welcomeMessage = "|cfff8e928Retail UI: |cffffffffType /rui to toggle the options menu."
print(CreateAtlasMarkup(icon, 16, 16), welcomeMessage)
--]]



--------------------==≡≡[ SLASH COMMANDS ]≡≡==-----------------------------------

SLASH_RUI1, SLASH_RUI2, SLASH_RUI3 = '/rui', '/retail', '/retailui'
SlashCmdList["RUI"] = function()
	RetailUISettingsPanel:OnSlashCommand()
end



--------------------==≡≡[ DIALOGS ]≡≡==-----------------------------------

-- See http://wowwiki.wikia.com/wiki/Creating_simple_pop-up_dialog_boxes
StaticPopupDialogs["Welcome_Popup"] = {
  text = "Welcome to Retail UI",
  button1 = "See options",
  OnAccept = function()
	RetailUISettingsPanel:OnSlashCommand(true)
	-- Sound: GAMEDIALOGOPEN
	PlaySound(88)
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}



--------------------==≡≡[ HIDE DEFAULT BLIZZARD ART ]≡≡==-----------------------------------

local function HideDefaultBlizzardArt()
	-- Hide default Blizzard bar textures
	for i = 0,  3 do
		_G["MainMenuBarTexture" .. i]:Hide()
	end
end



--------------------==≡≡[ ENABLE MINIMAP ZOOM IN/OUT VIA SCROLL ]≡≡==-----------------------------------

-- We're deferring this function, so that we can override other AddOn's
-- Minimap zoom implementations
local function Minimap_EnableScrollZoom()
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(target, input)
		local currentZoom = Minimap:GetZoom()
		local zoomLevels = Minimap:GetZoomLevels()
		local scrollUp = 1
		local scrollDown = -1

		-- Set zoom
		if (input == scrollUp and currentZoom < 5) then
			Minimap:SetZoom(currentZoom + 1)
		elseif (input == scrollDown and currentZoom > 0) then
			Minimap:SetZoom(currentZoom - 1)
		end

		-- Disable/enable minimap buttons
		currentZoom = Minimap:GetZoom()
		if (currentZoom == (zoomLevels - 1)) then
			MinimapZoomIn:Disable()
		else
			MinimapZoomIn:Enable()
		end
		if (currentZoom == 0) then
			MinimapZoomOut:Disable()
		else
			MinimapZoomOut:Enable()
		end
	end)
end
addon.CallbackRegistry:Register("AddOnLoadingComplete", Minimap_EnableScrollZoom)



--------------------==≡≡[ MICRO MENU ]≡≡==----------------------------------
local LFGMicroButton
local LGF_POSITION_INDEX = 3	--The 3rd one from the right

local function ModifyLFGMinimapButton()
	local f = LFGMinimapFrame

	if f and f:IsShown() then
		if LFGMinimapFrameBorder then
			LFGMinimapFrameBorder:SetTexture(nil)
		end

		if not LFGMicroButton then
			local function LoadMicroButtonTextures(self)
				self:RegisterForClicks("LeftButtonUp")
				local prefix = "Interface\\Buttons\\UI-MicroButton"
				local name = "character"
				self:SetNormalTexture(prefix..name.."-Up")
				self:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight")
			end

			LFGMicroButton = CreateFrame("Button", "RetailUILGFMicroButton", UIParent, "MainMenuBarMicroButton")
			LFGMicroButton:ClearAllPoints()
			LFGMicroButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			LoadMicroButtonTextures(LFGMicroButton)
			LFGMicroButton:SetScript("OnClick", nil)
			LFGMicroButton:SetScript("OnDisable", nil)
			LFGMicroButton:SetHitRectInsets(14, 14, 28, 28)

			f:SetFrameLevel(LFGMicroButton:GetFrameLevel() + 10)
			f:ClearAllPoints()
			f:SetParent(UIParent)

			local offsetY = -11
			f:SetPoint("CENTER", LFGMicroButton, "CENTER", 0, offsetY)

			f:HookScript("OnMouseDown", function()
				LFGMicroButton:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Down")
			end)

			f:HookScript("OnMouseUp", function()
				LFGMicroButton:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Up")
			end)

			f:HookScript("OnEnter", function()
				LFGMicroButton:LockHighlight()
			end)

			f:HookScript("OnLeave", function()
				LFGMicroButton:UnlockHighlight()
			end)

			f:ClearHighlightTexture()
		end

		LFGMicroButton:Show()

		return LFGMicroButton
	else
		if LFGMicroButton then
			LFGMicroButton:Hide()
		end
	end
end

local MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"GuildMicroButton",
	"WorldMapMicroButton",
	"MainMenuMicroButton",
	"HelpMicroButton",
}

local function Position_MicroMenuButtons()
	local numVisible = 0
	local firstButton, lastButton

	local microButtons = {}	--Button type

	if WorldMapMicroButton then
		if GetDBBool("MicroMenu_WorldMap") then
			WorldMapMicroButton:Hide();
		else
			WorldMapMicroButton:Show();
		end
	end

	for i, name in ipairs(MICRO_BUTTONS) do
		local microButton = _G[name]
		if microButton and microButton:IsShown() then
			numVisible = numVisible + 1
			microButtons[numVisible] = microButton
		end
	end

	local LFGButton = ModifyLFGMinimapButton()
	if LFGButton then
		numVisible = numVisible + 1
		local pos = numVisible + 1 - LGF_POSITION_INDEX
		if pos < 1 then
			pos = 1
		end
		table.insert(microButtons, pos, LFGButton)
	end

	for i, microButton in ipairs(microButtons) do
		microButton:ClearAllPoints()
		if i == 1 then
			firstButton = microButton
		else
			microButton:SetPoint("BOTTOMLEFT", lastButton, "BOTTOMRIGHT", -3, 0)
		end
		lastButton = microButton
	end

	if GetDBBool("Components_MicroAndBagsBackground") then
		if numVisible < 8 then
			numVisible = 8
		end
	end

	local buttonWidth = 29
	local buttonOffset = -3
	local microOffset = (numVisible - 1) * (buttonWidth + buttonOffset) - buttonOffset

	local container = RetailUIMicroButtonAndBagBar
	local barWidth = microOffset + 30
	container:SetWidth(barWidth)

	firstButton:ClearAllPoints()
	firstButton:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -microOffset, 3.5)

	-- Latency indicator
	local f1 = MainMenuBarPerformanceBarFrame
	f1:SetFrameStrata("HIGH")
	f1:SetScale((HelpMicroButton:GetWidth() / f1:GetWidth()) * (1 / 3))

	local f2 = MainMenuBarPerformanceBar
	f2:SetRotation(math.pi * 0.5)
	f2:ClearAllPoints()
	f2:SetPoint("BOTTOM", HelpMicroButton, -1, -24)

	local f3 = MainMenuBarPerformanceBarFrameButton
	f3:ClearAllPoints()
	f3:SetPoint("BOTTOMLEFT", f2, -(f2:GetWidth() / 2), 0)
	f3:SetPoint("TOPRIGHT", f2, f2:GetWidth() / 2, -28)
	--]]
end

local function MicroMenu_Hook()
	RetailUI:MicroMenu_Update()
	Position_MicroMenuButtons()
end
hooksecurefunc("MoveMicroButtons", MicroMenu_Hook)
hooksecurefunc("UpdateMicroButtons", MicroMenu_Hook)
hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", MicroMenu_Hook)


local function MicroAndBagsBackground_Update(value, userInput)
	if userInput then
		Position_MicroMenuButtons()
	end
end
addon.CallbackRegistry:Register("SettingChanged.Components_MicroAndBagsBackground", MicroAndBagsBackground_Update)
addon.CallbackRegistry:Register("SettingChanged.MicroMenu_WorldMap", MicroAndBagsBackground_Update)

--------------------------------==≡≡[ BAG SPACE TEXT ]≡≡==--------------------------------

local BagSpaceDisplay = CreateFrame("Frame", "BagSpaceDisplay", MainMenuBarBackpackButton)

BagSpaceDisplay:ClearAllPoints()
BagSpaceDisplay:SetPoint("BOTTOM", MainMenuBarBackpackButton, 0, -8)
BagSpaceDisplay:SetSize(MainMenuBarBackpackButton:GetWidth(), MainMenuBarBackpackButton:GetHeight())

BagSpaceDisplay.Text = BagSpaceDisplay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
BagSpaceDisplay.Text:SetAllPoints(BagSpaceDisplay)

local function UpdateBagSpace()
	local totalFree, freeSlots, bagFamily = 0
	for i = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		freeSlots, bagFamily = C_Container.GetContainerNumFreeSlots(i)
		if bagFamily == 0 then
			totalFree = totalFree + freeSlots
		end
	end

	BagSpaceDisplay.Text:SetText(string.format("(%s)", totalFree))
end

local f = CreateFrame("Frame")
f:RegisterEvent("BAG_UPDATE")
f:SetScript("OnEvent", UpdateBagSpace)



--------------------==≡≡[ ACTIONBARS/BUTTONS POSITIONING AND SCALING ]≡≡==-----------------------------------

-- Only needs to be run once, or when leaving combat.
local function Initial_ActionBarPositioning()
	-- Ensures these frames don't move up when player is max level
	UIPARENT_MANAGED_FRAME_POSITIONS.PossessBarFrame.maxLevel = 0
	UIPARENT_MANAGED_FRAME_POSITIONS.MultiCastActionBarFrame.maxLevel = 0

	-- Ensures these bars don't move when reputation bar is toggled, or when
	-- player is max level
	UIPARENT_MANAGED_FRAME_POSITIONS.StanceBarFrame = nil
	UIPARENT_MANAGED_FRAME_POSITIONS.MultiBarBottomLeft = nil

	if not InCombatLockdown() then
		-- Bottom left action button Position
		MultiBarBottomLeft:SetPoint("BOTTOMLEFT", ActionButton1, "TOPLEFT", 0, 13)

		-- Bottom right action button Position
		MultiBarBottomRight:SetPoint("LEFT", MultiBarBottomLeft, "RIGHT", 43, 0)

		-- Bottom right action button Wrapping
		MultiBarBottomRightButton7:SetPoint("LEFT", MultiBarBottomRight, 0, -50)

		-- Action bar page arrow Positions
		ActionBarUpButton:SetPoint("CENTER", MainMenuBar, "BOTTOMLEFT", 521, 30)
		ActionBarDownButton:SetPoint("CENTER", ActionBarUpButton, "BOTTOM", 0, -3)

		-- Backpack Position
		MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", RetailUIMicroButtonAndBagBar, -7, 47)

		-- Bag slots' Position and Scale
		for i = 0, 3 do
			local bagFrame, previousBag = _G["CharacterBag" .. i .. "Slot"], _G["CharacterBag" .. i-1 .. "Slot"]
	
			bagFrame:SetScale(0.75)
			bagFrame:ClearAllPoints()
	
			if i == 0 then
				bagFrame:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "BOTTOMLEFT", -9, 1)
			else
				bagFrame:SetPoint("BOTTOMRIGHT", previousBag, "BOTTOMLEFT", -6, 0)
			end
		end

		-- Key ring Scale and Position
		KeyRingButton:SetScale(0.8)
		KeyRingButton:SetPoint("RIGHT", CharacterBag3Slot, "LEFT", -4, -2)

		-- Pet bar texture Position (Visibility when bottom left bar is hidden)
		SlidingActionBarTexture0:SetPoint("TOPLEFT", PetActionBarFrame, 1, -5)
	end
end

local shortBarActive

local function ActivateShortBar()
	shortBarActive = true

	-- Toggle art
	RetailUIArtFrame.BackgroundSmall:Show()
	RetailUIArtFrame.BackgroundLarge:Hide()

	-- Main menu bar Size
	MainMenuBar:SetSize(550, 53)

	-- Action bar page number Position
	MainMenuBarPageNumber:SetPoint("BOTTOMLEFT", MainMenuBar, 537, 16.5)

	-- Gryphon Positions
	MainMenuBarLeftEndCap:ClearAllPoints()
	MainMenuBarLeftEndCap:SetPoint("RIGHT", RetailUIArtFrame, "LEFT", 30, 20)
	MainMenuBarRightEndCap:ClearAllPoints()
	MainMenuBarRightEndCap:SetPoint("LEFT", RetailUIArtFrame, "RIGHT", -30, 20)

	-- Status bars background
	RetailUIStatusBars.Background:SetWidth(540)
end

local function ActivateLongBar()
	shortBarActive = false

	-- Toggle art
	RetailUIArtFrame.BackgroundSmall:Hide()
	RetailUIArtFrame.BackgroundLarge:Show()

	-- Main menu bar Size
	MainMenuBar:SetSize(804, 53)

	-- Action bar page number Position
	MainMenuBarPageNumber:SetPoint("BOTTOMLEFT", MainMenuBar, 536, 16.5)

	-- Gryphon positions
	MainMenuBarLeftEndCap:ClearAllPoints()
	MainMenuBarLeftEndCap:SetPoint("RIGHT", RetailUIArtFrame, "LEFT", -97, 20)
	MainMenuBarRightEndCap:ClearAllPoints()
	MainMenuBarRightEndCap:SetPoint("LEFT", RetailUIArtFrame, "RIGHT", 97, 20)

	-- Status bars background
	RetailUIStatusBars.Background:SetWidth(798)
end

local function Update_ActionBars()
	if not InCombatLockdown() then
		if MultiBarBottomLeft:IsShown() then
			PetActionButton1:SetPoint("BOTTOMLEFT", PetActionButton1:GetParent(), "BOTTOMLEFT", 36, 2)
			StanceBarFrame:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", 21, 41)
		else
			PetActionButton1:SetPoint("BOTTOMLEFT", PetActionButton1:GetParent(), "BOTTOMLEFT", 36, -2)
			StanceBarFrame:SetPoint("BOTTOMLEFT", MainMenuBar, "TOPLEFT", 30, -5)
		end

		if MultiBarBottomRight:IsShown() then
			ActivateLongBar()
		else
			ActivateShortBar()
		end

		Update_StatusBars()
	end
end
hooksecurefunc("MultiActionBar_Update", Update_ActionBars)

-- Updates exhaustion tick position on experience bar width change
local function Update_ExhaustionTick()
	if GetXPExhaustion() and ExhaustionTick ~= nil and ExhaustionTick:IsShown() then
		ExhaustionTick_OnEvent(ExhaustionTick, "UPDATE_EXHAUSTION")
	end
end
MainMenuExpBar:HookScript('OnSizeChanged', Update_ExhaustionTick)

local function Toggle_StatusBars(SmallUpper, Small, LargeUpper, Large)
	if SmallUpper then
		RetailUIStatusBars.SingleBarSmallUpper:Show()
	else
		RetailUIStatusBars.SingleBarSmallUpper:Hide()
	end
	if Small then
		RetailUIStatusBars.SingleBarSmall:Show()
	else
		RetailUIStatusBars.SingleBarSmall:Hide()
	end
	if LargeUpper then
		RetailUIStatusBars.SingleBarLargeUpper:Show()
	else
		RetailUIStatusBars.SingleBarLargeUpper:Hide()
	end
	if Large then
		RetailUIStatusBars.SingleBarLarge:Show()
	else
		RetailUIStatusBars.SingleBarLarge:Hide()
	end

	-- StatusBars' Widths
	if shortBarActive then
		ReputationWatchBar.StatusBar:SetWidth(540)
	else
		ReputationWatchBar.StatusBar:SetWidth(798)
	end
	if shortBarActive then
		MainMenuExpBar:SetWidth(540)
	else
		MainMenuExpBar:SetWidth(798)
	end

	local point, relativeTo, relativePoint, xOfs = RetailUIStatusBars:GetPoint()
	-- Two Status Bars are shown
	if (LargeUpper and Large) or (SmallUpper and Small) then
		-- Reputation bar text Position
		ReputationWatchBar.OverlayFrame.Text:ClearAllPoints()
		ReputationWatchBar.OverlayFrame.Text:SetPoint("CENTER", ReputationWatchBar, 0, 3)

		-- Reputation bar Size and Position
		ReputationWatchBar.StatusBar:SetHeight(7)
		ReputationWatchBar:ClearAllPoints()
		ReputationWatchBar:SetPoint("BOTTOM", UIParent, 0, 7)

		-- Experience bar Size and Position
		MainMenuExpBar:SetHeight(8)
		MainMenuExpBar:ClearAllPoints()
		MainMenuExpBar:SetPoint("BOTTOM", UIParent, 0, 0)

		-- StatusBars' Textures
		RetailUIStatusBars.SingleBarLargeUpper:SetHeight(10)
		RetailUIStatusBars.SingleBarLarge:SetHeight(10)
		RetailUIStatusBars.SingleBarSmallUpper:SetHeight(10)
		RetailUIStatusBars.SingleBarSmall:SetHeight(10)
		RetailUIStatusBars:SetPoint(point, relativeTo, relativePoint, xOfs, -1)

		-- Reputation texture Position
		RetailUIStatusBars.SingleBarLargeUpper:ClearAllPoints()
		RetailUIStatusBars.SingleBarLargeUpper:SetPoint(point, relativeTo, relativePoint, xOfs, 9)
		RetailUIStatusBars.SingleBarSmallUpper:SetPoint(point, relativeTo, relativePoint, xOfs, 9)

	-- Only reputation bar is shown (Max level)
	elseif (LargeUpper or SmallUpper) and not (Large and Small) then
		-- Reputation bar text Position
		ReputationWatchBar.OverlayFrame.Text:ClearAllPoints()
		ReputationWatchBar.OverlayFrame.Text:SetPoint("CENTER", ReputationWatchBar, 0, 2)

		-- Reputation bar Size and Position
		ReputationWatchBar.StatusBar:SetHeight(12)
		ReputationWatchBar:ClearAllPoints()
		ReputationWatchBar:SetPoint("BOTTOM", UIParent, 0, 0)

		-- Experience bar Size and Position
		MainMenuExpBar:SetHeight(12)
		MainMenuExpBar:ClearAllPoints()
		MainMenuExpBar:SetPoint("BOTTOM", UIParent, 0, 0)

		-- StatusBars' Texture Visilibity
		if shortBarActive then
			RetailUIStatusBars.SingleBarSmallUpper:Hide()
			RetailUIStatusBars.SingleBarSmall:Show()
		else
			RetailUIStatusBars.SingleBarLargeUpper:Hide()
			RetailUIStatusBars.SingleBarLarge:Show()
		end

		RetailUIStatusBars.SingleBarLargeUpper:SetHeight(14)
		RetailUIStatusBars.SingleBarLarge:SetHeight(14)
		RetailUIStatusBars.SingleBarSmallUpper:SetHeight(14)
		RetailUIStatusBars.SingleBarSmall:SetHeight(14)
		RetailUIStatusBars:SetPoint(point, relativeTo, relativePoint, xOfs, 1)

		-- Reputation texture Position
		RetailUIStatusBars.SingleBarLarge:ClearAllPoints()
		RetailUIStatusBars.SingleBarLarge:SetPoint(point, relativeTo, relativePoint, xOfs, 0)
		RetailUIStatusBars.SingleBarSmall:SetPoint(point, relativeTo, relativePoint, xOfs, 0)

	else
		-- Reputation bar text Position
		ReputationWatchBar.OverlayFrame.Text:ClearAllPoints()
		ReputationWatchBar.OverlayFrame.Text:SetPoint("CENTER", ReputationWatchBar, 0, 2)

		-- Reputation bar Size and Position
		ReputationWatchBar.StatusBar:SetHeight(12)
		ReputationWatchBar:ClearAllPoints()
		ReputationWatchBar:SetPoint("BOTTOM", UIParent, 0, 0)

		-- Experience bar Size and Position
		MainMenuExpBar:SetHeight(12)
		MainMenuExpBar:ClearAllPoints()
		MainMenuExpBar:SetPoint("BOTTOM", UIParent, 0, 0)

		-- StatusBars' Textures
		RetailUIStatusBars.SingleBarLargeUpper:SetHeight(14)
		RetailUIStatusBars.SingleBarLarge:SetHeight(14)
		RetailUIStatusBars.SingleBarSmallUpper:SetHeight(14)
		RetailUIStatusBars.SingleBarSmall:SetHeight(14)
		RetailUIStatusBars:SetPoint(point, relativeTo, relativePoint, xOfs, 1)

		-- Reputation texture Position
		RetailUIStatusBars.SingleBarLargeUpper:ClearAllPoints()
		RetailUIStatusBars.SingleBarLargeUpper:SetPoint(point, relativeTo, relativePoint, xOfs, 0)
		RetailUIStatusBars.SingleBarSmallUpper:SetPoint(point, relativeTo, relativePoint, xOfs, 0)
	end
end

local function ActionBar_SetYOffset(yOffset)
	-- Get current positions
	local bGPoint, bGRelTo, bGRelPoint, bGOffsetX = RetailUIArtFrame.BackgroundSmall:GetPoint()
	local actionsPoint, actionsRelTo, actionsRelPoint, actionsOffsetX = MainMenuBar:GetPoint()

	-- Reposition Background
	RetailUIArtFrame.BackgroundSmall:SetPoint(bGPoint, bGRelTo, bGRelPoint, bGOffsetX, yOffset)
	RetailUIArtFrame.BackgroundLarge:SetPoint(bGPoint, bGRelTo, bGRelPoint, bGOffsetX, yOffset)

	-- Reposition MainMenuBar (moves all actions)
	MainMenuBar:SetPoint(actionsPoint, actionsRelTo, actionsRelPoint, actionsOffsetX, yOffset)
end

function Update_StatusBars()
	-- Reputation bar Font
	ReputationWatchBar.OverlayFrame.Text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

	-- Hide default reputation and experience bar textures
	for i = 0, 3 do
		_G["MainMenuXPBarTexture" .. i]:Hide()
		_G.ReputationWatchBar.StatusBar["WatchBarTexture" .. i]:Hide()
		-- Max level stuff to hide (When experience bar is hidden)
		_G["MainMenuMaxLevelBar" .. i]:Hide()
		_G.ReputationWatchBar.StatusBar["XPBarTexture" .. i]:Hide()
	end
	MainMenuExpBar:SetFrameStrata("LOW")
	ExhaustionTick:SetFrameStrata("MEDIUM")

	-- Experience bar text Position
	MainMenuBarExpText:ClearAllPoints()
	MainMenuBarExpText:SetPoint("CENTER", MainMenuExpBar, 0, 1)
	-- Experience bar Font
	MainMenuBarExpText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	-- Experience bar text Strata
	MainMenuBarOverlayFrame:SetFrameStrata("MEDIUM")

	if ReputationWatchBar:IsShown() and MainMenuExpBar:IsShown() then
		if shortBarActive then
			Toggle_StatusBars(true, true)
		else
			Toggle_StatusBars(false, false, true, true)
		end
		ActionBar_SetYOffset(19)

	elseif ReputationWatchBar:IsShown() then
		if shortBarActive then
			Toggle_StatusBars(true)
		else
			Toggle_StatusBars(false, false, true)
		end
		ActionBar_SetYOffset(13)

	elseif MainMenuExpBar:IsShown() then
		if shortBarActive then
			Toggle_StatusBars(false, true)
		else
			Toggle_StatusBars(false, false, false, true)
		end
		ActionBar_SetYOffset(13)

	else -- No status bar is shown (Shown at Max level with no reputation bar)
		Toggle_StatusBars()
		ActionBar_SetYOffset(0)
	end
end
ReputationWatchBar:HookScript('OnShow', Update_StatusBars)
ReputationWatchBar:HookScript('OnHide', Update_StatusBars)
MainMenuExpBar:HookScript('OnShow', Update_StatusBars)
MainMenuExpBar:HookScript('OnHide', Update_StatusBars)
hooksecurefunc("MainMenuTrackingBar_Configure", Update_StatusBars)



--------------------==≡≡[ PET ACTION BAR ]≡≡==-----------------------------------

-- Disallow Pet Action Bar offset if player is at max level
local function PetActionBar_DisallowMaxLevelOffset()
	UIPARENT_MANAGED_FRAME_POSITIONS.PETACTIONBAR_YOFFSET.maxLevel = 0
end

-- Disallow Pet Action Bar offset if the reputation watch bar is shown
-- NOTE: Unsafe to call in combat
local function PetActionBar_DisallowReputationOffset()
	UIPARENT_MANAGED_FRAME_POSITIONS.PETACTIONBAR_YOFFSET.watchBar = 0
end

local function SetYOffset(Frame, yOffset)
	local point, relativeTo, relativePoint, xOffset = Frame:GetPoint()
	Frame:ClearAllPoints()
	Frame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
end

-- Safely calls PetActionBar_DisallowReputationOffset once when leaving combat
local function PetActionBar_SafelyDisallowReputationOffset()
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_REGEN_ENABLED")
	f:SetScript("OnEvent", function(self)
		PetActionBar_DisallowReputationOffset()
		MultiActionBar_Update()
		self:UnregisterAllEvents()
	end)
end

PetActionBar_DisallowMaxLevelOffset()

-- Timer ensures "inCombat" boolean is accurate on load
-- This is crucial to prevent pet action bar becoming stuck and taint occuring
C_Timer.After(0, function()
	-- See https://authors.curseforge.com/forums/world-of-warcraft/general-chat/lua-code-discussion/225680-problem-with-incombatlockdown
    local inCombat = UnitAffectingCombat("player") or InCombatLockdown()
	if inCombat then
		PetActionBar_SafelyDisallowReputationOffset()
	else
		PetActionBar_DisallowReputationOffset()
	end
end)

--------------------==≡≡[ GENERAL EVENTS ]≡≡==-----------------------------------

-- Runs on Login
-- Most information about the game world should now be available to the UI
local function PlayerLogin()
	SESSION_XPBARTEXT_CVAR = GetCVarBool("xpBarText")
	HideDefaultBlizzardArt()
	Initial_ActionBarPositioning()
	Update_ActionBars()
	UpdateBagSpace()
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", PlayerLogin)


--[[
local function ShowAsExperienceBarCheckbox_Disable()
	ReputationDetailMainScreenCheckBox:Disable()
	ReputationDetailMainScreenCheckboxText:SetTextColor(0.5, 0.5, 0.5)
	ReputationDetailMainScreenCheckboxText:SetText("(Can't toggle in combat)")
end

local function ActionBarCheckboxes_Disable()
	InterfaceOptionsActionBarsPanelBottomLeft:Disable()
	_G[InterfaceOptionsActionBarsPanelBottomLeft:GetName() .. "Text"]:SetText(
		"Show Bottom Left ActionBar (can't toggle in combat)"
	)
	InterfaceOptionsActionBarsPanelBottomRight:Disable()
	_G[InterfaceOptionsActionBarsPanelBottomRight:GetName() .. "Text"]:SetText(
		"Show Bottom Right ActionBar (can't toggle in combat)"
	)
end

local function PlayerEnteredCombat()
	ShowAsExperienceBarCheckbox_Disable()
	ActionBarCheckboxes_Disable()
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:SetScript("OnEvent", PlayerEnteredCombat)

local ShowAsExperienceBarCheckbox_Text = ReputationDetailMainScreenCheckboxText:GetText()

local function ShowAsExperienceBarCheckbox_Enable()
	ReputationDetailMainScreenCheckBox:Enable()
	ReputationDetailMainScreenCheckboxText:SetTextColor(1, 0.82, 0)
	ReputationDetailMainScreenCheckboxText:SetText(
		ShowAsExperienceBarCheckbox_Text
	)
end

local function ActionBarCheckboxes_Enable()
	InterfaceOptionsActionBarsPanelBottomLeft:Enable()
	_G[InterfaceOptionsActionBarsPanelBottomLeft:GetName() .. "Text"]:SetText(
		"Show Bottom Left ActionBar"
	)
	InterfaceOptionsActionBarsPanelBottomRight:Enable()
	_G[InterfaceOptionsActionBarsPanelBottomRight:GetName() .. "Text"]:SetText(
		"Show Bottom Right ActionBar"
	)
end

local function PlayerLeftCombat()
	ShowAsExperienceBarCheckbox_Enable()
	ActionBarCheckboxes_Enable()

	-- Update layout
	Initial_ActionBarPositioning()
	Update_ActionBars()
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", PlayerLeftCombat)
--]]