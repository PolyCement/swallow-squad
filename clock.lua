-- the game clock
local font = love.graphics.newFont(32)

Clock = Object:extend()

function Clock:new(x, y)
    self.x = x
    self.y = y
    self.time = 0
end

function Clock:update(dt)
    self.time = self.time + dt
end

function Clock:draw()
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(font)
    love.graphics.print(self:getFormattedTime(), self.x, self.y)
    love.graphics.setColor(255, 255, 255, 255)
end

function Clock:getFormattedTime()
    local minutes = math.floor(self.time/60)
    local seconds = math.floor(math.fmod(self.time, 60))
    return string.format("Time: %02d:%02d", minutes, seconds)
end
