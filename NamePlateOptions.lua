local _, addon = ...
local FILL = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"

function addon.RestoreName(frame)
    if not addon.Allowed(frame) then return end
    local own = addon.frames[frame]
    if own and own.nameColor and addon.Allowed(frame.name) then
        frame.name:SetTextColor(unpack(own.nameColor))
        own.nameColor = nil
    end
end

function addon.ColorName(frame, clientUpdated)
    if not addon.Allowed(frame) or not addon.Allowed(frame.name) then return end
    local own = addon.frames[frame]
    if not own then return end
    -- A native refresh has already restored the client's current reaction/class color.
    if clientUpdated then
        local shown = frame.name:IsShown()
        if addon.Secret(shown) or not shown then return end
        own.nameColor = nil
    end
    local unit = addon.Unit(frame)
    local player = unit and UnitIsPlayer(unit)
    local flagged
    if not addon.Secret(player) and player then flagged = UnitIsPVP(unit) end
    if addon.Secret(flagged) or not flagged then addon.RestoreName(frame) return end
    if not own.nameColor then
        local r, g, b, a = frame.name:GetTextColor()
        if addon.Secret(r) or addon.Secret(g) or addon.Secret(b) or addon.Secret(a) then return end
        if r == nil or g == nil or b == nil or a == nil then return end
        own.nameColor = { r, g, b, a }
    end
    frame.name:SetTextColor(0, 1, 0, own.nameColor[4])
end

-- Reapply only our name color after native updates; leave text/visibility client-owned.
hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
    addon.ColorName(frame, true)
end)

local function ClassColor(unit)
    local _, class = UnitClass(unit)
    if addon.Secret(class) or class == nil then return end
    local color = RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
end

local function WantedColor(unit)
    local player = UnitIsPlayer(unit)
    if addon.Secret(player) or not player then return end
    local dead = UnitIsDead(unit)
    if addon.Secret(dead) or dead then return end
    if addon.config.classColors then return ClassColor(unit) end
    local friendly = UnitIsFriend("player", unit)
    if addon.Secret(friendly) or not friendly then return end
    local attackable = UnitCanAttack("player", unit)
    if addon.Secret(attackable) then return end
    if attackable then
        if C_CVar.GetCVarBool("nameplateShowClassColor") then
            local r, g, b = ClassColor(unit)
            if r then return r, g, b end
        end
        return 1, 0, 0
    end
    local flagged = UnitIsPVP(unit)
    if addon.Secret(flagged) then return end
    if flagged then return 0, 1, 0 end
    return 0, 0, 1
end

function addon.Unpaint(frame)
    local own = addon.frames[frame]
    if own and own.fill then own.fill:Hide() end
end

function addon.Color(frame)
    addon.ColorName(frame)
    local own = addon.frames[frame]
    local health = frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar
    if not own or not health then return end
    local unit = addon.Unit(frame)
    local r, g, b
    if unit then r, g, b = WantedColor(unit) end
    if not r then addon.Unpaint(frame) return end
    local texture = health.barTexture or health:GetStatusBarTexture()
    if not texture then return end
    if not own.fill then
        own.fill = health:CreateTexture(nil, "ARTWORK", nil, 0)
        own.fill:SetTexture(FILL)
    end
    -- Follow the client's fill; do not read or recalculate health values.
    if own.fillTexture ~= texture then
        local layer, sub = texture:GetDrawLayer()
        if addon.Secret(layer) or addon.Secret(sub) then addon.Unpaint(frame) return end
        texture:SetDrawLayer(layer, math.max((sub or 0) - 1, -8))
        own.fill:SetDrawLayer(layer, sub or 0)
        addon.Stretch(own.fill, texture)
        own.fillTexture = texture
    end
    addon.StyleMask(health, own.fill, false)
    own.fill:SetVertexColor(r, g, b)
    own.fill:Show()
end
