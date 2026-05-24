function Warfare.spawnSoldier(name, soul, pos, _isPreview, _soldierType, _faction, _unit)
    local wProperties = {
        isPreview = _isPreview,
        soldierType = _soldierType,
        faction = _faction,
        unit = _unit,
        command = "attack",
        visor = false
    }
    return System.SpawnEntity({class = "NPC", position = pos, name = name, properties = {WarfareProperties = wProperties, guidSharedSoulId = soul}})
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

    local unit = self:getFreeUnit(faction)

    for i = 1, numSpawns do
        local name = "wBattleEntity_"
        local soul = self.getRandomSoul(soldierType)
        local spawnPos = self:getFormationPos(i, basePos, dir, rowSize, entSpace)

        while System.GetEntityByName(name .. string.format("%03d", spnmr)) ~= nil do
			spnmr = spnmr + 1
		end

		name = name .. string.format("%03d", spnmr)
		spnmr = spnmr + 1

        local spawnedEntity = self.spawnSoldier(name, soul, spawnPos, false, soldierType, faction, unit)

        self:equipEntity(spawnedEntity, true)
        spawnedEntity:SetAngles({0, 0, ang - math.pi})

        --player can't chat with enemy soldiers
        if faction ~= 1 then
            spawnedEntity.soul:RemoveMetaRoleByName("NPC")
        end

        Warfare:addEntity(spawnedEntity)
       -- table.insert(self.SpawnedEntities, spawnedEntity)

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
            local name = "wPreviewEntity_"

            while System.GetEntityByName(name .. string.format("%03d", spnmr)) ~= nil do
                spnmr = spnmr + 1
            end

            name = name .. string.format("%03d", spnmr)
            spnmr = spnmr + 1

            local spawnedEntity = self.spawnSoldier(name, soul, spawnPos, true, soldierType, faction, 0)

            self:equipEntity(spawnedEntity, false)
            spawnedEntity:SetAngles({0, 0, ang - math.pi})
            spawnedEntity.soul:RemoveMetaRoleByName("NPC")

            table.insert(self.PreviewEntities, spawnedEntity)
        end
    end

    for i, ent in ipairs(self.PreviewEntities) do
        local ent = ent
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

    Script.SetTimerForFunction(5, "Warfare.spawnPreview", self)
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
    if (not ent or ent == player) then
        return
    end

    if entList then
        table.remove(entList, self.indexOf(entList, ent))
    end

    ent:DeleteThis()
end

function Warfare:despawnAll(entList)
    local count = 0
    local playerFound = false

    if not entList then
        return
    end

    while #entList > 0 do
        local ent = entList[#entList]
        table.remove(entList)

        if (ent ~= player) then
            if ent then
                ent:DeleteThis()
                count = count + 1
            end
        else
            playerFound = true
        end
    end
    if playerFound then
        table.insert(entList, player)
    end
    --self.log("Despawned " .. count .. " Entities")
end

