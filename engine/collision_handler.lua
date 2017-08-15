local Object = require "lib.classic"
local vector = require "lib.hump.vector"

-- distance to put between a collider and something it bumped into
local NUDGE = 0.0001

-- handles collisions
local CollisionHandler = Object:extend()

-- takes the "world" returned by tiledmap
function CollisionHandler:new(world)
    self.colliders = {}
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

-- draw world and all bounding boxes
function CollisionHandler:draw()
    self.world.draw()
    for c, _ in pairs(self.colliders) do
        c:drawBoundingBox()
    end
end

-- check if the given collider is touching the floor
function CollisionHandler:onGround(collider)
    local x, y = collider.pos:unpack()
    local w, h = collider.width, collider.height
    local tw, th = self.world.tileWidth, self.world.tileHeight
    local left_col, right_col = math.floor(x / tw), math.floor((x + w) / tw)
    local bottom_row = math.floor((y + h + (NUDGE*2)) / th)
    -- if we're within 2 NUDGEs of a solid block (should be 1 NUDGE but rounding), we're grounded
    for col = left_col, right_col do
        local current_tile = self.world:getTile(col, bottom_row)
        if current_tile.collisionType ~= "none" then
            return true
        end
    end
    return false
end

-- checks for a collision between 2 aabb colliders
local function intersect(a, b)
    local a_x, a_y = a.pos:unpack()
    local a_w, a_h = a.width, a.height
    local b_x, b_y = b.pos:unpack()
    local b_w, b_h = b.width, b.height
    return a_x < b_x + b_w and a_x + a_w > b_x and a_y < b_y + b_h and a_y + a_h > b_y
end

local function check_object_collision(self, collider)
    -- simple check for aabb collisions - doesn't handle any kind of blocking behaviour
    for other_collider, _ in pairs(self.colliders) do
        if other_collider ~= collider then
            if intersect(collider, other_collider) then
                collider.onCollision(nil, other_collider)
                other_collider.onCollision(nil, collider)
            end
        end
    end
end

local function check_world_collision_x(self, collider)
    local x, old_y = collider.pos.x, collider.lastPos.y
    local moving_right = x > collider.lastPos.x
    local w, h = collider.width, collider.height
    local tw, th = self.world.tileWidth, self.world.tileHeight
    -- figure out the x coord of the leading edge
    local fw_x = moving_right and x + w or x
    local tile_x = math.floor(fw_x / tw)

    local can_move = true

    -- check all but the bottom 2 rows
    local top_row = math.floor(old_y / th)
    local bottom_row = math.floor((old_y + h) / th) - 2
    for row = top_row, bottom_row do
        if self.world:getTile(tile_x, row).collisionType ~= "none" then
            can_move = false
            break
        end
    end
    bottom_row = bottom_row + 1

    -- special cases on second from bottom row
    local ascending_ramp = false
    if can_move then
        -- check if we're trying to move into a ramp tile on the second row up,
        -- and its close edge is connected to another ramp (currently inside us)
        local bottom_tile = self.world:getTile(tile_x, bottom_row)
        local bottom_col_type = bottom_tile.collisionType
        if bottom_col_type == "ramp" then
            -- get the y at the near edge
            local near_y = moving_right and bottom_tile.y.left or bottom_tile.y.right
            -- figure out where to look for a connected ramp tile
            local connected_row = (near_y == 16) and bottom_row + 1 or bottom_row
            local connected_col = moving_right and tile_x - 1 or tile_x + 1
            local connected_tile = self.world:getTile(connected_col, connected_row)
            if connected_tile.collisionType == "ramp" then
                -- get the y of the connected tile at the connecting edge
                local connecting_y = moving_right and connected_tile.y.right or connected_tile.y.left
                near_y = near_y % th
                if connecting_y == near_y then
                    ascending_ramp = true
                end
            end
        end
        if bottom_col_type == "block" or (bottom_col_type == "ramp" and not ascending_ramp) then
            can_move = false
        end
    end
    bottom_row = bottom_row + 1

    -- special cases on bottom row
    if can_move and not ascending_ramp then
        local midpoint_col = math.floor((x + w / 2) / tw)
        local midpoint_tile = self.world:getTile(midpoint_col, bottom_row)
        -- if our midpoint is in a ramp, ignore the bottom row altogether
        if midpoint_tile.collisionType ~= "ramp" then
            -- if the bottom tile is a block, or it's a ramp and the high edge is closest, block
            local bottom_tile = self.world:getTile(tile_x, bottom_row) 
            if bottom_tile.collisionType == "block" then
                can_move = false
            elseif bottom_tile.collisionType == "ramp" then
                local y_left, y_right = bottom_tile.y.left, bottom_tile.y.right
                local rel_y = (old_y + h) % th
                if moving_right then
                    can_move = not (y_left < y_right and rel_y > y_left)
                else
                    can_move = not (y_right < y_left and rel_y > y_right)
                end
            end
        end
    end

    print("x: " .. (can_move and "can move" or "can't move"))
    local dx = 0
    if not can_move then
        dx = moving_right and tile_x*tw - (x + w + NUDGE) or (tile_x+1)*tw - x + NUDGE
        collider.onCollision(moving_right and "right" or "left")
    end
    return dx
