local addonName, addon = ...
local CallbackRegistry = addon.CallbackRegistry

local OptionDB = {}

local DefaultValues = {
	TidyIcons = false,
	DarkTheme = false,
	AlwaysShowExpBarText = false,
	KeybindText_PrimaryBar = true,
	KeybindText_BottomLeftBar = true,
	KeybindText_BottomRightBar = true,
	KeybindText_RightBar = true,
	KeybindText_RightBar2 = true,
	Components_Gryphons = true,
	Components_Bags = true,
	Components_BagSpaceText = true,
	Components_MicroMenu = true,
	Components_MicroAndBagsBackground = true,
}

local CustomCommand = {
	"XPBarTextScale",
}

local function UpdateAllModules()
	RetailUI:TidyIcons_Update()
	RetailUI:KeybindText_Update()
	RetailUI:DarkTheme_Update()
	RetailUI:Gryphons_Update()
	RetailUI:Bags_Update()
	RetailUI:BagSpaceText_Update()
	RetailUI:MicroMenu_Update()
	RetailUI:MicroAndBagsBackground_Update()
end

local function SavedVariables_Load()
	local db = RUI_SavedVars or {}
	if not db.Options then
		db.Options = {}
	end
	OptionDB = db.Options

	for dbKey, value in pairs(DefaultValues) do
		if OptionDB[dbKey] == nil or type(OptionDB[dbKey]) ~= type(value) then
			OptionDB[dbKey] = value
		end
	end

	UpdateAllModules();
end

local function LoadCustomCommand()
	local db = RUI_SavedVars or {}
	for _, dbKey in ipairs(CustomCommand) do
		if db[dbKey] ~= nil then
			CallbackRegistry:Trigger("Custom."..dbKey, db[dbKey]);
		end
	end
end

local function SavedVariables_Init()
	if RUI_SavedVars ~= nil then
		-- Add any missing saved variables
	else
		-- No saved variables exist, show popup and create default saved variables
		StaticPopup_Show("RUI_Welcome_Popup")
		-- Create default saved variables
		RUI_SavedVars = {}
		RUI_SavedVars.Options = {}
	end
	SavedVariables_Load()
	LoadCustomCommand()
end

local function ResetSettings()
	for dbKey, value in pairs(DefaultValues) do
		OptionDB[dbKey] = value
	end

	UpdateAllModules()
end
addon.ResetSettings = ResetSettings;

local function GetDBBool(dbKey)
	return OptionDB[dbKey] or false
end
addon.GetDBBool = GetDBBool

local function SetDBValue(dbKey, value, userInput)
	OptionDB[dbKey] = value
	CallbackRegistry:Trigger("SettingChanged."..dbKey, value, userInput);
end
addon.SetDBValue = SetDBValue

-- This event fires whenever an addon has finished loading and the
-- SavedVariables for that addon have been loaded from their file
local function AddonLoaded(self, event, name)
	if name == addonName then
		SavedVariables_Init()
		self:UnregisterEvent(event);
	end
end
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", AddonLoaded)




do	--Custom Command
	local function XPBarTextScale(value)
		local fontString = addon.PatchAPI.GetGlobalObject("ReputationWatchBar.OverlayFrame.Text")
		if fontString then
			fontString:SetScale(value)
		end
		fontString = MainMenuBarExpText;
		if fontString then
			fontString:SetScale(value)
		end
	end
	CallbackRegistry:Register("Custom.XPBarTextScale", XPBarTextScale);

	RUI_SetXPBarTextScale = XPBarTextScale
end