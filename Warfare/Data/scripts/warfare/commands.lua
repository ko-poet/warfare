function Warfare:createCommand(cmdName, cmdFunc)
    System.AddCCommand(cmdName, cmdFunc, nil)
end


Warfare:createCommand("fight", "Warfare:startBattle()")
Warfare:createCommand("stop", "Warfare:endBattle()")

Warfare:createCommand("reset", "Warfare:reset()")

function Warfare:reset()
    local count = 0
    local playerFound = false

    --table.remove(Warfare.SpawnedEntities, Warfare:indexOf(Warfare.SpawnedEntities, player))

    while #Warfare.SpawnedEntities > 0 do
        local ent = Warfare.SpawnedEntities[#Warfare.SpawnedEntities]
        table.remove(Warfare.SpawnedEntities)

        if (ent ~= player) then
            ent:DeleteThis()
        else
            playerFound = true
            count = count - 1
        end
        count = count + 1
    end
    if playerFound then
        table.insert(Warfare.SpawnedEntities, player)
    end
    Warfare:log("Despawned " .. count .. " Entities")
end

function Warfare:startBattle()
    _G.fight = true
end

function Warfare:endBattle()
    _G.fight = false
end