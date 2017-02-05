-- maybe this should be renamed CollisionDetector since the collider itself handles the collision
CollisionHandler = Object:extend()

function CollisionHandler:new()
    self.colliders = {}
end

function CollisionHandler:add(collider)
    self.colliders[collider] = true
end

-- haha don't worry about it fam :)
function CollisionHandler:remove(collider)
    self.colliders[collider] = nil
end

-- "enum" for side which collision occurs on
-- negate to get the opposite side
side = {
    top = 1,
    bottom = -1,
    left = 2,
    right = -2 
}

-- check for collisions
-- execute the callback function of any colliding objects
-- returns the x and y coords of the position the object would end up at
-- note: this will absolutely fuck up if we collide with multiple objects on a single axis
function CollisionHandler:checkCollision(obj, dx, dy)
    local desired_x = obj.x + dx
    local desired_y = obj.y + dy
    local resulting_x = desired_x
    local resulting_y = desired_y
    for collider, _ in pairs(self.colliders) do
        -- the side of obj that made contact
        local colliding_side = nil
        -- check for a collision at the new x position
        if checkCollision(desired_x, obj.y, obj.width, obj.height,
                          collider.x, collider.y, collider.width, collider.height) then
            -- figure out where the collision actually happened
            -- if we're heading right we've collided with the other object's left side
            if dx > 0 then
                if collider:isSolid() then
                    resulting_x = collider.x - obj.width
                end
                colliding_side = side.right
            -- else, if we're heading left, we've collided with the other object's right side
            else
                if collider:isSolid() then
                    resulting_x = collider.x + collider.width
                end
                colliding_side = side.left
            end
        -- check y collision
        elseif checkCollision(obj.x, desired_y, obj.width, obj.height,
                              collider.x, collider.y, collider.width, collider.height) then
            -- if we're heading down we've collided with the top of the other object
            if dy > 0 then
                if collider:isSolid() then
                    resulting_y = collider.y - obj.height
                end
                colliding_side = side.bottom
            -- else, if we're heading up, we've collided with the other object's bottom
            else
                if collider:isSolid() then
                    resulting_y = collider.y + collider.height
                end
                colliding_side = side.top
            end
        end
        if colliding_side then
            -- hit that mf callback button
            obj:onCollision(collider, colliding_side)
            collider:onCollision(obj, -colliding_side)
        end
    end
    return resulting_x, resulting_y
end

--checks collision between 2 AABBs
function checkCollision(a_x, a_y, a_w, a_h, b_x, b_y, b_w, b_h)
    local a_left = a_x
    local a_right = a_x + a_w
    local a_top = a_y
    local a_bottom = a_y + a_h

    local b_left = b_x
    local b_right = b_x + b_w
    local b_top = b_y
    local b_bottom = b_y + b_h

    --check if sides overlap
    return a_right > b_left and
        a_left < b_right and
        a_bottom > b_top and
        a_top < b_bottom
end
