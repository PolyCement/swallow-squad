local vector = require "lib.hump.vector"
local sprite = require "engine.sprite"
local Level = require "engine.scenes.base"

-- test level, for debugging
local TestZone = Level:extend()

function TestZone:enter()
    -- initialize geometry and player position
    TestZone.super.new(self, "scenes/test_zone.json", 100, 416)
    
    -- show colliders cos we're in the void
    showColliders = true

    -- background
    bg = sprite.Sprite("assets/images/bg_cloud.png", 0, 0)
end

function TestZone:draw()
    -- draw clouds, then everything else
    clouds:draw()
    TestZone.super.draw(self)
end

return TestZone
