local addonName, addon = ...
local settings = {}

-- Only the appearance choices live in SavedVariables. Health remains client-owned.
local function LoadSettings()
    if type(ForeverPlatesDB) ~= "table" then ForeverPlatesDB = {} end
    local db = ForeverPlatesDB
    if db.style ~= "classic" and db.style ~= "compact" then db.style = "compact" end
    if type(db.classColors) ~= "boolean" then db.classColors = false end
    addon.db = db
    addon.config.style = db.style
    addon.config.classColors = db.classColors
    if addon.RequestLayout then addon.RequestLayout() end
end

local function Apply(key, value)
    addon.db[key] = value
    addon.config[key] = value
    if addon.RequestLayout then addon.RequestLayout() end
end

local function NotifySettings()
    for _, setting in pairs(settings) do setting:NotifyUpdate() end
end

local function RegisterSettings()
    if not Settings or not Settings.RegisterVerticalLayoutCategory or
        not Settings.RegisterProxySetting or not Settings.CreateCheckbox or
        not Settings.RegisterAddOnCategory or not Settings.VarType then return end

    local category = Settings.RegisterVerticalLayoutCategory("ForeverPlates")
    settings.style = Settings.RegisterProxySetting(category, "FOREVERPLATES_CLASSIC_STYLE",
        Settings.VarType.Boolean, "Classic oval nameplates", false,
        function() return addon.config.style == "classic" end,
        function(value) Apply("style", value and "classic" or "compact") end)
    Settings.CreateCheckbox(category, settings.style,
        "Use rounded classic nameplates. Uncheck to restore the compact style.")
    settings.classColors = Settings.RegisterProxySetting(category, "FOREVERPLATES_CLASS_COLORS",
        Settings.VarType.Boolean, "Player class colors", false,
        function() return addon.config.classColors end,
        function(value) Apply("classColors", value) end)
    Settings.CreateCheckbox(category, settings.classColors,
        "Color living player health bars by class. NPCs keep their normal reaction colors.")
    Settings.RegisterAddOnCategory(category)
    addon.settingsCategory = category
end

-- The existing /fplates handler owns slash registration and delegates here.
function addon.HandleAppearanceCommand(message)
    local command, value = message:match("^%s*(%a+)%s*(.-)%s*$")
    if command == "style" then
        if value ~= "classic" and value ~= "compact" then
            print("ForeverPlates: /fplates style classic | compact")
        else
            Apply("style", value)
            NotifySettings()
            print("ForeverPlates style: " .. value)
        end
        return true
    elseif command == "classcolors" then
        if value ~= "on" and value ~= "off" then
            print("ForeverPlates: /fplates classcolors on | off")
        else
            Apply("classColors", value == "on")
            NotifySettings()
            print("ForeverPlates player class colors: " .. value)
        end
        return true
    elseif command == "options" and value == "" then
        if InCombatLockdown() then
            print("ForeverPlates: Open options again out of combat.")
        elseif addon.settingsCategory and Settings.OpenToCategory then
            Settings.OpenToCategory(addon.settingsCategory:GetID())
        else
            print("ForeverPlates: Settings panel unavailable. Use /fplates style or /fplates classcolors.")
        end
        return true
    end
    return false
end

local driver = CreateFrame("Frame")
driver:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        LoadSettings()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        RegisterSettings()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")
