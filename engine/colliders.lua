local Object = require "lib.classic"
local vector = require "lib.hump.vector"

-- a polygonal collider
-- should an object collide with other objects? then it should extend this!

-- this is an edge
local Segment = Object:extend()

function Segment:new(a, b)
    self.a = a
    self.b = b
    self.direction = b - a
    self.normal = self.direction:perpendicular():normalized()
end

-- should probably remove this once im done debugging
function Segment:__tostring()
    local a_string = tostring(self.a)
    local b_string = tostring(self.b)
    local dir_string = tostring(self.direction)
    return "Segment(" .. a_string .. ", " .. b_string .. ", " .. dir_string .. ")"
end

-- THIS is the collider
local Collider = Object:extend()

-- assumes clockwise winding
-- first arg denotes solidity, the rest are alternating x and y coords of each vertex
function Collider:new(solid, ...)
    self.solid = solid
    -- store coordinates as vertices
    local args = {...}
    self.vertices = {}
    for i = 1, #args, 2 do
        table.insert(self.vertices, vector(args[i], args[i+1]))
    end
    -- create edges
    self.edges = {}
    for i = 1, #self.vertices do
        table.insert(self.edges, Segment(self.vertices[i], self.vertices[1+i%(#self.vertices)]))
    end
end

-- draw the collider's bounding box
function Collider:drawBoundingBox()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(255, 0, 0, 255)
    -- shove all coordinates in a table
    local vertices = {}
    for _, v in pairs(self.vertices) do
        table.insert(vertices, v.x)
        table.insert(vertices, v.y)
    end
    -- we need at least 3 points to draw a polygon
    if #vertices < 6 then
        love.graphics.line(unpack(vertices))
    else
        love.graphics.polygon("line", unpack(vertices))
    end
    love.graphics.setColor(r, g, b, a)
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

-- a one-way platform
local Platform = Collider:extend()

-- assumes b is to the right of a
function Platform:new(a_x, a_y, b_x, b_y)
    Platform.super.new(self, true, a_x, a_y, b_x, b_y) 
end

-- platforms are only solid if the player was above them on the previous cycle
function Platform:isSolid()
    -- if the player was above the bounding box of the platform, stay solid (allows hanging on edges)
    if player.prevBottomPos.y <= math.min(self.vertices[1].y, self.vertices[2].y) then
        return true
    end
    -- if the determinant of ba and "ca" is negative, we're above the platform
    local ca = player.prevBottomPos - self.vertices[1]
    local ba = self.edges[1].direction
    local determinant = ba.x * ca.y - ba.y * ca.x
    return determinant < 0
end

return {
    Collider = Collider,
    Platform = Platform
}
