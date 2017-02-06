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
-- note: this will absolutely fuck up if we collide with multiple objects on a single axis
function CollisionHandler:checkCollision(obj, delta)
    local desired_pos = obj.vertices[1] + delta
    local resulting_pos = desired_pos
    for collider, _ in pairs(self.colliders) do
        -- the side of obj that made contact
        local colliding_side = nil
        -- shifted clones
        local shifted_obj_x = obj:cloneAt(desired_pos.x, obj.vertices[1].y)
        local shifted_obj_y = obj:cloneAt(obj.vertices[1].x, desired_pos.y)
        if collider.vertices[3].x == 4096 then
            print("x", shifted_obj_x.vertices[1])
            print("y", shifted_obj_y.vertices[1])
        end
        -- check for a collision at the new x position
        if checkCollision(shifted_obj_x, collider) then
            -- figure out where the collision actually happened
            -- if we're heading right we hit our right side
            if delta.x > 0 then
                if collider:isSolid() then
                    local width = obj.vertices[3].x - obj.vertices[1].x
                    resulting_pos.x = collider.vertices[1].x - width
                end
                colliding_side = side.right
            -- else, we've hit our left side
            else
                if collider:isSolid() then
                    resulting_pos.x = collider.vertices[3].x
                end
                colliding_side = side.left
                print("yea its this shit again")
            end
        -- check y collision
        elseif checkCollision(shifted_obj_y, collider) then
            -- if we're heading down we've hit our bottom
            if delta.y > 0 then
                if collider:isSolid() then
                    local height = obj.vertices[3].y - obj.vertices[1].y
                    resulting_pos.y = collider.vertices[1].y - height
                end
                colliding_side = side.bottom
                print("hit my bottom")
            -- else, we've hit our top
            else
                if collider:isSolid() then
                    resulting_pos.y = collider.vertices[3].y
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
    return resulting_pos - obj.vertices[1]
end

-- checks collision between 2 colliders
function checkCollision(a, b)
    for _, v in pairs(a.edges) do
        local axis = v.direction:perpendicular()
        local a_, b_ = project(a, axis), project(b, axis)
        if not overlap(a_, b_) then
            return false
        end
    end
    return true
end

-- takes an object and an axis to project onto (ie. the hypotenuse of a triangle)
function project(a, axis)
    -- find the min and max projection values, take those as the ends of our projection
    local vertices = a:getVertices()
    local min = vertices[1] * axis
    local max = min
    for _, v in pairs(vertices) do
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
    -- adjusted this to work with the way im dealing with collisions rn
    -- try reverting this line once i've made push vectors work
    -- return n >= a and n <= b
    return n > a and n < b
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
