function Warfare.spawnSoldier(name, soul, pos, soldierType, _faction)
    local wProperties = {
        faction = _faction,
        soldierType = soldierType,
        visor = false
    }
    return System.SpawnEntity({class = "NPC", position = pos, name = name, properties = {WarfareProperties = wProperties, guidSharedSoulId = soul}})
end

function Warfare.spawnHorse(name, soul, pos)         
    return System.SpawnEntity({class = "Horse", position = pos, name = name, properties = {guidSharedSoulId = soul}})
end

function Warfare:spawnUnit(soldierType, faction, numSpawns, rowSize)
    local basePos = self.getLookingAt(ent_terrain, 200).pos
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
        local soul
        local spawnPos = self:getFormationPos(i, basePos, dir, rowSize)

        while System.GetEntityByName(name .. string.format("%03d", spnmr)) ~= nil do
			spnmr = spnmr + 1
		end

		name = name .. string.format("%03d", spnmr)
		spnmr = spnmr + 1

        if soldierType == "peasants" then
            soul, self.Souls.Bags.Weak = self.getRandomTableElement(self.Souls.Weak, self.Souls.Bags.Weak)
        else
            soul, self.Souls.Bags.Elite = self.getRandomTableElement(self.Souls.Elite, self.Souls.Bags.Elite)
        end

        local spawnedEntity = self.spawnSoldier(name, soul, spawnPos, soldierType, faction)

        self:equipEntity(spawnedEntity, true)
        spawnedEntity:SetAngles({0, 0, ang - math.pi})

        table.insert(self.SpawnedEntities, spawnedEntity)

        spawned = spawned + 1
    end

    self.log("Spawned " .. spawned .. " Entities")
end

function Warfare:preview()
    local ok, err = pcall(function()
        if not self.Settings.Preview.active then
            while #self.PreviewEntities > 0 do
                local ent = self.PreviewEntities[#self.PreviewEntities]
                table.remove(self.PreviewEntities, #self.PreviewEntities)
                ent:DeleteThis()
            end
            return
        end

        local numSpawns = self.Settings.numSpawns
        local rowSize = self.Settings.rowSize
        local faction = self.Settings.faction
        local soldierType = self.Settings.soldierType

        local basePos = self.getLookingAt(ent_terrain, 200).pos
        local ang = System.GetViewCameraAngles().z / 180 * math.pi
        local playerDir = System.GetViewCameraDir()
        local dir = {x = playerDir.y, y = -playerDir.x}

        if numSpawns < rowSize then
            rowSize = numSpawns
        end

        while #self.PreviewEntities > numSpawns do
            local ent = self.PreviewEntities[#self.PreviewEntities]
            table.remove(self.PreviewEntities, #self.PreviewEntities)
            ent:DeleteThis()
        end

        if #self.PreviewEntities < numSpawns then
            local spnmr = 1

            for i = 1, numSpawns - #self.PreviewEntities do
                local spawnPos = self:getFormationPos(i, basePos, dir, rowSize)
                local soulTable = self.Souls.Elite
                local soul = soulTable[math.random(#soulTable)]
                local name = "PreviewEntity_"

                while System.GetEntityByName(name .. string.format("%03d", spnmr)) ~= nil do
                    spnmr = spnmr + 1
                end

                name = name .. string.format("%03d", spnmr)
                spnmr = spnmr + 1

                local spawnedEntity = self.spawnSoldier(name, soul, spawnPos, soldierType, faction)

                self:equipEntity(spawnedEntity, false)
                spawnedEntity:SetAngles({0, 0, ang - math.pi})

                table.insert(self.PreviewEntities, spawnedEntity)
            end
        end

        for i = 1, #self.PreviewEntities do  
            local ent = self.PreviewEntities[i]
            local pos = self:getFormationPos(i, basePos, dir, rowSize)

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

    end)

    Script.SetTimerForFunction(5, "Warfare.preview", self)
end

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
    for i, ent in ipairs(preset) do
        local name = "sim_" .. i
        local soul

        if ent.soldierType == "peasants" then
            soul, self.Souls.Bags.Weak = self.getRandomTableElement(self.Souls.Weak, self.Souls.Bags.Weak)
        else
            soul, self.Souls.Bags.Elite = self.getRandomTableElement(self.Souls.Elite, self.Souls.Bags.Elite)
        end

        local spawnedEntity = self.spawnSoldier(name, soul, ent.pos, ent.soldierType, ent.faction)

        self:equipEntity(spawnedEntity, true)
        spawnedEntity:SetAngles({0, 0, ent.ang})

        table.insert(entList, spawnedEntity)
    end
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
    local playerFound = false

    while #entList > 0 do
        local ent = entList[#entList]
        table.remove(entList)

        if (ent ~= player) then
            ent:DeleteThis()
            count = count + 1
        else
            playerFound = true
        end
    end
    if playerFound then
        table.insert(entList, player)
    end
    self.log("Despawned " .. count .. " Entities")
end
