local Object = require "lib.classic"
local vector = require "lib.hump.vector"

-- polygonal colliders
-- they're components now btw

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
function Collider:new(...)
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
    -- solidity
    self.solid = true
    -- callback function
    self.onCollision = function() end
    -- tag (so other colliders know what hit em)
    self.tag = ""
    -- parent, for when a collider's parents need to know about each other in order to react properly
    -- (only useful for a handful of colliders, so it's optional)
    self.parent = nil
end

function Collider:setCallback(func)
    self.onCollision = func
end

function Collider:getTag()
    return self.tag
end

function Collider:setTag(tag)
    self.tag = tag
end

function Collider:getParent()
    return self.parent
end

function Collider:setParent(parent)
    self.parent = parent
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

-- move by the requested amount, no collision handling
local function movement_helper(self, delta)
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

-- move by the requested amount, correct our position if we hit something
function Collider:move(delta)
    movement_helper(self, delta)
    local correction_delta = collisionHandler:checkCollision(self)
    movement_helper(self, correction_delta)
end

function Collider:isSolid()
    return self.solid
end

-- get one vertex
function Collider:getVertex(idx)
    return self.vertices[idx]
end

-- get all the vertices
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

-- a on the left, b on the right
function Platform:new(a_x, a_y, b_x, b_y)
    Platform.super.new(self, a_x, a_y, b_x, b_y) 
end

-- platforms are only solid if the given collider was above them on the previous cycle
function Platform:isSolid(collider)
    local obj = collider:getParent()
    -- if the collider was above the bounding box of the platform, stay solid (allows hanging on edges)
    if obj.prevBottomPos.y <= math.min(self.vertices[1].y, self.vertices[2].y) then
        return true
    end
    -- if the determinant of ba and "ca" is negative, we're above the platform
    local ca = obj.prevBottomPos - self.vertices[1]
    local ba = self.edges[1].direction
    local determinant = ba.x * ca.y - ba.y * ca.x
    return determinant < 0
end

-- a non-solid collider
local Trigger = Collider:extend()

function Trigger:new(...)
    Trigger.super.new(self, ...)
    self.solid = false
end

return {
    Collider = Collider,
    Platform = Platform,
    Trigger = Trigger
}
