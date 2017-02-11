-- a polygonal collider
-- should an object collide with other objects? then it should extend this!

-- this is an edge
Segment = Object:extend()

function Segment:new(a, b)
    self.a = a
    self.b = b
    self.direction = b - a
end

-- should probably remove this once im done debugging
function Segment:__tostring()
    local a_string = tostring(self.a)
    local b_string = tostring(self.b)
    local dir_string = tostring(self.direction)
    return "Segment(" .. a_string .. ", " .. b_string .. ", " .. dir_string .. ")"
end

-- THIS is the collider
Collider = Object:extend()

-- assumes clockwise winding
function Collider:new(solid, ...)
    -- "false or true" is true so i got this workaround
    if solid == nil then
        self.solid = true
    else
        self.solid = solid
    end
    -- store coordinates as vertices
    self.vertices = {...}
    -- create edges
    self.edges = {}
    for i = 1, #self.vertices do
        table.insert(self.edges, Segment(self.vertices[i], self.vertices[1+i%(#self.vertices)]))
    end
end

function Collider:draw()
    if showColliders then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(255, 0, 0, 255)
        -- todo: this kinda sucks actually
        local vertices = {}
        for _, v in pairs(self.vertices) do
            table.insert(vertices, v.x)
            table.insert(vertices, v.y)
        end
        love.graphics.polygon("line", unpack(vertices))
        love.graphics.setColor(r, g, b, a)
    end
end

-- move by the requested amount, correct our position if we hit something
function Collider:move(delta)
    self:movementHelper(delta)
    local correction_delta = collisionHandler:checkCollision(self)
    self:movementHelper(correction_delta)
end

-- move by the requested amount, no collision handling
-- do not use outside of collider!!!!!!!!!!!
function Collider:movementHelper(delta)
    for i, v in pairs(self.vertices) do
        self.vertices[i] = v + delta
    end
    -- technically we don't need to update these since the direction is the only
    -- bit we actually use, and since we don't support rotation direction never changes
    for i, v in pairs(self.edges) do
        v.a = v.a + delta
        v.b = v.b + delta
    end
end

-- callback function, subclasses should override this
function Collider:onCollision()
end

function Collider:isSolid()
    return self.solid
end

function Collider:getVertices()
    return self.vertices
end

-- calculate the centre of the polygon
function Collider:getCenter()
    local num_vertices = #self.vertices
    local total = self.vertices[1]
    for i = 2, num_vertices do
        total = total + self.vertices[i]
    end
    return total/num_vertices
end

function Collider:__tostring()
    return "Collider"
end
