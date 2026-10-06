local _, addon = ...
local MEDIA = "Interface\\AddOns\\ForeverPlates\\media\\"
local function BorderPath()
    return MEDIA .. (addon.config.style == "classic" and "ClassicBorder.tga" or "CompactBorder.tga")
end
local FILL = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"
local BAR_W, BAR_H = 103.75, 10
local INSET_L, INSET_R, INSET_T, INSET_B = 3.5, 20.75, 2.5, 3.5
local HEALTH_ART = { "bgTexture", "selectedBorder", "deselectedOverlay" }
local BADGES = { "LevelFrame", "PlayerLevelDiffFrame", "ClassificationFrame" }
local EVENTS = {
    "PLAYER_LOGIN", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
    "UNIT_LEVEL", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_AURA",
    "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "DISPLAY_SIZE_CHANGED",
    "UI_SCALE_CHANGED", "CVAR_UPDATE", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTED",
}
local GLOBAL_EVENTS = {
    PLAYER_LOGIN = true, PLAYER_TARGET_CHANGED = true, PLAYER_FOCUS_CHANGED = true,
    DISPLAY_SIZE_CHANGED = true, UI_SCALE_CHANGED = true, CVAR_UPDATE = true,
}
local live = {}
local driver = CreateFrame("Frame")
local pending, playerSweep, elapsed = 0, false, 0

local barMasks = setmetatable({}, { __mode = "k" })

