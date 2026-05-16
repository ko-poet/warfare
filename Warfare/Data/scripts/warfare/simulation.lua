Warfare.Simulation = {
    preset = {},
    speed = 30,
    iterations = 10,
    index = 1,
    score = {0, 0},
    abort = false
}

function Warfare:runSimulation()
    self.Simulation.preset = self:createPreset(self.SpawnedEntities)

    self:despawnAll(self.SpawnedEntities)
    self:runIteration()
end

function Warfare:stopSimulation()
    System.SetCVar("t_scale", 1)
    self.fight = false

    self:despawnAll(self.SpawnedEntities)
    self:spawnFromPreset(self.Simulation.preset, self.SpawnedEntities)

    self.log("Simulation done.")
    self.log("Iterations: " .. self.Simulation.index - 1)
    self.log("Score: " .. self.Factions[1].coat .. " " .. self.Simulation.score[1] .. ":" .. self.Simulation.score[2] .. " " .. self.Factions[2].coat)

    self.Simulation.index = 1
    self.Simulation.score = {0, 0}
    self.Simulation.abort = false
end

function Warfare:runIteration()
    self.log(1)
    System.SetCVar("t_scale", self.Simulation.speed)
    self.fight = false
    self:spawnFromPreset(self.Simulation.preset, self.SpawnedEntities)

    self.fight = true

    self:updateSimulation()
end

function Warfare:updateSimulation()
    if self.Simulation.abort then
        self:stopSimulation()
        return
    end

    local winner, survivors = self:getWinner()

    if winner then
        self:despawnAll(self.SpawnedEntities)
        self.Simulation.index = self.Simulation.index + 1

        if winner ~= 0 then
            self.Simulation.score[winner] = self.Simulation.score[winner] + 1
        end

        if self.Simulation.index <= self.Simulation.iterations then
            self:runIteration()
        else
            self:stopSimulation()
        end

        return
    end

    Script.SetTimerForFunction(100, "Warfare.updateSimulation", self)
end

function Warfare:getWinner()
    local numAlive = {0, 0}
    for i, ent in ipairs(Warfare.SpawnedEntities) do
        if self.isAlive(ent) then
            local faction = self.getFaction(ent)
            numAlive[faction] = numAlive[faction] + 1
        end
    end

    if numAlive[1] == 0 then
        return 2, numAlive[2]
    elseif numAlive[2] == 0 then
        return 1, numAlive[1]
    elseif numAlive[1] == 0 and numAlive[2] == 0 then
        return 0, 0
    end

    return nil
end