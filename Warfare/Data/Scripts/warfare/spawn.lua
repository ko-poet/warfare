function Warfare.spawnSoldier(name, soul, pos, _isPreview, _soldierType, _faction)
    local wProperties = {
        isPreview = _isPreview,
        faction = _faction,
        soldierType = _soldierType,
        visor = false
    }
    return System.SpawnEntity({class = "NPC", position = pos, name = name, properties = {WarfareProperties = wProperties, guidSharedSoulId = soul}})
end

function Warfare.spawnEnt(model)
    --"Objects/manmade/common_furniture/barrels/barrel_a.cgf"
    return System.SpawnEntity({class = "BasicEntity", position = player:GetPos(), name = "test", properties = {bSerialize = 1, object_Model = model}})
end

function Warfare:spawnUnit(soldierType, faction, numSpawns, rowSize, entSpace)
    local basePos = self.getLookingAt(self.EntMask.terrain, 200).pos
    local ang = player:GetAngles().z
    local playerDir = player:GetDirectionVector()
    local dir = {x = playerDir.y, y = -playerDir.x}

    local spnmr = 1
    local spawned = 0

    if (rowSize > numSpawns) then
        rowSize = numSpawns
    end

    if numSpawns < rowSize then
        rowSize = numSpawns
    end

    for i = 1, numSpawns do
        local name = "SpawnedEntity_"
        local soul = self:getRandomSoul(soldierType)
        local spawnPos = self:getFormationPos(i, basePos, dir, rowSize, entSpace)

        while System.GetEntityByName(name .. string.format("%03d", spnmr)) ~= nil do
			spnmr = spnmr + 1
		end

		name = name .. string.format("%03d", spnmr)
		spnmr = spnmr + 1

        local spawnedEntity = self.spawnSoldier(name, soul, spawnPos, false, soldierType, faction)

        self:equipEntity(spawnedEntity, true)
        spawnedEntity:SetAngles({0, 0, ang - math.pi})

        table.insert(self.SpawnedEntities, spawnedEntity)

        --Warfare:activateBrain(spawnedEntity)

        spawned = spawned + 1
    end
    --self.log("Spawned " .. spawned .. " Entities")
end

function Warfare:spawnPreview()
    if not self.Settings.Preview.active then
        self:despawnAll(self.PreviewEntities)
        return
    end

    local numSpawns = self.Settings.numSpawns
    local rowSize = self.Settings.rowSize
    local entSpace = self.Settings.entSpace
    local faction = self.Settings.faction
    local soldierType = self.Settings.soldierType

    local basePos = self.getLookingAt(self.EntMask.terrain, 200).pos
    local ang = System.GetViewCameraAngles().z / 180 * math.pi
    local playerDir = System.GetViewCameraDir()
    local dir = {x = playerDir.y, y = -playerDir.x}

    if numSpawns < rowSize then
        rowSize = numSpawns
    end

    while #self.PreviewEntities > numSpawns do
        local ent = self.PreviewEntities[#self.PreviewEntities]
        self:despawn(ent, self.PreviewEntities)
    end

    if #self.PreviewEntities < numSpawns then
        local spnmr = 1

        for i = 1, numSpawns - #self.PreviewEntities do
            local spawnPos = self:getFormationPos(i, basePos, dir, rowSize, entSpace)
            local soul = self:getRandomSoul(soldierType)
            local name = "PreviewEntity_"

            while System.GetEntityByName(name .. string.format("%03d", spnmr)) ~= nil do
                spnmr = spnmr + 1
            end

            name = name .. string.format("%03d", spnmr)
            spnmr = spnmr + 1

            local spawnedEntity = self.spawnSoldier(name, soul, spawnPos, true, soldierType, faction)

            self:equipEntity(spawnedEntity, false)
            spawnedEntity:SetAngles({0, 0, ang - math.pi})

            table.insert(self.PreviewEntities, spawnedEntity)
        end
    end

    for i, ent in ipairs(self.PreviewEntities) do
        local ent = self.PreviewEntities[i]
        local pos = self:getFormationPos(i, basePos, dir, rowSize, entSpace)

        ent:SetPos(pos)
        ent:SetAngles({0, 0, ang - math.pi})

        if self.Settings.Preview.reload then
            self.setFaction(ent, faction)
            self.setType(ent, soldierType)
            self:equipEntity(ent, false)
        end
    end

    if self.Settings.Preview.reload then
        self.Settings.Preview.reload = false
    end

    Script.SetTimerForFunction(1, "Warfare.spawnPreview", self)
end

--create spawning preset from entity list
function Warfare:createPreset(entList)
    local result = {}
    for i, ent in ipairs(entList) do
        local entry = {
            pos = ent:GetPos(),
            ang = ent:GetAngles().z,
            soldierType = self.getType(ent),
            faction = self.getFaction(ent)
        }

        table.insert(result, entry)
    end
    return result
end

function Warfare:spawnFromPreset(preset, entList)
    local count = 0
    for i, ent in ipairs(preset) do
        local name = "sim_" .. i
        local soul

        if ent.soldierType == "peasants" then
            soul, self.Souls.Bags.Weak = self.getRandomTableElement(self.Souls.Weak, self.Souls.Bags.Weak)
        else
            soul, self.Souls.Bags.Elite = self.getRandomTableElement(self.Souls.Elite, self.Souls.Bags.Elite)
        end

        local spawnedEntity = self.spawnSoldier(name, soul, ent.pos, false, ent.soldierType, ent.faction)

        self:equipEntity(spawnedEntity, true)
        spawnedEntity:SetAngles({0, 0, ent.ang})

        table.insert(entList, spawnedEntity)
        count = count + 1
    end

    self.log("Spawned " .. count .. " Entities")
end

function Warfare:despawn(ent, entList)
    if (ent == player) then
        return
    end

    if entList then
        table.remove(entList, self.indexOf(entList, ent))
    end

    ent:DeleteThis()
end

function Warfare:despawnAll(entList)
    local count = 0

    while #entList > 0 do
        local ent = entList[#entList]

        if (ent ~= player) then
            table.remove(entList)
            if ent then
                ent:DeleteThis()
                count = count + 1
            end
        end
    end
    --self.log("Despawned " .. count .. " Entities")
end

