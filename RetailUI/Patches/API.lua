local _, addon = ...
local WoWAPI = {}
local PatchAPI = {}
addon.WoWAPI = WoWAPI
addon.PatchAPI = PatchAPI

do  --Moved/Renamed
    WoWAPI.IsAddOnLoaded = C_AddOns.IsAddOnLoaded
    WoWAPI.LoadAddOn = C_AddOns.LoadAddOn
end


do  --Removed
    if not OptionsList_ClearSelection then
        function OptionsList_ClearSelection (listFrame, buttons)
            if buttons and type(buttons) == "table" then
                for _, button in pairs(buttons) do
                    button.highlight:SetVertexColor(.196, .388, .8)
                    button:UnlockHighlight()
                end
                listFrame.selection = nil
            end
        end
    end
end


do  --Our API
    local _G = _G
    local ipairs = ipairs
    local gmatch = string.gmatch

    local ObjectCache = {};

    local function GetGlobalObject(objNameKey)
        --Get object via string "FrameName.Key1.Key2"
        if ObjectCache[objNameKey] then
            return ObjectCache[objNameKey]
        end

        local obj = _G;

        for k in gmatch(objNameKey, "%w+") do
            if k == "GetRegions" and obj.GetRegions then
                return obj:GetRegions()
            else
                obj = obj[k];
                if not obj then
                    return nil
                end
            end
        end

        if obj and not ObjectCache then
            ObjectCache[objNameKey] = obj
        end

        return obj or nil
    end
    PatchAPI.GetGlobalObject = GetGlobalObject

    function PatchAPI.DoesGlobalObjectExist(objNameKey)
        return GetGlobalObject(objNameKey) ~= nil
    end

    local SHOW_DIAGNOSIS = false

    function PatchAPI.PopulateObjectTable(objectNames, tbl)
        local n = 0;
        for _, name in ipairs(objectNames) do
            for i = 1, select("#", GetGlobalObject(name)) do
                local obj = select(i, GetGlobalObject(name))
                if obj then
                    n = n + 1
                    tbl[n] = obj
                else
                    if SHOW_DIAGNOSIS then
                        print("Retail UI: Missing Objects "..name)
                    end
                end
            end
        end
        SHOW_DIAGNOSIS = false
        return tbl
    end
end