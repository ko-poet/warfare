Flight = Flight or {}

Flight.Keys = {
    forward = false,
    back = false,
    left = false,
    right = false,
    up = false,
    down = false,
    fast = false,
    slow = false
}

Flight.active = false
Flight.speed = 10

function Flight.log(str)
    System.LogAlways(string.format("$5[Flight] " .. tostring(str)))
end

System.AddCCommand("flight_speed", "Flight.setSpeed(%line)", nil)

function Flight.setSpeed(line)
    local _speed = tonumber(line)

    if not _speed or _speed < 0 then
        Flight.log("Invalid speed value")
        return
    end

    Flight.speed = _speed
    Flight.log("Speed: " .. Flight.speed)
end


function Flight:Loop()
    if self.active then
        local basePos = player:GetPos()
        local dir = System.GetViewCameraDir()
        local move = {x = 0, y = 0, z = 0}
        local speed = self.speed * System.GetFrameTime() -- / System.GetCVar("t_scale") * System.GetFrameTime() scale by time

        if self.Keys.fast then
            speed = speed * 5
        elseif self.Keys.slow then
            speed = speed * 0.2
        end

        if self.Keys.forward then
            move = VectorUtils.Sum(move, VectorUtils.Scale(dir, speed))
        end

        if self.Keys.back then
            move = VectorUtils.Sum(move, VectorUtils.Scale(VectorUtils.Negate(dir), speed))
        end

        if self.Keys.left then
            move = VectorUtils.Sum(move, VectorUtils.Scale(VectorUtils.Negate(VectorUtils.Rotate90AroundZ(dir)), speed))
        end

        if self.Keys.right then
            move = VectorUtils.Sum(move, VectorUtils.Scale(VectorUtils.Rotate90AroundZ(dir), speed))
        end

        if self.Keys.up then
            local up = {x = 0, y = 0, z = 1}
            move = VectorUtils.Sum(move, VectorUtils.Scale(up, speed))
        end

        if self.Keys.down then
            local down = {x = 0, y = 0, z = -1}
            move = VectorUtils.Sum(move, VectorUtils.Scale(down, speed))
        end

        local finalPos = {x = basePos.x + move.x,
                        y = basePos.y + move.y,
                        z = basePos.z + move.z + 0.00001}

        player:SetPos(finalPos)
        Script.SetTimerForFunction(5, "Flight.Loop", self)
        return
    end

    Script.SetTimerForFunction(100, "Flight.Loop", self)
end

local _Player_OnAction = Player.OnAction

function Player:OnAction(action, activation, value)
    if action == "flight_toggle_keyboard" then
        Flight.active = not Flight.active

        if Flight.active then
            Flight.log("Flight On")
        else
            Flight.log("Flight Off")
        end

    elseif action == "flight_forward_keyboard" then
        if activation == "press" then
            Flight.Keys.forward = true
        else
            Flight.Keys.forward = false
        end

    elseif action == "flight_back_keyboard" then
        if activation == "press" then
            Flight.Keys.back = true
        else
            Flight.Keys.back = false
        end

    elseif action == "flight_left_keyboard" then
        if activation == "press" then
            Flight.Keys.left = true
        else
            Flight.Keys.left = false
        end

    elseif action == "flight_right_keyboard" then
        if activation == "press" then
            Flight.Keys.right = true
        else
            Flight.Keys.right = false
        end

    elseif action == "flight_up_keyboard" then
        if activation == "press" then
            Flight.Keys.up = true
        else
            Flight.Keys.up = false
        end

    elseif action == "flight_down_keyboard" then
        if activation == "press" then
            Flight.Keys.down = true
        else
            Flight.Keys.down = false
        end

    elseif action == "flight_fast_keyboard" then
        if activation == "press" then
            Flight.Keys.fast = true
        else
            Flight.Keys.fast = false
        end

    elseif action == "flight_slow_keyboard" then
        if activation == "press" then
            Flight.Keys.slow = true
        else
            Flight.Keys.slow = false
        end

    end
    if _Player_OnAction then
        return _Player_OnAction(self, action, activation, value)
    end
end

function Flight:OnGameplayStarted()
    if ActionMapManager then
        ActionMapManager.EnableActionMap("flight_action", true)
    else
        self.log("Failed to load keybinds")
    end

    self.active = false

    self.log("Ready")

    self:Loop()
end

UIAction.RegisterEventSystemListener(Flight, "", "OnGameplayStarted", "OnGameplayStarted")
