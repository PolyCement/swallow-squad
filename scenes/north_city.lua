-- level 1, north city
north_city = {}

-- pixels per meter
-- use this to specify things in meters rather than pixels
METER = 16

function north_city:enter()
    Object = require "lib.classic"
    Camera = require "lib.hump.camera"
    vector = require "lib.hump.vector"
    require "collision_handler"
    require "colliders.collider"
    require "colliders.rectangle_collider"
    require "colliders.platform"
    require "player"
    require "prey"
    require "sprite"
    require "animated_sprite"

    -- collision handler
    collisionHandler = CollisionHandler()

    -- define player & camera, start em both at the same coordinates
    local player_x, player_y = 1100, 1000
    player = Player(player_x, player_y)
    camera = Camera(player_x, player_y)

    -- background
    bg = Sprite("assets/north_city.png", 0, 0)

    -- set gravity
    gravity = 9.81 * METER

    local level_width = bg:getWidth()
    local level_height = bg:getHeight()

    -- define level geometry
    world = {}
    -- floor
    world[RectangleCollider(0, 1395, level_width, 64, true)] = true
    -- walls
    world[RectangleCollider(-64, 0, 64, level_height, true)] = true
    world[RectangleCollider(level_width, 0, 64, level_height, true)] = true
    -- these aren't the floor
    world[RectangleCollider(0, 1030, 860, 365, true)] = true
    world[RectangleCollider(1041, 1280, 514, 115, true)] = true
    -- sloped building
    world[Platform(vector(0, 1028), vector(674, 758))] = true
    world[Platform(vector(789, 489), vector(1045, 386))] = true
    world[Platform(vector(674, 462), vector(789, 462))] = true
    -- todo: make this one move
    world[Platform(vector(1710, 1178), vector(1876, 1178))] = true

    -- register level geometry with collision handler
    for v, _ in pairs(world) do
        collisionHandler:add(v)
    end

    -- survivors
    prey = {}
    prey[Prey("assets/prey_wolf.png", 600, 998)] = true
    prey[Prey("assets/prey_wolf.png", 1600, 1363)] = true
    prey[Prey("assets/prey_wolf.png", 700, 430)] = true

    showColliders = true
end

function north_city:update(dt)
    player:update(dt)
    camera:lookAt(bind_camera():unpack())
    for p, _  in pairs(prey) do
        p:update()
    end
end

function north_city:draw()
    camera:attach()
    bg:draw()
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

function north_city:keypressed(key)
    player:keyPressed(key)
end

function north_city:keyreleased(key)
    player:keyReleased(key)
end

-- restrain the camera to within the playable area
function bind_camera()
    local camera_pos = player:getPos()
    local min_cam_bound_x = love.graphics.getWidth() / 2
    local max_cam_bound_x = bg:getWidth() - love.graphics.getWidth() / 2
    local cam_bound_y = bg:getHeight() - love.graphics.getHeight() / 2
    if camera_pos.y > cam_bound_y then
        camera_pos.y = cam_bound_y
    end
    if camera_pos.x < min_cam_bound_x then
        camera_pos.x = min_cam_bound_x
    end
    if camera_pos.x > max_cam_bound_x then
        camera_pos.x = max_cam_bound_x
    end
    return camera_pos
end
