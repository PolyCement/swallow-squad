Object = require "lib.classic"
Camera = require "lib.hump.camera"
vector = require "lib.hump.vector"
require "collision_handler"
require "colliders.collider"
require "colliders.platform"
require "actors.player"
require "actors.prey"
require "sprite"
require "animated_sprite"
require "clock"

-- level 1, north city
north_city = {}

-- todo: figure out somewhere better to put this
local level_width = 5000
local level_height = 3000

world_colliders = {
    -- world geometry
    -- floor
    RectangleCollider(0, 2896, level_width, 64, true),
    -- walls
    RectangleCollider(-64, 0, 64, level_height, true),
    RectangleCollider(level_width, 0, 64, level_height, true),
    -- train track
    Platform(vector(0, 2735), vector(209, 2735)),
    Platform(vector(892, 2735), vector(1164, 2735)),
    Platform(vector(2023, 2735), vector(3277, 2735)),
    Platform(vector(4649, 2735), vector(level_width, 2735)),
    -- generic buildings on left (shortest to tallest)
    Platform(vector(209, 2578), vector(892, 2578)),
    Platform(vector(545, 2453), vector(1227, 2453)),
    Platform(vector(58, 1858), vector(770, 1858)),
    Platform(vector(824, 1418), vector(1506, 1418)),
    Platform(vector(71, 1171), vector(753, 1171)),
    Platform(vector(515, 1057), vector(714, 1057)),
    Platform(vector(273, 896), vector(957, 896)),
    -- old warehouse
    Platform(vector(1158, 2530), vector(2028, 2530)),
    -- sloped building
    Platform(vector(409, 2328), vector(1740, 1796)),
    Platform(vector(1740, 1573), vector(1855, 1573)),
    Platform(vector(1855, 1600), vector(2333, 1408)),
    -- generic buildings on right (shortest to tallest)
    Platform(vector(3277, 2478), vector(3964, 2478)),
    Platform(vector(3964, 2161), vector(4326, 2161)),
    Platform(vector(4020, 2128), vector(4109, 2128)),
    Platform(vector(4230, 1928), vector(4778, 1928)),
    Platform(vector(2937, 1032), vector(3620, 1032)),
    -- old busted up building
    Platform(vector(4326, 2335), vector(4655, 2335)),
    -- slope-topped building on right
    Platform(vector(4327, 1038), vector(4378, 1038)),
    Platform(vector(4378, 1038), vector(4888, 867)),
    Platform(vector(4888, 867), vector(4931, 867)),
    Platform(vector(4421, 676), vector(4888, 832)),
    Platform(vector(4378, 676), vector(4421, 676)),
    -- weird building on right
    Platform(vector(3355, 1580), vector(4201, 1580)),
    Platform(vector(3397, 1386), vector(4161, 1386)),
    Platform(vector(3438, 1348), vector(4120, 1348)),
    -- houses
    Platform(vector(2220, 2771), vector(2703, 2771)),
    -- building w/ crane
    Platform(vector(1053, 721), vector(1735, 721)),
    Platform(vector(1520, 690), vector(1547, 690)),
    Platform(vector(1533, 690), vector(1944, 288)),
    -- crane
    Platform(vector(3512, 503), vector(3868, 493)),
    Platform(vector(3868, 493), vector(3948, 493)),
    Platform(vector(3948, 493), vector(4205, 529)),
    -- central building
    Platform(vector(2159, 252), vector(2651, 154)),
    Platform(vector(2651, 252), vector(2728, 252)),
    Platform(vector(2728, 154), vector(3223, 252)),
    -- girders
    -- todo: make these ones move
    Platform(vector(1812, 1241), vector(2075, 1241)),
    Platform(vector(3418, 830), vector(3584, 830))
}

function north_city:enter()
    -- collision handler
    collisionHandler = CollisionHandler()

    -- define player & camera, start em both at the same coordinates
    -- if we don't spawn the player slightly above the ground they clip through sometimes
    local player_x, player_y = level_width/2, 2766
    player = Player(player_x, player_y)
    camera = Camera(player_x, player_y)

    -- background
    bg = Sprite("assets/north_city.png", 0, 0)

    -- gui blade
    blade = love.graphics.newImage("assets/gui_blade.png")

    -- set gravity
    gravity = 9.81 * 16

    -- the clock
    clock = Clock()

    -- has the game finished?
    gameEnded = false

    -- define level geometry
    world = {}
    for _, collider in pairs(world_colliders) do
        world[collider] = true
    end

    -- register level geometry with collision handler
    for v, _ in pairs(world) do
        collisionHandler:add(v)
    end

    -- survivors
    prey = {}
    prey[Prey("assets/prey_wolf.png", 4628, 2303)] = true
    prey[Prey("assets/prey_wolf.png", 100, 1139)] = true
    prey[Prey("assets/prey_wolf.png", 1680, 689)] = true
    prey[Prey("assets/prey_wolf.png", 4901, 835)] = true
    prey[Prey("assets/prey_wolf.png", 3372, 1548)] = true
    prey[Prey("assets/prey_wolf.png", 250, 1826)] = true
    prey[Prey("assets/prey_wolf.png", 2028, 1209)] = true
    prey[Prey("assets/prey_wolf.png", 2964, 1000)] = true
    prey[Prey("assets/prey_wolf.png", 250, 2546)] = true
    -- it's taur time
    prey[Taur("assets/taur_fox.png", 2678, 213)] = true

    showColliders = false
    showMousePos = false
end

function north_city:update(dt)
    -- check if the game should end
    if length(prey) == 0 then
        gameEnded = true
    end
    if not gameEnded then
        clock:update(dt)
        player:update(dt)
    end
    camera:lookAt(bind_camera():unpack())
    for p, _  in pairs(prey) do
        p:update()
    end
end

-- i can't believe i have to define this myself
function length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
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
    -- draw the timer
    if gameEnded then
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
    local y = love.graphics.getHeight() - 48
    -- draw the clock
    clock:draw(10, y)
    -- draw the number of remaining prey
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(gui_font)
    local message = "Survivors: " .. length(prey)
    love.graphics.print(message, 605, y)
    love.graphics.setColor(255, 255, 255, 255)
end

function drawBlades()
    local y = love.graphics.getHeight() - blade:getHeight()
    -- left blade
    love.graphics.draw(blade, 0, y)
    -- right blade
    love.graphics.draw(blade, love.graphics.getWidth(), y, 0, -1, 1)
end

function north_city:keypressed(key)
    if gameEnded then
        if key == "return" then
            Gamestate.switch(main_menu)
        end
    else
        player:keyPressed(key)
    end
end

function north_city:keyreleased(key)
    player:keyReleased(key)
end

-- debug: prints the coordinate under the cursor
-- mostly it's just so i know where to place world geometry
function north_city:mousemoved(x, y)
    if showMousePos then
        local adjusted_x = x - love.graphics.getWidth() / 2
        local adjusted_y = y - love.graphics.getHeight() / 2
        local cam_x, cam_y = camera:position()
        print(math.floor(adjusted_x + cam_x), math.floor(adjusted_y + cam_y))
    end
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
