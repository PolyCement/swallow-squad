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

-- cast a ray and see what it hits
function CollisionHandler:raycast(ray_start, ray_end)
    -- check all segments of all shapes for an intersect
    local collisions = {}
    local a = {ray_start, ray_end}
    for collider, _ in pairs(self.colliders) do
        for _, e in pairs(collider.edges) do
            local b = {e.a, e.b}
            local intersect = getIntersect(a, b)
            if intersect then
                table.insert(collisions, intersect)
            end
        end
    end
    return collisions
end

-- checks if a and b intersect
-- this could probably be made more efficient by starting with a bounding box check
function getIntersect(a, b)
    local p, q = a[1], b[1]
    local r, s = a[2] - a[1], b[2] - b[1]
    local t = (-r.y * (p.x - q.x) + r.x * (p.y - q.y)) / (-s.x * r.y + r.x * s.y)
    local u = (s.x * (p.y - q.y) - s.y * (p.x - q.x)) / (-s.x * r.y + r.x * s.y)

    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        -- a and b intersect at p + ur
        return p + u * r
    end
    
    -- a and b do not intersect
    return nil
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
-- returns the delta resulting from collisions with the environment
function CollisionHandler:checkCollision(obj)
    local correction_delta = vector(0, 0)
    for collider, _ in pairs(self.colliders) do
        -- the side of obj that made contact
        local colliding_side = nil
        -- check for a collision at the new position
        local mtd = checkCollision(obj, collider)
        if mtd then
            if collider:isSolid() then
                correction_delta = correction_delta + mtd
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
    return correction_delta
end

-- checks if the given colliders are, uh, colliding
function checkCollision(a, b)
    -- track all potential push vectors
    local push_vectors = {}
    for _, v in pairs(a.edges) do
        local push_vector = checkCollisionInAxis(v.normal, a, b)
        if not push_vector then
            return nil
        end
        table.insert(push_vectors, push_vector)
    end
    for _, v in pairs(b.edges) do
        local push_vector = checkCollisionInAxis(v.normal, a, b)
        if not push_vector then
            return nil
        end
        table.insert(push_vectors, push_vector)
    end
    local mtd = findMTD(push_vectors)
    -- make sure the mtd is pushing a's centre away from b's centre
    local d = a:getCenter() - b:getCenter()
    if (d * mtd) < 0 then
        mtd = -mtd
    end
    return mtd
end

-- check for a collision in the given axis
function checkCollisionInAxis(axis, a, b)
    local a_, b_ = project(a, axis), project(b, axis)
    if not overlap(a_, b_) then
        return nil
    end
    -- calculate overlap between projections
    local depth = math.min(a_[2] - b_[1], b_[2] - a_[1])
    -- convert axis to push vector
    return axis:normalized() * depth
end

-- takes an object and an axis to project onto
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
    if range[2] < range[1] then
        a = b
        b = range[1]
    end
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
        if v * v < mtd * mtd then
            mtd = v
        end
    end
    return mtd
end
