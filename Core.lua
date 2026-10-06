local _, addon = ...

-- Private addon configuration and shared helpers.
addon.version = "0.3.1"
addon.config = { classColors = false, nameSize = 11, healthSize = 9, style = "compact" }
addon.frames = setmetatable({}, { __mode = "k" })

function addon.Secret(value)
    return issecretvalue(value)
end

function addon.Allowed(frame)
    return frame and not frame:IsForbidden()
end

function addon.Point(region, point, relative, relativePoint, x, y)
    region:ClearAllPoints()
    region:SetPoint(point, relative, relativePoint, x or 0, y or 0)
end

function addon.Stretch(region, relative, left, top, right, bottom)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", relative, "TOPLEFT", left or 0, top or 0)
    region:SetPoint("BOTTOMRIGHT", relative, "BOTTOMRIGHT", right or 0, bottom or 0)
end

function addon.Fade(frame, keys)
    for _, key in ipairs(keys) do
        local region = frame[key]
        if region then region:SetAlpha(0) end
    end
end

function addon.EachPlate(callback)
    for _, plate in pairs(C_NamePlate.GetNamePlates()) do
        if addon.Allowed(plate) then
            local frame = plate.UnitFrame
            if addon.Allowed(frame) then callback(frame) end
        end
    end
end

function addon.Unit(frame)
    local unit = frame.unit
    if addon.Secret(unit) or type(unit) ~= "string" then return end
    if unit:match("^nameplate%d+$") then return unit end
end
