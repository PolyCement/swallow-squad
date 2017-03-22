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
    bg = Sprite("assets/bg_cloud.png", 0, 0)

    -- survivors
    prey = {}
    for idx = 1, 12 do
        prey[Prey("assets/prey_wolf.png", 144 + 16 * idx, 256)] = true
    end
end

function test_zone:update(dt)
    player:update(dt)
    -- have the camera follow the player
    camera:lookAt(player:getPos():unpack())
    -- update prey (shout)
    for p, _  in pairs(prey) do
        p:update()
    end
end

function test_zone:draw()
    -- draw the bg before attaching the camera to give a skybox effect
    bg:draw()
    camera:attach()
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
end
