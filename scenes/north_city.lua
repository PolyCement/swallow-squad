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
end

function north_city:draw()
    -- draw clouds and level sprite
    clouds:draw()
    camera:attach()
    bg:draw()
    camera:detach()
    -- then draw everything else on top
    north_city.super.draw(self)
end

-- checks if the game has ended
function north_city:gameEnded()
    if table.length(prey) == 0 then
        return true
    end
    return false
end
