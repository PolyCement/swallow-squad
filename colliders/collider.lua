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

-- should probably remove this once im done debugging
function Segment:__tostring()
    local a_string = tostring(self.a)
    local b_string = tostring(self.b)
    local dir_string = tostring(self.direction)
    return "Segment(" .. a_string .. ", " .. b_string .. ", " .. dir_string .. ")"
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
    for i, v in pairs(self.vertices) do
        self.vertices[i] = v + delta
    end
    -- technically we don't need to update these since the direction is the only
    -- bit we actually use, and since we don't support rotation that doesn't change
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
