WDebug = WDebug or {}

--get rid of annoying syntax errors
if false then
    Script = {}
    System = {}
    XGenAIModule = {}
    ActionMapManager = {}
    Physics = {}
    VectorUtils = {}
    UIAction = {}
    NPC = {}
    Player = {}
    player = {}
end

function WDebug.log(str)
    System.LogAlways(string.format("$4[Debug] " .. tostring(str)))
end

function WDebug.searchGlobals(str)
    for k, v in pairs(_G) do
        local s = tostring(k):lower()
        if s:find(str) then
            System.LogAlways(tostring(k) .. " = " .. tostring(v))
        end
    end
end

function WDebug.searchValues(str)
    for k, v in pairs(_G) do
        local s = tostring(v):lower()
        if s:find(str) then
            System.LogAlways(tostring(k) .. " = " .. tostring(v))
        end
    end
end
--#WDebug.dump(System.GetEntityByName("SpawnedEntity_001"))
function WDebug.dumpRecursive(object, index)
    if not object then
        return
    end

    local prefix = ""
    local vars = {}
    local tables = {}
    local functions = {}

    for i = 1, index do
        prefix = prefix .. "    "
    end

    for key, value in pairs(object) do
        if type(value) == "table" then
            table.insert(tables, {key, value})
        elseif type(value) == "function" then
            table.insert(functions, {key, value})
        else
            table.insert(vars, {key, value})
        end
    end

    for i, value in ipairs(vars) do
        System.LogAlways(prefix .. tostring(value[1]) ..  " = " .. tostring(value[2]))
    end

    for i, value in ipairs(functions) do
        System.LogAlways(prefix .. tostring(value[1]) .. "()")
    end

    for i, value in ipairs(tables) do
        System.LogAlways(prefix .. tostring(value[1]) .. ":")
        WDebug.dumpRecursive(value[2], index + 1)
    end
end

function WDebug.dump(object)
    WDebug.dumpRecursive(object, 0)
end

function WDebug.viewportToScreen(vec)
    local screenSize = {x = 1920, y = 1080}

    if vec.x < 0 or vec.x > 800 or vec.y < 0 or vec.y > 600 then
        return {x = 0, y = 0}
    end

    return {x = screenSize.x / 800 * vec.x, y = screenSize.y / 600 * vec.y}
end

function WDebug.IsInFrontOfCamera(targetPos)
    local camPos = System.GetViewCameraPos()
    local camForward = System.GetViewCameraDir()
    local toTarget = VectorUtils.Normalize(VectorUtils.Subtract(targetPos, camPos))
    return VectorUtils.DotProduct(toTarget, camForward) > 0
end

--Draw2DLine() doesnt work, manual way with text
function WDebug.drawLine(src, dest, size, step) 
    local font = 1
    local symbol = "˙"
    step = step or 1
    size = size or 1

    local dx = dest.x - src.x
    local dy = dest.y - src.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist == 0 then
        System.DrawText(src.x, src.y, symbol, size, 1, 1, 1)
        return
    end

    local nx = dx / dist
    local ny = dy / dist

    local x = src.x
    local y = src.y
    local travelled = 0

    while travelled <= dist do
        System.DrawText(x, y, symbol, size, 1, 1, 1)
        x = x + nx * step
        y = y + ny * step
        travelled = travelled + step
    end

    System.DrawText(dest.x, dest.y, symbol, size, 1, 1, 1)
end

function WDebug:draw2DBox(ent)
    local boxWidth = 10
    local headHeight = 1.6

    local pos = ent:GetWorldPos()
    local basePos = System.ProjectToScreen(pos)
    local base = self.viewportToScreen(basePos)

    local head = self.viewportToScreen(System.ProjectToScreen({pos.x, pos.y, pos.z + headHeight}))
    local sizeMult = math.abs(base.y - head.y) / 50
    boxWidth = boxWidth * sizeMult

    local p1 = {x = base.x - boxWidth, y = base.y}
    local p2 = {x = base.x + boxWidth, y = base.y}
    local p3 = {x = base.x - boxWidth, y = head.y}
    local p4 = {x = base.x + boxWidth, y = head.y}

    if (not self.IsInFrontOfCamera(pos)) then
        return
    end

    if (p1.x > 0 and p2.x > 0 and p3.x > 0 and p4.x > 0 and p1.x < 1920 and p2.x < 1920 and p3.x < 1920 and p4.x < 1920
        and p1.y > 0 and p2.y > 0 and p3.y > 0 and p4.y > 0 and p1.y < 1080 and p2.y < 1080 and p3.y < 1080 and p4.y < 1080) then
        self:drawLine(p1, p2)
        self:drawLine(p1, p3)
        self:drawLine(p2, p4)
        self:drawLine(p3, p4)
    end
end

function WDebug:drawEntText(ent)
    local pos = ent:GetWorldPos()
    local basePos = System.ProjectToScreen({pos.x, pos.y, pos.z + 1})
    local base = self.viewportToScreen(basePos)

    if (not self.IsInFrontOfCamera(pos)) then
        return
    end

    System.DrawText(base.x, base.y, ent:GetName(), 1.5, 1, 1, 1)
    System.DrawText(base.x, base.y + 5, ent.class, 1.5, 1, 1, 1)
end


function WDebug:debugDraw()
    local entities = System.GetEntities(player:GetPos(), 30)
    for i, ent in pairs(entities)
    do
        self:drawEntText(ent)
        if ent.class == "NPC" or ent.class == "NPC_Female" then

        end
    end

    Script.SetTimerForFunction(10, "WDebug.test", self)

end