-- handles collisions
CollisionHandler = Object:extend()

function CollisionHandler:new()
    self.colliders = {}
end

-- add a collider
function CollisionHandler:add(collider)
    self.colliders[collider] = true
end

-- remove a collider
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

-- check for collisions at the position we end up at with the given delta
-- execute the callback function of any colliding objects
-- returns the actual delta achieved
-- note: this will absolutely fuck up if we collide with multiple objects on a single axis
function CollisionHandler:checkCollision(obj, delta)
    local total_delta = vector(0, 0)
    for collider, _ in pairs(self.colliders) do
        -- the side of obj that made contact
        local colliding_side = nil
        -- check for a collision at the new position
        local colliding, mtd = checkCollision(obj, collider)
        if colliding then
            if collider:isSolid() then
                total_delta = total_delta + mtd
            end
            -- maybe this should be in player
            -- figure out which axis we're being pushed in hardest
            if math.abs(mtd.x) > math.abs(mtd.y) then
                -- if we're being pushed left we hit our right side
                if mtd.x < 0 then
                    colliding_side = side.right
                -- else, we've hit our left side
                else
                    colliding_side = side.left
                end
            else
                -- if we're being pushed up we hit our bottom
                if mtd.y < 0 then
                    colliding_side = side.bottom
                -- else, we've hit our top side
                else
                    colliding_side = side.top
                end
            end
        end
        if colliding_side then
            -- hit that mf callback button
            obj:onCollision(collider, colliding_side)
            collider:onCollision(obj, -colliding_side)
        end
    end
    return total_delta
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
    local mtd = findMTD(push_vectors)
    -- make sure the mtd is pushing a's centre away from b's centre
    local d = a:getCenter() - b:getCenter()
    if (d * mtd) < 0 then
        mtd = -mtd
    end
    return true, mtd
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
    if contains(a_[1], b_) or
       contains(a_[2], b_) or
       contains(b_[1], a_) or
       contains(b_[2], a_) then
        return true
    end
    return false
end

-- find minimum translation distance
function findMTD(push_vectors)
    local mtd = push_vectors[1]
    for _, v in pairs(push_vectors) do
        -- i dont think math.pow will work on vectors,
        if v * v < mtd * mtd then
            mtd = v
        end
    end
    return mtd
end