-- A fixed full-bar mask clips rounded ends without inspecting the fill value.
function addon.StyleMask(bar, texture, cast)
    if not addon.Allowed(bar) or not addon.Allowed(texture) then return end
    local classic = addon.config.style == "classic"
    local state = barMasks[bar]
    if not state then
        if not classic then return end
        local mask = bar:CreateMaskTexture()
        mask:SetTexture(MEDIA .. (cast and "ClassicCastMask.tga" or "ClassicHealthMask.tga"), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(bar, true)
        state = { mask = mask, applied = setmetatable({}, { __mode = "k" }) }
        barMasks[bar] = state
    end
    if classic and not state.applied[texture] then
        texture:AddMaskTexture(state.mask)
        state.applied[texture] = true
    elseif not classic and state.applied[texture] then
        texture:RemoveMaskTexture(state.mask)
        state.applied[texture] = nil
    end
end

-- Keep Blizzard's registered fill texture; replacing it can leave its art visible.
local function StyleFill(bar, cast)
    local texture = bar.barTexture or bar:GetStatusBarTexture()
    if not texture then return end
    texture:SetAtlas(nil)
    texture:SetTexture(FILL)
    texture:SetTexCoord(0, 1, 0, 1)
    addon.StyleMask(bar, texture, cast)
end

local function Scale()
    local value = C_CVar.GetCVar("nameplateSize")
    if addon.Secret(value) then return 1 end
    local index = tonumber(value)
    local sizes = NamePlateConstants and NamePlateConstants.NAME_PLATE_SCALES_CLASSIC_STYLE
    local size = sizes and sizes[index]
    return size and size.horizontal or 1
end

local function Border(bar, cast)
    local texture = bar:CreateTexture(nil, "OVERLAY", nil, 2)
    texture:SetTexture(BorderPath())
    if cast then
        texture:SetTexCoord(0, 0.5, 0.5, 1)
        texture:SetSize(64, 16)
        addon.Point(texture, "TOPLEFT", bar, "TOPLEFT", -INSET_L, INSET_T)
        local right = bar:CreateTexture(nil, "OVERLAY", nil, 2)
        right:SetTexture(BorderPath())
        right:SetTexCoord(0.5, 0, 0.5, 1)
        right:SetSize(64, 16)
        addon.Point(right, "TOPRIGHT", bar, "TOPRIGHT", INSET_L, INSET_T)
        return texture, right
    else
        texture:SetTexCoord(0, 1, 0.5, 1)
        addon.Stretch(texture, bar, -INSET_L, INSET_T, INSET_R, -INSET_B)
    end
    return texture
end

local function Level(frame, own)
    local unit = addon.Unit(frame)
    if not unit then own.level:SetText("") own.skull:Hide() return end
    local value = UnitEffectiveLevel(unit)
    if addon.Secret(value) or value == nil then
        own.level:SetText("")
        own.skull:Hide()
    elseif value < 0 then
        own.level:SetText("")
        own.skull:Show()
    else
        own.skull:Hide()
        own.level:SetText(value)
    end
end

local function Layout(frame)
    if not addon.Allowed(frame) then return end
    local previous = addon.frames[frame]
    if previous then previous.layoutComplete = false end
    if not addon.Unit(frame) then return end
    local container, casts = frame.HealthBarsContainer, frame.CastBarsContainer
    local health = container and container.healthBar
    local cast = casts and casts.castBar
    if not addon.Allowed(container) or not addon.Allowed(casts) or
        not addon.Allowed(health) or not addon.Allowed(cast) then return end

    local own = addon.frames[frame]
    if not own then
        own = {}
        own.border = Border(health)
        own.castBorder, own.castBorderRight = Border(cast, true)
        own.level = health:CreateFontString(nil, "OVERLAY", "SystemFont_NamePlateLevel")
        own.level:SetDrawLayer("OVERLAY", 3)
        own.level:SetTextColor(1, 0.82, 0)
        own.level:SetShadowOffset(0, 0)
        addon.Point(own.level, "CENTER", own.border, "RIGHT", -11.5, 0)
        own.skull = health:CreateTexture(nil, "OVERLAY", nil, 3)
        own.skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
        own.skull:SetSize(12, 12)
        addon.Point(own.skull, "CENTER", own.border, "RIGHT", -11.5, 0)
        addon.frames[frame] = own
    end
    local borderPath = BorderPath()
    own.border:SetTexture(borderPath)
    own.castBorder:SetTexture(borderPath)
    own.castBorderRight:SetTexture(borderPath)
    local scale = Scale()
    casts:SetScale(scale)
    casts:SetSize(BAR_W, BAR_H)
    addon.Point(casts, "BOTTOM", frame, "BOTTOM", 0, INSET_B)
    container:SetScale(scale)
    container:SetSize(BAR_W, BAR_H)
    addon.Point(container, "BOTTOM", casts, "TOP", 0, INSET_T + 2 + INSET_B)
    health:SetScale(1)
    addon.Stretch(health, container)
    StyleFill(health)
    addon.Fade(health, HEALTH_ART)
    addon.HealthText(health)
    addon.Fade(frame, BADGES)
    addon.Point(own.level, "CENTER", own.border, "RIGHT", -11.5, 0)
    addon.Point(own.skull, "CENTER", own.border, "RIGHT", -11.5, 0)
    Level(frame, own)
    addon.Color(frame)

    if frame.name then
        local name = frame.name
        addon.Point(name, "BOTTOM", own.border, "TOP", 0, 2)
        name:SetWidth(0)
        name:SetJustifyH("CENTER")
        -- Whole font sizes avoid adding a fractional size to the client's scaling.
        name:SetFont(UNIT_NAME_FONT, math.floor(addon.config.nameSize * scale + 0.5), "OUTLINE")
        name:SetShadowOffset(0, 0)
        local debuffs = frame.AurasFrame and frame.AurasFrame.DebuffListFrame
        if addon.Allowed(debuffs) then
            debuffs:ClearAllPoints()
            debuffs:SetPoint("LEFT", own.border, "LEFT", 0, 0)
            debuffs:SetPoint("BOTTOM", name, "TOP", 0, 4)
        end
    end

    cast:SetScale(1)
    addon.Stretch(cast, casts, 0, 0, INSET_R - INSET_L, 0)
    StyleFill(cast, true)
    local channel = cast.channeling
    if not addon.Secret(channel) then
        if channel then cast:SetStatusBarColor(0, 1, 0)
        else cast:SetStatusBarColor(1, 0.7, 0) end
    end
    addon.Fade(cast, { "Background", "Border", "CastTargetNameText" })
    if cast.Icon then
        cast.Icon:SetSize(14, 14)
        addon.Point(cast.Icon, "RIGHT", own.castBorder, "LEFT", -1, 0)
    end
    if cast.Text then
        addon.Point(cast.Text, "CENTER", cast, "CENTER", 0, 0)
        cast.Text:SetJustifyH("CENTER")
    end
    addon.TintAuras(frame)
    own.layoutComplete = true
end

local function UpdateAll()
    playerSweep = false
    addon.EachPlate(function(frame)
        Layout(frame)
        local unit = addon.Unit(frame)
        if unit then
            live[unit] = frame
            local player = UnitIsPlayer(unit)
            if addon.Secret(player) or player then playerSweep = true end
        end
    end)
end

local function OnUpdate(self, delta)
    if pending > 0 then
        pending = pending - 1
        UpdateAll()
    end
    if playerSweep then
        elapsed = elapsed + delta
        if elapsed >= 0.2 then
            elapsed = 0
            playerSweep = false
            addon.EachPlate(function(frame)
                local unit = addon.Unit(frame)
                if unit then
                    local player = UnitIsPlayer(unit)
                    if addon.Secret(player) or player then
                        playerSweep = true
                        addon.Color(frame)
                    else addon.Unpaint(frame) addon.RestoreName(frame) end
                end
            end)
        end
    end
    if pending == 0 and not playerSweep then self:SetScript("OnUpdate", nil) end
end

-- Two coalesced passes cover client handlers that finish later in the first frame.
local function Queue()
    pending = 2
    driver:SetScript("OnUpdate", OnUpdate)
end

driver:SetScript("OnEvent", function(_, event, unit)
    if GLOBAL_EVENTS[event] then Queue() return end
    if addon.Secret(unit) or type(unit) ~= "string" or not unit:match("^nameplate%d+$") then return end
    if event == "NAME_PLATE_UNIT_REMOVED" then
        local frame = live[unit]
        if addon.Allowed(frame) then
            addon.Unpaint(frame)
            addon.RestoreName(frame)
            local own = addon.frames[frame]
            if own then own.layoutComplete = false end
        end
        live[unit] = nil
    end
    Queue()
end)
for _, event in ipairs(EVENTS) do driver:RegisterEvent(event) end


addon.RequestLayout = Queue
