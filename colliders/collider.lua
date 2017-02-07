-- a polygonal collider
-- takes a bunch of x and y coordinates, each pair is taken as a point
-- should an object collide with other objects? then it should extend this!
-- might be worth making this non-solid, then having eg. SolidCollider extend it

-- this is an edge
Segment = Object:extend()

function Segment:new(a, b)
    self.a = a
    self.b = b
    self.direction = b - a
end

-- todo: just call it a polygon or somethin
Collider = Object:extend()

-- assumes clockwise winding
function Collider:new(solid, ...)
    -- "false or true" is true so i got this workaround
    if solid == nil then
        self.solid = true
    else
        self.solid = solid
    end
    -- convert coords to vectors
    self.vertices = {...}
    -- create edges
    self.edges = {}
    for i = 1, #self.vertices do
        table.insert(self.edges, Segment(self.vertices[i], self.vertices[1+i%(#self.vertices)]))
    end
end

-- sets the callback function to the function given
function Collider:setCallback(callback_function)
    self.onCollision = callback_function
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

-- attempt to move by the requested amount, go where we can
function Collider:move(dx, dy)
    local delta = collisionHandler:checkCollision(self, vector(dx, dy))
    -- do i actually need to update these?
    -- in theory the vectors should update themselves... shouldn't they?
    -- they're tables after all
    for i, v in pairs(self.vertices) do
        self.vertices[i] = v + delta
    end
    for i, v in pairs(self.edges) do
        v.a = v.a + delta
        v.b = v.b + delta
    end
end

-- subclasses should override this
function Collider:onCollision()
end

function Collider:isSolid()
    return self.solid
end

function Collider:getVertices()
    return self.vertices
end

-- create a copy of the collider-specific elements
-- used by collision handler to check where we'll end up
-- really shouldn't be overwritten
function Collider:cloneAt(x, y)
    local delta = vector(x, y) - self.vertices[1]
    local new_vertices = {}
    for _, v in pairs(self.vertices) do
        table.insert(new_vertices, v + delta)
    end
    return Collider(self.solid, unpack(new_vertices))
end

-- this only works for rectangles and triangles
-- so, uh, only use those?
function Collider:getCenter()
    if #self.vertices == 3 then
        return (self.vertices[1] + self.vertices[2] + self.vertices[3]) / 3
    end
    return (self.vertices[1] + self.vertices[3]) / 2
end

function Collider:__tostring()
    return "Collider"
end
