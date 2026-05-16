function Warfare:createCommand(cmdName, cmdFunc)
    System.AddCCommand(cmdName, cmdFunc, nil)
end

Warfare:createCommand("reset", "Warfare:despawnAll(Warfare.SpawnedEntities)")


Warfare:createCommand("fight", "Warfare:startBattle()")
function Warfare:startBattle()
    Warfare.fight = true
end

Warfare:createCommand("stop", "Warfare:endBattle()")
function Warfare:endBattle()
    Warfare.fight = false
end


Warfare:createCommand("sim_start", "Warfare:runSimulation()")

Warfare:createCommand("sim_stop", "Warfare:abortSimulation()")
function Warfare:abortSimulation()
    self.Simulation.abort = true
end

System.AddCCommand("sim_speed", "Warfare:setSimSpeed(%line)", nil)
function Warfare:setSimSpeed(line)
    local _speed = tonumber(line)

    if not _speed or _speed < 0 then
        self.log("Invalid speed value")
        return
    end

    self.Simulation.speed = _speed
    self.log("Simulation Speed: " .. self.Simulation.speed)
end

System.AddCCommand("sim_iterations", "Warfare:setSimIterations(%line)", nil)
function Warfare:setSimIterations(line)
    local _iterations = tonumber(line)

    if not _iterations or _iterations < 1 then
        self.log("Invalid iteraions")
        return
    end

    self.Simulation.iterations = _iterations
    self.log("Simulation Iterations: " .. self.Simulation.iterations)
end


Warfare:createCommand("brain_debug", "Warfare:setBrainDebug()")
function Warfare:setBrainDebug()
    self.brainDebug = not self.brainDebug
end