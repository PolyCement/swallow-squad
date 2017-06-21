local vector = require "lib.hump.vector"
local sprite = require "engine.sprite"
local Level = require "engine.scenes.base"

-- level 1, north city
local NorthCity = Level:extend()

function NorthCity:enter()
    -- initialize geometry and player position
    NorthCity.super.new(self, "scenes/north_city.csv", 2500, 2767, 5000, 3050)

    -- set the background to grey
    love.graphics.setBackgroundColor(230, 230, 230)

    -- clouds
    clouds = sprite.Sprite("assets/images/bg_cloud.png", 0, 0)

    -- background
    bg = sprite.Sprite("assets/images/north_city.png", 0, 0)
end

function NorthCity:draw()
    -- draw clouds and level sprite
    clouds:draw()
    self.camera:attach()
    bg:draw()
    self.camera:detach()
    -- then draw everything else on top
    NorthCity.super.draw(self)
end

-- checks if the game has ended
function NorthCity:gameEnded()
    if table.length(prey) == 0 then
        return true
    end
    return false
end

return NorthCity
