local Object = require "lib.classic"
local vector = require "lib.hump.vector"

-- todo: figure out where to put this, it's only used here and in player
-- "enum" for side which collision occurs on
-- negate to get the opposite side
side = {
    top = 1,
    bottom = -1,
    left = 2,
    right = -2 
}

-- handles collisions
local CollisionHandler = Object:extend()

-- world geometry is required (just a table)
function CollisionHandler:new(world)
    self.colliders = {}
    -- stuff to do with the world, maybe world should be its own object....
    self.world = world
end

-- add a collider
function CollisionHandler:add(collider)
    self.colliders[collider] = true
end

-- remove a collider
function CollisionHandler:remove(collider)
    self.colliders[collider] = nil
end

-- draw all collision boxes
function CollisionHandler:draw()
    for c, _ in pairs(self.colliders) do
        c:drawBoundingBox()
    end
end

-- check for collisions and resolve em
function CollisionHandler:resolve()
    -- only check objects that can move: right now, that's the player
    for collider, _ in pairs(self.colliders) do
        if collider:getTag() == "player" then
            local delta = self:checkWorldCollision(collider)
            collider:move(delta)
            self:checkObjectCollision(collider)
        end
    end
end

-- checks for a collision between 2 aabb colliders
local function intersect(a, b)
    local a_x, a_y = a.pos:unpack()
    local a_w, a_h = a.width, a.height
    local b_x, b_y = b.pos:unpack()
    local b_w, b_h = b.width, b.height
    return a_x < b_x + b_w and a_x + a_w > b_x and a_y < b_y + b_h and a_y + a_h > b_y
end

function CollisionHandler:checkObjectCollision(collider)
    -- simple check for aabb collisions - doesn't handle any kind of blocking behaviour
    for other_collider, _ in pairs(self.colliders) do
        if other_collider ~= collider then
            if intersect(collider, other_collider) then
                collider.onCollision(other_collider)
                other_collider.onCollision(collider)
            end
        end
    end
end

-- checks for collisions between the given collider and the world
-- hits a callback if a collision is detected
-- returns the delta resulting from collisions with the environment
local NUDGE = 0.0001
function CollisionHandler:checkWorldCollision(collider)
    -- break down the movement into x and y components
    local x, y = collider.pos:unpack()
    local old_x, old_y = collider.lastPos:unpack()
    local w, h = collider.width, collider.height
    local tw, th = self.world.tileWidth, self.world.tileHeight
    -- figure out the x coord of the forward edge
    local fw_x = x > old_x and x + w or x
    local tile_x = math.floor(fw_x / self.world.tileWidth)
    -- what rows are we intersecting?
    local top_y = math.floor(old_y / self.world.tileHeight)
    local bottom_y = math.floor((old_y + h)/self.world.tileHeight)
    -- check those rows
    -- if any of the tiles we hit are slopes we need to handle stuff differently
    -- ramp checks are only relevant to the lowest tile... handle it separately?
    local can_move = true
    for row = top_y, bottom_y do
        if self.world.world[tile_x][row] then
            can_move = false
        end
    end
    print("x: " .. (can_move and "can move" or "can't move"))
    local dx = 0
    if not can_move then
        dx = x > old_x and tile_x*tw - (x + w + NUDGE) or (tile_x+1)*tw - x + NUDGE
        collider.onCollision(nil, (x > old_x and side.right or side.left))
    end
    -- apply dx locally before calculating dy because wall grabs are not intended behaviour
    x = x + dx
    -- figure out the y coord of the forward edge
    local fw_y = y > old_y and y + h or y
    local tile_y = math.floor(fw_y / self.world.tileHeight)
    -- what rows are we intersecting?
    local top_x = math.floor(x / self.world.tileWidth)
    local bottom_x = math.floor((x + w)/self.world.tileWidth)
    -- check those columns
    local can_move = true
    for col = top_x, bottom_x do
        if self.world.world[col][tile_y] then
            can_move = false
        end
    end
    print("y: " .. (can_move and "can move" or "can't move"))
    local dy = 0
    if not can_move then
        dy = y > old_y and tile_y*th - (y + h + NUDGE) or (tile_y+1)*th - y + NUDGE
        collider.onCollision(nil, (y > old_y and side.bottom or side.top))
    end
    print("delta: ", dx, dy)
    return vector(dx, dy)
end

return CollisionHandler
