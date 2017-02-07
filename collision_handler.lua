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
-- todo: a better way of checking what side of the player made contact
-- presumably i can use the mtb for this? could i just check its rotation??
function CollisionHandler:checkCollision(obj, delta)
    local desired_pos = obj.vertices[1] + delta
    local resulting_pos = desired_pos
    for collider, _ in pairs(self.colliders) do
        -- the side of obj that made contact
        local colliding_side = nil
        -- shifted clones
        local shifted_obj_x = obj:cloneAt(desired_pos.x, obj.vertices[1].y)
        local shifted_obj_y = obj:cloneAt(obj.vertices[1].x, desired_pos.y)
        -- check for a collision at the new x position
        -- does this still need to be 2 parts?
        local colliding_x, mtb_x = checkCollision(shifted_obj_x, collider)
        local colliding_y, mtb_y = checkCollision(shifted_obj_y, collider)
        if colliding_x then
            if collider:isSolid() then
                print(mtb_x)
                resulting_pos = resulting_pos + mtb_x
            end
            -- figure out where the collision actually happened
            -- todo: fix how this works with triangles
            -- if we're heading right we hit our right side
            if delta.x > 0 then
                colliding_side = side.right
                print("hit my front")
            -- else, we've hit our left side
            else
                colliding_side = side.left
            end
        -- check y collision
        elseif colliding_y then
            if collider:isSolid() then
                print(mtb_y)
                resulting_pos = resulting_pos + mtb_y
            end
            -- if we're heading down we've hit our bottom
            if delta.y > 0 then
                print("hit my bottom")
                colliding_side = side.bottom
            -- else, we've hit our top
            else
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
    -- track all potential push vectors
    local push_vectors = {}
    for _, v in pairs(a.edges) do
        -- this sure looks like it should be a function
        -- normalise the normal or the depth calculation gets screwed up
        local axis = v.direction:perpendicular():normalized()
        local a_, b_ = project(a, axis), project(b, axis)
        if not overlap(a_, b_) then
            return false
        end
        -- calculate overlap between projections
        local depth = math.min(a_[2] - b_[1], b_[2] - a_[1])
        -- convert axis to push vector
        axis = axis:normalized() * depth
        table.insert(push_vectors, axis)
    end
    for _, v in pairs(b.edges) do
        local axis = v.direction:perpendicular():normalized()
        local a_, b_ = project(a, axis), project(b, axis)
        if not overlap(a_, b_) then
            return false
        end
        -- calculate overlap between projections
        local depth = math.min(a_[2] - b_[1], b_[2] - a_[1])
        -- convert axis to push vector
        axis = axis:normalized() * depth
        table.insert(push_vectors, axis)
    end
    local mtb = findMTB(push_vectors)
    -- make sure the mtb is pushing a's centre away from b's centre
    local d = a:getCenter() - b:getCenter()
    if (d * mtb) < 0 then
        mtb = -mtb
    end
    return true, mtb
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

function findMTB(push_vectors)
    local mtb = push_vectors[1]
    for _, v in pairs(push_vectors) do
        -- i dont think math.pow will work on vectors,
        if v * v < mtb * mtb then
            mtb = v
        end
    end
    return mtb
end
