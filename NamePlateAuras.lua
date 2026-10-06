local _, addon = ...
local ATLAS = "UI-HUD-CoolDownManager-IconOverlay"
local LISTS = { "DebuffListFrame", "BuffListFrame", "CrowdControlListFrame" }

local function TintItem(item)
    if not addon.Allowed(item) then return end
    for _, region in ipairs({ item:GetRegions() }) do
        if region.GetAtlas then
            local atlas = region:GetAtlas()
            if not addon.Secret(atlas) and atlas == ATLAS then
                region:SetVertexColor(0.8, 0.6, 0.35)
            end
        end
    end
end

function addon.TintAuras(frame)
    local auras = frame.AurasFrame
    if not addon.Allowed(auras) then return end
    for _, key in ipairs(LISTS) do
        local list = auras[key]
        if addon.Allowed(list) then
            for _, item in ipairs({ list:GetChildren() }) do TintItem(item) end
        end
    end
end
