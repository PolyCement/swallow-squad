vector = require "lib.hump.vector"
require "actors.prey"
require "engine.sprite"
require "scenes.level"

-- level 1, north city
north_city = Level:extend()

function north_city:enter()
    -- initialize geometry and player position
    north_city.super.new(self, "scenes/north_city.csv", 2500, 2767, 5000, 3050)

    -- set the background to grey
    love.graphics.setBackgroundColor(230, 230, 230)

    -- clouds
    clouds = Sprite("assets/bg_cloud.png", 0, 0)

    -- background
    bg = Sprite("assets/north_city.png", 0, 0)

    -- gui blade
    blade = love.graphics.newImage("assets/gui_blade.png")

    -- survivors
    prey = {}
    prey[Prey("assets/prey_wolf.png", 4628, 2303)] = true
    prey[Prey("assets/prey_wolf.png", 100, 1138)] = true
    prey[Prey("assets/prey_wolf.png", 1680, 689)] = true
    prey[Prey("assets/prey_wolf.png", 4901, 841)] = true
    prey[Prey("assets/prey_wolf.png", 3372, 1547)] = true
    prey[Prey("assets/prey_wolf.png", 200, 1825)] = true
    prey[Prey("assets/prey_wolf.png", 2002, 1209)] = true
    prey[Prey("assets/prey_wolf.png", 2964, 999)] = true
    prey[Prey("assets/prey_wolf.png", 250, 2545)] = true
    -- here comes a special boy!
    prey[Taur("assets/taur_fox.png", 2678, 213)] = true
end

-- checks if the game has ended
function north_city:gameEnded()
    if table.length(prey) == 0 then
        return true
    end
    return false
end

function north_city:draw()
    -- draw clouds in bg
    clouds:draw()
    camera:attach()
    bg:draw()
    -- draw world colliders
    if showColliders then
        collisionHandler:draw()
    end
    -- draw all prey
    for p, _  in pairs(prey) do
        p:draw()
    end
    player:draw()
    camera:detach()
    -- draw the timer
    if self:gameEnded() then
        drawEndMessage()
    else
        drawGUI()
    end
end

local gui_font = love.graphics.newFont(28)
local font = love.graphics.newFont(32)
-- prints the message when the game ends
function drawEndMessage()
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(font)
    local message = "Congratulations!\nYou saved everyone!\n\nTime: " .. clock:getFormattedTime()
    -- centre the message
    local text_width = font:getWidth(message)
    local x = (love.graphics.getWidth() - text_width) / 2
    local y = (love.graphics.getHeight() - font:getHeight(message)*4) / 2
    love.graphics.printf(message, x, y, text_width, "center")
    love.graphics.setColor(255, 255, 255, 255)
end

function drawGUI()
    -- draw gui blades
    drawBlades()
    local y = love.graphics.getHeight() - 40
    -- draw the clock
    clock:draw(12, y)
    -- draw the number of remaining prey
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(gui_font)
    local message = "Survivors: " .. table.length(prey)
    love.graphics.print(message, 603, y)
    love.graphics.setColor(255, 255, 255, 255)
end

function drawBlades()
    local y = love.graphics.getHeight() - blade:getHeight()
    -- left blade
    love.graphics.draw(blade, 0, y)
    -- right blade
    love.graphics.draw(blade, love.graphics.getWidth(), y, 0, -1, 1)
end
