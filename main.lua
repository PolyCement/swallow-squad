function love.load()
    Object = require "lib.classic"
    Camera = require "lib.hump.camera"
    vector = require "lib.hump.vector"
    anim8 = require "lib.anim8"
    require "collision_handler"
    require "colliders.collider"
    require "colliders.rectangle_collider"
    require "player"
    require "prey"
    require "sprite"
    require "animated_sprite"

    -- pixels per meter
    -- use this to attempt to specify things in meters rather than pixels
    meter = 16

    -- collision handler
    collisionHandler = CollisionHandler()

    -- define player & camera, start em both at the same coordinates
    local player_x, player_y = 100, 416
    player = Player(player_x, player_y)
    camera = Camera(player_x, player_y)

    -- background
    bg = Sprite("assets/bg_test.png", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- set gravity
    gravity = 9.81*meter

    local level_width = 4096

    -- define level geometry
    world = {}
    -- this one is the floor
    world[RectangleCollider(0, 544, level_width, 512, true)] = true
    -- these aren't the floor
    world[RectangleCollider(640, 416, 128, 128, true)] = true
    world[RectangleCollider(128, 288, 256, 64, true)] = true
    world[RectangleCollider(128, 288, 256, 64, true)] = true
    world[RectangleCollider(1024, 128, 256, 544, true)] = true
    world[RectangleCollider(896, 128, 128, 64, true)] = true
    world[RectangleCollider(768, 192, 256, 352, true)] = true
    -- triangles?
    world[Collider(true, vector(1024, 128), vector(1280, 0), vector(1280, 128))] = true

    -- register level geometry with collision handler
    for v, _ in pairs(world) do
        collisionHandler:add(v)
    end

    -- survivors
    prey = {}
    for idx = 1, 12 do
        prey[Prey("assets/prey_wolf.png", 256 + 16 * idx, 512)] = true
    end

    -- toggles drawing of colliders
    showColliders = true
end

function love.update(dt)
    player:update(dt)
    -- have the camera follow the player
    camera:lookAt(player:getPos():unpack())
end

function love.draw()
    -- draw the bg before attaching the camera to give a skybox effect
    bg:draw()
    camera:attach()
    -- draw world geometry
    for o, _ in pairs(world) do
        o:draw()
    end
    -- draw all prey
    for p, _  in pairs(prey) do
        p:draw()
    end
    player:draw()
    camera:detach()
end

function love.keypressed(key)
    -- esc to quit
    if key == "escape" then
        love.event.quit()
    end
    player:keyPressed(key)
end
