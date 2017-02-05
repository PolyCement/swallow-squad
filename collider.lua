-- a basic aabb
-- should an object collide with other objects? then it should extend this!
-- this is gonna end up as a generic polygonal collider
-- it'll take a list of vectors
-- classes that extend this should probably hide that
-- might also be worth making this non-solid, then having eg. SolidCollider extend it
Collider = Object:extend()

function Collider:new(x, y, width, height, solid)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    -- this is turning into a major overhaul huh
    self.vertices = {}
    local x2 = self.x + self.width
    local y2 = self.y + self.height
    table.insert(self.vertices, vector(x, y))
    table.insert(self.vertices, vector(x2, y))
    table.insert(self.vertices, vector(x2, y2))
    table.insert(self.vertices, vector(x, y2))
    -- the default should be true but obv "false or true" is true so i got this workaround
    if solid == nil then
        self.solid = true
    else
        self.solid = solid
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
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
        love.graphics.setColor(r, g, b, a)
    end
end

-- attempt to move by the requested amount, go where we can
function Collider:move(dx, dy)
    local new_x, new_y = collisionHandler:checkCollision(self, vector(dx, dy)):unpack()
    local delta = vector(self.x - new_x, self.y - new_y)
    self.x, self.y = new_x, new_y
    for i, v in pairs(self.vertices) do
        self.vertices[i] = v + delta
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
    return Collider(x, y, self.width, self.height, self.solid)
end

function Collider:__tostring()
    return "Collider"
end
