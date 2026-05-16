function Warfare.log(str)
    System.LogAlways(string.format("$5[Warfare] " .. tostring(str)))
end

function Warfare:brainLog(str)
    if self.brainDebug then
        System.LogAlways(string.format("$4[Brain] " .. tostring(str)))
    end
end

function Warfare.printMethods(object)
    if not object then
        return
    end

    Warfare.log("fields:")
    for key, value in pairs(object) do
        Warfare.log(key)
    end

    local mt = getmetatable(object)
    if mt then
        Warfare.log("metatable:")
        for key, value in pairs(mt) do
            Warfare.log(key)
        end

        if mt.__index and type(mt.__index) == "table" then
            Warfare.log("__index methods:")
            for key, value in pairs(mt.__index) do
                Warfare.log(key)
            end
        end
    end
end

function Warfare.copyTable(tbl)
    local out = {}
    for i = 1, #tbl do
        out[i] = tbl[i]
    end
    return out
end

function Warfare.indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

function Warfare.getRandomTableElement(tbl, bag)
    if not bag or #bag < 1 then
        bag = Warfare.copyTable(tbl)
    end

    local index = math.random(#bag)
    local result = bag[index]
    table.remove(bag, index)

    return result, bag
end

function Warfare.isAlive(ent)
    if not ent or not ent.actor or not ent.soul then return false end

    if ent.actor.IsDead and ent.actor:IsDead() then
        return false
    end
    if ent.actor:IsUnconscious() then
        return false
    end

    local ok, hp = pcall(function() return ent.soul:GetState('health') end)
    if not ok or hp == nil or hp <= 0 then return false end

    return true
end

function Warfare:isRanged(ent)
    local soldierType = self.getType(ent)

    if soldierType == "archers" or soldierType == "crossbowmen" or soldierType == "gunners" then
        return true
    end

    return false
end

function Warfare.getFaction(ent)
    return ent.Properties.WarfareProperties.faction
end

function Warfare.setFaction(ent, faction)
    ent.Properties.WarfareProperties.faction = faction
end

function Warfare.getType(ent)
    return ent.Properties.WarfareProperties.soldierType
end

function Warfare.setType(ent, soldierType)
    ent.Properties.WarfareProperties.soldierType = soldierType
end

function Warfare.getVisor(ent)
    return ent.Properties.WarfareProperties.visor
end

function Warfare.setVisor(ent, visor)
    ent.Properties.WarfareProperties.visor = visor
end

function Warfare.getDistanceToPlayer(entity)
    return VectorUtils.Distance(player:GetPos(), entity:GetPos())
end

function Warfare.getEntDistance(src, dst)
    return VectorUtils.Distance(src:GetPos(), dst:GetPos())
end

function Warfare.getGroundPos(pos)
    local from = {x = pos[1], y = pos[2], z = pos[3] + 10}

    local dir = {x = 0, y = 0, z = -1}
    dir = VectorUtils.Scale(dir, 20)

    local hitData = {}
    local hits = Physics.RayWorldIntersection(from, dir, 1, ent_terrain, nil, nil, hitData)

    if hitData[1].pos then
        return hitData[1].pos
    end
    return nil
end

function Warfare.getLookingAt(mask, maxDist)
    local from = System.GetViewCameraPos()
    local dir = System.GetViewCameraDir()

    dir = VectorUtils.Scale(dir, maxDist)

    local skip = player.id;

    local hitData = {}
    local hits = Physics.RayWorldIntersection(from, dir, 1, mask, skip, nil, hitData)
    return hitData[1]
end

function Warfare:getClosestTarget(entity, entList)
    local maxDist = 500
    local pos = entity:GetPos()
    local target = nil

    for _, ent in pairs(entList) do
        if (self.getFaction(ent) ~= self.getFaction(entity) and self.isAlive(ent)) then
            local dist = VectorUtils.Distance(ent:GetPos(), pos)

            if (dist < maxDist) then
                maxDist = dist
                target = ent
            end
        end
    end
    return target
end

function Warfare:getFormationPos(count, basePos, dir, rowSize)
    local rowSpace = 1.5
    local entSpace = self.Settings.entSpace
    local column = (count - 1) % rowSize
    local row = (count - 1 - column) / rowSize
    local len = math.sqrt(dir.x^2 + dir.y^2)

    local pos = {basePos.x - (entSpace * (rowSize / 2) - entSpace / 2) * (dir.x / len) + (column * entSpace) * (dir.x / len) + (row * rowSpace) * (-dir.y / len),
                basePos.y - (entSpace * (rowSize / 2) - entSpace / 2) * (dir.y / len) + (column * entSpace) * (dir.y / len) + (row * rowSpace) * (dir.x / len),
                basePos.z}

    local ground = self.getGroundPos(pos)
    if ground then
        pos = ground
    end

    return pos
end

function Warfare:setFactionTables(tbl)
    if tbl.coat == "Kuttenberg" then
        tbl.ClothingTable = self.Clothing.Kuttenberg
        tbl.WeaponsTable = self.Weapons.Kuttenberg

    elseif tbl.coat == "Semine" then
        tbl.ClothingTable = self.Clothing.Semine
        tbl.WeaponsTable = self.Weapons.Semine
    end
end
