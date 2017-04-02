vector = require "lib.hump.vector"
require "actors.prey"
require "engine.sprite"
require "scenes.level"

-- test level, for debugging
test_zone = Level:extend()

function test_zone:enter()
    -- initialize geometry and player position
    test_zone.super.new(self, "scenes/test_zone.csv", 100, 416)
    
    -- show colliders cos we're in the void
    showColliders = true

    -- background
    bg = Sprite("assets/images/bg_cloud.png", 0, 0)
end

function test_zone:draw()
    -- draw clouds, then everything else
    clouds:draw()
    test_zone.super.draw(self)
end
