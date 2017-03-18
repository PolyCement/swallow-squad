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
require "clock"
require "scenes.level"

-- level 1, north city
north_city = Level:extend()

-- todo: figure out somewhere better to put this (csv file? json?)
local level_width = 5000
local level_height = 3000

world_colliders = {
    -- world geometry
    -- floor
    RectangleCollider(0, 2895, level_width, 800, true),
    -- walls
    RectangleCollider(-64, 0, 64, level_height, true),
    RectangleCollider(level_width, 0, 64, level_height, true),
    -- train track
    Platform(vector(677, 2734), vector(1164, 2734)),
    Platform(vector(2023, 2734), vector(3264, 2734)),
    Platform(vector(4649, 2734), vector(level_width, 2734)),
    -- generic buildings on left (shortest to tallest)
    Platform(vector(0, 2577), vector(677, 2577)),
    Platform(vector(545, 2453), vector(1227, 2453)),
    Platform(vector(58, 1857), vector(768, 1857)),
    Platform(vector(893, 1417), vector(1487, 1417)),
    Platform(vector(69, 1170), vector(757, 1170)),
    Platform(vector(515, 1056), vector(714, 1056)),
    Platform(vector(342, 895), vector(971, 895)),
    -- old warehouse
    Platform(vector(1158, 2530), vector(2028, 2530)),
    -- sloped building
    Platform(vector(409, 2328), vector(1740, 1796)),
    Platform(vector(1740, 1572), vector(1855, 1572)),
    Platform(vector(1855, 1600), vector(2333, 1408)),
    -- generic buildings on right (shortest to tallest)
    Platform(vector(3264, 2477), vector(3951, 2477)),
    Platform(vector(3951, 2160), vector(4326, 2160)),
    Platform(vector(4007, 2127), vector(4096, 2127)),
    Platform(vector(4230, 1929), vector(4772, 1929)),
    Platform(vector(2933, 1031), vector(3623, 1031)),
    -- old busted up building
    Platform(vector(4326, 2335), vector(4655, 2335)),
    -- fence
    Platform(vector(4326, 2826), vector(4345, 2826)),
    Platform(vector(4407, 2826), vector(4699, 2826)),
    -- slope-topped building on right
    Platform(vector(4327, 1037), vector(4378, 1037)),
    Platform(vector(4378, 1037), vector(4866, 873)),
    Platform(vector(4866, 873), vector(4919, 873)),
    Platform(vector(4378, 669), vector(4866, 832)),
    -- weird building on right
    Platform(vector(3355, 1579), vector(4201, 1579)),
    Platform(vector(3397, 1385), vector(4161, 1385)),
    Platform(vector(3438, 1347), vector(4120, 1347)),
    -- building w/ crane
    Platform(vector(1053, 721), vector(1735, 721)),
    Platform(vector(1520, 690), vector(1547, 690)),
    Platform(vector(1533, 690), vector(1944, 288)),
    -- crane
    Platform(vector(3411, 500), vector(3956, 500)),
    Platform(vector(3956, 500), vector(3992, 536)),
    Platform(vector(3992, 536), vector(4234, 536)),
    -- central building
    Platform(vector(2159, 252), vector(2651, 154)),
    Platform(vector(2651, 252), vector(2728, 252)),
    Platform(vector(2728, 154), vector(3223, 252)),
    -- girders
    -- todo: make these ones move
    Platform(vector(1870, 1241), vector(2038, 1241)),
    Platform(vector(3357, 830), vector(3526, 830))
}

function north_city:enter()
    -- create collision handler and initialise with world geometry
    collisionHandler = CollisionHandler()
    initGeometry(world_colliders)

    -- define player & camera, start em both at the same coordinates
    -- something is making the player teleport down sometimes so spawn above the ground
    local player_x, player_y = level_width/2, 2767
    player = Player(player_x, player_y)
    camera = Camera(player_x, player_y)

    -- set the background to grey
    love.graphics.setBackgroundColor(230, 230, 230)

    -- clouds
    clouds = Sprite("assets/bg_cloud.png", 0, 0)

    -- background
    bg = Sprite("assets/north_city.png", 0, 0)

    -- gui blade
    blade = love.graphics.newImage("assets/gui_blade.png")

    -- set gravity
    -- we're using triple gravity cos at this scale standard gravity is super floaty
    gravity = 9.81 * 3 * 16

    -- the clock
    clock = Clock()

    -- has the game finished?
    gameEnded = false

    -- survivors
    prey = {}
    prey[Prey("assets/prey_wolf.png", 4628, 2303)] = true
    prey[Prey("assets/prey_wolf.png", 100, 1138)] = true
    prey[Prey("assets/prey_wolf.png", 1680, 689)] = true
    prey[Prey("assets/prey_wolf.png", 4901, 841)] = true
    prey[Prey("assets/prey_wolf.png", 3372, 1547)] = true
    prey[Prey("assets/prey_wolf.png", 200, 1825)] = true
    prey[Prey("assets/prey_wolf.png", 2002, 1209)] = true
    prey[Prey("assets/prey_wolf.png", 2964, 999)] = true
    prey[Prey("assets/prey_wolf.png", 250, 2545)] = true
    -- here comes a special boy!
    prey[Taur("assets/taur_fox.png", 2678, 213)] = true

    showColliders = false
    showMousePos = false
end

function north_city:update(dt)
    -- if dt is too big do multiple updates
    -- should stop players phasing through the floor
    -- todo: move this to main.lua?
    local time_left = dt
    while time_left > 0 do
        -- 0.05 should be lenient enough
        dt = math.min(0.05, time_left)
        time_left = time_left - dt
        -- check if the game should end
        if table.length(prey) == 0 then
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
end

function north_city:draw()
    -- draw clouds in bg
    clouds:draw()
    camera:attach()
    bg:draw()
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
    local y = love.graphics.getHeight() - 40
    -- draw the clock
    clock:draw(12, y)
    -- draw the number of remaining prey
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(gui_font)
    local message = "Survivors: " .. table.length(prey)
    love.graphics.print(message, 603, y)
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

-- restrain the camera to within the playable area
function bind_camera()
    local camera_pos = player:getPos()
    local min_cam_bound_x = love.graphics.getWidth() / 2
    local max_cam_bound_x = bg:getWidth() - love.graphics.getWidth() / 2
    local cam_bound_y = bg:getHeight() - 100 - love.graphics.getHeight() / 2
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
