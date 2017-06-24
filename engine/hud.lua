local Object = require "lib.classic"

-- a simple clock
local Clock = Object:extend()

function Clock:new()
    self.time = 0
end

function Clock:update(dt)
    self.time = self.time + dt
end

function Clock:getFormattedTime()
    local minutes = math.floor(self.time/60)
    local seconds = math.floor(math.fmod(self.time, 60))
    return string.format("%02d:%02d", minutes, seconds)
end

-- the hud
local Hud = Object:extend()

function Hud:new(num_prey)
    -- the clock
    self.clock = Clock()
    -- prey tracking
    self.maxPrey = num_prey
    self.preyCollected = 0
    -- icons
    self.clockIcon = love.graphics.newImage("assets/images/hud_clock.png")
    self.preyIcon = love.graphics.newImage("assets/images/hud_prey.png")
    -- positions
    self.clockPosX = 20
    self.clockPosY = love.graphics.getHeight() - 90
    self.clockTextPosX = self.clockPosX + self.clockIcon:getWidth() + 10
    self.preyPosX = 50
    self.preyPosY = love.graphics.getHeight() - 50
    self.preyTextPosX = self.preyPosX + self.preyIcon:getWidth() + 10
end

-- update clock and remaining prey count
function Hud:update(dt, num_prey)
    self.clock:update(dt)
    self.preyCollected = self.maxPrey - num_prey
end

-- draws the hud
local font = love.graphics.newFont("assets/fonts/StarPerv.ttf", 24)
function Hud:draw()
    -- draw icons
    love.graphics.draw(self.clockIcon, self.clockPosX, self.clockPosY)
    love.graphics.draw(self.preyIcon, self.preyPosX, self.preyPosY)
    -- set up for drawing text
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(font)
    -- draw the clock
    love.graphics.print(self.clock:getFormattedTime(), self.clockTextPosX, love.graphics.getHeight() - 85)
    -- draw the number of remaining prey
    love.graphics.print(self.preyCollected .. "/" .. self.maxPrey,
                        self.preyTextPosX, love.graphics.getHeight() - 45)
    love.graphics.setColor(255, 255, 255, 255)
end

-- prints the message when the game ends
local font_big = love.graphics.newFont(32)
function Hud:drawEndMessage()
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(font_big)
    local message = "Congratulations!\nYou saved everyone!\n\nTime: " .. self.clock:getFormattedTime()
    -- centre the message
    local text_width = font:getWidth(message)
    local x = (love.graphics.getWidth() - text_width) / 2
    local y = (love.graphics.getHeight() - font:getHeight(message)*4) / 2
    love.graphics.printf(message, x, y, text_width, "center")
    love.graphics.setColor(255, 255, 255, 255)
end

return Hud
