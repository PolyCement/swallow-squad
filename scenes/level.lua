Object = require "lib.classic"
Camera = require "lib.hump.camera"
require "engine.collision_handler"
require "colliders.collider"
require "colliders.platform"
require "engine.hud"
require "actors.player"

-- stuff common to all levels will end up here once i figure out what that actually is
-- levels should extend this
Level = Object:extend()

-- initialise the level
function Level:new(filename, player_x, player_y, width, height)
    -- initialize prey
    prey = {}

    -- create collision handler and initialise with world geometry
    collisionHandler = CollisionHandler()
    loadColliders(filename)

    -- define player & camera, start em both at the same coordinates
    player = Player(player_x, player_y)
    camera = Camera(player_x, player_y)

    -- hud
    self.hud = Hud()

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
        self.hud:update(dt)
        player:update(dt)
        camera:lookAt(bindCamera(self.width, self.height):unpack())
        for p, _  in pairs(prey) do
            p:update()
        end
    end
end

function Level:draw()
    camera:attach()
    -- draw world colliders
    if showColliders then
        collisionHandler:draw()
    end
    -- draw the player before prey so speech bubbles show on top
    player:draw()
    -- draw all prey
    for p, _  in pairs(prey) do
        p:draw()
    end
    camera:detach()
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
    -- if the game has ended ignore everything but enter
    if self:gameEnded() then
        if key == "return" then
            Gamestate.switch(main_menu)
        end
    else
        player:keyPressed(key)
    end
end

function Level:keyreleased(key)
    player:keyReleased(key)
end

-- debug: prints the coordinate under the cursor (for placing world geometry)
function Level:mousemoved(x, y)
    if showMousePos then
        local adjusted_x = x - love.graphics.getWidth() / 2
        local adjusted_y = y - love.graphics.getHeight() / 2
        local cam_x, cam_y = camera:position()
        print(math.floor(adjusted_x + cam_x), math.floor(adjusted_y + cam_y))
    end
end

-- monkey patch to add something resembling python's startswith
function string.starts(str, sub_str)
   return string.sub(str, 1, string.len(sub_str)) == sub_str
end

-- and another to add a split function
function string.split(str, delimiter)
    local delimiter, fields = delimiter or ",", {}
    local pattern = "([^" .. delimiter.. "]+)"
    string.gsub(str, pattern, function(x) table.insert(fields, x) end)
    return fields
end

-- loads colliders defined by the given file into the collision handler
function loadColliders(filename)
    -- open the file
    f = io.open(filename, "r")
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
                collisionHandler:add(Collider(true, unpack(fields, 2)))
            elseif fields[1] == "p" then
                -- standard collider
                for idx = 2, #fields do
                    fields[idx] = tonumber(fields[idx])
                end
                -- one-way platform
                collisionHandler:add(Platform(unpack(fields, 2)))
            elseif fields[1] == "s" then
                -- prey (s for survivor, since p is in use)
                prey[Prey(fields[2], tonumber(fields[3]), tonumber(fields[4]))] = true
            elseif fields[1] == "t" then
                -- taur
                prey[Prey(fields[2], tonumber(fields[3]), tonumber(fields[4]))] = true
            end
        end
    end
    f:close()
end

-- restrain the camera to stay between (0, 0) and (width, height)
-- don't bind on nil dimensions
-- todo: make this suck less
function bindCamera(width, height)
    local camera_pos = player:getPos()
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