end

local function check_world_collision_y(self, collider)
    local x, y = collider.pos:unpack()
    local old_y = collider.lastPos.y
    local moving_down = y >= old_y
    local w, h = collider.width, collider.height
    local tw, th = self.world.tileWidth, self.world.tileHeight
    -- where's our midpoint? what column is it in?
    local midpoint = x + w / 2
    local midpoint_col = math.floor(midpoint / tw)
    -- figure out the y coord of the leading edge
    local fw_y = moving_down and y + h or y
    local tile_y = math.floor(fw_y / th)
    local left_x = math.floor(x / tw)
    local right_x = math.floor((x + w) / tw)
    -- if we're in a ramp, don't check columns past the high end of the ramp
    -- (we also know the middle tile ain't a block, so skip that too)
    local mid_tile = self.world:getTile(midpoint_col, tile_y)
    if mid_tile.collisionType == "ramp" then
        if mid_tile.y.left > mid_tile.y.right then
            right_x = midpoint_col - 1
        else
            left_x = midpoint_col + 1
        end
    end
    -- check the columns we care about
    local can_move = true
    for col = left_x, right_x do
        local current_tile = self.world:getTile(col, tile_y)
        if current_tile.collisionType == "block" then
            can_move = false
            break
        end
    end
    -- welcome to the mf ramp zone
    local ramp_y = 0
    if can_move then
        -- if the midpoint is in a ramp, figure out if we need to be moved
        if mid_tile.collisionType == "ramp" then
            local t = x % tw / tw
            local r_y = math.floor((1 - t) * mid_tile.y.left + t * mid_tile.y.right)
            -- if we're under the ramp, push us up
            local rel_y = (fw_y % th)
            if rel_y > r_y then
                ramp_y = r_y
                can_move = false
            -- if we're above, but grounded and ~ 1 + NUDGE away, snap us down
            else
                local dist = r_y - rel_y
                if collider:getParent().grounded and dist > 1 then
                    return dist - NUDGE
                end
            end
        -- if it's not, check for other edge cases
        else
            -- if the player is grounded and the midpoint isn't in a ramp
            -- but would be on the row above or below, snap
            if collider:getParent().grounded then
                local super_mid_tile = self.world:getTile(midpoint_col, tile_y - 1)
                local sub_mid_tile = self.world:getTile(midpoint_col, tile_y + 1)
                if super_mid_tile.collisionType == "ramp" then
                    local t = x % tw / tw
                    local r_y = math.floor((1 - t) * super_mid_tile.y.left + t * super_mid_tile.y.right)
                    return ((tile_y - 1) * th + r_y) - fw_y + NUDGE
                elseif sub_mid_tile.collisionType ~= "none" then
                    local dist
                    if sub_mid_tile.collisionType == "ramp" then
                        local t = x % tw / tw
                        local r_y = math.floor((1 - t) * sub_mid_tile.y.left + t * sub_mid_tile.y.right)
                        dist = ((tile_y + 1) * th + r_y) - fw_y
                    -- if the tile below is a block, snap
                    else
                        dist = ((tile_y + 1) * th) - fw_y
                    end
                    if dist > 1 then
                        return dist - NUDGE
                    end
                end
            end
        end
    end
    print("y: " .. (can_move and "can move" or "can't move"))
    local dy = 0
    if not can_move then
        if moving_down then
            dy = (tile_y * th + ramp_y) - (fw_y + NUDGE)
        else
            dy = (tile_y + 1) * th - fw_y + NUDGE
        end
        collider.onCollision(moving_down and "bottom" or "top")
    end
    return dy
end

-- check for collisions and resolve em
function CollisionHandler:resolve()
    -- only check objects that can move: right now, that's the player
    for collider, _ in pairs(self.colliders) do
        if collider:getTag() == "player" then
            local dx = check_world_collision_x(self, collider)
            collider:moveX(dx)
            local dy = check_world_collision_y(self, collider)
            collider:moveY(dy)
            print("delta: ", dx, dy)
            check_object_collision(self, collider)
        end
    end
end

return CollisionHandler
