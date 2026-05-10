function Warfare:spawnSoldier(name, soul, pos, faction)         
    return System.SpawnEntity({class = "NPC", position = pos, name = name, properties = {warfare_faction = faction, warfare_type = Warfare.Settings.type, guidSharedSoulId = soul}})
end

function Warfare:spawnHorse(name, soul, pos, faction)         
    return System.SpawnEntity({class = "Horse", position = pos, name = name, properties = {warfare_faction = faction, guidSharedSoulId = soul}})
end

function Warfare:equipEntity(ent, faction)
    local clothing
    local weaponsTable = Warfare.Weapons.General.Pitchfork

    ent.inventory:RemoveAllItems()

    if Warfare.Settings.type == "infantry" then
        clothing, Warfare.Clothing.Bag = Warfare.getRandomTableElement(Warfare.Factions[faction].ClothingTable.Heavy, Warfare.Clothing.Bag)
        weaponsTable = Warfare.Factions[faction].WeaponsTable.Infantry
    elseif Warfare.Settings.type == "spearmen" then
        clothing, Warfare.Clothing.Bag = Warfare.getRandomTableElement(Warfare.Factions[faction].ClothingTable.Heavy, Warfare.Clothing.Bag)
        weaponsTable = Warfare.Weapons.General.Polearm
    elseif Warfare.Settings.type == "archers"then
        clothing, Warfare.Clothing.Bag = Warfare.getRandomTableElement(Warfare.Factions[faction].ClothingTable.Light, Warfare.Clothing.Bag)
        weaponsTable = Warfare.Weapons.General.Bow
    elseif Warfare.Settings.type == "crossbowmen" then
        clothing, Warfare.Clothing.Bag = Warfare.getRandomTableElement(Warfare.Factions[faction].ClothingTable.Light, Warfare.Clothing.Bag)
        weaponsTable = Warfare.Weapons.General.Crossbow
    elseif Warfare.Settings.type == "gunners" then
        clothing, Warfare.Clothing.Bag = Warfare.getRandomTableElement(Warfare.Factions[faction].ClothingTable.Light, Warfare.Clothing.Bag)
        weaponsTable = Warfare.Weapons.General.Gun
    elseif Warfare.Settings.type == "peasants" then
        clothing, Warfare.Clothing.Bag = Warfare.getRandomTableElement(Warfare.Clothing.Peasant, Warfare.Clothing.Bag)
        weaponsTable = Warfare.Weapons.General.Pitchfork
    end

    ent.actor:EquipClothingPreset(clothing)
    ent.actor:EquipWeaponPreset(weaponsTable[math.random(#weaponsTable)])

    if Warfare.Settings.type == "spearmen" or Warfare.Settings.type == "peasants"then
        ent.human:ToggleWeaponSet(2)
    else
        ent.human:ToggleWeaponSet(1)
    end
    ent.human:DrawWeapon()
end


function Warfare:spawn(faction, numSpawns, rowSize)
    local basePos = Warfare:getLookingAt().pos
    
    if (rowSize > numSpawns) then
        rowSize = numSpawns
    end

    local spnmr = 1

    local rowSize = Warfare.Settings.rowSize
    local ang = player:GetAngles().z
    local playerDir = player:GetDirectionVector()
    local dir = {x = playerDir.y, y = -playerDir.x}
    local spawned = 0

    if numSpawns < rowSize then
            rowSize = numSpawns
    end

    for i = 1, numSpawns do
        local name = "SpawnedEntity_"

        local spawnPos = Warfare:getFormationPos(i, basePos, dir, rowSize)


        while System.GetEntityByName(name .. string.format("%03d", spnmr)) ~= nil do
			spnmr = spnmr + 1
		end

		name = name .. string.format("%03d", spnmr)
		spnmr = spnmr + 1

        local soul

        if Warfare.Settings.type == "peasants" then
            soul, Warfare.Souls.Bags.Weak = Warfare.getRandomTableElement(Warfare.Souls.Weak, Warfare.Souls.Bags.Weak)
        else
            soul, Warfare.Souls.Bags.Elite = Warfare.getRandomTableElement(Warfare.Souls.Elite, Warfare.Souls.Bags.Elite)
        end

        local spawnedEntity = Warfare:spawnSoldier(name, soul, spawnPos, faction)
        --Warfare:log(spawnedEntity.Properties.warfare_faction)

        if Warfare.Settings.type == "cavalry" then
            local spawnedHorse = Warfare:spawnHorse("test_horse", "fc0e6251-b314-4398-b83f-3a66a52961ee", spawnPos, faction)
            spawnedEntity.human:DoBonding(spawnedHorse.id)
            spawnedEntity.human:Mount(spawnedHorse.id)
        end

        Warfare:equipEntity(spawnedEntity, faction)
        spawnedEntity:SetAngles({0, 0, ang - 3.14})

        table.insert(Warfare.SpawnedEntities, spawnedEntity)

        spawned = spawned + 1
    end

    Warfare:log("Spawned " .. spawned .. " Entities")
end


function Warfare.preview()
    local ok, err = pcall(function()

        if not Warfare.Settings.inPreview then
            while #Warfare.PreviewEntities > 0 do
                local ent = Warfare.PreviewEntities[#Warfare.PreviewEntities]
                table.remove(Warfare.PreviewEntities, #Warfare.PreviewEntities)
                ent:DeleteThis()
            end
            return
        end

        local numSpawns = Warfare.Settings.numSpawns
        local rowSize = Warfare.Settings.rowSize

        local basePos = Warfare:getLookingAt().pos
        local ang = player:GetAngles().z
        local playerDir = player:GetDirectionVector()
        local dir = {x = playerDir.y, y = -playerDir.x}

        if numSpawns < rowSize then
            rowSize = numSpawns
        end

        while #Warfare.PreviewEntities > numSpawns do
            local ent = Warfare.PreviewEntities[#Warfare.PreviewEntities]
            table.remove(Warfare.PreviewEntities, #Warfare.PreviewEntities)
            ent:DeleteThis()
        end

        if #Warfare.PreviewEntities < numSpawns then
            local spnmr = 1

            for i = 1, numSpawns - #Warfare.PreviewEntities do
                local spawnPos = Warfare:getFormationPos(i, basePos, dir, rowSize)
                local name = "PreviewEntity_"

                while System.GetEntityByName(name .. string.format("%03d", spnmr)) ~= nil do
                    spnmr = spnmr + 1
                end

                name = name .. string.format("%03d", spnmr)
                spnmr = spnmr + 1

                local soul
                local soulTable = Warfare.Souls.Elite

                soul = soulTable[math.random(#soulTable)]
                local spawnedEntity = Warfare:spawnSoldier(name, soul, spawnPos, Warfare.Settings.faction)

                Warfare:equipEntity(spawnedEntity, Warfare.Settings.faction)

                spawnedEntity:SetAngles({0, 0, ang - 3.14})
                    
                table.insert(Warfare.PreviewEntities, spawnedEntity)

            end
        end 

        for i = 1, #Warfare.PreviewEntities do
            local ent = Warfare.PreviewEntities[i]
            local pos = Warfare:getFormationPos(i, basePos, dir, rowSize)

            ent:SetPos(pos)
            ent:SetAngles({0, 0, ang - 3.14})

            if Warfare.Settings.Preview.reload then
                ent.Properties.warfare_faction = Warfare.Settings.faction
                Warfare:equipEntity(ent, Warfare.Settings.faction)
            end
        end

        if Warfare.Settings.Preview.reload then
            Warfare.Settings.Preview.reload = false
        end

    end)

    Script.SetTimerForFunction(5, "Warfare.preview")
end

