local _, addon = ...
local modes = {
    off = { false, false },
    percent = { true, false },
    value = { false, true },
    both = { true, true },
}

-- Blizzard owns the text contents, health updates and visibility decisions.
function addon.HealthText(health)
    local percent = C_CVar.GetCVarBitfield("nameplateInfoDisplay", Enum.NamePlateInfoDisplay.CurrentHealthPercent)
    local numeric = C_CVar.GetCVarBitfield("nameplateInfoDisplay", Enum.NamePlateInfoDisplay.CurrentHealthValue)
    local enabled = percent or numeric
    for _, key in ipairs({ "Text", "LeftText", "RightText" }) do
        local text = health[key]
        if text then
            text:SetAlpha(enabled and 1 or 0)
            text:SetFont(UNIT_NAME_FONT, addon.config.healthSize, "OUTLINE")
            text:SetShadowOffset(0, 0)
        end
    end
    if health.Text then
        if percent and not numeric then
            addon.Point(health.Text, "RIGHT", health, "RIGHT", -2, 0)
            health.Text:SetJustifyH("RIGHT")
        else
            addon.Point(health.Text, "CENTER", health, "CENTER", 0, 0)
            health.Text:SetJustifyH("CENTER")
        end
    end
    if health.LeftText then
        -- Current LeftText holds percentage after Blizzard initializes SetBarText.
        addon.Point(health.LeftText, "RIGHT", health, "RIGHT", -2, 0)
        health.LeftText:SetJustifyH("RIGHT")
    end
    if health.RightText then
        -- Current RightText holds the numeric value in both mode.
        addon.Point(health.RightText, "CENTER", health, "CENTER", 0, 0)
        health.RightText:SetJustifyH("CENTER")
    end
end

-- Read-only diagnostics; never inspect health values or secret text contents.
local function Display(value)
    if addon.Secret(value) then return "secret" end
    return tostring(value)
end

local function Size(region)
    if not addon.Allowed(region) then return "unavailable" end
    local width, height = region:GetSize()
    return Display(width) .. "x" .. Display(height)
end

local function Status()
    local version, build = GetBuildInfo()
    print("ForeverPlates " .. addon.version .. "; client " .. Display(version) .. " (" .. Display(build) .. ")")
    print("Appearance: style=" .. addon.config.style .. "; classColors=" .. Display(addon.config.classColors))
    print("Health settings: percent=" .. Display(C_CVar.GetCVarBitfield("nameplateInfoDisplay", Enum.NamePlateInfoDisplay.CurrentHealthPercent)) ..
        "; value=" .. Display(C_CVar.GetCVarBitfield("nameplateInfoDisplay", Enum.NamePlateInfoDisplay.CurrentHealthValue)))
    local selected, targetSelected, count, completed = nil, false, 0, 0
    addon.EachPlate(function(frame)
        count = count + 1
        local own = addon.frames[frame]
        if own and own.layoutComplete then completed = completed + 1 end
        local unit = addon.Unit(frame)
        local target = unit and UnitIsUnit(unit, "target")
        if not addon.Secret(target) and target then
            selected, targetSelected = frame, true
        elseif not selected then selected = frame end
    end)
    print("Allowed plates=" .. count .. "; completed layouts=" .. completed)
    if not selected then print("No allowed plate visible. Show a nearby nameplate and try again.") return end
    local container = selected.HealthBarsContainer
    local health = container and container.healthBar
    if not addon.Allowed(health) then print("Health bar unavailable.") return end
    local own = addon.frames[selected]
    print("Sample=" .. (targetSelected and "target" or "first visible") .. "; container=" .. Size(container) ..
        "; health=" .. Size(health) .. "; border=" .. Size(own and own.border))
    print("Client flags: simplified=" .. Display(health.isSimplified) .. "; target=" .. Display(health.isTarget) ..
        "; percent=" .. Display(health.showPercentage) .. "; numeric=" .. Display(health.showNumeric) ..
        "; forceShow=" .. Display(health.forceShow))
    for _, key in ipairs({ "Text", "LeftText", "RightText" }) do
        local text = health[key]
        if addon.Allowed(text) then
            local _, fontSize = text:GetFont()
            local layer, sub = text:GetDrawLayer()
            print(key .. ": shown=" .. Display(text:IsShown()) .. "; alpha=" .. Display(text:GetAlpha()) ..
                "; size=" .. Size(text) .. "; font=" .. Display(fontSize) .. "; layer=" .. Display(layer) .. "/" .. Display(sub))
        end
    end
end

SLASH_FOREVERPLATES1 = "/fplates"
SLASH_FOREVERPLATES2 = "/foreverplates"
SlashCmdList.FOREVERPLATES = function(message)
    message = message:lower()
    if message:match("^%s*status%s*$") then Status() return end
    if addon.HandleAppearanceCommand(message) then return end
    local mode = message:match("^%s*health%s+(%a+)%s*$")
    local choice = mode and modes[mode]
    if not choice then
        print("ForeverPlates: /fplates health percent | value | both | off; /fplates status")
        print("ForeverPlates: /fplates style classic | compact; /fplates classcolors on | off; /fplates options")
        return
    end
    local percent = C_CVar.SetCVarBitfield("nameplateInfoDisplay", Enum.NamePlateInfoDisplay.CurrentHealthPercent, choice[1])
    local numeric = C_CVar.SetCVarBitfield("nameplateInfoDisplay", Enum.NamePlateInfoDisplay.CurrentHealthValue, choice[2])
    if not percent or not numeric then
        print("ForeverPlates: The client could not apply the health setting. Try again out of combat.")
        return
    end
    if addon.RequestLayout then addon.RequestLayout() end
    print("ForeverPlates health display: " .. mode)
end
