local _, addon = ...
local GetDBBool = addon.GetDBBool
local _G = _G
local format = string.format

local function UpdateBarHotkeyText(namePatter, dbKey)
	--True: Show hotkey text
	local alpha = GetDBBool(dbKey) and 1 or 0
	local obj

	for i = 1, 12 do
		obj = _G[format(namePatter, i)]
		if obj then
			obj:SetAlpha(alpha)
		end
	end
end

local function UpdateBar0()
	UpdateBarHotkeyText("ActionButton%dHotKey", "KeybindText_PrimaryBar")
end

local function UpdateBar1()
	UpdateBarHotkeyText("MultiBarBottomLeftButton%dHotKey", "KeybindText_BottomLeftBar")
end

local function UpdateBar2()
	UpdateBarHotkeyText("MultiBarBottomRightButton%dHotKey", "KeybindText_BottomRightBar")
end

local function UpdateBar3()
	UpdateBarHotkeyText("MultiBarRightButton%dHotKey", "KeybindText_RightBar")
end

local function UpdateBar4()
	UpdateBarHotkeyText("MultiBarLeftButton%dHotKey", "KeybindText_RightBar2")
end

local function KeybindText_Update()
	UpdateBar0()
	UpdateBar1()
	UpdateBar2()
	UpdateBar3()
	UpdateBar4()
end

RetailUI.KeybindText_Update = KeybindText_Update


addon.CallbackRegistry:Register("SettingChanged.KeybindText_PrimaryBar", UpdateBar0)
addon.CallbackRegistry:Register("SettingChanged.KeybindText_BottomLeftBar", UpdateBar1)
addon.CallbackRegistry:Register("SettingChanged.KeybindText_BottomRightBar", UpdateBar2)
addon.CallbackRegistry:Register("SettingChanged.KeybindText_RightBar", UpdateBar3)
addon.CallbackRegistry:Register("SettingChanged.KeybindText_RightBar2", UpdateBar4)