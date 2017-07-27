local Object = require "lib.classic"
local Camera = require "lib.hump.camera"
local Hud = require "engine.hud"
-- ideally this would be imported as prey but prey is a global var already cos im bad at this
local survivors = require "actors.prey"
local CollisionHandler = require "engine.collision_handler"
local colliders = require "engine.colliders"
local Pause = require "scenes.pause"
local Player = require "actors.player"
local TiledMap = require "engine.tiledmap"

-- loads colliders defined by the given file into the collision handler
local function load_colliders(filename)
    -- open the file
    local f = io.open(filename, "r")
    for line in f:lines() do
        -- treat lines starting with # as a comment (ie. skip it)
        if not string.starts(line, "#") then
            -- read the fields to a table
            local fields = string.split(line)
            -- the first field determines the collider type
            if fields[1] == "c" then
                -- standard collider
                for idx = 2, #fields do
                    fields[idx] = tonumber(fields[idx])
                end
                collisionHandler:add(colliders.Collider(unpack(fields, 2)))
            elseif fields[1] == "p" then
                -- standard collider
                for idx = 2, #fields do
                    fields[idx] = tonumber(fields[idx])
                end
                -- one-way platform
                collisionHandler:add(colliders.Platform(unpack(fields, 2)))
            elseif fields[1] == "s" then
                -- prey (s for survivor, since p is in use)
                local species = survivors.get_random_species()
                prey[species:newPrey(tonumber(fields[2]), tonumber(fields[3]))] = true
            elseif fields[1] == "t" then
                -- taur
                local taur = survivors.species.taur
                prey[taur:newPrey(tonumber(fields[2]), tonumber(fields[3]))] = true
            end
        end
    end
    f:close()
end

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

function Level:new(filename, player_x, player_y, width, height)
    -- initialize prey
    prey = {}

    -- create collision handler and initialise with world geometry
    collisionHandler = CollisionHandler()
    -- load_colliders(filename)
    self.map = TiledMap(filename)

    -- define player & camera, start em both at the same coordinates
    self.player = Player(player_x, player_y)
    self.camera = Camera(player_x, player_y)

    -- make prey face the player
    for p, _ in pairs(prey) do
        p:lookAt(player_x)
    end

    -- hud
    self.hud = Hud(table.length(prey))

    -- level width and height (for restricting camera)
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
