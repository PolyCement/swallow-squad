function love.load()
    Object = require "lib.classic"
    Camera = require "lib.hump.camera"
    require "collider"
    require "collision_handler"
    require "obstacle"
    require "player"
    require "prey"
    require "sprite"

    -- pixels per meter
    -- use this to attempt to specify things in meters rather than pixels
    meter = 16

    -- define player & camera, start em both at the same coordinates
    local player_x, player_y = 100, 416
    player = Player(player_x, player_y)
    camera = Camera(player_x, player_y)

    -- background
    bg = Sprite("assets/bg_test.png", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- set gravity
    gravity = 9.81*meter

    -- collision handler
    collisionHandler = CollisionHandler()

    local level_width = 4096
    -- colliders
    obstacles = {}
    -- this one is the floor
    obstacles[Obstacle("assets/ground_test.png", 0, 544, level_width, 512)] = true
    -- these aren't the floor
    obstacles[Obstacle("assets/ground_test.png", 640, 416, 128, 128)] = true
    obstacles[Obstacle("assets/ground_test.png", 128, 288, 256, 64)] = true
    obstacles[Obstacle("assets/ground_test.png", 128, 288, 256, 64)] = true
    obstacles[Obstacle("assets/ground_test.png", 1024, 0, 256, 544)] = true
    obstacles[Obstacle("assets/ground_test.png", 896, 128, 128, 64)] = true
    obstacles[Obstacle("assets/ground_test.png", 768, 192, 256, 352)] = true


    -- survivors
    prey = {}
    for idx = 1, 12 do
        prey[Prey("assets/prey_wolf_16.png", 256 + 16 * idx, 512)] = true
    end

    -- toggles drawing of colliders
    showColliders = false
end

function love.update(dt)
    player:update(dt)
    -- have the camera follow the player
    local x, y = player:getPos()
    camera:lookAt(x, y)
end

function love.draw()
    -- draw the bg before attaching the camera to give a skybox effect
    bg:draw()
    camera:attach()
    -- draw all obstacles
    for o, _ in pairs(obstacles) do
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
