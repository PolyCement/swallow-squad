local Object = require "lib.classic"
local Camera = require "lib.hump.camera"
local Hud = require "engine.hud"
-- ideally this would be imported as prey but prey is a global var already cos im bad at this
local survivors = require "actors.prey"
local CollisionHandler = require "engine.collision_handler"
local Pause = require "scenes.pause"
local Player = require "actors.player"
local TiledMap = require "engine.tiledmap"

-- restrain the camera to stay between (0, 0) and (width, height)
-- don't bind on nil dimensions
-- todo: make this suck less
local function bind_camera(width, height, player_pos)
    local camera_pos = player_pos
    if width then
        local min_cam_bound_x = love.graphics.getWidth() / 2
        local max_cam_bound_x = width - love.graphics.getWidth() / 2
        if camera_pos.x < min_cam_bound_x then
            camera_pos.x = min_cam_bound_x
        end
        if camera_pos.x > max_cam_bound_x then
            camera_pos.x = max_cam_bound_x
        end
    end
    if height then
        local cam_bound_y = height - 100 - love.graphics.getHeight() / 2
        if camera_pos.y > cam_bound_y then
            camera_pos.y = cam_bound_y
        end
    end
    return camera_pos
end

-- stuff common to all levels will end up here once i figure out what that actually is
local Level = Object:extend()

function Level:new(filename, width, height)
    -- load the map
    self.map = TiledMap(filename)
    
    -- create collision handler and initialise with world geometry
    collisionHandler = CollisionHandler(self.map:getWorld())

    -- spawn any objects the map has requested
    local objs = self.map:getObjects()
    prey = {}
    for _, obj in pairs(objs) do
        if obj.type == "player" then
            player_x = obj.x
            self.player = Player(obj.x, obj.y)
        elseif obj.type == "prey" then
            local species = survivors.get_random_species()
            prey[species:newPrey(obj.x, obj.y)] = true
        end
    end
    local player_x, player_y = self.player:getPos():unpack()
    self.camera = Camera(player_x, player_y)

    -- make prey face the player
    for p, _ in pairs(prey) do
        p:lookAt(player_x)
    end

    -- hud
    self.hud = Hud(table.length(prey))

    -- level width and height (for restricting camera)
    -- todo: pull these from tiledmap
    self.width = width
    self.height = height

    -- set gravity
    gravity = 9.81 * 3 * 16

    -- toggles drawing of colliders
    showColliders = false
    showMousePos = false
end

function Level:update(dt)
    -- update stuff if the game hasn't ended
    if not self:gameEnded() then
        self.hud:update(dt, table.length(prey))
        self.player:update(dt)
        collisionHandler:resolve()
        self.camera:lookAt(bind_camera(self.width, self.height, self.player:getPos()):unpack())
        for p, _  in pairs(prey) do
            p:update()
        end
        print("pos: ", self.player:getPos())
    end
end

function Level:draw()
    self.camera:attach()
    self.map:draw()
    -- draw world colliders
    if showColliders then
        collisionHandler:draw()
    end
    -- draw the player before prey so speech bubbles show on top
    self.player:draw()
    -- draw all prey
    for p, _  in pairs(prey) do
        p:draw()
    end
    self.camera:detach()
    -- draw the timer
    if self:gameEnded() then
        self.hud:drawEndMessage()
    else
        self.hud:draw()
    end
end

-- by default the ride never ends
function Level:gameEnded()
    return false
end

function Level:keypressed(key)
    -- debug stuff
    if debug then
        if key == "c" then
            showColliders = not showColliders
        elseif key == "m" then
            showMousePos = not showMousePos
        end
    end
    -- pause menu
    if key == "escape" then
        Gamestate.push(Pause)
    end
    -- if the game has ended ignore everything but enter
    if self:gameEnded() then
        if key == "return" then
            Gamestate.switch(MainMenu)
        end
    else
        self.player:keyPressed(key)
    end
end

-- debug: prints the coordinate under the cursor (for placing world geometry)
function Level:mousemoved(x, y)
    if showMousePos then
        local adjusted_x = x - love.graphics.getWidth() / 2
        local adjusted_y = y - love.graphics.getHeight() / 2
        local cam_x, cam_y = self.camera:position()
        print(math.floor(adjusted_x + cam_x), math.floor(adjusted_y + cam_y))
    end
end

return Level
