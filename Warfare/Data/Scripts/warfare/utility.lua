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

function Warfare.log(str)
    pcall(function() System.LogAlways(string.format("$5[Warfare] " .. tostring(str))) end)
end

--used in NPC AI
function Warfare.brainLog(ent, str)
    if Warfare.brainDebug then
        pcall(function() System.LogAlways(string.format("$6[" .. ent:GetName() .. "] " .. tostring(str))) end)
    end
end

function Warfare:setChatTarget(ent)
    self.chatTarget = ent
    self.chatUpdate = true
end


--use bags for souls + equipment to avoid duplicates and better balancing
function Warfare.getRandomTableElement(tbl, bag)
    if not bag or #bag < 1 then
        bag = Warfare.copyTable(tbl)
    end

    local index = math.random(#bag)
    local result = bag[index]
    table.remove(bag, index)

    return result, bag
end

function Warfare:getRandomSoul(soldierType)
    local soul = nil
    if soldierType == "peasants" then
        soul, self.Souls.Bags.Weak = self.getRandomTableElement(self.Souls.Weak, self.Souls.Bags.Weak)
    else
        soul, self.Souls.Bags.Elite = self.getRandomTableElement(self.Souls.Elite, self.Souls.Bags.Elite)
    end
    return soul
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
    local hits = pcall(function() Physics.RayWorldIntersection(from, dir, 1, Warfare.EntMask.terrain, nil, nil, hitData) end)

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
    local hits = pcall(function() Physics.RayWorldIntersection(from, dir, 1, mask, skip, nil, hitData) end)
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

function Warfare:getFormationPos(count, basePos, dir, rowSize, entSpace)
    local rowSpace = 1.5
    local entSpace = entSpace
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

function Warfare:getFreeUnit(faction)
    if not faction then return end

    self.BattleEntities[faction] = self.BattleEntities[faction] or {}
    local factionTbl = self.BattleEntities[faction]

    local unit = #factionTbl + 1
    factionTbl[unit] = {}
    return unit
end

function Warfare:giveCommand(cmd, ent)
    local faction = self.getFaction(ent)
    local unit = self.getUnit(ent)
    local targets = self.BattleEntities[faction][unit]

    if not targets then return end

    for i, ent in ipairs(targets) do
        self.setCommand(ent, cmd)
        self:markEnt(ent)
    end
end

function Warfare:markEnt(ent)
    --draw 3d or spawn something
end

function Warfare:addEntity(ent)
    local faction = self.getFaction(ent)
    local unit = self.getUnit(ent)

    if not faction then return end

    self.BattleEntities[faction] = self.BattleEntities[faction] or {}
    local f = self.BattleEntities[faction]

    if not unit then
        unit = #f + 1
        f[unit] = {}

        self.setUnit(ent, unit)
    else
       f[unit] = f[unit] or {}
    end

    table.insert(f[unit], ent)

end

--set faction clothing and weapon tables based on coat of arms
function Warfare:setFactionTables(tbl)
    if tbl.coat == "Kuttenberg" then
        tbl.ClothingTable = self.Clothing.Kuttenberg
        tbl.WeaponsTable = self.Weapons.Kuttenberg

    elseif tbl.coat == "Semine" then
        tbl.ClothingTable = self.Clothing.Semine
        tbl.WeaponsTable = self.Weapons.Semine
    end
end

function Warfare:addFaction(coat)
    table.insert(self.Factions, {coat = coat})
    Warfare:setFactionTables(self.Factions[#self.Factions])
end

function Warfare:addPlayerToBattle()
    Warfare.setFaction(player, 1)
    table.insert(self.BattleEntities[1][1], player)
end

function Warfare:removePlayerFromBattle()
    player.Properties.WarfareProperties = {}
    table.remove(self.SpawnedEntities, self.indexOf(self.SpawnedEntities, player))
end

function Warfare:loadEntities(saved)
    while #saved > 0 do
        local ent = saved[#saved]
        local faction = self.getFaction(ent)
        local unit = self.getUnit(ent)

        if ent and faction and unit then
            table.insert(self.BattleEntities[faction][unit], ent)
            Warfare:equipEntity(ent, true)
            table.remove(saved)
        end
    end
end

function Warfare.getFaction(ent)
    if not ent or not ent.Properties or not ent.Properties.WarfareProperties then return nil end
    return ent.Properties.WarfareProperties.faction
end

function Warfare.setFaction(ent, faction)
    if not ent then return end
    if not ent.Properties then ent.Properties = {} end
    if not ent.Properties.WarfareProperties then ent.Properties.WarfareProperties = {} end

    ent.Properties.WarfareProperties.faction = faction
end

function Warfare.getType(ent)
    if not ent or not ent.Properties or not ent.Properties.WarfareProperties then return nil end
    return ent.Properties.WarfareProperties.soldierType
end

function Warfare.setType(ent, soldierType)
    if not ent then return end
    if not ent.Properties then ent.Properties = {} end
    if not ent.Properties.WarfareProperties then ent.Properties.WarfareProperties = {} end

    ent.Properties.WarfareProperties.soldierType = soldierType
end

function Warfare.getVisor(ent)
    if not ent or not ent.Properties or not ent.Properties.WarfareProperties then return nil end
    return ent.Properties.WarfareProperties.visor
end

function Warfare.setVisor(ent, visor)
    if not ent then return end
    if not ent.Properties then ent.Properties = {} end
    if not ent.Properties.WarfareProperties then ent.Properties.WarfareProperties = {} end

    ent.Properties.WarfareProperties.visor = visor
end

function Warfare.getUnit(ent)
    if not ent or not ent.Properties or not ent.Properties.WarfareProperties then return nil end
    return ent.Properties.WarfareProperties.unit
end

function Warfare.setUnit(ent, unit)
    if not ent then return end
    if not ent.Properties then ent.Properties = {} end
    if not ent.Properties.WarfareProperties then ent.Properties.WarfareProperties = {} end

    ent.Properties.WarfareProperties.unit = unit
end

function Warfare.getCommand(ent)
    if not ent or not ent.Properties or not ent.Properties.WarfareProperties then return nil end
    return ent.Properties.WarfareProperties.command
end

function Warfare.setCommand(ent, cmd)
    if not ent then return end
    if not ent.Properties then ent.Properties = {} end
    if not ent.Properties.WarfareProperties then ent.Properties.WarfareProperties = {} end

    ent.Properties.WarfareProperties.command = cmd
end

function Warfare.getIsPreview(ent)
    if not ent or not ent.Properties or not ent.Properties.WarfareProperties then return nil end
    return ent.Properties.WarfareProperties.isPreview
end

function Warfare.setIsPreview(ent, isPreview)
    if not ent then return end
    if not ent.Properties then ent.Properties = {} end
    if not ent.Properties.WarfareProperties then ent.Properties.WarfareProperties = {} end

    ent.Properties.WarfareProperties.isPreview = isPreview
end