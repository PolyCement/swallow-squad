Object = require "lib.classic"
Camera = require "lib.hump.camera"
vector = require "lib.hump.vector"
require "engine.collision_handler"
require "colliders.collider"
require "colliders.platform"
require "actors.player"
require "actors.prey"
require "engine.sprite"
require "engine.animated_sprite"
require "scenes.level"

-- test level, for debugging
test_zone = Level:extend()

local level_width = 4096

local world_colliders = {
    -- this one is the floor
    RectangleCollider(0, 544, level_width, 512, true),
    -- test platform
    Platform(vector(128, 288), vector(384, 288), vector(384, 352)),
    -- ramp and box for testing transition between surfaces
    Collider(true, vector(580, 544), vector(780, 400), vector(780, 544)),
    RectangleCollider(780, 400, 200, 144, true)
}

function test_zone:enter()
    -- collision handler
    collisionHandler = CollisionHandler()
    initGeometry(world_colliders)

    -- define player & camera, start em both at the same coordinates
    local player_x, player_y = 100, 416
    player = Player(player_x, player_y)
    camera = Camera(player_x, player_y)

    -- background
    bg = Sprite("assets/bg_cloud.png", 0, 0)

    -- set gravity (should this be in main.lua?)
    gravity = 9.81 * 3 * 16

    -- survivors
    prey = {}
    for idx = 1, 12 do
        prey[Prey("assets/prey_wolf.png", 144 + 16 * idx, 256)] = true
    end

    -- toggles drawing of colliders
    showMousePos = true
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
    collisionHandler:draw()
    -- draw all prey
    for p, _  in pairs(prey) do
        p:draw()
    end
    player:draw()
    camera:detach()
end

function test_zone:keypressed(key)
    player:keyPressed(key)
end

function test_zone:keyreleased(key)
    player:keyReleased(key)
end
