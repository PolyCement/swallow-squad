Object = require "lib.classic"

-- the game clock
local font = love.graphics.newFont(28)

Clock = Object:extend()

function Clock:new()
    self.time = 0
end

function Clock:update(dt)
    self.time = self.time + dt
end

function Clock:draw(x, y)
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(font)
    love.graphics.print("Time: " .. self:getFormattedTime(), x, y)
    love.graphics.setColor(255, 255, 255, 255)
end

function Clock:getFormattedTime()
    local minutes = math.floor(self.time/60)
    local seconds = math.floor(math.fmod(self.time, 60))
    return string.format("%02d:%02d", minutes, seconds)
end
