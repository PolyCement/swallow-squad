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
-- todo: unfuck this for triangles
-- i think i need to alter the resulting x and y using the normal somehow?
-- note: this will absolutely fuck up if we collide with multiple objects on a single axis
function CollisionHandler:checkCollision(obj, delta)
    local desired_pos = vector(obj.x, obj.y) + delta
    local resulting_pos = desired_pos
    for collider, _ in pairs(self.colliders) do
        -- the side of obj that made contact
        local colliding_side = nil
        -- shifted clones
        local shifted_obj_x = obj:cloneAt(desired_pos.x, obj.y)
        local shifted_obj_y = obj:cloneAt(obj.x, desired_pos.y)
        -- check for a collision at the new x position
        if checkCollision(shifted_obj_x, collider) then
            -- figure out where the collision actually happened
            -- if we're heading right we hit our right side
            if delta.x > 0 then
                if collider:isSolid() then
                    resulting_pos.x = collider.x - obj.width
                end
                colliding_side = side.right
            -- else, we've hit our left side
            else
                if collider:isSolid() then
                    resulting_pos.x = collider.x + collider.width
                end
                colliding_side = side.left
            end
        -- check y collision
        elseif checkCollision(shifted_obj_y, collider) then
            -- if we're heading down we've hit our bottom
            if delta.y > 0 then
                if collider:isSolid() then
                    resulting_pos.y = collider.y - obj.height
                end
                colliding_side = side.bottom
            -- else, we've hit our top
            else
                if collider:isSolid() then
                    resulting_pos.y = collider.y + collider.height
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
    return resulting_pos
end

-- checks collision between 2 aabbs, or an aabb and an axis-aligned triangle
-- todo: take both colliders
-- heyyyy why is this returning true every single time
function checkCollision(a, b)
    -- check overlap in x axis
    local a_left = a.x
    local a_right = a.x + a.width
    local b_left = b.x
    local b_right = b.x + b.width

    if not (a_right > b_left and a_left < b_right) then
        return false
    end

    -- check overlap in y axis
    local a_top = a.y
    local a_bottom = a.y + a.height
    local b_top = b.y
    local b_bottom = b.y + b.height

    if not (a_bottom > b_top and a_top < b_bottom) then
        return false
    end

    -- check overlap along third axis (hypotenuse) for triangles
    if b:is(Triangle) then
        local axis = b.normal
        local a_, b_ = project(a, axis), project(b, axis)
        if not overlap(a_, b_) then
            return false
        end
    end
    return true
end

-- takes an object and an axis to project onto (ie. the hypotenuse of a triangle)
function project(a, axis)
    --find the min and max projection values, take those as the ends of our projection
    local vertices = a:getVertices()
    local min = vertices[1] * axis
    local max = min
    for i, v in ipairs(vertices) do
        local proj = v * axis
        if proj < min then min = proj end
        if proj > max then max = proj end
    end
    return {min, max}
end

-- checks if a point lies within a given range
function contains(n, range)
    local a, b = range[1], range[2]
    -- make sure a is smaller than b
    if b < a then
        a = b
        b = range[1]
    end
    return n >= a and n <= b
end

-- check if 2 projections overlap
function overlap(a_, b_)
    if contains(a_[1], b_) then
        return true
    elseif contains(a_[2], b_) then
        return true
    elseif contains(b_[1], a_) then
        return true
    elseif contains(b_[2], a_) then
        return true
    end
    return false
end
