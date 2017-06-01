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

function Hud:new()
    -- the clock
    self.clock = Clock()
    self.preyCount = table.length(prey)
    -- gui blade sprite and y position
    self.blade = love.graphics.newImage("assets/images/gui_blade.png")
    self.bladeY = love.graphics.getHeight() - self.blade:getHeight()
    -- text positions
    self.textY = love.graphics.getHeight() - 40
    self.clockX = 12
    self.preyCountX = 603
end

-- update clock and remaining prey count
function Hud:update(dt)
    self.clock:update(dt)
    self.preyCount = table.length(prey)
end

-- draws the hud
local font = love.graphics.newFont(28)
function Hud:draw()
    -- draw gui blades
    love.graphics.draw(self.blade, 0, self.bladeY)
    love.graphics.draw(self.blade, love.graphics.getWidth(), self.bladeY, 0, -1, 1)
    -- set up for drawing text
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(font)
    -- draw the clock
    love.graphics.print("Time: " .. self.clock:getFormattedTime(), self.clockX, self.textY)
    -- draw the number of remaining prey
    love.graphics.print("Survivors: " .. self.preyCount, self.preyCountX, self.textY)
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
